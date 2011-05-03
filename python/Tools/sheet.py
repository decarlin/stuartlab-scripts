#!/usr/bin/python


#  Old:  #!/projects/sysbio/apps/x86_64/bin/python
'''
Sheet.py

A python program for viewing tab-delimited files in spreadsheet-like format. Only a viewer--you cannot edit files with it!



Uses the "CURSES" terminal interaction library to talk to the terminal.

by Alex Williams, 2009

Use it like this:   sheet.py  yourFile.tab   or else:    cat someFile | sheet.py

Example usage: "sheet.py -i ~/T" (tab-delimted file)

Note the line at the top of this file (the one that looks like "#!/somewhere/python")! That points to the current Python installation. It must be a real python distribution in order for you to be able to run sheet.py! (Otherwise try typing "which python" or "python sheet.py")
'''

#http://www.amk.ca/python/howto/curses/curses.html
# Semi-decent docs on how to use curses: http://www.amk.ca/python/howto/curses/

import sys

import curses # <-- docs at: http://docs.python.org/library/curses.html
import curses.ascii   # <-- docs at http://docs.python.org/library/curses.ascii.html
import curses.textpad
import curses.wrapper


from numpy import * # The matrices use this

GLOB = 1

kWANT_TO_ADJUST_CURSOR        = 0
kWANT_TO_DIRECTLY_MOVE_CURSOR = 1
kWANT_TO_MOVE_TO_SEARCH_RESULT    = 2
kWANT_TO_CHANGE_FILE          = 3

ROW_HEADER_MAXIMUM_COLUMN_FRACTION_OF_SCREEN = 0.25 # The row header column (i.e., the leftmost column) cannot be any wider than this fraction of the total screen width. 1.0 means "do not change--it can be the entire screen," 0.25 means "one quarter of the screen is the max, etc. 0.5 was the default before.

# ===============
class SearchBoard:
    def __init__(self, nrow, ncol):
        self.hit   = empty( (nrow, ncol), dtype=bool)
        self.dirty =  ones( (nrow, ncol), dtype=bool)
        pass

    def clear(self):
        self.dirty = ones( (self.numRows(), self.numCols()), dtype=bool)
        pass

    def set(self, row, col, value):
        self.hit[row][col] = value
        self.cleanify(row, col) # This cell has been legitimately set...
        pass

    def matches(self, row, col):
        if (self.dirty[row][col]):
            raise # It's not a "clean" value yet
        else:
            return self.hit[row][col]
        pass

    def isDirty(self, row, col):
        return self.dirty[row][col]

    def dirtify(self, row, col):
        self.dirty[row][col] = True
        pass

    def cleanify(self, row, col):
        self.dirty[row][col] = False
        pass

    def numRows(self):
        return self.hit.shape[0]

    def numCols(self):
        return self.hit.shape[1]

    pass # End of SearchBoard class
# ===============

import textwrap
#import time # we just want "sleep"
import os.path
import getopt

import re      # Regexp: http://docs.python.org/library/re.html


kSTDIN_HYPHEN = '-'

KEY_MODE_NORMAL_INPUT = 0
KEY_MODE_SEARCH_INPUT = 1

HEADER_NUM_DELIMITER_STRING = ": " # the separator between "ROW_1" and "here is the header". Example: "ROW_982-->Genomes". In that case, the string would have been "-->"

KEYS_TOGGLE_HIGHLIGHT_NUMBERS_MODE = (ord('!'),)

SHIFT_UP_KEY_ID    = 65 # ASCII id for "Shift key + arrow key"
SHIFT_DOWN_KEY_ID  = 66
SHIFT_RIGHT_KEY_ID = 67
SHIFT_LEFT_KEY_ID  = 68

FAST_UP_KEY_IN_LESS   = ord('b')
FAST_DOWN_KEY_IN_LESS = curses.ascii.SP # space

KEYS_MOVE_TO_TOP_IN_LESS = ord('g')
KEYS_MOVE_TO_BOTTOM_IN_LESS = ord('G')

FAST_DOWN_KEY_IN_EMACS = curses.ascii.ctrl(ord('v'))
FAST_UP_KEY_IN_EMACS   = curses.ascii.alt(ord('v'))

GOTO_LINE_START_KEY_IN_EMACS = curses.ascii.ctrl(ord('a'))
GOTO_LINE_END_KEY_IN_EMACS   = curses.ascii.ctrl(ord('e'))

KEYS_MOVE_TO_TOP  = (curses.KEY_HOME, KEYS_MOVE_TO_TOP_IN_LESS)
KEYS_MOVE_TO_BOTTOM = (curses.KEY_END, KEYS_MOVE_TO_BOTTOM_IN_LESS)

KEYS_MOVE_LEFT = (curses.KEY_LEFT, ord('j'), curses.ascii.ctrl(ord('b')))
KEYS_MOVE_UP   = (curses.KEY_UP, ord('i'), curses.ascii.ctrl(ord('p')))

KEYS_MOVE_DOWN = (curses.KEY_DOWN, ord('k'), curses.ascii.ctrl(ord('n')))
KEYS_MOVE_RIGHT = (curses.KEY_RIGHT, ord('l'), curses.ascii.ctrl(ord('f')))

KEYS_MOVE_RIGHT_FAST = (ord('L'), SHIFT_RIGHT_KEY_ID)
KEYS_MOVE_LEFT_FAST  = (ord('J'), SHIFT_LEFT_KEY_ID)
KEYS_MOVE_UP_FAST    = (ord('I'), ord('v'), SHIFT_UP_KEY_ID, curses.KEY_PPAGE, FAST_UP_KEY_IN_LESS, FAST_UP_KEY_IN_EMACS)
KEYS_MOVE_DOWN_FAST  = (ord('K'), SHIFT_DOWN_KEY_ID, curses.KEY_NPAGE, FAST_DOWN_KEY_IN_LESS, FAST_DOWN_KEY_IN_EMACS)

KEYS_GOTO_LINE_START = (ord('a'), GOTO_LINE_START_KEY_IN_EMACS)
KEYS_GOTO_LINE_END   = (ord('e'), GOTO_LINE_END_KEY_IN_EMACS)

KEYS_NEXT_FILE     = (ord('.'),ord('>'))
KEYS_PREVIOUS_FILE = (ord(','), ord('<'))
KEYS_TRANSPOSE     = (ord('t'),)

KEYS_QUIT = (ord('q'), ord('Q'), curses.ascii.ESC) #, curses.ascii.ctrl(ord('q')), curses.ascii.ctrl(ord('d')), curses.ascii.ctrl(ord('c')), curses.ascii.ESC)


KEYS_GOTO_NEXT_MATCH = (ord('n'),)
KEYS_GOTO_PREVIOUS_MATCH = (ord('N'),)


# ==== HERE ARE KEYS THAT ARE SPECIFIC TO SEARCH MODE ====
KEYS_SEARCH_MODE_FINISHED = (curses.KEY_ENTER, curses.ascii.LF, curses.ascii.CR )

KEYS_SEARCH_MODE_CANCEL = (curses.ascii.ESC, curses.ascii.ctrl(ord('g')), curses.KEY_CANCEL)

KEYS_SEARCH_MODE_BACKSPACE = (curses.KEY_BACKSPACE, curses.ascii.BS)
KEYS_SEARCH_MODE_DELETE_FORWARD = (curses.KEY_DC, curses.ascii.DEL)

# ==== END OF KEYS THAT ARE SPECIFIC TO SEARCH MODE ====


STANDARD_BG_COLOR = curses.COLOR_BLACK

# If a table ends with a "ragged end," and some rows aren't even the proper
# length, then the straggling cells get this color.
# You will see it a lot in ragged-end files, like list files.
RAGGED_END_ID = 1
RAGGED_END_TEXT_COLOR   = curses.COLOR_GREEN #BLUE #WHITE
RAGGED_END_BG_COLOR     = STANDARD_BG_COLOR #BLUE

SELECTED_CELL_ID = 2
SELECTED_CELL_TEXT_COLOR = curses.COLOR_CYAN
SELECTED_CELL_BG_COLOR = curses.COLOR_MAGENTA

