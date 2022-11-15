;
; Three-Zone_Alarm_Ass.asm
;
; Nelson Quach, s3779770 
; Matthew Devonshire, s3659780
;
key_table:					
	;   0x0  0x1  0x2  0x3  0x4  0x5  0x6  0x7  0x8  0x9  0xA  0xB  0xC  0xD  0xE  0xF  
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255  ; 0x0
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x1
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x2
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x3
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x4
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x5
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x6
	.DB 255, 255, 255, 255, 255, 255, 255 , 13, 255, 255, 255,  12, 255,  11,  10, 255	; 0x7
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x8
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0x9
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0xA
	.DB 255, 255, 255, 255, 255, 255, 255 , 15, 255, 255, 255,   9, 255,   6,   3, 255	; 0xB
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0xC
	.DB 255, 255, 255, 255, 255, 255, 255 ,  0, 255, 255, 255,   8, 255,   5,   2, 255	; 0xD
	.DB 255, 255, 255, 255, 255, 255, 255 , 14, 255, 255, 255,   7, 255,   4,   1, 255	; 0xE
	.DB 255, 255, 255, 255, 255, 255, 255 ,255, 255, 255, 255, 255, 255, 255, 255, 255	; 0xF
	// A=10 B=11 C=12 D=13 "*"=14 "#"=15

user_input:
	.DB 254, 254, 254, 254

code_value:
	.DB 1, 2, 3, 4 //This is the intial code 



.equ key_table_size = 16
.equ code_max_storage = 1 //for now
.equ code_max_length = 4 //for now
//Initiate Global Variables 
.def temp = r16
// R17 IS FUNCTIONALLY A SECOND TEMP VALUE
.def LEDstatus = r18
.def armed = r19				// Flag for armed status
.def trigger_large_C = r20			// Counter to help time strobe LED
.def trigger = r21				// Flag for triggered status
.def trigger_counter = r22		// Counter to help time the strobe LED
.def error_counter = r23		// Counter for incorrect attempts
.def temp_counter = r24			//another temp value

//Initiate Ports 
	LDI temp, 0xFF
	OUT DDRB, temp	; Set PORTB as output
	LDI temp, 0xF0
	OUT DDRC, temp	; Set PORTC bits 0-3 as inputs
	LDI temp, 0x0F
	OUT PORTC, temp	; Enable PORTC pullup resistors for bits 0-3

//Initial Values
CLR LEDstatus
CLR armed
CLR trigger
CLR error_counter
CLR trigger_counter
	
initialise:
	CALL initialise_code				; will write the original code to data space so it can be overwritten	
	

start:
	CALL reset_user_input				; resets the user input
	CLR temp_counter					; this will count how many numbers have been recived

recive_keypad_signals:
	CALL medium_delay	
	CALL read_keypress					; result will have "contents" of ZL equal to key press
	INC temp_counter
	CALL medium_delay
	LPM temp, Z							; Write the "contents" of ZL to temp
  
	CALL check_for_character			; call subroutine to check for A B C D # or *, will return if a number, otherwise will go off and do other things.
	
	CPI temp_counter, (code_max_length +1)	; after 5 inputs, error code will come up
	BREQ error_code_jmp

	CALL update_user_input				; writes temp to the dataspace where the user input is stored
	
	

	RJMP recive_keypad_signals
hash_pressed:							; if the hash is pressed, the user_input is not counted and the code skips straight to checking the code
	CPI temp_counter, 4
	BRLO error_code_jmp					; if the number of inputs is less than 4, error code
	CALL check_user_code				; if code is correct it will return here, otherwise it will have gone through the error subroutine.
	CALL reset_user_input				; after correct code entered, reset the user input code
	CLR error_counter					; if the code is correct, the error counter is reset.

	CPI armed, 0
	BRNE armed_on						; if armed = 0, trigger will also = 0 (unless of bugs) 
	JMP Arm_Alarm
armed_on:
	CPI trigger, 0						; if armed = 1 and trigger = 0, the alarm should be disarmed
	BRNE triggered
	JMP Disarm_Alarm
triggered:
	JMP Shutdown_Alarm					; (theoretically) the only option left is armed = 1 and trigger = 1, and the alarm should be shutdown.
	RJMP start							; theoretically, this would not be reached


