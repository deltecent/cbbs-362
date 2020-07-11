;CBBS V3.6.2 	CBBSOPER.ASM - OPERATOR FUNCTIONS (EXCEPT MESSAGE KILL)
;09/24/83 09:39:05
;
;	LINKS TO CBBSKILL
;
;	O O O	O O O	O O O	O O O
;	O   O	O   O	O	O   O
; CBBS	O   O	O O O	O O	O O O	.ASM
;	O   O	O	O	O O
;	O O O	O	O O O	O   O
;
;
;MODS LOG: (THRU 3.2 MOVED TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;	then to "history.036"
;
;-----> VALIDATE CE FUNCTION
;
;FORMAT FILENAME
;11/11/78 NOTE SIGNIFICANT MODS TO THIS
;	ROUTINE, TO HANDLE A: AND B: NAMES
;
CEFNC	XRA	A
	STA	CEFCB	;SO STAT WILL GO TO A:
;
;PUT "R" IN "WHERE FROM" IN CASE "NAME" COMMAND,
;I.E. RE-LOG IN.
;
	LXI	H,SUBJ	;WHERE 'CITY' STORED
	MVI	M,'R'
	INX	H
	MVI	M,','
	INX	H
	MVI	M,CR
;
	LXI	H,ANSWER
;
;SCAN FOR ' ' AFTER COMMAND
;
CESKB	MOV	A,M
	CPI	CR	;NO ' ' (E.G. STAT CMD)
	JZ	CECR	;	YES
	CPI	' '
	INX	H
	JNZ	CESKB
cecr	call	fmtfcb
;
;LOOK UP THE COMMAND
;
	LXI	H,CEFTAB ;FUNCTION TABLE
	CALL	CELOOK
	JMP	WHATM
;
; ====>	Format filename into CEFCB.  HL points to name.
;
fmtfcb	XRA	A	;DEFAULT TO
	STA	CEFCB	;	LOGGED IN DISK
	MOV	A,M	;JUST "DIR "?	
	CPI	CR
	JZ	ffCR
	INX	H	;CHECK FOR ':'
	MOV	A,M
	DCX	H
	CPI	':'	;DISK REQUESTED?
	JNZ	ffCR	;	NO
;PUT DISK INTO FCB
	MOV	A,M	;GET DISK
	SUI	'A'-1	;MAKE BINARY (A=1, ETC)
	STA	CEFCB	;STORE IN FCB
	INX	H	;SKIP TO ':'
	INX	H	;SKIP ':'
;POINTING TO FILENAME
ffCR	MVI	B,8	;FILENAME LEN
	LXI	D,CEFN	;POINT TO FILENAME
	CALL	CEFMN	;FORMAT NAME
	MVI	B,3	;FILETYPE LEN
	LXI	D,CEFT	;POINT TO FILETYPE
	CALL	CEFMN	;FORMAT TYPE
;
;FOR CHAR STRING MATCH IN FILE TYPE COMMAND,
;SAVE A POINTER TO THE COMMA, AND SAVE THE
;LAST CHAR SCANNED.  IF A COMMA, THEN WE
;ARE DOING STRING MATCH IN THE FILE TYPING.
;
	MOV	A,M	;GET COMMA (MAYBE)
	STA	STRFLG	;SAVE CHAR
	INX	H	;SKIP COMMA
	SHLD	STRPTR	;SAVE POINTER (MAYBE)
;
	ret
;
;====>	LOOK UP COMMAND
;	HL POINTS TO TABLE.  RETURNS ONLY IF NOT FOUND
;
CELOOK	MVI	B,4
celookn	LXI	D,ANSWER ;COMMAND
CELKLP	LDAX	D
	CMP	M
	JNZ	CELNO
	INX	D
	INX	H
	DCR	B
	JNZ	CELKLP
;
;FOUND, EXECUTE IT
;
CELGOT	MOV	E,M	;GET LO ADDR
	INX	H
	MOV	D,M	;GET HI
	POP	H	;DUMP RETURN ADDR
	XCHG
	PCHL		;TO COMMAND
;
;NOT FOUND - SKIP IT, TRY NEXT
;
CELNO	INX	H
	DCR	B
	JNZ	CELNO
	INX	H	;SKIP
	INX	H	;	ADDR
	MOV	A,M
	ORA	A
	RZ		;NOT FOUND
	JMP	CELOOK
;
; ====> TYPE A FILE
;
CETYPE	LXI	H,CEFCB
	LDA	ANSWER+4	;%07/11/81 MOD
	CPI	'H'
	JZ	CETFH
	CPI	'K'
	JZ	CETFK
	CALL	TYPEF
	JMP	FUNCT
;
;TYPE FILE, BUT ONLY LINES WITH "]"
;
CETFH	CALL	TYPEFH
	JMP	FUNCT
;
;TYPE FILE, LINES WITH ], AND THE NEXT 2 LINES
;
CETFK	CALL	TYPEFK
	JMP	FUNCT
