;CBBS V3.6.2	CBBSFUNC.ASM - MAINLINE PART 2
;04/24/83 22:47:51
;	LINKS TO CBBSBYE
;
;	O O O	O   O	O   O	O O O
;	O	O   O	OO  O	O
; CBBS	O O	O   O	O O O	O	.ASM
;	O	O   O	O  OO	O
;	O	O O O	O   O	O O O
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;	then to history.036
;04/10/83 Major hacks to make CBBS command input more friendly,
;	allowing naive use to type things like r1234 or o1, or ? fnc
;	----------------
;GIVE BRIEF ASSISTANCE WITH COMMAND ABBREVIATIONS
;===>	(USED TO BE INLINE, NOW TYPES FROM FILE
;	"FUNCTION" TO ALLOW IT TO BE EASILY TAILORED)
;
ASIST	LXI	H,FUNCFL
	CALL	TYPEF
;
DEFUNCT MVI	A,CR	;KILL..
	STA	INBUF	;..STACKED LINES
;	
;---------------- MAIN ROUTINE ----------------
;
FUNCT	LXI	SP,STACK
	XRA	A	;GET 0
	STA	DKUPSW	;SHOW NO DISK UPDATE
	STA	CTLKSW	;ENABLE CTL-K
	STA	RTOGO	;KILL BLOCK RETRIEVE
	STA	STRFLG	;NO STRING MATCH IN FILE
	STA	INHELP	;ALLOW "X" TO WORK
	sta	flagall	;turn off auto-retrieve
;
 if xfer		;-------;file xfer support?
	lda	mroute		;in modem sub-menu?
	ora	a		;
	jnz	mfunct		;	yes
 endif			;-------;
;
 if 0			;testing action without following code
	LDA	PREVCHR	;IF PREV WAS C/R
	CPI	CR	;	THEN HAVE TO
	JZ	FUNCR	;	CR/LF
	CALL	NCRLF	;OTHERWISE, CRLF IF NOT IN COLUMN 1
 endif
FUNCR	CALL	NCRLF
FUNOCR	LHLD	FLAGPTR	;ANY FLAGGED
	MOV	A,H	;	MESSAGE
	ORA	L	;	TO RTRV?
	JNZ	RTRVFLG	; YES, DO IT
	lda	inbuf		;stacked 
	cpi	cr		;	commands?
	jnz	funget		;	y/ skip mine
;
;	allow nulls to be exactly set in case ^N was used.
;
	lxi	h,nullset	;check ^N null switch
	mov	a,m		;
	mvi	m,0		;	set it = 0
	ora	a
	jnz	cnul0		;do nulls if 
;
;	if no stacked answers, and "MINE" has not 
;	been executed, do the "MINE" for the user.
;
	lxi	h,minesw	;get 1-time only switch
	mov	a,m		;get it
	mvi	m,2		;turn it off
	dcr	a		;test it
	jz	domine		;do "mine" automatically.
	mvi	m,0
;
funget	CALL	GETVAR
	DB	'Function: '
;
	IF	PMMI OR IDS
	DB	'A,'	;ALTER BAUD RATE
	ENDIF
;
	DB	'B,C,D,E,G,H,K,'
 if minfnc
	db	'M,'
 endif
	db	'N,O,P,Q,R,S,'
;
	IF	CLOCK
	DB	'T,'
	ENDIF
;
 if ulog
	db	'U,'
 endif
;
	DB	'V,W,X,# '
	DB	CR,LF
	DB	'(OR ? IF NOT KNOWN)',0
	DW	ANSWER	;READ INTO ANSWER
	DW	-1	;HELP MSG #: PASS "HELP" AND "?"
			;BACK TO THIS ROUTINE
	DB	40	;MAX ANSWER LEN
;
mainf	lxi	h,answer
	mov	a,m	;GET FIRST CHAR OF REPLY
	CPI	CR	;C/R ENTERED?
	JZ	FUNCT	;..YES, ASK AGAIN
;
	call	ck09	;04/10/83 number test subroutine
	jnc	funcnum