COL_HEADER_ID = 3
COL_HEADER_TEXT_COLOR = curses.COLOR_YELLOW #BLACK
COL_HEADER_BG_COLOR = STANDARD_BG_COLOR #curses.COLOR_BLUE #BLACK #YELLOW

ROW_HEADER_ID = 4
ROW_HEADER_TEXT_COLOR = curses.COLOR_GREEN #BLACK
ROW_HEADER_BG_COLOR = STANDARD_BG_COLOR #curses.COLOR_BLUE #BLACK #GREEN

BOX_COLOR_ID = 5 # The borders of the cells
BOX_COLOR_TEXT_COLOR = curses.COLOR_YELLOW
BOX_COLOR_BG_COLOR = STANDARD_BG_COLOR

BLANK_COLOR_ID = 6
BLANK_COLOR_TEXT_COLOR = curses.COLOR_CYAN
BLANK_COLOR_BG_COLOR = STANDARD_BG_COLOR

SEARCH_MATCH_COLOR_ID = 7 # Highlighted search results
SEARCH_MATCH_COLOR_TEXT_COLOR = curses.COLOR_YELLOW
SEARCH_MATCH_COLOR_BG_COLOR = curses.COLOR_RED

WARNING_COLOR_ID = 8 # "Error message" color
WARNING_COLOR_TEXT_COLOR = curses.COLOR_YELLOW
WARNING_COLOR_BG_COLOR = curses.COLOR_RED

NUMERIC_NEGATIVE_COLOR_ID = 9 # Negative numbers are this style
NUMERIC_NEGATIVE_COLOR_TEXT_COLOR = curses.COLOR_RED
NUMERIC_NEGATIVE_COLOR_BG_COLOR = STANDARD_BG_COLOR

NUMERIC_POSITIVE_COLOR_ID = 10 # Positive numbers are this style
NUMERIC_POSITIVE_COLOR_TEXT_COLOR = curses.COLOR_CYAN
NUMERIC_POSITIVE_COLOR_BG_COLOR = STANDARD_BG_COLOR

ACTIVE_FILENAME_COLOR_ID = 11
ACTIVE_FILENAME_COLOR_TEXT_COLOR = curses.COLOR_YELLOW
ACTIVE_FILENAME_COLOR_BG_COLOR = STANDARD_BG_COLOR

# RAGGED_END_ID = 1
# RAGGED_END_TEXT_COLOR   = curses.COLOR_WHITE
# RAGGED_END_BG_COLOR     = curses.COLOR_BLUE

# SELECTED_CELL_ID = 2
# SELECTED_CELL_TEXT_COLOR = curses.COLOR_BLACK
# SELECTED_CELL_BG_COLOR = curses.COLOR_MAGENTA

# COL_HEADER_ID = 3
# COL_HEADER_TEXT_COLOR = curses.COLOR_BLACK
# COL_HEADER_BG_COLOR = curses.COLOR_YELLOW

# ROW_HEADER_ID = 4
# ROW_HEADER_TEXT_COLOR = curses.COLOR_BLACK
# ROW_HEADER_BG_COLOR = curses.COLOR_GREEN

DEFAULT_HIGHLIGHT_NUMBERS_SETTING = True   # By default, color numbers + as green and - as red. (Based on the settings in NUMERIC_POSITIVE_COLOR_ID and NUMERIC_NEGATIVE_COLOR_ID.)

_DEBUG = False # Run the program with "-w" for debugging to be enabled

_debugFilename = "DEBUG.sheet.py.out.tmp"
def DebugPrint(argStr="", nl="\n"):
    f = open(_debugFilename, 'a')
    f.write(str(argStr) + nl)
    f.close()
    print(str(argStr) + nl)
    return

def DebugPrintTable(table):
    for entireRow in (table):
        for cell in (entireRow):
            DebugPrint(stringFromAny(cell) + ", ", nl="")
            pass
        DebugPrint()
        pass
    return

class Point:
    def __init__(self, argX, argY):
        self.x = argX
        self.y = argY

class RowCol: # Like a Point, but ROW (Y) comes first, then COL (X)
    def __init__(self, argRow, argCol):
        self.row = argRow
        self.col = argCol

    def __init__(self, rowColList): # Used to init size from "getmaxyx()"
        (self.row, self.col) = rowColList

class Size:
    def __init__(self, argWidth, argHeight):
        self.width  = argWidth
        self.height = argHeight

    def resizeYX(self, rowColList):
        (self.height, self.width) = rowColList



class AGW_File_Data_Collection:
    '''
    This object stores all the state about a file. It's a lot like a "window" on a normal GUI. Confusingly, it is NOT the same as an AGW_Win, which is a "CURSES" terminal sub-window. Sorry for the confusion.
    '''
    def __init__(self):
        self.collection = [] # <-- contants: a bunch of AGW_File_Data objects
        self.currentFileIdx = None # which one are we currently looking at? probably should be not part of the object, come to think of it.
        pass

    def size(self):
        '''Basically, how many files did we load.'''
        return len(self.collection)

    def getCurrent(self): # AGW_File_Data_Collection
        '''Get the current data object that backs the spreadsheet we are looking at right this second.'''
        return self.getInfoAtIndex(self.currentFileIdx)

    def getInfoAtIndex(self, i):
        return self.collection[i]

    def addFileInfo(self, fileInfoObj):
        if (not isinstance(fileInfoObj, AGW_File_Data)):
            cleanup()
            print "Uh oh, someone tried to add some random object into the file info collection."
            raise
        else:
            self.collection.append(fileInfoObj)
            pass

class AGW_File_Data:
    def __init__(self, argFilename):
        self.filename = argFilename
        self.table = AGW_Table()
        self.defaultCellProperty = curses.A_NORMAL #REVERSE
        self.hasColHeader = False
        self.hasRowHeader = False
        self.cursorPos = Point(0, 0) # what is the selected cell
        self.__regex = None
        self.__compiledRegex = None
        self.regexIsCaseSensitive = False
        self.boolHighlightNumbers = DEFAULT_HIGHLIGHT_NUMBERS_SETTING
        pass

    def getNumCols(self): return self.table.getNumCols()
    def getNumRows(self): return self.table.getNumRows()

    def getActiveCellX(self): return self.cursorPos.x
    def getActiveCellY(self): return self.cursorPos.y

    def toggleNumericHighlighting(self):
        self.boolHighlightNumbers = (not self.boolHighlightNumbers)
        setCommandStr("Toggled highlighting of numeric values.")
        return

    def getRegexString(self):
        return stringFromAny(self.__regex)

    def appendToCurrentSearchTerm(self, newThing):
        self.changeCurrentSearchTerm(stringFromAny(self.__regex) + stringFromAny(newThing))
        return

    # In class AGW_File_Data
    def changeCurrentSearchTerm(self, argSearchString, argIsCaseSens=None):
        self.__regex = argSearchString
        #setWarning("just set regex to: " + str(self.__regex))

        if (argIsCaseSens is not None):
            self.regexIsCaseSensitive = argIsCaseSens
            pass

        if (lenFromAny(self.__regex) <= 0):
            self.__regex         = None
            self.__compiledRegex = None
            pass
        else:
            if (self.regexIsCaseSensitive):
                self.__compiledRegex = re.compile(self.__regex)
                pass
            else:
                self.__compiledRegex = re.compile(self.__regex, re.IGNORECASE)
                pass
            pass
        return

    def clearCurrentSearchTerm(self):
        self.changeCurrentSearchTerm(None, None)
        pass

    def trimRegex(self, numChars=1):
        '''Remove the last <numChars> characters from the end of the search term (i.e., it is like pressing backspace). Clears the search term (which sets it to None) if it is going to be zero-length.'''
        currentRegexLength = lenFromAny(self.__regex)
        if (currentRegexLength <= 1): self.clearCurrentSearchTerm()
        else: self.changeCurrentSearchTerm(self.__regex[:(currentRegexLength-1)])
        return

    def regexIsActive(self):
        '''Tells us whether we should be highlighting the search terms or not'''
        return (self.__regex is not None)

    # In class AGW_File_Data
    def stringDoesMatchRegex(self, stringToCheck):
        if (self.__regex is None or stringToCheck is None):
            return False

        if (self.__compiledRegex.search(stringToCheck)): # Note the difference between *search* and *match*(match does not do partial results)
            #DebugPrint("Got a match with: " + stringToCheck + " from the compiled regex: " + self.__regex)
            return True
        else:
            #DebugPrint("NO match for: " + stringToCheck + " from the compiled regex: " + self.__regex)
            return False


