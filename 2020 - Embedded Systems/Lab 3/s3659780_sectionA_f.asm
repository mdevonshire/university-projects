;
; Lab3PartA.asm
;
; Created: 13/09/2020 7:45:20 AM
; Author : Matthew Devonshire s3659780


; Define some variables
;
.def  temp  = r16
.equ SP = 0xDF

; Define here Reset and interrupt vectors, if any
;
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

;***********************************************************
;
;   EEET2256 Laboratory 3a
;
; This program reads the OUSB DIP switches and displays the 
; value on the 8 LEDs
;*******************************
;
; Program starts here after Reset
start:
	LDI  TEMP,  SP    		; First, initialise the Stack pointer before we use it
	OUT  0x3D,  TEMP
    CALL Init              	; Initialise the system, ports etc.

loop:		
	CALL	ReadSw          ; value returned in R16 (temp)
                    		; This is useful comment as it says what this program is doing

	CALL	Display         ;Displays R16(temp) on the LEDs
	RJMP	loop			; Do all again NB You don't need to reinitialize
;
;
;
;************************************************************************
;
Init:				 ;initialise the I/O
		
	LDI r17, 0x00
	LDI r18, 0xFF

	OUT 0x14, r17 ;DDRC to 0x00
	OUT 0x15, r18 ;portc to 0xFF
	OUT 0x17, r18 ;DDRB to 0xFF
		RET
		
;************************************************************************
;
;   ReadSw reads DIP switch value into R16
; uses:  R16 (Temp)
; returns: temp
;
 ReadSw:
;   ReadSw reads numbers from the keypad and combines into Temp
;
	IN	Temp, 0x13	; put value of PINC (0x13) into register Temp
	NOP
  	    						  
	    RET		                  ; Exit back to calling routine with value in R16
;
;********************************************************************
; takes whatever is in the Temp register and outputs it to the LEDs
Display:
	OUT 0x18, Temp ;set portb(0x18) to Temp
		RET
;*************************************
;
.exit 		



