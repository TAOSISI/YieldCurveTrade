# -*- coding:utf-8 -*-
####################################################################################################################
'''''

 程序：Wind下载可交割债券的转换因子CF
 功能：从Wind资讯量化接口中下载国债期货对应的可交割债券及其转换因子
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


class WindCTDandCF:

    def getCurrentTime(self):
        # 获取当前时间
        return time.strftime('[%Y-%m-%d %H:%M:%S]', time.localtime(time.time()))

    def CFInfoData(self, symbols):
        """
        逐个债券代码查询基础数据
        wss代码可以借助 WindNavigator自动生成copy即可使用;
        """
        print(self.getCurrentTime(), ": Download CF Starting:")
        for symbol in symbols:
            w.start()
            CF = w.wset("conversionfactor", "windcode=" + symbol)

            BondBaseInfo_data = pd.DataFrame()
            print(CF)
            BondBaseInfo_data['bond_cd'] = CF.Data[0]
            BondBaseInfo_data['CF'] = CF.Data[1]

            rownum = len(CF.Data[1])
            for num in range(rownum):
                writer.writerow([symbol, BondBaseInfo_data.iloc[num, 0], BondBaseInfo_data.iloc[num, 1]])

        print(self.getCurrentTime(), ":Download Bond has Finished. ")

    def getTFCodesFromWind(self, end_date):
        w.start()
        # 加日期参数获取不同国债期货的所有合约信息
        TCodes = w.wset("futurecc", "startdate=2013-01-01;enddate=" + end_date + ";wind_code=T2012.CFE")
        TSCodes = w.wset("futurecc", "startdate=2013-01-01;enddate=" + end_date + ";wind_code=TS2012.CFE")
        TFCodes = w.wset("futurecc", "startdate=2013-01-01;enddate=" + end_date + ";wind_code=TF2012.CFE")
        print(TCodes.Data[2])
        return TCodes.Data[2] + TSCodes.Data[2] + TFCodes.Data[2]


def main():
    '''''
    主调函数
    '''
    global symbols, writer, end_date
    ret = w.start()
    print(ret)
    windCTDandCF = WindCTDandCF()
    # start_date=time.strftime('%Y-%m-%d', time.localtime(time.time()))
    # end_date=time.strftime('%Y-%m-%d', time.localtime(time.time()))
    end_date = '2020-11-16'
    print(end_date, 'Starting')
    symbols = windCTDandCF.getTFCodesFromWind(end_date)
    '''
    with open('TFbaseInfo' + end_date + '.csv', 'w', newline='') as datacsv:
        writer1 = csv.writer(datacsv)
        writer1.writerow(["sec_name", "code", "wind_code", "delivery_month", "change_limit", "target_margin",
                         "contract_issue_date", "last_trade_date", "last_delivery_month"])
        # writer1.writerow(["名称", "交易所代码", "wind代码", "交割月份", "涨跌幅限制", "交易保证金",
        #                  "合约上市日", "最后交易日", "最后交割日"])
    '''
    with open('CFInfo' + end_date + '.csv', 'w', newline='') as datacsv:
        writer = csv.writer(datacsv)
        writer.writerow(["sec_name", "bond_cd", "cf"])
        # writer2.writerow(["国债期货名称", "债券名称", "转换因子"])
        windCTDandCF.CFInfoData(symbols)

    print(end_date, 'Finished')


if __name__ == "__main__":
    main()