;
; ====> ERASE A FILE
;
CEERA	LXI	H,CEFN
	MOV	A,M
	CPI	'?'
	JZ	CENOTF
	DCX	H	;BACK TO DISK #
	CALL	SETRD	;SETUP
	JC	CENOTF	;NOT FOUND
	LXI	D,FCB
	MVI	C,ERASE
	CALL	BDOS
	CALL	ILPRT
	DB	'++ERASED',0
	JMP	FUNCT
;
; ====> DIR FUNCTION
;
CEDIR	LXI	H,CEFCB
	LXI	D,FCB
	MVI	B,12
	CALL	MOVE	;SET UP NAME
	MVI	A,'?'	;FIND ALL
	STA	FCBEXT	;	EXTENTS
	xra	a	;??? found this necessary
	sta	fcbs2	;	to get dir listing??
	LXI	H,'  '	;INIT #
	SHLD	CEDIRN	;	OF FILES
	SHLD	CEdirk	;	and 
	SHLD	CEDIRk+2;	total K
	MVI	A,'0'
	STA	CEDIRN+2
	sta	cedirk+3
	LDA	FCB+1	;IF FCB
	CPI	' '	;	IS ' '
	JNZ	CENQ	;	THEN
	LXI	H,FCB+1	;	MAKE
	MVI	A,'?'	;	IT
	MVI	B,11	;	ALL
CEDIRQ	MOV	M,A	;	'?'
	INX	H
	DCR	B
	JNZ	CEDIRQ
;
CENQ	MVI	C,SRCHF	;SEARCH FIRST
	xra	a
	sta	wkbuf		;0 = end of stored names
	JMP	CEDIRF
;
CEDIRL	MVI	C,SRCHN ;SEARCH NEXT
CEDIRF	LXI	D,FCB
	CALL	BDOS	;ANY?
	INR	A
	JZ	CEDIRp	;END, so print
	DCR	A
	ANI	3	;ISOLATE # IN SECTOR
	ADD	A
	ADD	A
	ADD	A	;MULTIPLY BY 32
	ADD	A
	ADD	A
	ADI	81H	;LOC'N IN BUFFER
	MOV	L,A
	MVI	H,0
	call	cedstn	;store unique name
	jnc	cedirl
;
;	end of files - print them
;
cedirp	call	cedlow		;find low name
	jc	cedir99		;print how many files
	push	h		;save to "zap" name
	mvi	c,12	;max chars to print + 1
	mvi	b,8
	call	cedsub
	mvi	a,'.'
	call	type
	mvi	b,3
	call	cedsub
;
; if not short, pad name out to align columns
;
	lda	noneflg		;"short" in effect?
	rar
	jnc	cedsp
	mvi	c,2		;yes, just 1 space
;
cedsp	dcr	c		;space
	jz	cedpk		;print # of K
	call	space		;	to pad out name
	jmp	cedsp
;
;	compute & print # of K in file
;
cedpk	mov	e,m		;get extent
	mov	b,a		;save #k
	inx	h		;to last extent record count
	mov	a,m		;get it
	adi	7		;round up
	rar ! rar ! rar 	; sectors/8 = k
	ani	1fh		;kill garbage bits after divide
	mvi	d,0		;de = extent #
	xchg			;hl = ext #
	dad h ! dad h ! dad h ! dad h ; x16 to compute #k
	add	l		;get total k
	mov	l,a
	jnc	ncytoh
	inx	h		;add in carry if any
ncytoh	push	h
	call	dechl		;print hl in decimal
	pop	h
	mov	a,h
	ora	l
	jz	cedkpk		;0 length, nothing to add
	mov	b,h		;move #k to 
	mov	c,l		;	bc
;
;	add the K of this file to the total
;
cedkp	lxi	h,cedirk+3
	call	add1
	dcx	b
	mov	a,b
	ora	c
	jnz	cedkp
