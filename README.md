[![License](https://img.shields.io/github/license/yonaskolb/Mint.svg?style=for-the-badge)](LICENSE)


# Swifty Blockchain

A Blockchain developer course project. Simple blockchain implementation


## Requirements

* Swift 5.6
* Linux or macOS, tested on Ubuntu 20.04 and macOS 13.3.1

## Install Swift toolchain

* macOS: Install Xcode
* Ubuntu/Debian Linux, install from repository: [https://www.swiftlang.xyz/](https://www.swiftlang.xyz/)
* Linux or Windows: Download from [https://www.swift.org/download/](https://www.swift.org/download/)

## Build

```bash
git clone https://github.com/DimaRU/SwiftyBlockchain
cd SwiftyBlockchain
swift build
```

## Run

Start first node:

```
swift run Run serve --hostname 127.0.0.1 --port 8080
```

Start second node

```
swift run Run serve --hostname 127.0.0.1 --port 8081
```


## Documentation:

### API Endpoints
-------------

| Method | Route             | Comment       |
|--------|-------------------|---------------|
| GET    | /                 | Check work |
| GET    | /chain            | Fetch the blockchain |
| GET    | /nodes/resolve    | Syncronise blockchain |
| GET    | /mine             | Mining new block   |
| POST   | /transactions/add | Add new transaction |
| POST   | /nodes/register   | Register new node in the network |


Fetching the blockchain
-----------------------

```
curl -X GET http://localhost:8080/chain
```

```
{
  "chain": [
    {
      "nonce": 100,
      "timestamp": 1651744662.377732,
      "previous_hash": "1",
      "transactions": [
      ],
      "index": 1
    }
  ],
  "length": 1
}
```

Adding a new transaction
------------------------

```
curl -X POST http://localhost:8080/transactions/add \
  -H 'content-type: application/json' \
  -d '{
 "sender": "Alice",
 "recipient": "Bob",
 "amount": 5
}'
```

`Transaction added to Block 2`


Mining a new Block
------------------
```
curl -X GET http://localhost:8080/mine
```

```
{
  "message": "New Block Mined",
  "nonce": 33575,
  "previous_hash": "49b04ba15e4c658069d77dd22f8d21fb847a3bba92b92e4a5cdf0cff905e26cb",
  "transactions": [
    {
      "amount": 5,
      "recipient": "Bob",
      "sender": "Alice"
    },
    {
      "amount": 2,
      "recipient": "127.0.0.1:8080",
      "sender": ""
    }
  ],
  "index": 2
}
```

Registering a new Node in the Network
-------------------------------------
```
curl -X "POST" "http://127.0.0.1:8080/nodes/register" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "address": "http://127.0.0.1:8081"
}'
```

```
{
  "message": "New node added",
  "nodes": [
    "http://127.0.0.1:8081"
  ]
}
```

Syncronise blockchain and resolve conflicts
---------------------
```
curl -X GET "http://127.0.0.1:8080/nodes/resolve"
```

```
{
  "message": "Our chain was replaced",
  "chain": [
    {
      "nonce": 100,
      "timestamp": 1651697093.6841831,
      "previous_hash": "1",
      "transactions": [],
      "index": 1
    },
    {
      "nonce": 33575,
      "timestamp": 1651697144.188246,
      "previous_hash": "e790a22b1acd2f7a06efb941c8a6167468dcc5a39d25d72ace8360156f48033d",
      "transactions": [
        {
          "amount": 10,
          "recipient": "Bob",
          "sender": "Alice"
        },
        {
          "amount": 1,
          "recipient": "127.0.0.1:8081",
          "sender": "0"
        }
      ],
      "index": 2
    }
  ]
}
```


## License
[MIT](LICENSE)
