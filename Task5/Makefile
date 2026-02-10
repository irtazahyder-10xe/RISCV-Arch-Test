PREFIX := riscv64-unknown-elf
GCC := $(PREFIX)-gcc
CFLAGS := -march=rv32g -mabi=ilp32 -nostdlib -T link.ld
OBJDUMP := $(PREFIX)-objdump
SPIKEFLAGS := --isa=rv32i -l --log-commits +signature=signature.txt --signature-granularity=4

OUT := test.elf
DISASM := test.disass

.PHONY: run clean build
run: $(OUT)
	@spike $(SPIKEFLAGS) $(OUT) 1>spike.out 2>spike.log

debug: $(OUT)
	@spike --isa=rv32i -d $<
build: $(OUT)

disasm:
	$(OBJDUMP) -SDt $(OUT) > $(DISASM)

clean:
	@-rm $(OUT) $(DISASM) spike.out spike.log *.o signature.txt

lsp_init:
	@bear -- $(GCC) $(CFLAGS) $(wildcard asm/*.S) -o $(OUT)

$(OUT): $(wildcard asm/*.S)
	$(GCC) $(CFLAGS) $^ -o $(OUT)
