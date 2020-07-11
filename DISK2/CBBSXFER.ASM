;CBBS V3.6.2 	CBBSXFER.ASM - FILE TRANSFER STUFF
;09/21/83 21:37:34
;
;	LINKS TO CBBSWORK (or CBBSWARD)
;
;	O   O	O O O	O O O	O O O
;	 O O	O	O	O   O
; CBBS	  O	O O O	O O	O O O	.ASM
;	 O O	O	O	O  O
;	O   O	O	O O O	O   O
;
;MOD LOG: 10/06/82 INITIALLY WRITTEN
;	remainder to history.036
;
soh	equ	1
eot	equ	4
nak	equ	15h
;
; modem file transfer stuff (added 10/82)
;
MASIST	CALL	ILPRT
 db '(H)elp <==; (D)irectory list; (M)ain menu return;',cr,lf
 db '(R)eceive file from you; (S)end file to you; (T)ype file;',cr,lf
 db '(?) Type this list; (U)ser # change (if allowed);',cr,lf
 db 'Other letters same as main menu (Ex: (G)ood bye)',cr,lf
	db	0
;
DMFUNCT	MVI	A,CR		;KILL
	STA	INBUF		;	STACKED LINES
;
mfunct	LXI	SP,STACK	;fixup stack on abort
	mvi	a,3		;set # ^X 
	sta	nctlx		;	before abort
	lda	xenable		;authorized?
	ora	a
	jnz	mfcont		;	yes, continue
;
;	let system operator in w/no special password
;
	lda	passflg		;system operator?	|10/19/82
	ora	a		;			|
	jz	mfcont		;yes, let 'em in	|
;
; password needed?
;
	lda	xpasswd		;0 password
	ora	a		;	means
	jz	mfcont		;	none needed
	jp	mrdpw		;80-ff means "disabled".
mnox	call	ilprt
	db	'++ Sorry, transfer disabled ++',cr,lf,0
	jmp	defunct
;
;	read the password file, set up XPASSWD
;
mrdpw	call	mrdpw2		;-------+
;					|
; --> return here ONLY ON ERROR <-------+
;
	call	ilprt
	db	'++ error in password file.',cr,lf,0
	jmp	tellus
;
mrdpw2	lxi	h,passfl	;point to name
	call	setrd		;open it
	call	findnam		;find the name
	jc	mnox		;user not in file
;
;	read the password, disk, user, and R/O flag 
;	from "pasword" file.  Format is:
;	[FIRSTNAME,LASTNAME,PASSWORD,DRIVE,USER,R/O,msg]
;	Ex: [WARD,CHRIS*,CBBSPW,B,3,N,optional msg]
;	Password is 8 char max.
;
	lxi	h,xpasswd	;point to passwd
xmp	call	rdbyte
	rc			;error - eof
	mov	m,a
	inx	h
	sui	','		;end of pw?
	jnz	xmp
	dcx	h
	mov	m,a		;set end of 0
	call	rdbyte		;get disk
	rc
	sui	'@'		;convert to drive
	sta	xdisk		;set disk
	call	rdbyte
	rc
	cpi	':'		;optional ":"
	cz	rdbyte		;rd ',' if was ':'
xmc	cpi	','
	rnz
;
;	now get max user or min-max user
;
	xra	a
	sta	xminusr		;dflt min=0
	mvi	b,0		;init user #
xgu	call	rdbyte
	rc
	cpi	','
	jz	xgotmax
	cpi	'-'		;lo user "-" high user?
	jz	xgotmin
	call	addin		;compute b= user
	jmp	xgu
;
;	got minimum user
;
xgotmin	mov	a,b		;get user
	sta	xminusr		;save min user allowed
;
;	now get the max user
;
	mvi	b,0		;init max
xgmu	call	rdbyte
	rc
	cpi	','
	jz	xgotmax		;got max user
	call	addin		;compute b= user
	jmp	xgmu
;
xgotmax	mov	a,b		;make current user
	sta	xuser		;	= max user
	sta	xmaxusr		;save max allowed
;
	call	rdbyte		;get R/O flag
	rc
	sui	'R'
	sta	xroflg		;save, =0 if 'R'
;
;	password, drive, min-max user, and R/O flag read,
;	now ask user for password
;
	call	rdbyte		;get delim
	cpi	','
	rc
	pop	h		;unstack error return addr
