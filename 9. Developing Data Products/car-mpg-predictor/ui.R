library(shiny)

shinyUI(navbarPage("Car MPG Predictor",
    tabPanel("Documentation",
        withMathJax(),
        fluidRow(
            column(8, offset = 2,
                h3("Car MPG Predictor"),
                p("This application predicts the fuel economy (miles per gallon) of a car
                   based on three key characteristics: weight, horsepower, and number of cylinders."),
                br(),
                h4("How It Works"),
                p("The app uses a multiple linear regression model trained on the classic",
                  strong("mtcars"), "dataset (1974 Motor Trend magazine data). The model is:"),
                p(code("mpg ~ weight + horsepower + cylinders")),
                br(),
                h4("Instructions"),
                tags$ol(
                    tags$li("Navigate to the", strong("Predictor"), "tab"),
                    tags$li("Adjust the three input sliders to match your car's specifications:"),
                    tags$ul(
                        tags$li("Weight (in thousands of pounds)"),
                        tags$li("Horsepower (mechanical horsepower)"),
                        tags$li("Number of cylinders (4, 6, or 8)")
                    ),
                    tags$li("Click the", strong("Calculate MPG"), "button"),
                    tags$li("View your predicted MPG and the scatterplot visualization")
                ),
                br(),
                h4("About the Data"),
                p("The", code("mtcars"), "dataset contains 32 observations on 11 variables
                   from 1974 Motor Trend magazine. It includes fuel consumption and 10
                   aspects of automobile design and performance."),
                br(),
                h4("Limitations"),
                tags$ul(
                    tags$li("The model is trained on 1970s car data"),
                    tags$li("Only three predictors are used (real-world MPG depends on many more factors)"),
                    tags$li("Predictions are estimates and should not be treated as exact values")
                )
            )
        )
    ),
    tabPanel("Predictor",
        fluidRow(
            column(4,
                wellPanel(
                    h4("Car Specifications"),
                    br(),
                    sliderInput("weight", "Weight (lbs):",
                        min = 1500, max = 5500, value = 3200, step = 100),
                    br(),
                    sliderInput("hp", "Horsepower:",
                        min = 50, max = 350, value = 150, step = 5),
                    br(),
                    sliderInput("cyl", "Cylinders:",
                        min = 4, max = 8, value = 6, step = 2),
                    br(),
                    submitButton("Calculate MPG")
                )
            ),
            column(8,
                h4("Predicted Fuel Economy"),
                br(),
                h3(textOutput("prediction"), style = "color: #d9534f; font-weight: bold;"),
                br(),
                plotOutput("mpgPlot")
            )
        )
    )
))
