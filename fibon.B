	LDI 05
	STA count
	LDI 01
	STA step
	LDI 00
	STA first
	LDI 01
	STA secnd
LOOP	LDA count
	SUB step
	STA count
	BRZ QUIT
	LDA first
	ADD secnd
	STA temp
	LDA secnd
	STA first
	LDA temp
	STA secnd
	GTO LOOP
;
first	NOP
secnd	NOP
count	NOP
step	NOP
temp	NOP
;
QUIT	LDA first
	PRT
	HLT