;
mgetpw	CALL	getpass
	DB	'Password:  Enter the modem sub-menu password:',cr,lf
	db	'(x will echo):',0
	dw	answer		;read into here.
	dw	0		;no help
	db	7		;8 byte max
	LDA	TWITSW		;befuddle twits so
	ORA	A		; They NEVER get password
	JNZ	mpwbad		; correct.
	lxi	h,answer
	lxi	d,xpasswd
mpwcomp	ldax	d
	ora	a
	jz	mpwok
	cmp	m
	inx	h
	inx	d
	jz	mpwcomp
mpwbad	call	ilprt
	db	'Sorry, incorrect',cr,lf,0
	jmp	funct
;
;	type any possible msg from pw file
;	to user now that pw is ok.
;
mpwok	call	rdbyte		;get ']' or message for user.
	jc	mfcont		;get out on error
	cpi	']'
	jz	mfcont
	call	type
	jmp	mpwok
;
mfcont	mvi	a,1
	sta	xenable		;enable xfer mode
	call	rsuser		;in case a main cmd exec
	mvi	a,1
	sta	mroute		;route "funct" to here
	LDA	PREVCHR		;IF PREV WAS C/R
	CPI	CR		;	THEN HAVE TO
	JZ	MFUNCR		;	CR/LF
	LDA	TABCOL		;OTHERWISE, CRLF
	ORA	A		;	IF NOT IN
	JZ	MFUNOCR		;	COLUMN 1
MFUNCR	CALL	CRLF
MFUNOCR	call	getvar
	DB	'Modem function: '
	db	'D,H,M,R,S,T,U '
	DB	'(or ? if not known)',0
	DW	ANSWER		;READ INTO ANSWER
	DW	-1		;HELP MSG #: PASS "HELP" AND "?"
				;BACK TO THIS ROUTINE
	DB	40		;MAX ANSWER LEN
;
	LDA	ANSWER		;GET FIRST CHAR OF REPLY
	CPI	CR		;C/R ENTERED?
	JZ	MFUNCT		;	YES, ASK AGAIN
	MOV	B,A		;SAVE CHAR
;
;	test for qr or sr
;
	lxi	h,answer+1
	mov	a,m	 	;SINGLE CHAR FNC?
	cpi	'R'
	jnz	mfnr
	lda	answer+2
	cpi	cr
	jz	mainf		;go do qr or sr
	mov	a,m		;re-get 2nd char
;
mfnr	cpi	' '		;as in "t name"
	cz	restack		;yes, restack name
	CPI	CR
	JNZ	m4		;CHECK FOR PASSWORD
	MOV	A,B		;GET FIRST CHAR
	CPI	'?'
	JZ	MASIST
;
	cpi 'D' ! jz mdir
	cpi 'H' ! jz mhelp
	cpi 'M' ! jz tofunct	;main menu, kill mroute
	cpi 'R' ! jz mrecv
	cpi 'S' ! jz msend
	cpi 'T' ! jz mtype
	cpi 'U' ! jz muser
;
; test for function from main menu, exec them if so
;
	cpi 'A' ! jz mainf
	cpi 'B' ! jz mainf
	cpi 'C' ! jz mainf
	cpi 'E' ! jz mainf
	cpi 'G' ! jz mainf
	cpi 'H' ! jz mainf
	cpi 'K' ! jz mainf
	cpi 'N' ! jz mainf
	cpi 'O' ! jz mainf
	cpi 'P' ! jz mainf
	cpi 'Q' ! jz mainf
	cpi 'S' ! jz mainf	;in case SR from "Mine", etc.
	cpi 'V' ! jz mainf
	cpi 'W' ! jz mainf
	cpi 'X' ! jz mainf
	cpi '#' ! jz mainf
;
; try 4-letter commands
;
m4	LXI	H,FTAB		;POINT TO FUNCTION TABLE
	CALL	CELOOK		;RET'S HL = FNC IF VALID
;
;NOT FOUND.  CHECK FOR OP FNC
;
	LDA	PASSFLG		;OPERATOR?
	ORA	A
	CZ	CEFNC		;PASSWORD HAS BEEN ENTERED
	LXI	H,WHAT		;GET 'DONT UNDERSTAND' MSG
	CALL	TYPEM0		;TYPE THE MESSAGE 
	LXI	H,ANSWER
	CALL	TYPEMCR
	LXI	H,QFNAME 	;POINT TO ', (NAME)
	CALL	TYPEMCR
	CALL	CRLF
	JMP	DMFUNCT
