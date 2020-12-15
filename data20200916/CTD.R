####################################################
# 用因子回归十年期国债到期收益率
# tcs,2020-06-10
# 后续跟踪
####################################################
# envrionment
setwd("D:\\qyzc\\专题\\收益率曲线陡平")
rm(list=ls())
gc()

#读取包
library(dplyr)
library(zoo)
library(graphics)
library(ggplot2)
library(PerformanceAnalytics)
library(TTR)

#读取数据
data1 <- read.csv("国债到期.csv")
#data2 <- read.csv("准备金率.csv")
head(data1)
#head(data2)
#data <- merge(data1, data2, by = "指标名称", all = TRUE)
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

#交易1
head(data1)
data1$change <- data1$X10_5-lag(data1$X10_5)
data1 <- subset(data1,data1$date > as.Date('2010-01-01'))
data1 <- as.data.frame(data1 %>% mutate(position = ifelse(R.5M > quan70, -1,ifelse(R.5M < quan30, 1,0))))
data1$position <- lag(data1$position)
data1$position[1] <- -1

#计算收益率曲线
data1$return <- data1$position*data1$change
data1$cumret <- cumsum(data1$return)
ggplot(data = data1,aes(date,cumret)) + geom_line()
#write.csv(data1, "data1.csv")


#交易2








