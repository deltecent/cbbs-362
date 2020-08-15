;CBBS V3.6.2 	CBBSRTRV.ASM - RETRIEVE
;06/23/83 22:19:16
;	LINKS TO CBBSOPER
;
;	O O	O O O	O O	O   O
;	O   O	  O	O   O	O   O
; CBBS	O O	  O	O O	O   O 	.ASM
;	O O	  O	O O	 O O
;	O   O	  O	O   O	  O
;
;		----------------
;the files containing the messages have the
;file name 'MESSAGE' and the filetype  'XNN'
;Where NN is the last 2 digits of the message
;number, rounded based on the value of "FILEDIV"
;(SEE DESCRIPTION IN CBBS.ASM), AND 'X' IS A LITERAL
;'X'.  THUS, IF "FILEDIV" IS 2, MESSAGE 12345
;WILL BE WRITTEN TO FILE MESSAGE.X44
;
;EACH MESSAGE IS PRECEEDED BY A BELL CHAR
;(NOT KEYABLE BY THE USER).
;
;MOD LOG: (THRU 3.2 WRITTEN TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.x TO "HISTORY.03x"
;
;====>	RETRIEVE FLAGGED MESSAGES
;
RTRVFLG	MVI	A,ctlkrtv	;SET SO ^K TURNS OFF RETRIEVE
				;	(goes to RTVFE)
	STA	CTLKSW		;	BY STORING 0 INTO FlagPtr
	CALL	ILPRT
	DB	CR,LF,'Retrieving flagged msgs: '
	DB	'C skips, K aborts.',CR,LF,0
	jmp	rtrv
;
; Many people type "R" when already "in" retrieve. 
; It then says "invalid number".  This is an improvement:
;
rign	call	ilprt
	db	'++ Already in retrieve, "R" ignored ++',cr,lf,0
;			
;====>	MAIN ENTRY - RETRIEVE MSGS
;
RTRV	mvi	a,1		;set first time
	sta	tries		;	switch
rtvnxf	xra	a		;blow away
	sta	fcb+1		;	knowledge of file
;
rtvnxt	LDA	RTOGO	;MORE TO RETRIEVE?
	ORA	A
	JZ	RTVG
	DCR	A
04	JP	RTVST	;RETRIEVE NEXT
04	ADI	2	;UN-DO DCR, +1
	JMP	RTVST	;RETRIEVE PREV
;
RTVG	LHLD	FlagPtr	;ANY FLAGGED?
	MOV	A,H
	ORA	A
	JNZ	RTVF
;
;	pre-scan the stacked input buffer, so message numbers
;	separated by " " or "," may be handled.
;
	lxi	h,inbuf
	mov	a,m
	cpi	cr
     	jz	rtvg2		;no stacked answers
;
;	step 1: skip valid #
;
rtvscan	mov	a,m
	inx	h
	call	ck09
	jnc	rtvscan
;
;	step 2: if ' ' or ',' change to ;
;
	cpi	' '
	jz	rtvgs
	cpi	','
	jnz	rtvg2	;not # or ' ' or ',', go process it.
;
;	got ' ' or ',' following a #, change it to a ";"
;
rtvgs	dcx	h
	mvi	m,';'
	inx	h
	jmp	rtvscan
;
rtvg2	CALL	GETVAR
	DB	CR,LF,'Msg #: to retrieve (C/R when done)',0
	DW	answer
	DW	17		;HELP MSG #
	DB	5		;MSG # LEN
	LDA	answer		;JUST
	CPI	CR		;	C/R?
	JZ	FUNCT		;	YES, EXIT
	cpi	'R'		;Another 'R'?
	jz	rign		;	yes, ignore
	CPI	'+'		;REQUEST TO
	JNZ	RTVNPL		;	DUMP NEXT 10?
02;COMMENT OUT NEXT 3
;	LDA	PASSFLG
;	ORA	A
;	JNZ	RTVNPL
	MVI	A,10		;RETRIEVE BLOCK OF 10
RTVST	STA	RTOGO		;SAVE 10 OR -10
;
;	catch "+nn" usage error
;
	push	psw
	lxi	h,answer+1
	mov	a,m
	cpi	cr
	jz	rincr		;ok, + or - is followed by cr.
	dcx	h
	mov	a,m
	sui	'-'		;if its not minus,
	jnz	rtvnrel		;	tell of error
;
;	said -nn, so back up that far from high msg #
;
	sta	rtogo		;cancel -10 default
	mvi	m,'0'		;overlay '-'
	call	justa		;right justify
	jc	rtvg		;# was bad
;
;	save hi msg # in Savmsg because don't want
;	to permanently change it.
;
	lxi	h,highmsg
	lxi	d,savmsg
	call	move5
;
;	subtract amt from hi msg
;
	lxi	d,savmsg+4
	lxi	h,msgno+4
	call	ascisub
;
;	move the # back to msgno for retrieval
;
	lxi	h,savmsg
	lxi	d,msgno
	call	move5
;
;	continue the retrieve with the specified msg #
;
	jmp	rtvok		;get that msg
;
;
;	said "+nn" so tell that's an error
;
rtvnrel	inx	h
	push	h
	call	typemcr
	call	ilprt
	db	': ignored.  "+" retrieves next 10',cr,lf,0
	pop	h
	mvi	m,cr
rincr	pop	psw
;
;INCREMENT NUMBER
;
	LXI	H,MSGNO+4 ;UNITS DIGIT
	ORA	A	;NEXT OR PREV?
	JZ	RTVG	;NO MORE
	JM	RTVPR	;PREV
	CALL	ADD1	;ADD 1 IN ASCII
;
;	if past hi approved msg, stop "+" retrieve
;
 if msgapp
	call	ckhiapp
	jnc	rnomore
 endif
;
;	if past hi msg, stop "+" retrieve
;
	lxi	h,highmsg
	lxi	d,msgno
	mvi	b,5
	call	compr
	jc	rmore
;
rnomore	call	ilprt
	db	cr,lf,'Past hi msg #',cr,lf,0
	mvi	a,cr
	sta	inbuf
	xra	a
	sta	rtogo
	jmp	rtvnxf
 if msgapp
;
;	if past hi msg, stop "+" retrieve
;
ckhiapp	lxi	h,highapp	;point to hi approved
	lxi	d,msgno
	mvi	b,5
	jmp	compr		;set carry if OK.
 endif
;
; take advantage of "maybe" having the desired message
; right "under the read pointer" when doing "R;+"
; (only valid for odd msg #'s in the FILEDIV=2 mode.
;
rmore	lda	fcb+1	;no file?
	ora	a
	jz	rtvok	;	none, just go on
; 
	lda	msgno+4		;get lo dig.
	ani	1		;odd?
	jz	rtvok		;	no, get next file
;
;	Digit is odd, the message "might" be next
;	(will be, unless it has been killed)
;
	jmp	rtvmat		;go match it
04;MODS:
;
;REQUEST TO RETRIEVE PREVIOUS
;
;	CHECK THAT NOT BACKING PAST 00000
;	& if so, reset msg # to high # for r;-
;
RTVPR	LXI	H,MSGNO	;POINT
	LXI	D,MSGNO+1
	CALL	COMP4	;ALL DIGITS SAME?
	jnz	RTVN00
	sui	'0'	;YES SAME, BUT 0?
	jnz	rtvn00
	call	ilprt
	db	'++ Back to 00000, reset to ',0
	call	ResetHi
	lxi	h,msgno
	call	typemcr
	call	crlf
	xra	a
	jmp	RTVST	;set 0 more to go
;
ResetHi	lxi	h,highmsg
	lxi	d,msgno
	call	move5
	ret
;
RTVN00	LXI	H,MSGNO+4
	CALL	SUB1	;BACK UP 1
	JMP	RTVOK	;CONTINUE
04;END
;
;MOVE FLAGGED MSG # TO MSGNO
;
RTVF	MOV	A,M	;AT LAST NUMBER?
	CPI	CR
	JZ	RTVFE	;	YES, END
	LXI	D,MSGNO	;NO, GET
	CALL	MOVE5	;	#
	SHLD	FlagPtr	;UPDATE POINTER
	JMP	RTVOK	;	RETRIEVE IT
;
;NO MORE FLAGGED TO RETRIEVE, TURN IT OFF
;	AND RETURN TO "FUNCT";
;
RTVFE	LXI	H,0
	SHLD	FlagPtr
;
;	restore hi msg # to msgno so r;- works OK.
;
	call	ResetHi
	JMP	FUNCT
;
;PAD NUMBER TO 5 BYTES
;
RTVNPL	EQU	$
04;MODS:
	CPI	'-'	;RETRIEVE 10 PREV?
	MVI	A,(-10) AND 0FFH
	JZ	RTVST	;YES, DO THEM
;
;	if first retrieve, take number literally.
;	otherwise, shorthand overlay right part of msg.
;
	lxi	h,tries
	mov	a,m		;get old switch
	mvi	m,0		;set to 0
	ora	a
	cnz	justa		;justify full number
	lxi	h,answer
	CALL	JUSTR	;R. JUST. ANS. INTO 'MSGNO'
	Jnc	rtvok	;BAD NUMBER
;
;	user screwed up - some garbage in retrieve
;
	call	ilprt
	db	cr,lf,'++ You are in message retrieve, "',0
	lxi	h,answer
	call	typemcr
	call	ilprt
	db	'" not understood ++',cr,lf,0
	mvi	a,cr
	sta	inbuf
	jmp	rtvg
;
RTVOK	CALL	SETMSGN	;SETUP FILENAME
;
 if msgapp
	call	ckhiapp
	jnc	rnomore
 endif

	LXI	H,MSGFN	;POINT TO 'MESSAGE ',MSGNO
	CALL	SETRD	;SET UP TO READ
	JNC	RTVFN	;FILE FOUND
;
;MSG NOT FOUND
;
RTRVN	lda	rtogo
	ora	a
	jz	rtrvnm
	CALL	ILPRT
	DB	'- ',0
	JMP	rtvnxf
;
rtrvnm	call	ilprt
	db	'No msg ',0
	LXI	H,MSGNO
	CALL	TYPEMCR
	CALL	CRLF
	JMP	rtvnxf	;GET NEXT
;
;FILE WHICH POTENTIALLY CONTAINS THE MESSAGE
;HAS BEEN FOUND.  NOW FIND THE MESSAGE NUMBER
;
RTVFN	CALL	RDBYTE
	JC	RTRVN
	CPI	'G'-40H	;BELL?
	JNZ	RTVFN
;GOT BELL CHAR - MATCH MESSAGE
rtvmat	LXI	H,MSGNO
	MVI	B,5	;CHARS TO MATCH
RTVFNM	CALL	RDBYTE
	JC	RTRVN
	CMP	M	;MATCH?
	JNZ	RTVFN	;NO, SCAN FOR NEXT
	INX	H
	DCR	B
	JNZ	RTVFNM
;
; message found - print it
;
rtvgot	CALL	RDBYTE	;KILL COMMA AFTER NUMBER
	CALL	ILPRT
	DB	CR,LF,'Msg ',0
	LXI	H,MSGNO
	CALL	TYPEMCR
	CALL	ILPRT
	DB	' is ',0
	CALL	RTVCM	;# LINES
	CALL	ILPRT
	DB	' line(s) on ',0
	CALL	RTVCM	;DATE
	CALL	ILPRT
	DB	' from ',0
	CALL	RTVCM
	CALL	ILPRT
	DB	CR,LF,'to ',0
	CALL	RTVCM
	CALL	ILPRT
	DB	' re: ',0
	CALL	RTVCM	;SUBJECT
	CALL	CRLF
	CALL	CRLF
RTVSKP	CALL	RDBYTE	;SKIP PASSWORD
	JC	rtvnxf
	CPI	LF
	JNZ	RTVSKP
RTVRD	CALL	RDBYTE
	JC	rtvnxf
	CPI	'G'-40H	;NEXT MSG HDR?
	JZ	RTRVEND
	CALL	NDTYPE
	CALL	CTLCKS	;CTL-C?
	JNZ	RTVRD	;NO.
	CALL	CRLF
;
; we interrupted out of this, so kill feature to find
; next msg
;
	xra	a		;blow away
	sta	fcb+1		;	knowledge of file
RTRVEND	LDA	INBUF	;MORE STACKED?
	CPI	CR
	JNZ	rtvnxt
	LDA	RTOGO
	ORA	A
	JNZ	rtvnxt
	LHLD	FlagPtr
	MOV	A,H
	ORA	L
	JNZ	rtvnxt
	CALL	ILPRT
	DB	'--End of ',0
	LXI	H,MSGNO
	CALL	TYPEMCR
	CALL	CRLF
	JMP	rtvnxt
;
;READ FIELD FROM MESSAGE (NAME, DATE, ETC)
;
RTVCM	CALL	RDBYTE
	JNC	RTVCMN
	POP	H	;KILL RETURN ADDR
	JMP	rtvnxt
;
RTVCMN	CPI	','
	RZ		;END OF FIELD
	CPI	CR
	JZ	RDBYTE	;EAT UP L/F, RETURN
	CALL	NDTYPE
	CALL	CTLCKS	;CHECK CTL C, K, S
	JZ	rtvnxt
	JMP	RTVCM
;
;SET MESSAGE NUMBER.  IN BASIC, THIS WOULD SIMPLY BE:
;FILE# = FILEDIV*INT(MSGNO/FILEDIV) 
;
;1. CONVERT LAST 2 DIGITS OF MSGNO TO BINARY
;
SETMSGN	LXI	H,MSGNO+3 ;TO ASCII #
	MOV	A,M	;GET 10S
	SUI	'0'	;MAKE BINARY
	MOV	B,A
	ADD	A	;X2
	ADD	A	;X4
	ADD	B	;X5
	ADD	A	;X10
	MOV	B,A	;SAVE
	INX	H	;TO UNITS
	MOV	A,M	;GET UNITS
	SUI	'0'	;MAKE BINARY
	ADD	B	;A=DECIMAL VALUE
;2. DIVIDE BY FILEDIV
	MVI	B,0FFH	;QUOTIENT
	MVI	C,FILEDIV ;DIVISOR
SETMDIV	INR	B
	SUB	C	;SUBTRACT DIVISOR
	JNC	SETMDIV	;LOOP 'TILL DONE
;3. MULTIPLY BY FILEDIV
	MVI	C,FILEDIV
	XRA	A
SETMMUL	ADD	B
	DCR	C
	JNZ	SETMMUL
;4. CONVERT BACK TO ASCII IN MSGFT
	LXI	H,MSGFT+1
	MVI	M,'0'-1
SETM2	INR	M
	SUI	10
	JNC	SETM2
	ADI	10+'0'
	INX	H
	MOV	M,A
	RET		;WITH MSGFT SET.
01 ;END OF 01 MODS
;
	LINK	CBBSOPER ;TO NEXT .ASM FILE
                                             