error_code_jmp:
	JMP error_code

initialise_code:
	LDI ZL, low(code_value<<1)			; set Z register on code_value
	LDI ZH, high(code_value<<1)
	CLR r27								; clear X high byte
	LDI r26, $60						; set XL to $60
ini_1:
	LPM temp, Z							; Write the "contents" of ZL to temp
	ST X, temp							; Write temp to address pointed to by XL
	CPI r26, ($5F + code_max_length)	; check to see if all of code copied
	BREQ return_2						;  return if finished
	INC ZL
	INC XL
	RJMP ini_1							; repeat until whole table copied
return_2:
	RET

reset_user_input:	
	LDI ZL, low(user_input<<1)			; set Z register on code_value
	LDI ZH, high(user_input<<1)
	CLR r27								; clear X high byte
	LDI r26, $70						; set XL to $70
reset_1:
	LPM temp, Z							; Write the "contents" of ZL to temp
	ST X, temp							; Write temp to address pointed to by XL
	CPI r26, ($6F + code_max_length)	; check to see if all of code copied
	BREQ return_2						;  return if finished
	INC ZL
	INC XL
	RJMP reset_1							; repeat until whole table copied


update_user_input:
									//the goal of this subroutine is to put the value of temp (the number recived from keypad) into the user_input table, in the correct location
	CLR r27								; clear X high byte
	LDI r26, $6F						; set XL to $6F
	CALL incXL							; inc XL by number equal to temp_counter
	ST X, temp							; write value of temp to address pointed to by XL
	RET
incXL:
	PUSH temp				; save temp as we will need it
	CLR temp				; temp will be used as a counter in this subroutine
X1:
	CP temp, temp_counter	; compare to see if XL has been incremented enough
	BREQ X2					; if so, wrap up subroutine
	INC XL					; otherwise increment XL 
	INC temp				; and temp,
	RJMP X1					; then repeat	
X2:
	POP temp				; clean up and return
	RET

check_for_character:
	CPI temp, 10			; check if input was a numerial
	BRLO return_1			; if temp less than 10, return
	CPI temp, 15			; check if input was "#"
	BREQ hash_pressed
	CPI temp, 14			; if input was "*", change the code (if armed = 0)
	BREQ change_code
	CPI armed, 1
	BRNE Error_code			; if alarm is not armed, pressing A B or C will do nothing
	CPI temp, 10			; if alarm is armed, check for A B or C (10=A)
	BREQ trigger_A
	CPI temp, 11			; 11=B
	BREQ trigger_B
	CPI temp, 12			; 12=C
	BREQ trigger_C
	JMP Error_code			; this is left in the occasion that armed = 1 and temp = D

change_code:
	LDI R17, 0
	CPSE armed, R17						; if armed does not = 0, don't change the code
	RJMP dont_change
	CPI temp_counter, 4					; if <4 digits, don't change the code
	BRLO dont_change
	CLR ZH
	LDI ZL, $60							; address of stored code
	CLR XH
	LDI XL, $70							; address of user input
change_1:
	LD temp, X							; store value of XL in temp
	ST Z, temp							; store temp in address pointed to by ZL (update code)
	INC ZL
	INC XL				
	CPI ZL, ($60 + code_max_length)		; if all digits changed, initiate success
	BREQ code_changed
	RJMP change_1
dont_change:
	JMP error_code
code_changed:
	ORI LEDstatus, 0x02		; mask to turn on LED1
	OUT PORTB, LEDstatus
	CALL medium_delay
	ANDI LEDstatus, 0xFD	; mask to turn off LED1
	OUT PORTB, LEDstatus
	JMP start


trigger_A:
	ORI LEDstatus, 0x02		; 0b00000010 mask to turn LED1 on (zoneA LED)
	RJMP trigger_alarm
trigger_B:
	ORI LEDstatus, 0x08		; 0b00001000 mask to turn LED3 on (zoneB LED)
	RJMP trigger_alarm
trigger_C:
	ORI LEDstatus, 0x20		; 0b00100000 mask to turn LED5 on (zoneC LED)
	RJMP trigger_alarm
