#include <cstdlib>
#include <vector>
#include <Rcpp.h>

// [[Rcpp::export]]
Rcpp::NumericVector testcppstring(std::vector<std::string> input)
{
    Rcpp::NumericVector score(input.size());

    for(int i=0;i<input.size();i++)
    {
       score[i] = input[i].length();
    }
    return score;
}
