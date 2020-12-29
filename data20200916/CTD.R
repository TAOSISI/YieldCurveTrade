####################################################
# �����ӻع�ʮ���ڹ�ծ����������
# tcs,2020-06-10
# ��������
####################################################
# envrionment
setwd("D:\\qyzc\\ר��\\���������߶�ƽ")
rm(list=ls())
gc()

#��ȡ��
library(dplyr)
library(zoo)
library(graphics)
library(ggplot2)
library(PerformanceAnalytics)
library(TTR)

#��ȡ����
data1 <- read.csv("��ծ����.csv")
#data2 <- read.csv("׼������.csv")
head(data1)
#head(data2)
#data <- merge(data1, data2, by = "ָ������", all = TRUE)
#head(data)
#write.csv(data, "data.csv")

data1$date <- as.Date(data1$date)
data1$quan70 <- NA
data1$quan30 <- NA
for (i in c(40:nrow(data1))) {
  data1$quan70[i] <- quantile(data1$R.5M[(i-39):i], 0.7, na.rm = TRUE)
  data1$quan30[i] <- quantile(data1$R.5M[(i-39):i], 0.3, na.rm = TRUE)
}
#write.csv(data1, "data.csv")

#����1
head(data1)
data1$change <- data1$X10_5-lag(data1$X10_5)
data1 <- subset(data1,data1$date > as.Date('2010-01-01'))
data1 <- as.data.frame(data1 %>% mutate(position = ifelse(R.5M > quan70, -1,ifelse(R.5M < quan30, 1,0))))
data1$position <- lag(data1$position)
data1$position[1] <- -1

#��������������
data1$return <- data1$position*data1$change
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date,cumret)) + geom_line()
#write.csv(data1, "data1.csv")


#����2








###����������###################################
#��ȡ����
data1 <- read.csv("TDInfo2020-09-16.csv")
head(data1)
# data1$LASTDELIVERY_DATE <- as.Date(paste(substr(data1$LASTDELIVERY_DATE,1,4),
#                                          substr(data1$LASTDELIVERY_DATE,5,6),
#                                          substr(data1$LASTDELIVERY_DATE,7,8),sep = "-"))
data1$LASTDELIVERY_DATE <- as.Date(data1$LASTDELIVERY_DATE)
data1$anal_precupn <- as.Date(data1$anal_precupn)
data1$nxcupn <- as.Date(data1$nxcupn)
#����󽻸���������ڶ������գ������󽻸�������һ��������ȥ3����������������ȥ1
data1$weekday <- weekdays(data1$LASTDELIVERY_DATE)
data1 <- as.data.frame(data1 %>% mutate(SCDDELIVERY_DATE = LASTDELIVERY_DATE-1))
data2 <- read.csv("CFInfo2020-09-14.csv")
#������Լ
#data3 <- read.csv("FutureClose2020-09-16.csv")
#������Լ
#data4 <- read.csv("LXFutureClose2020-09-16.csv")
head(data2)
#data3$date_id <- as.Date(data3$date_id)
#head(data3)
data <- merge(data1,data2,by = c("sec_name","bond_cd"),all = TRUE)
#data <- merge(data,data3,by = "sec_name", all = TRUE)
#data4$date_id <- as.Date(data4$date_id)
#head(data4)
#data <- merge(data,data4,by = "sec_name", all = TRUE)
#������Լ
data5 <- read.csv("ADPFutureClose2020-09-16.csv")
data5$date_id <- as.Date(data5$date_id)
data <- merge(data,data5,by = "sec_name", all = TRUE)
head(data)
data$irret <- NA
irr <- function(CouponRate,CF,PTMYear,SCDDeliveryDate,InterestfreQuency,SettlePrice,NXCUPN,ANAL_PRECUPN){
  #cfΪ�ֽ���������Ϊһ����������
  # CouponRate = 3.59
  # InterestfreQuency=2
  # PTMYear=6.632877
  # CF = 1.0354
  # SettlePrice = 97.9
  # SecondDeliveryDate = as.Date('2020-12-15')
  # NXCUPN = as.Date('2021-02-03')
  # ANAL_PRECUPN = as.Date('2020-08-03')
  SecondDeliveryDate = SCDDeliveryDate
  cf = rep(CouponRate/InterestfreQuency,ceiling(PTMYear*InterestfreQuency))
  cf[length(cf)] = cf[length(cf)] + 100
  AI = CouponRate/InterestfreQuency*as.numeric(SecondDeliveryDate - ANAL_PRECUPN)/as.numeric(NXCUPN - ANAL_PRECUPN)
  PV = CF*SettlePrice+AI
  N <- length(cf) - 1
  n <- 0 : N
  f <- function(r, n) (1 + r/InterestfreQuency)^(n+as.numeric(NXCUPN-SecondDeliveryDate)/as.numeric(NXCUPN - ANAL_PRECUPN))
  r <- seq(0.0001,1,0.0001)
  pv <- cf / t(outer(r, n, f))
  npv <- colSums(pv)-PV
  irr <- r[abs(npv) == min(abs(npv))]
  return(irr)
}

