//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    var handshakeController: HandshakeViewController!
    var actionsController: ActionsViewController!
    var walletConnect: WalletConnect!

    @IBAction func connect(_ sender: Any) {
        let connectionUrl = walletConnect.connect()
        let uri = connectionUrl.fullyPercentEncodedStr
        var delimiter: String
        
        let link = "https://rnbwapp.com"
        
        if link.contains("http") {
            delimiter = "/"
        } else {
            delimiter = "//"
        }
        let urlStr = "\(link)\(delimiter)wc?uri=\(uri)"
        
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            handshakeController = HandshakeViewController.create(code: connectionUrl)
            present(handshakeController, animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        walletConnect = WalletConnect(delegate: self)
        walletConnect.reconnectIfNeeded()
    }

    func onMainThread(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
}

extension MainViewController: WalletConnectDelegate {
    func failedToConnect() {
        onMainThread { [unowned self] in
            if let handshakeController = self.handshakeController {
                handshakeController.dismiss(animated: true)
            }
            UIAlertController.showFailedToConnect(from: self)
        }
    }

    func didConnect() {
        onMainThread { [unowned self] in
            self.actionsController = ActionsViewController.create(walletConnect: self.walletConnect)
            if let handshakeController = self.handshakeController {
                handshakeController.dismiss(animated: false) { [unowned self] in
                    self.present(self.actionsController, animated: false)
                }
            } else if self.presentedViewController == nil {
                self.present(self.actionsController, animated: false)
            }
        }
    }

    func didDisconnect() {
        onMainThread { [unowned self] in
            if let presented = self.presentedViewController {
                presented.dismiss(animated: false)
            }
            UIAlertController.showDisconnected(from: self)
        }
    }
}

extension UIAlertController {
    func withCloseButton() -> UIAlertController {
        addAction(UIAlertAction(title: "Close", style: .cancel))
        return self
    }

    static func showFailedToConnect(from controller: UIViewController) {
        let alert = UIAlertController(title: "Failed to connect", message: nil, preferredStyle: .alert)
        controller.present(alert.withCloseButton(), animated: true)
    }

    static func showDisconnected(from controller: UIViewController) {
        let alert = UIAlertController(title: "Did disconnect", message: nil, preferredStyle: .alert)
        controller.present(alert.withCloseButton(), animated: true)
    }
}
