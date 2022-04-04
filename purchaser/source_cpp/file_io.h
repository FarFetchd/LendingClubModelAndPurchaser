#ifndef STRIDER_IB_FILE_IO_H_
#define STRIDER_IB_FILE_IO_H_

#include <string>

// Will not add a newline at the end
void appendStringFile(std::string path, std::string text);

double readDoubleFile(std::string path);

int readIntFile(std::string path);

// trims any trailing newlines (does include other trailing whitespace).
std::string readStringFile(std::string path);

void writeDoubleFile(double val, std::string path);

#endif // STRIDER_IB_FILE_IO_H_