;
; leaving "M" menu - stop routing "funct" to "mfunct",
; and reset user #
;
tofunct	xra	a
	sta	mroute
	call	rsuser
	jmp	funct
;	________
;
; ====> user asked for help
;
mhelp	lxi	h,mhelfl
	call	intqf
	jmp	MFUNCT
;	________
;
; ====>	function to type a file
;
mtype	call	mgetnu
	jnz	mtype
	lda	fcb+1
	cpi	' '
	jz	mfunct
	mvi	a,ctlkmod	;set ^K to return
	sta	ctlksw		;	to mfunct
	lxi	h,fcb		;set up dummy move
	lda	expert
	ora	a
	jnz	mtypef		;go type it
	call	ilprt
	db	'^X to skip 10 lines, ^K to abort',cr,lf,cr,lf,0
mtypef	lxi	h,fcb		;dummy up for move fcb to fcb
	call	typef
	jmp	mfunct
;	________
;
; ====>	function to change user
;
muser	call	ilprt
	db	'User = ',0
	lda	xuser
	call	prdec
	call	ilprt
	db	', range allowed = ',0
	lxi	h,xminusr
	mov	a,m
	call	prdec
	call	ilprt
	db	' to ',0
	lxi	h,xmaxusr
	mov	a,m
	call	prdec
	call	crlf
	mov	a,m
	dcx	h		;to min user
	cmp	m		;min = max?
	jz	mfunct		;	y:only 1 user
mreusr	push	h		;	n:get new user
	call	getvar
	db	'New user #:',0
	dw	answer
	dw	0
	db	2
	lxi	d,answer
	ldax	d
	pop	h
	cpi	cr
	jz	mfunct
	push	h
	call	getnum		;puts # in HL
	mov	a,l		;	move to (A)
	pop	h
	jc	mreusr		;getnum carry if error
	cmp	m		;compare to min
	jc	mreusr		;	< min, re-ask
	inx	h
	cmp	m		;compare to max
	dcx	h		;set up for loop
	jc	msetu		;	> max, so OK.
	jnz	mreusr		;no, ask again
msetu	sta	xuser
	push	psw
	call	ilprt
	db	'User = ',0
	pop	psw
	call	prdec
	call	crlf
	jmp	mfunct
;	________
;
; ====>	function to list directory
;
mdir	lxi	h,otdf		;one-time dir flag
	mov	a,m		;get it
	mvi	m,0		;turn it off
	ora	a		;was it on?
	jnz	mdpro		;	yes, prompt
	lda	expert		;prompt non-experts
	ora	a
	jnz	mdnpro
mdpro	lda	inbuf
	cpi	cr
	jnz	mdnpro
	call	ilprt
	db	'* and ? allowed; press return for all: ',0
mdnpro	call	mgetnam		;get name,
	mvi	a,ctlkmod	;set ^K to return
	sta	ctlksw		;	to mfunct
	lda	expert
	ora	a
	jnz	cedir
	call	ilprt
	db	'^C or ^K to abort',cr,lf,0
	jmp	cedir		;go print dir.
;	________
;
; ====>	function to send a File
;
msend	call	mgetnu		;get unamb name
	jnz	msend		;had "*" or "?"
	lda	fcb+1
	cpi	' '		;no name?
	jz	mfunct		;was no name
	CALL	OPENFIL
	MVI	E,80
	CALL	WAITNAK
SENDLP	CALL	RDSECT
	JC	SENDEOF
	CALL	INCRSNO
	XRA	A
	STA	ERRCT
SENDRPT	CALL	SENDHDR
	CALL	SENDSEC
	CALL	SENDCKS
	CALL	GETACK
	JC	SENDRPT
	JMP	SENDLP
;
SENDEOF	MVI	A,4
	CALL	SEND
	CALL	GETACK
	JC	SENDEOF
	mvi	a,'S'		;show "sent"
	jmp	logxfer		;log it
