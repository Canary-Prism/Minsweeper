// The Swift Programming Language
// https://docs.swift.org/swift-book

import MinsweeperGame

//let unholy_variable = 
//    (3, 5, (mrrp: 3, 4, (1, nya: 5), 3), ["mrrp"], 3, teehee: ["we do a little funny": ">:3"], mrrp: 3, havent_we_used_that_name_before: nil as String?, 4, (1, nya: 5), 3..<1, (mrrp: 3, 3), {() -> (Int, (Int?, Int, teehee: String?))? in return nil}, (3 as? String)!, (3, 6, "3", "nyaaa", mrrp: "nya :3"), lol: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], (meww: 5, [3, { (meww: "mrrp", (3, teehee: "mrrp nya")) }, (ew: {["mrrp", "meww", (3, 4, D: 3...)]}, 3)]))



let game = try! Minsweeper(width: 30, height: 30, mines: 1, onWin: {print("hooray")}, onLose: {print("womp womp")})

let gamestate = game.start()

func printBoard(board: [[Cell]]) {
    print("   ", terminator: "")
    for i in 0..<board[0].endIndex {
        print(i, terminator: "  ")
    }
    print()
    for i in 0..<board.endIndex {
        print(i, board[i], separator: " ")
    }
}

printBoard(board: gamestate.board)

while let input = readLine() {
    let split = input.split(separator: " ")
    guard split.count == 3 else { continue }
    guard let x = Int(split[0]), let y = Int(split[1]) else { continue }
    guard x >= 0 && x < gamestate.board.endIndex && y >= 0 && y < gamestate.board[x].endIndex else { continue }

    guard ["l", "r"].contains(split[2]) else { continue }

    let gamestate = switch split[2] {
        case "l":
            game.leftClick(x: x, y: y)
        case "r":
            game.rightClick(x: x, y: y)
        default:
            fatalError("What?")
    }

    printBoard(board: gamestate.board)
}
