@testable import TextEditor
import XCTest

final class TextEditorTests: XCTestCase {
    func testNormalModeInsertAtStart() {
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["   asdfaqwer"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.insertAtStart),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 3, y: 0)
            }
        )
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.insertAtStart),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 0, y: 0)
            }
        )
    }

    func testNormalModeInsertAtEnd() {
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer   "],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.insertAtEnd),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 12, y: 0)
            }
        )
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.insertAtEnd),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 9, y: 0)
            }
        )
    }

    func testNormalModeUp() {
        // move up from the end of the line to line longer than the current one
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndf"],
                cursorPos: CursorPosition(x: 5, y: 1)
            ),
            action: .normal(.up),
            modification: { $0.cursorPos = CursorPosition(x: 5, y: 0) }
        )

        // move up from the end of the line to line shorter than the current one
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asd", "mnsndf"],
                cursorPos: CursorPosition(x: 5, y: 1)
            ),
            action: .normal(.up),
            modification: { $0.cursorPos = CursorPosition(x: 2, y: 0) }
        )
    }

    func testNormalModeDown() {
        // move down from the end of the line to line longer than the current one
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["mnsndf", "asdfaqwer"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.down),
            modification: { $0.cursorPos = CursorPosition(x: 5, y: 1) }
        )

        // move down from the end of the line to line shorter than the current one
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["mnsndf", "asd"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.down),
            modification: { $0.cursorPos = CursorPosition(x: 2, y: 1) }
        )
    }

    func testNormalModeInsertAfterCursorEmptyLine() {
        assertReduce(
            state: TextEditorState(area: EditorSize(w: 300, h: 300)),
            action: .normal(.insertAfterCursor),
            modification: { $0.mode = .insert }
        )
    }

    func testNormalModeInsertAfterCursor() {
        // insert after cursor in the middle of the line
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 5, y: 0)
            ),
            action: .normal(.insertAfterCursor),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 6, y: 0)
            }
        )

        // insert after cursor at the beginning of the line
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 0, y: 0)
            ),
            action: .normal(.insertAfterCursor),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 1, y: 0)
            }
        )

        // insert after cursor at the end of the line
        assertReduce(
            state: TextEditorState(
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 9, y: 0)
            ),
            action: .normal(.insertAfterCursor),
            modification: {
                $0.mode = .insert
                $0.cursorPos = CursorPosition(x: 9, y: 0)
            }
        )
    }

    func testNormalModeJumpWordForward() {
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asd 234 fs "],
                cursorPos: CursorPosition(x: 0, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 4, y: 0)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asd 234 fs "],
                cursorPos: CursorPosition(x: 4, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 8, y: 0)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asd 234 fs "],
                cursorPos: CursorPosition(x: 8, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 8, y: 0)
            }
        )

        // jump to next line
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", "uio "],
                cursorPos: CursorPosition(x: 0, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", "uio"],
                cursorPos: CursorPosition(x: 1, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", "uio"],
                cursorPos: CursorPosition(x: 2, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )

        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", " uio"],
                cursorPos: CursorPosition(x: 0, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 1, y: 1)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", " uio"],
                cursorPos: CursorPosition(x: 1, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 1, y: 1)
            }
        )
        assertReduce(
            state: TextEditorState(
                mode: .normal,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["fs ", " uio"],
                cursorPos: CursorPosition(x: 2, y: 0)
            ),
            action: .normal(.jumpWordForward),
            modification: {
                $0.cursorPos = CursorPosition(x: 1, y: 1)
            }
        )
    }

    func testInsertModeInsert() {
        // inset in the middle of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 5, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.insert(char: "1")),
            modification: {
                $0.bufferLines = ["asdfa1qwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 6, y: 0)
            }
        )
        // insert at the beginning of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 0, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.insert(char: "1")),
            modification: {
                $0.bufferLines = ["1asdfaqwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 1, y: 0)
            }
        )
        // insert at the end of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 9, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.insert(char: "1")),
            modification: {
                $0.bufferLines = ["asdfaqwer1", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 10, y: 0)
            }
        )
    }

    func testInsertModeRemove() {
        // remove in the middle of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 5, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.remove),
            modification: {
                $0.bufferLines = ["asdfqwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 4, y: 0)
            }
        )
        // remove at the beginning of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 0, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.remove),
            modification: {
                $0.bufferLines = ["asdfaqwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 0, y: 0)
            }
        )
        // remove at the end of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 9, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.remove),
            modification: {
                $0.bufferLines = ["asdfaqwe", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 8, y: 0)
            }
        )
    }

    func testInsertModeCRAtTheBeginningOfTheLine() {
        // CR at the beginning of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 0, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.cr),
            modification: {
                $0.bufferLines = ["", "asdfaqwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )
    }

    func testInsertModeCRAtTheEndOfTheLine() {
        // CR at the end of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 9, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.cr),
            modification: {
                $0.bufferLines = ["asdfaqwer", "", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )
    }

    func testInsertModeCRInTheMiddleOfTheLine() {
        // CR in the middle of the line
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 5, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.cr),
            modification: {
                $0.bufferLines = ["asdfa", "qwer", "mnsndfbqwer"]
                $0.cursorPos = CursorPosition(x: 0, y: 1)
            }
        )
    }

    func testInsertModeSetNormalMode() {
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 5, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.setNormalMode),
            modification: {
                $0.mode = .normal
            }
        )
    }

    func testInsertModeSetNormalModeAtTheEndOfTheLine() {
        assertReduce(
            state: TextEditorState(
                mode: .insert,
                area: EditorSize(w: 300, h: 300),
                bufferLines: ["asdfaqwer", "mnsndfbqwer"],
                cursorPos: CursorPosition(x: 9, y: 0),
                commandText: "",
                stopped: false
            ),
            action: .insert(.setNormalMode),
            modification: {
                $0.mode = .normal
                $0.cursorPos = CursorPosition(x: 8, y: 0)
            }
        )
    }
}

func assertReduce(
    state: TextEditorState,
    action: TextEditorAction,
    modification: (inout TextEditorState) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var reducedState = state
    reduceTextEditor(state: &reducedState, action: action)
    var expectedState = state
    modification(&expectedState)
    XCTAssertEqual(reducedState, expectedState, file: file, line: line)
}
