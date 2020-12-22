import pandas as pd
import csv
import numpy as np
import math

def get_quan():
    df_irr = pd.read_csv('T_TFirret.csv', encoding='utf-8')

    df_irr['quan20'] = df_irr['FutYHret'].copy()
    df_irr['quan80'] = df_irr['FutYHret'].copy()
    df_irr['quan50'] = df_irr['FutYHret'].copy()
    df_irr.dropna(axis=0, how='any', inplace=True)
    n = 90
    for i in range((n-1),len(df_irr['date_id'])):
        df_irr['quan80'][i] =  np.percentile(df_irr['FutYHret'][(i-n+1):i+1], 90)
        df_irr['quan20'][i] =  np.percentile(df_irr['FutYHret'][(i-n+1):i+1], 10)
        df_irr['quan50'][i] =  np.percentile(df_irr['FutYHret'][(i-n+1):i+1], 50)
    a = []
    for i in range(n-1):
        a.append(i)
    df_irr = df_irr.drop(a)


    df_price = pd.read_csv('ADPFutureClose2020-09-16.csv', encoding='utf-8')

    df_price.rename(columns={'sec_name':'T_name'}, inplace=True) 
    df01 = df_irr.merge(df_price,on=("date_id",'T_name'),how = 'left') 

    df01 = pd.DataFrame(df01, columns= ["date_id","T_name","T_irret","close","settle","TF_name","TF_irret","FutYHret","quan80","quan20","quan50"])
    df01.rename(columns={'close':'T_close','settle':'T_settle'}, inplace=True) 

    df_price.rename(columns={'T_name':'TF_name'}, inplace=True)


    df02 = df01.merge(df_price,on=("date_id",'TF_name'),how = 'left') 
    df02 = pd.DataFrame(df02, columns= ["date_id","T_name","T_irret","T_close","T_settle","TF_name","TF_irret","close","settle","FutYHret","quan80","quan20","quan50"])
    df02.rename(columns={'close':'TF_close','settle':'TF_settle'}, inplace=True) 
    #df02.to_csv('test.csv',index = False)

    return df02


def up_down(df):
    df['position_T80'] = df['quan50'].copy()
    df['position_TF80'] = df['quan50'].copy()
    for i in range(len(df['position_T80'])):
        df['position_T80'] = 0
        df['position_TF80'] = 0

    begin01 = False
    begin02 = False
    for i in range(1,len(df['position_T80'])):

        a = ((df['FutYHret'][i-1] < df['quan80'][i-1]) & (df['FutYHret'][i] >= df['quan80'][i]))
        
        if a:
            begin01 = True

        b = ((df['quan50'][i] < df['FutYHret'][i]) & begin01)

        if b:
            df['position_T80'][i] = 1
            df['position_TF80'][i] = -2  

        if  (df['quan50'][i] > df['FutYHret'][i]):
            begin01 = False

        c = ((df['FutYHret'][i-1] > df['quan20'][i-1]) & (df['FutYHret'][i] <= df['quan20'][i]))

        if c:
            begin02 = True
        
        d = ((df['FutYHret'][i] < df['quan50'][i]) & begin02)

        if d:
            df['position_T80'][i] = -1
            df['position_TF80'][i] = 2  

        if (df['quan50'][i] < df['FutYHret'][i]):
            begin02 = False

    
    df_test = pd.read_csv('data1.csv', encoding='utf-8')
    
    for i in range(1,len(df['position_T80'])):
        if df['position_T80'][i] != df_test['position_T90'][i]:
            print(df['position_T80'][i],df_test['position_T90'][i],i)

    #df.to_csv('test.csv',index = False)

    return df
def simulate(df):

    df['lag_position_TF80'] = df['position_TF80'].shift(1)
    df['lag_position_T80'] = df['position_T80'].shift(1)
    df['lag_position_T80'][0] = 0
    df['lag_position_TF80'][0] = 0

    df['ZHJE'] = df['lag_position_T80'][0].copy()
    df['KCSS'] = df['lag_position_T80'][0].copy()

    for i in range(len(df['ZHJE'])):
        df['ZHJE'][i] = 1000000
        df['KCSS'][i] = 0
    
    for i in range(1,len(df['ZHJE'])):
        if (df['lag_position_T80'][i-1] == 0) & (df['lag_position_T80'][i] != 0): 
            df['KCSS'][i] = math.floor(df['ZHJE'][i-1]/max(2*0.012*df['TF_settle'][i]*10000,0.02*df['T_settle'][i]*10000))
            df['ZHJE'][i] = 10000*df['KCSS'][i]*df['lag_position_T80'][i]*(df['T_settle'][i]-df['T_settle'][i-1])+\
                10000*df['KCSS'][i]*df['lag_position_TF80'][i]*(df['TF_settle'][i]-df['TF_settle'][i-1])+ df['ZHJE'][i-1]
        elif (df['lag_position_T80'][i-1] != 0) & (df['lag_position_T80'][i] != 0): 
            df['KCSS'][i] = df['KCSS'][i-1]
            df['ZHJE'][i] = 10000*df['KCSS'][i]*df['lag_position_T80'][i]*(df['T_settle'][i]-df['T_settle'][i-1])+\
                10000*df['KCSS'][i]*df['lag_position_TF80'][i]*(df['TF_settle'][i]-df['TF_settle'][i-1])+ df['ZHJE'][i-1]
        else:
            df['KCSS'][i] = 0
            df['ZHJE'][i] = df['ZHJE'][i-1]
    

    df.to_csv('test.csv',index = False)

def main():
    df = get_quan()
    simulate(up_down(df))
main()
