#include <cstdint>
// Verilator generated files
#include "Vtensorcore.h"
#include "Vtensorcore_tensorcore.h"
#include "Vtensorcore_tc_sram__pi1.h"
// Verilator include files
#include <verilated.h>
// Stillwater include files
#include "testbench.hpp"

int main(int argc, char* argv[]) 
{
	Verilated::commandArgs(argc, argv);
	TestBench<Vtensorcore> tb;

	tb.memset_sram(0, 256*4);

	while(!tb.done()) {
		tb.tick();
	} exit(EXIT_SUCCESS);
}
