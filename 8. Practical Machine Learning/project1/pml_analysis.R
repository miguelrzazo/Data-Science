# Load libraries
suppressPackageStartupMessages({
  library(caret)
  library(randomForest)
  library(rpart)
  library(rpart.plot)
  library(rattle)
  library(corrplot)
  library(ggplot2)
  library(dplyr)
})

# Load data
training <- read.csv("pml-training.csv", na.strings = c("NA", "#DIV/0!", ""))
testing <- read.csv("pml-testing.csv", na.strings = c("NA", "#DIV/0!", ""))

cat("Training dim:", dim(training), "\n")
cat("Testing dim:", dim(testing), "\n")
cat("Class distribution:\n")
print(table(training$classe))

# Remove first 7 columns (metadata)
training <- training[, -c(1:7)]
testing <- testing[, -c(1:7)]

# Remove near zero variance predictors
nzv <- nearZeroVar(training, saveMetrics = TRUE)
cat("NZV columns:", sum(nzv$nzv), "\n")
training <- training[, !nzv$nzv]
testing <- testing[, !nzv$nzv]

# Remove columns with >95% NA
na_cols <- sapply(training, function(x) mean(is.na(x))) > 0.95
cat("High NA columns:", sum(na_cols), "\n")
training <- training[, !na_cols]
testing <- testing[, !na_cols]

cat("After cleaning - Training dim:", dim(training), "Testing dim:", dim(testing), "\n")

# Check remaining NAs
cat("Remaining NAs in training:", sum(is.na(training)), "\n")
cat("Remaining NAs in testing:", sum(is.na(testing)), "\n")

# Ensure classe is factor (testing has no classe column)
training$classe <- as.factor(training$classe)

# Split training into train/validation
set.seed(12345)
inTrain <- createDataPartition(y = training$classe, p = 0.7, list = FALSE)
trainSet <- training[inTrain, ]
validSet <- training[-inTrain, ]

cat("Train set:", dim(trainSet), "Valid set:", dim(validSet), "\n")

# Train Random Forest with 5-fold CV
set.seed(12345)
ctrl <- trainControl(method = "cv", number = 5, verboseIter = TRUE)

rf_model <- train(classe ~ ., data = trainSet, method = "rf",
                  trControl = ctrl,
                  ntree = 250,
                  tuneLength = 3)

print(rf_model)
print(rf_model$finalModel)

# Validate on held-out data
pred_valid <- predict(rf_model, validSet)
cm <- confusionMatrix(pred_valid, validSet$classe)
cat("\n=== Validation Set Confusion Matrix ===\n")
print(cm)

# Predict on the 20 test cases
pred_test <- predict(rf_model, testing)
cat("\n=== Predictions for 20 Test Cases ===\n")
print(pred_test)

# Write submission files
pml_write_files = function(x){
  n = length(x)
  for(i in 1:n){
    filename = paste0("problem_id_", i, ".txt")
    write.table(x[i], file = filename, quote = FALSE, row.names = FALSE, col.names = FALSE)
  }
}

pml_write_files(pred_test)
cat("Prediction files written.\n")