;	________
;
; ====>	function to receive a file
;
mrecv	lda	xroflg
	ora	a
	jz	xrdonly
	call	mgetnu		;get unamb name
	jnz	mrecv		;had "*" or "?"
	lda	fcb+1
	cpi	' '		;no name?
	jz	mfunct		;was no name
	call	testfil		;see if it exists
	jc	mrecv
	call	makefil
	call	ilprt
	DB	'File open, ready to receive',cr,lf
	db	'to abort transfer, ^X three times',cr,lf,0
RCVLP	CALL	RCVSECT
	JC	RCVEOT
	CALL	WRSECT
	CALL	INCRSNO
	CALL	SENDACK
	JMP	RCVLP
;
RCVEOT	CALL	WRBLOCK
	CALL	SENDACK
	CALL	CLOSFIL
	mvi	a,'R'
;
; ====>	log who sent in the file
;
logxfer	push	psw		;save 'R' or 'S'
	call	rsuser		;user = default
	CALL	rsdma		;DMA=80H
	LXI	H,LOGFL 	;POINT TO FILE
	CALL	EXTEND
	CALL	WRCRLF
	MVI	A,']'
	CALL	WRBYTE
	pop	psw		;get (S)ent or (R)eceived
	CALL	WRBYTE
	MVI	A,','
	CALL	WRBYTE
	LXI	H,answer	;point to filename
	CALL	WRVARC
	CALL	WREOF		;CLOSE THE FILE
	call	ilprt
	db	'Transfer complete.',cr,lf,0
	JMP	mfunct

;
; can't receive - disk is designated "R/O".
;
xrdonly	call	ilprt
	db	'++ Sorry disk is Read-only ++',cr,lf,0
	jmp	mfunct
;	________
;
; subroutines.
;
rcvsect	xra	a
	sta	errct
rcvrpt	mvi	b,10
	call	recv
	jc	rcvserr
	cpi	soh
	jz	rcvdsoh
	ora	a
	jz	rcvrpt
	cpi	eot
	stc
	rz
	call	ckx		;09/12/82 check for 3-^x
;
; error receiving sector
;	(bad SOH, bad sector, timeout)
;
RCVSERR	MVI	B,1		;purge
	CALL	RECV		;	the
	JNC	RCVSERR		;	line
	MVI	A,nak	
	CALL	SEND
	LDA	ERRCT
	INR	A
	STA	ERRCT
	CPI	10
	JC	RCVRPT
;
RCVSABT	CALL	CLOSFIL
	CALL	MERXIT
	DB	'++unable to receive block'
	DB	cr,lf,'++aborting++',0
;
rcvdsoh	MVI	B,1
	CALL	RECV		;get sect #
	JC	RCVSERR
	MOV	D,A
	MVI	B,1
	CALL	RECV		;get cma'd sect #
	JC	RCVSERR
	CMA
	CMP	D
	JZ	RCVDATA
	JMP	RCVSERR		;sec hdr bad
;
RCVDATA	MOV	A,D
	STA	RCVSNO
	MVI	C,0
	LXI	H,80H
RCVCHR	MVI	B,1
	CALL	RECV
	JC	RCVSERR
	MOV	M,A
	INR	L
	JNZ	RCVCHR
	MOV	D,C
	MVI	B,1
	CALL	RECV
	JC	RCVSERR
	CMP	D
	JNZ	RCVSERR
	LDA	RCVSNO
	MOV	B,A
	LDA	SECTNO
	CMP	B
	JZ	RECVACK
	INR	A
	CMP	B
	JNZ	ABORT
	RET
;
RECVACK	CALL	SENDACK
	JMP	RCVSECT
;
SENDACK	MVI	A,6
	CALL	SEND
	RET
;
SENDHDR	MVI	A,soh
	CALL	SEND
	LDA	SECTNO
	CALL	SEND
	LDA	SECTNO
	CMA
	CALL	SEND
	RET
;
; send a sector
;
SENDSEC	MVI	C,0		;init cksum
	LXI	H,80H		
SENDC	MOV	A,M
	add	c
	mov	c,a
	mov	a,m
	CALL	SEND
	INR	L
	JNZ	SENDC
	RET
;
SENDCKS	MOV	A,C
	CALL	SEND
	RET
;
GETACK	MVI	B,20		;was 10
	CALL	RECVDG		;clear garbage, get char
	JC	ACKERR
	CPI	6		;ack?
	RZ
	call	ckx		;09/12/82 check for ^X
