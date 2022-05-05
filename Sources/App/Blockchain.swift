//
//  Blockchain.swift
//  
//
//  Created by Dmitriy Borovikov on 04.05.2022.
//

import Foundation
import CryptoSwift
import Vapor

struct Block: Codable {
    var index: UInt64
    var timestamp: TimeInterval
    var transactions: [Transaction]
    var nonce: UInt64
    var previous_hash: String
}

struct Transaction: Codable {
    var sender: String
    var recipient: String
    var amount: UInt64
}

class Blockchain {
    // MARK: - Properties
    var chain: [Block]
    var transactions: [Transaction]
    var nodes: Set<String>
    
    // MARK: - Initializer
    init() {
        chain = []
        transactions = []
        nodes = Set()
        
        // Create the genesis block
        addBlock(prevHash: "1", nonce: 100)
    }
    
    // MARK: - Methods
 
    @discardableResult
    /// Creates a new block and adds it to the chain
    /// - Parameters:
    ///   - prevHash: Hash of previous Block
    ///   - nonce: The nonce given by the Proof of Work algorithm
    /// - Returns: created block
    func addBlock(prevHash: String?, nonce: UInt64) -> Block {
        let block = Block(index: UInt64(chain.count + 1),
                          timestamp: Date().timeIntervalSince1970,
                          transactions: transactions,
                          nonce: nonce,
                          previous_hash: prevHash ?? hash(block: chain.last!)
        )
        
        // Clear the current list of transactions
        transactions = []
        chain.append(block)
        
        return block
    }
    
    @discardableResult
    /// Add a new transaction to go into the next mined Block
    /// - Parameters:
    ///   - sender: sender address
    ///   - recipient: recipient address
    ///   - amount: amount transferred
    /// - Returns: The index of the Block that will hold this transaction
    func addTransaction(sender: String, recipient: String, amount: UInt64) -> UInt64 {
        let transaction = Transaction(sender: sender, recipient: recipient, amount: amount)
        transactions.append(transaction)
        
        return chain.last!.index + 1
    }
    
    /// Evaluate SHA-256 hash of a Block
    /// - Parameter block: chain block
    /// - Returns: hash string
    func hash(block: Block) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let str = try! String(data: encoder.encode(block), encoding: .utf8)!
        return str.sha256()
    }
    
    func proofOfWork(lastNonce: UInt64) -> UInt64 {
        var nonce: UInt64 = 0
        while !self.validateProof(prevNonce: lastNonce, nonce: nonce) {
            nonce += 1
        }
        
        return nonce
    }
    
    func validateProof(prevNonce: UInt64, nonce: UInt64) -> Bool {
        let guess = "\(prevNonce)\(nonce)"
        let guess_hash = guess.sha256()
        return guess_hash.suffix(4) == "0000"
    }
    
    func registerNode(with address: String) -> Bool {
        guard let url = URL(string: address) else {
            print("Invalid URL:", address)
            return false
        }
        let host = url.absoluteString
        nodes.insert(host)
        return true
    }
    
    func validateChain(_ chain: [Block]) -> Bool {
        var prevBlock: Block?
        
        for block in chain {
            guard let previousBlock = prevBlock else {
                prevBlock = block
                continue
            }
            // Check the hash of the block is correct
            // Check that the Proof of Work is correct
            let prevBlockHash = self.hash(block: previousBlock)
            guard block.previous_hash == prevBlockHash,
                  validateProof(prevNonce: previousBlock.nonce, nonce: block.nonce) else {
                return false
            }
            prevBlock = block
        }
        return true
    }
    
    /// Resolve chain conflicts
    /// - Parameter app: vapor app
    /// - Returns: True if our chain was replaced, False if not
    func resolveConflicts(_ app: Application) async -> Bool {
        var newChain: [Block]?
        var maxLength = self.chain.count

        // Grab and verify the chains from all the nodes in our network
        for node in nodes {
            struct ChainResponse: Decodable {
                let chain: [Block]
                let length: Int
            }
            
            let response: ClientResponse
            let url = URL(string: node)!.appendingPathComponent("chain")
            let uri = URI(string: url.absoluteString)
            do {
                response = try await app.client.get(uri)
            } catch {
                print(error)
                continue
            }
            guard response.status == .ok,
                  let data = try? response.content.decode(ChainResponse.self)
            else { continue }
            let length = data.length
            let chain = data.chain
            if length > maxLength, self.validateChain(chain) {
                maxLength = length
                newChain = chain
            }

        }

        if let newChain = newChain {
            self.chain = newChain
            return true
        }

        return false
    }
    
}
