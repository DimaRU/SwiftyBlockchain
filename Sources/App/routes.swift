import Vapor

extension Application {
    var nodeId: String {
        let hostname = self.http.server.shared.localAddress?.hostname ?? "127.0.0.1"
        let port = self.http.server.shared.localAddress?.port ?? 8080
        return "\(hostname):\(port)"
    }
    
}

func routes(app: Application, blockchain: Blockchain) throws {
    app.get { req -> String in
        return "Welcome to Swifty Blockchain node \(app.nodeId)"
    }

    struct ChainResponce: Content {
        let chain: [Block]
        let length: Int
    }

   app.get("chain") { request -> ChainResponce in
       return ChainResponce(chain: blockchain.chain, length: blockchain.chain.count)
    }
    
    struct ResolveResponce: Content {
        let message: String
        let chain: [Block]
    }
    
    app.get("nodes", "resolve") { request -> ResolveResponce in
        let replaced = await blockchain.resolveConflicts(app)

        if replaced {
            return ResolveResponce(message: "This chain was replaced", chain: blockchain.chain)
        } else {
            return ResolveResponce(message: "This chain is authoritative", chain: blockchain.chain)
        }
    }
    
    
    struct MineResponce: Content {
        let message: String
        let index: UInt64
        let transactions: [Transaction]
        let nonce: UInt64
        let previous_hash: String
    }
    
    app.get("mine") { request -> MineResponce in
        let lastBlock = blockchain.chain.last!
        let lastNonce = lastBlock.nonce
        let nonce = blockchain.proofOfWork(lastNonce: lastNonce)
        
        // Add reward transation for finding the nonce.
        blockchain.addTransaction(sender: "", recipient: app.nodeId, amount: 2)
        
        let prevHash = blockchain.hash(block: lastBlock)
        let block = blockchain.addBlock(prevHash: prevHash, nonce: nonce)
        
        return MineResponce(message: "New Block Mined",
                            index: block.index,
                            transactions: block.transactions,
                            nonce: nonce,
                            previous_hash: prevHash)
    }

    struct TransactionRequest: Codable {
        var sender: String
        var recipient: String
        var amount: UInt64
    }
    
    app.post("transactions", "add") { request -> Response in
        guard let transaction = try? request.content.decode(TransactionRequest.self) else {
            throw Abort(.badRequest, reason: "Mailformed request")
        }
        let index = blockchain.addTransaction(sender: transaction.sender,
                                              recipient: transaction.recipient,
                                              amount: transaction.amount)

        return Response(status: .created, body: .init(string: "Transaction added to Block \(index)"))
    }

    struct RegisterRequest: Codable {
        var address: String
    }
    
    app.post("nodes", "register") { request -> Response in
        guard let registerRequest = try? request.content.decode(RegisterRequest.self) else {
            throw Abort(.badRequest, reason: "Mailformed request")
        }
        guard blockchain.registerNode(with: registerRequest.address) else {
            throw Abort(.badRequest, reason: "Invalid node")
        }
        
        struct RegisterResponse: Encodable {
            let message: String
            let nodes: [String]
        }
        
        let registerResponse = RegisterResponse(message: "New node added", nodes: Array(blockchain.nodes))
        let encoder = JSONEncoder()
        let data = try! encoder.encode(registerResponse)

        return Response(status: .created, body: .init(data: data))
    }

}
