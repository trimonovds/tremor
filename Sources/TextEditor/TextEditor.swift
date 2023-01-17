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

        var state = TextEditorState(area: EditorSize(w: COLS, h: LINES))
        var lastInput: Int32 = 0

        while !state.stopped {
            erase()
            defer { refresh() }

            render(state: state, key: lastInput)

            let input = getch()
            let action = TextEditorAction.keyPress(key: input)
            reduceTextEditor(state: &state, action: action)
            lastInput = input
        }
    }

    private static func render(state: TextEditorState, key: Int32) {
        renderBuffer(state.bufferLines)
        renderStatusLine(state: state, key: key)
        renderCommandLine(state: state)
        renderCursor(pos: state.cursorPos)
    }

    private static func renderBuffer(_ bufferLines: [String]) {
        for el in bufferLines.enumerated() {
            mvaddstr(Int32(el.offset), 0, el.element)
        }
    }

    private static func renderCursor(pos: CursorPosition) {
        attron(NCURSES.ATTRMask.reversed)
        mvaddstr(Int32(pos.y), Int32(pos.x), " ")
        attroff(NCURSES.ATTRMask.reversed)
    }

    private static func renderStatusLine(state: TextEditorState, key: Int32) {
        let (w, h) = (state.area.w, state.area.h)
        let modeStr: String = {
            switch state.mode {
            case .normal: return "NOR"
            case .insert: return "INS"
            case .command: return "CMD"
            }
        }()
        var statusLine = modeStr
        statusLine.append(" w: \(w), h: \(h), key: \(key)")
        attron(NCURSES.ATTRMask.reversed)
        mvaddstr(h - 2, 0, String(repeating: " ", count: Int(w)))
        mvaddstr(h - 2, 0, statusLine)
        attroff(NCURSES.ATTRMask.reversed)
    }

    private static func renderCommandLine(state: TextEditorState) {
        let (_, h) = (state.area.w, state.area.h)
        switch state.mode {
        case .command:
            var commandLine = ":"
            commandLine.append("\(state.commandText)")
            mvaddstr(h - 1, 0, commandLine)
        default:
            break
        }
    }
}
