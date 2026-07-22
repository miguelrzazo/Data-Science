library(shiny)
library(ggplot2)

data(mtcars)

fit <- lm(mpg ~ wt + hp + cyl, data = mtcars)

shinyServer(function(input, output) {

    predicted_mpg <- reactive({
        newdata <- data.frame(
            wt = input$weight / 1000,
            hp = input$hp,
            cyl = input$cyl
        )
        predict(fit, newdata = newdata)
    })

    output$prediction <- renderText({
        paste(round(predicted_mpg(), 1), "MPG")
    })

    output$mpgPlot <- renderPlot({
        mtcars$cyl_factor <- as.factor(mtcars$cyl)
        pred_wt <- input$weight / 1000
        pred_hp <- input$hp
        pred_cyl <- as.factor(input$cyl)
        pred_mpg <- predicted_mpg()

        ggplot(mtcars, aes(x = wt, y = mpg, color = cyl_factor)) +
            geom_point(size = 3, alpha = 0.7) +
            geom_point(aes(x = pred_wt, y = pred_mpg),
                       color = "red", size = 5, shape = 18) +
            geom_text(aes(x = pred_wt, y = pred_mpg,
                          label = paste0(round(pred_mpg, 1), " MPG")),
                      vjust = -1, hjust = 0.5, color = "red",
                      fontface = "bold", size = 4) +
            labs(
                title = "Car Weight vs. Fuel Economy (MPG)",
                subtitle = "Red diamond = your prediction",
                x = "Weight (1000 lbs)",
                y = "Miles Per Gallon",
                color = "Cylinders"
            ) +
            theme_minimal() +
            theme(
                plot.title = element_text(face = "bold", size = 14),
                plot.subtitle = element_text(color = "gray40")
            )
    })
})