for (i in c(1:length(data$sec_name))) {
  #i=1
  irret = irr(CouponRate = data$couponrate[i],CF = data$cf[i],PTMYear = data$ptmyear[i],
              SCDDeliveryDate = data$SCDDELIVERY_DATE[i],InterestfreQuency = data$interestfrequency[i],
              SettlePrice = data$settle[i],NXCUPN = data$nxcupn[i],ANAL_PRECUPN = data$anal_precupn[i])
  data$irret[i] = irret
}
data <- na.omit(data)
# ������������������ծȯһ���������ɽ���ȯ����������������������ȯ����Ӧ�����������ʵ�ƽ��ֵ��Ϊ�ڻ�������������
data <- as.data.frame(data %>% group_by(date_id,sec_name) %>% mutate(CTDRank = rank(irret,ties.method = c("first"))))
result <- aggregate(data = subset(data,CTDRank <= 3), irret~date_id+sec_name, mean)
write.csv(result,'irret.csv')
write.csv(data,'data.csv')






####����2##################################
data1 <- read.csv("T_TFirret.csv")
head(data1)
data1$date_id <- as.Date(data1$date_id)
data1$quan90 <- NA
data1$quan80 <- NA
data1$quan70 <- NA
data1$quan60 <- NA
data1$quan50 <- NA
data1$quan40 <- NA
data1$quan30 <- NA
data1$quan20 <- NA
data1$quan10 <- NA
# ��ȥ30�������յ�30%��70%��λ����Ϊ���߽��׵��ж�����
for (i in c(40:nrow(data1))) {
  data1$quan90[i] <- quantile(data1$FutYHret[(i-39):i], 0.9, na.rm = TRUE)
  data1$quan80[i] <- quantile(data1$FutYHret[(i-39):i], 0.8, na.rm = TRUE)
  data1$quan70[i] <- quantile(data1$FutYHret[(i-39):i], 0.7, na.rm = TRUE)
  data1$quan60[i] <- quantile(data1$FutYHret[(i-39):i], 0.6, na.rm = TRUE)
  data1$quan50[i] <- quantile(data1$FutYHret[(i-39):i], 0.5, na.rm = TRUE)
  data1$quan40[i] <- quantile(data1$FutYHret[(i-39):i], 0.4, na.rm = TRUE)
  data1$quan30[i] <- quantile(data1$FutYHret[(i-39):i], 0.3, na.rm = TRUE)
  data1$quan20[i] <- quantile(data1$FutYHret[(i-39):i], 0.2, na.rm = TRUE)
  data1$quan10[i] <- quantile(data1$FutYHret[(i-39):i], 0.1, na.rm = TRUE)
}
# write.csv(data1, "data2.csv")

# ����1
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# ��ȡ��ծ�ڻ��۸�
priceData <- read.csv("ADPFutureClose2020-09-16.csv")
head(priceData)
priceData$date_id <- as.Date(priceData$date_id)
names(priceData)[5] <- "T_name"
data1 <- merge(data1,priceData,by = c("date_id","T_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret",
                  "quan90","quan80","quan70","quan60","quan50","quan40","quan30","quan20","quan10")]
names(data1)[4:5] <- c("T_close","T_settle")
names(priceData)[5] <- "TF_name"    
data1 <- merge(data1,priceData,by = c("date_id","TF_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret",
                  "quan90","quan80","quan70","quan60","quan50","quan40","quan30","quan20","quan10")]
names(data1)[8:9] <- c("TF_close","TF_settle")

