TITLE Project 6 - String Primitives and Macros     (Proj6_morrowas.asm)

; Author: Ashley Morrow
; Last Modified: 3/19/23
; OSU email address: morrowas@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 3/19/23
; Description: Uses primitive functions to prompt the user for 10 numbers, calculates the sum and
;	average, and prints the values to the console.
;              

INCLUDE Irvine32.inc


;-------------------------------------------------------------------------------------------------
; Name: mGetString
;
; Description: 
;
; Preconditions: Address of prompt string array must be passed to the system
;	stack by reference. ESI must contain the address of the current userInput array index.
;
; Receives:
;	stringA			=	address of prompt
;	inputLocation	=	address of current element of userInput byte array, total size: 20 bytes
;	countAddress	=	address of countInput, to hold character count
;
; Returns: User input now at address entered as inputLocation. Character length of input now at
;	address of countInput variable.
;-------------------------------------------------------------------------------------------------
mGetString macro stringA, inputLocation, countAddress
	push	eax
	push	ebx
	push	ecx
	push	edx

	mDisplayString stringA
	mov		edx, inputLocation
	mov		ecx, 20						 
	call	ReadString						
	mov		countAddress, eax

	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
endm

;-------------------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Description: Prints the string passed to it by reference.
;
; Preconditions: The address of the string to be printed must already be pushed to the system stack.
;
; Postconditions:
;
; Receives:
;	stringB = address of string array
;
; Returns:
;-------------------------------------------------------------------------------------------------
mDisplayString MACRO stringB
	push	edx
	mov		edx, stringB
	call	WriteString
	call	Crlf
	pop		edx
endm

ARRAYSIZE = 10

.data

title1			BYTE	"Project 6: Creating low-level macros and procedures",13,10,0
title2			BYTE	"By: Ashley Morrow",13,10,0
intro1			byte	"Please enter 10 signed decimals.",10, 
						"The sum of all 10 numbers must fit within a 32 bit register.",10,
						"Once entered, a list of the integers, their sum, and their average ",10,
						"value will be displayed.",13,10,0
prompt1			byte	"Please enter a signed number: ",0
userInput		byte	20 dup(?)
countInput		dword	?						;Holds the number of characters the user inputs
errorMsg		byte	"Error! Number too large or not a signed number. Try again.",13,10,0
prompt2			byte	"Try again: ",0
numArray		sdword	ARRAYSIZE dup(0)
typeArray		dword	TYPE numArray			
countArray		dword	LENGTHOF numArray		
sumArray		sdword	0						;Sum of numbers in numArray
avgArray		sdword	?						;Average of numbers in numArray
avgRemainder	dword	?						;Holder for remainder in average calculations
revString		byte	100 dup(?)				;Holds reversed string from decimal to ASCII
numTitle		byte	"Here are the numbers you entered: ",0
sumTitle		byte	"The sum of these numbers is: ",0
avgTitle		byte	"The truncated average of these numbers is: ",0
numString		byte	110 dup(?)
sumString		byte	12 dup(?)
avgString		byte	12 dup(?)

.code
main PROC

	;Display introduction
	push	offset title1
	push	offset title2
	push	offset intro1
	call	introduction

	;Read input from user

	mov		ecx, countArray
	mov		esi, offset userInput
	mov		edi, offset numArray

_loopStart:
	push	offset prompt1
	push	offset userInput
	push	offset countInput
	push	offset errorMsg
	push	offset prompt2
	push	offset numArray
	push	typeArray
	push	countArray
	call	ReadVal
	loop	_loopStart

	push	offset numArray
	push	typeArray
	push	countArray
	push	offset sumArray
	call	calculateSum

	push	countArray
	push	sumArray
	push	offset avgRemainder
	push	offset avgArray
	call	calculateAverage

	push	offset numArray
	push	typeArray
	push	countArray
	push	sumArray
	push	avgArray
	push	offset revString
	push	offset numTitle
	push	offset sumTitle
	push	offset avgTitle
	push	offset numString
	push	offset sumString
	push	offset avgString
	call	displayValues

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;-------------------------------------------------------------------------------------------------
; Name: introduction
;
; Displays the program and programmer's name, then provides an introduction for the user explaining
;	the functionality of the program. Uses the mDisplayString macro to display the strings.
;
; Preconditions:
;
; Postconditions: 
;
; Receives:
;	[ebp+8]		=	address of intro1 global variable
;	[ebp+12]	=	address of title2 global variable
;	[ebp+16]	=	address of title1 global variable
;
; Returns:
;
;-------------------------------------------------------------------------------------------------
introduction proc
	push	ebp
	mov		ebp, esp
	push	edx			;Will be used by mDisplayString macro
	
	;Print title1
	mDisplayString	[ebp+16]

	;Print title2
	mDisplayString	[ebp+12]

	;Print intro1
	mDisplayString	[ebp+8]

	pop		edx
	pop		ebp
	ret		12