# =======================================
# End of class AGW_File_Data
# =======================================

# =======================================
# Start of class AGW_Win
# =======================================
class AGW_Win:
    def __init__(self):
        self.win = None
        self.pos  = Point(0,0) # where is the top-left of this window?
        self.windowWidth = 0
        self.windowHeight = 0
        pass

    def initWindow(self, argHeight, argWidth, atY, atX):
        self.pos  = Point(atX, atY)
        self.windowWidth  = argWidth
        self.windowHeight = argHeight
        try:
            self.win = curses.newwin(argHeight, argWidth, atY, atX)
            pass
        except:
            raise "Cannot allocate a curses window with height " + str(argHeight) + " and width " + str(argWidth) + " at Y=" + str(atY) + " and X=" + str(atX) # + ". Error was: " + err.message
        pass

    # safeAddCh: Safely adds a single character to an AGW_Win object
    # It is "safe" because it does not throw an error if it overruns
    # the pad (instead, it just doesn't draw anything at all)
    def safeAddCh(self, y, x, argChar, attr=0):
        if (y >= self.windowHeight or x >= self.windowWidth-1): # out of bounds!
            return

        try:
            self.win.addch(y, x, argChar, attr)
            pass
        except curses.error, err:
            cleanup() #1, "safeAddCh is messed up: " + err.message)
            print "ERROR: Unable to print a character at", y, x, "with window dimensions (in chars): ", self.windowHeight, self.windowWidth
            raise
        except:
            raise

    # safeAddStr: Safely adds a string to a CURSES "win" object.
    # It is "safe" because it does not throw an error if it overruns
    # Additionally, it does NOT WRAP TEXT. This is different from default addstr.
    def safeAddStr(self, y, x, string, attr=0):
        try:
            if (string is None): return
            if (x < 0 or y < 0): return

            if (y >= self.windowHeight): return # off screen!

            if (x+len(string) >= self.windowWidth): # Runs off to the right.
                newLength = max(0, (self.windowWidth - x - 1))
                string = string[:newLength]
                pass

            if (len(string) > 0):
                self.win.addstr(y, x, string, attr)

        except curses.error, err:
            #cleanup()
            print "safeAddStr is messed up!", err.message
            raise
        except:
            raise


class AGW_DataWin(AGW_Win):
    def __init__(self):
        AGW_Win.__init__(self) # parent constructor
        self.info  = None
        self.defaultCellProperty = curses.A_NORMAL #REVERSE
        pass

    def getTable(self):
        return self.info.table

    def setInfo(self, whichInfo):
        if (not isinstance(whichInfo, AGW_File_Data)):
            cleanup()
            print "### Someone passed in a not-an-AGW_File_Data object to AGW_DataWin--->setInfo()\n"
            raise

        self.info = whichInfo
        return

    def getInfo(self):
        return self.info

    def drawTable(self, whichInfo, topCell, leftCell, nRowsToDraw=None, nColsToDraw=None, boolPrependRowCoordinate=False, boolPrependColCoordinate=False):
        self.win.erase() # or clear()

        theTable = self.getTable()

        if (nColsToDraw is not None): numToDrawX = nColsToDraw
        else: numToDrawX = theTable.getNumCols()

        if (nRowsToDraw is not None): numToDrawY = nRowsToDraw
        else: numToDrawY = theTable.getNumRows()

        start = Point(leftCell, topCell) # "which cells to draw"
        end   = Point(min(leftCell+numToDrawX, theTable.getNumCols()),
                      min(topCell+numToDrawY , theTable.getNumRows()))

        cellTextPos = Point(None, None)
        for r in range(start.y, end.y):

            cellTextPos.y = gCellBorders.height + (gCellBorders.height+cellHeight)*(r - start.y) # <-- all cells are the same HEIGHT, so this can be computed in one equation

            if (cellTextPos.y >= self.windowHeight): break

            cellTextPos.x = gCellBorders.width # initialization! (update is way down below)

            for c in range(start.x, end.x):
                if (cellTextPos.x >= self.windowWidth): break

                cell = theTable.cellValue(r, c)

                if (boolPrependColCoordinate):
                    cell = str(c+1) + HEADER_NUM_DELIMITER_STRING + stringFromAny(cell)
                    pass

                if (boolPrependRowCoordinate):
                    cell = str(r+1) + HEADER_NUM_DELIMITER_STRING + stringFromAny(cell)
                    pass

                maxLenForThisCell = theTable.getColWidth(c)

                activeCellPt = whichInfo.cursorPos

                cellIsSelected = (c == activeCellPt.x and r == activeCellPt.y)
                shouldHighlightCell = cellIsSelected #or (self.highlightEntireCol and c == activeCellPt.x) or (self.highlightEntireRow and r == activeCellPt.y)

                cellAttr = self.defaultCellProperty

                if (whichInfo.boolHighlightNumbers):
                    cellAttr = attributeForNumeric(cell, self.defaultCellProperty)

                drawCheckerboard = False

                if (cell is None):
                    cellAttr = curses.color_pair(RAGGED_END_ID)       # (indicate that there isn't a cell here at all
                    cell = padStrToLength("", maxLenForThisCell, '~') #  distinct from an *empty* cell)
                    pass

                if (r == 0 and c == 0 and (self.info.hasRowHeader and self.info.hasColHeader)):
                    cellAttr = curses.A_NORMAL # there is an "odd man out" in the top left, for files
                    drawCheckerboard = True     # with both a column AND a row header
                    pass
                elif (r == 0 and self.info.hasColHeader):
                    cellAttr = curses.color_pair(COL_HEADER_ID)
                    drawCheckerboard = True
                    pass
                elif (c == 0 and self.info.hasRowHeader):
                    cellAttr = curses.color_pair(ROW_HEADER_ID)
                    drawCheckerboard = True
                    pass

                if (shouldHighlightCell):
                    cellAttr = curses.color_pair(SELECTED_CELL_ID) + curses.A_NORMAL
                    pass

                #setWarning(str(self.getColWidth(c)) + " is the length for col " + str(c))

                # cell = truncateLongCell(cell, maxLenForThisCell, truncationSuffix)

                if drawCheckerboard:
                    bgAttr = cellAttr
                    self.win.attron(bgAttr) #curses.color_pair(BOX_COLOR_ID))
                    hLineLength = max(0, min(self.windowWidth-cellTextPos.x, maxLenForThisCell))
                    self.win.hline(cellTextPos.y, cellTextPos.x, ' ', hLineLength) # checkerboard character
                    self.win.attroff(bgAttr) #curses.color_pair(BOX_COLOR_ID))
                    pass
                # curses.ACS_HLINE
                # curses.ACS_DIAMOND
                # curses.ACS_CKBOARD # checkerboard

                #whichInfo.changeCurrentSearchTerm("F")

                if (whichInfo.regexIsActive() and self is sheetWin): # <<<<<<< HORRIBLE HACK!!!! FIX LATER!!! should work on all windows!! not just the main one
                    # "self is sheetWin" is a horrible hack! Fix it eventually
                    theTable.initRegexTable()
                    if (theTable.regTab.isDirty(r, c)):
                        # calcluate the regex...
                        #DebugPrint("calc: " + str(r) + ", " + str(c))
                        boolRegexMatched = whichInfo.stringDoesMatchRegex(cell)
                        #DebugPrint("  match status is: " + str(boolRegexMatched))
                        theTable.regTab.set(row=r, col=c, value=boolRegexMatched)
                        pass

                    if (theTable.regTab.matches(row=r, col=c)):
                       #DebugPrint("This was the result at " + str(r) + ", " + str(c) + ": " + whichInfo.regex + " <-- " + cell)
                        cellAttr = curses.color_pair(SEARCH_MATCH_COLOR_ID) #+ curses.A_REVERSE #curses.A_BLINK
                        pass

                    pass

                self.safeAddStr(cellTextPos.y, cellTextPos.x, cell, cellAttr) # Draw text
                self.win.attron(curses.color_pair(BOX_COLOR_ID))

                if (gCellBorders.height > 0): # horizontal lines
                    hLineLength = max(0, min(self.windowWidth - cellTextPos.x - 1, maxLenForThisCell))

                    try:
                        self.win.hline(cellTextPos.y-1, cellTextPos.x, curses.ACS_HLINE, hLineLength)
                        pass
                    except:
                        cleanup()
                        print "problem when cellTextPos is y=" + str(cellTextPos.y) + ", x=" + str(cellTextPos.x) + " and also the rows and cols are " + str(r) + " and " + str(c) + " and terminal width is " + str(gTermSize.width) + " and height is " + str(gTermSize.height)
                        raise

                    pass

                if (gCellBorders.width > 0): # vertical lines
                    vLineLength = max(0, min(self.windowHeight-cellTextPos.y, gCellBorders.width))
                    try:
                        self.win.vline(cellTextPos.y, cellTextPos.x-1, curses.ACS_VLINE, vLineLength)
                        pass
                    except:
                        cleanup()
                        print "problem when cellTextPos is y=" + str(cellTextPos.y) + ", x=" + str(cellTextPos.x) + " and also the rows and cols are " + str(r) + " and " + str(c) + " and terminal width is " + str(gTermSize.width) + " and height is " + str(gTermSize.height)
                        raise
                    pass

                if (gCellBorders.width > 0 and gCellBorders.height > 0):
                    ch = calculateBorderChar(r=r, c=c, topRow=0, leftCol=0, bottomRow=theTable.getNumRows(), rightCol=theTable.getNumCols())
                    self.safeAddCh(cellTextPos.y-1, cellTextPos.x-1, ch)
                    pass

                self.win.attroff(curses.color_pair(BOX_COLOR_ID))

                cellTextPos.x += (gCellBorders.width+maxLenForThisCell)
                pass
            pass


        self.win.refresh()
        pass # end of "drawTable"
                #theWin.attroff(curses.A_REVERSE)
    #             Attributes: A_BLINK, A_BOLD, A_DIM, A_REVERSE, A_STANDOUT, A_UNDERLINEUnderlined



