;CBBS V3.6.2	CBBSSUMM.ASM - SUMMARY FUNCTION
;06/23/83 21:06:41
;	LINKS TO CBBSENT1
;
;	O O O	O   O	O   O	O   O
;	O	O   O	OO OO	OO OO
; CBBS	O O O	O   O	O O O	O O O	.ASM
;	    O	O   O	O   O	O   O
;	O O O	O O O	O   O	O   O
;
;MODIFICATION LOG: (THRU 3.2 WRITTEN TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;	;then to "history.036"
;	----------------
;
; Find a persons message via:
;	OR;1,t=firstname lastname-1st-4-chars
;		,t=firstname/,t=firstname"  "
;
;	Non-experts don't get the auto-retrieve, 
;		just the search
;
domine	mvi	a,2		;turn off auto-exec switch,
	sta	minesw		;	show looking.
	call	ilprt
	db	'"Mine" command checking for msgs TO you, '
	db		' ^K to abort..',cr,lf,0
mine	mvi	a,2		;turn off auto-
	sta	minesw		;	exec switch
 if xfer
;
;	ensure not in modem mode.  If so, "mine"
;	would fail, since it executes "sr;1...", and
;	in modem, s = Send, not Summary.
;
	xra	a
	sta	mroute
 endif
minenm	lxi	h,minemsg
	lxi	d,inbuf
	mvi	b,7
	call	move
	lxi	h,fname		;move
	mvi	b,20		;max chars
	call	miname		;	the first name
	mvi	a,' '		;move in
	stax	d		;	a space
	inx	d
	lxi	h,lname		;move in
	mvi	b,4		;	4 chars of
	call	miname		;	the last name
	lxi	h,minem2
	mvi	b,3
	call	move		;now s;1,t=(full name),t=
	lxi	h,fname		;get first name
	call	miname		;b=0 so move entire name
	mvi	a,'/'		;double space after first name
	stax	d		;	to find msgs with
	inx	d		;	TO only first name
	lxi	h,minem2
	mvi	b,3
	call	move		;now s;1,t=(full name),t=
	lxi	h,fname		;get first name
	call	miname		;b=0 so move entire name
	mvi	a,' '		;double space after first name
	stax	d		;	to find msgs with
	inx	d		;	TO only first name
	mvi	a,' '
	stax	d
	inx	d
;
	mvi	a,cr
	stax	d		;store final c/r
	jmp	funget		;leave "MINE1" alone, exec func.
;
minemsg	db	'OR;1'
minem2	db	',T='		;for first name check.
;
; move the CR terminated name from HL to DE
;
miname	mov	a,m		;get char
	inx	h		;to next
	cpi	cr		;done?
	rz			;	y/ret
	stax	d		;n/save it
	inx	d		;to next
	jmp	miname		;loop until c/r.
;
; ====>	O, Q, and R (and OR, QR and SR) command processor
;
SUMMRY	LXI	H,0
	SHLD	FLAGPTR	;SHOW NO FLAGGED RETRIEVES
	XRA	A
	STA	SAVMSG	;SHOW NO PREV
	sta	markcnt		;show no marked msgs
	LXI	SP,STACK ;CLEAN UP FROM ABORTS
	lxi	h,flagall	;show
	mvi	m,0		;	not "flag all"
	lda	twitsw		;twits
	ora	a		;	don't get
	jnz	sumnall		;	this neat stuff.
;
; 11/20/82 second thoughts about non-experts not having
;	some commands - makes documenting them more difficult.
;
;	lda	expert		;only experts
;	ora	a
;	jz	sumnall
	lda	answer+1	;was it "SR" or "QR"
	cpi	'R'
	jnz	sumnall		;	yes, not "all"
	mvi	m,'F'-40h	;set it to "all"
sumnall	CALL	GETVAR
	DB	'First msg #: (or ? for info '
	DB	'on searching msgs)',CR,LF
	DB	'(C/R to exit)',0
	DW	WKBUF
03	DW	-1	;NO HELP MSG #, PASS "?" BACK
	DB	60	;LEN (USED TO BE 36)
suall	LDA	WKBUF
	CPI	'?'	;REQUEST FOR HELP?
	JNZ	SUNOQ
;
; ? WAS ENTERED, GIVE HELP, ASK AGAIN
;
	LXI	H,SCHLFL
	CALL	INTQF	;INTERPRET THE QUESTION FILE
	JMP	SUMMRY
;
;CHECK FOR C/R ENTERED
;
SUNOQ	CPI	CR
	JZ	FUNCT
;IF MINUS SIGN, SAVE IT, REPLACE IT WITH A 0
	CPI	'-'
	MOV	B,A	;SAVE FOR - TEST
	PUSH	B
	JNZ	SUNNG	;NOT NEG
	MVI	A,'0'
	STA	WKBUF
;
;RIGHT JUSTIFY THE MESSAGE NUMBER
;
SUNNG	LXI	H,WKBUF	;TO #
	CALL	JUST5	;JUSTIFY, MOVE TO 'MSGNO'
	POP	B
	JC	SUMMRY	;INVALID #
	MOV	A,B	;WAS IT '-'?
	CPI	'-'
	JNZ	SUNNG2
;
;GET THE HI MSG #, SUBTRACT THE AMT REQUESTED
;
	CALL	RDNEXT	;READ IN "NEXT" TO 80H
	LXI	D,nxlmsg	 ;TO UNITS POSITION
	LXI	H,MSGNO+4 ;AMT TO SUBTRACT
	MVI	B,5	;LENGTH
	CALL	ASCISUB	;ASCII SUBTRACT
;
;MOVE THE CALCULATED MSG # TO MSGNO
;
	LXI	H,nxhmsg	;to next msg hi digit
	LXI	D,MSGNO
	MVI	B,5	;MSG # LEN
	CALL	MOVE
;
SUNNG2	LDA	EXPERT	;EXPERT USER?
	ORA	A
	JNZ	SUMNXT	;YES, SKIP FOLLOWING:
	CALL	ILPRT	;PRINT THE FOLLOWING:
	DB	'Use S to pause/restart, '
	DB	'C to skip, '
	DB	'K to abort.',CR,LF,0
;
;OPEN THE SUMMARY FILE
;
01;START OF MODS - SPLIT OUT BINARY SEARCH
SUMNXT	CALL	BINSRCH
01;END OF MODS
04;MODS:
;
;FIRST PASS:
;	CHANGE '<>' OR "(EXCLAMATION MARK)=" TO "#"
;
SUMDNE	LXI	H,WKBUF
SUMDNE1	MOV	A,M
	INX	H
	CPI	CR
	JZ	SUMDBLK	;GO DEBLANK
	CPI	'<'
	JNZ	SUMDNE4	;NOT POSSIBLE <>
	MOV	A,M
	CPI	'>'	;IS IT <>?
	JNZ	SUMDNE1
;
;GOT A 2-CHAR "NOT EQUAL".  CHANGE IT TO A #
;	AND DELETE THE FIRST CHAR OF IT
;
SUMDNE2	MVI	M,'#'	;CHANGE ">" TO "#"
SUMDNE3	MOV	A,M	;GET CHAR
	DCX	H
	MOV	M,A
	INX	H
	INX	H
	CPI	CR
	JNZ	SUMDNE3	;SQUEEZE OUT EXTRA CHAR
	JMP	SUMDNE
;
SUMDNE4	MOV	A,M
	CPI	'!'	;TEST FOR "NOT"
	JNZ	SUMDNE1
	INX	H
	MOV	A,M
	CPI	'='		;not =?
	JZ	SUMDNE2
	JMP	SUMDNE1
;
SUMDBLK	LXI	H,WKBUF
SUMDBL1	MOV	A,M
	CPI	CR
	JZ	SUMHDR	;DONE, NO MORE TO DO
	INX	H
	CPI	' '
	JNZ	SUMDBL1	;LOOP IF ITS NOT A SPACE
;
;FOUND ' ', IF BOOLEAN NEXT, 
;	DELETE THE SPACE
;
	MOV	A,M
	CALL	SUMBOOL	;'&', ',' OR '|'?
	JNZ	SUMDBL1
;
	MOV	D,H
	MOV	E,L
	DCX	D	;WHERE TO MOVE "TO"
SUMDBL2	MOV	A,M	;GET A CHAR
	STAX	D
	INX	D
	MOV	M,A
	CPI	CR
	JZ	SUMHDR
	INX	H
	CALL	SUMBOOL	;ANOTHER BOOLEAN?
	JNZ	SUMDBL2	;NO, CONTINUE DEBLANKING
;
;JUST GOT A BOOLEAN, BLANK A SPACE AFTER IT IF ANY
;
	MOV	A,M
	CPI	' '
	JNZ	SUMDBL2
	INX	H	;SKIP THE ' '
	JMP	SUMDBL2
04;END
;
;IF QUICK OR EXPERT, DON'T PRINT HEADER
;
SUMHDR	MVI	A,50	;HEADER EVERY 50
	STA	SUMCNT
;
	LDA	EXPERT	;EXPERT?
	ORA	A
	JNZ	SUMLP	;..NO HDR
;
;	if "mine", no header
;
	lda	minesw
	cpi	2
	jnc	sumlp
;
;	skip prompt for flagging if already
;	auto-flagging
;
	lda	flagall
	ora	a
	jnz	sumttl
;
;	or if retrieve asked for but not expert
;
	lda	answer+1
	cpi	'R'
	jz	sumcks
;
	CALL	ILPRT
	db	'Press "F" to flag PREVIOUS msg for '
	db		'later retrieval.',CR,LF
	db	'if missed with "F" press "return" to '
	db		'be asked for its number',CR,LF,0
sumcks	LDA	SUMTYP	;NO HDR IF
	CPI	'S'	;	QUICK or one-line SUMMARY
	JNZ	SUMLP
sumttl	call	ilprt
	DB	CR,LF,' NO.  SIZE --DATE-- FROM...'
	DB	'              TO...',CR,LF
	DB	0	;END OF MSG
;
;LOOP, READING IN SUMMARY ENTRY, 
;PRINTING IT IF IT IS >= REQUESTED NO.
;
; (deleted xra a, sta flagreq: I think it was redundant)
;
SUMLP	CALL	RDBYTE	;EAT UP THE BELL HDR CHR
	JC	SUMEOF
	LXI	H,SUMLN	;POINT TO LINE IN MEMORY
	MVI	B,7	;FOR MSG # + CR/LF
	CALL	SUMMV	;MOVE IN THE LINE NUMBER
	MVI	B,4	;FOR # LINES
	CALL	SUMMV
	MVI	B,9	;LENGTH OF DATE
	CALL	SUMMV
	MVI	B,21	;LENGTH OF NAME
	CALL	SUMMV
	MVI	B,21	;LENGTH OF "WHO TO"
	CALL	SUMMV
	LXI	H,SUBJ	;POINT TO SUBJECT AREA
	MVI	B,30	;LENGTH OF SUBJECT
	CALL	SUMMV
;
;SKIP PASSWORD
;
SUMSKP	CALL	RDBYTE
	JC	SUMEOF
	CPI	0AH	;END OF LINE?
	JNZ	SUMSKP
02;START OF MODS
	LDA	PASSFLG	;SYSTEM OPERATOR?
	ORA	A
	JZ	SUMSHOW	;SHOW FLAGGED
	LDA	SUMLN+7
	CPI	'X'
	JZ	SUMLP	;TO NEXT IF FLAGGED
SUMSHOW:
02;END OF MODS;
;
;CHECK IF THE MESSAGE IS LESS THAN THAT REQUESTED
;
	LXI	D,SUMLN	;POINT TO MESSAGE NUMBER
	LXI	H,MSGNO
	MVI	B,5	;LENGTH OF COMPARE
	CALL	COMPR
	JC	SUMLP	;DON'T PRINT
;
; see if past high approved msg #
;
 if msgapp
	LXI	D,highapp
	LXI	H,SUMLN
	MVI	B,5
	CALL	COMPR
	Jnc	sapp
;
; its past hi approved - show if author
;
	lxi	d,sumfr
	lxi	h,fname
	call	matnam
	lxi	h,lname
	cz	matnam		;comp last if 1st matches
	jnz	sumlp		;1st name - no match
 endif
;
;MESSAGE NO. READ IS OK
;
;****	HERE IS WHERE THE FLAG REQUEST IS TURNED
;	OFF.  ANY SUBSEQUENT "F" KEYS WILL FLAG
;	THE PREVIOUS RECORD
;
sapp	lda	flagall		;=0 unless flagging all
	STA	FLAGREQ
;
;CHECK FOR CTL-C OR K TO ABORT
;
	CALL	CTLCKS
	JZ	SUMLP
	CPI	'F'-40H	;FLAGGED RETRIEVE?
	JZ	SUMCCF
	CPI	'M'-40H	;FLAG MISSED ONE?
	JNZ	SUMCC0
SUMCCF	mov	b,a		;save flag request
	lda	flagall		;already flagging all?
	ora	a
	jz	sumcc0		;	y/don't flag
	mov	a,b		;	n/flag it.
	STA	FLAGREQ	;SHOW FLAGGED
;
;FIRST, CHECK IF 'FIELD=VALUE' WAS ASKED FOR
;
SUMCC0	LXI	H,WKBUF
SUMCC	MOV	A,M	;GET CHAR
	INX	H
	CPI	0DH
	JZ	SCANND	;NO FIELD, PRINT IT
	CPI	','	;COMMA?
	JNZ	SUMCC	;KEEP SCANNING
04
SUMSVP	SHLD	SCANPTR	;SAVE TO ZAP IF DATE
;
;GOT COMMA - VALIDATE FIELD VALUE
;VALID VALUES PRECEEDING AN "=" ARE:
;	D DATE
;	F FROM
;	T TO
;	S SUBJECT
;
	MOV	A,M	;GET CHAR
04;MODS:
	STA	SCANTYP	;SAVE FOR LATER TEST
	INX	H
	STA	COMPTYP	;IN CASE WAS "#"
	CPI	'#'
	JZ	SUMWORD	;GOT <>
	MOV	A,M
	DCX	H
	CPI	'#'	;NOT =?
	JZ	SUMN1
	CPI	'='
	JNZ	SUMWORD	;JUST A WORD, NO FIELD
SUMN1	STA	COMPTYP
	MOV	A,M
	LXI	D,SUMDT	;POINT TO DATE
	MVI	C,8	;DATE LENGTH
	CPI	'D'
	JZ	SUMGF	;GOT FIELD
	LXI	D,SUMFR	;POINT TO FROM
	MVI	C,20	;FROM LENGTH
	CPI	'F'
	JZ	SUMGF
	LXI	D,SUMTO
	CPI	'T'
	JZ	SUMGF
	LXI	D,SUBJ
	MVI	C,30
	CPI	'S'
	JZ	SUMGF
;
;INVALID FIELD ENTERED
;
SUMIF	CALL	ILPRT
	DB	'++Invalid field',CR,LF
	DB	'type ? for help',CR,LF,0
	JMP	SUMMRY
;
; sumnam compares a name to the summary
;
 if msgapp
matnam	ldax	d
	cmp	m
	inx	d
	inx	h
	jz	matnam
;
;	if cr matches space, its OK - end of name
;
	cpi	' '
	rnz
	dcx	h
	mov	a,m
	inx	h
	cpi	cr
	ret
 endif
;
;GOT A KEYWORD WITH NO ASSOCIATED FIELD
;
SUMWORD	XRA	A
	STA	SCANTYP	;NO SPECIFIC FIELD SCAN 
	MVI	C,98	;LENGTH OF ENTIRE FIELD
	LXI	D,SUMLN+5
	JMP	SUMGF2
;
;GOT FIELD, CHECK FOR '='
;
SUMGF	INX	H
	MOV	A,M
	STA	COMPTYP	;SAVE FOR = TEST LATER
	CPI	'#'
	JZ	SUMGF1
	CPI	'='
	JNZ	SUMIF	;INVALID
SUMGF1	INX	H	;POINT TO VALUE
;CALCULATE FIELD LENGTH FOR COMPARE
SUMGF2	PUSH	H	;SAVE POINTER TO START
	MVI	B,0	;INIT COUNT
SUMGC	MOV	A,M	;GET CHAR
	INX	H
	INR	B
	CPI	0DH	;END?
	JZ	SUMGD
	CALL	SUMBOOL	;"&", ",", OR "|"?
	JNZ	SUMGC
SUMGD	STA	SCDELIM	;SAVE DELIMITER
	DCR	B	;BACK OUT EXCESS INR
;MAKE SURE LENGTH IS VALID
	MOV	A,C	;GET FLD LEN
	CMP	B	;VS. COMPARE LENGTH
	JC	SUMIF	;INVALID
;CALCULATE THE NUMBER OF BYTES TO COMPARE
	MOV	A,C	;FIELD LEN
	SUB	B	;-COMPARE LEN
	INR	A	;MAKE 0 => 1, ETC.
	MOV	C,A	;SAVE # OF COMPARES
	SHLD	SCLOG	;SAVE CONTINUE FOR LOGICALS
	POP	H	;RESTORE POINTER
;DO THE COMPARE FOR THE FIELD VALUE
SUMCMP	PUSH	B
	PUSH	D
	PUSH	H
	CALL	COMPR
	POP	H
	POP	D
	POP	B
	JZ	SUMMAT	;MATCHED
;
;DIDN'T MATCH - SEE IF MORE COMPARES TO DO
;	first, if "mine", then no need to "window" scan.
;
	lda	minesw
	ani	2	;2-3 
	jnz	sunomat
	INX	D	;TO NEXT BYTE OF FIELD
	DCR	C	;MORE COMPARES?
	JNZ	SUMCMP
;
;DIDN'T MATCH - IF OPERATOR WAS NON-EQUAL MATCH,
;THEN MAKE IT A "HIT"
;
sunomat	LDA	COMPTYP
	CPI	'#'
	JZ	SUMMAT2
;
;DIDN'T MATCH FIELD, SEE IF "OR", AND IF SO,
; MATCH IT.  OTHERWISE SCAN FOR NEXT "OR"
;
SUMCMP2	LDA	SCDELIM
	CALL	SUMBOR	;IS IT "," OR "|"?
	JZ	SUMOR
SUMNXOR	MOV	A,M	;EXIT
	CPI	CR	;	IF C/R
	JZ	SUMLP
	CALL	SUMBOR	;IS IT "OR"?
	INX	H	;TO NEXT
	JZ	SUMSVP
	JMP	SUMNXOR
;
;	CHECK FOR "AND" OR "OR" CONDITION
;
SUMMAT	LDA	COMPTYP
	CPI	'#'	;REQUEST FOR NOT EQUAL?
	JZ	SUMCMP2	;	YES
SUMMAT2	LDA	SCDELIM	;WAS THERE A LOGICAL DELIM?
	CPI	0DH
	JZ	SUMNLOG
	CALL	SUMBOR	;"OR"?
	JZ	SUMNLOG	;	YES, GOT IT
;
;GOT "AND" CONDITION, OR FAILED "OR", 
; - SETUP TO CONTINUE TEST
;
SUMOR	LHLD	SCLOG	;GET LOGICAL POINTER
	JMP	SUMSVP	;GO BACK, HANDLE NEXT FIELD
;
;MATCH BOOLEANS: RZ IF ANY
;
SUMBOOL	CPI	'&'
	RZ
;
; RZ IF ONE OF THE "OR" BOOLEANS
;
SUMBOR	CPI	','
	RZ
	CPI	'|'
	RET
;
;IF DATE MATCH, FORCE MATCH FROM NOW ON.
;
SUMNLOG	LDA	SCANTYP
	CPI	'D'
	JNZ	SCANND
	LHLD	SCANPTR ;POINT
	DCX	H	;	TO ','
	MVI	M,CR	;	"ZAP" IT
SCANND:
04;END
	lxi	h,minesw
	mov	a,m		;get switch
	ori	4		;show found
	mov	m,a
	lda	SUMTYP
	CPI	'O'
	JZ	sumone	;one-line summary
	CPI	'Q'
	JZ	SUMQ	;YES
	LXI	D,SUMLN	;POINT TO LINE
	LXI	H,SUMTO+20 ;END OF TRUNCATE
	CALL	SUMTRP	;TRUNCATE AND PRINT
	call	crlf
	LXI	D,SUBJHD
	LXI	H,SUBJ+29
	CALL	SUMTRP
	call	crlf
	CALL	SUMFLG	;FLAG IF ASKED FOR
	CALL	SUMSVM	;SAVE MSG #
;
;	LDA	EXPERT	;DOUBLE SPACE
;	ORA	A	;	SUMMARY IF
;	CZ	CRLF	;	NOT EXPERT MODE
;
;SEE IF TIME TO PRINT A HEADER (EVERY 50)
;
	LDA	SUMCNT
	DCR	A
	STA	SUMCNT
	JNZ	SUMLP
	JMP	SUMHDR	;PRINT HDR
;
;SAVE THE MESSAGE NUMBER SO FLAGGING DURING
;	NEXT SUMMARY WILL PRINT THIS ONE
;
SUMSVM	LXI	H,SUMLN
SUMSAV	LXI	D,SAVMSG
	JMP	MOVE5
;
;QUICK SUMMARY (MSG #, SUBJECT)
;
SUMQ	LXI	H,SUMLN	;MSG #
sumqz	mov	a,m		;02/26/83 mod - del leading 0's
	inx	h
	cpi	'0'
	jz	sumqz		;.
	dcx	h
	MVI	B,' '		;ENDING DELIMITER
	CALL	TYPEM
	MVI	A,' '
	CALL	TYPE
	LXI	D,SUBJ
	LXI	H,SUBJ+29
	CALL	SUMTRP		;TRUNCATE & PRINT
	call	crlf
;
; 04/10/83 if "mine", but less than prev hi msg, don't flag it.
;
sumqf	CALL	SUMFLG		;FLAG IF ASKED FOR
	CALL	SUMSVM
	JMP	SUMLP
;
;  new 11/07/82: one-line summary
;
sumone	lxi	h,sumln		;get msg #
sumob	mov	a,m		;delete leading '0's
	inx	h
	cpi	'0'
	jz	sumob
	dcx	h
;
	mvi	b,' '		;ending delim
	call	typem		;type msg #
	lda	sumln+7		;is it 'x'ed? (op sees all summ)
	cpi	'X'
	cz	type
	call	space		;space,
	lxi	d,sumdt		;to date
	lxi	h,sumto-1	; field end
	call	sumtrp		;truncate & print
	call	ilprt
	db	' => ',0
	lxi	d,sumto
	lxi	h,subjhd-3
	call	sumtrp
	call	ilprt
	db	': "',0		;put subject in quotes.
	lxi	d,subj
	lxi	h,subj+29
	call	sumtrp		;no trailing spaces
	call	ilprt
	db	'"',cr,lf,0
	jmp	sumqf
;
;TRUNCATE A LINE, AND PRINT IT
;
SUMTRP	MOV	A,M
	DCX	H	;BACK UP INTO NON-' ' CHAR
	CPI	' '
	JZ	SUMTRP
	CPI	0DH	;IGNORE OLD CR/LF/0
	JZ	SUMTRP
	CPI	0AH
	JZ	SUMTRP
	ORA	A	;0 END OF MSG?
	JZ	SUMTRP
	INX	H	;TO CHAR
	INX	H	;PAST CHAR
	MVI	M,0	;END OF MSG
	XCHG		;GET MSG START TO DE
	CALL	TYPEM0	;TYPE MESSAGE, AND IF "F"
	ret		;	TYPED, FLAGREQ
;				IS SET FOR RETRIEVE
;
;SUBROUTINE TO MOVE DATA FROM SUMMARY FILE INTO
;BUFFER, LENGTH IN B.
;
SUMMV	CALL	RDBYTE	;GET A CHAR
	JC	SUMEOF
	CPI	','	;END OF FIELD
	JZ	SUMENDF
	CPI	0DH	;END OF FIELD?
	JZ	SUMCR	;YES, EAT LF
	MOV	M,A	;SAVE CHAR
	INX	H
	DCR	B
	JNZ	SUMMV	;LOOP IF MORE
;
;FIELD IS FILLED - IGNORE ANY EXTRA CHARS
;
SUMIGN	CALL	RDBYTE
	JC	SUMEOF
	CPI	','	;DELIM?
	RZ
	CPI	0DH	;DELIM?
	JNZ	SUMIGN
	JMP	RDBYTE	;GET L/F, RETURN
;
;END OF FIELD - IF SHORT, PAD WITH SPACES
;
SUMCR	CALL	RDBYTE	;EAT UP L/F
SUMENDF	XRA	A
	ORA	B	;END?
	RZ		;YES, RETURN
	MVI	M,' '
	INX	H
	DCR	B
	JMP	SUMENDF
;
;EOF ON SUMMARY FILE
;
;NOTE:	THIS NORMALLY DIDN'T PRINT FOR EXPERT USERS,
;	BUT NOW WITH FLAGGED RETRIEVE, IT IS USED
;	TO ALLOW THE LAST SUMMARY TO BE FLAGGED
;
SUMEOF	lda	flagall		;02/24/83 mod to not flag last
	sta	flagreq		; msg if 2nd last flagged.
	lda	minesw
	cpi	2		;if =2 then no
	jz	nomine		;	msgs found via MINE.
	CALL	ILPRT	;PRINT THE FOLLOWING:
	DB	CR,LF,'     '
	DB	'----END OF SUMMARY----'
	DB	CR,LF,0
	CALL	SUMFLG	;FLAG THE MSG IF ASKED FOR
	xra	a
	sta	minesw	;kill auto-mine if ANY other summ exec.
	JMP	FUNCT	;GO GET NEXT FUNCTION
;			 OR FLAGGED RETRIEVE IF ANY
;
nomine	call	ilprt
	db	'++ No msgs for you ++',cr,lf,0
	jmp	funct	;funct turns off "mine".
;
;====>	SUMFLG	SAVE FLAGGED MESSAGE # IF ASKED FOR
;		BY USER TYPING "F" DURING N-E-X-T SUMMARY
;
SUMFLG	lda	minesw
	ani	2
	jz	sumflg2
	lda	prevhi		;was there a
	ora	a		;	prev hi?
	jz	sumflg2		;	n/flag it
	lxi	h,prevhi
	lxi	d,savmsg
	ldax	d
	ora	a
	jz	sumflg2		;none to compare
	mvi	b,5
	call	compr
	rc
sumflg2	LDA	FLAGREQ	;FLAG REQUESTED?
	ORA	A
	RZ
	CPI	'M'-40H	;MISSED ONE?
	CZ	SUMISS	;GET MISSED ONE TO SAVMSG
	LDA	SAVMSG
	ORA	A	;ANY PREV MSG?
	RZ		;NO
	PUSH	H
	LHLD	FLAGPTR	;GET POINTER
	MOV	A,H
	ORA	L
	JNZ	SUMFC	;GOT A POINTER
	LXI	H,MSGBF	;POINT TO WORK AREA
	SHLD	FLAGPTR
	MVI	M,CR
;
;SCAN FOR C/R AT END
;
SUMFC	MOV	A,M
	INX	H
	CPI	CR
	JNZ	SUMFC
	DCX	H	;BACK TO C/R
;
;CHECK FOR saved msg # buffer OVERFLOW
;
	MOV	A,H
	CPI	2+(MSGBF/256)
	JNZ	sumfit
	call	ilprt
	db	cr,lf,'++ Msg flag limit reached (=~85 msgs) ++'
	db	cr,lf,cr,lf,0
	xra	a
	sta	flagall
	jmp	funct
;
sumfit	PUSH	H
	XCHG			;set up for move
	call	sumvsv
	XCHG
	MVI	M,CR
;
;	If still room to mark a msg, do so.
;
	lxi	h,markcnt
	mov	a,m
	cpi	9
	jz	sumfit2
	inr	m		;bump mark count
;
;	got room, compute displacement in marktbl
;
	call	compmrk		;compute marktbl entry addr
	xchg			;set up for move
	call	sumvsv		
sumfit2	POP	H
;
;	If flagging all, don't print ">Fnnnnn" msg
;
	lda	flagall
	ora	a
	jnz	sumnof
	CALL	ILPRT
	DB	' >F:',0
	CALL	TYPEMCR
	CALL	CRLF
SUMNOF	POP	H
SUMNOF2	XRA	A
	STA	SAVMSG	;PREVENT DOUBLE FLAG
;
;SEE IF THERE WERE MORE THAN 1 MSG REQUESTED
;	IN "M" FLAG
;
	LDA	FLAGREQ
	CPI	CR	;MISSED ONE FLAG?
	RNZ
	LDA	INBUF	;CHECK FOR STACKED
	CPI	CR
	RZ
	call	ck09	;04/10/83 is it a number?
	RC		;	
	LDA	FLAGPTR+1 ;OVERFLOW?
	CPI	4+(MSGBF/256)
	JC	SUMFLG
	RET
;
sumvsv	LXI	H,SAVMSG
	jmp	MOVE5
;
;USER MISSED A SUMMARY - NOW WANTS TO TELL ME
;	ITS NUMBER
;
SUMISS	lda	inbuf		;stacked msg #?
	mov	b,a		;save it
	push	b
	CALL	GETVAR
	DB	'Msg #(s): to retrieve',0
	DW	MISSMSG
	DW	-1	;NO HELP MSG #, PASS "?" BACK
	DB	5
	pop	b
	LXI	H,MISSMSG
	mov	a,m
	CPI	CR
	JZ	SUMNMD	;	Y, TREAT LIKE F
;
;	if this is first msg, take all of it.  If not,
;	use shorthand technique.  
;	Thus 200;1;2 will get 200,201,202.
;
	mov	a,b
	cpi	cr
	jnz	sumijr
	CALL	JUST5	;JUSTIFY INTO MSGNO
	JC	SUMISS
	jmp	sumisv
;
sumijr	call	justr
	jc	sumiss
sumisv	LXI	H,MSGNO
	JMP	SUMSAV	;MOVE IT TO SAVE, RETURN
;
;PRESSED C/R TO FLAG, NOW SAYS "NEVER MIND".
;
SUMNMD	POP	H	;DUMP CALLER RET ADDR
	RET		;	THUS IGNORE FLAGGING
;
;---->	BINSRCH - ROUTINE TO BINARY SEARCH SUMMARY.
;
;PLACE MESSAGE # IN "MSGNO", AND CALL "BINSRCH".
;UPON RETURN, FCB IS SET UP TO READ THE SECTOR THE
;NUMBER IS IN.
;
;DO A 6 LEVEL BINARY SEARCH FOR THE SUMMARY,
;THEN USE THE LOWEST SECTOR FOUND
;
BINSRCH	LXI	H,SUMFL	;POINT TO FILENAME
	CALL	SETRD	;EXIST?
	JC	NOSUM	;NO SUMMARY FILE
05;MODS: SEE IF MSG < 30, RETURN IF SO
	LXI	H,MSGNO
	LXI	D,THIRTY ;'00030'
	MVI	B,5
	CALL	COMPR
	RNC
05;END
;
;SEE IF 80H RECORDS, IF SO, MIGHT BE SECOND EXTENT
;
BINS:			;ENTER HERE TO BINARY SEARCH
			;ANY OPENED FILE. (NOT USED
			;YET)
	LDA	FCBNSEC	;GET # SECTORS
	CPI	80H	;FULL EXTENT
	JNZ	BINGO	;GO WITH FIRST EXTENT
;
;IF THERE IS AN EOF IN THIS SECTOR, FORGET 
;SECOND EXTENT.  IF NO EOF, FIND THE HIGHEST
;MSG # IN THIS EXTENT BY SCANNING FOR THE
;L-A-S-T BELL HEADER IN THE SECTOR
;
	MVI	A,7FH
	STA	FCBRNO	;REC # TO READ
	STA	LOSECT	;USED BY "BINGOT"
	CALL	BUF100
	CALL	RDBYTE	;FORCE SECTOR READ
	LXI	H,80H
BINCKE	MOV	A,M
	CPI	EOF
	JZ	BINGO	;GO WITH 1ST EXTENT
	CPI	7	;BELL?
	JNZ	BINNB	;NO
	MOV	D,H
	MOV	E,L	;COPY PTR TO DE
BINNB	INR	L	;DONE?
	JNZ	BINCKE
;DE HAS POINTER TO LAST BELL HDR
	XCHG		;TO HL
	SHLD	BUFPTR	;SETUP FOR READ
	CALL	BINCOMP	;READ, COMPARE
;MAKE SURE WE DIDN'T GO INTO NEXT EXTENT
	PUSH	PSW	;SAVE BINCOMP RESULT
	LDA	FCBEXT
	ORA	A
	JZ	BINE1	;STILL IN EXT 1
	XRA	A
	STA	FCBEXT
	CALL	SETOPEN	;REOPEN FIRST EXTENT
;
BINE1	POP	PSW	;RESTORE RESULT
	JZ	BINGOT	;EXACT HIT
	JC	BINEXT	;TO NEXT EXTENT
;
;POSITIONED TO RIGHT EXTENT - START READING.
;
BINGO	XRA	A	;0..
	STA	LOSECT	;..TO LOW
	LDA	FCBNSEC	;MAX #..
	STA	HISECT	;..TO HI
	MVI	A,6	;SET SEARCH..
	STA	SRCHLVL	;..LEVEL
;
BINMID	LDA	LOSECT	;MIDDLE..
	LXI	H,HISECT ;..= LOW
	ADD	M	;..+ HI..
	RAR		;..DIVIDED BY 2
	STA	MIDSECT
	STA	FCBRNO
	CALL	BUF100	;FORCE READ
	CALL	BINCOMP	;COMPARE MSG FOUND
	JC	BINHI	;GO HIGHER
	JNZ	BINLOW	;LOWER OR EOF
;GOT THE EXACT MESSAGE
	LDA	MIDSECT
	STA	LOSECT
	JMP	BINGOT
;
;GO LOWER
;
BINLOW	XRA	A	;ZAP OFF..
	STA	EOFLG	;..EOF COND.
	LDA	MIDSECT
	STA	HISECT
	JMP	BINCK	;SEARCH DONE?
;
;GO HIGHER
;
BINHI	LDA	MIDSECT
	STA	LOSECT
BINCK	LXI	H,SRCHLVL
	DCR	M
	JNZ	BINMID	;LOOP TILL 'N' LEVELS
;
;DONE WITH SEARCH, GO FROM HERE
;
BINGOT	LDA	LOSECT	;START AT LOW
	STA	FCBRNO
	CALL	BUF100	;INIT FOR READ
;	CALL	CRLF
;
;SCAN TO NEXT BELL HEADER TO GET READY
;
BINBELL	CALL	RDBYTE
	JC	BINBACK
	CPI	7
	JNZ	BINBELL
BINBACK	CALL	UNRDBYT	;BACK UP
	RET
;
NOSUM	CALL	ILPRT
	DB	'++NO SUMMARY FILE++',CR,LF,0
	JMP	TELLUS	;ITS AN ERROR
;
;---->	BINCOMP - SCAN SUMMARY FOR MSG HDR.
;CARRY:	FOUND LOWER MSG #
;ZERO:	FOUND = MSG #, OR EOF
;NOT 0:	FOUND HIGHER MSG #
;
BINCOMP	CALL	RDBYTE
	JC	BINCEOF	;GO LOWER
	CPI	7	;BELL HDR?
	JNZ	BINCOMP
	LXI	H,MSGNO	;GOT BELL,..
	MVI	B,5	;..MATCH MSG
BINSRM	CALL	RDBYTE
	JC	BINCEOF	;INVALID EOF
	CMP	M
	INX	H
	RC		;GO HIGHER
	RNZ		;LOWER
	DCR	B	;=, CONTINUE
	JNZ	BINSRM
	RET		;GOT THE EXACT MESSAGE
;
;GOT EOF
;
BINCEOF	ORA	A	;RESET CARRY, NOT ZERO
	RET
;
;GO TO NEXT EXTENT
;
BINEXT	MVI	A,1
	STA	FCBEXT
	CALL	SETOPEN	;OPEN EXTENT
	JC	NOSUM	;ERROR
	XRA	A
	STA	FCBRNO	;START AT BEGINNING
	JMP	BINGO	;GO WITH 2ND EXT.
;
BUF100	LXI	H,100H
	SHLD	BUFPTR	;FORCE READ
	RET
;
01;END OF SPLIT OUT BINARY SEARCH
;
;ROUTINE TO SUBTRACT TWO EQUAL LENGTH
;ASCII NUMBERS (USED TO CALC MSG # TO START
;SUMMARY AT FOR S;-20  (I.E. 20 BACK FROM HIGH)
;
;	NUMBER POINTED TO BY HL IS SUBTRACTED
;	FROM NUMBER POINTED TO BY DE, RESULT
;	LEFT AT DE
;
ASCISUB	MVI	B,5	;LOOP COUNT
	ORA	A	;SET NO BORROW
ASLP	LDAX	D
	SBB	M
	ADI	'0'	;MAKE ASCII AGAIN
	STAX	D
	CPI	'0'	;BORROW?
	JNC	ASNB	;NO BORROW
	ADI	10	;CORRECT IT
	STAX	D
	STC		;SET FOR BORROW
ASNB	DCX	D	;TO NEXT..
	DCX	H	;..HIGHER DIGIT
	DCR	B	;DONE?
	JNZ	ASLP	;NO, LOOP
	RET
;
	LINK	CBBSENT1 ;TO NEXT .ASM FILE
                                                                           