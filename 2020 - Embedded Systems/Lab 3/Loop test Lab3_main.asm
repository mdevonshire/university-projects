;
; Loop Test Lab3.asm
;
; Created: 18/09/2020 7:33:33 AM
; Author : suref
;


; Replace with your application code
	.def temp = r16
	.def i = r17
	.def two = r18
	.def tempread = r19
	.def col = r21
	.def row = r22
	LDI two, 2
start:
    
	ldi temp, 0b11110111
	call loopinitialise
	nop
	nop
	rjmp start

loopinitialise:
	
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
	bst tempread, 1		;if col 1, row 1 was pressed, bit 1 will be 0 
	brtc return				;if bit one was 0, flag t will be cleared, meaning the number has been found

	inc row
	bst tempread, 2		;if col 1, row 1 was pressed, bit 1 will be 0 
	brtc return

	inc row
	bst tempread, 3
	brtc return

	inc row
	bst tempread, 4
	brtc return


	sub temp, i			;move to check the next column
	mul i, two
	mov i, r0
	inc col
	;cpi i, 128 <-- this shouldn't happen, should have already broke
	;breq 
	rjmp loopc

return:
	ret
