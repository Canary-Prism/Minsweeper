public class Minsweeper {

    public init(width: Int, height: Int, mines: Int, onWin: @escaping () -> Void = {}, onLose: @escaping () -> Void = {}) throws {
        let size = (width: width, height: height, mines: mines)
        self.sizes = size
        self.onWin = onWin
        self.onLose = onLose

        guard size.width > 0 && size.height > 0 else { throw InitializationError.invalidSize }
        guard size.mines < size.width * size.height else { throw InitializationError.tooManyMines }
        guard size.mines > 0 else { throw InitializationError.tooFewMines }
    }
    public convenience init(size: ConventionalSizes, onWin: @escaping () -> Void = {}, onLose: @escaping () -> Void = {}) {
        switch size {
        case .beginner:
            try! self.init(width: 9, height: 9, mines: 10, onWin: onWin, onLose: onLose)
        case .intermediate:
            try! self.init(width: 16, height: 16, mines: 40, onWin: onWin, onLose: onLose)
        case .expert:
            try! self.init(width: 30, height: 16, mines: 99, onWin: onWin, onLose: onLose)
        }
    }

    let sizes: (width: Int, height: Int, mines: Int)

    let onWin: () -> Void
    let onLose: () -> Void


    var gamestate: GameState = GameState(status: .never, board: [], remaining_mines: -1)

    /// creates a new game with the same size, resetting the board
    /// - Returns: the state of the new game
    public func start() -> GameState {

        var temp_board = Array(repeating: Array(repeating: Cell.unknown(0), count: sizes.width), count: sizes.height)

        var mines = 0
        while (mines < sizes.mines) {
            let x = Int.random(in: 0..<sizes.width)
            let y = Int.random(in: 0..<sizes.height)

            if case .unknown = temp_board.get(x: x, y: y) {
                temp_board.set(x: x, y: y, newValue: .mine)
                mines += 1
            }
        }

        generateNumbers(&temp_board)

        gamestate = GameState(status: .playing, board: temp_board, remaining_mines: sizes.mines)

        first = true
        
        return gamestate.hideMines()
    }

    private func generateNumbers(_ board: inout [[Cell]]) {
        for y in 0..<board.endIndex {
            for x in 0..<board[y].endIndex {
                if case .unknown = board.get(x: x, y: y) {
                    board.set(x: x, y: y, newValue: .unknown(0))
                }
                // if case .revealed = board.get(x: x, y: y) {
                //     board.set(x: x, y: y, newValue: .revealed(0))
                // }
            }
        }
        for y in 0..<board.endIndex {
            for x in 0..<board[y].endIndex {
                if case .mine = board.get(x: x, y: y) {
                    for y2 in max(0, y-1)...min(board.endIndex-1, y+1) {
                        for x2 in max(0, x-1)...min(board[y2].endIndex-1, x+1) {
                            if case .unknown(let number) = board.get(x: x2, y: y2) {
                                board.set(x: x2, y: y2, newValue: .unknown(number+1))
                            }
                        }
                    }
                }
            }
        }
    }

    var first = false

    private func revealEmpty(x: Int, y: Int, board: inout [[Cell]]) {
        guard case .unknown = board.get(x: x, y: y) else { return }

        board.set(x: x, y: y, newValue: .revealed(0))

        for y2 in max(0, y - 1)...min(board.endIndex - 1, y + 1) {
            for x2 in max(0, x - 1)...min(board[y2].endIndex - 1, x + 1) {
                if case .unknown(let number) = board.get(x: x2, y: y2) {
                    if number == 0 {
                        revealEmpty(x: x2, y: y2, board: &board)
                    } else {
                        board.set(x: x2, y: y2, newValue: .revealed(number))
                    }
                }
            }
        }
    }

    private func internalReveal(x: Int, y: Int, board: inout [[Cell]]) -> Bool {
        switch board.get(x: x, y: y) {
        case .unknown(let number):
            if number == 0 {
                revealEmpty(x: x, y: y, board: &board)
            } else {
                board.set(x: x, y: y, newValue: .revealed(number))
            }
            first = false
            return true
        case .mine:
            // if it's the first move, move the mine to a random location
            if (first) {
                board.set(x: x, y: y, newValue: .unknown(0))
                //this is a bit inefficient, but it's not like it's going to be called often
                while (true) {
                    let x2 = Int.random(in: 0..<sizes.width)
                    let y2 = Int.random(in: 0..<sizes.height)

                    if case .unknown = board.get(x: x2, y: y2) {
                        board.set(x: x2, y: y2, newValue: .mine)
                        break
                    }
                }
                generateNumbers(&board)
                first = false
                return internalReveal(x: x, y: y, board: &board)
            } else {
                board.set(x: x, y: y, newValue: .exploded_mine)
                return false
            }
        default:
            return true
        }
    }

    /// reveals a cell on the board, similar to how a player would left click on an unknown cell
    /// - Parameters:
    ///   - x: the x coordinate
    ///   - y: the y coordinate
    /// - Returns: a modified GameState
    public func reveal(x: Int, y: Int) -> GameState {
        guard case .playing = gamestate.status else { return gamestate }
        guard x >= 0 && x < sizes.width && y >= 0 && y < sizes.height else { return gamestate.hideMines() }

        var board = gamestate.board

        let success = internalReveal(x: x, y: y, board: &board)

        gamestate.board = board

        guard (success) else {

            gamestate.status = .lost

            onLose()

            return gamestate
        }
        
        if gamestate.board.hasWon() {
            gamestate.status = .won

            onWin()

            return gamestate
        }



        return gamestate.hideMines()
    }

    public func clearAround(x: Int, y: Int) -> GameState {
        guard case .playing = gamestate.status else { return gamestate }
        guard x >= 0 && x < sizes.width && y >= 0 && y < sizes.height else { return gamestate.hideMines() }

        var board = gamestate.board

        guard case .revealed(let number) = board.get(x: x, y: y) else { return gamestate.hideMines() }

        var marked_mines = 0

        for y2 in max(0, y - 1)...min(board.endIndex - 1, y + 1) {
            for x2 in max(0, x - 1)...min(board[y2].endIndex - 1, x + 1) {
                if case .marked_mine = board.get(x: x2, y: y2) {
                    marked_mines += 1
                }
                if case .false_mine = board.get(x: x2, y: y2) {
                    marked_mines += 1
                }
            }
        }
        
        var success = true

        if marked_mines == number {
            for y2 in max(0, y - 1)...min(board.endIndex - 1, y + 1) {
                for x2 in max(0, x - 1)...min(board[y2].endIndex - 1, x + 1) {
                    success = internalReveal(x: x2, y: y2, board: &board) && success
                }
            }
        }

        gamestate.board = board

        guard (success) else {

            gamestate.status = .lost

            onLose()

            return gamestate
        }

        if gamestate.board.hasWon() {
            gamestate.status = .won

            onWin()

            return gamestate
        }


        return gamestate.hideMines()
    }

    public func toggleFlag(x: Int, y: Int) -> GameState {
        guard case .playing = gamestate.status else { return gamestate }
        guard x >= 0 && x < sizes.width && y >= 0 && y < sizes.height else { return gamestate.hideMines() }
        
        var board = gamestate.board

        let new_value: Cell = switch (board.get(x: x, y: y)) {
            case .mine:
                .marked_mine
            case .false_mine(let i):
                .unknown(i)
            case .marked_mine:
                .mine
            case .unknown(let i):
                .false_mine(i)
            default:
                board.get(x: x, y: y)
        }

        board.set(x: x, y: y, newValue: new_value)

        gamestate.board = board

        return gamestate.hideMines()
    }

    public func leftClick(x: Int, y: Int) -> GameState {
        guard case .playing = gamestate.status else { return gamestate }
        guard x >= 0 && x < sizes.width && y >= 0 && y < sizes.height else { return gamestate.hideMines() }

        return switch (gamestate.board.get(x: x, y: y)) {
            case .revealed:
                clearAround(x: x, y: y)
            case .false_mine, .marked_mine:
                gamestate.hideMines()
            default:
                reveal(x: x, y: y)
        }
    }

    @inlinable public func rightClick(x: Int, y: Int) -> GameState {
        return toggleFlag(x: x, y: y)
    }
}

