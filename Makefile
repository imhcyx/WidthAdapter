OBJ_DIR := $(shell pwd)/obj_dir
SIM_BIN := $(OBJ_DIR)/VHarness

VSRCS := adapter.v harness.v
CSRCS := sim.cpp

VERILATOR_FLAGS := -cc --exe --trace -top Harness

.PHONY: sim
sim: $(SIM_BIN)
	$(SIM_BIN)

.PHONY: sim_vcd
sim_vcd: $(SIM_BIN)
	$(SIM_BIN) +trace

$(SIM_BIN): $(VSRCS) $(CSRCS)
	verilator $(VERILATOR_FLAGS) $^
	make -j -C obj_dir -f VHarness.mk
