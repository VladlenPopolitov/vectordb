datasetName <- "lastfm"
#datasetName <- "glove-100-a"
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
outputFile <- paste(path,"benchmark.png", sep = "/")
png(outputFile)
plot(x=c(0.1,1.1), y=c(1,60000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$IndexTime, col="green" ,type = "l",pch=1)
lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="black" ,type = "b",pch=4)
lines(x=pgvector_i$Recall, y=pgvector_i$IndexTime, col="blue" ,type = "l",pch=4)
legend(0.1, 900, legend=c("pgvector_hnsw recall", "pgvector_hnsw index time","pgvector_i recall", "pgvector_i index time"),  
       fill = c("red","green","black","blue") )
dev.off()




