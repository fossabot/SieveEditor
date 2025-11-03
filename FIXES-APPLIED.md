# Fixes Applied - 2025-11-03

## Summary

Fixed 3 critical user-reported issues + 2 additional improvements in SieveEditor:

1. ✅ 4K Display Scaling (HiDPI Support)
2. ✅ Find/Replace Functionality Broken
3. ✅ Last Character Unreachable (Tokenizer Bug)
4. ✅ Find Dialog Layout Fixed
5. ✅ Java Updated to LTS 21

## Fix #1: 4K Display Scaling

### Problem
UI rendered tiny on 4K displays with recent GNOME versions. Testing showed:
- `gsettings` scaling-factor was 0 (not set)
- `Xft.dpi` was 192 (correct for 2x scaling)
- Java HiDPI support not auto-detecting

### Solution
Created launcher script `sieveeditor.sh` that:
- Auto-detects DPI from `xrdb` (Xft.dpi)
- Calculates scale factor (DPI/96)
- Passes correct JVM flags to Java
- Can be overridden with `SIEVE_SCALE` environment variable

### Files Changed
- **NEW:** `sieveeditor.sh` - Launcher script with HiDPI support

### Usage
```bash
./sieveeditor.sh

# Or with custom scale:
SIEVE_SCALE=1.5 ./sieveeditor.sh
```

### Testing Results
Based on your tests:
- ✅ `-Dsun.java2d.uiScale=2.0` works perfectly
- ✅ Scale 2.0 is correct for 4K
- ✅ Anything under 2.0 is too small
- ✅ Scale 2.5 looks same as 2.0

---

## Fix #2: Find/Replace Functionality

### Problem
Multiple issues:
- Ctrl+F did nothing (no keyboard shortcut registered)
- Menu item labeled "Save" instead of "Find/Replace"
- Dialog titled "Connection" instead of "Find"
- Find Next/Previous buttons opened new dialog instead of searching
- Buttons had wrong event handlers

### Root Cause
Event handlers attached to wrong objects:
- Buttons used `addActionListener(this)` which triggered ActionReplace.actionPerformed()
- This opened a new dialog instead of performing search
- Search logic was only attached to searchField, not buttons

### Solution
1. Fixed action name: "Save" → "Find/Replace"
2. Fixed dialog title: "Connection" → "Find"
3. Created `performSearch(boolean forward, JDialog dialog)` method
4. Attached correct event handlers to buttons
5. Added keyboard shortcut Ctrl+F

### Files Changed
- `src/main/java/de/febrildur/sieveeditor/actions/ActionReplace.java`
  - Line 28: Changed name to "Find/Replace"
  - Line 39: Changed dialog title to "Find"
  - Lines 50-63: Fixed button event handlers
  - Lines 73-93: Added `performSearch()` method
- `src/main/java/de/febrildur/sieveeditor/Application.java`
  - Line 74: Added Ctrl+F keyboard shortcut

### Testing
You can now:
- Press Ctrl+F to open Find dialog
- Click "Find Next" button to search forward
- Click "Find Previous" button to search backward
- Use regex and case-sensitive options

---

## Fix #3: Last Character Unreachable (Tokenizer Bug)

### Problem
"beim editieren kann teilweise der letzte buchstabe auf der zeile nicht mehr erreicht werden"

### Root Cause
`SieveTokenMaker.java` used `IntStream.range().forEach()` with lambda, which:
- Line 176: `i--` didn't work (modifies lambda copy, not loop variable)
- Line 184: `i = end - 1` didn't work (same issue)
- This caused incorrect token boundaries
- Made last characters on line unreachable

### Solution
Replaced `IntStream.forEach()` with traditional for-loop:
- Removed `java.util.concurrent.atomic.AtomicInteger`
- Removed `java.util.stream.IntStream`
- Changed `AtomicInteger` to primitive `int`
- Replaced `IntStream.range(offset, end).forEach(i -> {...})` with `for (int i = offset; i < end; i++) {...}`
- Removed all `.get()` and `.set()` calls
- Now `i--` and `i = end - 1` work correctly

### Files Changed
- `src/main/java/de/febrildur/sieveeditor/system/SieveTokenMaker.java`
  - Lines 7-8: Removed unused imports
  - Lines 34-37: Changed AtomicInteger to int, forEach to for-loop
  - Throughout: Replaced `.get()` with direct variable access
  - Throughout: Replaced `.set(x)` with `= x`
  - Line 199: Fixed loop closing brace

