;  Lion System Rom
;  v1.2
;  (C) 2015 Theodoulos Liontakis

	  	ORG 		0    ; Rom 
INT0_3      DA		HINT   ; hardware interrupts
		DA          INTEXIT
		DA		INTEXIT
		DA		INTEXIT  
INT4        DA        	INTR4     ; interrupt vector 4 system calls
INT5 		DA		INTR5	    ; fixed point routines
INT6_14     DW          0,0,0,0,0,0,0,0,0
INT15		DA		INTR15   ; trace interrupt

		MOV		A1,49148
		SETSP		A1
		SETX		1983       ; Set default color 
		MOV		A1,61152 ; was 65144
COLINIT:	MOV.B		(A1),57
		INC		A1
		JMPX		COLINIT
		SETX		32767    ;  memory test
		MOV		A1,START
MEMTST:     MOV.B		A2,(A1)
		MOV.B		(A1),$FF
		MOV.B		A0,(A1)
		CMP.B		A0,$FF
		MOV.B		(A1),A2
		JZ		memok
		PUSH		A1
		MOVI		A0,5
		MOV		A1,MEMNOTOK
		MOVI		A2,4
		INT		4
		POP		A1
		JMP		memnok
memok:	INC		A1
		JMPX		MEMTST
memnok:	SETX		1000
sdretr:	MOVI		A0,11        ; sd card init
		INT		4
		CMP		A0,256
		JNZ		NOSD
		MOVI		A0,5
		MOV		A1,SDOK
		MOVI		A2,5
		INT		4
		MOVI		A0,13
		MOVI		A1,0
		MOV		A2,SDCBUF1
		INT		4
            CMP		A0,256
		JNZ		S_EXIT
		MOV		(SDFLAG),256
		MOVI		A0,5
		MOV		A1,SDBOK
		MOVI		A2,6
		INT		4	
		JMP		S_EXIT
NOSD:		JMPX		sdretr
		MOVI		A0,5
		MOV		A1,SDNOTOK
		MOVI		A2,5
		INT		4
S_EXIT:	STI	
		JMP		START  ; address at RAM


SDOK		TEXT		"SD Card OK"
		DB	0
SDBOK		TEXT		"Block 0 Loaded"
		DB	0
SDNOTOK	TEXT		"SD Card failed"
		DB	0
MEMNOTOK	TEXT		"Memory Error"
		DB	0

VBASE		EQU		49152
XDIM2		EQU		384    ; XDIM Screen Horizontal Dim. 
YDIM		EQU		248    ; Screen Vertical Dimention
XCC		EQU		64     ; Horizontal Lines
YCC		EQU		31     ; Vertical Rows

;  INT4 FUNCTION TABLE  function in a0
INT4T0	DA		SERIN    ; Serial port in    
INT4T1	DA		SEROUT   ; Serial port out
INT4T2	DA		PLOT     ; at X=A1,Y=A2 A4=1 set A4=0 clear
INT4T3	DA		CLRSCR   ; CLEAR SCREEN
INT4T4	DA		PUTC     ; Print char A2 at A1.H A1.L
INT4T5	DA		PSTR     ; Print zero & cr terminated string
INT4T6	DA		SCROLL   ; Scrolls screen 1 char (8 points) up
INT4T7	DA		SKEYBIN  ; Serial Keyboard port in
INT4T8	DA		MULT     ; Multiplcation A1*A2 res in A2A1, a0<>0 overflow 
INT4T9	DA		DIV      ; integer Div A2 by A1 res in A1,A0
INT4T10	DA		KEYB     ; converts to ascii the codes from serial keyboard
INT4T11	DA		SPI_INIT ; initialize spi sd card
INT4T12	DA		SPISEND  ; spi send/receive byte in A1 mode A2 1=CS low 3=CS high
				         ; result in A0
