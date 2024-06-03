/*

	Cross Sums script!
	This script simple generates a plain text list of all the groups of digits (1-9, no repeats) that add up to a given sum
	Zero is not allowed as a digit. No blank spaces allowed (a 2-digit number must be full 2 digits).

	Reference: https://teachinglondoncomputing.org/kriss-kross-puzzles/

*/

#SingleInstance force ; only one instance of script can run
SetWorkingDir, %A_ScriptDir%		; My Documents
debug := False		; local / network switch

#Include, C:\Users\rob.lund\OneDrive - Thermo Fisher Scientific\Documents\AutoHotkey\Lib\GuiButtonIcon\GuiButtonIcon.ahk
#Include, C:\Users\rob.lund\OneDrive - Thermo Fisher Scientific\Documents\AutoHotkey\Lib\FileDialogs\FileDialogs.ahk
#Include, C:\Users\rob.lund\OneDrive - Thermo Fisher Scientific\Documents\AutoHotkey\Lib\AddTooltip\AddTooltip.ahk
#Include, C:\Users\rob.lund\OneDrive - Thermo Fisher Scientific\Documents\AutoHotkey\Lib\range.ahk
#Include, C:\Users\rob.lund\OneDrive - Thermo Fisher Scientific\Documents\AutoHotkey\Lib\ExploreObj.ahk

;---------------------------
; experimentation


If (debug)
{
	numbers := GetCollection(2)

	; check here if we want to print unused digits
	
	DisplayCollection(numbers, 2)


	numbers := GetCollection(3)

	DisplayCombinations(numbers, 3)
	numbers := GetCollection(4)
	DisplayCombinations(numbers, 4)
	numbers := GetCollection(5)
	DisplayCombinations(numbers, 5)
	numbers := GetCollection(6)
	DisplayCombinations(numbers, 6)
	numbers := GetCollection(7)
	DisplayCombinations(numbers, 7)

}


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; MsgBox 0x40, Cross Sums Helper, Welcome to the Cross Sums helper!  This will generate a file with all the possible combinations of digits for a given sum.  `n`nOptions for output are either CSV (for importing into Excel to sort and "prettify" as you see fit) or text to be printed or pasted elsewhere.`n`nThe digits unused option can be disabled.

; OutputDirectory := ChooseFolder([0, "Where would you like to save the file?"], A_MyDocuments, , 0x02000000) ; Do not add the item being opened or saved to the recent documents list (SHAddToRecentDocs).

Gui, Font, s12 norm bold, Arial
Gui, Add, Button, x200 y270 w85 h38 hwndStartButtonID vStartButton gStartButton, Start
GuiButtonIcon(StartButtonID, "shell32.dll", 259, "s32 a1 r2")
AddTooltip(StartButtonID, "Create the listing of sums and print to a file in your folder")

Gui, Add, Checkbox, x200 y240 gBackupsCheckbox vBackupsCheckbox, Search archive locations?	; add below previous control

Gui, Font, s14 norm bold, Arial
Gui, Add, Text, cRed x245 y10 h20, Number of Digits

Gui, Font, s16 norm cBlack
Gui, Add, DropDownList, AltSubmit vPresetLocation gPresetLocation x30 y65 w150 hwndPresetID



; parse the parts
Loop, 9
	If (A_Index > 1)
		optionString .= A_Index . "|"

; add the options
GuiControl, , PresetLocation, %optionString%




Gui, Show, w400 h370, Cross Sums Helper!
Return

GuiClose:
ExitApp
Return



;--------------
; Script log
;--------------

PresetLocation:

GuiControlGet, PresetLocation

If (PresetLocation = "")
{
	OutputDebug, no preset selected! `n
}
Else
{
	searchPath := stationPath[PresetLocation] . "\" . folderLogs . "\"		; add back slashes just in case
	OutputDebug, preset drop down was selected (index = %PresetLocation%), path = %searchPath% `n

	; also prep the archive folder
	searchBackup := stationPath[PresetLocation] . "\" . folderLogBackups . "\"		; add back slashes just in case
	OutputDebug, archive folder = %searchBackup% `n

	; save the primary
	searchPathPrimary := searchPath
}

GuiControl, Text, SearchPathDisplay, %searchPath%

Return




;--------------
; Log mover GUI
;--------------
BackupsCheckbox:

Return

;--------------
; Log mover GUI
;--------------

StartButton:

	TotalStartTime := A_TickCount

	;------------------------
	; start algorithm

	;------------------------
	; log results

	TotalElapsedTime := (A_TickCount - TotalStartTime)/1000
	logText = #### DONE - File created in %TotalElapsedTime% seconds

	;------------------------
	; open results

	; Sleep, 750
	Run, explore %OutputDirectory%

Return

;===============
; Helper Functions
;===============


GetCollection(numberDigits)
{
	StartTime := A_TickCount

	combinations := []
	combination := []
	
	GenerateCombinations(numberDigits, 1, combination, combinations)

	; print out the results
	DisplayCombinations(combinations, numberDigits)

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

; this function exists because "copying" an array into another array is done by reference in AHK, not true copying
CopyArray(arr)
{
	result := []

	For index, value in arr
		result.Push(value)

	Return result
}

; sum the combination array 
SumArray(arr)
{
	For index, digit in arr
		sum += digit

	Return sum
}

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

; parse through the collection object and prints out the combinations only
DisplayCombinations(combinations, numberDigits)
{
	size := combinations.MaxIndex()

	OutputDebug, There are %size% combinations of %numberDigits% digits (no repeats, 1-9, order not important):

	For index, combination in combinations
	{
		combinationString := ""

		For i, value in combination
			If (i < numberDigits)
				combinationString .= value . ", "
			Else
				combinationString .= value
				
		OutputDebug, combination #%index%: %combinationString%
	}
}

; parse through the collection object and print out the options along with their sum
DisplayCollection(collection, numberDigits)
{
	size := collection.MaxIndex()

	OutputDebug, There are %size% sums for %numberDigits% digits (no repeats, 1-9, order not important):

	Loop, %size%
	{
		collectionString := "sum " . collection[A_Index].sum . " has " . collection[A_Index].combinations.MaxIndex() . " combination of digits: `n"
		OutputDebug, %collectionString%

		For set, combination in collection[A_Index].combinations
		{
			Loop, %numberDigits%
			{
				collectionString .= combination[A_Index]

				If (A_Index < numberDigits)
					collectionString .= "+"
			}

				
		OutputDebug, collection #%index%: %collectionString%
		}
	}
}
