/*
	Cross Sums script!
	This script simple generates a plain text list of all the groups of digits (1-9, no repeats) that add up to a given sum
	Zero is not allowed as a digit. No blank spaces allowed (a 2-digit number must be full 2 digits).

	Reference: https://teachinglondoncomputing.org/kriss-kross-puzzles/
	
	Dell Penny puzzle books: https://www.pennydellpuzzles.com/?s=cross+sums

	File export option prints a nice cheat sheet similar to the one PennyPress publishes on their website
*/

#SingleInstance force ; only one instance of script can run
SetWorkingDir, %A_ScriptDir%		; My Documents
debug := False		; debug switch to experiment, disables GUI

; libraries
#Include, %A_MyDocuments%\AutoHotkey\Lib\GuiButtonIcon\GuiButtonIcon.ahk
#Include, %A_MyDocuments%\AutoHotkey\Lib\AddTooltip\AddTooltip.ahk
#Include, %A_MyDocuments%\AutoHotkey\Lib\ScrollBox\ScrollBox.ahk


ScrollBoxSettings := "f{s9 cBlack, Arial} h400 w400 x400 p w d c b1"

;===============
; experimentation
;===============


If (debug)
{
	numbers := GetCollection(2)
	DisplayCollection(numbers, 2, True)	; include unused digits

	numbers := GetCollection(3)
	DisplayCollection(numbers, 3, True)

	numbers := GetCollection(4)
	DisplayCollection(numbers, 4)

	numbers := GetCollection(5)
	DisplayCollection(numbers, 5)

	numbers := GetCollection(6)
	DisplayCollection(numbers, 6)

	numbers := GetCollection(7)
	DisplayCollection(numbers, 7)

	Pause
}


;===============
; GUI creation
;===============


;----------
; digit quantity drop down menu

Gui, Font, s14 norm bold, Arial
Gui, Add, Text, x50 y25 h20, Number of Digits

Gui, Font, s16 norm cBlack
Gui, Add, DropDownList, vDigitsDropdown x50 y65 w50 hwndPresetID

; make a drop down digit selector
Loop, 9
	If (A_Index > 1)
		optionString .= A_Index . "|"
	optionString .= "All"
	
GuiControl, , DigitsDropdown, %optionString%

;----------
; unused digits checkbox

Gui, Font, s12 norm bold, Arial
Gui, Add, Checkbox, x50 y120 vUnusedCheckbox, Show unused digits?

;----------
; file export checkbox

Gui, Font, s12 norm bold, Arial
Gui, Add, Checkbox, x50 y160 vExportCheckbox, Save to file?

;----------
; Start button

Gui, Font, s14 norm bold, Arial
Gui, Add, Button, x100 y200 w100 h45 hwndStartButtonID vStartButton gStartButton, Start
GuiButtonIcon(StartButtonID, "shell32.dll", 300, "s32 a1 r2")
AddTooltip(StartButtonID, "Create the listing of sums and print to a file in your folder")

;----------
; start GUI

Gui, Show, w300 h275, Cross Sums Helper!
Return

GuiClose:
Quit:
ExitApp


;--------------
; Start!

StartButton:

; get all GUI variable values
Gui, Submit, NoHide

; test GUI variable collection
OutputDebug, % DigitsDropdown
OutputDebug, % UnusedCheckbox
OutputDebug, % ExportCheckbox
OutputDebug, % StartButton

If (DigitsDropdown = "")
{
	MsgBox 0x30, Error, Select a number of digits first!
}
Else
{
	If (ExportCheckbox)
	{
		FileSelectFile, OutputFile, S, %A_MyDocuments%\Cross Sums options.csv, Cross Sums Helper, *.csv

		; trap for cancel
		If (ErrorLevel = 1)
			Return
		Else IfExist, %OutputFile%
			FileDelete, %OutputFile%
	}

	; disable other controls until done
	GuiControl, Disable, ExportCheckbox
	GuiControl, Disable, UnusedCheckbox
	GuiControl, Disable, DigitsDropdown
	GuiControl, Disable, StartButton

	; specific number of digits?
	If DigitsDropdown is digit
	{
		numbers := GetCollection(DigitsDropdown)
		DisplayCollection(numbers, DigitsDropdown, UnusedCheckbox)
		
		If (ExportCheckbox)
			PrintCollection(numbers, DigitsDropdown, UnusedCheckbox)
	}
	; all digits?
	Else If DigitsDropdown is alpha
	{
	; TODO: skip reporting?
		Loop, 9
		{
			If (A_Index > 1)
			{
				numbers := GetCollection(A_Index)
				; DisplayCollection(numbers, A_Index, UnusedCheckbox)
				
				If (ExportCheckbox)
					PrintCollection(numbers, A_Index, UnusedCheckbox)
			}
		}
	}
}

; disable other controls until done
GuiControl, Enable, ExportCheckbox
GuiControl, Enable, UnusedCheckbox
GuiControl, Enable, DigitsDropdown
GuiControl, Enable, StartButton

Return



;===============
; Helper Functions
;===============



