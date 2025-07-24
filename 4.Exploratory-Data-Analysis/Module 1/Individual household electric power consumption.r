setwd(dirname(sys.frame(1)$ofile)) # If running from RStudio Source# Read the data
power_data <- read.table("household_power_consumption.txt", header=TRUE, sep=";", na.strings="?", stringsAsFactors=FALSE)
# Convert Global_active_power to numeric (if needed)
power_data$Global_active_power <- as.numeric(power_data$Global_active_power)

# Plot histogram
dev.off()
png("global_active_power_histogram.png")
options(scipen=10) # Prevent scientific notation
h <- hist(power_data$Global_active_power,
     main="Histogram of Global Active Power",
     xlab="Global Active Power (kilowatts)",
     col="red",
     breaks=seq(floor(min(power_data$Global_active_power, na.rm=TRUE)),
               ceiling(max(power_data$Global_active_power, na.rm=TRUE)),
               by=0.5),
     ylab="Frequency")
# Redraw y-axis with normal notation
axis(2, at=axTicks(2), labels=format(axTicks(2), scientific=FALSE))
dev.off()