# -*- coding:utf-8 -*-
####################################################################################################################
'''''

 程序：Wind下载可交割债券
 功能：从Wind资讯量化接口中下载国债期货对应的可交割债券
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
            w.start()
            CTD = w.wset("ctd", "startdate=" + start_date + ";enddate= " + end_date + ";windcode=" + symbol)

            BondBaseInfo_data = pd.DataFrame()
            print(symbol)
            print(CTD)
            if CTD.Data:
                BondBaseInfo_data['date_id'] = CTD.Data[0]
                BondBaseInfo_data['ctd_cd'] = CTD.Data[1]
                BondBaseInfo_data['irr'] = CTD.Data[2]
                BondBaseInfo_data['ctd_ib'] = CTD.Data[3]
                BondBaseInfo_data['irr_ib'] = CTD.Data[4]
                BondBaseInfo_data['ctd_sh'] = CTD.Data[5]
                BondBaseInfo_data['irr_sh'] = CTD.Data[6]
                BondBaseInfo_data['ctd_sz'] = CTD.Data[7]
                BondBaseInfo_data['irr_sz'] = CTD.Data[8]

                rownum = len(CTD.Data[1])
                for num in range(rownum):
                    writer.writerow([symbol, BondBaseInfo_data.iloc[num, 0], BondBaseInfo_data.iloc[num, 1],
                                     BondBaseInfo_data.iloc[num, 2], BondBaseInfo_data.iloc[num, 3],
                                     BondBaseInfo_data.iloc[num, 4], BondBaseInfo_data.iloc[num, 5],
                                     BondBaseInfo_data.iloc[num, 6], BondBaseInfo_data.iloc[num, 7],
                                     BondBaseInfo_data.iloc[num, 8]])

            else:
                print(self.getCurrentTime(), ":empty ")

        print(self.getCurrentTime(), ":Download Bond has Finished. ")

    def getTFCodesFromWind(self, start_date, end_date):
        w.start()
        # 加日期参数获取不同国债期货的所有合约信息
        TCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=T2012.CFE")
        TSCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=TS2012.CFE")
        TFCodes = w.wset("futurecc", "startdate=" + start_date + ";enddate=" + end_date + ";wind_code=TF2012.CFE")
        print(TCodes.Data[2])
        return TCodes.Data[2] + TSCodes.Data[2] + TFCodes.Data[2]


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
    with open('CTDInfo' + end_date + '.csv', 'w', newline='') as datacsv:
        writer = csv.writer(datacsv)
        writer.writerow(["wind_cd", "date_id", "ctd_cd", "irr", "ctd_ib", "irr_ib", "ctd_sh", "irr_sh",
                         "ctd_sz", "irr_sz"])
        # writer2.writerow(["国债期货名称", "日期", "最便宜交割债券代码", "隐含回购利率", "银行间最便宜交割债券代码", "银行间隐含回购利率",
        #                   "沪市最便宜交割债券代码", "沪市隐含回购利率", "深市最便宜交割债券代码", "深市隐含回购利率"])
        windCTD.CTDInfoData(symbols, start_date, end_date)

    print(end_date, 'Finished')


if __name__ == "__main__":
    main()