cedkpk	call	ilprt
	db	' ',0
	pop	h		;flag name in table
	mvi	m,0ffh		;	as having been printed
	lda	tabcol		;if col > 60,
	cpi	60		;	skip trailing spaces
	jc	cedncr
	call	crlf
cedncr	lxi	h,cedirn+2 ;bump file
	call	add1	;	count
	jmp	cedirp
;
;END, PRINT # K, # FILES
;
CEDIR99	CALL	CTLCKS	;ALLOW ABORT
	LDA	TABCOL	;CRLF
	ORA	A	;	ONLY IF NOT
	CNZ	CRLF	;	IN COLUMN 0
;
;	print total only if > 1 file 
;
	lxi	h,cedirn+1	;point to 10's
	mov	a,m
	cpi	' '
	jnz	cedtot		;have 10's, print it.
	inx	h
	mov	a,m
	cpi	'2'
	jc	funct
cedtot	CALL	ILPRT
cedirk	db	'    K in '
CEDIRN	DB	'  0'	;MODIFIED
	DB	' Files',0
	JMP	FUNCT
;
; routine to find lowest name, set carry if no more
;
cedlow	call	cedl1st		;find first
	rc			;no more
	xchg			;move to de as lowest
	mov	h,d
	mov	l,e		;copy to hl
cedllp	call	cedlnxt		;find next name
	jc	cedglow		;got lowest
	push	d
	push	h
	mvi	b,11
	call	compr		;see which is lowest
	pop	h
	pop	d
	jc	cedllp
	mov	d,h		;save new low in de
	mov	e,l
	jmp	cedllp
;
; got lowest
;
cedglow	xchg			;get it to hl
	ora	a		;show OK
	ret
;
; find first name in buffer, carry if no more
;
cedl1st	lxi	h,wkbuf-13
cedlnxt	lxi	b,13		;table length
cedl1sl	dad	b
	mov	a,m
	ora	a
	stc
	rz			;ret if none
	jm	cedl1sl		;to next if already printed
	ora	a		;carry off - ok.
	ret
;
; subroutine to print filename, w/space suppress.
; non-' ' chars subtract from C, the count to space
; to even up names.
;
cedsub	mov	a,m		;get char
	cpi	' '		;is it space?
	jz	cednt		;	y/don't type it
	call	type
	dcr	c		;
cednt	inx	h
	dcr	b
	jnz	cedsub
	ret
;
; store a name, if it is unique
;
;	first, kill attr bits
;
cedstn	push	h		;save name
	mvi	b,11		;name length
ced01	mov	a,m
	ani	7fh
	mov	m,a
	inx	h
	dcr	b
	jnz	ced01
	pop	d		;SWITCH name to DE
;
;	look up name, see if unique
;
	lxi	h,wkbuf
cedlu	mov	a,m		;at end?
	ora	a
	jz	ced90		;yes, store it
	push	d
	push	h
	mvi	b,11
	call	compr
	jnz	cedne
;
;	names equal, check which extent is higher
;
	ldax	d		;get new ext
	cmp	m
	jc	cednn		;new extent is lower
	mov	m,a		;store new, higher ext
	inx	h		;point to ext size in table
	inx d ! inx d ! inx d	;	and in file
	ldax	d
	mov	m,a
cednn	pop	h
	pop	d
	ora	a		;no cy = no error
	ret
;
;	name didn't match, try next
;
cedne	pop	h
	pop	d
	lxi	b,13		;fn + ft + ext + len
	dad	b
	jmp	cedlu
;
;	name is unique, store it
;
ced90	xchg			;HL=from, DE=to
	mvi	b,12		;fn + ft + ext
	call	move
	inx h ! inx h		;to extent length
	mov	a,m
	stax	d
	inx	d
	xra	a		;store new end char
	stax	d		
	lda	bdos+2
	sui	2
	cmp	d		;filling mem?
	ret			;	if so, returns carry
;
;---->	STAT
03;MODS		REWRITTEN TO BE "UNIVERSAL"
;
;STAT FUNCTION - DETERMINES SIZE OF ALL LOGGED IN DISKS
;		CP/M 1.4 AND 2.2 COMPATIBLE.
;
CESTAT	MVI	C,INQDISK
	CALL	BDOS	;GET, AND
	PUSH	H	;	SAVE CURRENT DISK
	MVI	C,GETLGIN
	CALL	BDOS	;FIND WHICH DISKS LOGGED IN
	MOV	C,A	;C=LOGIN VECTOR
