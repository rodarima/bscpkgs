#include <mpi.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>

void sigsegv(int rank)
{
        if (rank == 2) raise(SIGSEGV);
}

int main(int argc, char *argv[])
{
        int rank;
        char where;

        MPI_Init(&argc, &argv);

        if(!argv[1])
        {
                fprintf(stderr, "missing \"before\" or \"after\" argument\n");
                exit(1);
        }

        MPI_Comm_rank(MPI_COMM_WORLD, &rank);

        where = argv[1][0];

        if(where == 'b') sigsegv(rank);

        MPI_Finalize();

        if(where == 'a') sigsegv(rank);

        return 0;
}