data1 <- as.data.frame(data1 %>% mutate(position_T90 = ifelse(FutYHret > quan90, -1,ifelse(FutYHret < quan10, 1,0)),
                                        position_TF90 = ifelse(FutYHret > quan90, 2, ifelse(FutYHret < quan10, -2,0)),
                                        position_T80 = ifelse(FutYHret > quan80, -1,ifelse(FutYHret < quan20, 1,0)),
                                        position_TF80 = ifelse(FutYHret > quan80, 2, ifelse(FutYHret < quan20, -2,0)),
                                        position_T70 = ifelse(FutYHret > quan70, -1,ifelse(FutYHret < quan30, 1,0)),
                                        position_TF70 = ifelse(FutYHret > quan70, 2, ifelse(FutYHret < quan30, -2,0)),
                                        position_T60 = ifelse(FutYHret > quan60, -1,ifelse(FutYHret < quan40, 1,0)),
                                        position_TF60 = ifelse(FutYHret > quan60, 2, ifelse(FutYHret < quan40, -2,0)),
                                        position_T50 = ifelse(FutYHret > quan50, -1,ifelse(FutYHret < quan50, 1,0)),
                                        position_TF50 = ifelse(FutYHret > quan50, 2, ifelse(FutYHret < quan50, -2,0))))
head(data1)
#�������ʱ���Դ�Χ���֣���С��Χƽ��
data1 <- as.data.frame(data1 %>% mutate(position_T = ifelse(position_T90==1&POSITION_T80),
                                        position_TF = position_TF90))
data1$lag_position_T <- lag(data1$position_T)
data1$lag_position_TF <- lag(data1$position_TF)
data1$lag_position_T[1] <- 0
data1$lag_position_TF[1] <- 0
data1$change_T <- data1$T_settle - lag(data1$T_settle)
data1$change_TF <- data1$TF_settle - lag(data1$TF_settle)
data1$return <- data1$lag_position_T*data1$change_T + data1$lag_position_TF*data1$change_TF
data1$return[1] <- 0
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date_id,cumret)) + geom_line()

#�����Լ����ʱ�˻����
data1$ZHJE <- 1000000
#�����Լ��������
data1$KCSS <- 0
for (i in c(2:length(data1$date_id))) {
  # i=286
  if(data1$lag_position_T[i-1]==0 & data1$lag_position_T[i]!=0){
    data1$KCSS[i] = floor(data1$ZHJE[i-1]/max(2*0.012*data1$T_close[i]*10000,0.02*data1$T_close[i]*10000))
    data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_close[i]-data1$T_close[i-1])+
                    10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_close[i]-data1$TF_close[i-1]) + data1$ZHJE[i-1]
  }
  else{
    if(data1$lag_position_T[i-1]!=0 & data1$lag_position_T[i]!=0){
      data1$KCSS[i] = data1$KCSS[i-1]
      data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_close[i]-data1$T_close[i-1])+
        10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_close[i]-data1$TF_close[i-1]) + data1$ZHJE[i-1]
    }
    else{
      data1$KCSS[i] = 0
      data1$ZHJE[i] = data1$ZHJE[i-1]
    }
  }
}
ggplot(data = data1,aes(date_id,ZHJE)) + geom_line()
data1$date_id <- as.Date(data1$date_id)
data1$return <- data1$ZHJE/lag(data1$ZHJE)-1
data1$return[1] <- 0
maxDrawdown(data1$return)
Return.annualized(data1$return,scale = 252)















####����3####################################################
#�Թ�ծ��ȯ�����ʲ�����
data1 <- read.csv("T_TFirret.csv")
data2 <- read.csv("��ծ����.csv")
head(data1)
head(data2)
data1$date_id <- as.Date(data1$date_id)
data2$date_id <- as.Date(data2$date)
data1 <- merge(data1,data2[,c("date_id","X10_5")])
data1$quan70 <- NA
data1$quan30 <- NA
data1$quan50 <- NA
# ��ȥ30�������յ�30%��70%��λ����Ϊ���߽��׵��ж�����
for (i in c(10:nrow(data1))) {
  data1$quan70[i] <- quantile(data1$X10_5[(i-9):i], 0.7, na.rm = TRUE)
  data1$quan30[i] <- quantile(data1$X10_5[(i-9):i], 0.3, na.rm = TRUE)
  data1$quan50[i] <- quantile(data1$X10_5[(i-9):i], 0.5, na.rm = TRUE)
}
# write.csv(data1, "data2.csv")

