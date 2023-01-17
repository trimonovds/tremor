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
    var cursorPos: CursorPosition = .init(x: 0, y: 0)
    var mode: Mode = .normal
    var area: EditorSize
    var text: String = ""
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
    case setMode(Mode)
    case insertAppend(char: String)
    case insertRemoveLast
    case commandAppend(char: String)
    case commandRemoveLast
    case commandExec
}

func reduceTextEditor(state: inout TextEditorState, action: TextEditorAction) {
    guard case .keyPress(let key) = action else { return }
    guard let command = TextEditorCommand(key: key, mode: state.mode) else { return }
    switch command {
    case .up:
        state.cursorPos.y -= 1
    case .down:
        state.cursorPos.y += 1
    case .left:
        state.cursorPos.x -= 1
    case .right:
        state.cursorPos.x += 1
    case .quit:
        state.stopped = true
    case let .setMode(mode):
        state.mode = mode
        state.commandText = ""
    case let .insertAppend(text):
        assert(state.mode == .insert)
        state.text += text
    case .insertRemoveLast:
        assert(state.mode == .insert)
        state.text.removeLast()
    case let .commandAppend(text):
        assert(state.mode == .command)
        state.commandText += text
    case .commandRemoveLast:
        assert(state.mode == .command)
        state.commandText.removeLast()
    case .commandExec:
        assert(state.mode == .command)
        if state.commandText == "q" {
            state.stopped = true
        } else {
            state.mode = .normal // TODO: Cmd Error
        }
    }
    state.cursorPos.x = clamp(state.cursorPos.x, from: 0, to: Int(state.area.w) - 1)
    state.cursorPos.y = clamp(state.cursorPos.y, from: 0, to: Int(state.area.h) - 1)
}

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
                self = .insertRemoveLast
            default:
                self = .insertAppend(char: "\(UnicodeScalar(UInt32(key))!)")
            }
        case .command:
            switch key {
            case 27: // Esc
                self = .setMode(.normal)
            case 263: // Backspace
                self = .commandRemoveLast
            case 10: // CR
                self = .commandExec
            default:
                self = .commandAppend(char: "\(UnicodeScalar(UInt32(key))!)")
            }
        }
    }
}

private extension String {
    var unsafeASCII32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}