INT4T13	DA		READSEC  ; read in buffer at A2, n in A1
INT4T14	DA		WRITESEC ; WRITE BUFFER at A2 TO A1 BLOCK
INT4T15	DA		PIMG     ; plot 8xA4 image from (A5) to A1,A2

;  INT5 FUNCTION TABLE  function in a0
INT5T0	DA		FMULT	   ; Fixed point multiply A1*A2
INT5T1	DA		FDIV	   ; Fixed point divide A2.(FRAC2)/A1.(FRAC1)

;Hardware interrupt
HINT:		INC		(COUNTER)
INTR15:	RETI        ; trace interrupt
		
INTR4:	SLL		A0,1
		ADD		A0,INT4T0
		JMP		(A0)
INTEXIT:	RETI

INTR5:	SLL		A0,1
		ADD		A0,INT5T0
		JMP		(A0)
		RETI

;---------------------------------
; INT5 A0=1  fixed point 16.16 
; Div A2 by A1 res in A1 (FRAC1),   restoring division 9/5/2017

FDIV:		STI	
		PUSH		A3
		PUSH		A4
		PUSH		A7
		PUSHX
		MOV		A0,A2
		XOR		A0,A1
		PUSH		A0
		BTST		A1,15           ; check if neg and convert 
		JZ		FDIV2
		NOT		A1
		MOV		A4,(FRAC1)
		NOT		A4
		INC		A4
		ADC		A1,0
		MOV		(FRAC1),A4
FDIV2:	MOV		A4,(FRAC2)
		BTST		A2,15          ; check if neg and convert 
		JZ		FDIV3
		NOT		A2
		NOT		A4
		INC		A4
		ADC		A2,0          ; A2A4 = Q Divident
FDIV3:	MOV		A3,(FRAC1)
		

		SETX		14            ; shift dividend as left as possible
FDC1:		BTST		A2,15
		JNZ		FDC2
		SLL		A2,1
		SLL		A4,1
		ADC		A2,0
		JMPx		FDC1
FDC2:		
		MOVX		A0
		CMP		A0,8
		JBE		FDC3
		SETX		7
		BTST		A3,0
		JNZ		FDC9
FDC5:		SRL		A3,1
		SRL		A1,1
		JNC		FDC4
		BSET		A3,15
FDC4:		DEC		A0
		JMPX		FDC5		
FDC9:		SETX		A0
FDC3:
		PUSHX		

		NOT		A1
		NOT		A3
		INC		A3
		ADC		A1,0
		MOV		A7,A1    ; store -M
		MOV		(FRAC2),A3
		
		MOVI		A1,0
		MOVI		A3,0	   	; A1A3 = A
		SETX		30
		 
FD_INTER:
		SLL		A1,1           ; shift AQ left
		SLL		A3,1
		ADC		A1,0
		SLL		A2,1
		ADC		A3,0
		SLL		A4,1
		ADC		A2,0
		
		PUSH		A1
		PUSH		A3
		ADD		A3,(FRAC2)   	;A=A-M
 		ADC		A1,A7
		JP		FD_COND1   
		POP		A3
		POP		A1
		BCLR		A4,0
		JMP		FD_COND2
FD_COND1:	POP		A0
		POP		A0	
		BSET		A4,0       
FD_COND2:	
		JMPX		FD_INTER
		
		POP		A0          ; shift left as needed
		ADDI		A0,3
		SUBI		A0,1
		JN		FDC6
		SETX		A0
FDLP:		SLL		A2,1
		SLL		A4,1
		ADC		A2,0
		JMPX		FDLP
		JMP		FDC7

FDC6:		INC		A0
		JZ		FDC7
		SRL		A4,1        ; or shift right as needed
		SRL		A2,1
		JNC		FDC8
		BSET		A4,15
FDC8:		JMP		FDC6

FDC7:		MOV		A1,A2	     ; integer result in A1
		POP		A0
		BTST		A0,15
		JZ		FDIVEND     ; correct sign
		NOT		A1
		NOT		A4
		INC		A4
		ADC		A1,0
