;CBBS V3.6.2 	CBBSSUB1.ASM - NON-DISK ROUTINES #1
;09/26/83 20:06:59
;	LINKS TO CBBSSUB2
;
;	O O O	O   O	O O	  O
;	O	O   O	O   O	O O
; CBBS	O O O	O   O	O O	  O	.ASM
;	    O	O   O	O   O	  O
;	O O O	O O O	O O	O O O
;
;MOD LOG: (THRU 3.2 PUT IN "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;
;
;N-O-T-E SUBROUTINES ALPHABETIZED 07/26/81
;(I GOT TIRED OF LOOKING FOR 'EM)
;
;	CTLCKS	DING	GETNUM	GETVAR	JUSTA	JUST5
;	PRDEC	DECHL	RDLINE	TYPEX
;
;
;-----> ROUTINE TO CHECK FOR ^C, K, OR S
;
;^C RETURNS ZERO INDICATOR; ^K ABORTS,
;AND JUMPS TO 'FUNCT' (OR ENCOMD IF IN MESSAGE
;ENTRY); ^S WAITS FOR NEXT CHR.  ^S IS
;TESTED FOR 1ST, SO USER CAN TYPE ^S THEN
;^K OR ^C.
;
CTLCKS	CALL	KEYCHR	;GET CHR
;
; 09/21/83 mod: must be "^N" to get nulls - not "N" or "n".
;
	CPI	'N'-40H	;SET NULLS?
	JZ	SETNUL
	ANI	1FH	;MAKE 'S' INTO ^S, ETC
	CPI	'S'-40H	;^S?
	CZ	KEYIN	;YES, WAIT FOR NEXT KEY
	ANI	1FH
	CPI	'K'-40H	;ABORT?
	JZ	CTLK	;CHECK IF ENABLED
	CPI	'C'-40H	;^C? (RET/ZERO SET)
	RET
;
;GOT ^N - INCREASE NULLS BY 5
;
SETNUL	LDA	NULLS
	ADI	5
	STA	NULLS
	ORA	A	;SET <>0 ^C CHECK
	sta	nullset	;set flag so we tell of nulls obtained.
	RET
;
;GOT ^K - SEE IF ENABLED
;
CTLK	LDA	CTLKSW
	ANI	7FH	;TURN OFf "PRINTING NO ^K" SW
	cpi	ctlkoff	;WAS IT 1?
	JZ	NCTLK	;	YES, DISALLOW
	lxi	sp,stack ;04/10/83 we're aborting so
			; prevent stack crash if multi-^K
	cpi	ctlkent	;2?
	JZ	ENCOMD	;	YES, RET. TO msg entry
	cpi	ctlkrtv	;3?
	JZ	RTVFE	;	YES, END FLAGGED RTRV
	cpi	ctlkfn	;4?
	JZ	getfn	;	YES, TO FIRST name Q.
	cpi	ctlkt1	;5?
	JZ	askt1	;	YES, TO FIRST time Q.
;
 if xfer
	cpi	ctlkmod	;6?
	JZ	mfunct	;	YES, to modem function.
 endif
;
	JMP	DEFUNCT	;	NO, just return to function prompt.
;
;TYPE THE 'NO ^K PERMITTED' MSG
;UNLESS WE ARE CURRENTLY PRINTING IT
;
NCTLK	LDA	CTLKSW	;ALREADY TYPING
	ORA	A	;	CAN'T ^K MSG?
	RM		;	YES, RETURN
	XRI	80H	;TURN ON 80H
	STA	CTLKSW
	PUSH	H
	PUSH	B
	LXI	H,NOCTLK
	CALL	TYPEM0	;TYPE MSG
	POP	B
	POP	H
	LDA	CTLKSW
	XRI	80H
	STA	CTLKSW
	XRA	A	;SO ^C ACTION TAKEN
	RET
;
; routine to ding the printer port (such as when twit signs on)
;
ding	equ	$
 if tty
	mvi	a,7		;"ding" to tell op
	call	log		;	twit just signed in
 endif
	ret
;
;-----> ROUTINE TO EXTRACT NUMBER FROM 'ANSWER'
;AND CONVERT TO BINARY.  ALSO JUST USED TO
;VALIDATE THAT A PROPER NUMBER HAS BEEN ENTERED.
;
GETNUM	LXI	H,0	;INIT RESULT
	LXI	D,ANSWER-1
GNLP	INX	D
	LDAX	D	;GET DIGIT
	CPI	CR
	RZ		;RETURN IF DONE
	CPI	','	;AS IN SUMMARY SEARCH?
	RZ
	call	ck09	;VALID number?
	jnc	GNOK
	MVI	A,CR	;GET CR,
	STA	INBUF	;KILL STACKED LINES
	CALL	ILPRT
	DB	'++Invalid number++',CR,LF,0
	STC
	RET
;
;DIGIT OK - ADD IT IN
;
GNOK	SUI	'0'	;MAKE NUMBER BINARY
	PUSH	D
	MOV	D,H
	MOV	E,L
	DAD	H	;X2
	DAD	H	;X4
	DAD	D	;X5
	DAD	H	;X10
	ADD	L	;ADD IN DIGIT
	MOV	L,A
	POP	D
	JNC	GNLP	;CARRY?
	INR	H	;ADD IN CARRY
	JMP	GNLP	;LOOP UNTIL C/R
;
;-----> ROUTINE TO INPUT A VARIABLE
;
;READS FROM KEYBOARD UNLESS IT IS IN THE BUFFER
;FROM A PREVIOUS ';' SEPARATOR.  TRANSLATES
;FROM LOWER TO UPPER CASE
;
;ENTRY POINT GETVARN READS FROM INBUF, AND
;DOESN'T TRANSLATE TO UPPER CASE, AND DOESN'T LOOK FOR
;SEMICOLONS TO SEPARATE LOGICAL LINES.
;
;CALLING SEQUENCE:
;	CALL	GETVAR
;	DB	'MESSAGE TO BE PRINTED',0
;	DW	ADDR OF VARIABLE
04;	DW	HELP MESSAGE # (-1 IF NONE) 03/04/81 MOD
;	DB	LENGTH OF VAR
;(ACTUAL VAR MUST BE 1 LONGER FOR THE CR)
;
GETVARN	MVI	A,CR	;GET FLAG
	STA	INBUF	;SHOW INPUT MUST BE READ
	JMP	GETVAR2
;
; input password (echoes 'X').  Save INBUF contents
;
getpass	mvi	a,1
	jmp	getvar1
;
;SET INFLG TO 0 TO SHOW THAT ';' IS TO BE
;HANDLED, AND THAT MESSAGE IS TO BE TRANSLATED
;TO UPPER CASE
;
GETVAR	xra	a
getvar1	sta	echopas
	XRA	A	;GET 0
GETVAR2	STA	INFLG	;handle ";"
	POP	H	;GET MESSAGE ADDR
	SHLD	GVREPT	;SAVE IF REPEAT REQUIRED
;
;FLUSH BUFFERS IF RUNNING UNDER FAST
;
	IF	FAST
	CALL	FLUSH
	ENDIF
 if 0		;just testing - not implemented	--------;
;							;
;	if reading a password, save the input buffer	;
;							;
	lda	echopas					;
	ora	a					;
	jz	getvr					;
	push	h					;
	lxi	h,inbuf		;save			;
	push	h					;
	lxi	d,wkbuf		;			;
	call	gpmv132		;	inbuf		;
	pop	h					;
	mvi	m,cr					;
	pop	h					;
;							;
	call	getvr		;process, return here..	;
;							;
	lxi	h,wkbuf		;restore		;
	lxi	d,inbuf		;			;
gpmv132	mvi	b,132		;			;
	jmp	move		;	inbuf		;
 endif							;
;
GETVR	LDA	INBUF	;HAVE TO INPUT IT?
	CPI	cr
	JNZ	GETNOI	;GET WITH NO INPUT
;HAVE TO INPUT
GETV00	CALL	TYPEX	;TYPE MESSAGE
	PUSH	H
;
; 10/10/82 mod: find length for ^L command to
;	print a "fill in the blanks line" based upon length.
;
	inx h ! inx h ! inx h ! inx h
	mov	a,m
	sta	length
;
	CALL	RDLINE	;READ A COMMAND LINE
	POP	H
	JMP	GETV
;ANS IN BUFFER - SKIP PROMPT MSG
GETNOI	call	skippz
;
;GET VARIABLE VALUE
;
GETV	MOV	E,M	;GET LO ADDR
	INX	H
	MOV	D,M	;GET HI ADDR
04	INX	H	;03/04/81 TEMP MOD -
04	INX	H	;	SKIP THE HELP #
	XCHG
	SHLD	GVTRUNC	;SAVE FOR TRUNCATE PRINT
	XCHG
	INX	H	;TO LENGTH
	MOV	A,M	;LENGTH
	STA	LENGTH
	MOV	C,A
	INR	C	;ADD IN FOR C/R
	INX	H	;GET RETURN ADDR
	PUSH	H	;SAVE FOR RETURN
	LXI	H,INBUF
	MOV	A,M
	STA	FIRSTCH	;SAVE FOR CASE TEST
;
;MOVE MESSAGE FROM INBUF TO VARIABLE.
;STORE CR AT END OF DATA RETRIEVED
;
GETMV	LDA	INFLG	;';' AND TRANSLATE?
	ORA	A	;SET FLAGS
	MOV	A,M	;GET CHR
	JNZ	NOUC	;NOT TRANSLATING
	CPI	';'	;IS IT THE DELIMITER?
	JNZ	GETND	;NO, NO DELIMITER
	MVI	A,CR	;FAKE UP C/R
GETND	CPI	'|'
06	JZ	NOUC	
	CPI	60H	;LOWER CASE CHR?
	JC	NOUC	;NO
	ANI	5FH	;MAKE UPPER CASE
NOUC	STAX	D	;SAVE IN OUTPUT
	INX	D
	INX	H
	CPI	CR
	JZ	GETMVD	;MOVE IS DONE
	DCR	C	;TOO LONG?
	JNZ	GETMV
;11/11/78 ADDED "TRUNCATE"
	DCX	D	;BACK UP
	MVI	A,CR
	STAX	D	;TRUNCATE
	PUSH	D	;SAVE C/R POINTER
	STA	INBUF	;CANCEL STACKED LINES
	CALL	ILPRT
	DB	'++LINE > ',0
;
;PRINT LENGTH IN DECIMAL
;
	LDA	LENGTH
	CALL	PRDEC	;PRINT (A) IN DECIMAL
	CALL	ILPRT
	DB	'  LONG - '
	DB	'truncated, ^U to re-enter: ',0
;
;05/07/79 PRINT TRUNCATED DATA
;10/14/82 make it "really nice", i.e. goes back to read line.
;
	LHLD	GVTRUNC
	POP	D		;GET C/R POINTER
	CALL	TRUNC
	lhld	gvtrunc		;point @ front of line
	lxi	d,inbuf
	mvi	b,0		;init char count
trunct	inr	b		;count the char
	mov	a,m
	stax	d
	inx	h
	inx	d
	cpi	cr
	jnz	trunct
	dcx	d		;set-up for ^R entry
	mov	h,d		;copy addr to hl
	mov	l,e
	mvi	m,'R'-40h	;set up for ^R
	call	rdctlr		;jmp middle of rdline.
	lhld	gvrept		;point to msg
	call	skippz		;skip past it
	pop	b		;kill old ret addr
	jmp	getv		;continue
;
;====>	TRUNC	GENERAL PURPOSE TRUNCATE TO A SPACE
;		HL = START OF C/R DELIMITED LINE
;		DE = END OF LINE
;
TRUNC	PUSH	H	;SAVE POINTER
TRUNCCR	MOV	A,M
	CPI	' '
	JNZ	TRUNS
	MOV	D,H	;SAVE ADDR
	MOV	E,L	;
TRUNS	INX	H
	CPI	CR
	JNZ	TRUNCCR
	STAX	D	;SET AT LAST SPACE OR BACK
;			 WHERE IT WAS
	POP	H
	RET
;
;ANSWER HAS BEEN MOVED - MOVE THE NEXT ENTRY
;IN INBUF UP TO THE FRONT.
;
GETMVD	LXI	D,INBUF
	DCX	H	;BACK UP TO CR OR ';'
	MOV	A,M	;GET DELIM
	CPI	CR	;REAL END?
	JZ	GETMV2	;JUST MOVE IN CR, RETURN
	INX	H	;SKIP ';'
GETMV2	MOV	A,M	;GET CHR
	STAX	D	;SAVE IT
	INX	D
	INX	H
	CPI	CR	;MOVED ALL?
	JNZ	GETMV2
;
;CHECK IF "X" ENTERED, AND TOGGLE EXPERT
;MODE, AND RE-ASK QUESTION, IF SO.
;
	LHLD	GVTRUNC	;POINT TO DATA
	MOV	A,M	;GET FIRST CHAR
	ANI	5FH	;MAKE UPPER CASE
	CPI	'X'	
	RNZ		;NOT X
	INX	H	;POINT TO SECOND CHAR
	MOV	A,M	;GET IT
	CPI	CR	;IF NOT C/R, THEN
	RNZ		;	RETURN
;
;GOT "X", TOGGLE EXPERT MODE (U-N-L-E-S-S
; BEING CALLED FROM "HELP" COMMAND)
;
	LDA	INHELP	;ARE WE "IN HELP"?
	ORA	A
	RNZ		;YES, RETURN
	CALL	TOGGLEX
	pop	h	;kill stacked ret addr
	LHLD	GVREPT
	JMP	GETVR	;RE-ASK, HAVING FLIPPED X
;
; ====> echo a char unless password mode, in which case echo 'X'
;
typepas	push	b		;save bc
	mov	b,a		;save char
	lda	echopas		;get flag
	ora	a		;test it
	mov	a,b		;get back char
	pop	b		;restore bc
	jz	type		;type if not pass
	mvi	a,'x'
	jmp	type
;
;-----> RIGHT JUSTIFY MESSAGE NUMBER, FROM
;WHAT HL POINTS TO, TO "MSGNO"
;
JUSTA	LXI	H,ANSWER ;COME FROM ANSWER
JUST5	mov	a,m		;test for "*" meaning
	cpi	'*'		;prev hi
	jz	justprv
	cpi	'N'		;"N"ew i.e. prev hi?
	jz	justprv
	cpi	'#'
	jz	justmrk		;got marked msg #.
	PUSH	H	;SAVE POINTER
	XCHG		;SET UP
	DCX	D	;	FOR GETNUM
	CALL	GNLP	;ENTR MIDDLE TO VALIDATE #
J5CK	POP	H
	RC		;INVALID
	PUSH	H
	MVI	B,0FFH	;"-1"
J5C	INR	B
	MOV	A,M
	CPI	','	;AS AT START OF SEARCH
	JZ	J5C2	;	STRING?
	CPI	CR
	INX	H
	JNZ	J5C
J5C2	POP	H
	MOV	A,B
	CPI	5
	JZ	J5M	;END, MOVE IT
	CMC		;CARRY IF >5
	RC		;	RET IF TOO MANY
J5R	PUSH	H	;SAVE POINTER
	MVI	B,'0'	;INIT "PREV" CHAR
;
;MOVE THE # RIGHT ONE, PADDING '0' ON LEFT
;
J5R1	MOV	A,M	;GET CHAR
	MOV	M,B	;STORE PREV
	MOV	B,A	;SAVE FOR NEXT MOVE
	INX	H
	CPI	CR
	JNZ	J5R1
	MOV	M,B	;STORE THE C/R
	JMP	J5CK	;REPEAT IF NECESSARY
;
; got "#" - use previously marked msg
;
justmrk	inx	h		;to mark number
	mov	a,m
	call	ck09
	rc
	sui	'0'		;make binary
	stc			;disallow
	rz			;	'0'
	lxi	h,markcnt	;valid marked #?
	dcr	a		;so cmp sets carry if OK
	cmp	m
	jnc	jmntb
	call	compmrk		;compute mark addr
	jmp	j5m		;move the marked #
;
; compute marktbl entry addr based on (a) which is #-1
;
compmrk	mov	b,a		;save for mult.
	add	a		;x2
	add	a		;x4
	add	b		;x5: displ now in (A)
	lxi	h,marktbl	;table base to hl
	mov	e,a		;set up de
	mvi	d,0		;as displ
	dad	d		;add displ to base
	ret
;
; marked # too big (ex: 3 marked, but said #4)
;
jmntb	call	ilprt
	db	'++ Mark # too big, max =',0
	lda	markcnt
	call	prdec
	call	crlf
	stc			;show error
	ret
;
; got "*" - use previous high as msg #
;
justprv	lxi	h,prevhi
	mov	a,m
	ora	a
	jnz	j5m
	call	ilprt
	db	'++ No prev hi msg # ++',cr,lf,0
	jmp	defunct
;
;MOVE # TO MSGNO
;
J5M	LXI	D,MSGNO	;MOVE IT
	call	MOVE5	;	to MSGNO
	ora	a	;	show no error
	ret
;
; 10/13/82 Take number in (hl), and "overlay" it upon the
; number in MSGNO.  Allows: r;12345;6;7;56;7;8;00001;2;3
;	Also in missed flagged retrieve: ;200;1;2..
;
justr	mov	a,m
	cpi	'*'
	jz	justprv		;justify prev hi.
	cpi	'N'
	jz	justprv		;justify prev hi.
	cpi	'#'
	jz	justmrk		;got marked msg #.
	call	jrvalid		;validate & count digits
	rc			;ret if bad
	lxi	d,msgno+4	;to low digit
jrmv	mov	a,m		;get a digit
	stax	d		;store it
	dcx	h		;back up "from"
	dcx	d		;back up "to"
	dcr	b		;more?
	jnz	jrmv		;	yes, loop
	ret
;
; subroutine to validate and count digits in answer.
; if > 5, or non numeric, returns carry.  
;
jrvalid	mvi	b,0		;# of digits
jrvlp	mov	a,m
	mov	c,a		;save for ',' test
	cpi	cr		;ret if c/r
	jz	jrvzck
	cpi	','		;	or ','
	jz	jrvzck
	call	ck09
	rc			;	ret w/carry
	inx	h		;to next
	inr	b		;count it (tested @ jrvzck)
	jmp	jrvlp
;
; ensure non-zero number of digits
;
jrvzck	dcx	h		;back to last digit
	mov	a,b
	ora	a
	stc
	rz
	ora	a
	ret
;
; check (a) for 0-9, set carry if not
;
ck09	cpi	'0'
	rc			;carry if < '0'
	cpi	'9'+1		;carry if '0'-'9'
	cmc			;no "	"	"
	ret
;
;====>	PRINT (A) IN DECIMAL.
;		ALSO STORES IT IN "DECNUM"
;
PRDEC	call	convdec		;convert to decimal
	push	h
	lxi	h,decnum
	call	typemcr		;	& print
	pop	h
	ret
;
;====>	convert (A) to decimal in DECNUM with leading ' '
;
convdec	PUSH	H
	LXI	H,DECNUM
	push	h
	MVI	C,100
	CALL	PRDECS
	MVI	C,10
	CALL	PRDECS
	ORI	'0'
	MOV	M,A	;SAVE LAST DIGIT
	pop	h
	call	prdsp	;store ' ' if it is 0
	cz	prdsp	;	and again if first was 0
	POP	H	
	ret
;
;	Blank out leading zeros by storing a space and 
;	returning with zero set and HL incremented if char(hl) = "0"
;
prdsp	mov	a,m
	cpi	'0'
	rnz
	mvi	m,' '
	inx	h
	ret
;
;PRINT DIGIT AS CONVERTED FROM BINARY TO DECIMAL
;
PRDECS	MVI	B,'0'-1
PRDECL	INR	B	;BUMP ASCII
	SUB	C
	JNC	PRDECL	;SUBTRACT MADE IT
	ADD	C	;BACK OUT LAST SUB
PRDEC2	PUSH	PSW	;SAVE NUMBER
	MOV	A,B	;GET ASCII
	MOV	M,A	;SAVE IN MEM
	INX	H	;TO NEXT
;	CALL	TYPE	;TYPE IT	;no longer type,
	POP	PSW	;RESTORE PARTIAL # (allow ' ' leadin)
	RET
;	________
;
; print (hl) in decimal, max 999 (DIR uses this for file size)
;
dechl	push	b
	push	d
	mvi	d,0		;init zero suppress flag
	lxi	b,-100		;first char
	call	dhlsub
	lxi	b,-10
	call	dhlsub
	mov	a,l
	adi	'0'
	call	type
	pop	d
	pop	b
	ret
;
dhlsub	mvi	e,'0'-1
dhllp	inr	e
	dad	b
	jc	dhllp
	mov	a,l
	sub	c
	mov	l,a
	mov	a,h
	sbb	b
	mov	h,a
	mov	a,e		;get char to type
	inr d ! dcr d		;zero suppressed?
	jnz	dhlzero		;	n/type it
	cpi	'0'		;zero?
	jnz	dhlzero		;	n/type, turn off zero supp
	mvi	a,' '		;zero suppressed - print a ' '
	jmp	dhlsp
;
dhlzero	inr	d		;kill zero suppress flag
dhlsp	call	type
	ret
;	________
;
;---->	ROUTINE TO READ IN LINE TO INBUF
;	(MAIN ENTRY 20 LINES DOWN)
;
RDLNCU	MVI	A,'^'	;ECHO '^U' FOR ^U
	CALL	TYPE
	MVI	A,'U'
	CALL	TYPE
;
 IF TTY
	MVI	A,'^'
	CALL	LOG
	MVI	A,'U'
	CALL	LOG
	MVI	A,CR
	CALL	LOG	;OUTPUT CR TO LOG
 ENDIF
;
RDLNCR	CALL	CRLF
;
;====>	RDLINE MAIN ENTRY POINT <====
;
RDLINE	LDA	BELLF	;PROMPT
	ANI	1	;	BELL REQD?
	MVI	A,7	;BELL
	CNZ	TYPE
	MVI	A,'?'
	CALL	TYPE
RDLP0	MVI	B,1	;CHR COUNT
	LXI	H,INBUF
RDLP	CALL	KEYIN	;GET A CHR
;
RDLTEST	MOV	M,A	;SAVE STORING IT LATER
;
;09/13/81 TEST FOR USER-ASSIGNED VIDEO BACKSPACE
;
	PUSH	H
	LXI	H,BSCHAR
	CMP	M
	POP	H
	JZ	RDVBS
;09/13/81 END
;
;TEST FOR NON-VIDEO DELETES
;
; 10/10/82 allow "_" as regular char, not delete.
;
;	CPI	'_'	;ASCII BACK ARROW??
;	JZ	RDDEL	;YES, TREAT AS DEL
	CPI	7FH	;DEL?
	JZ	RDDEL	;GOT DEL
	CPI	' '	;PRINTABLE?
	JC	RDLNCTL	;	NO, A CTL CHAR
;
;GOT PRINTABLE CHAR
;
RDECHO	INX	H
	INR	B	;SET MINUS IF
	JM	RDFULL	;BUFFER IS FULL, ECHO BELL
	PUSH	B	;SAVE CHR
	MOV	B,A	;	IN B
	LDA	ECHOFLG
	ORA	A
	MOV	A,B	;GET CHR
	CNZ	typepas	;ECHO IF FDX, NOT IF HDX, 
;				echo 'X' if password
	MOV	A,B	;GET CHR
	POP	B
;
 IF TTY
	CALL	LOG	;LOG IT
 ENDIF
;
;IF AT 75 CHRS, ECHO A BELL, WHETHER PROMPT
;	(BELL) FLAG IS ON OR NOT
;
	MOV	A,B
	CPI	75		;was 55 for 64-wide
	JNZ	RDLP
	JMP	RDBELL
;
;BUFFER IS FULL - ECHO BELL, BACK UP
;
RDFULL	DCR	B	;05/07/79 ADDED
	DCX	H	;BACK UP POINTER
RDBELL	MVI	A,7
	CALL	TYPE
	JMP	RDLP	;BACK UP
;
;====>	PROCESS ALL CONTROL CHARACTERS <====
;
RDLNCTL	CPI	'E'-40H
	JZ	RDCTLE	;LOGICAL C/R
	CPI	'H'-40H
	JZ	RDVBS	;VIDEO BACKSPACE
	CPI	'I'-40H
	JZ	RDTAB
	CPI	'K'-40H	;ABORT?
	JZ	RDCTLK
	CPI	'L'-40H	;"WHAT COL AM I IN?"
	jz	fillinb		;generate "________"
	CPI	'M'-40H	;(C/R?)
	JZ	RDLCR	;YES, DONE
	CPI	'R'-40H	;^R?
	JZ	RDCTLR
	CPI     'U'-40H ;^U?
	JZ	RDLNCU
	CPI     1bh		;esc?
	JZ	RDLNCU
	CPI	'W'-40H
	JZ	RDDELW	;WORD BACKSPACE
	CPI	'X'-40H
	JZ	RDDELX
;
;UNKNOWN CONTROL CHARACTER - beep
;
	JMP	rdbell	;IGNORE IT
;
;====>	CONTROL CHAR PROCESSING IN RDLINE
;
;
; DEL:	NON-VIDEO CHAR DELETE.
;	ECHO CHARS BETWEEN '\'S
;
RDDEL	DCR	B	;ALREADY AT FRONT?
	JZ	RDLP0	;	YES, NO ECHO
	INR	B
	CALL	RDBKS	;ECHO & LOG '\'
RDDELL	DCX	H
	DCR	B
	JZ	RDDELB	;BACKED UP TO BEGINNING
;
	IF	TTY
	MOV	A,M
	CALL	LOG
	ENDIF
;
	MOV	A,M	;GET DELETED CHAR
	CALL	TYPE	;	ECHO IT
;
;GET NEXT CHR, KEEP DELETING IF IT'S A DEL
;
	CALL	KEYIN
	CPI	7FH
	JZ	RDDELL	;KEEP ECHOING
	CPI	8	;ASCII BKSP?
	JZ	RDDELL
;	CPI	'_'
;	JZ	RDDELL
	PUSH	PSW	;SAVE CHR
	CALL	RDBKS	;ECHO FINAL '\'
	POP	PSW
	JMP	RDLTEST
;
;BACKED UP TO BEGINNING.  ECHO '\' THEN CRLF
;
RDDELB	CALL	RDBKS	;TYPE '\'
	JMP	RDLP0
;
;SEND '\' TO USER AND LOG
;
RDBKS	EQU	$
	MVI	A,'\'
	CALL	TYPE
;
	IF	TTY
LOGDEL	MVI	A,ttybs	;02/27/83 mod - I want ^H to be sent
	CALL	LOG	;LOG ALL DELETES
	ENDIF
;
	RET
;
;SEND BACKSPACE-SPACE-BACKSPACE TO VIDEO
;	TERMINAL TO ENSURE CHAR IS ERASED
;
RDBSB	MVI	A,8	;ASCII BS ' ' BS
	CALL	TYPE
	CALL	SPACE
 IF TTY
	CALL	LOGDEL	;LOG DELETED CHAR
 ENDIF
	MVI	A,8
	JMP	TYPE
;
;^E	LOGICAL C/R
;
RDCTLE	CALL	CRLF
	JMP	RDLP
;
;^H	VIDEO BACKSPACE
;
RDVBS	DCR	B
	JZ	RDLP0	;AT FRONT ALREADY
	CALL	RDBSB	;BS/SPACE/BS
	DCX	H
	JMP	RDLP
;
;^I	TAB
;
RDTAB	CALL	SPACE
	MVI	M,' '
	INX	H
	INR	B
	JM	RDFULL
	MOV	A,B
	DCR	A
	ANI	7
	JNZ	RDTAB
	JMP	RDLP
;
;^K	ABORT IF AT START OF LINE
;
RDCTLK	MOV	A,B	;GET COUNT
	DCR	A	;AT START?
	JNZ	RDLP	;	NO, IGNORE IT
	LDA	CTLKSW	;SEE IF ^K
	ORA	A	;	PERMITTED
	JNZ	RDLP	;NOT PERMITTED, IGNORE
;
;^K PERMITTED.  ECHO IT, AWAIT C/R
;
	MVI	A,'^'
	CALL	TYPE
	MVI	A,'K'
	CALL	TYPE
	CALL	KEYIN
	CPI	'U'-40H
	JZ	RDLNCU
	CPI	CR
	JZ	DEFUNCT	;KILL INBUF, GO TO FUNCT
	JMP	RDLTEST	;PROCESS THE CHAR
;
;^M	(C/R)
;
RDLCR	CALL	CRLF
;
	IF	TTY
	MVI	A,CR
	JMP	LOG
	ENDIF
;
	RET		;BUFFER HAS BEEN READ
;
;^R	RETYPE LINE
;
RDCTLR	PUSH	B
	PUSH	H
	CALL	CRLF
	MVI	B,'R'-40H ;ENDING CHAR
	LXI	H,INBUF ;PRINT
	CALL	TYPEM	;	THE BUFFER
	POP	H
	POP	B
	JMP	RDLP
;
;^W: VIDEO WORD DELETE
;
RDDELW	MVI	C,1	;SHOW IN WORD BACKSPACE
	JMP	RDDELWX
;
;^X: VIDEO LINE DELETE
;
RDDELX	MVI	C,0	;SHOW NOT END OF WORD
;
RDDELWX	DCR	B	;BACK TO BEGINNING?
	JZ	RDLP0	;YES
	DCX	H
	PUSH	B	;TYPING CLOBBERS C
	CALL	RDBSB	;BS/SP/BS
	CALL	CTLCKS	;ALLOW ABORT FROM
	POP	B
	JZ	RDLP	;	^2-ING A LONG WORD
	MOV	A,C	;ARE WE
	ORA	A	;	LINE BACKSPACING?
	JZ	RDDELWX	;	YES.
	DCX	H	;HAVE WE
	MOV	A,M	;	BACKED UP
	INX	H	;	TO
	CPI	' '	;	A ' '
	JZ	RDLP	;		(YES)
	CPI	';'	;	OR ';'?
	JZ	RDLP	;		(YES)
	JMP	RDDELWX	;	(NO), LOOP
;
; ====>	10/10/82 routine to type "_____" as a fill-in-the
;	blanks based upon length requested.
;
fillinb	mvi	m,0		;store ending char
	push	b
	push	h
;
; echo ^L
;
	mvi	a,'^'		;echo
	call	type		;	the
	mvi	a,'L'		;	^L
	call	type		;
;
; crlf and type line of "____"
;
	call	crlf		;start @ new line
	lda	length		;get input var. length
	mov	b,a		;save it
flbl	mvi	a,'_'		;type
	call	type		;	one "_"
	dcr	b		;more?
	jnz	flbl		;	y/loop
;
; CR and overtype what has already been keyed
;
	mvi	a,cr		;n/send 
	call	type		;	C/R
	lxi	h,inbuf		;print what has been
	call	typem0		;
	pop	h
	pop	b
	jmp	rdlp		;go prompt for input
;
;ROUTINE TO TYPE BUFFER, AS IN WHEN A
;QUESTION IS ASKED.  IF THE 'EXPERT USER' FLAG
;IS SET, THEN IT STOPS AT THE FIRST ':' IN
;THE MESSAGE.
;
TYPEX	LDA	EXPERT	;EXPERT USER?
	ORA	A
	JZ	TYPEM0	;NO, JUST TYPE LINE
TYPEX2	MOV	A,M	;GET CHAR
	INX	H
	ORA	A	;END (=0)?
	RZ		;YES, RET
	PUSH	PSW	
	CALL	TYPE
	POP	PSW
	CPI	':'
	JNZ	TYPEX2
;END OF EXPERT PROMPT, SKIP TO END OF MSG
;
; 10/10/82 label was typex3, make it a subroutine
;	to skip past zeros in m(hl)
;
SKIPPZ	MOV	A,M
	INX	H
	ORA	A
	JNZ	SKIPPZ
	RET
;
	LINK	CBBSSUB2 ;TO NEXT .ASM FILE
                                                                   