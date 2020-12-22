import pandas as pd
import csv
import numpy as np
import math

class ReverseStrategy:
    def __init__(self, T_TFirret_path, ADPFutureClose_path, ReverseStrategySave_path,days,quantiles):
        self.T_TFirret_path = T_TFirret_path
        self.ADPFutureClose_path = ADPFutureClose_path
        self.ReverseStrategySave_path = ReverseStrategySave_path
        self.days = days
        self.quantiles = quantiles
      

    def getQuantile(self):
        df_quan = pd.read_csv(self.T_TFirret_path, encoding='utf-8')
        n = self.days
        quan_name_list = []

        for quantile in self.quantiles:
            quan_name_list.append('quan' + str(quantile))

            df_quan['quan' + str(quantile)] = df_quan['FutYHret'].copy()
            df_quan.dropna(axis=0, how='any', inplace=True)
        
            for i in range((n-1),len(df_quan['date_id'])):
                df_quan['quan'+ str(quantile)][i] =  round(np.percentile(df_quan['FutYHret'][(i-n+1):i+1], quantile),2)
        
        a = [i for i in range(n-1)]          
        df_quan = df_quan.drop(a)


        df_price = pd.read_csv(self.ADPFutureClose_path , encoding='utf-8')

        df_price.rename(columns={'sec_name':'T_name'}, inplace=True) 
        df = df_quan.merge(df_price,on=("date_id",'T_name'),how = 'left') 
        df = pd.DataFrame(df, columns= ["date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret"] + quan_name_list)
        df.rename(columns={'close':'T_close','settle':'T_settle'}, inplace=True) 
        
        df_price.rename(columns={'T_name':'TF_name'}, inplace=True)
        df = df.merge(df_price,on=("date_id",'TF_name'),how = 'left') 
        df = pd.DataFrame(df, columns= ["date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret"] + quan_name_list)
        df.rename(columns={'close':'TF_close','settle':'TF_settle'}, inplace=True) 
        #print(df)
        return df

    def GetPosition(self):
        df = self.getQuantile()
        for quantile in self.quantiles:
            if quantile > 50:
                df['position_T'+ str(quantile)] = [0 for i in range(len(df['date_id']))]
                df['position_TF' + str(quantile)] = [0 for i in range(len(df['date_id']))]
                begin01 = False
                begin02 = False
                for i in range(len(df['date_id'])):

                    if ((df['FutYHret'][i] >= df['quan'+str(quantile)][i])):
                        begin01 = True

                    if (((df['quan50'][i] < df['FutYHret'][i])) & begin01):
                        df['position_T'+ str(quantile)][i] = 1
                        df['position_TF' + str(quantile)][i] = -2  

                    if  (df['quan50'][i] > df['FutYHret'][i]):
                        begin01 = False
                    #从下到上
                    if ((df['FutYHret'][i] <= df['quan'+str(100-quantile)][i])):
                        begin02 = True

                    if ((df['FutYHret'][i] <= df['quan50'][i]) & begin02 & (df['FutYHret'][i] < df['quan'+str(quantile)][i])) :
                        df['position_T'+ str(quantile)][i] = -1
                        df['position_TF'+ str(quantile)][i] = 2  

                    if (df['quan50'][i] < df['FutYHret'][i]):
                        begin02 = False

            
                df_test = pd.read_csv('data1.csv', encoding='utf-8')

                for i in range(len(df['position_T' + str(quantile)])):
                    if df['position_T' + str(quantile)][i] != df_test['position_T' + str(quantile)][i]:
                        print(quantile,i,df['position_T' + str(quantile)][i],df_test['position_T' + str(quantile)][i])

        #df.to_csv(self.StepReverseSave_path,index = False)

        return df    

    def Simulate(self):
        df = self.GetPosition()

        df['position_T'] = df['position_T90'].copy()+df['position_T80'].copy()+df['position_T70'].copy()+df['position_T60'].copy()
        df['position_TF'] = df['position_TF90'].copy()+df['position_TF80'].copy()+df['position_TF70'].copy()+df['position_TF60'].copy()
        

        df['lag_position_T'] = df['position_T'].shift(1)
        df['lag_position_TF'] = df['position_TF'].shift(1)

        df['lag_position_T'][0] = 0
        df['lag_position_TF'][0] = 0

        df['ZHJE'] = [1000000 for i in range(len(df['date_id']))]
        df['KCSS'] = [0 for i in range(len(df['date_id']))]
        df['XZZJ'] = [0 for i in range(len(df['date_id']))]

        
        for i in range(1,len(df['ZHJE'])):

            if (df['lag_position_T'][i-1] == 0) & (df['lag_position_T'][i] != 0): 
                df['KCSS'][i] = math.floor(df['ZHJE'][i-1]/(max(2*0.012*df['TF_settle'][i]*10000,0.02*df['T_settle'][i]*10000))/4)
                df['ZHJE'][i] = 10000*df['KCSS'][i]*df['lag_position_T'][i]*(df['T_settle'][i]-df['T_settle'][i-1])+\
                    10000*df['KCSS'][i]*df['lag_position_TF'][i]*(df['TF_settle'][i]-df['TF_settle'][i-1])+ df['ZHJE'][i-1]
            elif (df['lag_position_T'][i-1] != 0) & (df['lag_position_T'][i] != 0): 
                df['KCSS'][i] = df['KCSS'][i-1]
                df['ZHJE'][i] = 10000*df['KCSS'][i]*df['lag_position_T'][i]*(df['T_settle'][i]-df['T_settle'][i-1])+\
                    10000*df['KCSS'][i]*df['lag_position_TF'][i]*(df['TF_settle'][i]-df['TF_settle'][i-1])+ df['ZHJE'][i-1]
            else:
                df['KCSS'][i] = 0
                df['ZHJE'][i] = df['ZHJE'][i-1]
            df['XZZJ'][i] = df['ZHJE'][i] - df['KCSS'][i] * max(2*0.012*df['TF_settle'][i]*10000,0.02*df['T_settle'][i]*10000) * abs(df['lag_position_T'][i])

        df.to_csv(self.StepReverseSave_path,index = False)

def main():
    test = StepReverse('T_TFirret.csv','ADPFutureClose2020-09-16.csv','StepReverse.csv',100,[90,80,70,60,50,40,30,20,10])
    test.Simulate()

if __name__ == "__main__":
    main()
