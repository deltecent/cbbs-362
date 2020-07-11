;CBBS V3.6.2 	FILE CBBSMAIN.ASM - MAINLINE
;09/24/83 08:10:08
;
;LINKS TO CBBSFUNC.ASM
;
;	O   O	O O O	O O O	O   O
;	OO OO	O   O	  O	OO  O
; CBBS	O O O	O O O	  O	O O O	.ASM
;	O   O	O   O	  O	O  OO
;	O   O	O   O	O O O	O   O
;
;MODIFICATIONS LOG (last first)
;
;10/17/82	Split out from CBBS.ASM so CBBS.ASM can be
;		all the things an implementor need change.
;		Erased all previous rev indications.
;
;		Also split out "match" as a subroutine to
;		scan a file matching a name.
;
START	LXI	SP,STACK
	CALL	INIT		;SET UP I/O JMP ADDRESSES
;
;PICK UP THE PHONE, CHECK FOR CARRIER FOR 15 SEC.
;
	MVI	A,ctlkoff	;DISABLE..
	STA	CTLCSW		;..CTL-C
	sta	ctlksw		;	&ctl-k
	IF	NOT TEST
	call	rdssw		;read ssw, ani remote
	CNZ	CONNECT		;(EXITS IF NO CARRIER)
	ENDIF
;
;TYPE THE WELCOME MSG AS CONTAINED IN WELCOME FILE   
;
WELL	EQU	$
;
	IF	TTY
	MVI	A,ttywid	;FAKE UP COLUMN 02/27/83 mod
	STA	COL		;SO LOG TTY WILL
	MVI	A,LF		;C/R FOR THIS NEW USER
	CALL	LOG
	ENDIF
;
;PRINT VERSION
;
	MVI	B,6		;SEND 6..
	CALL	NULLP		;..NULLS
	CALL	ILPRT
	DB	'CBBS(R) '
	DB	'0'+VERS,'.'
	DB	'0'+MODIF,'.'
	DB	'0'+LEV
	db	hack		;alpha suffix
	DB	CR,LF,0
;
;PRINT DATE/TIME
;
 IF CLOCK
	MVI	B,6		;DO 6 NULLS..
	CALL	NULLP		;..BEFORE TIME
	CALL	PRTIME		;PRINT DATE,TIME
	lxi	h,answer+9	;move time from here
	LXI	d,LGINTIM	;	to here
	mvi	b,8		;	for 8
	call	move
	lxi	h,answer	;save date
	lxi	d,date		;	for user
	mvi	b,8		;	logging
	call	move
 ENDIF
;
;09/13/81 MODS TO WRITE DATE/TIME TO HARD-COPY LOG
;
 IF CLOCK AND TTY
	MVI	A,ttywid-18
	STA	COL		;FORCE C/R AFTER DATE/TIME
	LXI	H,ANSWER 	;WHERE "PRTIME" STORED DATE/TIME \RDTIME\
LOGTIME	PUSH	H
	MOV	A,M
	CALL	LOG
	POP	H
	INX	H
	MOV	A,M
	ORA	A
	JNZ	LOGTIME
	MVI	A,CR
	CALL	LOG
 ENDIF
;09/13/81 END
;
 if clock and wards
	call	wcltime		;clear stat, log time
 endif
;
;CHECK FOR CTL-C, TO SAVE OPENING WELCOME FILE
;
WELL1	XRA	A		;SHOW CTL-C..
	STA	CTLCSW		;..ENABLED
	mvi	a,6
	sta	tries		;init for "bad line" testing
	mvi	a,ctlkt1	;^K goes to "first time on sys?"
	sta	ctlksw
	CALL	CTLCWT		;WAIT 3/4 SEC, THEN TRY
	LXI	H,WELCOM 	;POINT TO FILENAME
	CNZ	TYPEF		;TYPE THE WELCOME FILE
;
;TYPE BULLETIN FILE IF IT EXISTS
;
NOWEL	CALL	CRLF
;
;CHECK FOR CTL-C, TO SAVE OPENING BULLETIN FILE
;
	CALL	CTLCWT		;WAIT 3/4 SEC FOR CTL-C
	LXI	H,BULFL		;POINT TO FILE
	CNZ	TYPEF		;TYPE IF NO CTL-C
