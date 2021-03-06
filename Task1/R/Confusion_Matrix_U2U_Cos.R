#-------------------------------------------------------------------
# FileName: Confusion_Matrix_U2U_Cos.R
# INPUT: The User Business Review Score CSV file, K value
# OUTPUT: Confusion Matrix
# Use: To obtain the confusion matrix for the most optimal value of K
#-------------------------------------------------------------------

rm(list=ls(all=TRUE))
require(data.table)
require(ggplot2)


topK <- 3

#--------------------------------------------------



data <- data.table::fread('C:/Users/Owner/eclipse-workspace-Java/final-Submission/userBusinessSentiment - SCNLP.csv')
data <- data.table::setDT(tidyr::spread(data,V2,V3))
data[is.na(data)] = 0.5
rowNames <- data$V1
rownames(data) <- data$V1
DATA <- copy(data)
data$V1 <- NULL
idx <- c()
for(row in 1:nrow(data)){
  idx <- c(idx,length(which(data[row] > 0.5)))
}
idx <- data.table::data.table(index = 1:nrow(data),len = idx)
test.idx <- idx[,which(len >=3)]
test <- data[test.idx,]
train <- data[-test.idx,]
Test <- copy(test) ## save keeping
for(row in 1:nrow(test)){
  col <- which(test[row,]>=0)
  change.col <- sample(col,floor(length(col) * .4))
  test[row,change.col] <- -1
}
N <- as.matrix(train) %*% t(as.matrix(test))
D <- sqrt(sum(as.matrix(test)^2)) * sqrt(sum(as.matrix(train)^2))
result <- as.data.table(N/D)
rowResult <- rowNames[-test.idx]
colnames(result) <- rowNames[test.idx]

finalResult <- data.frame(matrix(nrow = 0,ncol = ncol(data)))
colnames(finalResult) <- colnames(data)

for(col in colnames(result)){
  Rr <- data.table(Result = result[,get(col)],Name = rowResult)
  topKUsers <- head(Rr[order(-Result),Name],topK)
  res.dt <- merge(DATA[V1 %in% topKUsers],Rr[Name %in% topKUsers], all.x = T, by.x = 'V1', by.y='Name')
  selectCol <- setdiff(colnames(res.dt),c('Result','V1'))
  res.dt[, (selectCol) := lapply(.SD, function(x) 
    x * res.dt[['Result']] ), .SDcols = selectCol]
  # colSums(as.matrix(res.dt[,-c('V1','Result')]))/sum(Rr$Result)
  redt <- as.data.frame(res.dt)
  remo <- c("V1", "Result")
  finalResult <- rbind(finalResult,
                       as.data.frame(t(as.matrix(colSums(as.matrix(  as.data.table(redt[ , !(names(redt) %in% remo)])))/sum(Rr$Result)))))
}
rownames(finalResult) <- colnames(result)
result.final <-  copy(finalResult)

finalResult[finalResult < 0] <- -1
Test.df <- as.data.frame(Test)


#--------------------------------------------------


require(dplyr)
require(tidyr)
finalResult.g <- gather(finalResult, key = "key", value = "value")
finalResult.g$User <- as.data.frame(rep(c(row.names(finalResult)), dim(finalResult)[2]) )
finalResult.g <- finalResult.g[c(3,1,2)]
finalResult.g[finalResult.g$value == -1,3] <- 0
finalResult.g[finalResult.g$value < 1,3] <- 0
finalResult.g[finalResult.g$value != 0,3] <- 1

Test.df.g <- gather(Test.df, key = "key", value = "value")
Test.df.g$User <- as.data.frame(rep(c(row.names(finalResult)), dim(Test.df)[2]) )
Test.df.g <- Test.df.g[c(3,1,2)]

#Test.df.g <- Test.df.g[order(-Test.df.g$value),]
Test.df.g <- Test.df.g[order(Test.df.g$User),]
Test.df.g[Test.df.g$value == -1,3] <- 0
Test.df.g[Test.df.g$value == 0.5,3] <- 0
Test.df.g[Test.df.g$value > 0.5,3] <- 1

library(caret)
result <- confusionMatrix(finalResult.g$value, Test.df.g$value)
