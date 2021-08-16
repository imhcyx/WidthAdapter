#include <verilated.h>
#include "VHarness.h"

double sc_time_stamp() { return 0; }

int main(int argc, char** argv) {
    Verilated::mkdir("logs");
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    const std::unique_ptr<VHarness> top{new VHarness{contextp.get(), "TOP"}};

    top->rst = 1;
    top->clk = 0;

    while (!contextp->gotFinish()) {
        contextp->timeInc(5);
        top->clk = !top->clk;
        if (!top->clk) {
            if (contextp->time() < 50) {
                top->rst = 1;
            } else {
                top->rst = 0;
            }
        }
        top->eval();
    }

    top->final();

    return 0;
}