# ����1
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# ��ȡ��ծ�ڻ��۸�
priceData <- read.csv("ADPFutureClose2020-09-16.csv")
head(priceData)
priceData$date_id <- as.Date(priceData$date_id)
names(priceData)[5] <- "T_name"    
data1 <- merge(data1,priceData,by = c("date_id","T_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret","X10_5","quan70","quan30","quan50")]
names(data1)[4:5] <- c("T_close","T_settle")
names(priceData)[5] <- "TF_name"    
data1 <- merge(data1,priceData,by = c("date_id","TF_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret","X10_5","quan70","quan30","quan50")]
names(data1)[8:9] <- c("TF_close","TF_settle")

data1 <- as.data.frame(data1 %>% mutate(position_T = ifelse(FutYHret > quan70, -1,ifelse(FutYHret < quan30, 1,0)),
                                        position_TF = ifelse(FutYHret > quan70, 2, ifelse(FutYHret < quan30, -2,0))))
data1 <- as.data.frame(data1 %>% mutate(position_T1 = ifelse(dplyr::lag(position_T)==-1&FutYHret>quan50,-1,ifelse(dplyr::lag(position_T)==1&FutYHret<quan50,1,position_T)),
                                        position_TF1 = ifelse(dplyr::lag(position_TF)==-2&FutYHret<quan50,-2,ifelse(dplyr::lag(position_TF)==2&FutYHret>quan50,2,position_TF))))
data1 <- as.data.frame(data1 %>% mutate(position_T2 = ifelse(dplyr::lag(position_T1)==-1&FutYHret>quan50,-1,ifelse(dplyr::lag(position_T1)==1&FutYHret<quan50,1,position_T1)),
                                        position_TF2 = ifelse(dplyr::lag(position_TF1)==-2&FutYHret<quan50,-2,ifelse(dplyr::lag(position_TF1)==2&FutYHret>quan50,2,position_TF1))))

data1$lag_position_T <- lag(data1$position_T)
data1$lag_position_TF <- lag(data1$position_TF)
data1$lag_position_T[1:3] <- 0
data1$lag_position_TF[1:3] <- 0
data1$change_T <- data1$T_settle - lag(data1$T_settle)
data1$change_TF <- data1$TF_settle - lag(data1$TF_settle)
data1$return <- data1$lag_position_T*data1$change_T + data1$lag_position_TF*data1$change_TF
data1$return[1] <- 0
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date_id,cumret)) + geom_line()

#�����Լ����ʱ�˻����
data1$ZHJE <- 1000000
#�����Լ��������
data1$KCSS <- 0
for (i in c(2:length(data1$date_id))) {
  # i=2
  if(data1$lag_position_T[i-1]==0 & data1$lag_position_T[i]!=0){
    data1$KCSS[i] = floor(data1$ZHJE[i-1]/max(2*0.012*data1$TF_settle[i]*10000,0.02*data1$T_settle[i]*10000))
    data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
      10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
  }
  else{
    if(data1$lag_position_T[i-1]!=0 & data1$lag_position_T[i]!=0){
      data1$KCSS[i] = data1$KCSS[i-1]
      data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
        10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
    }
    else{
      data1$KCSS[i] = 0
      data1$ZHJE[i] = data1$ZHJE[i-1]
    }
  }
}
ggplot(data = data1,aes(date_id,ZHJE)) + geom_line()
data1$date_id <- as.Date(data1$date_id)
data1$return <- data1$ZHJE/lag(data1$ZHJE)-1
data1$return[1] <- 0
maxDrawdown(data1$return)
Return.annualized(data1$return,scale = 252)




###˫���߽���4########################################
data1 <- read.csv("T_TFirret.csv")
head(data1)
data1 <- na.omit(data1)
data1$date_id <- as.Date(data1$date_id)
ggplot(data = data1,aes(date_id,FutYHret)) + geom_line()
ggplot(data = data1,aes(date_id,X10_5)) + geom_line()
# ��ȥ��ͬ�����ֵ
data1 <- as.data.frame(data1 %>% mutate(sma90 = SMA(FutYHret,n=90),sma80 = SMA(FutYHret,n=80),sma70 = SMA(FutYHret,n=70),
                                        sma60 = SMA(FutYHret,n=60),sma50 = SMA(FutYHret,n=50),sma40 = SMA(FutYHret,n=40),
                                        sma30 = SMA(FutYHret,n=30),sma20 = SMA(FutYHret,n=20),sma10 = SMA(FutYHret,n=10)))
