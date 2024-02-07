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
setwd(".")
#pathToRepoRoot <- "./Development/work/vectordb/vectordb"
pathToRepoRoot <- "../"
pathToResultsRoot <- paste(pathToRepoRoot,"results",sep="/")
pathToAlgorithmRoot <- paste(pathToResultsRoot,datasetName,sep="/")
path <- paste(pathToAlgorithmRoot,queryLines,sep="/")
print( path )
source(file="theme.r")
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
embedding <- resultsSorted[resultsSorted$Algorithm == 'gann_hnsw',]
embedding

substrRight <- function(x, n){substr(x, nchar(x)-n+1, nchar(x))}

fc500<-filter(embedding, str_detect(embedding$Parameters,'fConstruction\'=>500,')==TRUE)
arrange(fc500,desc(Recall))
embeddingParm<-mutate(embedding,
       efC=str_extract(str_extract(embedding$Parameters,',\'fConstruction\'=>[0-9]+,'),'[0-9]+'),
       m=str_extract(str_extract(embedding$Parameters,',\'m\'=>[0-9]+'),'[0-9]+'),
       eS=substrRight(paste("  ",str_extract(str_extract(embedding$Parameters,'\'eSearch\'=>[0-9]+,'),'[0-9]+')),3)
       )
embeddingParm
embeddingParm<-mutate(embeddingParm,Legend=paste(paste('ef_const',embeddingParm@efC), paste('es',embeddingParm@eS)))

ggplot(data = embeddingParm) + 
  geom_point(mapping = aes(x = Recall, y = RecordsPerSecond,color=eS,shape=efC,size=m))

ggplot(data = embeddingParm) + 
  geom_point(mapping = aes(x = Recall, y = IndexTime,color=eS,shape=efC,size=m))

lantern <- resultsSorted[resultsSorted$Algorithm == 'lantern',]
lantern

outputFile <- paste(path,"benchmark.png", sep = "/")
png(outputFile, width=1920, height=1080)
#plot(x=c(0.989,1.001), y=c(1,1000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

#lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
#lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="green" ,type = "b",pch=4)
#lines(x=embedding$Recall, y=embedding$RecordsPerSecond, col="blue" ,type = "b",pch=5)
#lines(x=lantern$Recall, y=lantern$RecordsPerSecond, col="brown" ,type = "b",pch=6)

#legend(0.06, 20, legend=c("pgvector_hnsw", "gann_hnsw"),  
#       fill = c("red","blue") )
print(
  ggplot(resultsSorted, aes(x = Recall, y = RecordsPerSecond, color = Algorithm)) +
    geom_point(size=4) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_log10(limits=c(0.989, 1.001)) +
    scale_y_log10(limits=c(10, 1000)) +
    ggtitle("Query per seconds with different recall") +
    xlab("Recall") +
    ylab("Queries per second")
)
dev.off()

outputFile <- paste(path,"benchmark90-100.png", sep = "/")
png(outputFile, width=1920, height=1080)
#plot(x=c(0.989,1.001), y=c(1,1000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

#lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
#lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="green" ,type = "b",pch=4)
#lines(x=embedding$Recall, y=embedding$RecordsPerSecond, col="blue" ,type = "b",pch=5)
#lines(x=lantern$Recall, y=lantern$RecordsPerSecond, col="brown" ,type = "b",pch=6)

#legend(0.06, 20, legend=c("pgvector_hnsw", "gann_hnsw"),  
#       fill = c("red","blue") )
print(
  ggplot(resultsSorted, aes(x = Recall, y = RecordsPerSecond, color = Algorithm)) +
    geom_point(size=4) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_log10(limits=c(0.899, 1.001)) +
    scale_y_log10(limits=c(10, 1000)) +
    ggtitle("Query per seconds with different recall") +
    xlab("Recall") +
    ylab("Queries per second")
)
dev.off()

outputFile <- paste(path,"benchmark999.png", sep = "/")
png(outputFile, width=1920, height=1080)

#plot(x=c(0.989,1.001), y=c(1,1000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

#lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
#lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="green" ,type = "b",pch=4)
#lines(x=embedding$Recall, y=embedding$RecordsPerSecond, col="blue" ,type = "b",pch=5)
#lines(x=lantern$Recall, y=lantern$RecordsPerSecond, col="brown" ,type = "b",pch=6)

#legend(0.06, 20, legend=c("pgvector_hnsw", "gann_hnsw"),  
#       fill = c("red","blue") )
print(
  ggplot(resultsSorted, aes(x = Recall, y = RecordsPerSecond, color = Algorithm)) +
    geom_point(size=4) +
    geom_abline(intercept = 0, slope = 1, color = 'white') +
    scale_x_continuous(limits=c(0.9989, 1.0001)) +
    scale_y_continuous(limits=c(10, 250)) +
    ggtitle("Query per seconds with different recall") +
    xlab("Recall") +
    ylab("Queries per second")
)
dev.off()

outputFile <- paste(path,"benchmarkIndex.png", sep = "/")
png(outputFile)
plot(x=c(0.989,1.001), y=c(1,1000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Index creation time (seconds)")

lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$IndexTime, col="red" ,type = "l",pch=1)
#lines(x=pgvector_i$Recall, y=pgvector_i$IndexTime, col="green" ,type = "l",pch=4)
lines(x=embedding$Recall, y=embedding$IndexTime, col="blue" ,type = "l",pch=5)
#lines(x=lantern$Recall, y=lantern$IndexTime, col="brown" ,type = "b",pch=6)

legend(0.06, 10000, legend=c("pgvector_hnsw", "gann_hnsw"),  
       fill = c("red","blue") )
dev.off()