public enum InitializationError: Error, CustomStringConvertible {
    public var description: String {
        switch (self) {
        case .invalidSize:
            "The size of the board is invalid"
        case .tooManyMines:
            "There are too many mines for the size of the board"
        case .tooFewMines:
            "There must be at least 1 mine"
        }
    }

    case invalidSize, tooManyMines, tooFewMines
    
}

public struct GameState {
    public var status: GameStatus
    public var board: [[Cell]]
    public var remaining_mines: Int

    /// Convenience function to hide the mines of the underlying board
    /// - Returns: a modified GameState
    func hideMines() -> GameState {
        return GameState(status: status, board: board.hideMines(), remaining_mines: remaining_mines)
    }
}

public enum GameStatus {
    case playing, won, lost, never
}

public enum Cell: CustomStringConvertible {
    ///0 indicates empty
    case revealed(Int), unknown(Int)

    case marked_mine

    case mine

    case false_mine(Int), exploded_mine

    public var description: String {
        switch self {
        case .revealed(let number):
            number == 0 ? " " : number.description
        case .unknown(let number):
            number == 0 ? "O" : number.description
        case .marked_mine:
            "!"
        case .mine:
            "*"
        case .false_mine:
            "Ø"
        case .exploded_mine:
            "X"
        }
    }
}

public enum ConventionalSizes {
    case beginner, intermediate, expert
}

extension [[Cell]] {

    /// gets a cell from the board in a way that is easier to read
    /// - Parameters:
    ///   - x: the x coordinate
    ///   - y: the y coordinate
    /// - Returns: the cell at the given coordinates
    public func get(x: Int, y: Int) -> Cell {
        self[y][x]
    }

    /// sets a cell from the board in a way that is easier to read
    /// NOTE: a player has no use for this function
    /// - Parameters:
    /// - x: the x coordinate
    /// - y: the y coordinate
    /// - newValue: the new value of the cell
    mutating func set(x: Int, y: Int, newValue: Cell) {
        self[y][x] = newValue
    }

    /// hides mines and false mines to the player while the game is going on
    /// NOTE: a player has no use for this function
    /// does not modify the current board
    /// - Returns: a modified board
    func hideMines() -> [[Cell]] {

        self.map { row in
            row.map { cell in
                switch cell {
                case .mine, .unknown:
                    .unknown(0)
                case .false_mine:
                    .marked_mine
                default:
                    cell
                }
            }
        }
    }

    func hasWon() -> Bool {
        for row in self {
            for cell in row {
                switch cell {
                case .unknown, .false_mine:
                    return false
                default:
                    continue
                }
            }
        }
        return true
    }
}