trigger_alarm:
	ORI LEDstatus, 0x40		; 0b01000000 mask to turn LED6 on (Siren LED)
	LDI trigger, 1
	OUT PORTB, LEDstatus
	JMP start				; return to reciving input after triggering alarm

return_1:
	RET

check_user_code:
	//temp = code_value, R17 = user_input
	CLR ZH						; Set the Z register to check the code value stored in data
	LDI ZL, $60
	CLR XH
	LDI XL, $70
check1:
	LD temp, Z					; Write the "contents" of ZL to temp (temp = code)
	LD R17, X					; Write the "contents" of XL to R17 (R17 = user input)
	CP temp, R17				; compare the values
	BRNE Error_Code				; If not equal, show error code
	INC ZL
	INC XL
	CPI XL, ($70 + code_max_length)
	BREQ return_1
	RJMP check1


Error_Code:
	PUSH R0						; we will use R0 as a 0 value
	CLR R0
	ORI LEDstatus, 0x04			; 0x04 = 0b00000100, mask to turn on LED2
	OUT PORTB, LEDstatus
	CALL medium_delay
	ANDI LEDstatus, 0xFB		; 0xFB = 0b11111011, mask to turn off LED2
	OUT PORTB, LEDstatus
	CALL medium_delay
	ORI LEDstatus, 0x04			; 0x04 = 0b00000100, mask to turn on LED2
	OUT PORTB, LEDstatus
	CALL medium_delay
	ANDI LEDstatus, 0xFB		; 0xFB = 0b11111011, mask to turn off LED2
	OUT PORTB, LEDstatus
	CPSE armed, R0				; if the alarm is not armed, the error will not count
	INC error_counter			; count the amount of errors
	POP R0						; R0's job is done
	CPI error_counter, 5
	BREQ error_overload			; if there are 5 errors, trip the alarm

	JMP start

error_overload:
	CLR error_counter
	LDI armed, 1				; set armed status to on
	ORI LEDstatus, 0x01			; 0b00000001 is mask to turn on LED0 (armed LED)
	JMP	trigger_alarm			; LED1 will be updated in the trigger_alarm subroutine

read_keypress:
	CLR temp
	CLR trigger_large_C
	LDI ZH, high(key_table<<1)
    LDI ZL, low(key_table<<1)
read_column1:
	CPI trigger, 0
	BREQ skip_strobe	; if not triggered, skip this next section which will turn off/on strobe
	INC trigger_counter
	CPI trigger_counter, 0xFF
	BREQ inc_large_C
	RJMP skip_strobe
inc_large_C:
	INC trigger_large_C
	CPI trigger_large_C, 0x05
	BREQ strobe_on
	CPI trigger_large_C, 0x0A
	BREQ strobe_off
	RJMP skip_strobe
strobe_on:
	ORI LEDstatus, 0x10		; mask to turn on LED4 (strobe)
	OUT PORTB, LEDstatus	; turn on strobe
	RJMP skip_strobe
strobe_off:
	ANDI LEDstatus, 0xEF	; mask to turn off LED4 (strobe)
	OUT PORTB, LEDstatus	; turn off strobe
	CLR trigger_large_C

skip_strobe:
	LDI R17, 0xEF		; Set column 1 low
	OUT PORTC, R17		; Write to PORTC

	RCALL delay			; Delay

	IN temp, PINC		; Extracts the value of PINC and store into temp
	CP temp, R17		; Compare column value to temp
	BREQ read_column2	; Checks if a value has been pressed

	RJMP hex_convert	; If a value has been pressed, jump to the conversion

read_column2:
	LDI R17, 0xDF		; Set column 2 low
	OUT PORTC, R17		; Write to PORTC

	RCALL delay			; Delay

	IN temp, PINC		; Extracts the value of PINC and store into temp
	CP temp, R17		; Compare column value to temp
	BREQ read_column3	; Checks if a value has been pressed

	RJMP hex_convert	; If a value has been pressed, jump to the conversion

read_column3:
	LDI R17, 0xBF		; Set column 3 low
	OUT PORTC, R17		; Write to PORTC

	RCALL delay			; Delay
		
	IN temp, PINC		; Extracts the value of PINC and store into temp
	CP temp, R17		; Compare column value to temp
	BREQ read_column4	; Checks if a value has been pressed

	RJMP hex_convert	; If a value has been pressed, jump to the conversion

