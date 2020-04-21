##2019/1/8
##GEOоƬ���ݵ�ǰ�ڴ����Ͳ���������

##download GEO data
source("https://bioconductor.org/biocLite.R")
BiocManager::install('GEOquery')
BiocManager::install("GEOquery", version = "3.8")
library(GEOquery)
options( 'download.file.method.GEOquery' = 'libcurl' )  ##����ǽ���°�
gse010<-getGEO('GSE52139',destdir =".") ##����GSE�����������ݣ�����_series_matrix.txt.gz
gpl570<-getGEO('GPL570',destdir =".")    ##����GPL�����ص���оƬ��Ƶ���Ϣ, soft�ļ�

## ����R��
library(GEOquery)
## �������ݣ�����ļ������л�ֱ�Ӷ���
gset = getGEO('GSE52139', destdir='.',getGPL = F)
## ��ȡExpressionSet���󣬰����ı������ͷ�����Ϣ
index = gset@annotation

gse010<-getGEO(filename ='GSE52139_series_matrix.txt.gz')
gpl570<-getGEO(filename ='GPL570.soft') ## �������صı�������

##CEL�ļ�
BiocManager::install('affy')
library(BiocGenerics)
library(parallel)
library(Biobase)
library(affy)
setwd('E:/BaiduNetdiskDownload/RStudio/Ryj/GSE52139_RAW')
rawdata <- ReadAffy()
eset <- rma(rawdata)##eset <- mas5(rawdata) ##Background correcting;Normalizing;Calculating Expression
exprSet <- exprs(eset) ##ʹ��exprs��������ת���ɱ����׾���

##RcolorBrewer��ɫR��
library('RcolorBrewer') 
op <- par(mfrow=c(1,2))
cols <- brewer.pal(7, "Set3")
boxplot(rawdata52139,col=cols,names=1:7, main = "unnormalized.data")
boxplot(data.frame(exprs(eset)) ,names=1:7, main = "normalization.data", col="blue", border="brown")
par(op)

##����limma�����������
##�ο�http://blog.sciencenet.cn/blog-295006-403640.html
design <- model.matrix(~ -1+factor(c(1,1,2,2,2,2,2))) ##�����й���7��оƬ��ǰ2��Ϊcontrol�����飬��5��оƬΪʵ�鴦���飬��1��ʾ�����飬��2��ʾ������
colnames(design) <- c("control", "MS") 
contrast.matrix <- makeContrasts(control-MS, levels=design) ##
fit <- lmFit(eset, design)
fit <- eBayes(fit) 
fit2 <- contrasts.fit(fit, contrast.matrix)
fit2 <- eBayes(fit2)
results<-decideTests(fit2, method="global", adjust.method="BH", p.value=0.01, lfc=1.5) ##����pֵ��logFCֵ�����챶��Ҫ��õ��������
Output = topTable(fit2, coef=1, n=Inf)
summary(results)
getSQLiteFile()
x<-topTable(fit2, coef=1, number=10000, adjust.method="BH", sort.by="B", resort.by="M")
write.table(x, file="limma.xls", row.names=F, sep="t")

x$ID =rownames(x)
xID =merge(x=x,y=genename,by="ID",all.x =T)

###Probe IDת��Ϊsymbol
probe2symbol <- toTable(hgu133plus2SYMBOL)
exprSet <- as.data.frame(exprSet)
exprSet$probe_id <- rownames(exprSet)
exprSet_symbol <- merge(probe2symbol, exprSet, by = "probe_id")
dim(exprSet_symbol)
rownames(exprSet_symbol) <- exprSet_symbol$symbol 
exprSet_symbol <- exprSet_symbol[, -c(1,2)]

###����������
library(limma)
condition <- factor(c(rep("control", 2), rep("MS", 5)), levels = c("control", "MS"))
design <- model.matrix(~condition)
fit <- lmFit(exprSet_symbol, design)
fit=eBayes(fit)
output <- topTable(fit, coef=2,n=Inf)

heatDiagram(results,fit2$coef) ##��ͼ

