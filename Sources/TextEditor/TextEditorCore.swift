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
    enum Insert {
        case insert(char: String)
        case removeLast
        case cr
        case setNormalMode
    }

    enum Normal {
        case up
        case down
        case left
        case right
        case delete
        case newLineBelow
        case newLineAbove
        case insertAfterCursor
        case insertAtEnd
        case insertAtStart
        case setInsertMode
        case setCommandMode
        case quit
    }

    enum Command {
        case append(char: String)
        case removeLast
        case exec
        case setNormalMode
    }

    case insert(Insert)
    case normal(Normal)
    case command(Command)
}

func reduceInsertMode(state: inout TextEditorState, action: TextEditorAction.Insert) {
    switch action {
    case let .insert(char):
        let line = state.bufferLines[state.cursorPos.y]
        let index = line.index(line.startIndex, offsetBy: state.cursorPos.x)
        state.bufferLines[state.cursorPos.y].insert(contentsOf: char, at: index)
        state.cursorPos.x = state.cursorPos.x + 1
    case .removeLast:
        let line = state.bufferLines[state.cursorPos.y]
        guard !line.isEmpty else { break }
        state.bufferLines[state.cursorPos.y].removeLast()
        state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
    case .cr:
        state.bufferLines.append("")
        state.cursorPos = CursorPosition(x: 0, y: state.cursorPos.y + 1)
    case .setNormalMode:
        state.mode = .normal
        let line = state.bufferLines[state.cursorPos.y]
        if line.index(line.startIndex, offsetBy: state.cursorPos.x) == line.endIndex {
            state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
        }
    }
}

private func reduceNormalMode(state: inout TextEditorState, action: TextEditorAction.Normal) {
    switch action {
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
    case .delete:
        guard !state.bufferLines[state.cursorPos.y].isEmpty else { break }
        let line = state.bufferLines[state.cursorPos.y]
        let index = line.index(line.startIndex, offsetBy: state.cursorPos.x)
        state.bufferLines[state.cursorPos.y].remove(at: index)

        let lineAfter = state.bufferLines[state.cursorPos.y]
        if lineAfter.index(line.startIndex, offsetBy: state.cursorPos.x) == lineAfter.endIndex {
            state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: lineAfter.count - 1)
        }
    case .newLineBelow:
        state.bufferLines.insert("", at: state.cursorPos.y + 1)
        state.cursorPos.y += 1
        state.cursorPos.x = 0
        state.mode = .insert
    case .newLineAbove:
        let newLineIndex = max(0, state.cursorPos.y)
        state.bufferLines.insert("", at: newLineIndex)
        state.cursorPos.y = newLineIndex
        state.cursorPos.x = 0
        state.mode = .insert
    case .insertAfterCursor:
        state.cursorPos.x = state.cursorPos.x + 1
        state.mode = .insert
    case .insertAtEnd:
        let line = state.bufferLines[state.cursorPos.y]
        state.cursorPos.x = line.count
        state.mode = .insert
    case .insertAtStart:
        state.cursorPos.x = 0
        state.mode = .insert
    case .setInsertMode:
        state.mode = .insert
    case .setCommandMode:
        state.commandText = ""
        state.mode = .command
    case .quit:
        state.stopped = true
    }
}

private func reduceCommandMode(state: inout TextEditorState, action: TextEditorAction.Command) {
    switch action {
    case let .append(char):
        state.commandText += char
    case .removeLast:
        guard !state.commandText.isEmpty else { break }
        state.commandText.removeLast()
    case .exec:
        if state.commandText == "q" {
            state.stopped = true
        } else {
            state.mode = .normal // TODO: Cmd Error
        }
    case .setNormalMode:
        state.mode = .normal
        let line = state.bufferLines[state.cursorPos.y]
        if line.index(line.startIndex, offsetBy: state.cursorPos.x) == line.endIndex {
            state.cursorPos.x = clamp(state.cursorPos.x - 1, from: 0, to: line.count - 1)
        }
    }
}

func reduceTextEditor(state: inout TextEditorState, action: TextEditorAction) {
    switch action {
    case let .insert(insertAction):
        assert(state.mode == .insert)
        reduceInsertMode(state: &state, action: insertAction)
    case let .normal(normalAction):
        assert(state.mode == .normal)
        reduceNormalMode(state: &state, action: normalAction)
    case let .command(commandAction):
        assert(state.mode == .command)
        reduceCommandMode(state: &state, action: commandAction)
    }
}

private let bottomLinesHeight = 2 // statusLine + cmdLine

extension TextEditorAction {
    init?(key: Int32, mode: Mode) {
        switch mode {
        case .normal:
            switch key {
            case "q".unsafeASCII32:
                self = .normal(.quit)
            case "k".unsafeASCII32:
                self = .normal(.up)
            case "j".unsafeASCII32:
                self = .normal(.down)
            case "h".unsafeASCII32:
                self = .normal(.left)
            case "l".unsafeASCII32:
                self = .normal(.right)
            case "x".unsafeASCII32:
                self = .normal(.delete)
            case "o".unsafeASCII32:
                self = .normal(.newLineBelow)
            case "O".unsafeASCII32:
                self = .normal(.newLineAbove)
            case "a".unsafeASCII32:
                self = .normal(.insertAfterCursor)
            case "A".unsafeASCII32:
                self = .normal(.insertAtEnd)
            case "I".unsafeASCII32:
                self = .normal(.insertAtStart)
            case "i".unsafeASCII32:
                self = .normal(.setInsertMode)
            case ":".unsafeASCII32:
                self = .normal(.setCommandMode)
            default:
                return nil
            }
        case .insert:
            switch key {
            case 27: // Esc
                self = .insert(.setNormalMode)
            case 263: // Backspace
                self = .insert(.removeLast)
            case 10: // CR
                self = .insert(.cr)
            default:
                self = .insert(.insert(char: "\(UnicodeScalar(UInt32(key))!)"))
            }
        case .command:
            switch key {
            case 27: // Esc
                self = .command(.setNormalMode)
            case 263: // Backspace
                self = .command(.removeLast)
            case 10: // CR
                self = .command(.exec)
            default:
                self = .command(.append(char: "\(UnicodeScalar(UInt32(key))!)"))
            }
        }
    }
}

private extension String {
    var unsafeASCII32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}
