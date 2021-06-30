// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VOUR_H_
#define VERILATED_VOUR_H_  // guard

#include "verilated_heavy.h"

//==========

class Vour__Syms;

//----------

VL_MODULE(Vour) {
  public:

    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vour__Syms* __VlSymsp;  // Symbol table

    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vour);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vour(VerilatedContext* contextp, const char* name = "TOP");
    Vour(const char* name = "TOP")
      : Vour(nullptr, name) {}
    /// Destroy the model; called (often implicitly) by application code
    ~Vour();

    // API METHODS
    /// Return current simulation context for this model.
    /// Used to get to e.g. simulation time via contextp()->time()
    VerilatedContext* contextp();
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();

    // INTERNAL METHODS
    static void _eval_initial_loop(Vour__Syms* __restrict vlSymsp);
    void __Vconfigure(Vour__Syms* symsp, bool first);
  private:
    static QData _change_request(Vour__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vour__Syms* __restrict vlSymsp);
    static void _ctor_var_reset(Vour* self) VL_ATTR_COLD;
  public:
    static void _eval(Vour__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vour__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vour__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _initial__TOP__1(Vour__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
