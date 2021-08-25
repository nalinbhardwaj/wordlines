//
//  gameSquare.swift
//  WordLines
//
//  Created by Nalin Bhardwaj on 25/08/21.
//  Copyright © 2021 nibnalin. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreGraphics

class gameSquareParameters: ObservableObject {
    @Published var lines: [String]
    @Published var figure: [[String]]

    struct Node {
        let center: CGPoint
        let adjustment: CGPoint
        let radius: CGFloat
        let letter: String
    }
    
    struct Line {
        let startNode: Node
        let endNode: Node
    }
    
    var nodes: [Node] {
        return [
            // top side node
            Node(
                center: CGPoint(x: 0.3, y: 0.1),
                adjustment: CGPoint(x: 0.3, y: 0.1 + 0.04),
                radius: 0.05,
                letter: figure[0][0]
            ),
            Node(
                center: CGPoint(x: 0.5, y: 0.1),
                adjustment: CGPoint(x: 0.5, y: 0.1 + 0.04),
                radius: 0.05,
                letter: figure[0][1]
            ),
            Node(
                center: CGPoint(x: 0.7, y: 0.1),
                adjustment: CGPoint(x: 0.7, y: 0.1 + 0.04),
                radius: 0.05,
                letter: figure[0][2]
            ),
            // bottom side node
            Node(
                center: CGPoint(x: 0.3, y: 0.9),
                adjustment: CGPoint(x: 0.3, y: 0.9 - 0.04),
                radius: 0.05,
                letter: figure[1][0]
            ),
            Node(
                center: CGPoint(x: 0.5, y: 0.9),
                adjustment: CGPoint(x: 0.5, y: 0.9 - 0.04),
                radius: 0.05,
                letter: figure[1][1]
            ),
            Node(
                center: CGPoint(x: 0.7, y: 0.9),
                adjustment: CGPoint(x: 0.7, y: 0.9 - 0.04),
                radius: 0.05,
                letter: figure[1][2]
            ),
            // left side node
            Node(
                center: CGPoint(x: 0.1, y: 0.3),
                adjustment: CGPoint(x: 0.1 + 0.04, y: 0.3),
                radius: 0.05,
                letter: figure[2][0]
            ),
            Node(
                center: CGPoint(x: 0.1, y: 0.5),
                adjustment: CGPoint(x: 0.1 + 0.04, y: 0.5),
                radius: 0.05,
                letter: figure[2][1]
            ),
            Node(
                center: CGPoint(x: 0.1, y: 0.7),
                adjustment: CGPoint(x: 0.1 + 0.04, y: 0.7),
                radius: 0.05,
                letter: figure[2][2]
            ),
            // right side node
            Node(
                center: CGPoint(x: 0.9, y: 0.3),
                adjustment: CGPoint(x: 0.9 - 0.04, y: 0.3),
                radius: 0.05,
                letter: figure[3][0]
            ),
            Node(
                center: CGPoint(x: 0.9, y: 0.5),
                adjustment: CGPoint(x: 0.9 - 0.04, y: 0.5),
                radius: 0.05,
                letter: figure[3][1]
            ),
            Node(
                center: CGPoint(x: 0.9, y: 0.7),
                adjustment: CGPoint(x: 0.9 - 0.04, y: 0.7),
                radius: 0.05,
                letter: figure[3][2]
            )
        ]
    }
    
    init(figure: [[String]], lines: [String]) {
        self.figure = figure
        self.lines = lines
    }
    
    func parametriseLine(line: String) -> Line {
        var startNode: Node?
        var endNode: Node?
        for node in self.nodes {
            if String(line[0]) == node.letter {
                startNode = node
            }
            if String(line[1]) == node.letter {
                endNode = node
            }
        }
        return Line(startNode: startNode!, endNode: endNode!)
    }
}

struct gameLine: View {
    let line: gameSquareParameters.Line
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = min(geometry.size.width, geometry.size.height)
            let height = width
            
            Path { path in
                path.move(to: CGPoint(x: line.startNode.adjustment.x * width, y: line.startNode.adjustment.y * height))
                path.addLine(to: CGPoint(x: line.endNode.adjustment.x * width, y: line.endNode.adjustment.y * height))
            }.stroke(lineWidth: 3.0).fill(Color.blue)
            
            Path { path in
                path.move(to: CGPoint(x: line.startNode.center.x * width, y: line.startNode.center.y * height))
                path.addArc(
                    center: CGPoint(x: width * line.startNode.center.x, y: height * line.startNode.center.y),
                    radius: line.startNode.radius * width,
                    startAngle: Angle(degrees: 0.0),
                    endAngle: Angle(degrees: 0.1),
                    clockwise: true)
                path.move(to: CGPoint(x: line.endNode.center.x * width, y: line.endNode.center.y * height))
                path.addArc(
                    center: CGPoint(x: width * line.endNode.center.x, y: height * line.endNode.center.y),
                    radius: line.endNode.radius * width,
                    startAngle: Angle(degrees: 0.0),
                    endAngle: Angle(degrees: 0.1),
                    clockwise: true)
            }.strokedPath(StrokeStyle(lineWidth: 1.0, dash: [4]))
        }
    }
}

struct gameNodeFill: View {
    let node: gameSquareParameters.Node
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = min(geometry.size.width, geometry.size.height)
            let height = width
            
            Path { path in
                path.move(to: node.center)
                path.addArc(
                    center: CGPoint(x: width * node.center.x, y: height * node.center.y),
                    radius: node.radius * width,
                    startAngle: Angle(degrees: 0.0),
                    endAngle: Angle(degrees: 0.1),
                    clockwise: true)
            }.fill(Color.blue)
        }
    }
}

struct gameNodeText: View {
    let node: gameSquareParameters.Node
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = min(geometry.size.width, geometry.size.height)
            let height = width
            
            Text(node.letter.uppercased()).position(x: width * node.center.x, y: height * node.center.y).foregroundColor(.white)
        }
    }
}


struct gameSquare: View {
    @StateObject var params: gameSquareParameters
    
    var lineStrokes: some View {
        ForEach(params.lines, id: \.self) { line in
            gameLine(line: params.parametriseLine(line: line))
        }
    }
    
    var nodeFills: some View {
        ForEach(0..<params.nodes.count) {i in
            gameNodeFill(node: params.nodes[i])
        }
    }
    
    var letters: some View {
        ForEach(0..<params.nodes.count) {i in
            gameNodeText(node: params.nodes[i])
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.8, alignment: .center)
                lineStrokes
                nodeFills
                letters
            }
        }
    }
}

struct gameSquare_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let params = gameSquareParameters(figure: [["l", "u", "k"], ["r", "m", "i"], ["s", "c", "n"], ["o", "g", "f"]], lines: ["ci"])
            gameSquare(params: params).frame(width: 256, height: 256, alignment: .center)
        }
    }
}
