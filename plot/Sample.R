
  
library(ggplot2)
#setwd("../vectordb/plot")
source(file="theme.r")

data <- read.csv(file='result.log', header=TRUE, sep=',')
data$NJOINS <- as.factor(data$NJOINS)
data
png('resul.log.png', width=1920, height=1080)
print(
  ggplot(data, aes(x = TimeNAQO, y = TimeAQO, color = NJOINS)) +
    geom_point(size=4) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_log10(limits=c(100, 35000)) +
    scale_y_log10(limits=c(100, 35000)) +
    ggtitle("Optimization Latency") +
    xlab("Postgres") +
    ylab("AQO")
)
dev.off()
