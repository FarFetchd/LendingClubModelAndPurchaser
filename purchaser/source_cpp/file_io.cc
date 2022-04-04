#include <string>
#include <fstream>
#include <streambuf>
#include <cstdio>

void appendStringFile(std::string path, std::string text)
{
  FILE* f = fopen(path.c_str(), "at");
  fwrite(text.c_str(),1,text.length(),f);
  fclose(f);
}

double readDoubleFile(std::string path)
{
  std::ifstream t(path);
  std::string str((std::istreambuf_iterator<char>(t)),
                  std::istreambuf_iterator<char>());
  return std::stod(str);
}

int readIntFile(std::string path)
{
  std::ifstream t(path);
  std::string str((std::istreambuf_iterator<char>(t)),
                  std::istreambuf_iterator<char>());
  return std::stoi(str);
}

// trims any trailing newlines (does include other trailing whitespace).
std::string readStringFile(std::string path)
{
  std::ifstream t(path);
  std::string s((std::istreambuf_iterator<char>(t)),
                     std::istreambuf_iterator<char>());
  while (!s.empty() && s.back() == '\n')
    s.pop_back();
  return s;
}

void writeDoubleFile(double val, std::string path)
{
  FILE* f = fopen(path.c_str(), "wt");
  fprintf(f, "%f", val);
  fclose(f);
}
