# Install required packages if not present
packages <- c("AppliedPredictiveModeling", "caret", "Hmisc", "ggplot2", "lattice")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}

library(AppliedPredictiveModeling)
library(caret)
library(Hmisc)
library(ggplot2)
library(lattice)

cat("=== QUESTION 1: 50/50 Train-Test Split ===\n")
data(AlzheimerDisease)
adData <- data.frame(diagnosis, predictors)
trainIndex <- createDataPartition(diagnosis, p = 0.5, list = FALSE)
training <- adData[trainIndex, ]
testing  <- adData[-trainIndex, ]
cat("Training rows:", nrow(training), "Testing rows:", nrow(testing), "\n")
cat("Proportions - Training:", round(nrow(training)/nrow(adData), 3), 
    "Testing:", round(nrow(testing)/nrow(adData), 3), "\n\n")

cat("=== QUESTION 2: Cement Data Plot ===\n")
data(concrete)
# The dataset is called 'mixtures' in the concrete data
# Check the structure
cat("Column names:", names(mixtures), "\n")
cat("Dimensions:", dim(mixtures), "\n")

# Plot CompressiveStrength vs index, colored by each variable
# Use cut2 to bin continuous variables for coloring
inTrain <- createDataPartition(mixtures$CompressiveStrength, p = 3/4)[[1]]
training_mix <- mixtures[inTrain, ]
testing_mix <- mixtures[-inTrain, ]

# Create index for plotting
training_mix$index <- 1:nrow(training_mix)

# Plot outcome vs index colored by each predictor
predictors_mix <- names(training_mix)[names(training_mix) != "CompressiveStrength" & names(training_mix) != "index"]
for (pred in predictors_mix) {
  p <- ggplot(training_mix, aes_string(x = "index", y = "CompressiveStrength", color = pred)) +
    geom_point(alpha = 0.6) +
    theme_minimal() +
    ggtitle(paste("CompressiveStrength vs Index colored by", pred))
  print(p)
}

# Also show the pattern with cut2 for continuous vars
cat("\nObservation: Looking for non-random patterns not explained by predictors...\n\n")

cat("=== QUESTION 3: SuperPlasticizer Histogram ===\n")
# Check the actual column name (case sensitive)
cat("Column names in mixtures:", names(mixtures), "\n")
# It's likely "Superplasticizer" (lowercase s)
hist(mixtures$Superplasticizer, main = "Superplasticizer Distribution", 
     xlab = "Superplasticizer", breaks = 30)
cat("Zero values:", sum(mixtures$Superplasticizer == 0), "\n")
cat("Negative values:", sum(mixtures$Superplasticizer < 0), "\n")
cat("Summary:\n")
print(summary(mixtures$Superplasticizer))
cat("\nWhy log transform is poor: log(0) = -Inf, which breaks models\n\n")

cat("=== QUESTION 4: PCA on IL Variables (90% variance) ===\n")
data(AlzheimerDisease)
adData <- data.frame(diagnosis, predictors)
set.seed(3433)
inTrain <- createDataPartition(adData$diagnosis, p = 3/4)[[1]]
training_ad <- adData[inTrain, ]
testing_ad <- adData[-inTrain, ]

# Find IL-prefixed variables
il_vars <- grep("^IL", names(training_ad), value = TRUE)
cat("IL variables found:", length(il_vars), "\n")
cat("Variables:", il_vars, "\n")

# PCA with 90% variance threshold
preproc_90 <- preProcess(training_ad[, il_vars], method = "pca", thresh = 0.90)
cat("\nPCA with 90% variance:\n")
cat("Number of components needed:", preproc_90$numComp, "\n")
cat("Cumulative variance explained:\n")
print(cumsum(preproc_90$pca$var.prop)[preproc_90$numComp])

# Also check for 80% for Question 5
preproc_80 <- preProcess(training_ad[, il_vars], method = "pca", thresh = 0.80)
cat("\nPCA with 80% variance:\n")
cat("Number of components needed:", preproc_80$numComp, "\n\n")

cat("=== QUESTION 5: GLM Models with/without PCA ===\n")
# Training data with only IL predictors + diagnosis
train_il <- training_ad[, c("diagnosis", il_vars)]
test_il <- testing_ad[, c("diagnosis", il_vars)]

# Model 1: Raw predictors
set.seed(3433)
ctrl <- trainControl(method = "cv", number = 5)
model_raw <- train(diagnosis ~ ., data = train_il, method = "glm", 
                   trControl = ctrl, family = "binomial")
cat("Raw model trained.\n")

# Predict on test set
pred_raw <- predict(model_raw, newdata = test_il)
cm_raw <- confusionMatrix(pred_raw, test_il$diagnosis)
cat("Raw model accuracy:", round(cm_raw$overall["Accuracy"], 4), "\n")

# Model 2: PCA with 80% variance
train_pca <- predict(preproc_80, training_ad[, il_vars])
train_pca$diagnosis <- training_ad$diagnosis

test_pca <- predict(preproc_80, testing_ad[, il_vars])
test_pca$diagnosis <- testing_ad$diagnosis

model_pca <- train(diagnosis ~ ., data = train_pca, method = "glm", 
                   trControl = ctrl, family = "binomial")
cat("PCA model trained.\n")

pred_pca <- predict(model_pca, newdata = test_pca)
cm_pca <- confusionMatrix(pred_pca, test_pca$diagnosis)
cat("PCA model accuracy:", round(cm_pca$overall["Accuracy"], 4), "\n")

cat("\n=== SUMMARY ===\n")
cat("Non-PCA Accuracy:", round(cm_raw$overall["Accuracy"], 4), "\n")
cat("PCA Accuracy:", round(cm_pca$overall["Accuracy"], 4), "\n")
cat("More accurate:", ifelse(cm_raw$overall["Accuracy"] > cm_pca$overall["Accuracy"], 
                             "Non-PCA", "PCA"), "\n")