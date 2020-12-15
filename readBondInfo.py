# -*- coding:utf-8 -*-
####################################################################################################################
'''''

 程序：Wind下载可交割债券的详细信息
 功能：从Wind资讯量化接口中下载国债期货对应的可交割债券的剩余期限，上一付息日，下一付息日（指定日为连续国债期货第二交割日），票面利率，转换因子
 创建时间：2020/09/14  V1.01 创建版本，Python3.8

 环境和类库：使用Python 3.8及第三方库pandas、WindPy、sqlalchemy
             Wind资讯量化接口
 作者：tcs
'''
####################################################################################################################
import pandas as pd
from WindPy import w
from sqlalchemy import create_engine
import datetime, time
import os
import csv


class WindCTD:

    def getCurrentTime(self):
        # 获取当前时间
        return time.strftime('[%Y-%m-%d %H:%M:%S]', time.localtime(time.time()))

    def CTDInfoData(self, symbols):
        """
        逐个债券代码查询基础数据
        wss代码可以借助 WindNavigator自动生成copy即可使用;
        """
        print(self.getCurrentTime(), ": Download CF Starting:")
        for i in range(len(symbols[0])):
            symbol = symbols[0][i]
            print(symbol)
            w.start()
            CF = w.wset("conversionfactor", "windcode=" + symbol)
            print(CF.Data[0])
            LASTDELIVERY_DATE = symbols[1][i].strftime("%Y%m%d")
            print(LASTDELIVERY_DATE)

            CTD = w.wss(list(filter(lambda s: s.endswith("IB"), CF.Data[0])),
                        "ptmyear,anal_precupn,nxcupn,couponrate,interestfrequency",
                        "tradeDate=" + LASTDELIVERY_DATE)

            BondBaseInfo_data = pd.DataFrame()

            print(CTD)
            if CTD.Data:
                BondBaseInfo_data['BOND_CD'] = CTD.Codes
                BondBaseInfo_data['PTMYEAR'] = CTD.Data[0]
                BondBaseInfo_data['ANAL_PRECUPN'] = CTD.Data[1]
                BondBaseInfo_data['NXCUPN'] = CTD.Data[2]
                BondBaseInfo_data['COUPONRATE'] = CTD.Data[3]
                BondBaseInfo_data['INTERESTFREQUENCY'] = CTD.Data[4]

                rownum = len(CTD.Data[1])
                for num in range(rownum):
                    writer.writerow([symbol, LASTDELIVERY_DATE, BondBaseInfo_data.iloc[num, 0],
                                     BondBaseInfo_data.iloc[num, 1], BondBaseInfo_data.iloc[num, 2],
                                     BondBaseInfo_data.iloc[num, 3], BondBaseInfo_data.iloc[num, 4],
                                     BondBaseInfo_data.iloc[num, 5]])

            else:
                print(self.getCurrentTime(), ":empty ")

        print(self.getCurrentTime(), ":Download Bond has Finished. ")

    def getTFCodesFromWind(self, start_date, end_date):
        w.start()
        # 加日期参数获取不同国债期货的所有合约信息
        TCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=T.CFE")
        TSCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=TS.CFE")
        TFCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=TF.CFE")
        print(TCodes.Data[2])
        print([TCodes.Data[2] + TSCodes.Data[2] + TFCodes.Data[2], TCodes.Data[8] + TSCodes.Data[8] + TFCodes.Data[8]])
        return [TCodes.Data[2] + TSCodes.Data[2] + TFCodes.Data[2], TCodes.Data[8] + TSCodes.Data[8] + TFCodes.Data[8]]


def main():
    '''''
    主调函数
    '''
    global symbols, writer, end_date
    ret = w.start()
    print(ret)
    windCTD = WindCTD()
    start_date = '2013-01-01'
    end_date = '2020-11-16'
    print(end_date, 'Starting')
    symbols = windCTD.getTFCodesFromWind(start_date, end_date)
    with open('TDInfo' + end_date + '.csv', 'w', newline='') as datacsv:
        writer = csv.writer(datacsv)
        writer.writerow(["sec_name", "LASTDELIVERY_DATE", "bond_cd", "ptmyear", "anal_precupn", "nxcupn", "couponrate",
                         "interestfrequency"])
        # writer2.writerow(["国债期货名称", "日期", "可交割债券代码", "剩余期限（年）", "上一付息日", "下一付息日", "票面利率",
        #                   "每年付息次数"])
        windCTD.CTDInfoData(symbols)

    print(end_date, 'Finished')


if __name__ == "__main__":
    main()