#include <cstdint>
// Verilator generated files
#include "Vtensorcore.h"
// Verilator include files
#include <verilated.h>
// Stillwater include files
#include "testbench.hpp"

int main(int argc, char* argv[]) 
{
	Verilated::commandArgs(argc, argv);
	TestBench<Vtensorcore> tb;

	while(!tb.done()) {
		tb.tick();
	} exit(EXIT_SUCCESS);
}