class AGW_Table:
    def __init__(self):
        self.clearTable()
        pass

    def clearTable(self):
        self.__nCells = Size(0,0) # size in cells
        self.__cells = []
        self.colWidth = [] # maximum char length in a col
        self.isRagged = False # Does the table have "ragged" ends? (differing col counts). Ragged means "some rows have more cols than others"
        self.regTab = None # this will be a table of "None" (not yet checked) "True" or "False", depending on whether the cell currently matches the regex!
        pass

    def getColWidth(self, colIdx):
        if (gTransposition):
            return 25 # This is a hack! Currently colwidth isn't properly computed for transposed matrices

        try: return self.colWidth[colIdx]
        except:
            cleanup()
            print "### Someone passed in an invalid column index, " + str(colIdx) + ". Max was " + str(self.getNumCols()) + ".\n"
            raise #return 0 #raise #return 0

    def getNumCols(self):
        if (gTransposition):
            return self.__nCells.height # <-- if displaying transposed!
        else:
            return self.__nCells.width  # table width in number of cells

    def getNumRows(self):
        if (gTransposition):
            return self.__nCells.width  # <-- if displaying transposed!
        else:
            return self.__nCells.height  # table height in number of cells

    def getHeaderCellForCol(self, colIdx): return self.cellValue(0, colIdx)
    def getHeaderCellForRow(self, rowIdx): return self.cellValue(rowIdx, 0)

    def cellValue(self, row, col):
        if (gTransposition):
            temp = row
            row = col
            col = temp
            pass

        try:    return self.__cells[row][col] # problem is with the number of rows...
        except IndexError, err:
            return None # <-- dubious... ? maybe we should actually just fail here
        except:
            raise
        return


    def initRegexTable(self):
        self.regTab = SearchBoard(nrow=self.getNumRows(), ncol=self.getNumCols())
        return

    def appendRowOfCellContents(self, contents):
        self.__cells.append(contents)

        if (self.__nCells.width > 0 and self.__nCells.width != len(contents)):
            self.isRagged = True # Ragged table! (not a "true" table)
            pass

        numItemsInThisNewRow = len(contents)
        self.__nCells.width = max(self.__nCells.width, numItemsInThisNewRow) # Set the table width to that of the MAXIMUM number of cols that a row has
        self.__nCells.height += 1 # Read another row...

        for c in range(0, self.__nCells.width):
            # Ok, find the longest item in each col.
            cellWidth = None
            if (c >= numItemsInThisNewRow or (contents[c] is None)): cellWidth = 0
            else:                                                    cellWidth = len(contents[c])

            numColsWithWidth = len(self.colWidth)
            if (c == 0 and c < numColsWithWidth): # and self.hasRowHeader):
                # It's the ROW header (the leftmost column)! Gotta account for the ": " in the row header
                cellWidth += len(str(self.getNumCols())) + len(HEADER_NUM_DELIMITER_STRING) #+ gCellBorders.width*2
                pass

            if (c >= numColsWithWidth):
                cellWidth += len(str(c+1)) + len(HEADER_NUM_DELIMITER_STRING)  # Accounting for the col header!
                self.colWidth.append(cellWidth)
                pass
            else:
                self.colWidth[c] = max(self.colWidth[c], cellWidth)
                pass
            pass
        pass

    def readFromFileInfo(self, singleFileInfo, maxLines):
        if (not isinstance(singleFileInfo, AGW_File_Data)):
            cleanup()
            print "### Someone passed in a not-an-AGW_File_Data object to readFromFileInfo\n"
            raise

        try:
            file = None
            self.clearTable()

            if (singleFileInfo.filename is kSTDIN_HYPHEN):
                file = sys.stdin
                pass
            else:
                file = open(singleFileInfo.filename, 'r')
                pass

            numLinesRead = 0
            while True:
                if (MAX_NUM_LINES_TO_READ is not None) and (numLinesRead >= MAX_NUM_LINES_TO_READ): break
                # ff = file.readlines()
                myLine = file.readline()
                if (not myLine): break # just read the last line

                myLine = myLine.rstrip("\n") # <-- like Perl's "chomp"--remove the trailing newlines
                self.appendRowOfCellContents( myLine.split(delimiter) )
                numLinesRead += 1
                #global GLOB
                #GLOB = str(GLOB) + " " + str(numLinesRead)
                pass
        except:
            cleanup()
            print "Cannot read from the file <" + singleFileInfo.filename + ">. Sorry!"
            raise
        finally:
            if (singleFileInfo.filename is kSTDIN_HYPHEN):
                os.close(0) # <-- closes stdin (required!)
                sys.stdin = open('/dev/tty', 'r')
                #raise "LEAVING!!! DBEUG!!!"
                pass
            else:
                if (file is not None): file.close()
                pass
            pass

        return # end of "readFromFileInfo"


def lenFromAny(argThing): # returns 0 for None's length
    if (argThing is None): return 0
    else: return len(argThing)

def stringFromAny(argString): # Returns a string, even if given None as an input
    if (argString is None): return ""
    else:                   return str(argString)


def cursesClearLine(window, lineYPos):
    window.move(lineYPos, 0);
    window.clrtoeol()
    pass


def agwEnglishPlural(string, numOf, suffix="s"):
    '''You pass in a string like "squid" and a number
    indicating how many squid there are. If the number
    is one, then "squid" is returned, otherwise "squids"
    is returned.'''
    if (1 == numOf):
        return string
    else:
        return string + suffix
    pass

def attributeForNumeric(theProspectiveNumber, defaultAttr):
    # Give it something that might be a number.
    # if it *is* a numnber, it returns the format for that type of
    # number. If it isn't, it returns "defaultAttr"
    try:
        if (float(theProspectiveNumber) < 0):
            return curses.color_pair(NUMERIC_NEGATIVE_COLOR_ID)
            pass
        elif (float(theProspectiveNumber) > 0):
            return curses.color_pair(NUMERIC_POSITIVE_COLOR_ID)
            pass
        else: # for zero, maybe NaN too
            return defaultAttr
        pass
    except (ValueError, TypeError):
        return defaultAttr # not a number
    pass


gTermSize = Size(None, None)