mainf2	STA	SUMTYP	;REMEMBER "Q" OR "S"
	MOV	B,A	;SAVE CHAR
	inx	h	;SINGLE CHAR FNC?
	mov	a,m
	call	ck09q	;a number? (i.e. r1234 or o1) or "?func"
	cnc	stacknu	;	yes, stick in a space.
	cpi	','	;03/10/83 test erroneous "R nnnn", etc
	jz	czres	;	and stack answer if so.
	cpi	' '
czres	cz	restack
	CPI	CR
	JNZ	SPEC	;CHECK FOR PASSWORD
	MOV	A,B	;GET FIRST CHAR
	CPI	'?'
	JZ	ASIST
;
	IF	PMMI OR IDS
	CPI	'A'
	JZ	ALTBAUD
	ENDIF
;
	CPI	'B'
	JZ	REBUL	;TYPE BULLETIN
	CPI	'C'
	JZ	CCASE	;CHANGE CASE
	CPI	'D'
	JZ	DUPLX	;FLIP/FLOP DUPLEX MODE
	CPI	'E'
	JZ	ENTER
	CPI	'G'
	JZ	BYE
	CPI	'H'
	JZ	HELP
	CPI	'K'
	JZ	KILL
;
 if xfer
	cpi	'M'
	jz	mfunct
 endif
;
	CPI	'N'
	JZ	CNUL
	CPI	'O'
	JZ	SUMMRY	;one-line summary
	CPI	'P'	;CHG BELL PROMPT?
	JZ	BELL
	CPI	'Q'
	JZ	SUMMRY	;QUICK SUMMARY
	CPI	'R'
	JZ	RTRV
	CPI	'S'
	JZ	SUMMRY
;
	IF	CLOCK
	CPI	'T'
	JZ	PRDTIME
	ENDIF
;
	CPI	'V'	;assign
	JZ	VIDBS	;	video backspace?
;
	CPI	'W'
	JZ	REWEL
	CPI	'X'	;EXPERT USER?
	JZ	XPERT
	CPI	'#'
	JZ	STATS
 if ulog
	CPI	'*'
	JZ	PRPREV
	CPI	'U'
	JZ	uluser
 endif
	JMP	WHATM	;INVALID FUNCTION
;
; check for r1234, o1, ?r or other commands that need to have
; a blank inserted after the first char to make them understood
;
ck09q	cpi	'-'		;as in q-20 or r-3
	jz	ck09q2		;	yes, treat as a number
	call	ck09
	rnc			;ret if it was a #
ck09q2	lda	answer		;was it "?"
	cpi	'?'
	mov	a,m		;restore char
	stc			;show not to insert ' '
	rnz
;
;	got "?", see if valid delimiter
;
	cpi	' '
	stc
	rz
	cpi	cr
	stc
	rz
	ora	a		;show it needs stacking
	ret
;
; user keyed a number - not a function. 03/10/83 mod.
;
funcnum	call	ilprt
	db	'++I don''t know what to do with that number!',cr,lf
	db	'++Use r;nnnn or o;nnnn etc',cr,lf
	db	'++Type ? for a list of valid functions.',cr,lf,0
	jmp	funct
;
;CHECK FOR 2-BYTE FUNCTIONS.
;
SPEC	cpi	'R'		;xR?
	jnz	spnr
	lda	answer+2	;	xR(cr)?
	cpi	cr
	jnz	spnr
	lda	answer		;	OR, SR or QR?
	cpi 'O' ! jz summry
	cpi 'Q' ! jz summry
	cpi 'S' ! jz summry
;
; not qr/or/sr so try 4-byte op codes.
;
spnr	LXI	H,FTAB	;POINT TO FUNCTION TABLE
	CALL	CELOOK	;RET'S HL = FNC IF VALID
;
;NOT FOUND.  CHECK FOR OP FNC
;
	LDA	PASSFLG	;OPERATOR?
	ORA	A
	JZ	CEFNC	;PASSWORD HAS BEEN ENTERED
;
; 02/25/83 mod to look in synonym file for translation 
;	of command e.g. (BYE=G) etc. (one line per synonym)
;
	LDA	TWITSW
	ORA	A
	JNZ	whatm
	lxi	h,synfile
	call	setrd
	jc	whatm
