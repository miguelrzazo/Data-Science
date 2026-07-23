##
## predict.R
## Deployment copy of scripts/03_predict.R — shinyapps.io only bundles files
## inside shiny/, so this must live here rather than be sourced via "../".
## Keep in sync with scripts/03_predict.R if the backoff logic changes.
##
## Tables are data.table with columns: context, word, prob (top-5 per context,
## keyed on context for fast lookup).
##

library(data.table)

BACKOFF_WEIGHT <- 0.4

load_models <- function(model_dir) {
  list(
    unigram  = readRDS(file.path(model_dir, "unigram.rds")),
    bigram   = readRDS(file.path(model_dir, "bigram.rds")),
    trigram  = readRDS(file.path(model_dir, "trigram.rds")),
    quadgram = readRDS(file.path(model_dir, "quadgram.rds"))
  )
}

tokenize_input <- function(text) {
  unlist(regmatches(tolower(text), gregexpr("\\b[a-z]+\\b", tolower(text))))
}

#' Predict the next word given a phrase, using Stupid Backoff.
#'
#' Tries the longest available context (up to 3 preceding words) first, at
#' full probability. If fewer than `k` candidates are found, backs off to
#' shorter contexts, each discounted by BACKOFF_WEIGHT per order dropped, and
#' fills remaining slots without duplicating words already found.
predict_next_word <- function(text, models, k = 3) {
  words <- tokenize_input(text)
  n <- length(words)

  candidates <- data.table(word = character(0), score = numeric(0))

  add_candidates <- function(table, ctx, weight) {
    if (nrow(candidates) >= k) return(invisible(NULL))
    rows <- table[.(ctx), on = "context", nomatch = NULL]
    if (nrow(rows) == 0) return(invisible(NULL))
    rows <- head(rows, k)  # rows are pre-sorted by prob descending when saved
    rows <- rows[!word %in% candidates$word]
    if (nrow(rows) == 0) return(invisible(NULL))
    new_rows <- data.table(word = rows$word, score = weight * rows$prob)
    candidates <<- rbind(candidates, new_rows)
  }

  if (n >= 3) {
    add_candidates(models$quadgram, paste(tail(words, 3), collapse = " "), 1)
  }
  if (n >= 2) {
    add_candidates(models$trigram, paste(tail(words, 2), collapse = " "), BACKOFF_WEIGHT)
  }
  if (n >= 1) {
    add_candidates(models$bigram, tail(words, 1), BACKOFF_WEIGHT^2)
  }
  add_candidates(models$unigram, "", BACKOFF_WEIGHT^3)

  candidates <- candidates[order(-score)]
  head(candidates, k)
}
