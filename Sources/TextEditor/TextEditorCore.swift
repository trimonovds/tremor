struct CursorPosition: Equatable {
    var x: Int
    var y: Int
}

enum Mode {
    case normal
    case insert
    case command
}

struct EditorSize: Equatable {
    var w: Int32
    var h: Int32
}

struct TextEditorState: Equatable {
    var mode: Mode = .normal
    var area: EditorSize
    var bufferLines: [String] = [""]
    var cursorPos: CursorPosition = .init(x: 0, y: 0)
    var commandText: String = ""
    var stopped = false
}

enum TextEditorAction {
    case keyPress(key: Int32)
}

enum TextEditorCommand {
    case up
    case down
    case left
    case right
    case quit
    case norDelete
    case norNewLineBelow
    case norNewLineAbove
    case setMode(Mode)
    case insInsert(char: String)
    case insRemoveLast
    case insCR
    case cmdAppend(char: String)
    case cmdRemoveLast
    case cmdExec
}

func reduceTextEditor(state: inout TextEditorState, action: TextEditorAction) {
    guard case let .keyPress(key) = action else { return }
    guard let command = TextEditorCommand(key: key, mode: state.mode) else { return }
    switch command {
    case .up:
        let newY = clamp(state.cursorPos.y - 1, from: 0, to: state.bufferLines.count - 1)
        let newLine = state.bufferLines[newY]
        state.cursorPos = CursorPosition(x: min(newLine.count - 1, state.cursorPos.x), y: newY)
    case .down:
        let newY = clamp(state.cursorPos.y + 1, from: 0, to: state.bufferLines.count - 1)
        let newLine = state.bufferLines[newY]
        state.cursorPos = CursorPosition(x: min(newLine.count - 1, state.cursorPos.x), y: newY)
    case .left:
        let line = state.bufferLines[state.cursorPos.y]
        state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
    case .right:
        let line = state.bufferLines[state.cursorPos.y]
        state.cursorPos.x = clamp(state.cursorPos.x + 1, from: 0, to: line.count - 1)
    case .norDelete:
        assert(state.mode == .normal)
        guard !state.bufferLines[state.cursorPos.y].isEmpty else { break }
        let line = state.bufferLines[state.cursorPos.y]
        let index = line.index(line.startIndex, offsetBy: state.cursorPos.x)
        state.bufferLines[state.cursorPos.y].remove(at: index)

        let lineAfter = state.bufferLines[state.cursorPos.y]
        if lineAfter.index(line.startIndex, offsetBy: state.cursorPos.x) == lineAfter.endIndex {
            state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: lineAfter.count - 1)
        }
    case .norNewLineBelow:
        assert(state.mode == .normal)
        state.bufferLines.insert("", at: state.cursorPos.y + 1)
        state.cursorPos.y += 1
        state.cursorPos.x = 0
        state.mode = .insert
    case .norNewLineAbove:
        assert(state.mode == .normal)
        let newLineIndex = max(0, state.cursorPos.y)
        state.bufferLines.insert("", at: newLineIndex)
        state.cursorPos.y = newLineIndex
        state.cursorPos.x = 0
        state.mode = .insert
    case .quit:
        state.stopped = true
    case let .setMode(mode):
        state.mode = mode
        switch mode {
        case .normal:
            let line = state.bufferLines[state.cursorPos.y]
            if line.index(line.startIndex, offsetBy: state.cursorPos.x) == line.endIndex {
                state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
            }
        case .command, .insert: 
            break
        }
        state.commandText = ""
    case let .insInsert(text):
        assert(state.mode == .insert)
        let line = state.bufferLines[state.cursorPos.y]
        let index = line.index(line.startIndex, offsetBy: state.cursorPos.x)
        state.bufferLines[state.cursorPos.y].insert(contentsOf: text, at: index)
        state.cursorPos.x = state.cursorPos.x + 1
    case .insRemoveLast:
        assert(state.mode == .insert)
        let line = state.bufferLines[state.cursorPos.y]
        guard !line.isEmpty else { break }
        state.bufferLines[state.cursorPos.y].removeLast()
        state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
    case .insCR:
        state.bufferLines.append("")
        state.cursorPos = CursorPosition(x: 0, y: state.cursorPos.y + 1)
    case let .cmdAppend(text):
        assert(state.mode == .command)
        state.commandText += text
    case .cmdRemoveLast:
        assert(state.mode == .command)
        guard !state.commandText.isEmpty else { break }
        state.commandText.removeLast()
    case .cmdExec:
        assert(state.mode == .command)
        if state.commandText == "q" {
            state.stopped = true
        } else {
            state.mode = .normal // TODO: Cmd Error
        }
    }
}

private let bottomLinesHeight = 2 // statusLine + cmdLine

private extension TextEditorCommand {
    init?(key: Int32, mode: Mode) {
        switch mode {
        case .normal:
            switch key {
            case "q".unsafeASCII32:
                self = .quit
            case "k".unsafeASCII32:
                self = .up
            case "j".unsafeASCII32:
                self = .down
            case "h".unsafeASCII32:
                self = .left
            case "l".unsafeASCII32:
                self = .right
            case "x".unsafeASCII32:
                self = .norDelete
            case "o".unsafeASCII32:
                self = .norNewLineBelow
            case "O".unsafeASCII32:
                self = .norNewLineAbove
            case "i".unsafeASCII32:
                self = .setMode(.insert)
            case ":".unsafeASCII32:
                self = .setMode(.command)
            case 27: // Esc
                self = .setMode(.normal)
            default:
                return nil
            }
        case .insert:
            switch key {
            case 27: // Esc
                self = .setMode(.normal)
            case 263: // Backspace
                self = .insRemoveLast
            case 10: // CR
                self = .insCR
            default:
                self = .insInsert(char: "\(UnicodeScalar(UInt32(key))!)")
            }
        case .command:
            switch key {
            case 27: // Esc
                self = .setMode(.normal)
            case 263: // Backspace
                self = .cmdRemoveLast
            case 10: // CR
                self = .cmdExec
            default:
                self = .cmdAppend(char: "\(UnicodeScalar(UInt32(key))!)")
            }
        }
    }
}

private extension String {
    var unsafeASCII32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}
