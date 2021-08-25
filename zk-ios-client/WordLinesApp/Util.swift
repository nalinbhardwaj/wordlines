//
//  Util.swift
//  ClientApp
//
//  Created by Nalin Bhardwaj on 22/08/21.
//  Copyright © 2021 Gnosis. All rights reserved.
//

import Foundation

import Web3
import Web3PromiseKit
import Web3ContractABI

import SwiftyJSON

func getWeb3() -> Web3 {
    return Web3(rpcURL: "https://rinkeby.infura.io/v3/94ab4cf52228436fa729f0c77b91fdf0")
}

func getContractABIString() -> String {
    var request = URLRequest(url: URL(string: "https://wordlines.herokuapp.com/wordlines.abi")!)
    request.httpMethod = "GET"
    var contractABIString = ""
    let sem = DispatchSemaphore(value: 0)

    URLSession.shared.dataTask(with: request) {data, response, err in
        defer { sem.signal() }
        contractABIString = String(data: data!, encoding: .utf8)!
    }.resume()

    sem.wait()
    
    return contractABIString
}

func getContract(contractAddressString: String) -> DynamicContract {
    let contractJsonABI = getContractABIString().data(using: .utf8)!
    print(contractJsonABI)

    let web3 = getWeb3()

    let contractAddress = try! EthereumAddress(hex: contractAddressString, eip55: true)
    // You can optionally pass an abiKey param if the actual abi is nested and not the top level element of the json
    let contract = try! web3.eth.Contract(json: contractJsonABI, abiKey: "abi", address: contractAddress)
    return contract
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

func getPublicSeed() -> JSON {
    var request = URLRequest(url: URL(string: "https://wordlines.herokuapp.com/pubseed.json")!)
    request.httpMethod = "GET"
   
    var responseJSON: JSON = []
    let sem = DispatchSemaphore(value: 0)

    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { sem.signal() }
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
            print("error", error ?? "Unknown error")
            return
        }

        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            return
        }

        responseJSON = try! JSON(data: data)
        print("responseJSON = \(String(describing: responseJSON))")
    }.resume()

    sem.wait()

    return responseJSON
}

extension Character {
    var isAscii: Bool {
        return unicodeScalars.allSatisfy { $0.isASCII }
    }
    var ascii: UInt32? {
        return isAscii ? unicodeScalars.first?.value : nil
    }
}

extension StringProtocol {
    var asciiValues: [UInt32] {
        return compactMap { $0.ascii }
    }
}

func encodePolyHash(line: [String]) -> [String] {
    let WORD_SIZE = 6
    let LINE_SIZE = 7
    
    func getPaddingHash() -> BigUInt {
        var hash = BigUInt(0)
        for _ in 0..<WORD_SIZE {
            hash *= BigUInt(32)
            hash += BigUInt(28)
        }
        return hash
    }
    
    var res: [String] = []
    for word in line {
        var hash = BigUInt(0)
        for ch in word.asciiValues {
            hash *= BigUInt(32)
            hash += try! BigUInt(ch - Character("a").ascii!)
        }
        for _ in 0..<(WORD_SIZE-word.asciiValues.count) {
            hash *= BigUInt(32)
            hash += BigUInt(27)
        }
        res.append(hash.description)
    }
    while res.count < LINE_SIZE {
        res.append(getPaddingHash().description)
    }
    print("hash \(res)")
    return res
}

func getProofData(line: [String], pubSeed: JSON, walletAddress: String) -> JSON {
    let walletAddressIntegered = EncodeHex(from: walletAddress)
    
    var request = URLRequest(url: URL(string: "https://wordlines.herokuapp.com/generate_proof")!)
    request.httpMethod = "POST"
    
    let parameters: [String: Any] = [
        "line": encodePolyHash(line: line),
        "figure": pubSeed["computer"]["figure"].stringValue,
        "compressed_dictionary": pubSeed["computer"]["compressed_dictionary"].arrayValue.map { $0.stringValue },
        "address": String(walletAddressIntegered),
        "private_address": String(walletAddressIntegered)
    ]
    let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
    request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    var responseJSON: JSON = []
    let sem = DispatchSemaphore(value: 0)

    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { sem.signal() }
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
            print("error", error ?? "Unknown error")
            return
        }

        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            return
        }

        responseJSON = try! JSON(data: data)
        print("responseJSON = \(String(describing: responseJSON))")
    }.resume()

    sem.wait()
    
    return responseJSON
}

public extension String {
  subscript(value: Int) -> Character {
    self[index(at: value)]
  }
    
  var fullyPercentEncodedStr: String {
    self.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }
}

public extension String {
  subscript(value: NSRange) -> Substring {
    self[value.lowerBound..<value.upperBound]
  }
}

public extension String {
  subscript(value: CountableClosedRange<Int>) -> Substring {
    self[index(at: value.lowerBound)...index(at: value.upperBound)]
  }

  subscript(value: CountableRange<Int>) -> Substring {
    self[index(at: value.lowerBound)..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeUpTo<Int>) -> Substring {
    self[..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeThrough<Int>) -> Substring {
    self[...index(at: value.upperBound)]
  }

  subscript(value: PartialRangeFrom<Int>) -> Substring {
    self[index(at: value.lowerBound)...]
  }
}

private extension String {
  func index(at offset: Int) -> String.Index {
    index(startIndex, offsetBy: offset)
  }
}

func EncodeHex(from: String) -> BigUInt {
    return BigUInt(hexString: String(from[2...]))!
}
