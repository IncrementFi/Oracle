import os
import json
import re


print('-------------------------------------------------- test flowtoken price on user1')
os.system('flow transactions send ./cadence/transactions/reader/get_median_price.example.cdc --arg Address:"0x01cf0e2f2f715450" --signer emulator-reader1')

os.system('flow transactions send ./cadence/transactions/reader/get_median_price.example.cdc --arg Address:"0x179b6b1cb6755e31" --signer emulator-reader1')