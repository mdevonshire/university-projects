
; s3659780_questionB.asm
; Author: Matthew Devonshire
; 14/08/2020
; 
;
;

; Define here the variables
.def  temp  =r19
.def counter =r17 ;set r17 to the counter
.def lownumber =r18 ;set r18 to the placeholder for the low number




; Define here Reset and interrupt vectors, if any
; the only one at the moment is the reset vector
;that points to the start of the program (i.e., label: start)
reset:
   rjmp start
   reti      ; Addr $01
   reti      ; Addr $02
   reti      ; Addr $03
   reti      ; Addr $04
   reti      ; Addr $05
   reti      ; Addr $06        Use 'rjmp myVector'
   reti      ; Addr $07        to define a interrupt vector
   reti      ; Addr $08
   reti      ; Addr $09
   reti      ; Addr $0A
   reti      ; Addr $0B        This is just an example
   reti      ; Addr $0C        Not all MCUs have the same
   reti      ; Addr $0D        number of interrupt vectors
   reti      ; Addr $0E
   reti      ; Addr $0F
   reti      ; Addr $10

; Program starts here after Reset
.cseg
start:		; start here

; The Z register is used as a pointer to the t  entries in the table 
; so we need to load the location of the table into the high and 
; low byte of Z. 
; Note how we use the directives 'high' and 'low' to do this.

	LDI ZH, high(Tble<<1)	; Initialize Z-pointer
	LDI ZL, low(Tble<<1)	; a byte at a time 
	LPM lownumber, Z ;move the value that Z is pointing to into lownumber as a start point
	CLR counter

/*
Psudocode:
int counter = 0
lownumber = Tble[counter]
while (counter < 63)
	counter++
	if (table[counter] < lownumber)
		lownumber = Tble[counter]
	else
output low
*/

loop:
	INC ZL ;increment the pointer
	INC counter ;increment the counter (used in checkend)
	LPM temp, Z ;set temp to the value Z is pointing to
	CP temp, lownumber ;compare temp and lownumber
	BRLO replacelow ;if temp is less than lownumber, go to replacelow function

/* Psudocode for checking 
	JMP checkend ;if temp was not less than lownumber, skip the replacelow function and move to checkend

replacelow:
	MOV lownumber, temp

checkend:
	CPI counter, 63 ;one less than length of table 
	BRNE loop ;move back to loop while still in table

here:
   JMP here  ; why do we need this? To create a stop? so it would just loop forever?

; Create 64 bytes in code memory of table to search.
; The DC (or DB?) directive defines constants in (code) memory
; you will search this table for the desired entry.
Tble:
	.DB 181, 127,  80,  43, 159, 252,  44,  66 
	.DB 102,  19, 175, 103, 251,  68, 154,  12
	.DB  98,  42, 203, 223,  90,  83,  76, 136
	.DB 213, 153,  86,  77, 116, 108,  92, 143
	.DB 190, 109, 110,  32,   7,  74,  81, 167
	.DB 245, 239, 117,  62, 195, 194, 189, 191
	.DB  28, 162, 119,  55,  26, 211,  45,  58
	.DB 170, 229, 132, 180,  40, 244, 138, 174


.exit  ;done and dusted



