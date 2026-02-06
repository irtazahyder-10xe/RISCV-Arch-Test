PREFIX := riscv64-unknown-elf
GCC := $(PREFIX)-gcc
CFLAGS := -march=rv32g -mabi=ilp32 -nostdlib -T asm/link.ld
OBJDUMP := $(PREFIX)-objdump
SPIKEFLAGS = --isa=rv32i -l --log-commits +signature=$(SIGNATURE_FILE) +signature-granularity=4

OUT := test.elf
DISASM := test.disass
SIGNATURE_FILE := signature.txt

.PHONY: run clean build
run: $(OUT)
	spike $(SPIKEFLAGS) $(OUT) 1>spike.out 2>spike.log

build: $(wildcard asm/*.S)
	$(GCC) $(CFLAGS) $^ -o $(OUT)

disasm:
	$(OBJDUMP) -SDt $(OUT) > $(DISASM)

clean:
	@-rm $(OUT) $(DISASM) spike.out spike.log *.o $(SIGNATURE_FILE)

$(OUT): build
