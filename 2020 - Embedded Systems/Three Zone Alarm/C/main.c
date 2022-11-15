/*	Three-zone Alarm using ATMEGA32A
	
	Nelson Quach, s3779770
	Matthew Devonshire, s3659780
	
	Due: 9th Oct, 2020
*/

#define key_table_size 16
#define code_max_storage 3
#define code_max_length 6

//	Initialise Table						  0     1     2     3     4     5     6     7     8     9     A     B     C     D     *     #
volatile unsigned const char Key_Table[] = { 0xD7, 0xEE, 0xDE, 0xBE, 0xED, 0xDD, 0xBD, 0xEB, 0xDB, 0xBB, 0x7E, 0x7D, 0x7B, 0x77, 0xE7, 0xB7 };
	
volatile unsigned char key_value[code_max_storage][code_max_length] = {						// User code that can be up to 6 keys long and max 3 users
																	  { 1, 2, 3, 4 },		// User #1
																	  { 0, 8, 5, 2, 3, 9},	// User #2 
																	  { 5, 8, 0, 7, 9}		// User #3 
																	  };		
							
volatile unsigned char temp_key[code_max_length] = {};		// Temporary alarm code for error checking							
volatile char valid_code = 0;								// Flag for valid code checking
volatile char armed = 0;									// Flag for armed status
volatile char trigger = 0;									// Flag for triggered status
volatile int code_counter = 1;								// Counter for code length 
volatile int code_row = 0;									// Counter for code row indication
volatile int error_counter = 0;								// Counter for incorrect attempts
volatile unsigned char zone_location = 0;					// Zone location bit for trigger

// Initialising Required Ports
volatile unsigned char * DDB = (unsigned char *)0x37;		// DDRB
volatile unsigned char * DDC = (unsigned char *)0x34;		// DDRC
volatile unsigned char * PtB = (unsigned char *)0x38;		// PORTB
volatile unsigned char * PtC = (unsigned char *)0x35;		// PORTC
volatile unsigned char * PnC = (unsigned char *)0x33;		// PINC

void delay(volatile long int delay_time)					// Simple loop for delay
{
	for(volatile long int i = 0; i < delay_time; i++);
}
void Arm_Alarm()											// Turns on the armed LED
{	
	trigger = 0;			// Trigger status is set to false
	armed = 1;				// Armed status is set to true
	
	// Flash arm LED
	for(int i = 0; i < 5; i++)
	{
		*PtB = 0x01;		
		delay(200000);		// Delay to simulate occupants leaving
		*PtB = 0x00;		
		delay(200000);		// Delay to simulate occupants leaving
	}
	
	*PtB = 0x01;			// Set armed LED to 0000 0001
}
void Disarm_Alarm()											// Shuts off the armed LED
{
	*PtB = *PtB & 0xFE;		// Bitwise AND 1111 1110 to shut off armed LED
	armed = 0;
}
void Error_Code()											// Rapid LED flash if code was incorrectly inputted
{
	for(volatile int i = 0; i < 2; i++)
	{
		*PtB = *PtB | 0x04;	// Bitwise OR 0000 0100 for error LED;		
		delay(20000);
		*PtB = *PtB & 0xFB;	// Bitwise AND 1111 1011 to shut off error LED;		
		delay(20000);
	}
}
void Trigger_Alarm()										// Sets strobe and siren LED
{
	*PtB = zone_location | 0x50;		// Bitwise OR siren and strobe LED (0101 0000)
	delay(102417);						// Delay		
	*PtB = *PtB & 0x6A;					// Bitwise AND zone bits and siren LED (0110 1010)	
	delay(102417);						// Delay
}
unsigned char Read_Press()									// Reads key press of the user and returns a raw value
{
	*PtC = 0xEF;						// Set column 1 Low
	delay(100);							// Delay
	if(*PnC != 0xEF) { return *PnC; }
		
	*PtC = 0xDF;						// Set column 2 Low
	delay(100);							// Delay
	if(*PnC != 0xDF) { return *PnC; }
		
	*PtC = 0xBF;						// Set column 3 Low
	delay(100);							// Delay
	if(*PnC != 0xBF) { return *PnC; }
		
	*PtC = 0x7F;						// Set column 4 Low
	delay(100);							// Delay
	if(*PnC != 0x7F) { return *PnC; }
		
	return 0;
}
void Hex_Convert(volatile unsigned char * key_ptr)			// Converts the hex value obtained by the keypad into the value represented by the keypad
{
	for(volatile int i = 0; i < key_table_size; i++)
	{
		if(*key_ptr == Key_Table[i]) 
		{ 
			*key_ptr = i; 
			return; 
		}
	}
}
void Check_Code()											// Checks the inputted code with the stored code located in the 2D array
{	
	valid_code = 1;
	
	for(volatile int i = 0; i < code_max_length; i++)		
	{
		if(temp_key[i] != key_value[code_row][i])			// Checks temporary key code with stored codes
		{
			code_row++;										// Increment code row
			i = 0;											// Reset counter
			
			if (code_row > 3)								// If the code array has reached the end, break
			{
				valid_code = code_row = 0;
				break;
			}
			continue;
		}
	}
	
	for(int i = 0; i < code_counter; i++) { temp_key[i] = 0; }	// Reset temp code
}										
void Change_Code()											// Changes code of the last user that disarmed the alarm
{
	for(volatile int i = 0; i < code_counter; i++) { key_value[code_row][i] = temp_key[i]; }	// Checks temporary key code with stored codes
	for(volatile int i = 0; i < code_counter; i++) { temp_key[i] = 0; }							// Reset temp code
}	