FDIVEND:	MOV		(FRAC1),A4  ; store fraction result 
		POPX
		POP		A7
		POP		A4
		POP		A3
		RETI

;-------------------------------------
;  		INT 5 A0=0
; fixed point multiply
FMULT:	STI	
		PUSH		A3
		PUSH		A4
		PUSH		A5
		PUSH		A6
		MOV		A0,A2
		XOR		A0,A1
		PUSH		A0
		BTST		A1,15    ; check if neg and convert 
		JZ		FMUL2
		NOT		A1
		MOV		A4,(FRAC1)
		NOT		A4
		INC		A4
		ADC		A1,0
		MOV		(FRAC1),A4
FMUL2:	BTST		A2,15   ; check if neg and convert 
		JZ		FMUL3
		NOT		A2
		MOV		A4,(FRAC2)
		NOT		A4
		INC		A4
		ADC		A2,0
		MOV		(FRAC2),A4
FMUL3:	MOV		A5,A1
		MOV		A6,A2
		MULU		A1,A2
		MOV		A0,A2
		MOV		A3,A1
		MOV		A1,(FRAC1)
		MOV		A2,(FRAC2)
		MOV		A4,A1
		OR		A4,A2
		JZ		FMULZ ; skip more mults if fractions = zero
		MULU		A1,A2
		MOV		A4,A2 ; store result fraction
		MOV		A1,(FRAC1)
		MOV		A2,A6
		MULU 		A1,A2
		ADD		A4,A1
		ADC		A3,A2
		ADC		A0,0
		MOV		A1,(FRAC2)
		MOV		A2,A5
		MULU 		A1,A2
		ADD		A4,A1
		ADC		A3,A2
		ADC		A0,0	
FMULZ:	MOV		A1,A3
		POP		A2
		BTST		A2, 15
		MOV		A2,A0
		JZ		FMULEND     ; Check result sign
		NOT		A1
		NOT		A4
		NOT		A2
		INC		A4
		ADC		A1,0
		ADC		A2,0
FMULEND:	MOV		(FRAC1),A4
		POP		A6
		POP		A5
		POP		A4
		POP		A3
		RETI


;--------------------------------------
WRITESEC:
	PUSHX
	PUSH	A1
	PUSH	A2
	PUSH	A3
	PUSH	A4

	PUSH  A2   ; save buffer address

	MOV	A4,A1
	MOV	A3,A1
	SRL	A3,7
	SLL	A4,9    ; multiply 512 to convert block to byte

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS
	MOVI	A2,1
	OUT	19,1

	MOV 	A1,$58  ; write SECTOR
	JSR	SPIS
	MOVLH	A1,A3
	JSR	SPIS
	MOV.B	A1,A3
	JSR	SPIS
	MOVLH	A1,A4
	JSR	SPIS
	MOV.B	A1,A4
	JSR	SPIS
	MOV 	A1,$FF 
	JSR	SPIS 

	MOV	A1,$FF   ; delay
	JSR	SPIS
	 
	MOV	A1,$FE    ; SEND START OF DATA
	JSR	SPIS	

	POP 	A3         ;	MOV	A3,SDCBUF1    ; buffer
	SETX	511        ; WRITE DATA 512 BYTES + 2 CRC bytes
WRI6:	MOV.B	A1,(A3)
	JSR	SPIS
	INC	A3
	JMPX	WRI6
	MOVI	A1,0
	JSR	SPIS
	MOVI	A1,0
	JSR	SPIS

	SETX	100          ; READ ANSWER until $05 is found
WRS8:	MOV	A1,$FF
	JSR	SPIS
	AND.B	A0,$0F
	CMPI.B A0,5
	JRZ	4
	JMPX	WRS8

	CMPI.B A0,5
	JNZ	WRIF

	SETX	5000          ; READ ANSWER until $00 is found
