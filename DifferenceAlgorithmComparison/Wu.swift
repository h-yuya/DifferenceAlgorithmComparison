//
//  Wu.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/02/17.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

struct Wu<E: Equatable> {
    enum Script: CustomStringConvertible, Equatable {
        case delete(at: Int)
        case insert(from: Int, to: Int)
        case insertToHead(from: Int)
        case sourceScript
        
        var description: String {
            switch self {
            case .delete(let atIndex):
                return "D(\(atIndex))"
                
            case .insert(let fromIndex, let toIndex):
                return "I(\(fromIndex), \(toIndex))"
                
            case .insertToHead(let fromIndex):
                return "IH(\(fromIndex))"
                
            case .sourceScript:
                return "No Script"
            }
        }
        
        static func ==(lhs: Script, rhs: Script) -> Bool {
            switch (lhs, rhs) {
            case let (.delete(lfi), .delete(rfi)):
                return lfi == rfi
                
            case let (.insert(lfi, lti), .insert(rfi, rti)):
                return lfi == rfi && lti == rti
                
            case let (.insertToHead(lfi), .insertToHead(rfi)):
                return lfi == rfi
                
            case (.sourceScript, .sourceScript):
                return true
                
            default:
                return false
            }
        }
    }
    
    static func diff(from fromArray: Array<E>, to toArray: Array<E>) -> Array<Script> {
        if fromArray.count == 0 && toArray.count == 0 {
            return []
        } else if fromArray.count == 0 && toArray.count > 0 {
            return (0...toArray.count - 1).reversed().map { Script.insertToHead(from: $0) }
        } else if fromArray.count > 0 && toArray.count == 0 {
            return (0...fromArray.count - 1).map { Script.delete(at: $0) }
        } else {
            let path = exploreEditGraph(from: fromArray, to: toArray)
            return reverseTree(path: path, sinkVertice: .vertice(x: fromArray.count, y: toArray.count))
        }
    }
}

private extension Wu {
    typealias Edge = (D: Int, from: Vertice, to: Vertice, script: Script, snakeCount: Int)
    
    static func reverseTree(path: Array<Edge>, sinkVertice: Vertice) -> Array<Script> {
        var nextToVertice = sinkVertice
        var scripts = Array<Script>()
        
        path.reversed().forEach { D, fromVertice, toVertice, script, snakeCount in
            guard toVertice.snakeOffset(by: snakeCount) == nextToVertice else { return }
            nextToVertice = fromVertice
            
            switch script {
            case .delete, .insert, .insertToHead:
                scripts.append(script)
                
            case .sourceScript:
                break
            }
        }
        
        return scripts
    }
    
    static func exploreEditGraph(from fromArray: Array<E>, to toArray: Array<E>) -> Array<Edge> {
        let fromCount = fromArray.count
        let toCount = toArray.count
        if fromCount > toCount { return exploreEditGraph(from: toArray, to: fromArray) }
        
        let totalCount = toCount + fromCount
        let delta = toCount - fromCount
        var furthestReaching = Array(repeating: 0, count: totalCount + 2)
        var path = Array<Edge>()
        
        let snake: (Int, Int) -> Int = { k, y in
            var _y = y
            while _y - k < fromCount && _y < toCount && fromArray.safeGet(at: _y - k) == toArray.safeGet(at: _y) {
                _y += 1
            }
            return _y
        }
        
        for p in 0...fromCount {
            let lowerRange = -p...delta - 1
            
            for k in lowerRange {
                let index = k + fromCount
                let m = k == -fromCount ? furthestReaching[index + 1] : max(furthestReaching[index - 1] + 1, furthestReaching[index + 1])
                furthestReaching[index] = snake(k, m)
            }
            
            if p >= 1 {
                let upperRange = (delta + 1...delta + p).reversed()
                for k in upperRange {
                    let index = k + fromCount
                    let m = max(furthestReaching[index - 1] + 1, furthestReaching[index + 1])
                    furthestReaching[index] = snake(k, m)
                }
            }
            
            let m = max(furthestReaching[delta - 1] + 1, furthestReaching[delta + 1])
            furthestReaching[delta] = snake(delta, m)
            
            if furthestReaching[delta] >= toCount {
                return []
            }
        }
        
        return []
    }
}

private extension Wu {
    enum Vertice: Equatable {
        case vertice(x: Int, y: Int)
        
        func snakeOffset(by count: Int) -> Vertice {
            guard case let .vertice(x, y) = self else { return self }
            return .vertice(x: x + count, y: y + count)
        }
        
        static func ==(lhs: Vertice, rhs: Vertice) -> Bool {
            guard case let .vertice(lx, ly) = lhs,
                case let .vertice(rx, ry) = rhs else { return false }
            return lx == rx && ly == ry
        }
    }
}

private extension Array {
    func safeGet(at index: Int) -> Element? {
        guard (0...count - 1).contains(index) else { return nil }
        return self[index]
    }
}