;
; give stat based upon OPER or not, XFER or not:
;
;		  oper	 not oper
;		+------+- --------
; xfer:		| full | xfer disk
; not xfer:	| full | tell "WHAT?"
;
;
	lda	passflg
	ora	a
	jz	cestop		;is op, give all
;
 if not xfer
	jmp	whatm		;"WHAT?" if not operator
 endif
;
 if xfer
;
; xfer enabled, allow stat only on the xfer disk
;
	lda	xdisk		;get the disk (1=a, etc)
	mov	b,a		;set for count
	xra	a		;a=0
	stc			;	but carry set
cestl	ral			;shift mask
	dcr	b		;count down disks
	jnz	cestl
	ana	c		;kill other drives
	mov	c,a		;may be 0 if xfer
				; disk not logged in.
 endif
;
cestop	MVI	B,1	;B=NEXT DISK TO TRY
	MVI	D,'A'	;CURRENT DISK BEING TRIED
CESTDK	PUSH	B	;SAVE DISK, ETC
	PUSH	D
	MOV	A,C	;GET LOGIN VECTOR
	ANA	B	;TEST FOR 1 DISK
	JZ	CESTNLI	;NOT LOGGED IN
;SELECT THE DISK
	MOV	A,D	;GET ASCII
	CALL	TYPE	;TYPE IT
	MVI	A,':'	;THEN ':'
	CALL	TYPE
	MOV	A,D
	SUI	'A'	;MAKE IT ACCEPTABLE TO BDOS
	MOV	E,A
	MVI	C,LGINDK	;LOGIN THE DISK
	mvi	a,ctlkoff	;disallow ^K while logged
	sta	ctlksw		;	to another disk
	CALL	BDOS	;LOG IN THE DISK
;
; get the size of the disk
;
	MVI	C,GETVERS
	CALL	BDOS	;GET VERSION
	MOV	A,L
	ORA	A
	JNZ	CEST22	;IT IS 2.2
;
;THIS IS 1.4, SO GET PARM BLOCK FROM THE FRONT OF BDOS
;
	LHLD	BDOS+1	;GET ADDR
	LXI	D,36H	;OFFSET TO PARM
	DAD	D
	MOV	A,M	;GET BLOCK SHIFT FACTOR
	INX	H
	INX	H
	MOV	E,M	;GET DISK SIZE
	MVI	D,0
	JMP	CESTCAL
;
CEST22	MVI	C,GETPARM
	CALL	BDOS	;GET DISK PARM ADDR
	INX	H
	INX	H
	MOV	A,M
	INX	H
	INX	H
	INX	H
	MOV	E,M
	INX	H
	MOV	D,M
CESTCAL	XCHG
	INX	H	;FUDGE HL TO # OF BITS IN MAP
	PUSH	PSW	;SAVE ALLOCATION BLOCK SIZE
	PUSH	H	;SAVE # BITS
	MVI	C,INQALC
	CALL	BDOS	;GET ALLOCATION
	POP	D	;GET BIT MAP COUNT
	LXI	B,0	;INIT # K FREE
CESTB80	MVI	A,80H	;INIT MASK
CESTBIT	PUSH	PSW	;SAVE MASK
	ANA	M	;FREE?
	JNZ	CESTNB	;NO BIT
	INX	B	;COUNT THE BIT
CESTNB	DCX	D	;COUNT DOWN # BITS
	MOV	A,D
	ORA	E
	JZ	CESTASC	;DONE, COMPUTE IN ASCII
	POP	PSW	;GET MASK
	ORA	A	;NO CARRY
	RAR		;RIGHT 1 BIT,
	JNC	CESTBIT	;LOOP IF SAME BYTE
	INX	H	;TO NEXT BYTE
	JMP	CESTB80
;
;DONE, BC = #K FREE, COMPUTE IN ASCII
;
CESTASC	POP	PSW	;DUMP THE BIT MASK
	LXI	H,CESTFRE
	MVI	A,' '
	MOV	M,A
	INX	H
	MOV	M,A
	INX	H
	MOV	M,A
	INX	H
	MVI	M,'0'	;IN CASE '0' K FREE
