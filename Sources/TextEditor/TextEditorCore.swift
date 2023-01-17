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
    case up
    case down
    case left
    case right
    case quit
    case setMode(Mode)
    case insertAppend(char: Int32)
    case commandAppend(char: Int32)
    case commandExec
}

func reduceTextEditor(state: inout TextEditorState, action: TextEditorAction) {
    switch action {
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
    case let .insertAppend(key):
        assert(state.mode == .insert)
        state.text += "\(UnicodeScalar(UInt32(key))!)"
    case let .commandAppend(key):
        assert(state.mode == .command)
        state.commandText += "\(UnicodeScalar(UInt32(key))!)"
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
