##
## 02_ngram_model.R
## Build frequency tables for unigrams through quadgrams using quanteda for
## tokenization/cleaning (inspired by wayneheller/DataScienceSpecializationCapstone).
## Output: models/unigram.rds ... models/quadgram.rds
##

library(data.table)
library(quanteda)
library(quanteda.textstats)

# ── 1. Load training data ───────────────────────────────────────────────────

if (file.exists("data/train.rds")) {
  base_dir <- getwd()
} else if (file.exists("../data/train.rds")) {
  base_dir <- dirname(getwd())
} else {
  stop("Cannot find data/train.rds")
}

data_dir  <- file.path(base_dir, "data")
model_dir <- file.path(base_dir, "models")

cat("Loading training data...\n")
train <- readRDS(file.path(data_dir, "train.rds"))
cat("Training lines (full):", nrow(train), "\n")

# Subsample the training corpus, stratified by source. Building on the full
# ~3.8M lines pushed peak memory towards ~11GB and 30+ min runtime, and
# produced a >1GB model — impractical for a shinyapps.io deployment. ~1.5M
# lines keeps build time/memory comfortable while still covering the bulk of
# vocabulary and n-gram diversity (Heaps' law: vocabulary growth is sublinear).
sample_fraction <- 0.4
set.seed(42)
sample_idx <- train[, .(idx = sample(line_id, size = floor(sample_fraction * .N))), by = source]$idx
train <- train[line_id %in% sample_idx]
cat("Training lines (sampled, fraction =", sample_fraction, "):", nrow(train), "\n")

# ── 2. Tokenize with quanteda ────────────────────────────────────────────────

cat("Tokenizing...\n")
toks <- tokens(
  train$text,
  remove_punct     = TRUE,
  remove_symbols   = TRUE,
  remove_numbers   = TRUE,
  remove_url       = TRUE,
  remove_separators = TRUE,
  split_hyphens    = FALSE
)
toks <- tokens_tolower(toks)
rm(train); gc()

# Drop profanity (same list used in EDA_Report.Rmd) so it never surfaces as a
# predicted word.
profanity_words <- c("fuck", "shit", "ass", "bitch", "damn", "hell",
                      "crap", "dick", "piss", "bastard", "whore", "slut")
toks <- tokens_remove(toks, profanity_words, valuetype = "fixed")

# Replace hapax legomena (words seen exactly once) with "unk" — this bounds
# vocabulary size and gives unseen/rare words a shared representation instead
# of vanishing from the model entirely.
cat("Identifying hapax legomena for UNK replacement...\n")
unigram_freq <- textstat_frequency(dfm(toks))
hapax_words  <- unigram_freq$feature[unigram_freq$frequency == 1]
cat("  ", length(hapax_words), "hapax legomena out of", nrow(unigram_freq), "unique words\n")

toks <- tokens_replace(toks, pattern = hapax_words,
                        replacement = rep("unk", length(hapax_words)),
                        valuetype = "fixed")
rm(unigram_freq); gc()

# ── 3. Build n-gram counts via quanteda ─────────────────────────────────────

build_ngram_counts <- function(toks, n, min_count) {
  cat("  Building", n, "-grams...\n")

  if (n == 1) {
    ng_toks <- toks
  } else {
    ng_toks <- tokens_ngrams(toks, n = n, concatenator = " ")
  }

  ng_dfm  <- dfm(ng_toks)
  ng_dfm  <- dfm_trim(ng_dfm, min_termfreq = min_count)
  freq_df <- textstat_frequency(ng_dfm)

  freq <- as.data.table(freq_df)[, .(ngram = feature, count = frequency)]

  # Split into context + word
  if (n == 1) {
    freq[, context := ""]
    freq[, word := ngram]
  } else {
    parts <- strsplit(freq$ngram, " ")
    freq[, context := sapply(parts, function(p) paste(p[-length(p)], collapse = " "))]
    freq[, word := sapply(parts, function(p) p[length(p)])]
  }

  # Conditional probabilities
  freq[, prob := count / sum(count), by = context]
  freq <- freq[order(context, -prob)]

  # Keep only the top 5 candidates per context — predictions never need more,
  # and the long tail per context is most of the memory footprint.
  if (n > 1) {
    freq <- freq[, .SD[seq_len(min(.N, 5))], by = context]
  }

  setkey(freq, context)

  cat("    ", nrow(freq), "unique", n, "-grams (min_count =", min_count, ")\n")
  freq
}

unigram  <- build_ngram_counts(toks, 1, min_count = 3)
gc()
bigram   <- build_ngram_counts(toks, 2, min_count = 3)
gc()
trigram  <- build_ngram_counts(toks, 3, min_count = 3)
gc()
quadgram <- build_ngram_counts(toks, 4, min_count = 3)

rm(toks); gc()

# ── 4. Save models ──────────────────────────────────────────────────────────

dir.create(model_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(unigram,  file.path(model_dir, "unigram.rds"))
saveRDS(bigram,   file.path(model_dir, "bigram.rds"))
saveRDS(trigram,  file.path(model_dir, "trigram.rds"))
saveRDS(quadgram, file.path(model_dir, "quadgram.rds"))

cat("\nModel sizes:\n")
cat("  Unigram: ", format(object.size(unigram),  units = "MB"), "\n")
cat("  Bigram:  ", format(object.size(bigram),   units = "MB"), "\n")
cat("  Trigram: ", format(object.size(trigram),  units = "MB"), "\n")
cat("  Quadgram:", format(object.size(quadgram), units = "MB"), "\n")
cat("  Total:   ", format(
  object.size(unigram) + object.size(bigram) +
  object.size(trigram) + object.size(quadgram),
  units = "MB"), "\n")

cat("\nDone. Models saved to", model_dir, "\n")