;
;NOW, MULTIPLY THE # OF BITS THAT WERE 0,
;	BY THE # OF K PER BIT
;
	POP	PSW	;GET BLOCK SHIFT
	MOV	D,B
	MOV	E,C	;MOVE COUNT TO DE
	XCHG		;THEN TO HL
	SUI	3	;IS IT 1K?
	JZ	CESTASB	;YES
CESTINK	DAD	H	;DOUBLE # OF BITS FREE
	DCR	A	;COUNT DOWN
	JNZ	CESTINK
CESTASB	XCHG
CESTASL	MOV	A,D	;DOWN TO
	ORA	E	;	0 LEFT?
	JZ	CESTPRT	;	YES, PRINT IT
	PUSH	H	;SAVE POINTER
	CALL	ADD1	;ADD 1 IN ASCII
	DCX	D	;DCR COUNT
	POP	H
	JMP	CESTASL
;
CESTPRT	CALL	ILPRT
CESTFRE	DB	'    K Free',0DH,0AH,0
;
;DISK NOT LOGGED IN, OR DONE PROCESSING.  TRY NEXT ONE
;
CESTNLI	POP	D
	POP	B
	INR	D	;BUMP PRINTABLE DISK
	MOV	A,B	;GET MASK
	ADD	A	;SHIFT LEFT
	MOV	B,A
	JNC	CESTDK	;PROCESS NEXT DISK
;
;RESTORE ORIGINALLY LOGGED IN DISK
;
	POP	D
	MVI	C,LGINDK
	CALL	BDOS
	JMP	FUNCT
03;END
;
;---->	'NOTE' FUNCTION - WRITES NOTES TO 'NOTES' FILE
;	WHICH ARE THEN TYPED VIA 'TYPE NOTES' COMMAND
;	AND ERASED VIA 'ERA NOTES' COMMAND
;
CENOTE	LXI	H,NOTEFL ;POINT TO FILENAME
	CALL	EXTEND	;EXTEND (OR CREATE)
	MVI	A,']'
	CALL	WRBYTE
;
	LDA	ANSWER+4 ;IS THIS "NOTEN"
	CPI	'N'	;	I.E. NOTES
	JZ	CENOTEN	;	WITHOUT HEADER?
;
	LXI	H,COMFRM ;WRITE 'FROM:',
	CALL	WRVAR
	LXI	H,FNAME
	CALL	WRVARC	;FIRST NAME ","
;
 IF CLOCK
	CALL	WRTIME
 ENDIF
CENOTEN	CALL	WRCRLF
;
CENLP	CALL	GETVARN	;07/19/81 FORMERLY GETVAR
	DB	':',0	;07/11/81 FORMERLY HAD CR,LF
	DW	ANSWER	;READ IN HERE
02	DW	0	;HELP MSG #
	DB	80	;LINE LENGTH was 60
	LDA	ANSWER	;END?
	CPI	CR
	JZ	CENEND	;YES, END
	LXI	H,ANSWER
	CALL	WRLINE	;WRITE LINE TO DISK
	JMP	CENLP	;LOOP UNTIL C/R ENTERED
;
;END OF CE NOTE FUNCTION - CLOSE FILE
;
CENEND	CALL	WREOF	;CLOSE
	JMP	FUNCT
;
 if chat
;
; ===>	CHAT command - talk between operator and user
;
cechat	lda	twitsw
	ora	a
	jnz	nochat
	call	ilprt
	db	'I''ll ring 5 times for the operator, ',0
	call	typname		;09/24/83 mod - subroutine now.
	call	ilprt
	db	'Press K to abort.',cr,lf,0
;
;	Make terminal bell "ring like phone":
;	b-b-b-b-beep . . . b-b-b-b-beep . . . 
;
	mvi	b,5		;total "rings"
cecloop	mvi	c,4		;# beeps/"ring"
cecbeep	lxi	h,2000h*mhz	;fraction of sec delay
cecdly1	dcx	h
	mov	a,h
	ora	l
	jnz	cecdly1
	mvi	a,7		;get bell
	call	type
	call	ctlcks		;^k out, or ^c
	jz	hello		;	..into "hello".
	dcr	c
	jnz	cecbeep
	mvi	c,28
