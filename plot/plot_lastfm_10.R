getwd()
path <- "./Development/work/vectordb/vectordb/results/lastfm/10/"
print( path )
results <- read.csv(paste(path,"benchmark.csv", sep = ""), sep = "\t")
results
resultsSorted = results[order(results$Dataset,results$Algorithm, results$Recall,results$RecordsPerSecond),]
resultsSorted
pgvector_hnsw <- resultsSorted[resultsSorted$Algorithm == 'pgvector_hnsw',]
pgvector_hnsw
pgvector_i <- resultsSorted[resultsSorted$Algorithm == 'pgvector_i',]
pgvector_i
png(paste(path,"benchmark.png", sep = ""))
plot(x=c(0.1,1.1), y=c(10,10000), col="white" ,type = "b",pch=3,log="y",xlab="Recall",ylab="Queries per second")

lines(x=pgvector_hnsw$Recall, y=pgvector_hnsw$RecordsPerSecond, col="red" ,type = "b",pch=1)
lines(x=pgvector_i$Recall, y=pgvector_i$RecordsPerSecond, col="green" ,type = "b",pch=4)
legend(0.1, 100, legend=c("pgvector_hnsw", "pgvector_i"),  fill = c("red","green") )
dev.off()