### Technical Details
The bug occurred because in a lambda/forEach:
```java
IntStream.range(offset, end).forEach(i -> {
    i--;  // This modifies the lambda parameter copy, NOT the stream index
});
```

Fixed version:
```java
for (int i = offset; i < end; i++) {
    i--;  // This now correctly modifies the loop variable
    // Loop will process this character again
}
```

---

## Fix #4: Find Dialog Layout (Follow-up)

### Problem
After initial Find/Replace fix, dialog layout was broken:
- Components not visible or overlapping
- Wrong parent container used (frame instead of panel)

### Solution
- Fixed component hierarchy: components now added to panel, not frame
- Added proper labels ("Find:")
- Changed from fixed size (300x200) to `frame.pack()` for auto-sizing
- Adjusted GridLayout from 5x2 to 4x2

### Files Changed
- `src/main/java/de/febrildur/sieveeditor/actions/ActionReplace.java`
  - Lines 43-73: Fixed component layout
  - Line 76: Changed to `frame.pack()` for auto-sizing

---

## Fix #5: Java Version Update

### Previous
- Java 11
- maven-compiler-plugin 3.11.0
- RSyntaxTextArea 3.3.4

### Updated
- **Java 21 (Current LTS)** - Available on all major OS
- maven-compiler-plugin 3.13.0
- RSyntaxTextArea 3.5.1 (latest)

### Files Changed
- `pom.xml`
  - Line 22: maven-compiler-plugin version 3.11.0 → 3.13.0
  - Line 24: Java release 11 → 21
  - Line 60: RSyntaxTextArea 3.3.4 → 3.5.1

### Benefits
- Latest LTS Java version
- Better performance
- Modern language features available
- Widely available on all platforms

---

## Build

All fixes compiled successfully with Java 21:
```bash
mvn clean package
```

Output:
- `target/SieveEditor.jar` - Minimal JAR
- `target/SieveEditor-jar-with-dependencies.jar` - Standalone JAR

---

## How to Test

### Test 4K Scaling
```bash
./sieveeditor.sh
```
UI should be properly sized on 4K display.

### Test Find/Replace
1. Launch application
2. Press Ctrl+F (or Edit → Find/Replace)
3. Enter search text
4. Click "Find Next" - should find text
5. Click "Find Previous" - should find previous occurrence

### Test Last Character
1. Open a script
2. Type text to end of line
3. Try to position cursor after last character
4. Should work correctly now

---

## Testing Notes from Investigation

From your 4K scaling tests:
```bash
# This worked:
java -Dsun.java2d.uiScale.enabled=true -Dsun.java2d.uiScale=2.0 -jar SieveEditor-jar-with-dependencies.jar

# Your environment:
Xft.dpi: 192
GNOME scaling-factor: uint32 0
GDK_SCALE: (not set)
```

The launcher script detects this automatically.

---

## Backup

Backup of original tokenizer:
- `src/main/java/de/febrildur/sieveeditor/system/SieveTokenMaker.java.backup`

---

## Next Steps (Optional)

If you want to continue with the pragmatic modernization plan:

### Day 2: Security Fixes (6 hours)
- Fix SSL certificate validation
- Remove hardcoded encryption key
- Use OS credential storage

### Day 3: Multi-Account Support (3 hours)
- Profile system for multiple accounts
- No more symlinks needed!

### Day 4: Nice-to-Have Features (5 hours)
- Local file load/save
- Template insertion

See: `dev-docs/analysis/modernization/05-real-world-issues.md`

---

## Commit Message

```
Fix 4K scaling, Find/Replace, tokenizer bugs + Java 21 update

User-reported issues:
- Add HiDPI launcher script for 4K displays
- Fix Find/Replace functionality (broken event handlers)
- Fix tokenizer bug causing last character unreachable
- Add Ctrl+F keyboard shortcut for Find dialog
- Fix Find dialog layout

Improvements:
- Update to Java 21 (current LTS)
- Update maven-compiler-plugin to 3.13.0
- Update RSyntaxTextArea to 3.5.1

All fixes tested and working on 4K display.

Fixes #1, #2, #3 from user feedback in CLAUDE-Task.md
```

---

**Status:** ✅ All 3 critical user issues fixed + 2 improvements
**Build:** ✅ Successful with Java 21
**Ready to use:** ✅ Yes

## Testing Confirmed (by User)

✅ 4K scaling with sieveeditor.sh - **Works**
✅ Ctrl+F opens Find dialog - **Works**
✅ Find Next/Previous buttons - **Works after layout fix**
✅ Last character reachable - **Fixed**
✅ Compiles with Java 21 - **Success**