read_column4:
	LDI R17, 0x7F		; Set column 4 low
	OUT PORTC, R17		; Write to PORTC

	RCALL delay			; Delay

	IN temp, PINC		; Extracts the value of PINC and store into temp
	CP temp, R17		; Compare column value to temp
	BREQ read_column1	; Checks if a value has been pressed, jumps back to first column

	RJMP hex_convert	; If a value has been pressed, jump to the conversion

hex_convert:
	CP temp, ZL							; Compare temp to address/index of key table
	BREQ return							; If index is equal to temp, return to main code

	INC ZL								; Otherwise, increment to next index

	CPI ZL, low((key_table<<1) + 256)	; If the index reaches the end, start over
	BRNE hex_convert

	CLR ZL								; Clears ZL 

	RJMP recive_keypad_signals			; Jumps back to start to read value again

return:
	RET
delay:
	PUSH R16		; save R16 as we're going to use it
	PUSH R0			; we'll also use R0 as a zero value
	CLR R0
	CLR R16			; init inner counter
L1:      DEC R16    ; counts down from 0 to FF to 0
	CPSE R16, R0    ; equal to zero?
	RJMP L1			; if not, do it again
	CLR R16			; reinit inner counter

	POP R0          ; done, clean up and return
	POP R16

	RET
medium_delay:
	PUSH R16		; save R16 as we're going to use it
	PUSH R17		; same with R17
	PUSH R18		; and R18
	PUSH R0			; we'll also use R0 as a zero value
	CLR R0
	CLR R16			; initiate inner counter
	CLR R17			; initiate layer 1 counter
	LDI R18, 0x08	; initiate outer counter 
M1:
	DEC R16			; counts down from 0 to FF to 0
	CPSE R16, R0    ; equal to zero?
	RJMP M1			; if not, do it again
	CLR R16			; reinit inner counter
	DEC R17			; counts down from 0 to FF to 0
	CPSE R17, R0    ; equal to zero?
	RJMP M1			; if not do it again
	CLR R17			; reinit layer 1 counter
	DEC R18			; counts down from 0 to FF to 0
	CPSE R18, R0    ; equal to zero?
	RJMP M1			; if not do it again

	POP R0			; done, clean up and return
	POP R18
	POP R17
	POP R16
	RET
		
Arm_Alarm:
	ORI LEDstatus, 0x01  ; 0b00000001 is the mask to turn on LED0 (armed LED)
	OUT PORTB, LEDstatus
	CALL medium_delay
	CALL medium_delay
	CALL medium_delay
	ANDI LEDstatus, 0xFE ; 0b11111110 is the mask to turn off LED0 (armed LED)
	OUT PORTB, LEDstatus
	CALL medium_delay
	CALL medium_delay
	CALL medium_delay
	ORI LEDstatus, 0x01  ; 0b00000001 is the mask to turn on LED0 (armed LED)
	OUT PORTB, LEDstatus
	CALL medium_delay
	CALL medium_delay
	CALL medium_delay
	ANDI LEDstatus, 0xFE ; 0b11111110 is the mask to turn off LED0 (armed LED)
	OUT PORTB, LEDstatus
	CALL medium_delay
	CALL medium_delay
	CALL medium_delay
	ORI LEDstatus, 0x01  ; 0b00000001 is the mask to turn on LED0 (armed LED)
	OUT PORTB, LEDstatus
	
	LDI armed, 1		 ; Set "Armed" status to on
	JMP start



Disarm_Alarm:
	LDI armed, 0			; Set "Armed" status to off
	ANDI LEDstatus, 0xFE    ; 0b11111110 is the mask to turn off LED0 (armed LED)
	OUT PORTB, LEDstatus    ; LED0 OFF
	JMP start

Shutdown_Alarm:			
	ANDI LEDstatus, 0x85	; 0b10000101 is the mask to turn off LED1 (ZoneA), LED3 (ZoneB), LED5 (ZoneC), LED4 (StrobeLED) and LED6 (SirenLED)
	OUT PORTB, LEDstatus	; apply changes to LEDstatus
	LDI trigger, 0x00		; change triggered status to off (0)
	// ADD CODE TO TURN OFF STROBE LIGHT
	JMP start