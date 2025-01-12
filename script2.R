#!/usr/bin/env Rscript

install.packages("caret")
install.packages("kernlab")
install.packages("NeuralNetTools")
install.packages("party")
library(caret)
library(kernlab)
library(NeuralNetTools)
library(magrittr)
library(party)

datos=read.csv("./mcdonalds_menu_2.csv")
datos=datos %>% mutate(category=as.factor(Category))
datos=as_tibble(datos)

inTrain=createDataPartition(y=datos$category,p=0.8)[[1]]
datos_train=datos %>% slice(inTrain)
datos_test=datos %>% slice(-inTrain)
train_index=createFolds(datos_train$category, k = 10)

ctreeFit <- datos_train %>% train(category ~ .,
  method = "ctree",
  data = .,
  tuneLength = 5,
  trControl = trainControl(method = "cv", indexOut = train_index))

knnFit <- datos_train %>% train(category ~ .,
  method = "knn",
  data = .,
  preProcess = "scale",
  tuneLength = 5,
  tuneGrid = data.frame(k = 1:10),
  trControl = trainControl(method = "cv", indexOut = train_index))

svmFit <- datos_train %>% train(category ~ .,
  method = "svmLinear",
  data = .,
  tuneLength = 5,
  trControl = trainControl(method = "cv", indexOut = train_index))

nneFit <- datos_train %>% train(category ~ .,
  method = "nnet",
  data = .,
  tuneLength = 5,
  trControl = trainControl(method = "cv", indexOut = train_index),
  trace = FALSE)

resamps <- resamples(list(ctree = ctreeFit, SVM = svmFit, KNN = knnFit, NeuralNet = nneFit))
print(summary(resamps)$statistics$Accuracy[, "Mean"])
#  ctree      SVM       KNN    NeuralNet
#0.8921154 0.9916667 0.9791667 0.7306197
