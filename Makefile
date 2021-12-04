ASMX := asmx

.PHONY: all
all: BIOS.idiot

BIOS.idiot: *.asm
	@rm -f BIOS.hex
	$(ASMX) -e -w -l BIOS.lst -i -o BIOS.idiot main.asm || (rm BIOS.idiot; false)

BIOS.hex:   *.asm
	@rm -f BIOS.idiot
	$(ASMX) -e -w -l BIOS.lst    -o BIOS.hex   main.asm || (rm BIOS.hex; false)

.PHONY: clean
clean:
	rm -f *.lst *.idiot *.hex

.PHONY: install
install:BIOS.idiot
	screen -X slowpaste 5
	screen -X readreg p "`pwd`/BIOS.idiot"
	screen -X paste p