;
;IF THIS IS THE USERS FIRST TIME ON THE SYSTEM,
;PROCESS THE FILE 'FIRSTIME' WHICH SUPPLIES
;SOME INFO ON THE SYSTEM'S USAGE.
;07/15/81 ^K COMES HERE NOW IF CTLKSW SET TO [ctlkt1]
;
ASKT1	lxi	h,tries		;check if been here too often
	dcr	m		;count down 5 times -
	jz	disc		;	must be bad line - disc.
	mvi	a,'N'
	sta	t1flag
	MVI	A,CR		;BLANK 'WHERE FROM' FIELD
	STA	SUBJ		;..IN CASE IT'S NOT ENTERED.
;
; 09/26/82 \kill case test stuff\
;
	CALL	GETVAR
	DB	CR,LF
	DB	'Y/N: want CBBS "1st time user" info',0
	DW	ANSWER
	DW	0		;HELP MSG #
	DB	9		;MAX ANSWER LEN
;
	LDA	FIRSTCH		;GET UN-TRANSLATED 1ST CHAR
	ani	5fh		;make upper case
	sta	T1FLAG		;remember if 1ST TIME
	CPI	'N'
	JZ	GETFN
	CPI	'Y'
	JNZ	ASKT1
	mvi	a,ctlkfn	;direct ^K 
	sta	ctlksw		;	to "getfn"
;
;ASK WHERE CALLING FROM
;
WHERE	CALL	GETVARN
	DB	CR,LF
	DB	'(Optional) ',CR,LF
	DB	'What city/state are you calling from',0
	DW	SUBJ		;TEMP STORE IT HERE
	DW	0		;NO HELP MSG #
	DB	30		;MAX LEN
	LXI	H,TIME1		;POINT TO FILENAME
	CALL	INTQF		;INTERPRET THE QUESTION FILE
;
;GET CALLER'S NAME
;
GETFN	call	ncrlf		;cr/lf if not col 1
	mvi	a,ctlkfn	;direct ^K 
	sta	ctlksw		;	to "getfn"
	CALL	GETVAR		;GET THE NAME
	DB	'What is your FIRST name',0
	DW	FNAME
	DW	0		;HELP MSG #
	DB	19		;MAX LEN
	lxi	h,FNAME
	mov	a,m
	CPI	'A'		;FORCE ALPHA
	JC	GETFN
	CPI	'Z'+1
	JNC	GETFN
	call	trtrsp		;trunc. trailing spaces.
GETLN	CALL	GETVAR
	DB	'(Press return to return to "first name" '
	DB	'question)',CR,LF
	DB	'What is your LAST name',0
	DW	LNAME		;READ LAST NAME
	DW	0		;HELP MSG #
	DB	19		;MAX LEN
	lxi	h,LNAME
	mov	a,m
	CPI	CR
	JZ	GETFN
	CPI	'-'
	JZ	GETFN
	CPI	'A'		;FORCE ALPHA
	JC	GETLN
	CPI	'Z'+1
	JNC	GETLN
	call	trtrsp		;trunc. trailing spaces.
;
;MAKE SURE FIRST + LAST NOT > 20 CHARS
;
	LXI	H,FNAME
	CALL	COUNTC0		;INIT B=0, COUNT CHARS
	LXI	H,LNAME
	CALL	COUNTC
	MOV	A,B		;GET COUNT
	CPI	20		;+ 1 SPACE BETWEEN
	JC	CKNOK		;CHECK IF NAME OK
	CALL	ILPRT
	DB	'Sorry, first name + last name '
	DB	'may not be > 19 long',CR,LF,0
	JMP	GETFN
;
;IF FIRST TIME USER, ASK IF NAME SPELLED OK.
;
;EXPERIENCED USERS DON'T NEED THIS QUESTION,
;AS THEY SHOULD KNOW CTL-U, DEL, ETC EDITING.
;
CKNOK	LDA	T1FLAG		;1ST TIME?
	CPI	'N'
	JZ	LOGIN		;NOT 1ST TIME
	CALL	ILPRT
	DB	'Hi, ',0
	call	typname
	CALL	GETVARN
	DB	'Y/N Did I get your name right',0
	DW	ANSWER
	DW	0		;NO HELP MSG #
	DB	9		;MAX ANSWER LEN
	LDA	ANSWER
	ANI	5FH		;UPPER CASE
	CPI	'N'
	JZ	GETFN
	CPI	'Y'
	JNZ	CKNOK
	CALL	ILPRT
	DB	'(NOTE: correcting done only if '
	DB	'you said "1st time")',CR,LF,0
