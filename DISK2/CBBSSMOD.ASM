;CBBS V3.6.0 	CBBSSMOD.ASM - HAYES SMARTMODEM 1200, Cromemco Tu-art
;09/30/83 08:30:59
;	LINKS TO CBBSWORK
; or	if XFER, (see NOTE below) LINKS TO CBBSXFER
;
;Thanks to Jim Willing of CBBS/NW (CBBS at (503) 646-5510)
;	for supplying this version of CBBSMODM.ASM
;
;====> 	NOTE: to support file transfer, additional
;	routines like those in CBBSPMMI.ASM will have to
;	be written for character status and I/O. 
;
;====>	THERE IS NO EQUATE IN CBBS.ASM TO SUPPORT THIS ROUTINE.
;	INSTEAD, REN CBBSUDS.ASM=CBBSMODM.ASM
;	AND	 REN CBBSMODM.ASM=CBBSSMOD.ASM
;	so CBBS assembly will link to THIS routine.
;
;	O   O	O O O	O O	O   O
;	OO OO	O   O	O   O	OO OO
; CBBS	O O O   O   O   O   O   O O O	.ASM
;	O   O   O   O   O   O   O   O
;	O   O	O O O	O O	O   O
;	
;
;MOD LOG:
;
; 22-Dec-82	1st revision, for use with updated Tu-Art
; 25-Dec-82	Add code to reset chip when entering baud
;		rate scanner. Else UARTS seem to get confused
;		on 110 baud.
;
;	The modem is running on a (slightly) modified
;	Cromemco Tu-art, modified to return CD & SPEED,
;	and to have control of DTR to force modem to hang
;	up or not answer.  Mods were easy, had spare
;	drivers on board. /JW
;
;	Tu-Art Port Equates
;
ABASE	Equ	0		;Base address device A
BBASE	Equ	50H		;Base address device B
ASTAT	Equ	ABASE		;Status port device A
BSTAT	Equ	BBASE		;Status port device B
ABAUD	Equ	ABASE		;Baud Rate port device A
BBAUD	Equ	BBASE		;Baud Rate port device B
ADATA	Equ	ABASE+1		;Data I/O port device A
BDATA	Equ	BBASE+1		;Data I/O port device B
ACMD	Equ	ABASE+2		;Command port device A
BCMD	Equ	BBASE+2		;Command port device B
AINT	Equ	ABASE+3		;Interrupt port device A
BINT	Equ	BBASE+3		;Interrupt port device B
APARA	Equ	ABASE+4		;Parallel port device A
BPARA	Equ	BBASE+4		;Parallel port device B
;
;	Tu-Art Status Masks
;
TBE	Equ	80H		;Transmitter Buffer Empty
RDA	Equ	40H		;Recieved Data Available
INTPND	Equ	20H		;Interrupt Pending Flag
HIBAUD	Equ	10H		;High Speed Flag
CARDET	Equ	08H		;Carrier Detect
RINGIN	Equ	04H		;Ring Indicator (to be added)
OVRRUN	Equ	02H		;Overrun Error flag
FRAMER	Equ	01H		;Framing Error flag
;
;	Tu-Art Baud Rate equates
;
B110	Equ	01H		;110 baud, 2 stop bits
B300	Equ	84H		;300 baud, 1 stop bit
B1200	Equ	88H		;1200 baud, 1 stop bit
;
;In later versions, we will get here only
;after control has passed here from the
;Ring Detect routine.
;
;In this version, we will get here and the
;modem has already answered the phone. We
;will just check for Carrier-Detect
;and then proceed...
;
;ROUTINE TO CONNECT TO THE CALLER
;
CONNECT	EQU	$
 if motctl
	call	motoron 	;LEAVE DISK MOTOR ON
 endif
;
	MVI	A,00H	 	;TURN ON DTR TO ALLOW MODEM TO
				;PICK UP THE PHONE
	OUT	APARA		;TO MODEM CTL PORT
;
	MVI	B,15	;APPROX # SEC. DELAY
DELAY	LXI	H,9A00H	;1 SEC DELAY
DELLP	IN	ASTAT		;Input modem status
	ANI	CARDET		;Mask the carrier detect bit
	JZ	GOTCAR		;EXIT LOOP IF CARRIER FOUND
	DCX	H		;DECR. LOOP COUNT
	MOV	A,H
	ORA	L
	JNZ	DELLP
