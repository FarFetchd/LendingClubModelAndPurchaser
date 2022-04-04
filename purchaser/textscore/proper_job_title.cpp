#include <iostream>
using std::cerr;
using std::endl;

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
	return (c>='0'&&c<='9') || (isupper(c)!=0);
}
bool isLowerOrNumber(char c)
{
	return (c>='0'&&c<='9') || (islower(c)!=0);
}

//TODO: do not require caps on: of, to, the, and

//NOTE: the very last place of employment, before job title switch:
//"699673",2013-10-15,"CVS Caremark"

//Bad if all lower case
//Bad if all upper case
//Each word should be capitalized
//a single word that is entirely caps is considered ok AND not misspelled, UNLESS it's the only word
//===some exceptions for single acronym jobs: RN, MD, EMT, HR, VP, CEO, CFO, CTO, CPA
//===for pre-september 2013 items, it's place of employment. accept UPS, ATT, AT&T, CVS, IHOP, NYPD, LAPD, IBM, GE
//                                                           UPDATE Jan2017: USPS, IRS, USAF, USMC
//in the exceptions list but only first letter capitalized: bad
//
//single word not in the acceptable acronyms list and not a real word: bad
//
//following hyphen, caps optional
//any double space: bad
//leading space: bad
//trailing space: ok, might be the interface, there are many
double properJobTitle(std::string input, MySpell* theSpeller)
{
	bool foundAnyLower = false;
	bool mustBeAcronym = false;
	bool foundEndOfFirstWord = false;
	bool foundStartOfSecondWord = false;

	//trailing space is ok
	if(input.find_last_not_of(" ") != input.length() - 1)
		input = input.substr(0, input.find_last_not_of(" ")+1);
	//uncapitalized 'of, to, the, and' are ok
	if(input.find(" of") != string::npos)
		input.replace(input.find(" of"), 3, string(" Of"));
	if(input.find(" to") != string::npos)
		input.replace(input.find(" to"), 3, string(" To"));
	if(input.find(" the") != string::npos)
		input.replace(input.find(" the"), 4, string(" The"));
	if(input.find(" and") != string::npos)
		input.replace(input.find(" and"), 4, string(" And"));

	if(input.find("  ") != string::npos) //Bad because double space.
		return 0.0;

	const char* cur = input.c_str();
	//NOTE is-1st-char-lower covers are-all-lower
	if(isspace(*cur) || islower(*cur)) //Bad starts with a space or lower.
		return 0.0;

	bool wantCap = true;
	while(*cur)
	{
		if(*cur=='.'||*cur=='?'||*cur=='!'||*cur=='('||*cur==')'||*cur=='&'||*cur=='/')
		{
			wantCap = true;
			cur = skipWhitespace(cur+1);
		}
		else if(*cur=='-')//next can be either lower or cap
		{
			cur++;
			if(isspace(*cur)) //Bad because space after hyphen.
				return 0.0;
			cur++;
			wantCap=false;
		}
		else if(isspace(*cur))
		{
			cur++;
			mustBeAcronym = false;
			foundEndOfFirstWord = true;
			wantCap = true;
		}
		else
		{
			if(foundEndOfFirstWord)
				foundStartOfSecondWord = true;

			if((wantCap || mustBeAcronym) && !isCapitalOrNumber(*cur))
			{
				//cerr << "Bad because " << (wantCap?"wantCap":"") << (mustBeAcronym?"mustBeAcronym":"")
				//	<<", and this character " << *cur << " is not cap or number." << endl;
				return 0.0;
			}
			else if(!wantCap && !isLowerOrNumber(*cur))
			{
				mustBeAcronym = true;
				cur++;
			}
			else
			{
				if(wantCap)
					wantCap = false;
				if(islower(*cur))
					foundAnyLower = true;
				cur++;
			}
		}
	}

	//a single word that is entirely caps is considered ok AND not misspelled, UNLESS it's the only word,
	//in which case it must be in a list of exceptions
	if(!foundAnyLower)
	{
		if(foundStartOfSecondWord)
			return 0.0;

		//===some exceptions for single acronym jobs: RN, MD, EMT, HR, VP, CEO, CFO, CTO, CPA
		if(input!="RN" && input!=("MD") && input!=("EMT") &&
			input!=("HR") && input!=("VP") && input!=("CEO") &&
			input!=("CFO") && input!=("CTO") && input!=("CPA") && input!=("HVAC") &&
			//===for pre-september 2013 items, it's place of employment. accept UPS, ATT, AT&T, CVS, IHOP, NYPD, LAPD, IBM, GE
			input!=("UPS") && input!=("ATT") && input!=("AT&T") &&
			input!=("CVS") && input!=("IHOP") && input!=("NYPD") &&
			input!=("LAPD") &&  input!=("IBM") && input!=("GE") &&
			// USPS, IRS, USAF, USMC
			input!=("USPS") &&  input!=("IRS") && input!=("USAF") && input!=("USMC") )
		{
			//cerr << "Bad because a single all cap word, not in the exceptions list." << endl;
			return 0.0;
		}
	}

	//spellcheck NON-acronym words: any wrong, bad.
	//NON-acronym: copy string, overwrite acronyms with space. Also overwrite
	//HACK
	if(input.length() > 250)
		return 0.0;
	char* noAcronyms = new char[256];
	memset(noAcronyms, 0, 256);
	//char* noAcronyms = new char[input.length()+1]; noAcronyms[input.length()]=0;
	strcpy(noAcronyms, input.c_str());
	int curInd = input.length() - 1;
	bool nowBlanking = false;
	while(curInd > 0)
	{
		if(nowBlanking)
		{
			if(isspace(noAcronyms[curInd]))
				nowBlanking = false;
			noAcronyms[curInd] = ' ';
			curInd--;
		}
		else if(isupper(noAcronyms[curInd]) &&
		        !(isspace(noAcronyms[curInd-1]) || noAcronyms[curInd-1]=='.' || noAcronyms[curInd-1]=='/' ||
		          noAcronyms[curInd-1]=='(' || noAcronyms[curInd-1]=='&' || noAcronyms[curInd-1]=='-'))
		{
			nowBlanking = true;
			noAcronyms[curInd] = ' ';
			curInd--;
		}
		else
		{
			if(noAcronyms[curInd]=='.' || noAcronyms[curInd]==')' || noAcronyms[curInd]=='/' ||
		          noAcronyms[curInd]=='(' || noAcronyms[curInd]=='&' || noAcronyms[curInd]=='-')
			{
				noAcronyms[curInd] = ' ';
			}
			curInd--;
		}
	}
	if(nowBlanking)
		noAcronyms[0] = ' ';

	char* curStart = noAcronyms;
	char* curEnd = noAcronyms;
	while(*curStart)
	{
		curEnd = curStart;
		while(*curEnd && *curEnd != ' ')
			curEnd++;
		*curEnd = 0;
		curEnd++;
		if(theSpeller->spell(curStart) == 0)
		{
			//cerr << "Bad because " << std::string(curStart) << " was misspelled" << endl;
			delete noAcronyms;
			return 0.0;
		}
		curStart = curEnd;
		if(!*curStart)
			break;
	}

	delete noAcronyms;

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
Rcpp::NumericVector properjobtitle(std::vector<std::string> input)
{
	MySpell* theSpeller = new MySpell("purchaser/textscore/MySpell-3.0/en_US.aff",
	                                  "purchaser/textscore/MySpell-3.0/en_US.dic");


	Rcpp::NumericVector score(input.size());
	for(int i=0; i<input.size(); i++)
		score[i] = properJobTitle(input[i], theSpeller);
	delete theSpeller;
	return score;
}