gStandardScreen = None  # The main screen

gTransposition = False # Whether to show the data "as-is" or transposed

mainInfo = AGW_File_Data_Collection() # An array of AGW_File_Datas

sheetWin = AGW_DataWin()
infoWin  = AGW_Win()

colHeaderWin = AGW_DataWin()
rowHeaderWin = AGW_DataWin()

MAX_NUM_LINES_TO_READ = None   # None means "no limit"--read all lines

cellHeight = 1

gCellBorders = Size(1, 0) #Size(1,1) # Width, Height

gCurrentMode = KEY_MODE_NORMAL_INPUT

gWantToQuit = False

windowPos = Point(0,0)

truncationSuffix = "..."

delimiter = "\t"

fastMoveSpeed = Point(10, 10)

#activeCellPos = Point(0,0)

gWarningMessage = None
gCommandStr = None

def setWarning(string):
    global gWarningMessage
    gWarningMessage = string
    return

def setCommandStr(string): global gCommandStr ; gCommandStr = string
def clearCommandStr():     global gCommandStr ; gCommandStr = None

def usageAndQuit(exitCode, message=None):
    cleanup()
    fillWidth = 80
    message = textwrap.fill(message, fillWidth)
    if (message is not None):
        print ""
        print "sheet.py: "
        print message
        print "sheet.py: Printing usage information below."
        print "*"*fillWidth ; print "*"*fillWidth ;
        pass
    print ALEX_PROGRAM_USAGE_TEXT # at the very bottom of this file
    if (message is not None):
        print "(End of usage information for sheet.py.)"
        print "*"*fillWidth ; print "*"*fillWidth ;
        print "sheet.py: "
        print message
        pass
    sys.exit(exitCode)
    return


def initializeWindowSettings(fileInfoToReadFrom):
    #if (fileInfoToReadFrom is None):
    #    usageAndQuit(1, "Missing a command-line argument: We did not have at least one file passed in as an argument on the command line! Pass in at least one valid file on the command line. Maybe you passed in a file that could not be read for some reason, or passed in a directory name.\n")
    #    raise

    if (not isinstance(fileInfoToReadFrom, AGW_File_Data)):
        cleanup()
        print "### Init window: Someone passed in a not-an-AGW_File_Data object to initializeWindowSettings\n"
        raise

    global sheetWin
    global infoWin
    global colHeaderWin
    global rowHeaderWin

    gTermSize.resizeYX(gStandardScreen.getmaxyx())

    INFO_PANEL_HEIGHT = 6

    COL_HEADER_HEIGHT = 2 # one line for the data, and one below for the horizontal line

    sheetWin.setInfo(fileInfoToReadFrom)
    fileInfoToReadFrom.table.readFromFileInfo(fileInfoToReadFrom, MAX_NUM_LINES_TO_READ)

    if (fileInfoToReadFrom.hasColHeader and fileInfoToReadFrom.getNumRows() >= 2):
        fileInfoToReadFrom.cursorPos.y = 1 # start off with the column to the RIGHT of the col header selected, instead of having the column header show up twice
        pass

    if (fileInfoToReadFrom.hasRowHeader and fileInfoToReadFrom.getNumCols() >= 2):
        fileInfoToReadFrom.cursorPos.x = 1 # start off with the first not-a-header row highlighted
        pass

    rowHeaderMaxWidth = 0
    if (sheetWin.getTable().getNumCols() > 0):
        # If there is at least one column, then the row header is as wide as the first column
        # (but note that the maximum size is adjusted below)
        rowHeaderMaxWidth = sheetWin.getTable().getColWidth(0) + (gCellBorders.width*2)
        pass

    # However: the maximum allowed rowHeaderWidth is some fraction of the total screen width
    if (rowHeaderMaxWidth > (gTermSize.width*ROW_HEADER_MAXIMUM_COLUMN_FRACTION_OF_SCREEN)):
        rowHeaderMaxWidth = int(gTermSize.width*ROW_HEADER_MAXIMUM_COLUMN_FRACTION_OF_SCREEN)
        pass

    sheetWin.initWindow(gTermSize.height - INFO_PANEL_HEIGHT - COL_HEADER_HEIGHT,
                        gTermSize.width - rowHeaderMaxWidth,
                        INFO_PANEL_HEIGHT+COL_HEADER_HEIGHT,
                        rowHeaderMaxWidth)

    infoWin.initWindow(INFO_PANEL_HEIGHT,  # height
                       gTermSize.width,    # width
                       0,      # location--y
                       0)      # location--x

    # Goes along the left side!
    ROW_HEADER_HEIGHT = (gTermSize.height - INFO_PANEL_HEIGHT - COL_HEADER_HEIGHT)
    ROW_HEADER_LOC_X  = 0
    ROW_HEADER_LOC_Y  = INFO_PANEL_HEIGHT + COL_HEADER_HEIGHT
    rowHeaderWin.initWindow(ROW_HEADER_HEIGHT,
                            rowHeaderMaxWidth,
                            ROW_HEADER_LOC_Y,
                            ROW_HEADER_LOC_X)
    #rowHeaderWin.defaultCellProperty = curses.color_pair(ROW_HEADER_ID)


    # Goes along the TOP
    COL_HEADER_WIDTH = gTermSize.width-rowHeaderMaxWidth
    COL_HEADER_LOC_X = rowHeaderMaxWidth
    COL_HEADER_LOC_Y = INFO_PANEL_HEIGHT
    colHeaderWin.initWindow(COL_HEADER_HEIGHT,
                            COL_HEADER_WIDTH,
                            COL_HEADER_LOC_Y,
                            COL_HEADER_LOC_X)
    #colHeaderWin.defaultCellProperty = curses.color_pair(COL_HEADER_ID)

    colHeaderWin.setInfo(fileInfoToReadFrom)
    rowHeaderWin.setInfo(fileInfoToReadFrom)

    fastMoveSpeed.x = 5 #gTermSize.width // 2 # <-- measured in CELLS, not characters!
    fastMoveSpeed.y = sheetWin.windowHeight // 2 # measured in CELLS, not characters!

    pass



def main(argv):

    try:
        opts, args = getopt.gnu_getopt(argv, "hwi:d", ["help", "warn", "input="])
    # Docs for getopt: http://docs.python.org/library/getopt.html
    except getopt.GetoptError, err:
        usageAndQuit(1, "Encountered an unknown command line option!\n" + "sheet.py: Please remember that long names must have double-dashes!\n" + "sheet.py: (i.e. -warn generates an error, but --warn is correct)\n" + "sheet.py: The specific error was \"" + err.msg + "\"") # err.opt
        raise

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usageAndQuit(0, "Printed the HELP information, since the --help option was supplied.")
            pass
        elif opt in ("-w", "--warn"):
            global _DEBUG
            _DEBUG = True
            pass
        else:
            pass
    # End of function

    if (_DEBUG):
        print "Unprocessed arguments:" , args
        print "Unprocessed options:" , opts
        pass

    arrFilenamesToRead = []

    if (sys.stdin.isatty() is False):
        # If the user has piped in a file, add that to the "things to read"
        # Note that STDIN must be the VERY FIRST thing in the list of filenames
        # to read.
        if (len(arrFilenamesToRead) > 0):
            setWarning("Since input was piped in through STDIN, we ignored the files that were passed on the command line.")
            pass
        arrFilenamesToRead.extend(kSTDIN_HYPHEN) # Add to the list
        pass
    else:
        arrFilenamesToRead.extend(args) # Add the unread files... AFTER handling stdin.
        pass

    #print "Files to read = <" , arrFilenamesToRead , ">" ; sys.exit(1)

    if (0 == len(arrFilenamesToRead)):
        usageAndQuit(0, "ARGUMENT ERROR: You must specify at least one filename on the command line!")
        pass

    for filename in arrFilenamesToRead:
        if (filename is kSTDIN_HYPHEN or os.path.isfile(filename)):
            # It's a valid thing to read...
            singleFileInfo = AGW_File_Data(filename)
            singleFileInfo.hasColHeader = True
            singleFileInfo.hasRowHeader = True

            mainInfo.addFileInfo(singleFileInfo)
            pass
        else:
            print "Tried to read <" + filename + ">, which is not a file!"
            pass
        pass

    global gStandardScreen
    gStandardScreen = setUpCurses()

    mainInfo.currentFileIdx = 0

    if (mainInfo.size() == 0):
        usageAndQuit(0, "sheet.py: No files that were specified on the command line could be read. Maybe you specified a directory (instead of a list of files). If you want to list all the files in a directory, try:\tsheet.py your_directory/*\n")
        pass

    initializeWindowSettings(mainInfo.getCurrent()) # load the first file...

    #cleanup()
    #print str(len(mainInfo.getCurrent().table.colWidth))
    #print "is the thing."
    #global GLOB
    #print str(GLOB)
    #sys.exit(1)

    curses.wrapper(inputHandlingLoop) # Passes in the initialized screen as the first argument to inputHandlingLoop. Automatically restores normal terminal operation upon program termination.

    return


