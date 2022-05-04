import Vapor

// Instance of blockchain
fileprivate let blockchain = Blockchain()

// configures your application
public func configure(_ app: Application) throws {
    // register routes
    try routes(app: app, blockchain: blockchain)
}
