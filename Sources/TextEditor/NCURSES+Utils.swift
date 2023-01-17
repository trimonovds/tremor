import Darwin.ncurses

enum NCURSES {}

extension NCURSES {
    enum ATTRMask {
        static let reversed = NCURSES_BITS(1, 10)
    }
}

private func NCURSES_BITS(_ mask: UInt32, _ shift: UInt32) -> CInt {
    CInt(mask << (shift + UInt32(NCURSES_ATTR_SHIFT)))
}
