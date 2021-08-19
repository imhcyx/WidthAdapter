OBJ_DIR := $(shell pwd)/obj_dir

VSRCS := adapter.v harness.v
CSRCS := sim.cpp

IW ?= 64
OW ?= 32

DUMPFILE := \"logs/dump-$(IW)-$(OW).vcd\"
OUTPUT_FILE := VHarness-$(IW)-$(OW)
SIM_BIN := $(OBJ_DIR)/$(OUTPUT_FILE)

VERILATOR_FLAGS := -cc --exe --trace -top Harness -o $(OUTPUT_FILE) -DIWIDTH=$(IW) -DOWIDTH=$(OW) -DDUMPFILE=$(DUMPFILE)

.PHONY: sim
sim: $(SIM_BIN)
	$(SIM_BIN)

.PHONY: sim_vcd
sim_vcd: $(SIM_BIN)
	$(SIM_BIN) +trace

$(SIM_BIN): $(VSRCS) $(CSRCS)
	verilator $(VERILATOR_FLAGS) $^
	make -j -C obj_dir -f VHarness.mk
