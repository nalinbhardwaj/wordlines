//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

import Web3

import Web3ContractABI
import Web3PromiseKit


class ActionsViewController: UIViewController {
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var personalSignButton: UIButton!
    @IBOutlet weak var ethSignButton: UIButton!
    @IBOutlet weak var ethSignTypedDataButton: UIButton!
    @IBOutlet weak var ethSendTransactionButton: UIButton!
    @IBOutlet weak var ethSignTransactionButton: UIButton!
    @IBOutlet weak var ethSendRawTransactionButton: UIButton!
    @IBOutlet weak var ethCustomRequestButton: UIButton!

    var client: Client!
    var session: Session!
    
    let contractAddress = "0xb426733E5f42016fC9c5CDf1E66A760d1aE67Ba1"

    static func create(walletConnect: WalletConnect) -> ActionsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ActionsViewController") as! ActionsViewController
        controller.client = walletConnect.client
        controller.session = walletConnect.session
        return controller
    }

    var walletAccount: String {
        return session.walletInfo!.accounts[0]
    }

    @IBAction func disconnect(_ sender: Any) {
        guard let session = session else { return }
        try? client.disconnect(from: session)
    }

    // personal_sign should send a human readable message
    @IBAction func personal_sign(_ sender: Any) {
        try? client.personal_sign(url: session.url, message: "Hi there!", account: session.walletInfo!.accounts[0]) {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }

    // eth_sign should send a properly formed hash: keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))
    @IBAction func eth_sign(_ sender: Any) {
        try? client.eth_sign(url: session.url, account: session.walletInfo!.accounts[0], message: "0x0123") {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }

    @IBAction func eth_signTypedData(_ sender: Any) {
        try? client.eth_signTypedData(url: session.url,
                                      account: session.walletInfo!.accounts[0],
                                      message: Stub.typedData) {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature") }
    }

    @IBAction func eth_sendTransaction(_ sender: Any) {
        // example when we make 2 chained requests: 1) get nonce 2) sendTransaction
        try? client.send(nonceRequest()) { [weak self] response in
            guard let self = self, let nonce = self.nonce(from: response) else { return }
            let transaction = Stub.transaction(from: self.walletAccount, nonce: nonce)
            try? self.client.eth_sendTransaction(url: response.url, transaction: transaction) { [weak self] response in
                self?.handleReponse(response, expecting: "Hash")
            }
        }
    }

    @IBAction func eth_signTransaction(_ sender: Any) {
        let transaction = Stub.transaction(from: self.walletAccount, nonce: "0x0")
        try? self.client.eth_signTransaction(url: session.url, transaction: transaction) { [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }
    
    @IBAction func eth_sendRawTransaction(_ sender: Any) {
        let contract = getContract(contractAddressString: self.contractAddress)
        let proof = getProofData(walletAddress: self.walletAccount)
        let pi_a = proof["pi_a"].arrayValue.map { $0.stringValue }
        let big_pi_a = pi_a.map(EncodeHex)
        
        let pi_b = proof["pi_b"].arrayValue.map { $0.arrayValue.map { $0.stringValue } }
        let big_pi_b = pi_b.map { $0.map { EncodeHex(from: $0) } }
        
        let pi_c = proof["pi_c"].arrayValue.map { $0.stringValue }
        let big_pi_c = pi_c.map(EncodeHex)
        
        let inputs = proof["inputs"].arrayValue.map { $0.stringValue }
        let big_inputs = inputs.map(EncodeHex)

        guard let transaction = contract["mintItem"]?(try! EthereumAddress(hex: self.walletAccount, eip55: true),
                                                       "QmWncWK3cherDbRgkzzqZRfxAaShti29MTEMpFUmEcysXi",
                                                       big_pi_a as ABIEncodable,
                                                       big_pi_b as ABIEncodable,
                                                       big_pi_c as ABIEncodable,
                                                       big_inputs as ABIEncodable
        ).createTransaction(nonce: 0, from: try! EthereumAddress(hex: self.walletAccount, eip55: true), value: 0, gas: 0, gasPrice: EthereumQuantity(quantity: 21.gwei)) else {
            print("sad")
            return
        }
        print(transaction.data.hex())
        
        let wc_transaction = Stub.assemble_transaction(from_address: self.walletAccount, to_address: self.contractAddress, data: transaction.data.hex())
        try? self.client.eth_sendTransaction(url: session.url, transaction: wc_transaction) { [weak self] response in
            self?.handleReponse(response, expecting: "Hash")
        }
    }

    @IBAction func customRequest(_ sender: Any) {
        try? client.send(.eth_gasPrice(url: session.url)) { [weak self] response in
            self?.handleReponse(response, expecting: "Gas Price")
        }
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }

    private func handleReponse(_ response: Response, expecting: String) {
        if let error = response.error {
            show(UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert))
            return
        }
        do {
            let result = try response.result(as: String.self)
            show(UIAlertController(title: expecting, message: result, preferredStyle: .alert))
        } catch {
            show(UIAlertController(title: "Error",
                                      message: "Unexpected response type error: \(error)",
                                      preferredStyle: .alert))
        }
    }

    private func show(_ alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    private func nonceRequest() -> Request {
        return .eth_getTransactionCount(url: session.url, account: session.walletInfo!.accounts[0])
    }

    private func nonce(from response: Response) -> String? {
        return try? response.result(as: String.self)
    }
}

extension Request {
    static func eth_getTransactionCount(url: WCURL, account: String) -> Request {
        return try! Request(url: url, method: "eth_getTransactionCount", params: [account, "latest"])
    }

    static func eth_gasPrice(url: WCURL) -> Request {
        return Request(url: url, method: "eth_gasPrice")
    }
}

fileprivate enum Stub {
    /// https://docs.walletconnect.org/json-rpc/ethereum#example-parameters
    static let typedData = """
[
  "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
  {
    "types": {
      "EIP712Domain": [
        {
          "name": "name",
          "type": "string"
        },
        {
          "name": "version",
          "type": "string"
        },
        {
          "name": "chainId",
          "type": "uint256"
        },
        {
          "name": "verifyingContract",
          "type": "address"
        }
      ],
      "Person": [
        {
          "name": "name",
          "type": "string"
        },
        {
          "name": "wallet",
          "type": "address"
        }
      ],
      "Mail": [
        {
          "name": "from",
          "type": "Person"
        },
        {
          "name": "to",
          "type": "Person"
        },
        {
          "name": "contents",
          "type": "string"
        }
      ]
    },
    "primaryType": "Mail",
    "domain": {
      "name": "Ether Mail",
      "version": "1",
      "chainId": 1,
      "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
      "from": {
        "name": "Cow",
        "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
      },
      "to": {
        "name": "Bob",
        "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
      },
      "contents": "Hello, Bob!"
    }
  }
]
"""

    /// https://docs.walletconnect.org/json-rpc/ethereum#example-parameters-1
    static func transaction(from address: String, nonce: String) -> Client.Transaction {
        return Client.Transaction(from: address,
                                  to: "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
                                  data: "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
                                  gas: "0x76c0", // 30400
            gasPrice: "0x9184e72a000", // 10000000000000
            value: "0x9184e72a", // 2441406250
            nonce: nonce)
    }
    
    static func assemble_transaction(from_address: String, to_address: String, data: String) -> Client.Transaction {
        return Client.Transaction(from: from_address,
                                  to: to_address,
                                  data: data,
                                  gas: "0x1e8480", // 2 million
                                  gasPrice: nil,
                                  value: "0x0",
                                  nonce: nil
        )
    }

    /// https://docs.walletconnect.org/json-rpc/ethereum#example-5
    static let data = "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f07244567"

}

