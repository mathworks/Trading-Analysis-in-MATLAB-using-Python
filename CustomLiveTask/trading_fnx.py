import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings("ignore")

def sma(data):
    data['PnL'] = np.zeros(len(data));
    data['trade'] = np.zeros(len(data));
    data['sma'] = data['Close'].rolling(15).mean().dropna();
    data['indicator'] = np.where(data['Close'] > data['sma'],1,0);
    for i in range(1,len(data)-1):
        if data['indicator'].iloc[i] == 1:
            data['PnL'][i] -= data['Close'].iloc[i];
            data['PnL'][i] += data['Open'].iloc[i+1];
            data['trade'][i] = 1;
        if data['indicator'].iloc[i] == 0:
            data['PnL'][i] += data['Close'].iloc[i];
            data['PnL'][i] -= data['Open'].iloc[i+1];
            data['trade'][i] = 1;
    return data

#function for mean reversion strategy
def mean_rev(data):
    data['PnL'] = np.zeros(len(data));
    data['trade'] = np.zeros(len(data));
    for i in range(2,len(data)-1):
        if data['Close'].iloc[i-2] > data['Close'].iloc[i-1] > data['Close'].iloc[i]:
            #buy one share at next day open
            data['PnL'][i] -= data['Open'].iloc[i+1];
            #sell one share at next day close
            data['PnL'][i] += data['Close'].iloc[i+1];
            data['trade'][i] = 1;
        if data['Close'].iloc[i-2] < data['Close'].iloc[i-1] < data['Close'].iloc[i]:
            #sell one share at next day open
            data['PnL'][i] += data['Open'].iloc[i+1];
            #buy one share at next day close
            data['PnL'][i] -= data['Close'].iloc[i+1];
            data['trade'][i] = 1;
    return data

def momentum(data):
    data['PnL'] = np.zeros(len(data));
    data['trade'] = np.zeros(len(data));
    for i in range(2,len(data)-1):
        if data['Close'].iloc[i-2] > data['Close'].iloc[i-1] > data['Close'].iloc[i]:
            #sell one share at next day open
            data['PnL'][i] += data['Open'].iloc[i+1];
            #buy one share at next day close
            data['PnL'][i] -= data['Close'].iloc[i+1];
            data['trade'][i] = 1;
        if data['Close'].iloc[i-2] < data['Close'].iloc[i-1] < data['Close'].iloc[i]:
            #buy one share at next day open
            data['PnL'][i] -= data['Open'].iloc[i+1];
            #sell one share at next day close
            data['PnL'][i] += data['Close'].iloc[i+1];
            data['trade'][i] = 1;
    return data
