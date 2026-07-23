##
## 01_data_prep.R
## Load, clean, and prepare the English SwiftKey dataset.
## Output: data/cleaned_en_US.rds, data/train.rds, data/test.rds
##

library(data.table)
library(stringr)

# ── 1. Load raw data ────────────────────────────────────────────────────────

data_dir <- file.path(dirname(getwd()), "final", "en_US")
out_dir  <- file.path(dirname(getwd()), "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Loading blogs...\n")
blogs <- readLines(file.path(data_dir, "en_US.blogs.txt"), encoding = "UTF-8", warn = FALSE)
cat("  Lines:", length(blogs), "\n")

cat("Loading news...\n")
news <- readLines(file.path(data_dir, "en_US.news.txt"), encoding = "UTF-8", warn = FALSE)
cat("  Lines:", length(news), "\n")

cat("Loading twitter...\n")
twitter <- readLines(file.path(data_dir, "en_US.twitter.txt"), encoding = "UTF-8", warn = FALSE)
cat("  Lines:", length(twitter), "\n")

# ── 2. Combine into data.table ──────────────────────────────────────────────

dt <- data.table(
  text   = c(blogs, news, twitter),
  source = rep(c("blogs", "news", "twitter"),
               times = c(length(blogs), length(news), length(twitter)))
)

rm(blogs, news, twitter)
gc()

cat("Total lines:", nrow(dt), "\n")
cat("Memory:", format(object.size(dt), units = "MB"), "\n")

# ── 3. Basic cleaning ───────────────────────────────────────────────────────

# Remove non-ASCII characters (keep letters, digits, punctuation, whitespace)
dt[, text := str_replace_all(text, "[^\x20-\x7E]", "")]

# Normalize whitespace
dt[, text := str_squish(text)]

# Remove empty lines
dt <- dt[nchar(text) > 0]

cat("After cleaning:", nrow(dt), "lines\n")

# ── 4. Add line IDs ────────────────────────────────────────────────────────

dt[, line_id := .I]

# ── 5. Save full cleaned dataset ────────────────────────────────────────────

saveRDS(dt, file.path(out_dir, "cleaned_en_US.rds"))
cat("Saved cleaned_en_US.rds:", format(object.size(dt), units = "MB"), "\n")

# ── 6. Train/test split (90/10, stratified by source) ───────────────────────

set.seed(42)
train_idx <- dt[, .(idx = sample(line_id, size = floor(0.9 * .N))), by = source]$idx
train <- dt[line_id %in% train_idx]
test  <- dt[!line_id %in% train_idx]

cat("Train:", nrow(train), "lines\n")
cat("Test: ", nrow(test),  "lines\n")

saveRDS(train, file.path(out_dir, "train.rds"))
saveRDS(test,  file.path(out_dir, "test.rds"))

cat("Done. Files saved to", out_dir, "\n")
