import Darwin.ncurses
import Foundation

@main
public enum TextEditor {
    public static func main() {
        setlocale(LC_CTYPE, "en_US.UTF-8")
        initscr()
        noecho()
        curs_set(0)
        keypad(stdscr, true)
        use_default_colors()
        defer { endwin() }

        var state = TextEditorState(area: EditorSize(w: Int(COLS), h: Int(LINES)))
        var lastInput: Int32 = 0

        while !state.stopped {
            erase()
            defer { refresh() }

            render(state: state)

            // TODO: Take new size into account
            let w = COLS
            let h = LINES

            renderBottomBar(w: w, h: h, key: lastInput, state: state)

            let input = getch()
            let action = TextEditorAction(key: input)
            if let action = action {
                reduceTextEditor(state: &state, action: action)
            }
            lastInput = input
        }
    }

    private static func render(state: TextEditorState) {
        renderCursor(pos: state.cursorPos)
    }

    private static func renderCursor(pos: CursorPosition) {
        attron(NCURSES.ATTRMask.reversed)
        mvaddstr(Int32(pos.y), Int32(pos.x), " ")
        attroff(NCURSES.ATTRMask.reversed)
    }

    private static func renderBottomBar(w: Int32, h: Int32, key: Int32, state: TextEditorState) {
        let modeStr: String = {
            switch state.mode {
                case .normal: return "NOR"
                case .insert: return "INS"
            }
        }()
        var bottomBar = modeStr + " `q` to quit."
        bottomBar.append("\tw: \(w), h: \(h), key: \(key)")
        attron(NCURSES.ATTRMask.reversed)
        mvaddstr(h - 1, 0, String(repeating: " ", count: Int(w)))
        mvaddstr(h - 1, 0, bottomBar)
        attroff(NCURSES.ATTRMask.reversed)
    }
}

private extension TextEditorAction {
    init?(key: Int32) {
        switch key {
        case "q".unsafeASCII32:
            self = .quit
        case  "k".unsafeASCII32:
            self = .up
        case  "j".unsafeASCII32:
            self = .down
        case  "h".unsafeASCII32:
            self = .left
        case  "l".unsafeASCII32:
            self = .right
        // case "y".unsafeASCII32:
        //     self = .copy
        // case "p".unsafeASCII32:
        //     self = .paste
        default:
            return nil
        }
    }
}

private extension String {
    var unsafeASCII32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}
