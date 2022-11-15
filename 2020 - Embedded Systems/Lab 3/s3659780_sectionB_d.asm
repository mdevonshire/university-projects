;
; Lab3SectionB.asm
;
; Created: 14/09/2020 8:02:57 AM
; Author : Matthew Devonshire s3659780
;

; ******************************************************
; BASIC .ASM template file for AVR
; ******************************************************

; Define some variables here
;
.def  temp  = r16
.def i = r20
.def two = r21
.def tempread = r22
.def col = r23
.def row = r24
.def three = r25
.def counter = r19
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
;   EEET2256 Laboratory 3
;
; This program reads two numbers from a key pad
;
;*******************************
;
; Program starts here after Reset
start:
		LDI  TEMP,  SP    ; Init Stack pointer
		OUT  0x3D,  TEMP
		LDI two, 2
	  	LDI three, 3
		

       CALL	Init
	   
	   OUT	portb, temp              	;Initialise the system.

loop:		
;	    CALL	ReadTwo           ;value returned in R16 (temp) READTWO NOT NEEDED FOR SECTION B
        CALL	ReadKP                   	

	    CALL	Display
	    RJMP	loop					;Do all again NB You don't need to reinitialize
;
;
;
;************************************************************************
;
Init:
; uses:    R16
; returns: nothing
;
;initialise the 16-key keypad connected to Port C
; this assumes that a 16-key alpha numeric keypad is connected to
;port C as follows (see keypad data):
; key pad   function 		   J2 pin
;  1      Row 1, Keys 1, 2, 3, A       1   PC0
;  2      Row 2, Keys 4, 5, 6, B       2   PC1
;  3      Row 3, Keys 7, 8, 9, C       3   PC2
;  4      Row 4, Keys *, 0, #, D       4   PC3
;  5      Column 1, Keys 1, 4, 7, *    5   PC4
;  6      Column 2, Keys 2, 5, 8, 0    6   PC5
;  7      Column 3, Keys 3, 6, 9, #    7   PC6
;  8      Column 4, Keys A, B, C, D    8   PC7

	; Set the pull-up resistor values on PORTC.
	CLR temp
	
	LDI temp, 0b11110000         
	OUT 0x14, temp ;DDRC to 0x0F
	
	LDI temp, 0b11111111
	OUT 0x15, temp ;portc to 0xFF
	OUT 0x17, temp ;DDRB to 0xFF
	NOP

  	RET
		
;************************************************************************
;
;   ReadTwo reads two numbers from the keypad and combines into R16
; uses:  R16 (Temp), R17
; returns: temp
;
; ReadTwo:   ;READTWO NOT NEEDED FOR SECTION B
;   ReadTwo reads two numbers from the keypad and combines into Temp
;
;	    RCALL	ReadKP	          ;Read one number from keypad and return in Temp (R16)
;	    PUSH	Temp	             	 ;saves first number
;	    RCALL	ReadKP	          ;Read second into R16
;	    POP  R17                   ;first number now in R17
;	    RCALL	Combine            ;Build the number - result in Temp in hexadecimal
;	    RET		                   ;Exit back to calling routine
;
;********************************************************************
;ReadKP will determine which key is pressed and return that key in Temp
;The design of the keypad is such that each row is normally pulled high
; by the internal pullups that are enabled at init time
;
;When a key is pressed contact is made between the corresponding row and column.
;To determine which key is pressed each column is forced low in turn
;and software tests which row has been pulled low at micro input pins
;
;To avoid contact bounce the program must include a delay to allow
;the signals time to settle
;
ReadKP:

		clr temp
		ldi i, 16
		ldi temp, 0b11101111
		ldi col, 1
		ldi row, 1
loopc:
	out portc, temp
	nop
	nop
	in tempread, pinc
	nop
