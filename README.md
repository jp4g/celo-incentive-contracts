# OrgToken Contract Suite

### 1: in cli, clone this repo 
```git clone https://github.com/MUBlockchain/contracts.git```

### 2: install dependencies 
```npm i```

### 3: add environment variables 
```nano .env```

*Example .env file:*
```
INFURA=infura.io/v3/xxxxxxxxxxxxxxxxxxxxxxx
MNEMONIC=word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12
```

### 4: run a truffle development console 
```npx truffle develop```

### 5: build the contracts 
```compile```

## BRANCHING STEPS: LOCAL DEPLOYMENT AND TESTING

### 6: deploy to the truffle development server 
```migrate --reset```

### 7: test the application 
```test tests/test.js``` 
*yes I know this isn't configured correctly. no i will not do anything about it rn*

## BRANCHING STEPS: LIVE DEPLOYMENT AND TESTING
*if your preferred network is not listed here you must add it in truffle-config.js*

### 6: deploy to your preferred network (we choose kovan)
```migrate --network kovan --reset```

### 7: test the application
```test tests/test.js --network kovan```