;
;LOG: (DATE TIME [IF THERE IS A CLOCK BOARD])
;(CALLER #),(FIRST NAME),(LAST NAME),(WHERE FROM)
;
LOGIN	CALL	ILPRT
	DB	CR,LF
	DB	'Logging name to disk...',0
	MVI	A,ctlkoff
	STA	DKUPSW		;SET DISK UPDATE IN PROGRESS
	STA	CTLKSW		;DISALLOW CTL-K
;GET THE CALLER # FROM FILE "NEXT"
; (FORMAT IS: 
;
; NNNNN(CR)(LF)CCCCC(CR)(LF)AAAAA(CR)(LF)MMMMM(CR)(LF)(CTL-Z)
;
; WHERE NNNNN IS NEXT MSG #, CCCCC IS CALLER #,
; AAAAA IS THE # OF ACTIVE MESSAGES
;MMMMM IS MAX ACTIVE MSGS).
	CALL	RDNEXT
;save caller # so it can be logged
	LXI	H,nxhclr	;from high digit of high caller 
	LXI	D,CALLERN 	;..to,
	MVI	B,6		;..length
	CALL	MOVE		;move incl. c/r
; save hi msg # to stop r;+
	lxi	h,80h
	lxi	d,highmsg
	call	move5
	LXI	H,LOGFL		;point to filename
	CALL	EXTEND		;extend the file
;
	CALL	WRCRLF		;CRLF BEFORE
;
;WRITE DATE AND TIME TO LOG FILE
	IF	CLOCK
	CALL	WRTIME
	ENDIF			;CLOCK
;
	LXI	H,CALLERN
	CALL	WRVARC		;WRITE CALLER #,
	LXI	H,SPEED		;WRITE BAUD RATE
	CALL	WRVARC		;(1, 3, 4, OR 6)
	CALL	WRNAME		;"FN LN,"
	LXI	H,SUBJ		;AND 'WHERE FROM'.
	CALL	WRVARC
;
;NOP THE CALL WRCRLF, SO THE E.T. WILL FOLLOW.
;	CALL	WRCRLF	
	CALL	WREOF		;CLOSE FILE
	CALL	CRLF
	XRA	A		;GET 0
	STA	DKUPSW		;NOT UPDATING DISK
;09/13/81 KILL INSTR PER LEWIS MOSELEY,
; 'CAUSE TWITS COULD ^K PAST NAME CHECK
;	STA	CTLKSW		;ALLOW CTL-K
;
;EDIT 01 PULLED CODE OUT OF HERE, MOVED TO
;"STATSUB" AT END OF CBBS.ASM
;
	CALL	ILPRT
	DB	'You are',0
	CALL	STATSUB		;PRINT CALLER, MSG, MSGS
;
 if wards		;-------;
;				;
; log name, etc to VIO status line
;				;
	lxi	h,callern	;
	call	viotype		;
	lxi	h,fname		;
	call	viotype		;
	lxi	h,lname		;
	call	viotype		;
 endif			;-------;wards
;
;WRITE BACK FILE W/MSG # AND CALLER #
;
	XRA	A
	STA	FCBRNO		;BACK TO SECTOR 0
	LXI	D,FCB
	MVI	C,WRITE
	CALL	BDOS		;WRITE BACK
	ORA	A		;WAS IT OK?
				;MODS:
	JNZ	NXERR
	LXI	D,FCB
	MVI	C,CLOSE
	CALL	BDOS
	INR	A
	JZ	NXERR
;
;12/09/78 ADD NOTIFY TEST
;
 IF NOT NOTIFY
	JMP	FUNCT
 ENDIF
;
 IF NOTIFY
	JMP	CKMSGS
 ENDIF
;
NXERR	CALL	ILPRT
				;END OF MODS
	DB	'++Error writing user #',CR,LF,0
	JMP	TELLUS
;
	IF	NOTIFY
;
;LOOK IN "NEXT" FILE FOR A MSG TO THIS CALLER
;
CKMSGS	CALL	RDNEXT		;PRIME BUFFER
findtwo	call	findnam		;find name
	jc	ulogf
	CALL	CRLF
CKNTLP	CALL	RDBYTE
	JC	ulogf
	CPI	']'		;END OF MSG?
	JZ	CKNSY
	CALL	TYPE
	JMP	CKNTLP
;
;CHECK NAME FOR SYSTEM FUNCTION:
;
; 	/	HANG UP ON THE CALLER
;	*	FLAG AS "TWIT" (NO KILL, ENTER)
;
CKNSY	CALL	RDBYTE
	CPI	'/'
	JZ	DISC		;DISCONNECT
	CPI	'*'
	JZ	TWITSET
	CPI	'+'		;IF '+', CONTINUE (TO ALLOW
	JZ	findtwo		;	INDIVIDUAL + "*.*".
ulogf:
 if ulog
	call	ulogin
 endif
	JMP	FUNCT
;
; 09/24/83 subroutine to type name (at logon, signing comments,
;	and to identify chat.
;
typname	LXI	H,FNAME
	CALL	TYPEMCR		;TYPE FIRST NAME
	MVI	A,' '
	CALL	TYPE
	LXI	H,LNAME
	CALL	TYPEMCR		;TYPE LAST NAME
	jmp	CRLF
;
TWITSET	MVI	A,1
	STA	TWITSW
	call	ding		;ding log tty
	JMP	FUNCT
;
; 10/19/82 split this out as subroutine.
;	Call FINDNAM after opening ANY file.
;	file must have format [firstname,lastname,....
;	With * allowed.  Returns with read pointer
;	following the ",".
;
findnam	CALL	RDBYTE
	RC			;NO MSGS
	CPI	'['		;NAME HDR?
	JNZ	findnam
;MATCH THE NAME
	LXI	H,FNAME
	CALL	MATCH
	RC
	JNZ	findnam
	LXI	H,LNAME
	CALL	MATCH
	RC
	JNZ	findnam
	ret		;OK, NAME MATCHED.
;
;MATCH A NAME AGAINST THE FILE
;
; 10/17/82 mod as subroutine, carry on EOF, C/R on match.
;
MATCH	CALL	RDBYTE
	RC
	CPI	'*'		;MATCH ANY?
	JZ	MATCHOK
	CPI	','		;DELIM?
	JZ	MATCHCR		;YES
	CMP	M		;CHAR MATCH?
	stc			;ensure carry
	cmc			;	off - no error.
	RNZ			;..NO match, ret.
	INX	H
	JMP	MATCH
;
;OK, SKIP TO NEXT DELIM
;
MATCHOK	CALL	RDBYTE
	rc
	CPI	','		;DELIM?
	RZ			;YES
	JMP	MATCHOK
;
;MATCH THE C/R AT END OF NAME
;
MATCHCR	MOV	A,M		;get char from name
	CPI	0DH
	RET			;ZERO SET IF OK
	ENDIF			;NOTIFY
;
;"#" COMMAND (STATS)
;
STATS	CALL	ILPRT
	DB	'Next',0
	CALL	STATSUB		;PRINT
	lda	prevhi
	ora	a
	jz	statmrk
	call	ilprt
	db	'*=',0
	lxi	h,prevhi
	call	typem0
	call	ilprt
	db	' (hi msg last call)',cr,lf,0
;
;	see if any marked msgs, tell of them if so.
;
statmrk	lxi	h,markcnt
	mov	a,m
	ora	a
	jz	funct
	mvi	c,1
	lxi	d,marktbl
stamlp	mvi	a,'#'
	call	type
	mov	a,c
	adi	'0'
	call	type
	mvi	a,'='
	call	type
	mvi	b,5
stml2	ldax	d
	call	type
	inx	d
	dcr	b
	jnz	stml2
	call	space
	mov	a,c
	inr	c
	cmp	m
	jc	stamlp
	jmp	funct
;
;TYPE CALLER #, HI MSG #, # OF MSGS.
;CALLED AT LOGON, AND BY # (STATS) FUNCTION.
;
STATSUB	CALL	ILPRT
	DB	' caller ',0
	CALL	RDNEXT		;GET "NEXT" TO 80H
	LXI	H,87H		;POINT TO NUMBER
	CALL	TYPEMCR
;
;INCREMENT CALLER # (NOP ON # COMMAND, BECAUSE
;ITS NOT WRITTEN BACK)
;
	LXI	H,8BH		;TO UNITS DIGIT
	CALL	ADD1
;
;TYPE THE NEXT MESSAGE NUMBER
;
	CALL	ILPRT
	DB	'; next msg =',0
	LXI	H,80H		;POINT TO NUMBER
	PUSH	H		;SAVE POINTER
	CALL	TYPEMCR
;	CALL	CRLF
;
;TYPE # OF ACTIVE MESSAGES
;
	CALL	ILPRT
	DB	';',0
	LXI	H,8EH
	CALL	TYPEMCR
	CALL	ILPRT
	DB	' active msgs.',CR,LF,0
;
;SAVE HI MSG # FOR "R;-"
;
	POP	H		;MSG # POINTER
	LXI	D,MSGNO
	MVI	B,5
	CALL	MOVE
;
	RET
;
	LINK	CBBSFUNC 	;NEXT .ASM FILE
                                                  