import os
import json
import re


print('-------------------------------------------------- test flowtoken price on user1')
os.system('flow transactions send ./cadence/transactions/reader/get_median_price.cdc --arg Address:"0x2d766f00eb1d0c37" --signer testnet-reader1 --network testnet')

os.system('flow transactions send ./cadence/transactions/reader/get_median_price.cdc --arg Address:"0x3b220a3372190656" --signer testnet-reader1 --network testnet')