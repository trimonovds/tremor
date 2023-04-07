import XCTest
@testable import TextEditor

final class TextEditorTests: XCTestCase {
    func testNormalModeInsertAfterCursorEmptyLine() {
        assertReduce(
            state: TextEditorState(area: EditorSize(w: 300, h: 300)),
            action: .normal(.insertAfterCursor),
            modification: { $0.mode = .insert }
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