# write.csv(data1, "data2.csv")

# ����
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# ��ȡ��ծ�ڻ��۸�
priceData <- read.csv("ADPFutureClose2020-09-16.csv")
head(priceData)
priceData$date_id <- as.Date(priceData$date_id)
names(priceData)[5] <- "T_name"
data1 <- merge(data1,priceData,by = c("date_id","T_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret",
                  "sma90","sma80","sma70","sma60","sma50","sma40","sma30","sma20","sma10")]
names(data1)[4:5] <- c("T_close","T_settle")
names(priceData)[5] <- "TF_name"    
data1 <- merge(data1,priceData,by = c("date_id","TF_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret",
                  "sma90","sma80","sma70","sma60","sma50","sma40","sma30","sma20","sma10")]
names(data1)[8:9] <- c("TF_close","TF_settle")
#����������ϴ������������࣬�������´�������������
data1 <- as.data.frame(data1 %>% mutate(position_T = ifelse(sma20 > sma50, -1,ifelse(sma20 < sma50, 1,0)),
                                        position_TF = ifelse(sma20 > sma50, 2, ifelse(sma20 < sma50, -2,0))))
data1$lag_position_T <- lag(data1$position_T)
data1$lag_position_TF <- lag(data1$position_TF)
data1$lag_position_T[1] <- 0
data1$lag_position_TF[1] <- 0
data1$change_T <- data1$T_settle - lag(data1$T_settle)
data1$change_TF <- data1$TF_settle - lag(data1$TF_settle)
data1$return <- data1$lag_position_T*data1$change_T + data1$lag_position_TF*data1$change_TF
data1$return[1] <- 0
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date_id,cumret)) + geom_line()

#�����Լ����ʱ�˻����
data1$ZHJE <- 1000000
#�����Լ��������
data1$KCSS <- 0
for (i in c(2:length(data1$date_id))) {
  # i=2
  if(data1$lag_position_T[i-1]==0 & data1$lag_position_T[i]!=0){
    data1$KCSS[i] = floor(data1$ZHJE[i-1]/max(2*0.012*data1$TF_settle[i]*10000,0.02*data1$T_settle[i]*10000))
    data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
      10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
  }
  else{
    if(data1$lag_position_T[i-1]!=0 & data1$lag_position_T[i]!=0){
      data1$KCSS[i] = data1$KCSS[i-1]
      data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
        10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
    }
    else{
      data1$KCSS[i] = 0
      data1$ZHJE[i] = data1$ZHJE[i-1]
    }
  }
}
ggplot(data = data1,aes(date_id,ZHJE)) + geom_line()
data1$date_id <- as.Date(data1$date_id)
data1$return <- data1$ZHJE/lag(data1$ZHJE)-1
data1$return[1] <- 0
maxDrawdown(data1$return)
Return.annualized(data1$return,scale = 252)