synmat	lxi	h,answer
syncmp	call	rdbyte
	jc	whatm		;eof
	cmp	m
	inx	h
	jz	syncmp
;
;	got mismatch, if its an = sign and memory = CR,
;	then we found a synonym.
;
	cpi	'='
	jnz	synext
	dcx	h
	mov	a,m
	cpi	cr
	jnz	synext
	call	ilprt
	db	cr,lf,'Translating to the CBBS command: ',0
	lxi	h,inbuf
synpr	call	rdbyte
	jc	whatm
	mov	m,a
	call	type
	mov	a,m
	inx	h
	cpi	lf
	jnz	synpr
	jmp	funget
;
synext	call	rdbyte
	jc	whatm
	cpi	lf
	jnz	synext
	jmp	synmat
;
WHATM	LXI	H,WHAT	;GET 'DONT UNDERSTAND' MSG
	CALL	TYPEM0	;TYPE THE MESSAGE 
	LXI	H,ANSWER
	CALL	TYPEMCR
	LXI	H,QFNAME ;POINT TO ', (NAME)
	CALL	TYPEMCR
	call	ilprt
	db	cr,lf,'Type ? for list of valid commands.',cr,lf,0
 if tty
	mvi	a,'<'		;point to user's error
	call	log		;	to help observe 
	mvi	a,'='		;	problems
	call	log		;	via the hard copy log
	mvi	a,'='
	call	log
	mvi	a,' '
	call	log
 endif
	JMP	DEFUNCT
;
;4-BYTE FUNCTION TABLE
;
FTAB	DB	'HELP'
	DW		HELPNEW	;new user help
	DB	'SHOR'
	DW		SHORTEN	;shorten output
	DB	'NEWS'
	DW		NEWSCMD
	DB	'PASS'
	DW		GETPW
	DB	'CONT'
	DW		CECONT
	DB	'STAT'
	DW		CESTAT
 if pmmi
	db	'STOP'
	dw		stop		;stop bits
 endif
	db	'MINE'
	dw		mine
 if chat
	db	'CHAT'
	DW		cechat
	db	' HI '
	dw		hello
	db	'^CHA'
	dw		logchat
 endif
	DB	0
;
;====>	SHORT	COMMAND - ASKING FOR NO REDUNDANT
;		GRAPHIC CHARS, SPACE THRU "/"
SHORTEN	LDA	NONEFLG
	XRI	1
	STA	NONEFLG
	JZ	SHORTY
	CALL	ILPRT
	DB	'No ',0
SHORTY	CALL	ILPRT
	DB	'dup. chars.',CR,LF,0
	JMP	FUNCT
;
;SUBROUTINE TO ASK IF LOWER CASE CAN BE
;HANDLED.  (ASKED ONLY ONCE)
;
QCASE	LDA	CASE	;GET CASE
	INR	A	;WAS IT 0FFH (LOWER CASE OK)?
	RZ		;YES, RETURN
;HAVE WE ASKED?
	LDA	CASEFLG
	ORA	A
	RNZ		;YES, WE HAVE ASKED
	MVI	A,1	;SHOW WE HAVE ASKED
	STA	CASEFLG
;
	CALL	GETVAR
	DB	'LOWER CASE CHARACTERS, Y/N: '
	DB	'CAN YOUR TERMINAL HANDLE THEM',0
	DW	ANSWER
	DW	3	;HELP MSG #
	DB	9
;
	LDA	ANSWER
	CPI	'N'
	RZ
	CPI	'Y'
	JNZ	QCASE
	MVI	A,0FFH	;LOWER CASE OK.
	STA	CASE
	RET
;
;CHANGE CASE BETWEEN UPPER AND LOWER
;
CCASE	LDA	CASE	;GET CASE MASK
	XRI	0A0H	;FLIP
	STA	CASE	;SAVE IT BACK
	LXI	H,LCASEM ;POINT TO 'lower/UPPER'
	INR	A	;WAS MASK 0FFH?
	JZ	LCASE2
	LXI	H,UCASEM ;POINT TO 'UPPER'
