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
            let action = TextEditorAction(key: input, mode: state.mode)
            if let action = action {
                reduceTextEditor(state: &state, action: action)
            }
            lastInput = input
        }
    }

    private static func render(state: TextEditorState, key: Int32) {
        renderStatusLine(state: state, key: key)
        renderCommandLine(state: state)
        renderCursor(pos: state.cursorPos)
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
        statusLine.append(" `q` to quit.")
        statusLine.append(state.text)
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

private extension TextEditorAction {
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
            default:
                self = .insertAppend(char: key)
            }
        case .command:
            switch key {
            case 27: // Esc
                self = .setMode(.normal)
            case 10: // CR
                self = .commandExec
            default:
                self = .commandAppend(char: key)
            }
        }
    }
}

private extension String {
    var unsafeASCII32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}