WRS9: MOV	A1,$FF
	JSR	SPIS
	OR.B	A0,A0
	JRZ	4
	JMPX	WRS9
	
	OR.B	A0,A0
	JNZ	WRIF

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS

	MOV	A0,$0100  ; ALL OK

WRIF: POP	A4
	POP	A3
	POP	A2
	POP	A1
	POPX
	RETI

;-----------------------------------------

READSEC:
	PUSHX
	PUSH	A1
	PUSH	A2
	PUSH	A3
	PUSH	A4

	PUSH	A2

	MOV	A4,A1
	MOV	A3,A1
	SRL	A3,7
	SLL	A4,9    ; multiply 512 to convert block to byte

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS
	MOVI	A2,1
	OUT	19,1

	MOV 	A1,$51  ; READ SECTOR
	JSR	SPIS
	MOVLH	A1,A3
	JSR	SPIS
	MOV.B	A1,A3
	JSR	SPIS
	MOVLH	A1,A4
	JSR	SPIS
	MOV.B	A1,A4
	JSR	SPIS
	MOV 	A1,$FF 
	JSR	SPIS 

	SETX	299          ; READ ANSWER until $FE is found
RDS5:	MOV	A1,$FF
	JSR	SPIS
	CMP.B	A0,$FE
	JZ	SDRD2
	JMPX	RDS5

SDRD2:
	POP	A3   		; MOV	A3,SDCBUF1 ; read to buffer
	CMP.B	A0,$FE  
	JNZ	RDIF       ; data ready ?
	SETX	513        ; READ DATA 512 BYTES + 2 CRC bytes
RDI6:	MOV	A1,$FF
	JSR	SPIS
	MOV.B	(A3),A0
	INC	A3
	JMPX	RDI6

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS

	MOV	A0,$0100  ; ALL OK

RDIF: POP	A4
	POP	A3
	POP	A2
	POP	A1
	POPX
	RETI

;-----------------------------------------
SPISEND:
	PUSH	A1
	PUSH	A2
	JSR	SPIS
	POP	A2
	POP	A1
	RETI
;------------------------------------------------
SPIS:
	OUT	18,A1
	OUT	19,A2
	BCLR	A2,0
	OUT	19,A2
	BSET	A2,0
SPIC: IN	A1,17
	OR.B	A1,A1
	JNZ	SPIC
	IN	A0,16
	RET
	
;--------------- * INIT * ----------------
SPI_INIT:
	PUSHX
	PUSH 	A1
	PUSH	A2
	PUSH	A3

	MOVI	A3,0

SPIN:	CMP	A3,100   
	JA	SPIF  ; MANY RETRIES FAIL
	SETX	9
	MOVI	A2,3
SPI0: MOV	A1,255	
	JSR	SPIS
	JMPX	SPI0    ; SEND 80 CLK PULSES WITH CS HIGH
	
	MOVI	A2,1
	OUT	19,0    ; cs=0


	MOV 	A1,$40  ; INIT SPI MODE WITH CS LOW
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOV 	A1,$95
	JSR	SPIS	

	SETX	7	         ;READ 8 RESPONCES
SPI3:	MOV	A1,$FF
	JSR	SPIS
	CMPI.B A0,1
	JNZ	SPNF
	MOV	A2,5
SPNF:	JMPX	SPI3
	
	INC 	A3	
	CMPI	A2,5
	JNZ	SPIN

	MOV	A3,0

SPNT:	CMP	A3,50
	JA	SPIF

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS
	MOVI	A2,1

	MOV 	A1,$41  ; INITIALIZE spi
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOV 	A1,$FF 
	JSR	SPIS 

	SETX	7         ; READ 8 ANSWERS
SPI2:	MOV	A1,$FF
	JSR	SPIS
	OR.B	A0,A0
	JNZ	SPNX
	MOV	A2,5