LCASE2	CALL	TYPEM0
	JMP	FUNCT
;
;SWITCH BETWEEN HALF AND FULL DUPLEX,
;I.E. ECHOING AND NOT ECHOING, BY TOGGLING
;THE ECHO FLAG
;
DUPLX	LDA	ECHOFLG
	INR	A
	ANI	1
	STA	ECHOFLG
	JNZ	FDX
	CALL	ILPRT
	DB	CR,LF,'Half duplex (no echo) mode'
	DB	CR,LF,0
	JMP	FUNCT
FDX	CALL	ILPRT
	DB	CR,LF,'Full duplex (echo) mode'
	DB	CR,LF,0
	JMP	FUNCT
;
; nulls requested via ^N - tell of them.
;
cnul0	call	ilprt
	db	cr,lf,'You asked for 5 more NULLS (pressed N while '
	db		'CBBS typed)  ',cr,lf,0
;
;CHANGE NUMBER OF NULLS
;
CNUL	xra	a		;turn off switch set by ^N .
	sta	nullset
	CALL	ILPRT
	DB	'Nulls were: ',0
	LDA	NULLS
	CALL	PRDEC	;PRINT NNN
	LDA	INBUF	;ALREADY ANSWERED?
	CPI	CR
	CNZ	CRLF	;YES, CRLF
	CALL	GETVAR
	DB	' How many wanted: (usually 0)',0
	DW	ANSWER
	DW	4	;HELP MSG #
	DB	3
	LDA	ANSWER
	sui	CR	;12/23/82 make C/R = 0 nulls
	JZ	stanul
	CALL	GETNUM	;GET BINARY #
	JC	CNUL	;INVALID, RE-ASK
	MOV	A,H
	ORA	A	;>255?
	JNZ	CNUL
	MOV	A,L	;GET VALUE (0-255)
stanul	STA	NULLS
	CALL	NCRLF
	JMP	FUNCT
;
;RETYPE THE WELCOME FILE
;
REWEL	LXI	H,WELCOM
	CALL	TYPEF
	JMP	FUNCT
;
;RETYPE THE BULLETIN FILE
;
REBUL	LXI	H,BULFL
	CALL	TYPEF
	JMP	FUNCT
;
;TYPE THE NEWS FILE
;
NEWSCMD	CALL	GETVAR
	DB	'H/D: H for headlines, D for details:',0
	DW	ANSWER
	DW	0		;<==== NEEDS HELP MSG #
	DB	3
	LXI	H,NEWSFL
	LDA	ANSWER
	CPI	CR
	JZ	newstyp		;was "funct"
	CPI	'D'
	JZ	NEWSTYP	;TYPE ALL
	CPI	'H'
	JNZ	NEWSCMD
	CALL	TYPEFH	;ONLY HEADLINES
	JMP	FUNCT
;
NEWSTYP	CALL	TYPEF
	JMP	FUNCT
;
;TOGGLE BELL PROMPT FLAG
;
BELL	LDA	BELLF
	xri	1		;was cma
	STA	BELLF
	JMP	FUNCT
;
;TOGGLE EXPERT USER FLAG
;
XPERT	CALL	TOGGLEX
	JMP	FUNCT
;
TOGGLEX	LDA	EXPERT	;TOGGLE
	xri	1	;	THE.
	STA	EXPERT	;	FLAG
	RET
;
;VIDEO BACKSPACE MODE CHANGE:
;
;	ASKS FOR A CHAR 2 TIMES.  IF THEY MATCH, THE CHAR
;	IS SET AS AN ALTERNATE VIDEO BS CHAR.  NORMAL
;	^H STILL APPLIES.
;
VIDBS	LDA	EXPERT
	ORA	A
	JZ	VIDNX
	CALL	ILPRT
	DB	'B.S. char (Twice): ',0
	JMP	VIDBS2
;
VIDNX	CALL	ILPRT
	DB	CR,LF,'Type your choice of '
	DB	'video backspace char, 2 times:',0