;DELAYED ANOTHER SECOND, MORE SECONDS?
	DCR	B	;DCR SECONDS
	JNZ	DELAY	;YES
	JMP	NOCAR
;
;LOOK FOR C/R AT EACH SPEED
;
GOTCAR	MVI	A,10+1	;10 TRIES FOR C/R
	STA	TRIES
;
	Mvi	A,01		;Load RESET code for UART
	Out	ACMD		;Send to command port
;
	IN	ASTAT		;Read modem status
	ANI	HIBAUD		;Check for Hi Speed status
	JZ	GOT12		;Jump over if 1200 baud call
;
;QUIT IF NO C/R HAS BEEN READ AFTER 10 TRIES
;
TRY1	LXI	H,TRIES
	DCR	M
	JZ	NOCAR	;NO CARRIER
;
	CALL	SET110
01	CZ	CKCR	;GET SECOND C/R
	RZ
	CALL	SET300
01	CZ	CKCR	;GET SECOND C/R
	RZ
;
	JMP	TRY1	;TRY 10 TIMES
;
;Test for 1200 baud carriage return
;
GOT12	LXI	H,TRIES		;Set pointer to try counter
	DCR	M		;-1 from counter
	JZ	NOCAR
;
	CALL	SET120		;Set up for 1200 baud
	CALL	CKCR		;Check for Carriage-Return
	RZ
;
	IN	ASTAT		;Read modem status
	ANI	HIBAUD		;Check for Hi Speed status
	JNZ	TRY1		;Jump out if not 1200 baud call
;
	JMP	GOT12		;Loop till tries exhausted...
;
;TEST FOR C/R ENTERED, OR LOSS OF CARRIER
;
CKCR	CALL	KEYIN
	CPI	CR
	RZ
	INR	A	;FF MEANS NO CARR
	RNZ
;
;NO CARRIER FOUND
;
NOCAR	LXI	H,NOCON
	JMP	PRDIS	;PRINT MSG, EXIT TO PROM
NOCON	DB	CR,LF
	DB	'++NO C/R SEEN, OR LOSS OF CARRIER'
	DB	CR,LF,'    ',0
;
;SET SPEED TO 110 BAUD - PARITY INHIBIT, 2 STOP BITS
;
SET110	MVI	A,B110		;8 data, 2 stop bits, no parity
	OUT	ABAUD		;Set baud rate
	MVI	A,'1'
	STA	SPEED
	JMP	CKCR		;CHECK FOR C/R
;
;SET SPEED TO 300 BAUD, PARITY INHIBIT, 1 STOP BIT
;
SET300	MVI	A,B300		;8 data, 1 stop, no parity
	OUT	ABAUD		;Set baud rate
	MVI	A,'3'
	STA	SPEED
	JMP	CKCR
;
;	NOTE TU-ART can't handle 600 baud.  If your baud-rate
;	generator can, add code for it.
;
;SET SPEED TO 1200 BAUD, PARITY INHIBIT, 1 STOP BIT
;
SET120	MVI	A,B1200		;8 data, 1 stop, no parity
	OUT	ABAUD		;Set baud rate
	MVI	A,'H'		;High speed
	STA	SPEED
	JMP	CKCR
;
;ROUTINE TO HANG UP PHONE
;
HANGUP	MVI	A,0FFH		;Load a FF in (A)
	OUT	APARA		;Drop DTR (forces hang up)
HANGWT	LXI	H,9A00H		;Aprox 1 sec delay
HANGLP	DCX	H		;Decr loop count
	MOV	A,H
	ORA	L
	JNZ	HANGLP

	MVI	A,00H		;Stick a 1 in (A)
	OUT	APARA		;Set DTR
	RET
;
;WAIT FOR PHONE TO RING IF RE-INIT
;
	IF	REINIT
RINGWT	IN	ASTAT		;INPUT STATUS PORT
	ANI	CARDET		;Do we have carrier?
	JZ	START
	IN	SSW	;GO TO START IF REMOTE
	ANI	REMOTE	;..SWITCH TURNED OFF
	JZ	START
	JMP	RINGWT
	ENDIF		;REINIT
;
 if xfer
RECVDG	write per cbbsinst.doc
RECV	write per cbbsinst.doc
SEND	write per cbbsinst.doc
;
	link	cbbsxfer
 endif	
;
	LINK	CBBSWORK ;NEXT .ASM FILE
                                                 