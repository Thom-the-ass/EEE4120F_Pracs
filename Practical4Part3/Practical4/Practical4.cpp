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
#define  MASTER	0



/*
    Useful Code be here
*/

/*
* This function takes in data from the csv generated from matlab to create a matrix
* don't know if I need this anymore
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

void vecToCsv(std::vector<double>&time, std::string& filename) {
    std::ofstream outFile(filename); // Open the output file

    if (!outFile.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;
    } 

    for (int i = 0; i < time.size(); ++i) {
        if (i != 0&& time[i] != 0)
        {
            outFile << ",";
        }

        if (time[i] != 0) {
            outFile << time[i]; // Write the index to the file
           
        }
    }

    outFile.close(); // Close the file
    std::cout << "Indexes written to " << filename << std::endl;
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
Run with:
mpiexec -n <number of proccessors> Practical4.exe <textfile to read from> <file to write to>

The directory of interest is:
cd \Users\tlgwo\Documents\UCT\4th Year\EEE4120F\Practical4Part3\Practical4\x64\Debug

mpiexec -n 4 Practical4.exe 10x10Matrix.csv 10x10Times.csv
*/
std::vector<std::vector<int>> matrix;
int main(int argc, char* argv[])
{
   
   
    /***** Initializations *****/
    
    int numtasks, taskid, rc, dest, offset, tag1, tag2, source, chunksize, leftover, arraySize;
    double time;
   

    MPI_Init(&argc, &argv);
    double startTime = MPI_Wtime();
    MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
    MPI_Comm_rank(MPI_COMM_WORLD, &taskid);
    MPI_Status status;

    tag2 = 1;
    tag1 = 2;

    /*Getting Data from the csvFile */
    std::string readFile = argv[1];
    std::string writeFile = argv[2];
   
    //trying to just send the data in main instead of this
    
    matrix = csvToVec(readFile);
    arraySize = matrix.size();
    chunksize = (arraySize / numtasks);
    leftover = (arraySize % numtasks);
    
    if (taskid == MASTER)
    {
        double ti = MPI_Wtime();
        std::vector<double> allTimes(arraySize);
        
        //sending the data to be sorted
        offset = 0;
        for (dest = 1; dest < numtasks; dest++) {
            //sending the offset
            MPI_Send(&offset, 1, MPI_INT, dest, tag1, MPI_COMM_WORLD);
           /*Havent got these working yet, I think for this to work will need to do a 1xX array - luss
            MPI_Send(&arraySize, 1, MPI_INT, dest, 2, MPI_COMM_WORLD);
            MPI_Send(&chunksize, 1, MPI_INT, dest, 3, MPI_COMM_WORLD);
            MPI_Send(&matrix[offset][0], chunksize, MPI_INT, dest, 4, MPI_COMM_WORLD);
            */
            offset+=chunksize;
        }
        //Master doing its section of the work, sorting its chunk and an additional leftover
        std::cout << "Master is busy doing work \n";
       
        for(int j = 0; j < chunksize+leftover; j++)
        {
            matrix[offset +j]= bubbleSortRow(matrix[offset + j]);
        }
        double tf = MPI_Wtime();
        allTimes[0] = (tf - ti) * 1000;
       
        //reciving the data 
        for (int i = 1; i < numtasks; i++) {
            source = i;
            MPI_Recv(&time, 1, MPI_DOUBLE, source, tag2, MPI_COMM_WORLD, &status);
            allTimes[i] = time;
        }
        allTimes[numtasks + 1] = (MPI_Wtime() - startTime) * 1000;
        //writingData to csv
        vecToCsv(allTimes, writeFile);
    }

    if (taskid > MASTER) {
        double ti = MPI_Wtime();
        MPI_Recv(&offset, 1, MPI_INT, MASTER, tag1, MPI_COMM_WORLD, &status);
        /*
        MPI_Recv(&arraySize, 1, MPI_INT, MASTER, 2, MPI_COMM_WORLD, &status);
        
        MPI_Recv(&chunksize, 1, MPI_INT, MASTER, 3, MPI_COMM_WORLD, &status);
        chunksize = (arraySize / numtasks);
        MPI_Recv(&matrix[offset][0], chunksize, MPI_INT, MASTER, 4, MPI_COMM_WORLD, &status);*/
        
        
        std::cout << "Worker Number " << taskid << " is trying its best... \n";
        
        for (int i = 0; i < chunksize; i++)
        {
            matrix[offset + i] = bubbleSortRow(matrix[offset+i]);
        }
        double time = (MPI_Wtime() - ti)*1000;
        MPI_Send(&time, 1, MPI_DOUBLE, MASTER, tag2, MPI_COMM_WORLD);

      

    } /* end of non-master */
    //
    MPI_Finalize();
    return 0;
}   /* end of main */

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
