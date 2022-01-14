import os
import json
import re

Network = 'emulator'

with open('./flow.json', 'r') as f:
    flow_json = json.load(f)

OracleConfigs = flow_json['oracles'][Network]
FeederConfigs = flow_json['feeders'][Network]
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
          '--arg String:{0} '.format("PriceOracle") + \
          '--signer {0}'.format(deployer)
    print(cmd)
    os.system(cmd)


print('-------------------------------------------------- init oracles:')
for tokenName in OracleConfigs:
    oracleConfig = OracleConfigs[tokenName]
    deployer = oracleConfig['deployer']
    priceIdentifier = oracleConfig['priceIdentifier']
    feederPath = oracleConfig['feederPath']
    readerPath = oracleConfig['readerPath']
    print('-------------------------------------------------- init oracle', deployer)
    cmd = 'flow transactions send ./cadence/transactions/oracle/init_oracle.cdc ' + \
        '--args-json \'[' + \
        '{"type": "String", "value": "'+priceIdentifier+'"}, ' + \
        '{"type": "Int", "value": "'+str(oracleConfig['minFeederNumber'])+'"}, ' + \
        '{"type": "Path", "value": {"domain": "storage", "identifier": "'+feederPath+'"} },' + \
        '{"type": "Path", "value": {"domain": "public", "identifier": "'+feederPath+'"} },' + \
        '{"type": "Path", "value": {"domain": "storage", "identifier": "'+readerPath+'"} }]\' ' + \
        '--signer {0}'.format(deployer)
    print(cmd)
    os.system(cmd)

print('-------------------------------------------------- init feeders:')
for tokenName in FeederConfigs:
    feederList = FeederConfigs[tokenName]
    for feederConfig in feederList:
        oracleConfig = OracleConfigs[tokenName]

        feederDeployer = feederConfig['deployer']
        feederAddr = flow_json['accounts'][feederDeployer]['address']
        feederInitPrice = feederConfig['initPrice']

        oracleDeployer = oracleConfig['deployer']
        oracleAddr = flow_json['accounts'][oracleDeployer]['address']
        
        
        cmd = 'flow transactions send ./cadence/transactions/feeder/mint_local_price_feeder.cdc ' + \
            '--arg Address:"{0}" '.format(oracleAddr) + \
            '--signer {0}'.format(feederDeployer)
        print(cmd)
        print('-------------------------------------------------- init feeder', feederDeployer, 'on', oracleDeployer)
        os.system(cmd)

        
        #
        print('-------------------------------------------------- add whitelist:')
        cmd = 'flow transactions send ./cadence/transactions/oracle/add_feeder.cdc ' + \
              '--arg Address:"{0}" '.format(feederAddr) + \
              '--signer {0}'.format(oracleDeployer)
        os.system(cmd)
        
        #
        print("-------------------------------------------------- publish init price")
        cmd = 'flow transactions send ./cadence/transactions/feeder/publish_price.cdc ' + \
              '--arg Address:"{0}" '.format(oracleAddr) + \
              '--arg UFix64:"{0}" '.format(feederInitPrice) + \
              '--signer {0}'.format(feederDeployer)
        os.system(cmd)




print('-------------------------------------------------- add reader whitelist:')
for tokenName in ReaderConfigs:
    readerList = ReaderConfigs[tokenName]
    for readerConfig in readerList:
        oracleConfig = OracleConfigs[tokenName]
        feederConfig = FeederConfigs[tokenName]

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
        
        """
        # apply for reader certificate
        print('-------------------------------------------------- mint price reader')
        cmd = 'flow transactions send ./cadence/transactions/reader/mint_local_price_reader.cdc ' + \
              '--arg Address:"{0}" '.format(oracleAddr) + \
              '--signer {0}'.format(readerDeployer)
        os.system(cmd)
        """