;
;	delay a while "between rings"
;
cecwait	lxi	h,1000h*mhz
cecdly2	dcx	h
	mov	a,h
	ora	l
	jnz	cecdly2
	call	ctlcks		;^k out, or ^c
	jz	hello		;	..into "hello".
	dcr	c
	jnz	cecwait
 endif
 if chat and wards		;flash VIO, beep printer if not
				; before 7:00 A.M.
	lda	lgintim		;get hours
	cpi	'0'
	jnz	wardbp		;go beep if not 0x:xx:xx
	lda	lgintim+1
	cpi	'7'
	jc	wardnb		;no beep until 7 am.
wardbp	push	b
	mvi	a,7		;no terminal, ring printer bell
	call	log		;via log.
	call	cktty		;then allow it to be sent.
	pop	b
wardnb	lxi	h,viostat+8	;bump the space between date
	inr	m		;	& time so can check if
;					chat was asked for.
	lxi	h,viostat
	mvi	d,240		;rev-vid 3 lines.
flvio	mov	a,m
	xri	80h
	mov	m,a
	dcx	h
	dcx	h
	dcx	h
	dcr	d
	jnz	flvio
 endif
 if chat
	dcr	b
	jnz	cecloop
nochat	call	ilprt
	db	'Operator unavailable.',cr,lf,0
;
;	if haven't already said so, ask 1-line about "why chat"?
;
	lda	chatdoc
	ora	a
	jnz	funct
	call	getvarn
	db	'Briefly (72 char line) say what you '
	db		'wanted to CHAT about please.',cr,lf,0
	dw 	answer
	dw	0
	db	72
	lda	answer
	cpi	cr
	jz	funct		;no comments made
	mvi	a,ctlkoff
	sta	ctlksw
	sta	dkupsw		;show updating disk
	lxi	h,logfl		;point to filename
	call	extend		;extend the log file
	call	wrcrlf
	lxi	h,chathdr
	call	wrvar		;write "]help: "
	lxi	h,answer
chatwc	mov	a,m
	inx	h
	cpi	cr
	jz	chatwe
	call	wrbyte
	jmp	chatwc
;
chatwe	mvi	a,','
	call	wrbyte
	call	wreof		;close file
	mvi	a,1
	sta	chatdoc		;disallow further "why chat" logs
	jmp	funct
;
chathdr	db	']CHAT: ',cr
;
hello	xra	a
	sta	ctlksw
	lda	passflg		;if operator,
	ora	a
	jz	cecnbel		;skip msg
	call	ilprt
	db	'In chat mode.  Press ^K then return to exit'
	db	cr,lf,cr,lf
	db	'After each message, press return twice '
	db		'as a signal "over to you".'
	db	cr,lf,cr,lf,0
	lda	bellf
	ora	a
	jz	cechat2
	call	ilprt
	db	'Issuing "P" command to turn bell off.',cr,lf,cr,lf,0
cecnbel	xra	a
	sta	bellf
cechat2	call	getvarn
	db	0		;no msg, just "?" prompt
	dw	wkbuf
	dw	0
	db	128
	jmp	cechat2
;
; chat with logging
;
logchat	lxi	h,chatlog
	call	extend		;doesn't return if error
chatlp	call	getvarn
	db	0		;no msg, just "?" prompt
	dw	wkbuf
	dw	0
	db	128
	lxi	h,wkbuf
	call	wrline
	lda	wkbuf
	cpi	'^'
	jnz	chatlp
	call	wreof
	jmp	funct
 endif				;chat
;
03	;MODS:
;
;====>	HOLD	COMMAND PREVENTS PHONE HANGUP
;
HOLD	LDA	HOLDFLG
	XRI	1
	STA	HOLDFLG
	JNZ	HOLDNO
	CALL	ILPRT
	DB	'Will',0
	JMP	HOLDMSG
;
HOLDNO	CALL	ILPRT
	DB	'Won''t',0
HOLDMSG	CALL	ILPRT
	DB	' time out',0
	JMP	FUNCT
03;END
;
;---->	DUMP COMMAND - USE CTL-K TO ABORT
;
CEDUMP	LXI	D,CEFN	;TO ASCII HEX
	CALL	RDHEX	;TO HL
;
;DUMP A LINE AT A TIME, ABORT ON CTL-K
;
CEDULN	MOV	A,H
	CALL	HEX
	MOV	A,L
	CALL	HEXB
	PUSH	H
CEDUNHC	MOV	A,M
	INX	H
	CALL	HEX
	CALL	CTLCKS
	JZ	FUNCT
	MOV	A,L
	ANI	3
	CZ	SPACE
	MOV	A,L
	ANI	0FH
	JNZ	CEDUNHC
	POP	H
	CALL	CEDUAST
