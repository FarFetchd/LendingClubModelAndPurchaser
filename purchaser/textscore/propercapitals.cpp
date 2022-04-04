#include <cstdlib>
#include <string>
using std::string;
#include <vector>
#include <Rcpp.h>


const char* skipWhitespace(const char* input)
{
	while(*input && isspace(*input))
		input++;
	return input;
}

bool isCapitalOrNumber(char c)
{
	return (c>='0'&&c<='9') || isupper(c)!=0;
}
bool isLowerOrNumber(char c)
{
	return (c>='0'&&c<='9') || islower(c)!=0;
}

double properCapitals(std::string input)
{
	const char* cur = input.c_str();
	cur = skipWhitespace(cur);
	bool wantCap = true;
	while(*cur)
	{
		if(*cur=='.'||*cur=='?'||*cur=='!')
		{
			wantCap = true;
			cur = skipWhitespace(cur+1);
			continue;
		}
		else if(isspace(*cur))
			cur = skipWhitespace(cur);
		else if(wantCap && !isCapitalOrNumber(*cur))
			return 0.0;
		else if(!wantCap && !isLowerOrNumber(*cur))
			return 0.0;
		else
		{
			if(wantCap)
				wantCap=false;
			cur++;
		}
	}
	return 1.0;

}

string sanitize(string input)
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

// [[Rcpp::export]]
Rcpp::NumericVector propercapitals(std::vector<std::string> input)
{
	Rcpp::NumericVector score(input.size());

	for(int i=0;i<input.size();i++)
		score[i] = properCapitals(input[i]);
	return score;
}