#
#
# File " " is 2 rows X 3 cols. (Ragged ends)
# File list:
# Row 1: <FDSFSDF>
# Col 8: <LKJOIJWE>
# Value: <Value>
# > Command
#
def drawInfoWin(theScreen, theInfo, inTab):
    '''inTab: the actual table of data that is going to be drawn'''

    activeCellPos = theInfo.cursorPos

    infoWin.win.erase()

    FILE_INFO_ROW = 0
    FILE_LIST_ROW = 1
    ROW_HEADER_ROW = 2
    COL_HEADER_ROW = 3
    VALUE_ROW = 4
    COMMAND_ROW = 5

    if (theInfo.filename is kSTDIN_HYPHEN): filename = "<STDIN>"
    else:                                   filename = '"' + theInfo.filename + '"'

    if (gTransposition): filename = "Transposed file " + filename
    else: filename = "File " + filename

    if (inTab.isRagged): raggedText = " The table is ragged--some rows have differing numbers of columns."
    else:                raggedText = ""

    if (mainInfo.size() >= 1): fileNumberStr = (" (#" + str(mainInfo.currentFileIdx+1) + " of " + str(mainInfo.size()) + ")" )
    else:                      fileNumberStr = ""

    fileStatusStr = filename + fileNumberStr + " has " + str(inTab.getNumRows()) + agwEnglishPlural(" row", inTab.getNumRows()) + " and " + str(inTab.getNumCols()) + agwEnglishPlural(" column", inTab.getNumCols()) + "." + raggedText

    infoWin.safeAddStr(FILE_INFO_ROW, 0, fileStatusStr)

    rowStr1 = "Row #" + str(activeCellPos.y+1) + ": " + stringFromAny(inTab.getHeaderCellForRow(activeCellPos.y))
    cursesClearLine(infoWin.win, ROW_HEADER_ROW)
    infoWin.safeAddStr(ROW_HEADER_ROW, 0, rowStr1, curses.color_pair(ROW_HEADER_ID))

    colStr1 = "Col #" + str(activeCellPos.x+1) + ": " + stringFromAny(inTab.getHeaderCellForCol(activeCellPos.x))
    cursesClearLine(infoWin.win, COL_HEADER_ROW)
    infoWin.safeAddStr(COL_HEADER_ROW, 0, colStr1, curses.color_pair(COL_HEADER_ID))

    cellText = stringFromAny(inTab.cellValue(activeCellPos.y, activeCellPos.x))
    valueStr1 = "(R_" + str(activeCellPos.y+1) + ", C_" + str(activeCellPos.x+1) + ") = " + cellText
    infoWin.safeAddStr(VALUE_ROW, 0, valueStr1)

    if (mainInfo.size() < 2):
        fileListStr1 = "" # only one file to read... no need for a list
        pass
    else:
        xOffset = 0
        fileListStr1 = "File List: "
        infoWin.safeAddStr(FILE_LIST_ROW, 0, fileListStr1)
        xOffset += len(fileListStr1)
        for i in range(0, mainInfo.size()):

            fileListStr1 = mainInfo.getInfoAtIndex(i).filename

            if (i == mainInfo.currentFileIdx):
                fileListAttr = curses.color_pair(ACTIVE_FILENAME_COLOR_ID)
                infoWin.safeAddStr(FILE_LIST_ROW, xOffset, fileListStr1, fileListAttr)
                xOffset += len(fileListStr1)
                fileListStr1 = ""
                pass

            fileListAttr = curses.A_NORMAL
            if (i < mainInfo.size()-1):
                fileListStr1 += ", "
                pass

            infoWin.safeAddStr(FILE_LIST_ROW, xOffset, fileListStr1, fileListAttr)
            xOffset += len(fileListStr1)
            pass

        pass

    commandStr1 = "" + stringFromAny(gCommandStr)
    infoWin.safeAddStr(COMMAND_ROW, 0, commandStr1, curses.A_NORMAL)

#     #setWarning(str(curses.COLORS)) # <-- number of colors the current terminal can support

    if (gWarningMessage is not None):
        for i in range(0,4):
            cursesClearLine(infoWin.win, i)
            attr = None
            if (i % 2 == 0):
                attr = curses.color_pair(WARNING_COLOR_ID)
            else:
                attr = curses.color_pair(WARNING_COLOR_ID)
            infoWin.safeAddStr(i, 0, gWarningMessage, attr)
            pass

        setWarning(None) # And then clear the warning

        pass

    infoWin.win.refresh()

    return

def drawEverything(theScreen):
    activeFI = mainInfo.getCurrent()
    activeCellPos = activeFI.cursorPos

    drawInfoWin(theScreen, activeFI, sheetWin.getTable())
    sheetWin.drawTable(activeFI, activeCellPos.y, activeCellPos.x)
    rowHeaderWin.drawTable(activeFI, activeCellPos.y, 0, nColsToDraw=1, boolPrependRowCoordinate=True)

    colHeaderWin.drawTable(activeFI, 0, activeCellPos.x, nRowsToDraw=1, boolPrependColCoordinate=True)

    lineAttr = curses.color_pair(BOX_COLOR_ID)
    colHeaderWin.win.attron(lineAttr)
    colHeaderWin.win.hline(colHeaderWin.windowHeight-1, 0, curses.ACS_CKBOARD, colHeaderWin.windowWidth)
    colHeaderWin.win.attroff(lineAttr)
    colHeaderWin.win.refresh()

    theScreen.refresh()
    return

def inputHandlingLoop(theScreen):

    ch = None
    while True:
        try:
            if (ch is None):
                ch = '' # this is a horrible hack, but for some reason we
                pass
            else: # need to run this loop at least once before things draw.
                ch = theScreen.getch()
                # DebugPrint(str(ch))
                global GLOB
                #infoWin.win.addstr(0, 0, "Read char <" + str(ch) + ">" + str(GLOB), curses.color_pair(COL_HEADER_ID))
                #GLOB += 1
                pass

            if (gCurrentMode == KEY_MODE_SEARCH_INPUT):
                handleKeysForSearchMode(ch, sheetWin.getTable(), theScreen)
                pass
            elif (gCurrentMode == KEY_MODE_NORMAL_INPUT):
                handleKeysForNormalMode(ch, sheetWin.getTable(), theScreen)
                pass

            if (gWantToQuit): break

            drawEverything(theScreen)

            pass

        except KeyboardInterrupt:
            break # Exit the program on a Ctrl-C as well. Regular terminal printing is automatically restored by "curses.wrapper"
        except:
            raise # Something unexpected has happened. Better report it!

        pass

    return # end of inputHandlingLoop


