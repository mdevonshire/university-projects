// errorcheck.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
using namespace std;

char nocomma[20];

int main(int argc, char *argv[])
{
	cout << atof("2e") << endl;
	if (argc == 1)
	{
		cout << "student info\n";
		return 0;

	}
	else if (argc == 2)
	{
		int ecount = 0;
		int i = 0;
		for (i = 0; argv[1][i] != '\0'; i++)
		{
			if (!isdigit(argv[1][i]))
			{
				if (argv[1][i] == 'e' || argv[1][i] == 'E')
				{
					ecount++;
					if (ecount > 1 || argv[1][i + 1] == '\0' || i == 0)
					{
						cout << "X\n";
						return 0;
					}
				}
				else if (((argv[1][i] == '-' || argv[1][i] == '+') && i == 0) || ((argv[1][i] == '-' || argv[1][i] == '+') && (argv[1][i - 1] == 'e' || argv[1][i - 1] == 'E'))) {}
				else
				{
					cout << "V\n";
					return 0;
				}
			}
		}
		cout << 7 + atof(argv[1]) << endl;
		return 0;

	}
	else
	{
		cout << "P\n";
		return 0;
	}
    return 0;
}

