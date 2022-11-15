/**
 * s3659780_SectionA_g
 *
 * Made by: Matthew Devonshire
 * 14/09/2020
 */


#include <avr/io.h>
int main (void)
{
	/* Insert system clock initialization code here (sysclk_init()). */
	//^^ code seems to work without this
	

	//Initialise the system
	DDRB = 0xFF;
	DDRC = 0x00;
	PORTC = 0xFF;
	
	char temp = 0x00;		//Initialise variable "temp"
	while (1)
	{
		temp = PINC;		//read PINC to temp
		PORTB = temp;		//write temp to PORTB
	}
	
}