#���ڴ�����س���������ߵ�֮�����������̫С�����ֻ��Ƶ�������ӽ��׳ɱ����������������ڣ�������Ʒ�Χ��С����ץ��ס����������飬
#���������߶�����ߵ㣬����������ʧ��������Ʒ�Χ̫����ƽ�ֲ���ʱ���װ���ʧ����
data1 <- read.csv("T_TFirret.csv")
head(data1)
data1$date_id <- as.Date(data1$date_id)
data1 <- na.omit(data1)
# ��ȡ��ծ�ڻ��۸�
priceData <- read.csv("ADPFutureClose2020-09-16.csv")
head(priceData)
priceData$date_id <- as.Date(priceData$date_id)
names(priceData)[5] <- "T_name"
data1 <- merge(data1,priceData,by = c("date_id","T_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret","X10_5")]
names(data1)[4:5] <- c("T_close","T_settle")
names(priceData)[5] <- "TF_name"    
data1 <- merge(data1,priceData,by = c("date_id","TF_name"),all.x = TRUE)
data1 <- data1[,c("date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret","X10_5")]
names(data1)[8:9] <- c("TF_close","TF_settle")
#######��������###################
#KD����ָ���Ϊ�������Ծ��н����ԵĲ����߽�����ơ�
#KDָ�����
#����FutYHretΪ�۲����У� rsv ָ��Ϊ��ǰ�۲����ȥ N ����Сֵ�Ĳ����ȥ N �����ֵ����Сֵ��ı�����
#�����������и�ֵ������ 1�����µ������и�ֵ������ 0��K ָ��Ϊ rsv ��ȥ m ��ľ�ֵ�� D ָ��Ϊ K ָ���ȥ m ��ľ�ֵ��
data1$rsv <- NA
data1$K <- NA
data1$D <- NA
# ��ȥ30�������յĵ�KDָ��
N = 30
m = 10
for (i in c(N:nrow(data1))) {
  data1$rsv[i] <- (data1$FutYHret - min(data1$FutYHret[(i-N+1):i]))/(max(data1$FutYHret[(i-N+1):i]) - min(data1$FutYHret[(i-N+1):i]))
  data1$K[i] <- mean(data1$rsv[(i-m+1):i])
  data1$D[i] <- mean(data1$K[(i-m+1):i])
}
#����Ӧ����AMA����
#dl��ʾ n ��ľ��۸�䶯�� vt��ʾ n ��۸�仯���ۺϣ���ʾ�г����������� n ���ݲ�ͬƷ����ϵļ۲��ֵ�ظ�ʱ��������ѡ��.
n = 10
Nf = 60
Ns = 4
data1$DL <- NA
data1$vt <- NA
data1$ER <- NA
data1$smooth <- NA
data1$C <- NA
data1$AMA <- 0
for (i in c(n:nrow(data1))) {
  fastest = 2/(Nf+1)
  slowest = 2/(Ns+1)
  data1$DL[i] <- abs(data1$FutYHret[i] - data1$FutYHret[i-n+1])
  data1$vt[i] <- sum(abs(diff(data1$FutYHret[(i-n+1):i])))
  data1$ER[i] = data1$DL[i]/data1$vt[i]
  data1$smooth[i] = data1$ER[i]*(fastest-slowest)+slowest
  data1$C[i] = data1$smooth[i]*data1$smooth[i]
  data1$AMA[i] = data1$AMA[i-1]+data1$C[i]*(data1$FutYHret[i]-data1$AMA[i-1])
}
#�����ź�
#1.�����ź�
#�����ʷ�ϼ�ֵ��ķֲ��Ƚ��ȶ�����ʹ�� KD ָ�����������źŵ��жϡ�
#���۲����һ��ˮƽ��ͬʱ KD ָ��� K �����´�Խ D ��ʱ���������ռ۲
#���۲�С��һ��ˮƽ��ͬʱ KD ָ��� K �����ϴ�Խ D ��ʱ����������۲
#�����ʷ�ϼ�ֵ��ķֲ����Ǻ��ȶ���������һ���ϴ�ķ�Χ�ڲ�������ʹ������Ӧ���������źŵ��жϡ�
#���۲��������������Χ���Ϲ죬ͬʱ����Ӧ�������¹�ͷʱ���� AMAt-1 < AMAt-2�� AMAt-2 > AMAt-3ʱ�����ռ۲
#���۲�С������������Χ���¹죬ͬʱ����Ӧ�������Ϲ�ͷʱ���� AMAt-1 > AMAt-2�� AMAt-2 < AMAt-3ʱ����������۲
#2.ƽ���ֲ�λ�ź�
#���ռ۲���ڼ۲�δ�ع鵽��������ˮƽʱ����� AMAt-1 > AMAt-2 ��AMAt-2 < AMAt-3ʱ����ƽ�����ֲ�λ��
#����۲���ڼ۲�δ�ع鵽��������ˮƽʱ����� AMAt-1 < AMAt-2�� AMAt-2 > AMAt-3ʱ����ƽ�����ֲ�λ��

#3.ֹ���ź�
#����ʹ�� KD ָ�������������λ��
#��������ռ۲�Ĳ�λ����ô�ڼ۲����ʷ�¸ߺ�ֹ��ƽ�֣�
#���������۲�Ĳ�λ����ô�ڼ۲����ʷ�µͺ�ֹ��ƽ�֡�

#����ʹ������Ӧ������Ϊ�źſ��ֵĲ�λ��
#��������ռ۲�Ĳ�λ����ô������Ӧ���ߵ�ֵ���ڿ���ʱ����Ӧ���ߵ�ֵʱ��ֹ��ƽ�֣�
#���������۲�Ĳ�λ����ô������Ӧ���ߵ�ֵС�ڿ���ʱ����Ӧ���ߵ�ֵʱ��ֹ��ƽ�֡�
#4.ֹӯ�ź�
#�������ռ۲������۲����С�� Ma+CP_Short *Std ʱ���� �� �� ֹ ӯ �� �� ֹ ӯ ƽ �� ��
#��������۲������۲����Ǵ��� Ma+CP_Long *Stdʱ��������ֹӯ����ֹӯƽ��

#������ʷ��ֵ��ķֲ�
ggplot(data = data1,aes(date_id,FutYHret)) + geom_line()
ggplot(data = data1,aes(date_id,X10_5)) + geom_line()

#���谴����ʷ��ֵ��ֲ���Ϊ�ȶ����жϣ�ʹ��KDָ���������źŵ��жϡ�
# write.csv(data1, "data2.csv")
#�۲��ˮƽʹ����ʷ30���ֵ�İٷ�λ����Ϊ�жϡ�����70%��30%��90%��10%��
data1$quan90 <- NA
data1$quan80 <- NA
data1$quan70 <- NA
data1$quan60 <- NA
data1$quan50 <- NA
data1$quan40 <- NA
data1$quan30 <- NA
data1$quan20 <- NA
data1$quan10 <- NA
# ��ȥ30�������յİٷ�λ����Ϊ���߽��׵��ж�����
M=30
for (i in c(M:nrow(data1))) {
  data1$quan90[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.9, na.rm = TRUE)
  data1$quan80[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.8, na.rm = TRUE)
  data1$quan70[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.7, na.rm = TRUE)
  data1$quan60[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.6, na.rm = TRUE)
  data1$quan50[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.5, na.rm = TRUE)
  data1$quan40[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.4, na.rm = TRUE)
  data1$quan30[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.3, na.rm = TRUE)
  data1$quan20[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.2, na.rm = TRUE)
  data1$quan10[i] <- quantile(data1$FutYHret[(i-M+1):i], 0.1, na.rm = TRUE)
}
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))

#����������ϴ������������࣬�������´�������������
data1 <- as.data.frame(data1 %>% mutate(position_T = ifelse(FutYHret>quan70 & K>D, -1, ifelse(FutYHret<quan30 & K<D, -1, 0)),
                                        position_TF = ifelse(FutYHret>quan70 & K>D, -2, ifelse(FutYHret<quan30 & K<D, 2, 0))))
data1$lag_position_T <- lag(data1$position_T)
data1$lag_position_TF <- lag(data1$position_TF)
data1$lag_position_T[1] <- 0
data1$lag_position_TF[1] <- 0
data1$change_T <- data1$T_settle - lag(data1$T_settle)
data1$change_TF <- data1$TF_settle - lag(data1$TF_settle)
data1$return <- data1$lag_position_T*data1$change_T + data1$lag_position_TF*data1$change_TF
data1$return[1] <- 0
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date_id,cumret)) + geom_line()
#�����Լ����ʱ�˻����
data1$ZHJE <- 1000000
#�����Լ��������
data1$KCSS <- 0
for (i in c(2:length(data1$date_id))) {
  # i=2
  if(data1$lag_position_T[i-1]==0 & data1$lag_position_T[i]!=0){
    data1$KCSS[i] = floor(data1$ZHJE[i-1]/max(2*0.012*data1$TF_settle[i]*10000,0.02*data1$T_settle[i]*10000))
    data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
      10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
  }
  else{
    if(data1$lag_position_T[i-1]!=0 & data1$lag_position_T[i]!=0){
      data1$KCSS[i] = data1$KCSS[i-1]
      data1$ZHJE[i] = 10000*data1$KCSS[i]*data1$lag_position_T[i]*(data1$T_settle[i]-data1$T_settle[i-1])+
        10000*data1$KCSS[i]*data1$lag_position_TF[i]*(data1$TF_settle[i]-data1$TF_settle[i-1]) + data1$ZHJE[i-1]
    }
    else{
      data1$KCSS[i] = 0
      data1$ZHJE[i] = data1$ZHJE[i-1]
    }
  }
}
ggplot(data = data1,aes(date_id,ZHJE)) + geom_line()
data1$date_id <- as.Date(data1$date_id)
data1$return <- data1$ZHJE/lag(data1$ZHJE)-1
data1$return[1] <- 0
maxDrawdown(data1$return)
Return.annualized(data1$return,scale = 252)