CEDUASC	MOV	A,M
	CPI	' '
	JC	CEDUPER
	CPI	7FH
	JC	CEDUNP
CEDUPER	MVI	A,'.'	;NON PRINTABLE
CEDUNP	CALL	TYPE
	CALL	CTLCKS
	JZ	FUNCT
	INX	H
	MOV	A,L
	ANI	0FH
	JNZ	CEDUASC
	CALL	CEDUAST
	CALL	CRLF
	JMP	CEDULN
;
CEDUAST	MVI	A,'*'
	JMP	TYPE
;
;====>	PRINT	ROUTINE, CAUSES TYPING TO ECHO TO LIST
;
CEPRINT	LDA	PRINTSW
	XRI	1
	STA	PRINTSW
	JZ	CEPRNO
	CALL	ILPRT
	DB	'On',0
	JMP	FUNCT
;
CEPRNO	CALL	ILPRT
	DB	'OFF',0
	JMP	FUNCT
;
;---->	ENTR COMMAND - ENTER A BYTE INTO MEMORY
;
;	ENTR ADDR.DATA, DATA = 1 BYTE ONLY
;
CEENTR 	LXI	D,CEFT
	CALL	RDHEX	;GET DATA
	MOV	B,L	;SAVE IT
	LXI	D,CEFN	;TO ADDR
	CALL	RDHEX
	MOV	A,M	;GET OLD VALUE
	CALL	HEX
	MOV	M,B	;STORE NEW
	JMP	FUNCT
;
;====>	CESLOW
;		TO SLOW DOWN TYPING
;		WHEN TESTING CBBS LOCALLY
;
CESLOW	LDA	TYPDLY+2 ;GET TYPING DELAY
	ADI	8
	ANI	18H
	STA	TYPDLY+2
	JMP	FUNCT
;
;HEX READ ROUTINE, DE POINTS TO ASCII.
;TERMINATES WITH ' ' OR CR.
;
RDHEX	LXI	H,0	;INIT ADDR
RDHI	LDAX	D
	INX	D
	CPI	' '	;END?
	RZ		;START DUMPING
	CPI	CR
	RZ
	CPI	'0'	;CONV ASCII TO HEX
	JC	WHATM		
	CPI	'9'+1
	JC	RDHNUM
	CPI	'A'
	JC	WHATM
	CPI	'F'+1
	JNC	WHATM
	SUI	7
RDHNUM	SUI	'0'
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	ADD	L
	MOV	L,A
	JMP	RDHI
;
;FILE NOT FOUND
;
CENOTF	CALL	ILPRT
	DB	'No: ',0
	LXI	H,CEFN
	MVI	B,0
	CALL	TYPEM
	JMP	FUNCT
;
;FORMAT NAME - PAD W/SPACES. LEN IN B
;
CEFMN	MOV	A,M
	CPI	CR	;END?
	JZ	CEFEND
	CPI	','	;START OF STRING?
	JZ	CEFEND
	INX	H
	CPI	'.'
	JZ	CEFEND
	CPI	'*'
	JZ	CEFQM	;FILL W/'?'
	call	cevch	;validate the char
	jz	cefmns
	STAX	D
	INX	D
cefmns	DCR	B
	JNZ	CEFMN
	MOV	A,M	;AT '.'?
	CPI	'.'
	RNZ		;NO
	INX	H	;SKIP '.'
	RET
;
; validate filename char, rz if bad.
;
cevch	cpi	' ' ! rz	;bad
	cpi	':' ! rz
	cpi	'>' ! rz
	cpi	'<' ! rz
	cpi	'=' ! rz
	cpi	'_'
	ret
;
;END OF INPUT FIELD, PAD W/' '
;
CEFEND	MVI	A,' '
	STAX	D
	INX	D
	DCR	B
	JNZ	CEFEND
	RET
;
;GOT "*", PAD WITH '?'
;
CEFQM	MVI	A,'?'
	STAX	D
	INX	D
	DCR	B
	JNZ	CEFQM
	MOV	A,M	;AT '.'?
	CPI	'.'
	RNZ
	INX	H
	RET
;
;-----> WORK AREA FOR CE FUNCTIONS
;
CEFCB	DS	1	;DISK (A=1, ETC)
CEFN	DS	8	;FILENAME
CEFT	DS	3	;FILETYPE
	DB	0	;END OF NAME, FOR PRINTING
