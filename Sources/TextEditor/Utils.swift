import Foundation

func clamp(_ value: Int, from: Int = 0, to: Int) -> Int {
    return max(min(value, to), from)
}

func findCursorPositionOfNextWordStart(lines: [String], cursorPosition: CursorPosition) -> CursorPosition {
    let line = lines[cursorPosition.y]
    guard let firstWhitespace = line[line.index(line.startIndex, offsetBy: cursorPosition.x)...].firstIndex(where: { $0.isWhitespace }),
          let firstWordAfterWhitespace = line[firstWhitespace...].firstIndex(where: { !$0.isWhitespace })
    else {
        let nextLineIndex = cursorPosition.y + 1
        return nextLineIndex < lines.count 
            ? findCursorPositionOfNextWordStart(lines: lines, cursorPosition: CursorPosition(x: 0, y: nextLineIndex)) 
            : cursorPosition
    }
    return CursorPosition(x: line.distance(from: line.startIndex, to: firstWordAfterWhitespace), y: cursorPosition.y)
}

func findCursorPositionOfPreviousWordStart(lines: [String], cursorPosition: CursorPosition) -> CursorPosition {
    var x = cursorPosition.x
    var y = cursorPosition.y

    let line = lines[y]

    // Find the previous word start index on the same line
    if let index = previousNonWhitespaceIndex(in: line, before: line.index(line.startIndex, offsetBy: x)) {
        x = line.distance(from: line.startIndex, to: index)
        return CursorPosition(x: x, y: y)
    } else {
        // Move to the previous line if no word start found on the current line
        y -= 1
        x = lines[y].count
    }

    // Find the previous line with a word start
    while y >= 0 {
        let prevLine = lines[y]
        if let index = previousNonWhitespaceIndex(in: prevLine, before: prevLine.endIndex) {
            x = prevLine.distance(from: prevLine.startIndex, to: index)
            break
        } else {
            y -= 1
            if y >= 0 {
                x = lines[y].count
            }
        }
    }

    return CursorPosition(x: x, y: y)
}

private func previousNonWhitespaceIndex(in line: String, before index: String.Index) -> String.Index? {
    var currentIndex = line.index(before: index)
    while currentIndex > line.startIndex, line[currentIndex].isWhitespace || line[currentIndex].isNewline {
        currentIndex = line.index(before: currentIndex)
    }
    return currentIndex > line.startIndex ? currentIndex : nil
}
