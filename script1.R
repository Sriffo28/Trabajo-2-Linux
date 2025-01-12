#!/usr/bin/env Rscript
x=read.table("index.txt",header=F)
y=as.vector(read.table("values.txt",header=F))
datos=read.csv("mcdonalds_menu.csv")

datos=datos[x[[1]],]
datos$Serving.Size=y[[1]]
# eliminar columna item
datos=datos[-2]
# sanitizar nombre columnas
colnames(datos)[-1]=paste("col",1:22,sep="")
# Categorias a entero
datos$Category=as.integer(as.factor(datos$Category))
# guardar en mcdonalds_menu_2.csv
write.csv(datos,"mcdonalds_menu_2.csv",row.names=F)
