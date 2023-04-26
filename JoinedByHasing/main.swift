//
//  main.swift
//  JoinedByHasing
//
//  Created by Kimleng Hor on 4/19/23.
//

import Foundation

/* MARK: Part 1. Data Generation. */

// file path to my relation txt file
let filePath = "/Users/kimlenghor/Documents/JoinedByHasing/relation.txt"

func generateData() {
    let numTuples = 5000

    let bRange = 10000...50000

    guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
        fatalError("Failed to create file handle for writing")
    }

    for _ in 0..<numTuples {
        let bValue = Int.random(in: bRange)
        let cValue = UUID().uuidString

        let tupleString = "\(bValue): \(cValue)\n"

        guard let data = tupleString.data(using: .utf8) else {
            fatalError("Failed to convert tuple string to data")
        }

        fileHandle.write(data)
    }

    fileHandle.closeFile()
}

//generateData()

/* MARK: Part 2. Virtual Disk I/O. */

var sHashTable = [Int: [Int]]()
var rHashTable = [Int: [Int]]()
var sDict = [Int: String]()

//create virtual main memory
struct VirtualMemory {
    let blockSize = 8
    let limit = 15
    var blocks = [Int: [Int]]()
    var hashTables = [Int: [Int]]()

    mutating func addBlockToMemory(blockNumber: Int, newElement: Int) {
        
        if blocks[blockNumber]?.count != blockSize {
            if blocks[blockNumber] != nil {
                blocks[blockNumber]?.append(newElement)
            } else {
                blocks[blockNumber] = [newElement]
            }
        } else {
            //memory of the block is full
            //write to the disk
            writeToDiskFromMainMemory(blockNumber: blockNumber, values: blocks[blockNumber] ?? [], hashTable: &hashTables)
            
            //remove everything
            blocks[blockNumber]?.removeAll()
            
            //add the new element to the block
            blocks[blockNumber]?.append(newElement)
        }
    }
    
    func joinedByHashing() -> [(Int, Int, String)] {
        var result = [(Int, Int, String)]()
        for (rKey, rValues) in rHashTable {
            for element in rValues {
                if let sValues = sHashTable[rKey] {
                    if sValues.contains(randomRDict[element] ?? 0) {
                        let tuple = (element, randomRDict[element]!, sDict[randomRDict[element]!] ?? "")
                        result.append(tuple)
                    }
                }
            }
        }
        return result
    }
}

//tuple
struct S {
    var B: Int
    var C: String
}

struct R {
    var A: Int
    var B: String
}

var virtualMemory = VirtualMemory()

//hash function
func hashFunction(key: Int, numBlocks: Int) -> Int {
    let hashValue = key % numBlocks
    return hashValue
}

func readFromFile() {
    //reads from the virtual disk to the virtual main memory
    guard let fileString = try? String(contentsOfFile: filePath) else {
        fatalError("Error: failed to read file")
    }

    // print the file content
    let tuples = fileString.split(separator: "\n")

    for tuple in tuples {
        let values = tuple.split(separator: ":")
        let s = S(B: Int(values.first!)!, C: String(values.last!).replacingOccurrences(of: " ", with: ""))
        sDict[s.B] = s.C
    }
}

readFromFile()

func readFromDiskToMainMemory(values: [Int]) -> [Int: [Int]] {

    let virtualMemorySize = 15

    //apply the hash function to add into the block in virtual memory
    for value in values {
        let blockNumber = hashFunction(key: value, numBlocks: virtualMemorySize)
        virtualMemory.addBlockToMemory(blockNumber: blockNumber, newElement: value)
    }
    
    return virtualMemory.hashTables
}

let sDictArray = Array(sDict.keys) as! [Int]
sHashTable = readFromDiskToMainMemory(values: sDictArray)

func writeToDiskFromMainMemory(blockNumber: Int, values: [Int], hashTable: inout [Int: [Int]]) {
    if hashTable[blockNumber] != nil {
        hashTable[blockNumber]?.append(contentsOf: values)
    } else {
        hashTable[blockNumber] = values
    }
}

func randomPickFromS() -> [Int: Int] {
    var rDict = [Int: Int]()
    let randomTuples = sDict.keys.shuffled().prefix(1000)
    
    for i in 0..<1000 {
        rDict[i] = randomTuples[i]
    }
    
    return rDict
}

//let randomRDict = randomPickFromS()

func randomPickFromRange() -> [Int: Int] {
    var rDict = [Int: Int]()
    let rRange = 20000...30000
    
    
    for i in 20000..<30000 {
        let randomR = Int.random(in: rRange)
        rDict[i] = randomR
    }
    
    return rDict
}

let randomRDict = randomPickFromRange()

let rDictArray = Array(randomRDict.keys) as! [Int]
rHashTable = readFromDiskToMainMemory(values: rDictArray)

let result = virtualMemory.joinedByHashing()
print(result)