SPNX:	JMPX	SPI2

	INC	A3
	CMPI	A2,5
	JNZ	SPNT

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS
	MOVI	A2,1

	MOV 	A1,$50  ; SET TRANSFER SIZE
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$02
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOV 	A1,$FF 
	JSR	SPIS 

	SETX	7          ; READ ANSWER
SPI4:	MOV	A1,$FF
	JSR	SPIS
	JMPX	SPI4

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS
	MOVI	A2,1

	MOV 	A1,$51  ; READ FIRST SECTOR
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOVI 	A1,$0
	JSR	SPIS
	MOV 	A1,$FF 
	JSR	SPIS 

	SETX	51          ; READ ANSWER until $FE is found
SPI5:	MOV	A1,$FF
	JSR	SPIS
	CMP.B	A0,$FE
	JZ	SDRD
	JMPX	SPI5

SDRD:	CMP.B	A0,$FE  
	JNZ	SPIF       ; data ready ?
	MOV	A3,SDCBUF1 ; read to buffer
	SETX	513        ; READ DATA 512 BYTES + 2 CRC bytes
SPI6:	MOV	A1,$FF
	JSR	SPIS 
	MOV.B	(A3),A0
	INC	A3
	JMPX	SPI6

	MOVI	A2,3
	MOV 	A1,$FF  ; send dummy with cs high
	JSR	SPIS

	MOV	A0,$0100  ; ALL OK

SPIF:	POP	A3
	POP	A2
	POP	A1
	POPX
	RETI

;---------------------------------------- 
SERIN:	IN		A0,6  ;Read serial byte if availiable
		BTST		A0,1  ;Result in A1, A0(1)=0 if not avail
		JZ		INTEXIT
		IN		A1,4
		MOVI		A0,2
		OUT		2,A0
		MOVI		A0,0
		OUT		2,A0
		MOVI		A0,2
		RETI
;----------------------------------------
SEROUT:	IN		A0,6  ;Wite serial byte if ready
		BTST		A0,0  ; A0(0)=0 if not ready
		JZ		INTEXIT
            PUSH        A1
		OUT		0,A1
		MOVI		A1,0
		MOVI		A0,1
		OUT		2,A0
		OUT		2,A1
		POP		A1
		RETI
; -------------------------------------
SKEYBIN:	IN		A0,6  ;Read serial byte if availiable
		BTST		A0,2  ;Result in A1, A0(2)=0 if not avail
		JZ		INTEXIT
		IN		A1,14
		MOVI		A0,2
		OUT		15,A0
		MOVI		A0,0
		OUT		15,A0
		MOVI		A0,4
		RETI

;----------------------------------------
PUTC:		STI
		PUSHX        ;  PRINT Character in A1 at A2 (XY)
		PUSH		A4
		PUSH		A3
		;PUSH		A1
		AND		A1,$00FF
		CMP.B		A1,96  
		JBE		LAB1
		SUB.B		A1,32
		CMP.B		A1,90
		JLE		LAB1
		ADDI		A1,6
LAB1:		SUB.B		A1,32    
		MULU.B	A1,6
		ADD		A1,CTABLE
		MOV		A4,A1       ; character table address
		MOVI		A0,0
		MOV.B		A0,A2
		MULU		A0,XDIM2
		;SLL		A0,1
		MOVI		A1,0
          	MOVLH 	A1,A2
		MULU.B	A1,6
		ADD		A0,A1
		ADD		A0,VBASE   ; video base
		MOV		A3,A0      ; Addres at videoram
		SETX		5          ; 6 Times
LP1:		MOV.B		(A3),(A4)
		INC		A4
		INC		A3          ; next   
		JMPX		LP1
		;POP		A1
		POP		A3
		POP		A4
		POPX	
		RETI
