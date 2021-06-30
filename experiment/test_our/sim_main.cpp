#include "Vour.h"
#include "verilated.h"
int main(int argc, char** argv, char** env) {
	VerilatedContext* contextp= new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vour* top = new Vour{contextp};
	while (!contextp->gotFinish()) {
		top->eval();
	}
	delete top;
	delete contextp;
	return EXIT_SUCCESS;
}