;
;10/17/81 MODS TO SUPPORT CONTINUING A MSG IN MSG ENTRY
;
CECONT	MVI	A,1
	STA	MCONT	;SHOW CONTINUED
	JMP	ENTER	;THEN GO TO MSG ENTRY
;
;10/17/81 END
;
;
; 04/09/83 "twit" command: writes directly to the NEXT file
;	i.e. TWIT<cr> then type lines into LOG until double C/R.
;
;	Ex: twit<cr>
;	[flip,scopes,]*<cr>
;	<cr>
;
cetwit	MVI	A,ctlkoff
	STA	CTLKSW
	STA	DKUPSW	;SHOW UPDATING DISK
	LXI	H,NEXTFL	;POINT TO FILENAME
	CALL	EXTEND	;EXTEND THE NEXT FILE
wtlp	call	getvar
	db	'next:',0
	dw	answer
	dw	0
	db	79
	lda	answer
	cpi	cr
	jz	wteoi
	lxi	h,answer
	call	wrline
	jmp	wtlp
;
wteoi	call	wreof	;write eof, close file
	jmp	funct
 if ulog
; ====>	LOGIN command, new 11/12/82
;
;	login;firstname;lastname;date;time;msg#
;
celogin	call	getvar
	db	0
	dw 	fname
	dw	0
	db	20
;
	call	getvar
	db	0
	dw 	lname
	dw	0
	db	20
;
 endif
 if ulog and clock
	call	getvar
	db	'mm/dd/yy',cr,0
	dw 	date
	dw	0
	db	20
;
	call	getvar
	db	'hh:mm:ss',cr,0
	dw 	lgintim
	dw	0
	db	20
 endif
 if ulog
;
	call	getvar
	db	'nnnnn',cr,0
	dw 	highmsg
	dw	0
	db	5
;
	call	ulogin
	jmp	funct
 endif	;ulog
;
; ====>	user command - new 10/19/82
;
ceuser	lxi	h,cefn		;point to digits
	mvi	b,0		;init result
ceul	mov	a,m
	cpi	' '
	jz	ceus
	call	addin		;mult by 10, add it
	inx	h
	jmp	ceul
;
; subroutine to compute ascii number < 255.
;
addin	mov	c,a		;save ascii digit
	mov	a,b		;get prev
	add	a		;x2
	add	a		;x4
	add	b		;x5
	add	a		;x10
	add	c		;+ new digit + '0'
	sui	'0'
	mov	b,a
	ret
;
;	got user #, set it
;
ceus	mov	a,b		;get user
 if xfer
	sta	xuser		;save as transfer user
 endif
	mov	e,a		;set up for bdos
	mvi	c,sguser	;	set user fnc
	call	bdos
	jmp	funct
;
;HEX WITH SPACE
;
HEXB	CALL	HEX
	JMP	SPACE
;
;HEX PRINT ROUTINE
;
HEX	PUSH	PSW
	RAR
	RAR
	RAR
	RAR
	CALL	NIBBL
	POP	PSW
NIBBL	ANI	0FH
	CPI	10
	JC	HEXNUM
	ADI	7
HEXNUM	ADI	'0'
	JMP	TYPE
;
;FUNCTION TABLE
;
CEFTAB	DB	'TYPE'
	DW		CETYPE
	DB	'DIR '
	DW		CEDIR
	DB	'DIRN'
	DW		CEDIR
	DB	'ERA '
	DW		CEERA
	DB	'XCPM'
	DW		0
	DB	'NOTE'
	DW		CENOTE
	DB	'NAME'
	DW		GETFN
	DB	'DUMP'
	DW		CEDUMP
	DB	'ENTR'
	DW		CEENTR
	DB	'PURG'
	DW		PURGE
	DB	'HOLD'
	DW		HOLD
	DB	'PRIN'
	DW		CEPRINT
	DB	'SLOW'
	DW		CESLOW
	DB	'TWIT'
	DW		cetwit
	DB	'USER'
	DW		CEuser
 if ulog
	DB	'LOGI'
	DW		CElogin
 endif
;	DB	'CONT'			;these made public
;	DW		CECONT		;10/10/82
;	DB	'STAT'
;	DW		CESTAT
;
	DB	0	;END OF FUNCTION TABLE
;
	LINK	CBBSKILL
                                                                                                                        