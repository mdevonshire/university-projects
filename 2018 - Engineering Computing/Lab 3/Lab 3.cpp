// Lab 3.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <cstdlib>
#include <time.h>
#include <math.h>
#include <errno.h>   

using namespace std;

int readadc_writeportb()
{
	char line[255] = {};
	FILE *fpipe;			
	char command[255] = { "ousb -r adc 5" };
	int adcvalue;
	int portb = 0;
	char div_four_val[10]{};

	fpipe = (FILE*)_popen(command, "r");
	if (fpipe != NULL)
	{
		while (fgets(line, sizeof(line), fpipe))
		{
			// cout << "Value read from ADC" << line << endl;
			adcvalue = atoi(line);

		}
		_pclose(fpipe);
	}
	strcpy_s(command, "ousb -r io portb ");
	portb = adcvalue >> 2;
	_itoa_s(portb, div_four_val, 10);
	strcat_s(command, div_four_val);

	fpipe = (FILE*)_popen(command, "r");
	if (fpipe != NULL)
	{
		while (fgets(line, sizeof(line), fpipe))
		{
			cout << "Value written to board: " << line << endl;
		}
		_pclose(fpipe);
	}
	return portb;
}
int main(int argc, char *argv[])
{
	//cout << "Task 1\n";
	//char line[255] = {};	// array to hold received data from the OUSB board
	//FILE *fpipe;			// file variable, see text book module 11.
	//char command[255] = { "ousb -r adc 5" };
	//int adcvalue;

	//fpipe = (FILE*)_popen(command, "r");
	//if (fpipe != NULL)
	//{
	//	while (fgets(line, sizeof(line), fpipe))
	//	{
	//		cout << line << endl;
	//		adcvalue = atoi(line);

	//	}
	//	_pclose(fpipe);
	//}
	//cout << "Min: 0 \nMax: 1023\n";

	//cout << "Task 2\n";
	//strcpy_s(command, "ousb -r io portb ");
	//cout << "5V / 1024 = 4.88mV\n";
	//int portb = 0;
	//char div_four_val[10]{};
	//portb = adcvalue >> 2;
	//_itoa_s(portb, div_four_val, 10);
	//strcat_s(command,div_four_val);
	//
	//fpipe = (FILE*)_popen(command, "r");
	//if (fpipe != NULL)
	//{
	//	while (fgets(line, sizeof(line), fpipe))
	//	{
	//		cout << "Debug Line" << line << endl;
	//	}
	//	_pclose(fpipe);
	//}

	cout << "Task 3\n";
	int stopnumber = 10;
	int x= 255;
	while (x > stopnumber)
	{
		x = readadc_writeportb();
		cout << x << endl;
	}
	
	cout << "Task 4\n";
	int valuelist[10] = { 23,53,654,456,3,4,65,64,56,334 };
	int highest_number = 0;
	int highest_index;
	for (int n = 0;n < 10;n++)
	{
		if (highest_number < valuelist[n])
		{
			highest_number = valuelist[n];
			highest_index = n;
		}
		else {}
	}
	cout << "Highest Number is: " << highest_number << endl;
	cout << "Index is: " << highest_index << endl;

	cout << "Task 5\n";
	const char validCharacters[] = ",.-+eE0123456789";
	bool validchar = false;
	for (int i = 0; argv[1][i] != '\0'; i++)
	{
		validchar = false;
		for (int j = 0;validCharacters[j] != '\0'; j++)
		{
			if (argv[1][i] == validCharacters[j])
			{
				validchar = true;
			}
		}
		if (validchar != true)
		{
			cout << "X\n";
			return 0;
		}
	}
	cout << "Valid Input\n";
	cout << argv[1] << endl;

	cout << "Task 6\n";
	char mysentence[] = "Bongocat goes to school";
	char * endarray = mysentence + strlen(mysentence);
	for (int i = 1; i <= strlen(mysentence); i++)
	{
		cout << (char)*(endarray - i);
	}
	cout << endl;
    return 0;
}