introduction endp

;-------------------------------------------------------------------------------------------------
; Name: readVal
;
; Prompts the user to input a signed integer, then puts that entry into a memory location using the 
;	mGetString macro. Then, converts the string of ascii digits to its numeric representation and
;	validates that the entry is not too large or not a signed integer. Lastly, stores the validated
;	value to memory.
;
; Preconditions:
;
; Postconditions:
;
; Receives: 
;	
;	[ebp+8]		=	address of countArray global variable; value: 10
;	[ebp+12]	=	typeArray variable, number of bytes in data type
;	[ebp+16]	=	address of numArray global variable
;	[ebp+20]	=	address of prompt2 global variable (string array)
;	[ebp+24]	=	address of errorMsg global variable (string array)
;	[ebp+28]    =	address of countInput, holds the number of characters the user inputs
;	[ebp+32]	=	address of userInput global variable (byte array)
;	[ebp+36]	=	address of prompt1 global variable (string array)
;
; Returns:
;
;-------------------------------------------------------------------------------------------------
ReadVal proc
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	;Prompts user for input using prompt1, stores in userInput array based on what index ESI is
	;	pointing at.
_promptforNum:
	mov		ebx, [ebp+28]					;Moves address of countInput into EBX
	mGetString [ebp+36], esi, [ebx]			

	;If number of characters greater than 11, number automatically too large, re-prompt
	mov		eax, [ebx]
	cmp		eax, 11
	jg		_tryAgain

	;Check to see if first character is + or -
	push	esi
	mov		edx, 0
	mov		dl, [esi]
	cmp		dl, 43
	je		_modifyCounter
	cmp		dl, 45
	je		_modifyCounter
	jmp		_normalCounter

_modifyCounter:
	mov		ecx, [ebx]
	dec		ecx
	inc		esi
	jmp		_outerLoop

_normalCounter:
	;Loop to check to see if any of the characters input are invalid
	mov		ecx, [ebx]						;Set outer loop equal to number of characters entered
	
_outerLoop:
	mov		ebx, 0							;Clear EBX
	cld
	lodsb									;Moves value at ESI to AL
	push	ecx								;Preserve outer loop counter
	mov		ecx, 48							;Will check input number against ascii characters 0d through 47d
	
	;Checks for ascii characters 0d through 47d
_innerLoop:
	cmp		al, bl
	je		_tryAgain
	inc		bl
	loop	_innerLoop

	mov		bl, 58
	mov		ecx, 70

	;Checks for ascii characters 58d through 127d
_innerLoop2:
	cmp		al, bl
	je		_tryAgain
	inc		bl
	loop	_innerLoop2

	pop		ecx
	loop	_outerLoop

	jmp		_startConversion

_tryAgain:
	mDisplayString [ebp+24]
	jmp		_promptforNum

_startConversion:
	;Convert string of ascii digits to numeric value
	mov		eax, 0					;Clearing EAX
	pop		esi						;ESI now holds offset of first userInput byte array again
	mov		ebx, 0					;Clearing EBX
	mov		edx, esi				;Moving address of userInput first array index to edx/dl
	mov		bl, [edx]				;Moves value at first array index to ebx/bl
	cmp		ebx, 43					;Checking to see if first character is +
	je		_skipFirstChar			;If equal, will skip first character, then process as normal
	cmp		ebx, 45
	je		_negativeNum
	jmp		_positiveNum

