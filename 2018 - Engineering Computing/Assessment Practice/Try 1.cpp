#include "stdafx.h"
#include <iostream>
#include <cstdlib>
#include <time.h>
#include <math.h>
#include <errno.h>   

using namespace std;

const double MAXRANGE = pow(2.0, 16.0); // 65536
const double MINRANGE = -pow(2.0, 16.0);

char nocomma[20];

bool check = 0;
int CheckSize(int Input)
{
	int proc_input;
	proc_input = abs(Input);
	if (proc_input >= 255)
		return 255;
	else
		return proc_input;
}

unsigned int ReadPinC()
{
	int pinc = 0;
	char line[255] = {};	// array to hold received data from the OUSB board
	FILE *fpipe;			// file variable, see text book module 11.
	char command[255] = { "ousb -r io PINC" };

	// pipe code that sends out the current Command stored in the command variable
	fpipe = (FILE*)_popen(command, "r");
	if (fpipe != NULL)
	{
		while (fgets(line, sizeof(line), fpipe))
		{
			if (line[0] == 'F')
			{
				check = true;
				return 0;
			}
			// do nothing, or print out debug data
			// cout << "Read PinC Debug line: " << line; // print out OUSB data
		}
		_pclose(fpipe);
	}
	

	// convert value from char array to int	
	pinc = (unsigned int)atoi(line);
	// Mask pinc value for bottom 8-bit only.
	// pinc = pinc & 0x00FF;
	return pinc;
}

unsigned int WritePortB(unsigned int val)
{
	char line[255] = {};	// array to hold received data from the OUSB board
	FILE *fpipe;			// file variable, see text book module 11.
	char command[255] = { "ousb -r io PORTB " }; // Need to have a extra space after PORTB
	char val_string[4] = {};

	//Convert integer (in base 10) to character
	_itoa_s(val, val_string, 10);
	// append the value to the Command string
	strcat_s(command, val_string);

	// pipe code that sends out the current Command stored in the command variable
	fpipe = (FILE*)_popen(command, "r");
	if (fpipe != NULL)
	{
		while (fgets(line, sizeof(line), fpipe))
		{
			// do nothing, or print out debug data
			// cout << "Debug line: " << line; // print out OUSB data
		}
		_pclose(fpipe);
	}
	

	// convert value from char array to int	
	unsigned int portb = (unsigned int)atoi(line);
	return portb;
}

// WRITE ANY USER DEFINED FUNCTIONS HERE 

int main(int argc, char *argv[])
{
	int portb;
	if (argc == 1)
	{
		// When run with just the program name (no parameters) your code  MUST print 
		// student ID string in CSV format. i.e.
		// "studentNumber,student_email,student_name"
		// eg: "2345678,s2345678@student.rmit.edu.au,EEET2246_Student"

		// No parameters on command line just the program name
		// Edit string below: eg: "studentNumber,student_email,student_name"

		cout << "3659780,s3659780@student.rmit.edu.au,Matthew_Devonshire" << endl;

		// The convention is to return Zero to signal NO ERRORS (please do not change it).
		return 0;
	}	
	int e_count = 0;
	int dot_count = 0;
	int nocomma_count = 0;
	for (int i = 0; argv[1][i] != '\0'; i++)
	{
		if (!isdigit(argv[1][i]))
		{
			if (argv[1][i] == ',') {}
			else if ((i == 0 && (argv[1][i] == '+' || argv[1][i] == '-')) || ((argv[1][i] == '+' || argv[1][i] == '-') && (argv[1][i - 1] == 'e' || argv[1][i - 1] == 'E'))) {}
			else if (argv[1][i] == 'e' || argv[1][i] == 'E')
			{
				e_count++;
				if (e_count > 1)
				{
					cout << "X\n";
					return 0;
				}
				else
				{
					if (argv[1][i + 1] == '\0')
					{
						cout << "X\n";
						return 0;
					}
				}
			}
			else if (argv[1][i] == '.')
			{
				dot_count++;
				if (dot_count > 1 || argv[1][i + 1] == 'e' || argv[1][i + 1] == 'E')
				{
					cout << "X\n";
					return 0;
				}
			}
			else
			{
				cout << "X\n";
				return 0;
			}
		}
		if (argv[1][i] == ',') {}
		else
		{
			nocomma[nocomma_count] = argv[1][i];
			nocomma_count++;
		}
	}
	if (atof(nocomma) < MINRANGE || atof(nocomma) > MAXRANGE)
	{
		cout << "R\n";
		return 0;
	}
	double pinc = 0;

	if (argc == 2)
	{
		pinc = ReadPinC();
		//if check;
		cout << ReadPinC() + atof(nocomma) << endl;
		portb = CheckSize(ReadPinC() + atof(nocomma));
		WritePortB(portb);
		return 0;
	}

	else if (argc == 3)
	{
		if (argv[2][1] == '\0')
		{
			if (argv[2][0] == 'a')
			{
				cout << ReadPinC() + atof(nocomma) << endl;
				portb = CheckSize(ReadPinC() + atof(nocomma));
				//cout << portb;
				WritePortB(portb);
				return 0;
			}
			else if (argv[2][0] == 's')
			{
				cout << ReadPinC() - atof(nocomma) << endl;
				portb = CheckSize(ReadPinC() - atof(nocomma));
				WritePortB(portb);
				return 0;
			}
			else if (argv[2][0] == 'm')
			{
				cout << ReadPinC() * atof(nocomma) << endl;
				portb = CheckSize(ReadPinC() * atof(nocomma));
				WritePortB(portb);
				return 0;
			}
			else if (argv[2][0] == 'd')
			{
				if (atof(nocomma) != 0)
				{
					cout << ReadPinC() / atof(nocomma) << endl;
					portb = CheckSize(ReadPinC() / atof(nocomma));
					WritePortB(portb);
					return 0;
				}
				else
				{
					cout << "M\n";
					return 0;
				}
			}
			else if (argv[2][0] == 'p')
			{
				cout << pow(ReadPinC(), atof(nocomma)) << endl;
				WritePortB(abs(pow(ReadPinC(), atof(nocomma))));
				return 0;
			}
			else
			{
				cout << "V\n";
				return 0;
			}
		}
		else
		{
			cout << "V\n";
			return 0;
		}
	}
	else
	{
		cout << "P\n";
		return 0;
	}
}
	//--- START YOUR CODE HERE.