int main(void)
{
	unsigned char key_press = 0;							// Stores individual key press
	unsigned char * key_ptr = &key_press;					// Key pointer
	
	// Set status of PORTS
	*DDB = 0xFF;											// Set PORTB to all outputs
	*DDC = 0xF0;											// Set 4 upper bits of PORTC to outputs
	*PtC = 0x0F;											// Enable pull up resistors for lower 4 bits of PORTC
	
	// Alarm is disarmed upon powering
	Disarm_Alarm();
	
    while (1) 
    {	
		// The disarmed state will fetch the user code from the user and arm the alarm if it is correct
		while(!armed)
		{
			for(code_counter = 0; code_counter <= code_max_length; code_counter++)
			{
				do 
				{
					key_press = Read_Press(); 				// Assigns contents of the key value 
				} while (!key_press);
				
				Hex_Convert(key_ptr);						// Converts the key value
				delay(50000);								// Delay
				
				if(key_press > 9) { break; }				// Checks for the following presses: '*#ABCD'
		
				temp_key[code_counter] = key_press;			// Assign to temporary code placeholder
				*PtB = key_press*16;
			}	
			
			if(key_press == 14 && code_counter > 3)			// Changes the code when the combination is at least 4 keys
			{ 
				Change_Code(temp_key);						// Changes code of the last user that disarmed the alarm		
				continue;	
			}	

			Check_Code(temp_key); 													// Check the temporary code with the real code
										
			if(!valid_code || (key_press > 9 && key_press < 14)) { Error_Code(); }	// Flash error LED
			else if (valid_code && key_press == 15) { Arm_Alarm(); }				// Arm alarm if code is valid
		}
		
		// The armed state will fetch the user code from the user and disarm the alarm if it is correct
		while(armed)
		{	
			for(code_counter = 0; code_counter <= code_max_length; code_counter++)
			{
				do
				{
					key_press = Read_Press(); 				// Assigns contents of the key value
				} while (!key_press);	
				
				Hex_Convert(key_ptr);						// Converts the key value
				delay(50000);								// Delay
				
				if(key_press == 15) { break; }				// Checks for '#'
					
				if(key_press == 10 || key_press == 11 || key_press == 12)			// Checks for zone key press
				{ 
					trigger = 1;
					break;
				}

				temp_key[code_counter] = key_press;			// Assign to temporary code placeholder
			}
			
			if(!trigger)
			{
				Check_Code(temp_key);						// Check the temporary code with the real code
					
				if(!valid_code)								// Flash error LED
				{ 
					error_counter++;						// Increase error counter
					Error_Code(); 
				}			
				else if (valid_code)						// Disarm Alarm if code is valid
				{ 
					Disarm_Alarm(); 
					error_counter = 0;						// Reset error counter
					
				}		
			}
			else if (trigger)								// If trigger is true set location bit
			{ 								
				if(key_press == 10) { zone_location = 0x02; }
				else if (key_press == 11) { zone_location = 0x08; }
				else if (key_press == 12) { zone_location = 0x20; }
				
				break;
			}	
			
			if(error_counter == 5)							// Check if code has been inputted incorrectly 5 times
			{ 
				trigger = 1; 
				error_counter = zone_location = 0;
				break;
			}
		}
		
		// The triggered state will fetch the user code and return to arm if it is correct
		while(trigger)
		{	
			for(code_counter = 0; code_counter <= code_max_length; code_counter++)
			{
				do 
				{
					key_press = Read_Press();				// Assigns contents of the key value
					Trigger_Alarm();
					key_press = Read_Press(); 				// Assigns contents of the key value
				} while(!key_press);
				
				Hex_Convert(key_ptr);						// Converts the key value		
				delay(50000);								// Delay
				
				if(key_press == 15) { break; }				// Checks for '#'
				
				temp_key[code_counter] = key_press;			// Assign to temporary code placeholder
			}					

				Check_Code(temp_key);						// Check the temporary code with the real code
				
				if(!valid_code) { Error_Code(); }			// Flash error LED
				else if (valid_code) { Arm_Alarm();	}		// Disarm Alarm if code is valid
		}			
    }
}

