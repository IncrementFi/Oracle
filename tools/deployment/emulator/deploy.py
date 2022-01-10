import os
import json
import re

Network = 'emulator'

with open('./flow.json', 'r') as f:
    flow_json = json.load(f)

OracleConfigs = flow_json['oracles'][Network]
FeaderConfigs = flow_json['feaders'][Network]
ReaderConfigs = flow_json['readers'][Network]

if Network == 'emulator':
    # create new account
    for deployer in flow_json['accounts']:
        if deployer.startswith('emulator-') and deployer != 'emulator-account':
            os.popen('flow accounts create --key 99c7b442680230664baab83c4bc7cdd74fb14fb21cce3cceb962892c06d73ab9988568b8edd08cb6779a810220ad9353f8e713bc0cb8b81e06b68bcb9abb551e --sig-algo "ECDSA_secp256k1"  --signer "emulator-account"').read()

print('-------------------------------------------------- deploy normally:')
os.system('flow project deploy -f flow.json --update --network {0}'.format(Network))

print('-------------------------------------------------- deploy oracles:')
for tokenName in OracleConfigs:
    oracleConfig = OracleConfigs[tokenName]
    deployer = oracleConfig['deployer']
    print('-------------------------------------------------- deploy oracle', deployer)
    cmd = 'flow transactions send ./cadence/transactions/tool/deploy_by_template.cdc ' + \
          '--arg Address:{0} '.format(flow_json['oracles']['codeTemplate'][Network]) + \
          '--arg String:{0} '.format("TokenPriceOracle") + \
          '--signer {0}'.format(deployer)
    print(cmd)
    os.system(cmd)


print('-------------------------------------------------- init oracles:')
for tokenName in OracleConfigs:
    oracleConfig = OracleConfigs[tokenName]
    deployer = oracleConfig['deployer']
    tokenType = oracleConfig['tokenType']
    feaderPath = oracleConfig['feaderPath']
    print('-------------------------------------------------- init oracle', deployer)
    cmd = 'flow transactions send ./cadence/transactions/oracle/init_oracle.cdc ' + \
        '--args-json \'[' + \
        '{"type": "String", "value": "'+tokenType+'"}, ' + \
        '{"type": "Int", "value": "'+str(oracleConfig['minFeaderNumber'])+'"}, ' + \
        '{"type": "Path", "value": {"domain": "storage", "identifier": "'+feaderPath+'"} },' + \
        '{"type": "Path", "value": {"domain": "public", "identifier": "'+feaderPath+'"} }]\' ' + \
        '--signer {0}'.format(deployer)
    print(cmd)
    os.system(cmd)

print('-------------------------------------------------- init feaders:')
for tokenName in FeaderConfigs:
    feaderList = FeaderConfigs[tokenName]
    for feaderConfig in feaderList:
        oracleConfig = OracleConfigs[tokenName]

        feaderDeployer = feaderConfig['deployer']
        feaderAddr = flow_json['accounts'][feaderDeployer]['address']
        feaderInitPrice = feaderConfig['initPrice']

        oracleDeployer = oracleConfig['deployer']
        oracleAddr = flow_json['accounts'][oracleDeployer]['address']
        

        cmd = 'flow transactions send ./cadence/transactions/feader/init_feader.cdc ' + \
            '--arg Address:"{0}" '.format(oracleAddr) + \
            '--signer {0}'.format(feaderDeployer)
        print(cmd)
        print('-------------------------------------------------- init feader', feaderDeployer, 'on', oracleDeployer)
        os.system(cmd)
        
        #
        print('-------------------------------------------------- add whitelist:')
        cmd = 'flow transactions send ./cadence/transactions/oracle/add_feader.cdc ' + \
              '--arg Address:"{0}" '.format(feaderAddr) + \
              '--signer {0}'.format(oracleDeployer)
        os.system(cmd)
        
        #
        print("-------------------------------------------------- publish init price")
        cmd = 'flow transactions send ./cadence/transactions/feader/publish_price.cdc ' + \
              '--arg Address:"{0}" '.format(oracleAddr) + \
              '--arg UFix64:"{0}" '.format(feaderInitPrice) + \
              '--signer {0}'.format(feaderDeployer)
        os.system(cmd)




print('-------------------------------------------------- add reader whitelist:')
for tokenName in ReaderConfigs:
    readerList = ReaderConfigs[tokenName]
    for readerConfig in readerList:
        oracleConfig = OracleConfigs[tokenName]
        feaderConfig = FeaderConfigs[tokenName]

        oracleDeployer = oracleConfig['deployer']
        oracleAddr = flow_json['accounts'][oracleDeployer]['address']
        
        readerDeployer = readerConfig['deployer']
        readerAddr = flow_json['accounts'][readerDeployer]['address']

        # add reader white list
        print('-------------------------------------------------- add reader white list', readerAddr, 'on', oracleDeployer)
        cmd = 'flow transactions send ./cadence/transactions/oracle/add_reader.cdc ' + \
              '--arg Address:"{0}" '.format(readerAddr) + \
              '--signer {0}'.format(oracleDeployer)
        os.system(cmd)
        
        # apply for reader certificate
        print('-------------------------------------------------- apply for reader certificate')
        cmd = 'flow transactions send ./cadence/transactions/reader/apply_reader_certificate.cdc ' + \
              '--arg Address:"{0}" '.format(oracleAddr) + \
              '--signer {0}'.format(readerDeployer)
        os.system(cmd)