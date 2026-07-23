##
## app.R
## Next-word predictor: type a phrase, get top-3 candidate next words from a
## Stupid Backoff n-gram model, click one to append it.
##

library(shiny)
library(data.table)

source("predict.R")

models <- load_models("models")

ui <- fluidPage(
  titlePanel("Next-Word Predictor"),
  helpText(
    "Type a phrase below. The model looks at up to your last 3 words and",
    "suggests the most likely next word, backing off to shorter contexts",
    "(then to the single most common words overall) when it hasn't seen",
    "your exact phrase before."
  ),
  fluidRow(
    column(
      width = 8,
      textAreaInput("phrase", label = NULL, value = "",
                     placeholder = "Start typing a sentence...",
                     width = "100%", rows = 3)
    )
  ),
  fluidRow(
    column(
      width = 8,
      uiOutput("suggestion_buttons")
    )
  ),
  fluidRow(
    column(
      width = 8,
      tags$p(style = "color: grey; margin-top: 15px;",
             textOutput("latency_text"))
    )
  )
)

server <- function(input, output, session) {

  predictions <- debounce(reactive({
    text <- input$phrase
    if (nchar(trimws(text)) == 0) {
      return(list(words = character(0), latency_ms = 0))
    }
    start <- Sys.time()
    preds <- predict_next_word(text, models, k = 3)
    latency_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
    list(words = preds$word, latency_ms = latency_ms)
  }), 300)

  output$suggestion_buttons <- renderUI({
    words <- predictions()$words
    if (length(words) == 0) return(NULL)
    tagList(
      lapply(seq_along(words), function(i) {
        actionButton(
          inputId = paste0("suggestion_", i),
          label   = words[i],
          class   = "btn btn-primary",
          style   = "margin-right: 8px;"
        )
      })
    )
  })

  observe({
    lapply(seq_len(3), function(i) {
      local({
        idx <- i
        observeEvent(input[[paste0("suggestion_", idx)]], {
          words <- isolate(predictions()$words)
          if (idx <= length(words)) {
            current <- isolate(input$phrase)
            sep <- if (nchar(trimws(current)) == 0) "" else " "
            updateTextAreaInput(session, "phrase",
                                 value = paste0(current, sep, words[idx], " "))
          }
        }, ignoreInit = TRUE)
      })
    })
  })

  output$latency_text <- renderText({
    lat <- predictions()$latency_ms
    if (lat == 0) return("")
    sprintf("Last prediction took %.1f ms", lat)
  })
}

shinyApp(ui, server)
