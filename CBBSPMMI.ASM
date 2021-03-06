;CBBS V3.6.2 	CBBSPMMI.ASM - PMMI MODEM
;09/21/83 19:23:46
;
;	LINKS TO CBBSWORK, CBBSXFER, OR CBBSWARD
;
;	O O O	O   O	O   O	O O O
;	O   O	OO OO	OO OO	  O
; CBBS	O O O	O O O	O O O	  O	.ASM
;	O	O   O	O   O	  O
;	O	O   O	O   O	O O O
;
;	CONNECT	DELAY	DELLP	GOTCAR	TRY1
;	CKCR	NOCAR	NOCON	SET110	SET300
;	SET450	SET600	SETBAUD	SETB2	HANGUP
;	hanglp	RINGWT	
;
;MOD LOG: (THRU 3.2 WRITTEN TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;
;09/05/83 Add carrier detect code.
;06/22/83 Move base port equate to CBBS.ASM
;03/31/83 Default 300 if no C/Rs seen
;11/27/82 call motor on subroutine in CBBS.ASM
;10/09/82 add char in and out for file xfer
;10/05/82 Change hangup routine to not send break; also
;	  that means no carrier detect is seen on a bad
;	  call or a hangup.
;10/03/82 double carrier wait from 15 sec to 30 because 4MHz
;09/26/82 add link to "cbbsward" if "ward's"
;
;
;PMMI MODEM BOARD EQUATES
;
;PMMIB	EQU	0C0H		;BASE ADDRESS (Moved to CBBS.ASM)
;
PMMIUST	EQU	PMMIB		;UART STATUS PORT ADDRESS
;
;	INPUT BITS IN PMMIUST
;
	PMMIDAV	EQU	2	;DATA AVAILABLE
	PMMITBE	EQU	1	;XMIT BUFF EMPTY
;
;	OUTPUT BITS FOR PMMIUST
;
	PMMIANS	EQU	2	;ANSWER MODE
	PMMI81	EQU	1CH	;8 DATA BITS, 1 STOP
	PMMI82	EQU	5CH	;8 DATA BITS, 2 STOP
;	----
PMMIDAT	EQU	PMMIB+1		;DATA PORT ADDRESS
;
PMMIMST	EQU	PMMIB+2		;MODEM STATUS PORT
;
;	INPUT BITS IN PMMIMST
;
	PMMICTS	EQU	4	;(NOT) CTS (I.E. CARRIER)
	PMMIRI	EQU	2	;(NOT) RING INDICATOR
;
PMMIBRT	EQU	PMMIMST		;BAUD RATE PORT
;
PMMIMCT	EQU	PMMIB+3		;MODEM CTL OUTPUT
;
;	OUTPUT BITS FOR PMMIMCT
;
	PMMILS	EQU	7FH	;LOW SPD (<=300)
	PMMIHS	EQU	5FH	;HI SPD (>300)
	PMMINST	EQU	10H	;Not self test - for hangup
;
PMMI110	EQU	15625/110 	;VARIOUS
PMMI300	EQU	15625/300 	;	BAUD
PMMI450	EQU	15625/450 	;	RATES
PMMI600	EQU	15625/600
;
;When going off hook, the answer phone
;bit is turned on, but after carrier is
;found it is turned off.  This allows the
;pmmi to hang up on loss of carrier by
;itself.  The BIOS character in/out routines
;test for loss of carrier, and for the bit
;saying that the modem chip has hung up.
;this is an automatic 15 second loss test.
;
;ROUTINE TO CONNECT TO THE CALLER
;
CONNECT	EQU	$
 if motctl
	call	motoron		;turn on drive motors
 endif
;
	MVI	A,PMMILS 	;DTR ON 
	OUT	PMMIMCT		;	TO MODEM CTL PORT
	MVI	A,PMMI82+PMMIANS ;ANS PHONE
	OUT	PMMIUST		;	TO UART PORT
;
	MVI	B,15*mhz	;APPROX # SEC. DELAY
DELAY	LXI	H,9A00H		;1 SEC DELAY @ 2mHz
DELLP	call	ckcarr		;check for carrier
	JZ	GOTCAR		;EXIT LOOP IF CARRIER FOUND
	DCX	H		;DECR. LOOP COUNT
	MOV	A,H
	ORA	L
	JNZ	DELLP
;DELAYED ANOTHER SECOND, MORE SECONDS?
	DCR	B		;DCR SECONDS
	JNZ	DELAY		;YES
	JMP	NOCAR
;
; 09/05/83 CHECK CARRIER - returns zero if carrier
;
ckcarr	in	pmmimst
;	cma			;oops - not needed to return 0
	ani	pmmicts
	ret
;
;LOOK FOR C/R AT EACH SPEED
;
GOTCAR	MVI	A,10+1		;10 TRIES FOR C/R
	STA	TRIES
;
;QUIT IF NO C/R HAS BEEN READ AFTER 10 TRIES
;
TRY1	CALL	SET110
	CZ	CKCR		;GET SECOND C/R
	RZ
	CALL	SET300
	CZ	CKCR		;GET SECOND C/R
	RZ
;
	lda	tries		;tries
	dcr	a		;	= tries-1
	sta	tries
	jz	nocr		;if tries = 0, no c/r seen
	cpi	5		;if tries = 5, send msg
	cz	tellcr		; telling them to hit c/r
;
	CALL	SET450
	CZ	CKCR
	RZ
	CALL	SET600
	CZ	CKCR
	RZ
;
;READ 110 A SECOND TIME.  OTHERWISE 110 C/R READ
;AT 600 WILL FAIL AND CAUSE INVALID 110 C/R TOO
;
	CALL	SET110
	CZ	CKCR		;GET SECOND C/R
	RZ
	JMP	TRY1		;TRY 10 TIMES
;
; no c/r's seen, default 300 baud, type msg
;
tellcr	call	ilprt
	db	'++ Expecting MANY C/Rs (NO LFs!) for '
	db		'speed detect ++',cr,lf,0
	ret
;
;TEST FOR C/R ENTERED, OR LOSS OF CARRIER
;
CKCR	CALL	KEYIN
	CPI	CR
	RZ
	INR	A		;FF MEANS NO CARR
	RNZ
;
;NO CARRIER FOUND
;
NOCAR	call	msgdis
	db	'++ No carrier seen ++',cr,lf,0
;
nocr	call	msgdis
	db	'++ No speed-detect C/Rs seen ++',cr,lf,0
;
msgdis	pop	h		;get msg addr
	jmp	prdis
;
;SET SPEED TO 110 BAUD - PARITY INHIBIT, 2 STOP BITS,
;ANSWER MODE
;
SET110	MVI	A,PMMI82	;8 DATA, 2 STOP, NO PARITY
	OUT	PMMIUST
	MVI	A,PMMILS	;LOW SPEED DTR
	OUT	PMMIMCT		;TO MODEM CTL PORT
	MVI	A,PMMI110
	OUT	PMMIBRT
	MVI	A,'1'
	STA	SPEED
	JMP	CKCR		;CHECK FOR C/R
;
;SET SPEED TO 300 BAUD, PARITY INHIBIT, 1 STOP BIT,
;ANSWER MODE
;
SET300	MVI	A,PMMI81	;8 DATA BITS, 1 STOP, NO PARITY
	OUT	PMMIUST
	MVI	A,PMMI300
	OUT	PMMIBRT
	MVI	A,'3'
	STA	SPEED
	JMP	CKCR
;
SET450	MVI	A,PMMIHS	;HI SPEED DTR
	OUT	PMMIMCT		;TO MODEM CTL
	MVI	A,PMMI450
	OUT	PMMIBRT
	MVI	A,'4'
	STA	SPEED
	JMP	CKCR
;
SET600	MVI	A,PMMI600
	OUT	PMMIBRT
	MVI	A,'6'
	STA	SPEED
	JMP	CKCR
;
;SET BAUD RATE, BINARY VALUE IN C
;(FROM ALTBAUD COMMAND)
;
SETBAUD	MOV	A,C		;GET RATE
	OUT	PMMIBRT
	CPI	PMMI300		;	IF > 300
	MVI	A,PMMIHS	;HI SPEED DTR
	JC	SETB2
	MVI	A,PMMILS	;LOW SPEED
SETB2	OUT	PMMIMCT		;TO MODEM CTL
	CALL	KEYIN		;AWAIT A CHAR
	JMP	FUNCT
;
;ROUTINE TO HANG UP PHONE
;
HANGUP	XRA	A
	OUT	PMMIUST		;ON HOOK
	MVI	A,PMMINST	;	DON'T BREAK, BUT
	OUT	PMMIMCT		;KILL DTR
;
; 10/07/82 added delay to ensure no carrier detecteable
; when returning from "hangup" routine.
;
	mvi	b,5*MHz
hanglp	dcx	h
	mov	a,h
	ora	l
	jnz	hanglp
	dcr	b
	jnz	hanglp
	RET
;
;WAIT FOR PHONE TO RING IF RE-INIT
;
 if reinit
RINGWT	IN	PMMIMST		;INPUT STATUS PORT
	ANI	PMMIRI		;RINGING?
	JZ	START
	call	rdssw		;see if remote mode
	JZ	START
	JMP	RINGWT
 ENDIF				;REINIT
;
; routines to set 1 or 2 stop bits on the fly
;
stop1	MVI	A,PMMI81	;8 DATA BITS, 1 STOP, NO PARITY
	jmp	stop12
;
stop2	MVI	A,PMMI82	;8 DATA BITS, 2 STOP, NO PARITY
stop12	OUT	PMMIUST
	jmp	funct
 if xfer
;
; receive with garbage collect 
;	(flush any waiting chars)
;
RECVDG	IN	PMMIDAT
	IN	PMMIDAT
;
; receive a char for file transfer, with timeout in b
;
RECV	PUSH	D
	mov	a,b		;4MHz: double the time.
	add	a
	mov	b,a
MSEC	LXI	D,0bbbbh
;	CALL	CKABORT		;is this needed?
MWTI	IN	PMMIUST	
	ANI	PMMIDAV
	JNZ	MCHAR
	DCR	E ! JNZ MWTI
	DCR	D ! JNZ MWTI
	DCR	B ! JNZ MSEC	;another second
	POP	D
	STC			;show timeout
	RET
;
MCHAR	IN	PMMIDAT
	POP	D
	PUSH	PSW
	ADD	C
	MOV	C,A
	POP	PSW
	ORA	A
	RET
;
; send a byte to the modem (used only in file transfer 
;	mode - the BIOS is used for all other I/O.
;
SEND	PUSH	PSW
SENDW	IN	PMMIUST
	ANI	PMMITBE
	JZ	SENDW
	POP	PSW
	OUT	PMMIDAT
	RET
;
	link	cbbsxfer
 endif
;
 if wards
	link	cbbsward
 endif	
;
	LINK	CBBSWORK 	;NEXT .ASM FILE
                          