def setUpCurses(): # initialize the curses environment
    newlyMadeScreen = curses.initscr()
    newlyMadeScreen.keypad(0) # <-- somehow important for it to be 0...

    if (not curses.has_colors()):
        cleanupAndExit(1, "UH OH, this terminal does not support color! We might crash. Quitting now anyway until I figure out what to do. Sorry. This might not actually be a problem, but I will need to test it to see what happens in a non-color terminal!")
        pass
    curses.start_color()

    curses.init_pair(RAGGED_END_ID, RAGGED_END_TEXT_COLOR, RAGGED_END_BG_COLOR)
    curses.init_pair(SELECTED_CELL_ID, SELECTED_CELL_TEXT_COLOR, SELECTED_CELL_BG_COLOR)
    curses.init_pair(COL_HEADER_ID, COL_HEADER_TEXT_COLOR, COL_HEADER_BG_COLOR)
    curses.init_pair(ROW_HEADER_ID, ROW_HEADER_TEXT_COLOR, ROW_HEADER_BG_COLOR)
    curses.init_pair(BOX_COLOR_ID, BOX_COLOR_TEXT_COLOR, BOX_COLOR_BG_COLOR)
    curses.init_pair(BLANK_COLOR_ID, BLANK_COLOR_TEXT_COLOR, BLANK_COLOR_BG_COLOR)
    curses.init_pair(SEARCH_MATCH_COLOR_ID, SEARCH_MATCH_COLOR_TEXT_COLOR, SEARCH_MATCH_COLOR_BG_COLOR)
    curses.init_pair(WARNING_COLOR_ID, WARNING_COLOR_TEXT_COLOR, WARNING_COLOR_BG_COLOR)
    curses.init_pair(NUMERIC_NEGATIVE_COLOR_ID, NUMERIC_NEGATIVE_COLOR_TEXT_COLOR, NUMERIC_NEGATIVE_COLOR_BG_COLOR)
    curses.init_pair(NUMERIC_POSITIVE_COLOR_ID, NUMERIC_POSITIVE_COLOR_TEXT_COLOR, NUMERIC_POSITIVE_COLOR_BG_COLOR)
    curses.init_pair(ACTIVE_FILENAME_COLOR_ID, ACTIVE_FILENAME_COLOR_TEXT_COLOR, ACTIVE_FILENAME_COLOR_BG_COLOR)

    CURSES_INVISIBLE_CURSOR = 0
    CURSES_VISIBLE_CURSOR = 1
    CURSES_HIGHLIGHTED_CURSOR = 2
    try:
        curses.curs_set(CURSES_INVISIBLE_CURSOR) # Don't show a blinking cursor
    except curses.error, err:
        print("Unable to set cursor state to \"invisible\"")
        pass
    
    curses.meta(1)  # Allow 8-bit chars
    curses.noecho() # Don't echo keyboard input
    curses.cbreak() # Don't require ENTER to be pressed before keys are read

    return newlyMadeScreen


def cleanup():
    if (gStandardScreen is not None):
        gStandardScreen.erase()
        gStandardScreen.refresh()
        gStandardScreen.keypad(0)
        curses.echo()
        curses.nocbreak()
        curses.endwin()
        pass

    return # end of "cleanup"

def cleanupAndExit(exitCode, message=None):
    cleanup()
    if (message is not None):
        print "sheet.py: " + message
    sys.exit(exitCode)
    return

def truncateLongCell(argString, argMaxlen, argTruncString):
    if (len(argString) > argMaxlen):
        truncateToThisLen = argMaxlen - len(argTruncString)
        return (argString[:truncateToThisLen] + argTruncString)
    else:
        return argString
    pass

def padStrToLength(argString, argMaxlen, padChar):
    # pad out the length with blanks so that the ENTIRE
    # length is taken up However! curses does not like to
    # draw just plain things unfortunately so we have to
    # trick it with a -. This is very hackish. Maybe I
    # should draw colored boxes instead?
    numBlankSpacesToAdd = argMaxlen - len(argString)
    if (numBlankSpacesToAdd > 0):
        return (argString + str(padChar*numBlankSpacesToAdd))
    else:
        return argString
    return

def calculateBorderChar(r, c, topRow, leftCol, bottomRow, rightCol):
    if (r == 0): # TOP R
        if (c == 0):          ch = curses.ACS_ULCORNER
        elif (c == rightCol): ch = curses.ACS_URCORNER
        else:                 ch = curses.ACS_TTEE
        pass
    elif (r == bottomRow):
        if (c == 0):          ch = curses.ACS_LLCORNER
        elif (c == rightCol): ch = curses.ACS_LRCORNER
        else:                 ch = curses.ACS_BTEE
        pass
    else:
        if (c == 0): ch = curses.ACS_LTEE
        elif (c == rightCol): ch = curses.ACS_RTEE
        else:                 ch = curses.ACS_PLUS
        pass

    return ch


def handleKeysForSearchMode(argCh, currentTable, theScreen):

    finishedSearch = False
    cancelSearch = False

    if (argCh in KEYS_SEARCH_MODE_FINISHED):
        # ----------------------------------
        if (len(mainInfo.getCurrent().getRegexString()) > 0):
            finishedSearch = True # If there *is* a search string
            pass
        else:
            cancelSearch = True # Search string is blank--user cancelled the search
            pass
        # ----------------------------------
        pass
    elif (argCh in KEYS_SEARCH_MODE_CANCEL):
        # ----------------------------------
        cancelSearch = True
        # ----------------------------------
        pass
    elif argCh in KEYS_SEARCH_MODE_BACKSPACE or argCh in KEYS_SEARCH_MODE_DELETE_FORWARD:
        # ----------------------------------
        # we don't support forward-delete yet. sorry.
        # Pretend it's regular delete for now...
        if (mainInfo.getCurrent().regexIsActive() is False):
            # The user deleted PAST the beginning of the string
            cancelSearch = True
            pass
        else:
            mainInfo.getCurrent().trimRegex(numChars=1)
            currentTable.regTab.clear()
            pass
        # ----------------------------------
        pass
    else:
        # ----------------------------------
        # Append whatever the user typed to the search string...
        try:
            charToAdd = chr(argCh)
            mainInfo.getCurrent().appendToCurrentSearchTerm(charToAdd)
            currentTable.regTab.clear()
            pass
        except ValueError, err:
            # we don't care if "charToAdd" is not in the range of add-able chars
            pass
        # ----------------------------------
        pass

    if (cancelSearch):
        setCommandStr("Search Cancelled")
        mainInfo.getCurrent().clearCurrentSearchTerm()
        currentTable.regTab.clear()
        GLOBAL_exitSearchMode()
        pass
    elif (finishedSearch):
        setCommandStr("Searching for \"" + mainInfo.getCurrent().getRegexString() + '"')
        GLOBAL_exitSearchMode()
        pass
    else:
        setCommandStr("Search (press enter when done): " + mainInfo.getCurrent().getRegexString())
        pass

    return





