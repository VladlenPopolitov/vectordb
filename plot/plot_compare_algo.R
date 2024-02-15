library(stringr)
library(tidyverse)
#datasetName <- "lastfm"
#datasetName <- "glove-100-a"
datasetName <- "fashion-mnist-784-e"
#datasetName <- "galaxies-3-5000-e"
#datasetName <- "galaxies-16-5000-e"
#datasetName <- "galaxies-16-1000000-e"
queryLines <- "10"
getwd()
#setwd("../vectordb/plot")
#pathToRepoRoot <- "./Development/work/vectordb/vectordb"
pathToRepoRoot <- "../"
pathToResultsRoot <- paste(pathToRepoRoot,"results",sep="/")
pathToAlgorithmRoot <- paste(pathToResultsRoot,datasetName,sep="/")
path <- paste(pathToAlgorithmRoot,queryLines,sep="/")
print( path )
source(file="theme.r")
inputFile <- paste(path,"benchmarkunit.csv", sep = "/")
inputFile
results <- read.csv(inputFile, sep = "\t")
results
resultsSorted = results  #results[order(results$Dataset,results$Algorithm, results$Recall,results$RecordsPerSecond),]
resultsSorted

substrRight <- function(x, n){substr(x, nchar(x)-n+1, nchar(x))}


outputFile <- paste(path,"benchmarkunit90-100.png", sep = "/")
png(outputFile, width=1920, height=1080)
print(
  ggplot(resultsSorted, aes(x = Recall, y = Speed, color = Algorithm)) +
    geom_line(linetype = "solid", size=2) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_log10(limits=c(0.0001, 0.1)) +
    scale_y_continuous(limits=c(0.5, 1.5)) +
    ggtitle("Query per seconds with different recall, ration Qgann / Qpgvector") +
    xlab("Recall value ( 1 - recall )") +
    ylab("Queries per second ratio to pgvector: Qgann / Qpgvector")
)
dev.off()

outputFile <- paste(path,"benchmarkunit999.png", sep = "/")
png(outputFile, width=1920, height=1080)
print(
  ggplot(resultsSorted, aes(x = Recall, y = Speed, color = Algorithm)) +
    geom_line(linetype = "solid", size=2) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_continuous(limits=c(0.0, .001)) +
    scale_y_continuous(limits=c(0.5, 1.5)) +
    ggtitle("Query per seconds with different recall, ration Qgann / Qpgvector") +
    xlab("Recall value ( 1 - recall )") +
    ylab("Queries per second ratio to pgvector: Qgann / Qpgvector")
)
dev.off()
resultsSorted