VIDBS2	CALL	KEYIN	;GET IT
	CPI	CR	;C/R RETURNS
	JZ	FUNCT	;	TO MENU
	MOV	B,A	;SAVE FOR CMP
	PUSH	B	;SAVE
	CALL	KEYIN	;GET SECOND
	POP	B	;GET FIRST
	CMP	B	;SAME?
	JNZ	VDIFF	;	NO, SAY SO
	LXI	H,VNACH	;VIDEO, NOT ALLOWED
	CPI	'0'	;DISALLOW 0
	JC	VCMP
	CPI	'9'+1	;	THRU 9
	JC	VNALOW	;	
	CPI	'A'	;DISALLOW A
	JC	VCMP
	CPI	'Z'+1	;	THRU Z
	JC	VNALOW
	CPI	'A'+20H	;DISALLOW LOWER CASE A
	JC	VCMP
	CPI	'Z'+1+20H	;	THRU Z
	JC	VNALOW
;
;TEST FOR CERTAIN CONTROL CHARS NOT ALLOWED,
;	^U, ^R, ^W
;
VCMP	MOV	A,M
	CMP	B
	JZ	VNALOW
	INX	H
	ORA	A
	JNZ	VCMP
	MOV	A,B
	STA	BSCHAR
	CALL	ILPRT
	DB	CR,LF,'++SET++',CR,LF,0
	JMP	FUNCT
;
VNALOW	CALL	ILPRT
	DB	CR,LF
	DB	'Alpha, numeric, or system ctl chars '
	DB	'(L, U, R, W) not allowed',CR,LF,0
	JMP	VAGAIN
;
VNACH	DB	'L'-'@','U'-'@','R'-'@','W'-'@',0
;
VDIFF	CALL	ILPRT
	DB	CR,LF
	DB	'No match.  ',0
VAGAIN	CALL	ILPRT
	DB	CR,LF
	DB	'Try again. C/R to quit',CR,LF,0
	JMP	VIDBS
;
;GET PASSWORD TO GO INTO OPERATOR MODE
;
GETPW	LDA	INBUF+4	;MUST HAVE BEEN "PASS",CR
	CPI	CR
	JNZ	WHATM
	LXI	H,PASSFL ;POINT TO FILENAME
	CALL	SETRD	;OPEN FILE
	JC	NOPWF	;NOT FOUND
	CALL	RDBYTE	;PRIME BUFFER
;
;	11/13/82 mod to use new GETPASS function.
;
	call	getpass
	db	0
	dw	answer
	dw	0
	db	20
	mvi	a,1
	sta	passflg	;show not op.
	lda	answer		;02/26/83 just turn off op
	cpi	cr		;	mode if no 
	jz	funct		;	password entered.
	LXI	H,80H	;POINT TO PASSWORD
	lxi	d,answer
GETPWL	ldax	d
	CMP	M
	Jnz	pwbad
	INX	H
	inx	d
	SUI	CR	;END?
	JNZ	GETPWL
	STA	PASSFLG	;SET FLAG, 0=OK
	Jmp	PWOK	;OK. GOT IT.
;
;LOG FAILURE TO ENTER CORRECT PASSWORD
;
pwbad	LXI	H,LOGFL	;POINT TO FILENAME
	CALL	EXTEND
	CALL	WRCRLF
	MVI	A,']'
	CALL	WRBYTE
	LXI	H,PASSFL+1 ;POINT TO "PASSWORD"
	CALL	WRVAR	;WRITE IT
	MVI	A,' '
	CALL	WRBYTE
	CALL	WRNAME
06;	CALL	WRCRLF
	CALL	WREOF
	lxi	h,passfl+1	;02/27/83 mod to cause
	lxi	d,answer	;	the "don't understand"
	call	move5		;	prompt to say
	mvi	a,cr		;	"pass" instead of
	sta	answer+4	;	what was keyed.
	call	ding		;ding the log
	JMP	WHATM	;PROMPT "DON'T UNDERSTAND"
;
;IF THERE IS A NOTES FILE, TYPE IT
;
PWOK	LXI	H,NOTEFL
	CALL	TYPEF	;TYPE NOTES FILE
	JMP	FUNCT