def handleKeysForNormalMode(argCh, currentTable, theScreen):
    # Handle user keyboard input when we are *not* in search mode

    theAction = None

    wantToMove = Point(0,0)
    wantToChangeFileIdx = None

    activeCellPos = mainInfo.getCurrent().cursorPos

    #if (argCh is not None and argCh is not ''): raise "ArgCh: " + str(argCh)

    if argCh in KEYS_QUIT:
        global gWantToQuit
        gWantToQuit = True
        pass
    elif argCh in KEYS_TOGGLE_HIGHLIGHT_NUMBERS_MODE: mainInfo.getCurrent().toggleNumericHighlighting()
    elif argCh in KEYS_MOVE_TO_TOP:      activeCellPos.y = 0
    elif argCh in KEYS_MOVE_TO_BOTTOM:   activeCellPos.y = (currentTable.getNumRows()-1)
    elif argCh in KEYS_MOVE_RIGHT:       wantToMove.x = 1
    elif argCh in KEYS_MOVE_LEFT:        wantToMove.x = -1
    elif argCh in KEYS_MOVE_UP:          wantToMove.y = -1
    elif argCh in KEYS_MOVE_DOWN:        wantToMove.y = 1
    elif argCh in KEYS_MOVE_RIGHT_FAST:  wantToMove.x = fastMoveSpeed.x
    elif argCh in KEYS_MOVE_LEFT_FAST:   wantToMove.x = -fastMoveSpeed.x
    elif argCh in KEYS_MOVE_UP_FAST:     wantToMove.y = -fastMoveSpeed.y
    elif argCh in KEYS_MOVE_DOWN_FAST:   wantToMove.y = fastMoveSpeed.y
    elif argCh in KEYS_PREVIOUS_FILE: wantToChangeFileIdx = -1
    elif argCh in KEYS_NEXT_FILE:     wantToChangeFileIdx = 1
    elif argCh in KEYS_GOTO_NEXT_MATCH:
        theAction = kWANT_TO_MOVE_TO_SEARCH_RESULT
        theActionParam = -1
        pass
    elif argCh in KEYS_GOTO_PREVIOUS_MATCH:
        theAction = kWANT_TO_MOVE_TO_SEARCH_RESULT
        theActionParam = 1
        pass
    elif argCh in KEYS_TRANSPOSE: # Display the file in transposed format
        global gTransposition
        gTransposition = ~gTransposition
        temp = activeCellPos.x
        activeCellPos.x = activeCellPos.y
        activeCellPos.y = temp
        if (gTransposition):
            setCommandStr("Now displaying the file in TRANSPOSED format.")
            pass
        else:
            setCommandStr("Now displaying the file in NON-TRANSPOSED format again.")
            pass
        drawEverything(theScreen)
        pass
    elif argCh in KEYS_GOTO_LINE_END: activeCellPos.x = (currentTable.getNumCols()-1)
    elif argCh in KEYS_GOTO_LINE_START: activeCellPos.x = 0
    #elif argCh in (ord('w'),): sheetWin.win.mvwin(20,0)
    # elif argCh in (ord('R'),): gCellBorders.width = (1 - gCellBorders.width)
    elif argCh in (ord('r'),): gCellBorders.height = (1 - gCellBorders.height)
    elif argCh in (ord('/'),):
        GLOBAL_setUserInteractionMode(KEY_MODE_SEARCH_INPUT)
        mainInfo.getCurrent().clearCurrentSearchTerm()
        currentTable.initRegexTable()
        setCommandStr("Search (press enter when done): ")
        pass
    else:
        pass # unrecognized key


    if (theAction is None):
        pass
    elif (theAction == kWANT_TO_MOVE_TO_SEARCH_RESULT):
        setCommandStr("Sorry! Not implemented yet.")
        pass


    if (wantToMove.x != 0 or wantToMove.y != 0):
        activeCellPos.y = max(0, min(currentTable.getNumRows()-1, (activeCellPos.y+wantToMove.y)))
        activeCellPos.x = max(0, min(currentTable.getNumCols()-1 , (activeCellPos.x+wantToMove.x)))
        clearCommandStr() # whatever the previous command was, it no longer applies now that we have moved
        pass

    if (wantToChangeFileIdx is not None):
        possibleNewIndex = (mainInfo.currentFileIdx + wantToChangeFileIdx)
        if (mainInfo.getCurrent().filename is kSTDIN_HYPHEN):
            setWarning(">>> Cannot change files, because we read input from an STDIN pipe. Multiple files cannot be read when reading from a pipe.")
            pass
        elif (possibleNewIndex < 0):
            setWarning(">>> Cannot go to the previous file, because we are already at the beginning of the file list.")
            pass
        elif (possibleNewIndex >= mainInfo.size()):
            setWarning(">>> Cannot go to the next file, because we are already at the end of the file list.")
            pass
        else:
            sheetWin.win.clear()
            infoWin.win.clear()
            colHeaderWin.win.clear()
            colHeaderWin.win.refresh()
            rowHeaderWin.win.clear()
            mainInfo.currentFileIdx = possibleNewIndex # update which file we are currently examining
            initializeWindowSettings(mainInfo.getCurrent())
            setCommandStr("Changed to the file named \"" + mainInfo.getCurrent().filename + '".')
            pass
        pass



    return


def GLOBAL_exitSearchMode():
    if (gCurrentMode != KEY_MODE_SEARCH_INPUT):
        raise "Uh oh, tried to exit search mode... but we were not even IN search mode!!"
    else:
        GLOBAL_setUserInteractionMode(KEY_MODE_NORMAL_INPUT)
        pass
    return

def GLOBAL_setUserInteractionMode(argNewMode):
    global gCurrentMode
    gCurrentMode = argNewMode
    return


ALEX_PROGRAM_USAGE_TEXT = '''sheet.py
A program for displaying tab-delimited files in spreadsheet format.

This is a file-viewing program only, not an editor.

Written for Python 2.5.1 by Alex Williams, 2009.

Requires the "curses" terminal module, which is built-in
with most python distributions.


Usage:
   sheet.py INPUT_FILENAMES

or to read from STDIN:

   cat INPUT_FILE | sheet.py

Example usage:

sheet.pl myfile.tab
	This reads in the tab-delimited file "myfile.tab"

sheet.pl file1.tab anotherFile.tab
	This reads in two files. "file1.tab" is the first
	one you will see. You would have to press '>' in
	order to go to "anotherFile.tab".

Options and arguments:
-h or --help:
	Print this usage/help message

-w or --warn:
	Enable debugging warnings

Controls:

Navigation keys:
[  i  ]      [ Arrow  ]
[ jkl ]  or  [  Keys  ]:   (Hold shift to move faster)

	* Move the cursor around. Note that "IJKL" makes an
	  inverted-T shape, just like the arrow keys on most
	  keyboards.

	* Hold "shift" along with IJKL or the arrow keys in
          order to move faster.

	* Space Bar (down) and "b" (up) work to move
          quickly, just like in LESS.

	* Also supported is the standard terminal/emacs
          Ctrl-P/N/B/F for moving the cursor around.

Fast navigation keys:
[   g  ]
[ a   e]
[   G  ]:
	* Move to the top (g) or bottom (G) of a file (same
          keybindings as in LESS).

	* Move to the leftmost column (a) or rightmost
          column (e), with keybindings similar to emacs's.

[ < ] and [ > ]:

	* Switch between files, when more than one file was
          specified. Not valid when the input is STDIN.

[ / ]:
	* Set the search term. Text that matches will be
          highlighted. Hit "enter" to finish the search.
          Press [ / ] again to cancel.

[ q ]:
	* Quit the program.



BUGS:

	Someone should probably add a "--vi" switch to give
	this vi-style hjkl navigation.
'''



# Must come at the VERY END!
if __name__ == "__main__":
    main(sys.argv[1:])
    pass




# Extra code snippets:

# curses.textpad.rectangle(self.win, cellTextPos.y-1, cellTextPos.x-1, cellTextPos.y+cellHeight, cellTextPos.x+maxLenForThisCell)



# import curses as c

# def doKeyEvent(key):
#     if key == '\x00' or key == '\xe0': # non ASCII key
#        key = screen.getch() # fetch second character
#     screen.addstr(str(key)+' ')

# def doQuitEvent(key):
#     raise SystemExit

# # clear the screen of clutter, stop characters auto
# # echoing to screen and then tell user what to do to quit

# screen = c.initscr()
# c.noecho()
# screen.addstr("Hit space to end...\n")

# # Now mainloop runs "forever"
# while True:
#      ky = screen.getch()
#      if ky != -1:
#        # send events to event handling functions
#        if ky == ord(" "): # check for quit event
#             doQuitEvent(ky)
#        else:
#             doKeyEvent(ky)

# c.endwin()

# #


                        #. Move with IJKL. Hold shift to move faster. '/' activates search mode.")
#     infoWin.safeAddStr(1, 0, fileStatusString)
#     infoWin.safeAddStr(2, 0, "File #" + str(mainInfo.currentFileIdx+1) + " (of " + str(mainInfo.size()) + ") is \"" + theInfo.filename + "\"")

#     selectedCellProperty = curses.color_pair(SELECTED_CELL_ID)

#     cursesClearLine(infoWin.win, 3)
#     if (selectedCellText is None):
#         line3 = "R_" + str(activeCellPos.y+1) + ", C_" + str(activeCellPos.x+1) + " does not exist in this table."
#         infoWin.safeAddStr(3, 0, line3, curses.A_NORMAL)
#         pass
#     else:
#         line3a = "R_" + str(activeCellPos.y+1) + ", C_" + str(activeCellPos.x+1) + " = "
#         line3b = selectedCellText
#         infoWin.safeAddStr(3, 0, line3a, curses.A_NORMAL)
#         infoWin.safeAddStr(3, len(line3a), line3b, selectedCellProperty)
#         pass





# b = BitBoard(row=3, col=5)

# b.board[1][1] = None
# print b.board[1][1]

# b.board[0][1] = False
# print b.board[0][1]

# b.board[1][0] = True
# print b.board[1][0]

#sys.exit(1)
#b.set(row=2,col=1)
#print b.at(2,3)
#print b.sizeX()
#print b.board
#sys.exit(1)
