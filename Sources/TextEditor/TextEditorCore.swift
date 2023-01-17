struct CursorPosition: Equatable {
    var x: Int
    var y: Int
}

enum Mode {
    case normal
    case insert
}

struct TextEditorState: Equatable {
    var cursorPos: CursorPosition = CursorPosition(x: 0, y: 0)
    var mode: Mode = .normal
    var stopped = false
}

enum TextEditorAction {
    case up
    case down
    case left
    case right
    case quit
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
    }
}
