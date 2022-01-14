
### Config

*  `config.json`
	*  `windowSize`: e.g. 1200 - update once at most every 1200 seconds.
	*  `deviation`: e.g. 0.01 - update once Δ { marketData, lastSavedData } > 0.01.
    

### Start Feeder node

*  `pm2 start feeder.js --exp-backoff-restart-delay=10000`

### Get node state

* emulator: `http://127.0.0.1:15535/states`