//	bst tempread, 1			;if col 1, row 1 was pressed, bit 1 will be 0 
//	brtc table					;if bit one was 0, flag t will be cleared, meaning the number has been found
	cpi tempread, 0b11101110
	breq table
	cpi tempread, 0b11011110
	breq table
	cpi tempread, 0b10111110
	breq table
	cpi tempread, 0b01111110
	breq table

	inc row
	;bst tempread, 2			;if col 1, row 1 was pressed, bit 1 will be 0 
	;brtc table
	cpi tempread, 0b11101101
	breq table
	cpi tempread, 0b11011101
	breq table
	cpi tempread, 0b10111101
	breq table
	cpi tempread, 0b01111101
	breq table

	inc row
	;bst tempread, 3
	;brtc table
	cpi tempread, 0b11101011
	breq table
	cpi tempread, 0b11011011
	breq table
	cpi tempread, 0b10111011
	breq table
	cpi tempread, 0b01111011
	breq table

	inc row
	;bst tempread, 4
	;brtc table
	cpi tempread, 0b11100111
	breq table
	cpi tempread, 0b11010111
	breq table
	cpi tempread, 0b10110111
	breq table
	cpi tempread, 0b01110111
	breq table


	sub temp, i			;move to check the next column
	mul i, two
	mov i, r0
	inc col
	;cpi i, 128 <-- this shouldn't happen, should have already broke
	;breq 
	rjmp loopc

table:

	mov temp, col			 ;make temp = col
	dec temp				 ;temp = temp - 1
	mul temp, three			 ;temp = temp*3
	mov temp, r0
	add temp, col			 ;temp = temp + col
	add temp, row			 ;temp = temp + row
							 ;the value of temp now shows the position in the table for the key press (* = 0x0E, # = 0x0F)
	LDI ZH, high(Tble<<1)	; Initialize Z-pointer
	LDI ZL, low(Tble<<1)	; a byte at a time 
	LDI counter, 0 

zlloop:					; the section increments zl to the same number as temp
	inc ZL
	inc counter
	cp counter, temp
	breq findnumber
	nop
	rjmp zlloop

findnumber:
	LPM temp, Z				;store the value of Z as temp, this should be the pressed key
	NOP
	RET


	;create 128 value table
Tble:
	.DB 0xFF, 0xFF, 0x01, 0x04, 0x07, 0x0E, 0x02, 0x05
	.DB 0x08, 0x00, 0x03, 0x06, 0x09, 0x0F, 0x0A, 0x0B
	.DB 0x0C, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

;
;
;Combine will take most significant decimal number in A and
;add to least significant decimal number in B
;The result will be returned in Accum B in hexadecimal
;
Combine:
	    RCALL	H2Dec             ;Convert hex to decimal
		 RET
		
;H2Dec will convert a hexadecimal byte in Temp to a decimal value
; (also in Temp)
;
H2Dec:
    	
		RET	;do nothing for now
;

;************************************************************************
;
; takes whatever is in the Temp register and outputs it to the LEDs
Display:
			OUT	0x18, temp
			RET
;*************************************
;
; Delay routine
;
; this has an inner loop and an outer loop.  The delay is approximately
; equal to 256*256*number of inner loop instruction cycles.
; You can vary this by changing the initial values in the accumulator.
; If you need a much longer delay change one of the loop counters
; to a 16-bit register such as X or Y.
;
;*************************************
Delay:
         PUSH R16			; save R16 and 17 as we're going to use them
         PUSH R17       ; as loop counters
         PUSH R0        ; we'll also use R0 as a zero value
         CLR R0
         CLR R16        ; init inner counter
         CLR R17        ; and outer counter
L1:      DEC R16         ; counts down from 0 to FF to 0
			CPSE R16, R0    ; equal to zero?
			RJMP L1			 ; if not, do it again
			CLR R16			 ; reinit inner counter
L2:      DEC R17
         CPSE R17, R0    ; is it zero yet?
         RJMP L1			 ; back to inner counter
;
         POP R0          ; done, clean up and return
         POP R17
         POP R16
         RET
.exit 		



