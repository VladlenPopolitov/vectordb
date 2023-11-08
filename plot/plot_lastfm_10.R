# library for regexp
library(stringr)
# library for gplot
library(tidyverse)
substrRight <- function(x, n){substr(x, nchar(x)-n+1, nchar(x))}

#datasetName <- "lastfm"
#datasetName <- "glove-100-a"
datasetName <- "fashion-mnist-784-e"
queryLines <- "10"
getwd()
setwd(".")
pathToRepoRoot <- "./Development/work/vectordb/vectordb"
pathToResultsRoot <- paste(pathToRepoRoot,"results",sep="/")
pathToAlgorithmRoot <- paste(pathToResultsRoot,datasetName,sep="/")
path <- paste(pathToAlgorithmRoot,queryLines,sep="/")
print( path )
inputFile <- paste(path,"benchmark.csv", sep = "/")
inputFile
results <- read.csv(inputFile, sep = "\t")
results
resultsSorted = results[order(results$Dataset,results$Algorithm, results$Recall,results$RecordsPerSecond),]
resultsSorted
pgvector_hnsw <- resultsSorted[resultsSorted$Algorithm == 'pgvector_hnsw',]
pgvector_hnsw
pgvector_i <- resultsSorted[resultsSorted$Algorithm == 'pgvector_i',]
pgvector_i
embedding <- resultsSorted[resultsSorted$Algorithm == 'pg_embedding',]
embedding
lantern <- resultsSorted[resultsSorted$Algorithm == 'lantern',]
lantern

outputFile <- paste(path,"benchmark.png", sep = "/")
png(outputFile)
plot(x=c(0.05,1.1), y=c(1,60000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="green" ,type = "b",pch=4)
lines(x=embedding$Recall, y=embedding$RecordsPerSecond, col="blue" ,type = "b",pch=5)
lines(x=lantern$Recall, y=lantern$RecordsPerSecond, col="brown" ,type = "b",pch=6)

legend(0.06, 20, legend=c("pgvector_hnsw", "pgvector_i", "embedding_pg","lantern"),  
       fill = c("red","green","blue","brown") )
dev.off()

outputFile <- paste(path,"benchmarkIndex.png", sep = "/")
png(outputFile)
plot(x=c(0.05,1.1), y=c(1,60000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Index creation time (seconds)")

lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$IndexTime, col="red" ,type = "l",pch=1)
lines(x=pgvector_i$Recall, y=pgvector_i$IndexTime, col="green" ,type = "l",pch=4)
lines(x=embedding$Recall, y=embedding$IndexTime, col="blue" ,type = "l",pch=5)
lines(x=lantern$Recall, y=lantern$IndexTime, col="brown" ,type = "b",pch=6)

legend(0.06, 10000, legend=c("pgvector_hnsw", "pgvector_i", "embedding_pg","lantern"),  
       fill = c("red","green","blue","brown") )
dev.off()

resultFiltered<-filter(resultsSorted,Recall>0.4)
outputFile <- paste(path,"benchmark2.png", sep = "/")
png(outputFile)
ggplot(data = resultFiltered,aes(x = Recall, y = RecordsPerSecond,color=Algorithm,group=Algorithm)) + ylab("Records Per Second") +
  geom_point(mapping = aes(x = Recall, y = RecordsPerSecond,color=Algorithm,group=1)) + 
  geom_path() +
  geom_point() +
  ggtitle(paste("Dataset: ",datasetName))

dev.off()