;
NOPWF	CALL	ILPRT
	DB	'++NO PASSWORD FILE???',0
	JMP	FUNCT
;
;WAIT 3/4 SEC FOR CTL-C TO BE TYPED
;
CTLCWT	mvi	b,mhz/2
	LXI	H,0
CTLCW2	DCX	H
	MOV	A,H
	ORA	L
	JNZ	CTLCW2
	dcr	b
	JNZ	CTLCW2
	JMP	CTLCKS	;CHECK CTL-C, RETURN
;
	IF	TWITCK
;'TWIT' TEST OF NAME, RET ZERO IF INVALID NAME
;
;A "TWIT" IS SOMEONE LIKE "JOE,JOE" OR "BO,BO" WHICH
;CBBS/CHICAGO IS PLAGUED WITH, SO AT LEAST WE
;DENY HIM MESSAGE ACCESS.
;
TWITST	LDA	LNAME+1	;A TWIT WOULD USE..
	CPI	0DH	;..ONLY A LAST INITIAL
	JZ	ISTWIT
	LXI	H,LNAME
	LXI	D,FNAME
TWITLP	LDAX	D
	CMP	M
	RNZ
	INX	D
	INX	H
	CPI	0DH
	JNZ	TWITLP
ISTWIT	LDA	TWITCT
	INR	A
	ANI	3
	STA	TWITCT
	JZ	BYETWIT
	XRA	A
	RET
BYETWIT	MVI	A,ctlkoff	;disable ^K
	STA	CTLKSW
	JMP	BYEBYE
TWITCT	DB	0
	ENDIF		;TWITCK
;
; ====> Print prev hi msg # (if there was one)
;		(Prevhi byte 0 is 00H if none)
;
 if ulog
PRPREV	lxi	h,prevhi
	call	typem0
	call	ncrlf
	jmp	funct
 endif
 if pmmi
;
;====> STOP command - set modem stop bits.
;
stop	CALL	GETVAR
	DB	'# of modem stop bits: 1 or 2',0
	DW	ANSWER
	DW	0		;<==== NEEDS HELP MSG #
	DB	1
	LDA	ANSWER
	CPI	CR
	jz	funct
	sui	'1'
	jz	stop1		;set 1 stop bit
	dcr	a
	jz	stop2		;set 2 stop bits
	jmp	stop
 endif				;pmmi
;
; user entered xnnnn such as r1234 or o1, so change it to
; r 1234 and o 1 so it will be handled properly
;
stacknu	mvi	c,' '		;inserted char
stnins	mov	a,m		;get char
	mov	m,c		;store prev
	mov	c,a		;save for prev
	inx	h
	cpi	cr
	jnz	stnins
	mov	m,a
	lxi	h,answer+1	;fall into "restack"
;
;03/10/83 mod - restack an answer if 1-byte function is followed
;	by a space.  Specifically: if r,1234 or r 1234 was entered,
;	put "R" in answer, and put 1234 back into INBUF.
;
restack	push	b
	push	h
	lda	answer		;was it "? xxx"
	cpi	'?'
	jz	resnmsg
	call	ilprt
	db	'++Use ";" to separate answers, e.g.',cr,lf,0
	mvi	m,';'		;terminate 1-byte command
	dcx	h
	call	typemcr
	call	crlf
resnmsg	lxi	h,answer+1
	mvi	m,cr
	lxi	d,inbuf
restlp	inx	h
	mov	a,m
	stax	d
	inx	d
	cpi	cr
	jnz	restlp
;
;	if "? xxxx" was entered, change it to: "h;xxxx;;"
;
	lda	answer
	cpi	'?'		;"?" normally has no operands
	jnz	restret
	dcx	d
	mvi	a,';'
	stax	d		;store ";"
	inx	d
	stax	d		;	another ";"
	inx	d
	mvi	a,cr		;	then CR.
	stax	d
	pop	h
	pop	b
	mvi	b,'H'		;translate "?" to "H" command.
	mov	a,m
	ret
;
restret	pop	h
	pop	b
	mov	a,m
	ret
;
	LINK	CBBSBYE
                                                                                                  