###隐含收益率###################################
#读取数据
data1 <- read.csv("TDInfo2020-09-16.csv")
head(data1)
# data1$LASTDELIVERY_DATE <- as.Date(paste(substr(data1$LASTDELIVERY_DATE,1,4),
#                                          substr(data1$LASTDELIVERY_DATE,5,6),
#                                          substr(data1$LASTDELIVERY_DATE,7,8),sep = "-"))
data1$LASTDELIVERY_DATE <- as.Date(data1$LASTDELIVERY_DATE)
data1$anal_precupn <- as.Date(data1$anal_precupn)
data1$nxcupn <- as.Date(data1$nxcupn)
#由最后交割日推算出第二交割日，如果最后交割日是周一则天数减去3如果是其他天数则减去1
data1$weekday <- weekdays(data1$LASTDELIVERY_DATE)
data1 <- as.data.frame(data1 %>% mutate(SCDDELIVERY_DATE = LASTDELIVERY_DATE-1))
data2 <- read.csv("CFInfo2020-09-14.csv")
#主力合约
#data3 <- read.csv("FutureClose2020-09-16.csv")
#连续合约
#data4 <- read.csv("LXFutureClose2020-09-16.csv")
head(data2)
#data3$date_id <- as.Date(data3$date_id)
#head(data3)
data <- merge(data1,data2,by = c("sec_name","bond_cd"),all = TRUE)
#data <- merge(data,data3,by = "sec_name", all = TRUE)
#data4$date_id <- as.Date(data4$date_id)
#head(data4)
#data <- merge(data,data4,by = "sec_name", all = TRUE)
#连续合约
data5 <- read.csv("ADPFutureClose2020-09-16.csv")
data5$date_id <- as.Date(data5$date_id)
data <- merge(data,data5,by = "sec_name", all = TRUE)
head(data)
data$irret <- NA
irr <- function(CouponRate,CF,PTMYear,SCDDeliveryDate,InterestfreQuency,SettlePrice,NXCUPN,ANAL_PRECUPN){
  #cf为现金流，可作为一个向量输入
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
# 由于隐含收益率最大的债券一般是最廉可交割券，计算最廉，次廉和三廉券所对应的隐含收益率的平均值作为期货的隐含收益率
data <- as.data.frame(data %>% group_by(date_id,sec_name) %>% mutate(CTDRank = rank(irret,ties.method = c("first"))))
result <- aggregate(data = subset(data,CTDRank <= 3), irret~date_id+sec_name, mean)
write.csv(result,'irret.csv')
write.csv(data,'data.csv')






####交易2##################################
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
# 过去30个交易日的30%和70%分位点作为曲线交易的判断依据
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

# 交易1
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# 读取国债期货价格
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
#开仓入局时，以大范围开仓，但小范围平仓
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

#计算合约开仓时账户金额
data1$ZHJE <- 1000000
#计算合约开仓手数
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















####交易3####################################################
#以国债现券收益率差额计算
data1 <- read.csv("T_TFirret.csv")
data2 <- read.csv("国债到期.csv")
head(data1)
head(data2)
data1$date_id <- as.Date(data1$date_id)
data2$date_id <- as.Date(data2$date)
data1 <- merge(data1,data2[,c("date_id","X10_5")])
data1$quan70 <- NA
data1$quan30 <- NA
data1$quan50 <- NA
# 过去30个交易日的30%和70%分位点作为曲线交易的判断依据
for (i in c(10:nrow(data1))) {
  data1$quan70[i] <- quantile(data1$X10_5[(i-9):i], 0.7, na.rm = TRUE)
  data1$quan30[i] <- quantile(data1$X10_5[(i-9):i], 0.3, na.rm = TRUE)
  data1$quan50[i] <- quantile(data1$X10_5[(i-9):i], 0.5, na.rm = TRUE)
}
# write.csv(data1, "data2.csv")

# 交易1
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# 读取国债期货价格
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

#计算合约开仓时账户金额
data1$ZHJE <- 1000000
#计算合约开仓手数
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




###双均线交易4########################################
data1 <- read.csv("T_TFirret.csv")
head(data1)
data1 <- na.omit(data1)
data1$date_id <- as.Date(data1$date_id)
ggplot(data = data1,aes(date_id,FutYHret)) + geom_line()
ggplot(data = data1,aes(date_id,X10_5)) + geom_line()
# 过去不同区间均值
data1 <- as.data.frame(data1 %>% mutate(sma90 = SMA(FutYHret,n=90),sma80 = SMA(FutYHret,n=80),sma70 = SMA(FutYHret,n=70),
                                        sma60 = SMA(FutYHret,n=60),sma50 = SMA(FutYHret,n=50),sma40 = SMA(FutYHret,n=40),
                                        sma30 = SMA(FutYHret,n=30),sma20 = SMA(FutYHret,n=20),sma10 = SMA(FutYHret,n=10)))
# write.csv(data1, "data2.csv")

# 交易
data1 <- na.omit(data1)
head(data1)
# data1 <- subset(data1,data1$date > as.Date('2015-10-21'))
# 读取国债期货价格
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
#如果短期向上穿过长期则做多，短期向下穿过长期则做空
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

#计算合约开仓时账户金额
data1$ZHJE <- 1000000
#计算合约开仓手数
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




#由于大多数回撤出现在最高点之后，如果窗口期太小，开仓会很频繁，增加交易成本。但是拉长窗口期，如果限制范围较小容易抓不住大多数的行情，
#反而买在走陡的最高点，反而蒙受损失。如果限制范围太大，则平仓不及时，白白损失利润。
data1 <- read.csv("T_TFirret.csv")
head(data1)
data1$date_id <- as.Date(data1$date_id)
data1 <- na.omit(data1)
# 读取国债期货价格
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
#######波动分析###################
#KD技术指标较为灵敏，对具有较明显的波动边界的走势。
#KD指标介绍
#假设FutYHret为价差序列， rsv 指标为当前价差与过去 N 天最小值的差与过去 N 天最大值与最小值差的比例，
#在上涨行情中该值趋近于 1，在下跌行情中该值趋近于 0，K 指标为 rsv 过去 m 天的均值， D 指标为 K 指标过去 m 天的均值。
data1$rsv <- NA
data1$K <- NA
data1$D <- NA
# 过去30个交易日的的KD指标
N = 30
m = 10
for (i in c(N:nrow(data1))) {
  data1$rsv[i] <- (data1$FutYHret - min(data1$FutYHret[(i-N+1):i]))/(max(data1$FutYHret[(i-N+1):i]) - min(data1$FutYHret[(i-N+1):i]))
  data1$K[i] <- mean(data1$rsv[(i-m+1):i])
  data1$D[i] <- mean(data1$K[(i-m+1):i])
}
#自适应均线AMA介绍
#dl表示 n 天的净价格变动， vt表示 n 天价格变化的综合，揭示市场噪音总量。 n 根据不同品种组合的价差均值回复时的特征来选择.
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
#交易信号
#1.开仓信号
#如果历史上极值点的分布比较稳定，则使用 KD 指标来做进行信号的判断。
#当价差大于一定水平，同时 KD 指标的 K 线向下穿越 D 线时，开仓做空价差；
#当价差小于一定水平，同时 KD 指标的 K 线向上穿越 D 线时，开仓做多价差。
#如果历史上极值点的分布不是很稳定，而是在一个较大的范围内波动，则使用自适应均线来做信号的判断。
#当价差大于正常波动范围的上轨，同时自适应均线向下拐头时，即 AMAt-1 < AMAt-2且 AMAt-2 > AMAt-3时，做空价差；
#当价差小于正常波动范围的下轨，同时自适应均线向上拐头时，即 AMAt-1 > AMAt-2且 AMAt-2 < AMAt-3时，进场做多价差。
#2.平部分仓位信号
#做空价差后，在价差未回归到正常波动水平时，如果 AMAt-1 > AMAt-2 且AMAt-2 < AMAt-3时，先平掉部分仓位；
#做多价差后，在价差未回归到正常波动水平时，如果 AMAt-1 < AMAt-2且 AMAt-2 > AMAt-3时，先平掉部分仓位。

#3.止损信号
#对于使用 KD 指标进场的套利仓位，
#如果是做空价差的仓位，那么在价差创出历史新高后止损平仓；
#如果是做多价差的仓位，那么在价差创出历史新低后止损平仓。

#对于使用自适应均线做为信号开仓的仓位，
#如果是做空价差的仓位，那么当自适应均线的值大于开仓时自适应均线的值时，止损平仓；
#如果是做多价差的仓位，那么当自适应均线的值小于开仓时自适应均线的值时，止损平仓。
#4.止盈信号
#进场做空价差后，如果价差回落小于 Ma+CP_Short *Std 时，则 落 入 止 盈 区 间 止 盈 平 仓 ；
#进场做多价差后，如果价差上涨大于 Ma+CP_Long *Std时，则落入止盈区间止盈平仓

#考察历史极值点的分布
ggplot(data = data1,aes(date_id,FutYHret)) + geom_line()
ggplot(data = data1,aes(date_id,X10_5)) + geom_line()

#假设按照历史极值点分布较为稳定来判断，使用KD指标来进行信号的判断。
# write.csv(data1, "data2.csv")
#价差的水平使用历史30天均值的百分位数作为判断。例如70%与30%，90%与10%。
data1$quan90 <- NA
data1$quan80 <- NA
data1$quan70 <- NA
data1$quan60 <- NA
data1$quan50 <- NA
data1$quan40 <- NA
data1$quan30 <- NA
data1$quan20 <- NA
data1$quan10 <- NA
# 过去30个交易日的百分位点作为曲线交易的判断依据
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

#如果短期向上穿过长期则做多，短期向下穿过长期则做空
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
#计算合约开仓时账户金额
data1$ZHJE <- 1000000
#计算合约开仓手数
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