;----------------------------------------
PSTR:		STI
		MOVI.B	A0,0 ; PRINT A 0 OR 13 TERM. STRING POINTED BY A1 AT A2
		MOV.B		A0,(A1)
		CMPI.B	A0,0
		JZ		STREXIT
		CMPI.B	A0,13
		JNZ         PSTR2
		MOVI		A0,6
		INT		4
		JMP		STREXIT
PSTR2:	PUSH 		A1
		MOV		A1,A0
		MOVI		A0,4
		INT		4
		POP		A1
		SWAP		A2      ;  X
		INC		A2
		CMP.B		A2,XCC
		JNZ		LAB3
		MOVI.B	A2,0
		SWAP		A2
		INC		A2
		CMP.B		A2,YCC
		JNZ		LAB3
		MOVI		A0,6
		INT		4
LAB3:		SWAP		A2
		INC		A1
		JMP		PSTR
STREXIT:	RETI
;----------------------------------------

SCROLL:	STI
		PUSHX
		PUSH		A1
		SETX		11519       ;7499	
		MOV		A0,VBASE
		MOV		A1,49536   ; 49152+384
SC1:		MOV.B		(A0),(A1)  ;  Only byte wide access to video ram
		INC		A0
		INC		A1
		JMPX		SC1
		SETX		383
SC2:		MOV.B		(A0),0
		INC		A0
		JMPX		SC2		
		POP		A1
		POPX
		RETI
;----------------------------------------

CLRSCR:	STI
		PUSHX
		SETX		11904       ;7799	
		MOV		A0,VBASE
CLRS1:	MOV.B		(A0),0
		INC		A0
		JMPX		CLRS1
		POPX
		RETI
;----------------------------------------
PLOT:		STI
		PUSHX
		PUSH		A1
		PUSH		A2        ; PLOT at A1,A2 mode in A4
		MOV		A0,A2
		AND		A0,7
		SRL		A2,3
		MULU		A2,XDIM2
		;SLL		A2,1
		ADD		A2,A1
		ADD		A2,VBASE 
		MOV.B		A1,(A2)
		SETX		A0
PL1:		SLL		A1,1
		JMPX		PL1
		OR		A4,A4
		JNZ		PL3
		BCLR		A1,8
		JMP		PL4
PL3:		CMPI		A4,2
		JNZ		PL5
		XOR		A1,$100
		JMP		PL4
PL5:		BSET		A1,8
PL4:		SETX		A0
PL2:		SRL		A1,1
		JMPX		PL2
		MOV.B		(A2),A1
		POP		A2
		POP		A1
		POPX
		RETI
;----------------------------------------
PIMG:		STI
		PUSHX
		PUSH		A1
		PUSH		A2       ;Draw Image at A1,A2 from A5(A3 bytes),mode in A4
		PUSH		A3
		MOV		A0,A2
		AND		A0,7
		SRL		A2,3
		MULU		A2,XDIM2
		;SLL		A2,1
		ADD		A2,A1
		ADD		A2,VBASE 
		
		DEC		A3
		SETX		A3
PIM1:		MOVI		A3,0
		MOV.B		A3,(A5)
		SWAP		A3
		PUSH		A0

PIM2:		CMPI		A0,0
		JZ		PIM3
		SRL		A3,1
		DEC		A0
		JNZ		PIM2
	
PIM3:		SWAP		A3
		MOV.B		A1,(A2)
		XOR		A1,A3
		MOV.B		(A2),A1
		MOV		A0,XDIM2
		;SLL		A0,1
		ADD		A0,A2
		MOV.B		A1,(A0)
		SWAP		A3
		XOR		A1,A3
		MOV.B		(A0),A1
		INC		A2
		INC		A5
		POP		A0	
		JMPX		PIM1
		POP		A3
		POP		A2
		POP		A1
		POPX
		RETI

;---------------------------------------
KEYB:		STI
		PUSHX
		CMP		A1,90 
		JNZ		NOTCR
		MOVI		A1,13
		JMP		LP10
