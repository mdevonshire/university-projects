/*
 *    Created by Matthew Devonshire 
 *    s3659780
 *    28/08/2020
 */ 

#include <avr/io.h>
void delay() //create a function that makes a 5 sec delay
{
	for (long j = 0 ; j < 80000000 ; j++) //80,000,000 cycles = 5sec??? (5*16MHz)
	{
	}
}
int main(void)
{
    // Create the table in memory
	unsigned char table[64] =	{	181, 127,  80,  43, 159, 252,  44,  66, 102,  19, 175, 103, 251,  68, 154,  12,
									 98,  42, 203, 223,  90,  83,  76, 136, 213, 153,  86,  77, 116, 108,  92, 143,
									190, 109, 110,  32,   7,  74,  81, 167, 245, 239, 117,  62, 195, 194, 189, 191,
									 28, 162, 119,  55,  26, 211,  45,  58, 170, 229, 132, 180,  40, 244, 138, 174 };							
	
	// Begin you code here.
	char temp;								//create char to be the temp value
	char lownumber = table[0];				//create char for the low number,                    set it as table[0] to begin
	char* lowpos = &table[0];				//create pointer for the position of the low number, set it as position of table[0] to begin
	char highnumber = table[0];				//create char for the high number,                   set it as table[0] to begin
	char* highpos = &table[0];				//create char for the position of the high number,   set it as position of table[0] to begin
	char temp2;								//create a variable to hold the swapped numbers
	
	for ( int i = 1; i < 64; i++ )	
	{
		temp = table[i];
		if ( temp < lownumber )
		{
			lownumber = table[i];
			lowpos = &table[i];
		}
		else if ( temp > highnumber)
		{
			highnumber = table[i];
			highpos = &table[i];
		}

	}
		
	for (char i = 0 ; i < 64 - 1; i++)
	{
		for (char j = 0 ; j < 64 - i - 1; j++)
		{
			if (table[j] > table[j+1])                // (For decreasing order use "<")
			{
				temp2 = table[j];
				table[j] = table[j+1];
				table[j+1] = temp2;
			}
		}
	}	
		
	// The first cycle of the inner for loop (the j for loop) will get the highest number to the last spot in the table.
	// The second cycle will get the second highest number to the second last position on the table, and so on.
	// After on full cycle of the outer for loop (the i for loop), all the numbers will be in their position (ascending order).
	
	
	while(1)
	{
					
	}
}

