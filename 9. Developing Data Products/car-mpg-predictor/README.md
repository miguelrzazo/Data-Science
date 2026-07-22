# Car MPG Predictor

An interactive Shiny application that predicts car fuel economy (miles per gallon) based on weight, horsepower, and number of cylinders.

## Running Locally

```r
install.packages("shiny")
library(shiny)
runApp("car-mpg-predictor")
```

## How It Works

The app uses a multiple linear regression model fitted on the `mtcars` dataset:

```r
fit <- lm(mpg ~ wt + hp + cyl, data = mtcars)
```

### Inputs
- **Weight** (1,500 - 5,500 lbs): The curb weight of the vehicle
- **Horsepower** (50 - 350 HP): Engine power output
- **Cylinders** (4, 6, or 8): Number of engine cylinders

### Outputs
- **Predicted MPG**: The estimated fuel economy in miles per gallon
- **Scatterplot**: A visualization of weight vs. MPG with your prediction highlighted

## Files

| File | Description |
|------|-------------|
| `ui.R` | User interface definition with documentation and predictor tabs |
| `server.R` | Server logic with model fitting and reactive outputs |
| `README.md` | This file |

## Data

Uses the built-in `mtcars` dataset from R, which contains fuel consumption and 10 aspects of automobile design and performance for 32 automobiles (1974 Motor Trend).

## Deployment

To deploy on shinyapps.io:

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name='your-account', token='your-token', secret='your-secret')
rsconnect::deployApp("car-mpg-predictor")
```