NOTCR:	CMP		A1,102
		JNZ		NOTBS
		MOVI		A1,8
		JMP		LP10
NOTBS:	CMP		A1,118
		JNZ		KB1
		MOV		A1,27
		JMP		LP10		
KB1:		SETX 		67           ; Convert Keyboard scan codes to ASCII
		MOV		A0,KEYBCD
LP3:		CMP.B		A1,(A0)
		JZ		LP4
		INC		A0
		JMPX		LP3
		MOV		A1,0
		JMP		LP10
LP4:		MOVX		A0
		MOV		A1,99
		SUB		A1,A0
		CMP.B		A1,94
		JBE		LP10
		ADD		A1,28
LP10:		POPX
		RETI

;--------------------------------------------------------------
; Multiplcation A1*A2 res in A2A1, a0<>0 if 16bit overflow  

MULT:		STI
		PUSH		A3
		MOV		A0,A2
		XOR		A0,A1
		PUSH		A0
		BTST		A1,15    ; check if neg and convert 
		JZ		MUL2
		NOT		A1
		INC		A1
MUL2:		BTST		A2,15   ; check if neg and convert 
		JZ		MUL3
		NOT		A2
		INC		A2
MUL3:		MULU		A1,A2
		POP		A0
		BTST		A0, 15
		MOV		A0,A2
		JZ		MULEND     ; Check result sign
		NOT		A1
		NOT		A2
		INC		A1
		ADC		A2,0
MULEND:	POP		A3
		RETI

;-------------------------------------------------------------
; Div A2 by A1 res in A1,A0

DIV:		STI
		PUSHX
		PUSH		A3
		PUSH		A4
		MOV		A3,A1
		MOV		A1,32767
		OR		A3,A3
		JZ		DIVE
		MOVI		A1,0
		XOR		A0,A2
		BTST		A0,15
		JZ		DIV1     ; Check result sign
		MOVI		A1,1
DIV1:		PUSH		A1 
		BTST		A2,15    ; check if neg and convert 
		JZ		DIV2
		NOT		A2
		INC		A2
DIV2:		BTST		A3,15   ; check if neg and convert 
		JZ		DIV3
		NOT		A3
		INC		A3
DIV3:		MOV		A1,A2
		CMP		A3,A1
		JBE		DIV4
		MOV		A0,A1  ; id divider > divident res=0 rem=divident
		MOVI		A1,0
		JMP		DIV14
DIV4:		MOV		A0,A2 ; main algorithm
		MOVI		A1,0
DIV5:		BTST		A0,14  ; left align
		JNZ		DIV6
		INC		A1
		SLL		A0,1
		JMP		DIV5
DIV6:		PUSH 		A1     ; store no of shifts
		MOVI		A4,0
		MOV		A1,A3
DIV7:		BTST		A1,14  ; left align 
		JNZ		DIV12
		SLL		A1,1
		INC		A4
		JMP		DIV7
DIV12:	MOV		A2,A0  
		MOV		A3,A1  
		MOV		A1,A4
		POP		A0  ; Get no of shifts
		MOV		A4,A0
		SUB		A1,A0
		PUSH		A1   ; shifts differance
		MOV		A0,A2  
		MOV		A1,A3  
DIV10:	OR		A4,A4
		JZ		DIV9
		SRL		A1,1
		SRL		A0,1
		DEC		A4
		JMP		DIV10
DIV9:		MOV		A2,A0  ; new dividend = remainder
		MOV		A3,A1  ; new divisor
		POP		A1
		SETX		A1
		MOVI		A1,0       ; quotient
DIV11:	SLL		A1,1       
		CMP		A0,A3  ; compare remainder with divisor
		JC		DIV8		
		BSET		A1,1
		SUB		A0,A3
DIV8:		SRL		A3,1
		JMPX		DIV11
		SRL		A1,1
DIV14:	POP		A3
		OR		A3,A3
		JZ		DIVE
		NOT		A1
		INC		A1
