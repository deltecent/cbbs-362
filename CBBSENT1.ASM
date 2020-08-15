;CBBS V3.6.2 	CBBSENT1.ASM - MSG ENTRY, PART 1
;06/22/83 17:15:28
;
;	LINKS TO CBBSENT2
;
;	O O O	O   O	O O O	  O
;	O	OO  O	  O	O O
;CBBS	O O	O O O	  O	  O	.ASM
;	O	O  OO	  O	  O
;	O O O	O   O	  O	O O O
;
;MODS (THRU 3.2 MOVED TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;	then to "history.036"
;
;---->	ENTER A MESSAGE
;
ENTER	EQU	$
;
	LXI	H,0	;SHOW ABOUT TO CLOBBER
	SHLD	FLAGPTR	;	FLAGGED MSG #'S
	IF	TWITCK
	CALL	TWITST	;DON'T LET 'TWITS'
	JZ	nofunc	;..ENTER MSGS
	LDA	TWITSW
	ORA	A
	JNZ	nofunc
	ENDIF
;
;DETERMINE THE NEXT MESSAGE NUMBER
;
	CALL	RDNEXT	;READ FILE 'NEXT'
02;START OF 02 MODS
;
;LIMIT # OF MSGS ALLOWED
;
	LXI	D,nxhnmsg	;TO hi digit of # ACTIVE
	LXI	H,nxhmmsg	;TO hi digit of MAX ALLOWED
	MVI	B,5		;set COMPARE LENGTH
	CALL	COMPR
	JC	ENROOM1	;ROOM FOR MORE
	JZ	ENROOM1
ENNRM	CALL	ILPRT
	DB	'++Sorry, no room for more msgs++',CR,LF,0
	LDA	PASSFLG
	ORA	A
	JZ	ENROOM	;ALLOW OPERATOR
	JMP	DEFUNCT	;KILL STACKED LINES
;
;	TWIT can't enter msg
;
nofunc	call	ilprt
	db	'++ Sorry, function unavailable ++',0
	jmp	defunct
;
;SEE IF AT MAX/USER
ENROOM1	LDA	ELEFT
	ORA	A
	JZ	ENNRM	;NO MORE
	DCR	A
	STA	ELEFT
ENROOM	EQU	$
02; END OF MODS
	CALL	ILPRT
	DB	'Msg ',0
	LXI	H,80H	;=MSG # IN DISK BUFFER
	CALL	TYPEMCR
	CALL	CRLF
;
	LXI	H,80H	;POINT TO MSG #
	LXI	D,MSGNO
	MVI	B,6	;5 DIGITS + CR
	CALL	MOVE	;MOVE TO MSGNO
	CALL	SETMSGN	;SET UP FILE NAME
	LDA	EXPERT
	ORA	A
	JNZ	GDATE
;
;EXPERTS DON'T SEE THE FOLLOWING:
;
	CALL	ILPRT
	DB	'Typing a dash for subject, etc. ',cr,lf
	DB	'backs up 1 question.',CR,LF
	DB	0
	JMP	GDATE
REDATE	MVI	A,CR
	STA	INBUF	;CANCEL STACKED INPUT
GDATE	EQU	$
;
	IF	CLOCK
	LXI	H,DATE
	CALL	RDDATE
	MVI	M,CR
	JNC	ENTER0	;CLOCK BOARD GOT DATE
	ENDIF
;
	CALL	GETVAR
	DB	'Date: Today''s date,'
	DB	' please (MM/DD/YY)',0
	DW	DATE
	DW	8	;HELP MSG #
	DB	8
	LDA	DATE
	CPI	'-'
	JZ	FUNCT
	CPI	' '
	JZ	REDATE
	CPI	CR
	JZ	REDATE
;EDIT DATE (FOR SLASHES, ALLOWING M OR MM)
	LXI	H,DATE+1
	MVI	A,'/'
	CMP	M
	JZ	ENTSL
	INX	H
	CMP	M
	JNZ	REDATE
;GOT FIRST SLASH, CHECK FOR SECOND
ENTSL	INX	H
	INX	H
	CMP	M
	JZ	ENTER0	;SINGLE DIGIT DAY
	INX	H
	CMP	M
	JNZ	REDATE
	JMP	ENTER0
;
;10/17/81 COMMENTED OUT - SCITRONICS DOESN'T GLITCH
;
;01 ;
;01 ;VALIDATE DATE ENTERED FROM CLOCK BOARD
;01 ;(CBBS/CHI COMES IN WITH MONTH=99 SOME TIMES)
;01 ;
;01 ENCKDAT	LDA	DATE
;01	CPI	'9'
;01	JZ	REDATE
;01	JMP	ENTER0
;
;REENTER WHO TO, IT WAS BAD
;
REWHO	MVI	A,CR
	STA	INBUF	;CANCEL STACKED LINES
;
;10/17/81 MODS SEE IF THIS IS AN OPERATOR CONTINUED MSG
;
ENTER0	LXI	H,MCONT	;POINT TO CONTINUE FLAG
	MOV	A,M	;GET IT
	MVI	M,0	;	AND ZERO IT
	ORA	A
	JZ	ENTER1
	lda	msgto		;zero if nothing to continue
	ora	a
	jz	enter1
	LXI	H,CONTMSG ;POINT TO "(CONT'D)"
	LXI	D,SUBJ
	MVI	B,9
	CALL	MOVE
	JMP	ENCLR
;
CONTMSG	DB	'(CONT''D)',CR
;
;10/17/81 END OF MODS
;
ENTER1	CALL	GETVAR
	DB	'Who to: (20 char max.) '
	DB	'(or use: ALL)',0
	DW	MSGTO
	DW	0	;future "help" msg pointer
	DB	20	;MAX LEN
	LDA	MSGTO
	CPI	' '
	JZ	REWHO
	CPI	CR
	JZ	FUNCT	;%07/11/81 WAS REWHO
	LDA	MSGTO+1	;will return if
	CPI	CR	;	'-<cr>' entered.
	JZ	FUNCT
;
;12/03/78 IF DATE ENTERED (NO LONGER ASKED FOR
;IF CLOCK BOARD) THEN IGNORE IT, SKIP TO NEXT FIELD
;
	IF	CLOCK
	LDA	MSGTO
	call	ck09	;number?
	Jc	ENSUBJ
	LDA	MSGTO+1
	CPI	'/'
	JZ	ENTER0	;SKIP DATE
	LDA	MSGTO+2
	CPI	'/'
	JZ	ENTER0
	ENDIF
;
	LDA	MSGTO
	CPI	'-'
	JZ	REDATE
;
	JMP	ENSUBJ
RESUBJ	MVI	A,CR
	STA	INBUF	;CANCEL STACKED LINES
ENSUBJ	CALL	GETVAR
	DB	'Subj: Be Specific!  '
	DB	'Press C/R for examples',CR,LF
	DB	CR,LF,'Message subject (30 '
	DB	'chars max)',0
	DW	SUBJ
03	DW	10	;HELP MSG #
	DB	30
	LDA	SUBJ
	CPI	' '
	JZ	RESUBJ
	CPI	'-'
	JZ	REWHO	;BACK UP 1 QUESTION
	CPI	CR	;NOTHING ENTERED?
	JNZ	REPASS
	CALL	ILPRT
	DB	CR,LF,'Typical:',CR,LF
	DB	'xxxxxx for sale '
	DB	'	(Be precise, not just "for sale")',CR,LF
	DB	'need help with xxxxxx',CR,LF,0
	JMP	RESUBJ
;
;09/13/81 PASSWORD LOGIC CHANGED: NOW ALWAYS ENTER ONE.
;
REPASS	CALL	GETVAR
	DB	'4-char Password: Enter 4 letter delete password',cr,lf
	DB	'(If you just press return, '
	DB	'anyone can kill your msg): ',0
	DW	PASSWD
03	DW	12	;HELP MSG #
	DB	4
	LXI	H,PASSWD
	MOV	A,M
	CPI	'-'
	JZ	RESUBJ
	MVI	B,0	;INIT COUNT
	CALL	COUNTC	;SEE HOW MANY CHARS
	ORA	A
	JZ	ENNOPW
	CPI	4
	JNZ	REPASS
;
ENNOPW	LDA	EXPERT	;11/18/81 REV
	ORA	A	;
	JNZ	NOHELP	;
	CALL	GETVAR
	DB	'Help Y/(N): Review steps to '
	DB	'enter a message:',0
	DW	ANSWER
03	DW	13	;HELP MSG #
	DB	3
	LDA	ANSWER
	CPI	'-'
	JZ	REPASS
	CPI	'Y'	;11/18/81 MOD: "N" DEFAULT
	JNZ	NOHELP
;TYPE THE 'ENTINTRO' FILE
	LXI	H,ENINFL ;POINT TO FILENAME
	CALL	TYPEF	;TYPE THE FILE
NOHELP	CALL	QCASE	;SEE IF LOWER CASE
	LDA	EXPERT	;EXPERT USER?
	ORA	A
	JNZ	ENCLR	;SKIP PROMPT IF SO
	CALL	ILPRT
	DB	CR,LF
	DB	'Enter the msg, 79 chars/line max.  ',0
	CALL	ILPRT
	DB	'(Bell rings at 75).',0
	CALL	ILPRT
	DB	CR,LF,'Use ctl-I (tab) to space over.'
	DB	CR,LF,'-----> WHEN DONE ENTERING, '
	DB	'press return twice.'
	DB	CR,LF,'-----> TO ABORT, ENTER: ABORT'
	DB	CR,LF,'THEN PRESS RETURN'
	DB	CR,LF,0
;
ENCLR	LXI	H,'01'
	SHLD	LINO
	DCR	H	;MAKE IT '00' %
	SHLD	HILINE	;SAVE HI LINE #
	mvi	a,1	;set binary line #
	sta	blino	;	=1
	LXI	H,MSGBF	;POINT TO MAXL x 128 AREA	;was 64
	SHLD	LINEAD	;SAVE LINE ADDR
;STORE 0 AT START OF EACH LINE + past end of buffer
	LXI	D,128	;was 64
	MVI	B,MAXL+1
ENST0	MVI	M,0
	DAD	D
	DCR	B
	JNZ	ENST0
ENLOOP	MVI	A,ctlkent	;SET SO CTL-K GOES
	STA	CTLKSW		;	TO ENCOMD, NOT FUNCT
	CALL	GETVARN	;NO TRANSLATE
LINO	DB	'## ',0
LINEAD	DW	$-$	;MODIFIED TO POINT TO BUFFER
03	DW	14	;HELP MSG #
	DB	79	;MAX LEN (was 60)
;SEE IF END, I.E. EMPTY LINE
	LHLD	LINEAD
	MOV	A,M	;CHECK FOR
	CPI	CR	;BLANK LINE
	JZ	ENCOMD	;END OF ENTER, GET COMMAND
;SEE IF 'ABORT' ENTERED
	LHLD	LINEAD	;MOVE TO DE FOR..
	XCHG		;..XLATE TO UPPER CASE
	LXI	H,ABORTM
	MVI	B,6	;'ABORT',CR
	CALL	COMPR	;ABORT?
	JNZ	NOABORT
;
;ABORT REQUESTED, VERIFY IT'S WANTED
;
VABORT	CALL	GETVAR
	DB	'++ABORT DISCARDS YOUR '
	DB	'MESSAGE++',CR,LF
	DB	'ENTER Y TO THROW IT AWAY',0
	DW	ANSWER
03	DW	15	;HELP MSG #
	DB	3
	LDA	ANSWER
	CPI	'Y'
	JZ	FUNCT
	JMP	ENCOMD	;GET SUBCOMMAND
;
;BUMP LINE POINTER
;
NOABORT	LHLD	LINEAD
	LXI	D,128	;was 64
	DAD	D
	SHLD	LINEAD
;BUMP LINE #
	LHLD	LINO
	SHLD	HILINE
	LXI	H,LINO+1
	CALL	ADD1	;ASCII ADD
	lxi	h,blino		;bump
	inr	m		;	binary line #
; MAXL LINES?
	mov	a,m
	cpi	maxl+1
	jz	enfull
; prompt for 1-2-3 remaining?
	cpi	maxl-2
	jc	enloop
;PRINT NUMBER OF LINES REMAINING (1, 2, 3)
	cma
	adi	maxl+2+'0'	;MAKE IT 1, 2, OR 3
	PUSH	PSW	;(FOR LINE/LINES TEST)
	CALL	TYPE	;TYPE 1, 2, OR 3
	CALL	ILPRT
	DB	' line',0
	POP	PSW
	CPI	'1'
	MVI	A,'s'
	CNZ	TYPE	;MAKE IT 'LINES' IF >1
	LDA	EXPERT	;EXPERT?
	ORA	A
	JNZ	ENXCR	;SKIP FOLLOWING MSG
	CALL	ILPRT
	DB	' left.  Press return to end'
	DB	CR,LF,0
	JMP	ENLOOP
;
ENXCR	CALL	CRLF	;EXPERT
	JMP	ENLOOP
;
;BUFFER FULL
;
ENFULL	CALL	ILPRT
	DB	CR,LF
	DB	'Message full',CR,LF,0
	MVI	A,CR
	STA	INBUF	;KILL STACKED LINES
	JMP	ENCOMD	;GET SUBCOMMAND
;
;SAVE THE MSG
;
;OPEN AND EXTEND THE APPROPRIATE DISK FILE
;(MESSAGE.NNX WHERE NN IS THE FIRST 2 DIGITS
;OF THE MESSAGE #)
;
ENSAVE	CALL	ILPRT
	DB	'Writing to disk.',CR,LF,0
	MVI	A,ctlkoff	;DISABLE CTL-K ABORT
	STA	CTLKSW
;
;KEEP RUNNING EVEN IF LOSS OF MODEM CARRIER
;BECAUSE WE ARE UPDATING THE DISK
;
	STA	DKUPSW
	CALL	SETMSGN	;SETUP MSG # IN NAME
	LXI	H,MSGFN ;POINT TO FILENAME
	CALL	EXTEND	;OPEN (OR MAKE IF NEW)
;
;WRITE THE FILE HEADER
;
	CALL	WRHDR	;WRITE HEADER
;
;WRITE THE MESSAGE ITSELF
;
	LXI	H,MSGBF	;POINT TO FIRST LINE
	LXI	D,128	;was 64
	call	deind	;de-indent if entire msg was indented.
;
;	is leading line blank?  Ignore it if so.
;
enwrsb	mov	b,h
	mov	c,l		;copy to hl
enwrsbl	ldax	b
	inx	b
	ora	a
	jz	enwrl
	cpi	' '
	jz	enwrsbl
	cpi	tab
	jz	enwrsbl
	cpi	cr
	jnz	enwrl
;
;	line is empty, skip it
;
	dad	d		;point to next line
	jmp	enwrsb
;
ENWRL	MOV	A,M	;END?
	ORA	A
	JZ	ENWRCLS	;YES, CLOSE FILE
	PUSH	H
	CALL	WRLINE	;WRITE THRU CR/LF
	POP	H
	DAD	D
	jmp	ENWRL
;
;END OF WRITE, CLOSE THE FILE
;
ENWRCLS	CALL	WREOF	;EOF, THEN CLOSE
;
;UPDATE THE 'NEXT' MESSAGE NUMBER FILE
;
	CALL	RDNEXT	;READ THE FILE
	LXI	H,nxlmsg	;POINT TO UNITS
	CALL	ADD1	;BUMP IT BY 1
;
;	save the hi msg #
;
	lxi	h,nxhmsg
	lxi	d,highmsg
	call	move5
;
;UPDATE THE # OF ACTIVE MESSAGES
;
	LXI	H,nxlnmsg	;POINT TO UNITS
	CALL	ADD1	;BUMP IT BY 1
;
;WRITE "NEXT" FILE BACK
;
	XRA	A	;GET 0
	STA	FCBRNO	;WRITE RECORD 0
	LXI	D,FCB
	MVI	C,WRITE
	CALL	BDOS	;UPDATE IN PLACE
	ORA	A	;OK?
	JZ	CLSNXT	;OK, WRITE SUMMARY
	CALL	ILPRT
	DB	'++ERROR writing "NEXT" file',CR,LF,0
	JMP	TELLUS
03;CLOSE NEXT FILE
CLSNXT	CALL	CLOSENX
;
;UPDATE THE SUMMARY FILE
;
	CALL	ILPRT
	DB	CR,LF
	DB	'Updating summary.',CR,LF,0
	LXI	H,SUMFL
	CALL	EXTEND
	CALL	WRHDR	;WRITE HEADER
	CALL	WREOF	;WRITE EOF, CLOSE
	JMP	FUNCT
;
; subroutine to de-indent the message in case a twit is
; wasting time/space indenting the WHOLE message.
;
deipass	pop	h		;another pass thru.
;
deind	mov	a,m		;test if		3.6.1
	ora	a		;	empty msg	3.6.1
	rz			;	y/return.	3.6.1
	push	h		;save buf ptr
deilp	mov	a,m		;get char
	dad	d		;to next line
	ora	a		;eom?
	jz	deiz		;zap the indent
	cpi	' '
	jz	deilp		;loop while spaces
;
; at least one line is not indented - return
;
deir	pop	h
	ret
;
deiz	pop	h
	push	h
deizl	mov	a,m
	ora	a		;end of msg?
	jz	deipass		;yes, try another pass
	push	h		;save cur line
deizl2	inx	h		;to next char
	mov	a,m		;get char
	dcx	h		;back up
	mov	m,a		;store it back
	inx	h
	cpi	cr
	jnz	deizl2
	pop	h		;get this line pointer
	dad	d		;to next
	jmp	deizl
;
;SUBROUTINE TO WRITE HEADER TO FILE,
;USED FOR BOTH MESSAGE AND SUMMARY FILE
;
WRHDR	MVI	A,'G'-40H ;BELL CHAR AS HDR I.D.
	CALL	WRBYTE
	LXI	H,MSGNO
	CALL	WRVARC	;MESSAGE #
	LXI	H,HILINE ;# LINES
	CALL	WRVARC
	LXI	H,DATE
	CALL	WRVARC	;DATE
	CALL	WRNAME	;"FIRST LAST,"
	LXI	H,MSGTO
	CALL	WRVAR	;WHO MESSAGE IS TO
	CALL	WRCRLF	;CR/LF
	LXI	H,SUBJ
	CALL	WRVARC	;SUBJECT
	LXI	H,PASSWD ;PASSWORD
	CALL	WRVAR
	CALL	WRCRLF	;THEN FINAL CR/LF
	RET		;FROM WRHDR
;
	LINK	CBBSENT2 ;TO NEXT .ASM FILE
  