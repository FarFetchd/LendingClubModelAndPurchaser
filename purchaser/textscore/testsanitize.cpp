#include <iostream>
#include <string>
using namespace std;

std::string sanitize(std::string input)
{
        //remove all Borrower added on 03/10/14
        //(26 chars long)
        size_t borrowerAdded = string::npos;
        while((borrowerAdded = input.find("Borrower added on ")) != string::npos)
        {
                input = input.replace(borrowerAdded, 26, 26, ' ');
        }
        size_t brbr = string::npos;
        while((brbr = input.find("<br>")) != string::npos)
        {
                input = input.replace(brbr, 4, 4, ' ');
        }
        brbr = string::npos;
        while((brbr = input.find("<")) != string::npos)
        {
                input = input.replace(brbr, 1, 1, ' ');
        }
        brbr = string::npos;
        while((brbr = input.find(">")) != string::npos)
        {
                input = input.replace(brbr, 1, 1, ' ');
        }
	return input;
}

int main(int argc, char** argv)
{
	cout << sanitize(string(argv[1])) << endl;
}
