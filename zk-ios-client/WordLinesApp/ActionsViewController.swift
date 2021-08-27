//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import WalletConnectSwift
import SpriteKit
import GameplayKit

import Web3
import Toast

import Web3ContractABI
import Web3PromiseKit


class ActionsViewController: UIViewController {
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var ethSendRawTransactionButton: UIButton!
    @IBOutlet weak var wordTextField: UITextField!
    
    var client: Client!
    var session: Session!
    
    let contractAddress = "0xb426733E5f42016fC9c5CDf1E66A760d1aE67Ba1"
    let pubSeed = getPublicSeed()
    
    var squareParams: gameSquareParameters!

    var currentWords: [String] = []
    
    static func create(walletConnect: WalletConnect) -> ActionsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let mainController = storyboard.instantiateViewController(withIdentifier: "ActionsViewController") as! ActionsViewController
        mainController.client = walletConnect.client
        mainController.session = walletConnect.session
        mainController.squareParams = mainController.getSquareParams()

        let gameView = gameSquare(params: mainController.squareParams)
        let controller = UIHostingController(rootView: gameView)
        mainController.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        mainController.view.addSubview(controller.view)
        controller.didMove(toParent: mainController)

        NSLayoutConstraint.activate([
            controller.view.widthAnchor.constraint(equalTo: mainController.view.widthAnchor, multiplier: 0.75),
            controller.view.heightAnchor.constraint(equalTo: mainController.view.widthAnchor, multiplier: 0.75),
            controller.view.centerXAnchor.constraint(equalTo: mainController.view.centerXAnchor),
            controller.view.bottomAnchor.constraint(equalTo: mainController.view.centerYAnchor, constant: -64)
        ])
        return mainController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wordTextField.delegate = self
    }

    var walletAccount: String {
        return session.walletInfo!.accounts[0]
    }
    
    var validWords: [String] {
        return pubSeed["human"]["dict"].arrayValue.map { $0.stringValue }
    }
    
    func getSquareParams() -> gameSquareParameters {
        let fig = pubSeed["human"]["figure"].arrayValue.map { $0.arrayValue.map { $0.stringValue }}
        let res = gameSquareParameters(figure: fig, lines: [])
        return res
    }

    @IBAction func disconnect(_ sender: Any) {
        guard let session = session else { return }
        try? client.disconnect(from: session)
    }
    
    @IBAction func eth_sendRawTransaction(_ sender: Any) {
        let contract = getContract(contractAddressString: self.contractAddress)
        let proof = getProofData(line: self.currentWords, pubSeed: self.pubSeed, walletAddress: self.walletAccount)
        let pi_a = proof["pi_a"].arrayValue.map { $0.stringValue }
        let big_pi_a = pi_a.map(EncodeHex)
        
        let pi_b = proof["pi_b"].arrayValue.map { $0.arrayValue.map { $0.stringValue } }
        let big_pi_b = pi_b.map { $0.map { EncodeHex(from: $0) } }
        
        let pi_c = proof["pi_c"].arrayValue.map { $0.stringValue }
        let big_pi_c = pi_c.map(EncodeHex)
        
        let inputs = proof["inputs"].arrayValue.map { $0.stringValue }
        let big_inputs = inputs.map(EncodeHex)

        guard let transaction = contract["mintItem"]?(try! EthereumAddress(hex: self.walletAccount, eip55: true),
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
}

fileprivate enum Stub {
    static func assemble_transaction(from_address: String, to_address: String, data: String) -> Client.Transaction {
        return Client.Transaction(from: from_address,
                                  to: to_address,
                                  data: data,
                                  gas: "0x1312d00", // 20 million
                                  gasPrice: nil,
                                  value: "0x0",
                                  nonce: nil
        )
    }
}


extension ActionsViewController: UITextFieldDelegate {
    func isContinual(currentWords: [String], nextWord: String) -> Bool {
        return (currentWords.count == 0) || (currentWords.last!.last! == nextWord.first!)
    }
    
    func addLines(word: String) {
        for i in 0...(word.count-2) {
            print(String(word[i]))
            squareParams.lines.append(String(word[i]) + String(word[i+1]))
            print("wtf \(squareParams.lines)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        defer { textField.text = nil }
        if (textField.text != nil) && self.validWords.contains(textField.text!) && isContinual(currentWords: self.currentWords, nextWord: textField.text!) {
            self.currentWords.append(textField.text!)
            self.addLines(word: textField.text!)
            textField.resignFirstResponder()
            return true
        }
        else {
            self.view.makeToast("Invalid word, try again!", position: .top)
            return false
        }
    }
}
