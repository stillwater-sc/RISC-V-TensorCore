#pragma once
#include <iostream>
#include <iomanip>
#include <cstdint>
#include "tracer.hpp"

#define	TBASSERT(TB,A) do { if (!(A)) { (TB).closetrace(); } assert(A); } while(0);

template <typename Module>
class TestBench {
public:
	TestBench() : nrTicks{0ull} 
	{
		Verilated::traceEverOn(true);
		module.clk = 0;
		module.tensorcore->i_tc_sram->sram[0][0] = 0;
		eval(); // initialize initial values properly
	}

	virtual	void opentrace(const std::string& vcdname) {
		bTracing = tracer.open(vcdname);
	}

  virtual	void fill_sram(IData* input, size_t entries) {
    memcpy ( module.tensorcore->i_tc_sram->sram, input, sizeof(IData)*entries);
  }

  virtual	void memset_sram(int value, size_t size) {
    memset ( module.tensorcore->i_tc_sram->sram,value,size);
  }

	virtual	void eval(void) {
		module.eval();
	}

	virtual	void tick(void) {
		++nrTicks;

		// Make sure we have our evaluations straight before the top
		// of the clock.  This is necessary since some of the 
		// connection modules may have made changes, for which some
		// logic depends.  This forces that logic to be recalculated
		// before the top of the clock.
		eval();
		if (bTracing) tracer.dump(10*nrTicks-2);
		module.clk = 1;
		eval();
		if (bTracing) tracer.dump(10*nrTicks);
		module.clk = 0;
		eval();
		if (bTracing) {
			tracer.dump(0*nrTicks+5);
			tracer.flush();
		}
	}

	virtual	void reset(void) {
		module.reset = 1;
		tick();
		module.reset = 0;
	}

	virtual bool done() { return Verilated::gotFinish(); }

	inline uint64_t ticks() { return nrTicks; }

private:
	Module		module;
	Tracer		tracer;
	bool            bTracing;
	uint64_t	nrTicks;

};
