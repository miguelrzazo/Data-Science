##
## 04_evaluate.R
## Evaluate the Stupid Backoff model on held-out test data: accuracy@1/2/3,
## average prediction latency, and total model size.
## Output: models/evaluation_results.rds
##

library(data.table)

if (file.exists("data/test.rds")) {
  base_dir <- getwd()
} else if (file.exists("../data/test.rds")) {
  base_dir <- dirname(getwd())
} else {
  stop("Cannot find data/test.rds")
}

data_dir   <- file.path(base_dir, "data")
model_dir  <- file.path(base_dir, "models")
script_dir <- file.path(base_dir, "scripts")

source(file.path(script_dir, "03_predict.R"))

cat("Loading models...\n")
models <- load_models(model_dir)

model_size_mb <- as.numeric(
  object.size(models$unigram) + object.size(models$bigram) +
  object.size(models$trigram) + object.size(models$quadgram)
) / 1e6

cat("Loading test data...\n")
test <- readRDS(file.path(data_dir, "test.rds"))

# ── Sample test lines and build (context, actual_next_word) pairs ──────────

set.seed(42)
n_lines <- min(3000, nrow(test))
sample_lines <- test[sample(nrow(test), n_lines), text]

build_eval_pairs <- function(lines) {
  pairs <- list()
  for (line in lines) {
    words <- tokenize_input(line)
    if (length(words) < 2) next
    for (i in 2:length(words)) {
      context_words <- words[max(1, i - 3):(i - 1)]
      pairs[[length(pairs) + 1]] <- list(
        context = paste(context_words, collapse = " "),
        actual  = words[i]
      )
    }
  }
  pairs
}

cat("Building evaluation pairs from", n_lines, "test lines...\n")
eval_pairs <- build_eval_pairs(sample_lines)
n_pairs <- length(eval_pairs)
cat("  ", n_pairs, "evaluation pairs\n")

# Cap the number of scored predictions for tractable runtime.
n_eval <- min(2000, n_pairs)
eval_pairs <- eval_pairs[sample(n_pairs, n_eval)]

# ── Run predictions, score accuracy@1/2/3, time it ──────────────────────────

cat("Running predictions...\n")
hit1 <- hit2 <- hit3 <- logical(n_eval)

start_time <- Sys.time()
for (i in seq_len(n_eval)) {
  preds <- predict_next_word(eval_pairs[[i]]$context, models, k = 3)$word
  actual <- eval_pairs[[i]]$actual
  hit1[i] <- length(preds) >= 1 && actual == preds[1]
  hit2[i] <- actual %in% head(preds, 2)
  hit3[i] <- actual %in% preds
}
elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

results <- data.table(
  metric = c("accuracy@1", "accuracy@2", "accuracy@3",
             "avg_latency_ms", "total_predictions",
             "model_size_mb"),
  value  = c(mean(hit1), mean(hit2), mean(hit3),
             1000 * elapsed / n_eval, n_eval,
             model_size_mb)
)

cat("\n=== Evaluation Results ===\n")
print(results)

dir.create(model_dir, showWarnings = FALSE, recursive = TRUE)
saveRDS(results, file.path(model_dir, "evaluation_results.rds"))
cat("\nSaved to", file.path(model_dir, "evaluation_results.rds"), "\n")