###�ж��Ƿ���Ҫ��������ת��
ex <- exprSet
qx <- as.numeric(quantile(ex, c(0., 0.25, 0.5, 0.75, 0.99, 1.0), na.rm=T))
LogC <- (qx[5] > 100) ||
  (qx[6]-qx[1] > 50 && qx[2] > 0) ||
  (qx[2] > 0 && qx[2] < 1 && qx[4] > 1 && qx[4] < 2)
if (LogC) { ex[which(ex <= 0)] <- NaN
exprSet <- log2(ex)
print('log2 transform finished')}else{print('log2 transform not needed')}

###̽��ת�������ȥ��
library(dplyr)
library(tibble)
exprSet <-rownames_to_column(exprSet,var='probeset') 
##�ϲ�̽�����Ϣ
inner_join(probe2symbol,by='probeset')
##ȥ��������Ϣ
select(-probeset) 
##��������
select(symbol,everything()) 
##���ƽ����(��ߵĵ�Ŵ�����һ������������)
mutate(rowMean =rowMeans(.[grep('GSM', names(.))])) 
##ȥ��symbol�е�NA
filter(symbol != 'NA') 
##�ѱ�������ƽ��ֵ���Ӵ�С����
arrange(desc(rowMean)) 
##symbol���µ�һ��
distinct(symbol,.keep_all = T) 
##����ѡ��ȥ��rowMean��һ��
select(-rowMean) 
##�����������
column_to_rownames(var = 'symbol')


---------------------------------------------------------------------------
##upload 19.11.29
setwd("E:/BaiduNetdiskDownload/RStudio/Ryj/GSE52139_RAW")
library(limma)
exprSet<-read.table("GSE52139.txt",header = T)
design <- model.matrix(~ 0+factor(c(rep(c(1,0),8))))
colnames(design) <- c("MS", "control") 
cont.matrix <- makeContrasts(controlvsMS=MS-control, levels=design)
fit <- lmFit(exprSet, design)
fit2 <- contrasts.fit(fit, cont.matrix)
fit2 <- eBayes(fit2)
GSE52139_output<- topTable(fit2, adjust="BH", n=Inf)
GSE52139up_p0.05_1.5 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > log(1.5)/log(2) & GSE52139_output$P.Value<0.05,c(1,4)])
GSE52139dn_p0.05_1.5 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -log(1.5)/log(2) & GSE52139_output$P.Value<0.05,c(1,4)])

GSE52139up_p0.01 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > 1 & GSE52139_output$P.Value<0.01,c(1,4)])
GSE52139dn_p0.01 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -1 & GSE52139_output$P.Value<0.01,c(1,4)])

GSE52139up_p0.05 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > 1 & GSE52139_output$P.Value<0.05,c(1,4)])
GSE52139dn_p0.05 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -1 & GSE52139_output$P.Value<0.05,c(1,4)])

GSE52139up_p0.01_1.5 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > log(1.5)/log(2) & GSE52139_output$P.Value<0.01,c(1,4)])
GSE52139dn_p0.01_1.5 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -log(1.5)/log(2) & GSE52139_output$P.Value<0.01,c(1,4)])

write.table(GSE52139up_p0.05_1.5, "GSE52139up_p0.05_1.5.txt",quote = F,sep = "\t")
write.table(GSE52139dn_p0.05_1.5, "GSE52139dn_p0.05_1.5.txt",quote = F,sep = "\t")


GSE52139up_p0.25 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > log(1.5)/log(2) & GSE52139_output$P.Val<0.25,c(1,5)])
GSE52139dn_p0.25 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -log(1.5)/log(2) & GSE52139_output$P.Val<0.25,c(1,5)])

GSE52139up_0.05 <- as.data.frame(GSE52139_output[GSE52139_output$logFC > 1 & GSE52139_output$adj.P.Val<0.05,c(1,5)])
GSE52139dn_0.05 <- as.data.frame(GSE52139_output[GSE52139_output$logFC < -1 & GSE52139_output$adj.P.Val<0.05,c(1,5)])
write.table(GSE52139up_0.05, "GSE52139up_0.05.txt",quote = F,sep = "\t")
write.table(GSE52139dn_0.05, "GSE52139dn_0.05.txt",quote = F,sep = "\t")