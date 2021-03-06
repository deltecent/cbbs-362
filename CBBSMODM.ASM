;CBBS V3.6.2 	CBBSUDS.ASM - UDS MODEM WITH HSIO-4
;09/10/83 17:01:53
;	LINKS TO CBBSWORK
;
;	O   O	O O O	O O	O   O
;	OO OJ	O   O	O   O	OO OO
;CBBS	O O O	O   O	O   O	O O O	.ASM
;	O   O	O   O	O   O	O   O
;	O   O	O O O	O O	O   O
;
;MOD LOG (THRU 3.2 WRITTEN TO "HISTORY")
;
;09/05/83 add ckcarr - returns zero if carrier.
;	used by bye routine.
;07/26/83 modified from cbbsmodm, hays, and pmmi, 
;	for uds modem running on n* hs4io board
;
;uds serial port equates
;
UDSDAT	EQU	12H		;data port address
;
;status input port, and it's bits:
;
UDSST	EQU	UDSDAT+1 	;status port
;
UDSRI	EQU	80H		;ring indicate
UDSCD	EQU	80H		;carrier detect
UDSTRE	EQU	1		;tx reg empty
UDSRRF	EQU	2		;rcv reg filled
;
;control output port 1 and it's bits:
;
UDSCP1	EQU	10H		;control port 1
;
;
;control output port 2 and it's bits:
;
;
;		----
;
;connect with caller, await carrier for 15 sec
;
CONNECT	CALL	SET300		;pick up phone, 300 baud
	MVI	B,15*MHZ	;approx # sec. delay
DELAY	LXI	H,9A00H		;1 sec delay
DELLP	CALL	CKCARR
	JZ	GOTCAR		;exit loop if carrier found
	DCX	H		;decr. loop count
	MOV	A,H
	ORA	L
	JNZ	DELLP
;delayed another second.
;more seconds?
	DCR	B
	JNZ	DELAY		;yes
	JMP	NOCAR
;
; 09/05/83 ckcarr returns zero if carrier
;	NOTE this is supposed to be called from BYEYN so that
;	if in the "y/n want to leave any comments" loop with
;	caller gone, it exits properly. (JZ BYEBYE)
;
CKCARR	IN	UDSST		;get status
	CMA			;force "jz gotcarrier" logic
	ANI	UDSCD		;check for carrier
	RET
;
;phase 1 - look for C/R at either speed
;
GOTCAR	MVI	A,10+1		;10 tries for C/R
	STA	TRIES
;
;quit if no C/R has been read after 10 tries
;
TRY1	IN	17H		;1200 baud?
	ANI	80H
	JZ	NOT1200
	MVI	A,'H'		;put "h" in log for (h)igh speed.
	STA	SPEED
	MVI	A,4		;1200 baud
	OUT	10H
	MVI	A,27H
	OUT	13H
	CALL	KEYIN
	CPI	CR
	RZ
	INR	A		;bios returns 0ffh if no carrier.
	JZ	NOCAR
	JMP	TRY1

NOT1200	CALL	SET110
	CZ	CKCR		;get second C/R
	RZ
	CALL	SET300
	CZ	CKCR		;get second C/R
	RZ
;
	LDA	TRIES		;tries
	DCR	A		;	= tries-1
	STA	TRIES
	JZ	NOCR		;if tries = 0, no C/R seen
	CPI	5		;if tries = 5, send msg
	CZ	TELLCR		; telling them to hit C/R
;
	CALL	SET600
	CZ	CKCR
	RZ
;
;read 110 a second time.  otherwise 110 C/R read
;at 600 will fail and cause invalid 110 C/R too
;
	CALL	SET110
	CZ	CKCR		;get second C/R
	RZ
	JMP	TRY1		;try 10 times
;
; no C/R's seen, default 300 baud, type msg
;
TELLCR	CALL	ILPRT
	DB	'++ Expected many C/Rs for '
	DB		'speed detect ++',CR,LF,0
	RET
;
;test for C/R entered, or loss of carrier
;
CKCR	CALL	KEYIN
	CPI	CR
	RZ
	INR	A		;ff means no carr
	RNZ
;
;no carrier found
;
NOCAR	CALL	MSGDIS
	DB	'++ No carrier seen ++',CR,LF,0
;
NOCR	CALL	MSGDIS
	DB	'++ No speed-detect C/Rs seen ++',CR,LF,0
;
MSGDIS	POP	H		;get msg addr
	JMP	PRDIS

;
;baud rate set subroutines for uds modem
;
;set speed to 110 baud, answer mode
;
SET110	MVI	A,'1'		;log '1'
	STA	SPEED
	MVI	A,7
	OUT	10H
	MVI	A,27H
	OUT	13H
	JMP	CKCR
;
;set speed to 300 baud, parity inhibit, 1 stop bit,
;answer mode
;
SET300	MVI	A,'3'
	STA	SPEED
	MVI	A,6
	OUT	10H
	MVI	A,27H
	OUT	13H
	JMP	CKCR
;
SET600	MVI	A,'6'
	STA	SPEED
	MVI	A,5
	OUT	10H
	MVI	A,27H
	OUT	13H
	JMP	CKCR
;
;
;routine to hang up phone
;
HANGUP	MVI	A,25H		;kill dtr.
	OUT	13H   		;hang up
HANGWT	IN	UDSST
	ANI	UDSCD		;still have carrier?
	JNZ	HANGWT		;yes, wait for it to go away
;
; delay a few seconds to make sure of clean disconnect
;
	LXI	H,0
	MVI	B,5*MHZ
HANGDLY	DCX	H
	MOV	A,H
	ORA	L
	JNZ	HANGDLY
	DCR	B
	JNZ	HANGDLY
	RET
;
;if running "reinit", await phone ring.
;
	IF	REINIT
RINGWT	MVI	A,27H
	OUT	13H
RINGWT1	IN	UDSST		;input hayes status port
	ANI	UDSRI		;ringing?
	JNZ	START
	IN	SSW		;go to start if remote
	ANI	REMOTE		;..switch turned off
	JZ	START
	JMP	RINGWT1
	ENDIF			;reinit
;
	IF 	XFER
;
RECVDG	IN	12H
	IN	12H
;
RECV:	PUSH	D
	MOV	A,B
	ADD	A
	MOV	B,A
MSEC:	LXI	D,0BBBBH
MWTI:	IN	13H
	ANI	2
	JNZ	MCHAR
	DCR	E ! JNZ	MWTI
	DCR	D ! JNZ MWTI
	DCR	B ! JNZ MSEC
	POP	D
	STC
	RET
;
MCHAR:	IN	12H
	POP	D
	PUSH	PSW
	ADD	C
	MOV	C,A
	POP	PSW
	ORA	A
	RET
SEND:	PUSH	PSW
SENDW:	IN	13H
	ANI	1
	JZ	SENDW
	POP	PSW
	OUT	12H
	RET
	LINK	CBBSXFER
	ENDIF
	IF	NOT	XFER
	LINK	CBBSWORK
	ENDIF
    