_skipFirstChar:
	mov		ebx, [ebp+28]			;Moves address of countInput into EBX
	mov		ecx, [ebx]				;Moves value at EBX to ECX counter
	sub		ecx, 2					;Decrement by 2 to skip first character (one less loop turn than normal case, first run won't be in loop)
	inc		esi						;Increment by 1 to skip first character (move pointer by one byte)
	jmp		_setFirstValue

_positiveNum:
	mov		ebx, 0					;Initialize ebx to 0, must not be a part of any loop
	mov		ebx, [ebp+28]			;Moves address of countInput into EBX
	mov		ecx, [ebx]				;Moves value at EBX to ECX counter
	dec		ecx						;Subtracts 1 from ECX since first character will not be part of loop
	mov		ebx, 0					;Once counter set, clear EBX

_setFirstValue:
	cld
	lodsb							;Copies value pointed to by ESI register to AL register, then modifies ESI to point to next location
	sub		al, 48					;Convert to integer value
	mov		ebx, eax				;Moves first integer value to ebx
	mov		eax, 0					;Clear EAX
	cmp		ecx, 0
	je		_moveTotal

_conversionLoop:
	cld
	lodsb							;Copies value pointed to by ESI register to AL register, then modifies ESI to point to next location
	sub		al, 48					;Convert to integer value
	push	eax						;Push integer value to stack
	mov		eax, 0
	mov		edx, 0		
	mov		eax, ebx				;Move EBX (grand total) to EAX for multiplication
	mul		dword ptr [ebp+8]		;Multiply grand total by 10, new grand total in EAX
	mov		ebx, eax				;Store result in ebx
	pop		dword ptr eax			;Integer value from conversion back in eax/al
	add		ebx, eax				;EBX now has new grand total (grand total + new integer)
	loop	_conversionLoop	
	
_moveTotal:
	mov		eax, edi
	mov		[eax], ebx
	jmp		_endProcedure

_negativeNum:
	call Crlf
	
_endProcedure:
	pop		edi
	add		edi, 4
	pop		esi
	inc		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		32
ReadVal	endp

;-------------------------------------------------------------------------------------------------
; Name: calculateSum
;
; Calculates the sum of the values in numArray.
;
; Preconditions: numArray must be filled in with 10 values.
;
; Postconditions:
;
; Receives:
;	[ebp+8]		=	memory address of sumArray
;	[ebp+12]	=	value of countArray global variable (10)
;	[ebp+16]	=	value of typeArray global variable (4)
;	[ebp+20]	=	memory address of numArray
;
; Returns: sumArray will hold the sum of all the values in the array.
;
;-------------------------------------------------------------------------------------------------
calculateSum proc
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push    esi
	push	edi

	mov		eax, 0				;Make sure EAX is clear
	mov		esi, [ebp+20]		;Move numArray address to ESI
	mov		edi, [ebp+8]		;Move sumArray address to EDI
	mov		ecx, [ebp+12]		;Counter set to 10

_addition:
	mov		ebx, [esi]			;Move value at current index of numArray to EBX
	add		eax, ebx			;Using EAX to hold total
	add		esi, [ebp+16]		;Move to next element
	loop	_addition
	mov		[edi], eax

	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		16
calculateSum	endp

;-------------------------------------------------------------------------------------------------
; Name: calculateAverage
;
; Calculates the average of the values in numArray.
;
; Preconditions: sumArray must hold the sum of the values in numArray.
;
; Postconditions: 
;
; Receives:
;	[ebp+8]		=	memory address of avgArray
;	[ebp+12]	=	memory address of avgRemainder
;	[ebp+16]	=	value of sumArray global variable
;	[ebp+20]	=	value of countArray global variable (10)
;
; Returns: sumArray will hold the sum of all the values in the array.
;
;-------------------------------------------------------------------------------------------------
calculateAverage proc
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx

	mov		edx, 0			;Clearing EDX for division
	mov		eax, [ebp+16]	;Move value of sumArray to EAX
	CDQ						;Sign extend EAX into EDX
	mov		ebx, [ebp+20]	;Value of countArray to EBX
	idiv	ebx				;EAX holds quotient, EDX holds remainder
	mov		ebx, [ebp+8]	;EBX now holds memory address of avgArray
	mov		[ebx], eax

	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		16
calculateAverage	endp

;-------------------------------------------------------------------------------------------------
; Name: displayValues
;
; Description: Displays the integers entered by the user, their sum and their truncated average.
;
; Preconditions:
;
; Postconditions:
;
; Receives:
;	[ebp+8]		=	address of avgString
;	[ebp+12]	=	address of sumString
;	[ebp+16]	=	address of numString
;	[ebp+20]	=	address of avgTitle
;	[ebp+24]	=	address of sumTitle
;	[ebp+28]	=	address of numTitle
;	[ebp+32]	=	address of revString
;	[ebp+36]	=	decimal value of avgArray
;	[ebp+40]	=	decimal value of sumArray
;	[ebp+44]	=	value of countArray
;	[ebp+48]	=	value of typeArray
;	[ebp+52]	=	address of numArray
;
; Returns:
;
;-------------------------------------------------------------------------------------------------

displayValues proc
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	;Display num title
	mDisplayString [ebp+28]

	;Convert numbers from numArray to ASCII and print
	mov		ecx, ARRAYSIZE
	mov		esi, [ebp+52]		;Move address of numArray to ESI

_printNext:
	push	ecx
	mov		eax, 0
	mov		ecx, 100
	mov		edi, [ebp+32]		;Clearing revString for next printing
	rep		stosb

	push	[ebp+16]			;Pushing address of numString to stack
	push	[esi]				;Pushing decimal value at current index of numArray
	push	[ebp+32]			;Pushing address of revString to stack
	call	WriteVal
	pop		ecx
	add		esi, 4
	loop	_printNext

	;Display sum title
	mDisplayString [ebp+24]

	;Convert sum integer to ASCII and print
	mov		eax, 0
	mov		ecx, 100
	mov		edi, [ebp+32]		;Clearing revString for next printing
	rep		stosb

	push	[ebp+12]			;Pushing address of sumString to stack
	push	[ebp+40]			;Pushing decimal value of sumArray to stack
	push	[ebp+32]			;Pushing address of revString to stack
	call	WriteVal


	;Display average title
	mDisplayString [ebp+20]

	;Convert average integer to ASCII and print
	mov		eax, 0
	mov		ecx, 100
	mov		edi, [ebp+32]		;Clearing revString for next printing
	rep		stosb

	push	[ebp+8]				;Pushing address of avgString to stack
	push	[ebp+36]			;Pushing decimal value of avgArray to stack
	push	[ebp+32]			;Pushing address of revString to stack
	call	WriteVal


	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		48
displayValues	endp

;-------------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Description: Converts numeric SDWORD value to a string of ASCII digits, then invokes the
;	mDisplayString macro to print the ASCII representation of the value to output.
;
; Preconditions: Must push address that converted string will be added to
;	and value being converted to stack right before the call to
;	WriteVal.
;
; Postconditions:
;
; Receives:
;	[ebp+8]		=	address where reversed string will be saved
;	[ebp+12]	=	decimal value being converted to ASCII
;	[ebp+16]    =   address where converted value will be saved
;
; Returns:
;
;-------------------------------------------------------------------------------------------------

WriteVal proc
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	mov		eax, [ebp+12]	;move value being converted to EAX
	mov		esi, [ebp+8]	;move address where reversed converted value will be saved to ESI
	mov		edi, [ebp+16]	;move address where final converted value will be saved to EDI
	mov		ecx, 0			;will start counting number of times array is filled with a character

_keepConverting:
	cdq
	mov		ebx, 10			;move divisor (10) to EBX
	idiv	ebx				;quotient in EAX, remainder in EDX
	add		edx, 48			;converted remainder to ASCII
	mov		[esi], edx
	inc		ecx
	cmp		eax, 0
	je		_reverseString
	inc		esi
	jmp		_keepConverting

_reverseString:
	STD
	LODSB
	CLD
	STOSB
	loop	_reverseString

	mDisplayString [ebp+16]

	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12			;Clears items pushed to stack before call
WriteVal	endp
END main