;--------------
GetCollection(numberDigits)
{
	global ExportCheckbox

	StartTime := A_TickCount

	combinations := []
	combination := []
	
	GenerateCombinations(numberDigits, 1, combination, combinations)

	If (ExportCheckbox = False)
	{
		; print out the results
		DisplayCombinations(combinations, numberDigits)
	}

	ElapsedTime := (A_TickCount - StartTime) / 1000
	OutputDebug, %ElapsedTime% seconds have elapsed.

	; new approach here for sorting and summing

	; first get all the sums of each combination
	sums := []
	For i In combinations
	{
		; these sums will largely be in order already, by design
		sum := SumArray(combinations[i])

		AddSumToArray(sums, sum)
	}

	; make an array of all the unique sums along with their combinations of digits
	collection := []

	For j In sums
	{
		; now make the grouping object
		collection[j] := {}

		; make a collection object
		; put the combo into that sum bucket
		collection[j].sum := sums[j]
		collection[j].combinations := []

		; parse through the combinations now
		For k, combination In combinations
		{
			; these sums will largely be in order already, by design
			sum := SumArray(combination)

			If (sum = collection[j].sum)
			{
				collection[j].combinations.Push(combination)
			}
		}
	}

	Return collection
}


;--------------
GenerateCombinations(numberDigits, currentDigit, combination, combinations)
{
	If (numberDigits = 0)
	{
		; copy the array manually
		combinations.Push(CopyArray(combination))

		Return
	}

	Loop, 9
	{
		if (A_Index >= currentDigit)
		{
			combination.Push(A_Index)
			GenerateCombinations(numberDigits - 1, A_Index + 1, combination, combinations)
			combination.Pop()
		}
	}
}


;--------------
; this function exists because "copying" an array into another array is done by reference in AHK, not true copying
CopyArray(arr)
{
	result := []

	For index, value in arr
		result.Push(value)

	Return result
}


;--------------
; sum the combination array 
SumArray(arr)
{
	For index, digit in arr
		sum += digit

	Return sum
}


;--------------
; searches for sum in sum array. If we can't find, it's new and is inserted at the end. If we find it, returns index.  If sum should exist between two indexes, returns second index
AddSumToArray(arr, newSum)
{
	foundIndex := 1

	For index, sum in arr
	{
		If (sum = newSum)
			Return	; sum already exists, bail out
		Else If (newSum > sum)
			foundIndex := index+1
		Else If (newSum < sum)
		{
			If (foundIndex > 1)
				Break
			Else
				foundIndex := 1
		}
	}

	arr.InsertAt(foundIndex, newSum)
	Return foundIndex
}


;--------------
; parse through the collection object and prints out the combinations only
DisplayCombinations(combinations, numberDigits)
{
	global ScrollBoxSettings

	size := combinations.MaxIndex()

	ReportString = There are %size% combinations of %numberDigits% digits (no repeats, 1-9, order not important): `n

	For index, combination in combinations
	{
		combinationString := ""

		For i, value in combination
			If (i < numberDigits)
				combinationString .= value . ", "
			Else
				combinationString .= value
				
		ReportString .= "combination #" . index . ": " . combinationString . "`n"
	}

	OutputDebug, % ReportString
	ScrollBox(ReportString, ScrollBoxSettings, "Digit Combinations")
}


;--------------
; parse through the collection object and print out the options along with their sum
; option to show unused digits, default off
DisplayCollection(collection, numberDigits, showUnused := False)
{
	global ScrollBoxSettings

	size := collection.MaxIndex()

	ReportString = There are %size% sums for %numberDigits% digits (no repeats, 1-9, order not important): `n

	Loop, %size%
	{
		; init unused array of booleans (true @ index = used, false = unused)
		usedDigits := []

		collectionString := "sum=" . collection[A_Index].sum . ", " . collection[A_Index].combinations.MaxIndex() . " combinations of digits: `n"

		For set, combination in collection[A_Index].combinations
		{
			Loop, %numberDigits%
			{
				; remove used digits
				usedDigits[combination[A_Index]] := True

				collectionString .= combination[A_Index]

				If (A_Index < numberDigits)
					collectionString .= "+"
			}

			collectionString .= "`n"
		}

		If (showUnused)
		{
			collectionString .= "Unused digits: "
			firstUnused := False

			; assume all used digits
			allUsed := True

			Loop, 9
			{
				If (usedDigits[A_Index] <> True)
				{					
					allUsed := False

					; comma placement
					If (firstUnused = False)
					{
						collectionString .= A_Index
						firstUnused := True
					}
					Else
						collectionString .=  ", " . A_Index
				}
			}

			If (allUsed)
				collectionString .=  "(none)"

			collectionString .= " `n"
		}

		ReportString .= collectionString
	}

	OutputDebug, % ReportString
	ScrollBox(ReportString, ScrollBoxSettings, "Sum Collections")
}


;--------------
; parse through the collection object and print out the options along with their sum
; option to show unused digits, default off
PrintCollection(collection, numberDigits, showUnused := False)
{
	global OutputFile

	; header
	ReportString := "`n" . numberDigits . " DIGITS`n"

	size := collection.MaxIndex()

	Loop, %size%
	{
		; init unused array of booleans (true @ index = used, false = unused)
		usedDigits := []

		collectionString := collection[A_Index].sum . " = `t"

		For set, combination in collection[A_Index].combinations
		{
			Loop, %numberDigits%
			{
				; remove used digits
				usedDigits[combination[A_Index]] := True

				collectionString .= combination[A_Index]

				If (A_Index < numberDigits)
					collectionString .= "+"
			}

			collectionString .= "`t"
		}

		If (showUnused)
		{
			unusedString := "{"
			firstUnused := False

			; assume all used digits
			allUsed := True

			Loop, 9
			{
				If (usedDigits[A_Index] <> True)
				{					
					allUsed := False

					; comma placement
					If (firstUnused = False)
					{
						unusedString .= A_Index
						firstUnused := True
					}
					Else
						unusedString .=  ", " . A_Index
				}
			}

			unusedString .= "}"

			If (!allUsed)
				collectionString .=  unusedString
		}

		collectionString .= "`n"
		ReportString .= collectionString
	}

	FileAppend, %ReportString%, %OutputFile%
}