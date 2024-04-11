// Practical4.cpp : This file contains the 'main' function. Program execution begins and ends there.
//  Step to configure : 
// * set up the include directies
// * set up the linker directories
// * set up the input (msmpi.lib) 
// 
// How to run
// * open developers command prompt
// find the exe file created should be in  C:\Users\tlgwo\Documents\UCT\4th Year\EEE4120F\Practical4Part3\Practical4\x64\Debug\
// run with mpiexed -n x Practical4.exe
// 
// Things to do 
//  *need to make this run from command line with the parameters of main being the input the input text file and output text file
//

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string.h>
#include <assert.h>
#include "mpi.h"


#include <stdio.h>
#include <stdlib.h>
#define  ARRAYSIZE	20000
#define  MASTER		0



/*
    Useful Code be here
*/

/*
* This function takes in data from the csv generated from matlab to create a matrix
*/
std::vector<std::vector<int>> csvToVec(std::string filename) {
    std::ifstream file(filename);

    // Read the first line to determine the size of the matrix
    std::string firstLine;
    std::getline(file, firstLine);
    std::stringstream firstLineStream(firstLine);
    int n = 0;
    std::string temp;
    while (std::getline(firstLineStream, temp, ',')) {
        n++;
    }
    
    // Reset the file stream to the beginning of the file
    file.clear();
    file.seekg(0, std::ios::beg);

    // Initialize the matrix with the determined size
    std::vector<std::vector<int>> matrix(n, std::vector<int>(n));

    for (int row = 0; row < n; row++) {
        std::string line;
        std::getline(file, line);
        if (!file.good())
            break;

        std::stringstream iss(line);

        for (int col = 0; col < n; col++) {
            std::string val;
            std::getline(iss, val, ',');
            if (col == n)
            {
                std::getline(iss, val, '*');
            }
            if (!iss.good() || val.empty())
                break;

            std::stringstream convertor(val);
            convertor >> matrix[row][col];
        }
    }

    return matrix;
}


/*
Sorts a single row of the two by two matrix
*/
std::vector<int> bubbleSortRow(std::vector<int>& arr) {
    int n = arr.size();
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // Swap adjacent elements
                std::swap(arr[j], arr[j + 1]);
            }
        }
    }
    return arr;
}

/*
Test code be here
*/

int main()
{
    //Getting all the data I need from the console
    std::string readFileName;
    std::string writeFileName;
    std::cout << "Welcome to the thunderdome \n";
    std::cout << "Please Give me a file to read data from: \n";
    std::cin >> readFileName;
    std::cout << "Please Give me a file name to write to: \n";
    std::cin >> writeFileName;
    std::cout << "Let the games begin";
    return 0;


}

/*
    std::vector<std::vector<int>> matrix = csvToVec("10x10Matrix.csv");
    std::vector<int> sortedArray = bubbleSortRow(matrix[0]);


    for (int index : sortedArray)
    {
        std::cout << index << "\n";
    }

*/

/*
    // Print the matrix
    for (int i = 0; i < matrix.size(); i++) {
        for (int j = 0; j < matrix[i].size(); j++) {
            std::cout << matrix[i][j] << " ";
        }
        std::cout << "\n";
    }

    return 0;
*/

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