DIVE:		POP		A4
		POP		A3
		POPX
		RETI

ROMEND:
; Charcter table Font
CTABLE	DB	0,0,0,0,0,0,58,0,0,0,0,0
C34_35	DB	96,0,96,0,0,0,20,62,20,62,20,0
C36_37	DB	58,42,127,42,46,0,34,4,8,16,34,0
C38_39      DB    20,62,20,62,20,0,96,0,0,0,0,0
C40_41	DB	28,34,0,0,0,0,34,28,0,0,0,0
C42_43	DB	168,112,32,112,168,0,8,8,62,8,8,0
C44_45	DB	3,0,0,0,0,0,8,8,8,8,8,0
C46_47	DB	2,0,0,0,0,0,0,6,8,48,0,0
C48_49	DB	28,38,42,50,28,0,0,18,62,2,0,0
C50_51	DB	38,42,42,42,18,0,34,42,42,42,54,0
C52_53	DB	60,4,14,4,4,0,58,42,42,42,36,0
C54_55	DB	62,42,42,42,46,0,32,32,38,40,48,0
C56_57	DB	62,42,42,42,62,0,58,42,42,42,62,0
C58_59	DB	34,0,0,0,0,0,35,0,0,0,0,0
C60_61	DB	8,20,34,0,0,0,20,20,20,20,20,0
C62_63	DB	34,20,8,0,0,0,16,32,42,16,0,0
C64_65	DB	62,34,42,42,58,0,62,36,36,36,62,0
C66_67	DB	62,42,42,42,54,0,62,34,34,34,34,0
C68_69	DB	62,34,34,34,28,0,62,42,42,42,34,0
C70_71	DB	62,40,40,40,32,0,62,34,34,42,46,0
C72_73	DB	62,8,8,8,62,0,34,34,62,34,34,0
C74_75	DB	6,2,2,34,62,0,62,8,8,20,34,0
C76_77	DB	62,2,2,2,2,0,62,16,8,16,62,0
C78_79	DB	62,16,8,4,62,0,28,34,34,34,28,0
C80_81	DB	62,40,40,40,16,0,60,36,38,36,60,0
C82_83	DB	62,40,40,40,22,0,58,42,42,42,46,0
C84_85	DB	32,32,62,32,32,0,62,2,2,2,62,0
C86_87	DB	48,12,2,12,48,0,60,2,12,2,60,0
C88_89	DB	34,20,8,20,34,0,48,8,6,8,48,0
C90_91	DB	34,38,42,50,34,0,62,34,0,0,0,0
C92_93	DB	48,8,6,0,0,0,34,62,0,0,0,0
C94_95	DB	0,64,128,64,0,0,2,2,2,2,2,2
C96_123	DB	0,128,0,0,0,0,0,8,62,34,0,0
C124_125 	DB	54,0,0,0,0,0,0,34,62,8,0,0
C126  	DB	64,128,64,128,0,0


KEYBCD	DB    $29,$16,$71,$26,$25,$2E,$3D,$52,$46,$45,$3E,$79,$41,$4E,$49,$4A,$70,$69,$72,$7A
		DB    $6B,$73,$74,$6C,$75,$7D,$7C,$4C,$7E,$55,$E1,$78,$1E,$1C,$32,$21,$23,$24,$2B,$34
		DB	$33,$43,$3B,$42,$4B,$3A,$31,$44,$4D,$15,$2D,$1B,$2C,$3C,$2A,$1D,$22,$35,$1A,$54
		DB	$5D,$58,$36,$3,$0B,$83,$0A,0

		ORG     	8192   ;Ram
SDCBUF1	DS	514
SDCBUF2	DS	514
SDFLAG	DS	2 ; =256 if sd init succeeded
COUNTER	DS	2 ; Counter for general use (RND) increased by int 0 
FRAC1		DS	2 ;
FRAC2		DS	2 ;
START:	
