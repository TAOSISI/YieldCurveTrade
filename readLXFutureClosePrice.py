# -*- coding:utf-8 -*-
####################################################################################################################
'''''

 程序：Wind下载可交割债券的详细信息
 功能：从Wind资讯量化接口中下载国债期货连续合约对应的可交割债券的剩余期限，上一付息日，下一付息日（指定日为连续国债期货第二交割日），票面利率，转换因子
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

    def CTDInfoData(self, symbols, start_date, end_date):
        """
        逐个债券代码查询基础数据
        wss代码可以借助 WindNavigator自动生成copy即可使用;
        """
        print(self.getCurrentTime(), ": Download CF Starting:")
        for symbol in symbols:
            print(symbol)
            w.start()
            Future = w.wsd(symbol, "close,settle,trade_hiscode", start_date, end_date, "")

            BondBaseInfo_data = pd.DataFrame()

            print(Future)
            if Future.Data:
                BondBaseInfo_data['DATE_ID'] = Future.Times
                BondBaseInfo_data['close'] = Future.Data[0]
                BondBaseInfo_data['settle'] = Future.Data[1]
                BondBaseInfo_data['trade_hiscode'] = Future.Data[2]

                rownum = len(Future.Data[1])
                for num in range(rownum):
                    writer.writerow([symbol, BondBaseInfo_data.iloc[num, 0],
                                     BondBaseInfo_data.iloc[num, 1], BondBaseInfo_data.iloc[num, 2],
                                     BondBaseInfo_data.iloc[num, 3]])

            else:
                print(self.getCurrentTime(), ":empty ")

        print(self.getCurrentTime(), ":Download Bond has Finished. ")

    def getTFCodesFromWind(self):
        w.start()
        # 加日期参数获取不同国债期货的所有合约信息
        return ["T00.CFE", "TS00.CFE", "TF00.CFE"]


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
    symbols = windCTD.getTFCodesFromWind()
    with open('LXFutureClose' + end_date + '.csv', 'w', newline='') as datacsv:
        writer = csv.writer(datacsv)
        writer.writerow(["future_name", "date_id", "close", "settle", "sec_name"])
        # writer2.writerow(["期货品种", "日期", "收盘价", "结算价", "主力合约"])
        windCTD.CTDInfoData(symbols, start_date, end_date)

    print(end_date, 'Finished')


if __name__ == "__main__":
    main()