;				 abort if 3 of them
ACKERR	LDA	ERRCT
	INR	A
	STA	ERRCT
	CPI	10
	RC
CSABORT	CALL	MERXIT
	DB	'CAN''T SEND SECTOR - ABORTING'
	DB	cr,lf,0
;
;
; 09/12/82 check for ^X (three times for a hit)
;
ckx	ani	7fh		;kill poss. parity
	cpi	'X'-40h		;09/12/82 check for ^X
	rnz
	lxi	h,nctlx
	dcr	m
	jz	abort
	mvi	b,3		;try for another ^X
	call	recv
	rc
	jmp	ckx
;
ABORT	LXI	SP,STACK
ABORTL	MVI	B,1
	CALL	RECV
	JNC	ABORTL
	MVI	A,'X'-40h
	CALL	SEND
ABORTW	MVI	B,1
	CALL	RECV
	JNC	ABORTW
	MVI	A,' '
	CALL	SEND
	CALL	ILPRT
	DB	'++ CANCELLED ++'
	DB	cr,lf,0
	JMP	MFUNCT
;
INCRSNO	LDA	SECTNO
	INR	A
	STA	SECTNO
	RET
;
testFIL	LXI	D,FCB
	MVI	C,SRCHF
	CALL	BDOS
	INR	A
	ora	a		;kill carry, set zero
	RZ
;
;	if the file is 0 long, it might be 'cause of an
;	aborted receive, so erase it and let it go again.
;
	lda	fcbnsec
	ora	a
	jnz	tex
	lxi	d,fcb
	mvi	c,erase
	call	bdos
	ora	a		;carry off, no error.
	ret
;
tex	CALL	ILPRT
	DB	'++FILE EXISTS, please receive as another name'
	DB	cr,lf,0
	stc			;carry shows error
	ret
;
MAKEFIL	lxi	d,fcb
	mvi	c,make
	call	bdos
	inr	a
	rnz
	call	merxit
	db	'++error - can''t make file'
	db	cr,lf,'++directory must '
	db	'be full',cr,lf,0
;
OPENFIL	LXI	D,FCB
	MVI	C,OPEN
	CALL	BDOS
	INR	A
	JNZ	OPENOK
	call	merxit
	DB	'CAN''T OPEN FILE',0
;
OPENOK	CALL	ILPRT
	DB	'FILE OPEN, EXTENT LENGTH: '
	DB	0
	LDA	FCB2-1
	CALL	HEX
	MVI	A,'H'
	CALL	TYPE
	CALL	CRLF
	RET
;
CLOSFIL	LXI	D,FCB
	MVI	C,close
	CALL	BDOS
	INR	A
	RNZ
	CALL	MERXIT
	DB	'CAN''T CLOSE FILE',0
;
RDSECT	LDA	SECINBF
	DCR	A
	STA	SECINBF
	JM	RDBLOCK
	LHLD	bufptr
	LXI	D,80H
	mov	b,e		;b=128
	CALL	MOVE
	SHLD	bufptr
	RET
;
RDBLOCK	LDA	EOFLG
	CPI	1
	STC
	RZ
	MVI	C,0
	LXI	D,wkbuf
RDSECLP	PUSH	B
	PUSH	D
	MVI	C,SETDMA
	CALL	BDOS
	LXI	D,FCB
	MVI	C,READ
	CALL	BDOS
	POP	D
	POP	B
	ORA	A
	JZ	RDSECOK
	DCR	A
	JZ	REOF
	CALL	MERXIT
	DB	'++FILE READ ERROR',0
;
RDSECOK	LXI	H,80H
	DAD	D
	XCHG
	INR	C
	MOV	A,C
	CPI	16		;16 sectors in buffer
	JZ	RDBFULL
	JMP	RDSECLP
;
REOF	MVI	A,1
	STA	EOFLG
	MOV	A,C
RDBFULL	STA	SECINBF
	LXI	H,wkbuf
	SHLD	bufptr
	LXI	D,80H
	MVI	C,setdma
	CALL	BDOS
	JMP	RDSECT
;
WRSECT	LHLD	bufptr
	XCHG
	LXI	H,80H
	mov	b,l		;b=128
	CALL	MOVE
	XCHG
	SHLD	bufptr
	LDA	SECINBF
	INR	A
	STA	SECINBF
	CPI	10H
	RNZ
