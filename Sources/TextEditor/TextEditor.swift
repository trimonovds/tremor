import Darwin.ncurses
import Foundation

@main
public enum TextEditor {
    private static func readFile(_ url: URL) -> TextEditorState {
        let content = try! String(contentsOf: url)
        let lines = content.split(separator: "\n").map { String($0) }
        return TextEditorState(
            area: EditorSize(w: COLS, h: LINES),
            bufferLines: lines
        )
    }

    private static func parseCommandLine() -> TextEditorState {
        let args = CommandLine.arguments
        switch args.count {
        case 1:
            return TextEditorState(
                area: EditorSize(w: COLS, h: LINES),
                bufferLines: [""]
            )
        case 2:
            let path = args[1]
            return readFile(URL(fileURLWithPath: path))
        default:
            print("Usage: \(args[0]) <file>")
            exit(1)
        }
    }

    public static func main() {
        setlocale(LC_CTYPE, "en_US.UTF-8")
        initscr()
        noecho()
        curs_set(0)
        keypad(stdscr, true)
        use_default_colors()
        defer { endwin() }

        var state = parseCommandLine()
        var lastInput: Int32 = 0

        while !state.stopped {
            erase()
            defer { refresh() }

            render(state: state, key: lastInput)

            let input = getch()
            if let action = TextEditorAction(key: input, mode: state.mode, floatingPanel: state.floatingPanel) {
                reduceTextEditor(state: &state, action: action)
            }
            lastInput = input
        }
    }

    private static func render(state: TextEditorState, key: Int32) {
        renderBuffer(state.bufferLines)
        renderStatusLine(state: state, key: key)
        renderCommandLine(state: state)
        renderCursor(pos: state.cursorPos)
        renderFloatingPanel(state.floatingPanel)
    }

    private static func renderFloatingPanel(_ panel: FloatingPanel?) {
        guard let panel = panel else { return }
        switch panel {
        case let .filePicker(picker):
            renderPicker(picker)
        }
    }

    struct Coordinate {
        var x: Int32
        var y: Int32
    }

    private static func renderPicker(_ picker: Picker) {
        let paddingH: Int32 = 16
        let paddingV: Int32 = 4
        let w: Int32 = COLS - 2 * paddingH
        let h: Int32 = LINES - 2 * paddingV

        // Search bar
        let searchBarText = "> \(picker.text)"
        let searchBarOrigin = Coordinate(x: (COLS - w) / 2, y: (LINES - h) / 2 )
        attron(NCURSES.ATTRMask.reversed)
        mvaddstr(searchBarOrigin.y, searchBarOrigin.x, String(repeating: " ", count: Int(w)))
        mvaddstr(searchBarOrigin.y, searchBarOrigin.x, String(searchBarText.prefix(Int(w))))
        attroff(NCURSES.ATTRMask.reversed)

        // Items
        let origin = Coordinate(x: (COLS - w) / 2, y: (LINES - h) / 2 + 1)
        let itemsH = Int(h - 1)
        let renderedItems = picker.filteredItems.prefix(itemsH)
        for element in renderedItems.enumerated() {
            let item = element.element
            let itemY = origin.y + Int32(element.offset)
            attron(NCURSES.ATTRMask.reversed)
            mvaddstr(itemY, origin.x, String(repeating: " ", count: Int(w)))
            mvaddstr(itemY, origin.x, String(item.prefix(Int(w))))
            attroff(NCURSES.ATTRMask.reversed)
        }
        if renderedItems.count < itemsH {
            let emptyLines = itemsH - renderedItems.count
            for i in 0 ..< emptyLines {
                let itemY = origin.y + Int32(renderedItems.count + i)
                attron(NCURSES.ATTRMask.reversed)
                mvaddstr(itemY, origin.x, String(repeating: " ", count: Int(w)))
                attroff(NCURSES.ATTRMask.reversed)
            }
        }
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