WRBLOCK	LDA	SECINBF
	ORA	A
	RZ
	MOV	C,A
	LXI	D,wkbuf
DKWRLP	PUSH	H
	PUSH	D
	PUSH	B
	MVI	C,setdma
	CALL	BDOS
	LXI	D,FCB
	MVI	C,write
	CALL	BDOS
	POP	B
	POP	D
	POP	H
	ORA	A
	JNZ	WRERR
	LXI	H,80H
	DAD	D
	XCHG
	DCR	C
	JNZ	DKWRLP
rsbuf	XRA	A
	STA	SECINBF
	LXI	H,wkbuf
	SHLD	bufptr
RSDMA	LXI	D,80H
	MVI	C,setdma
	CALL	BDOS
	RET
;
WRERR	MVI	C,'X'-40h
	CALL	SEND
	CALL	MERXIT
	DB	'++ERROR WRITING FILE',cr,lf,0
;
WAITNAK	CALL	ILPRT
	DB	'AWAITING INITIAL NAK',cr,lf
	db	'to abort transfer, ^X three times',cr,lf,0
WAITNLP	MVI	B,1
	CALL	RECV
	CPI	nak
	RZ
	call	ckx		;09/12/82 check for ^X (3 times)
	DCR	E
	JZ	ABORT
	JMP	WAITNLP
;	________
;
; get name, no ambiguous names allowed
;
mgetnu	call	mgetnam
	rz
	push	psw
	call	ilprt
	db	'++ No ambiguous (? or *) names',cr,lf,0
	pop	psw
	ret
;
; get name to transfer
;	return # of "?" found in name
;
mgetnam	call	getvar
	DB	'Filename:',0
	DW	ANSWER		;READ INTO ANSWER
	DW	-1		;HELP MSG #: PASS "HELP" AND "?"
				;BACK TO THIS ROUTINE
	DB	30		;MAX ANSWER LEN
;
	lxi	h,answer	;point to raw name
	call	fmtfcb		;format filename to cefcb
;
;	if operator, allow disk specification.
;	if not, force to authorized disk.
;
	lda	passflg		;op?
	ora	a
	jnz	mgnop		;	y/leave disk
;
;	is operator - if disk specified, make it the
;	xfer disk, otherwise leave it.
;
	lda	cefcb		;default?
	ora	a
	jz	mgop		;yes, use prev disk
	sta	xdisk		;update it.
mgnop	lda	xdisk		;get authorized disk
	sta	cefcb		;ensure right disk
mgop	lxi	h,cefcb		;move it to fcb
	lxi	d,fcb
	mvi	b,12		;disk, fn, ft
	call	move		;set up fcb
;
	lda	xuser		;set user
	mov	e,a		;	to the
	mvi	c,sguser	;	authorized one
	call	bdos
	call	mfinit		;clear fcb etc.
;
; return with count of "?" in (A)
;
	lxi	h,fcb+1
	mvi	b,0		;init count
	mvi	c,11		;name length
mcountq	mov	a,m
	cpi	'?'
	jnz	mcnq
	inr	b
mcnq	inx	h
	dcr	c
	jnz	mcountq
	mov	a,b		;get count
	ora	a		;set result
	ret
;	________
;
; init file for transfer or type.
;
mfinit	xra	a
	sta	fcbext
	sta	fcbrno
	sta	eoflg
	sta	sectno
	jmp	rsbuf
;	________
;
; reset the user #
;
rsuser	lda	userno		;set CBBS normal
	mov	e,a		;	operational
	mvi	c,sguser	;	user #
	lda	passflg		;if operator,
	ora	a		;	leave as is.
	cnz	bdos		;
	ret
;	________
;
; error from transfer
;
merxit	pop	h		;get message
	call	typem0		;type up to 00h
	jmp	dmfunct		;kill stacked lines
;
RCVSNO	DB	0
SECTNO	DB	0
ERRCT	DB	0
;
; abort if ^X is entered from keyboard three times.  
; Prevents a single ^X glitch from aborting, yet 
; allows aborting.  Works for both send and receive.
;
nctlx	db	3
SECINBF	DB	0
;
 if wards
	link	cbbsward
 endif	
	LINK	CBBSWORK 	;NEXT .ASM FILE
                                                                                                                         