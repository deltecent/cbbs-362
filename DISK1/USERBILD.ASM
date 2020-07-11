;Name:		Userbild.asm
;Author:	Ward Christensen
;Written:	09/30/83 15:56:39
;Function:	Build an empty CBBS "USERS" file.
;Processor:	ASM
;Dependencies:	None. (converted from MAC program)
;		Only BIOS calls for I/O.
;Revs (last first):
;		None.
;Usage:		userbild [drive:]
;		ex:	userbild	builds on default drive
;			userbild b:	builds on B: drive.
;
cr	equ	0dh
lf	equ	0ah
;
	ORG	100H
	jmp	start
;
signon	DB	'USERBILD as of 09/30/83',cr,lf
	db	'Builds an empty CBBS USERS file on '
	db		'the logged in disk',cr,lf
	db	'or you may specify a drive: USERBILD '
	db		'B: for example',cr,lf
	db	'$'
;
;INIT LOCAL STACK, PRINT SIGNON MSG
;
START	LXI	H,0
	DAD	SP
	SHLD	STACK
	LXI	SP,STACK
;
	lxi	d,signon
	MVI	C,PRINT
	CALL	BDOS		;PRINT ID
;
;START OF PROGRAM EXECUTION
;
	lda	fcb		;get requested drive
	sta	users		;set it for USERS file
	lxi	d,users		;see if USERS exists
	mvi	c,srchf
	call	bdos
	inr	a
	jz	OK		;	no, OK, go on.
	call	ilprt
	db	'File USERS already exists',cr,lf
	db	'Type E to erase it: ',0
	MVI	C,RDCON
	CALL	BDOS
	ani	5fh		;make upper case
	call	crlf
	cpi	'E'
	jnz	abort
	mvi	c,erase
	lxi	d,users
	call	bdos
	jmp	ok
;
abort	call	erxit
	db	'Aborting',0
;
;	File didn't previously exist.
;
OK	call	ilprt
 db cr,lf
 db 'The size of the user file is determined by ULEXM,',cr,lf
 db ' (the User Logging Extent Mask)',cr,lf,cr,lf
 db 'Input a ULEXM of: 0 to abort',cr,lf,cr,lf
 db 'Input a ULEXM of: 1 for a  32K user file of  511 entries.',cr,lf
 db 'Input a ULEXM of: 3 for a  64K user file of 1023 entries.',cr,lf
 db 'Input a ULEXM of: 7 for a 128K user file of 2047 entries.',cr,lf
 db 'Enter the ULEXM value you set or will set in CBBS.ASM: '
 db 0
	mvi	c,rdcon
	call	bdos
	ani	7FH
	call	crlf
	cpi	'0'
	jz	abort
	lxi	h,511/2		;/2 'cause counting SECTORS.
	cpi	'1'
	jz	gotu
	lxi	h,1023/2
	cpi	'3'
	jz	gotu
	lxi	h,2047/2
	cpi	'7'
	jnz	OK
;
;	HL contains record count: write the file.
;
gotu	push	h		;save count
	mvi	c,make		;make
	lxi	d,users		;	the
	call	bdos		;	file
	inr	a		;test ret code
	jz	makerr		;oops - no room
	mvi	c,setdma	;set dma to 
	lxi	d,ubuff		;	the data buffer
	call	bdos
	call	ilprt
	db	'One . for each sector written: ',0
	pop	h		;get count
wrlp	push	h		;save count
	mvi	c,write		;write 1 sect
	lxi	d,users
	call	bdos
	ora	a		;test write
	jnz	wrerr		;	bad, exit
	mvi	c,wrcon
	lxi	d,'.'		;show progress
	call	bdos
;
;	bump record numbers
;
	lxi	h,r1+3
	call	add2
	lxi	h,r2+3
	call	add2
	pop	h
	dcx	h
	mov	a,h
	ora	l
	jnz	wrlp
	mvi	c,close
	lxi	d,users
	call	bdos
	inr	a
	jz	clserr
	call	erxit
	db	cr,lf
	db	'++ DONE ++$'
;
; add 2 in ascii
;
add2	push	h
	call	add1
	pop	h
;
; add 1 in ascii
;
add1	mov	a,m
	inr	a
	mov	m,a
	cpi	'9'+1		;carry?
	rnz
	mvi	m,'0'		;	yes
	dcx	h
	jmp	add1
;
; various error messages
;
makerr	call	erxit
	db	'++ Can''t make USERS file on logged-in disk$'
wrerr	call	erxit
	db	cr,lf
	db	'++ Can''t write USERS file on logged-in disk',cr,lf
	db	'Disk may be full$'
clserr	call	erxit
	db	cr,lf
	db	'++ Can''t close USERS file on logged-in disk$'
;
; print CRLF, but save (A).
;
crlf	push	psw
	call	ilprt
	db	cr,lf,0
	pop	psw
	ret
;
;inline print:  Call ilprt, with message following
;the call.  A 00 terminates the message.  Control
;returns following the 00
;
ilprt	xthl
ilplp	mov	a,m
	call	type
	inx	h
	mov	a,m
	ora	a
	jnz	ilplp
	inx	h		;07/04/82 - skip the 00
	xthl
	ret
;
;TYPE CHAR IN A, SAVES ALL REGS
;
type	push	b
	push	d
	push	h
	mov	e,a
	mvi	c,wrcon
	call	bdos
	pop	h
	pop	d
	pop	b
	ret
;
;EXIT WITH ERROR MESSAGE
;
MSGEXIT	EQU	$		;EXIT W/"INFORMATIONAL" MSG
ERXIT	POP	D		;GET MSG
	MVI	C,PRINT
	call	bdos
;
;EXIT, RESTORING STACK AND RETURN
;
EXIT	lxi	d,80h		;reset dma to 80h
	mvi	c,setdma	;	so SUBMIT will work
	call	bdos
	LHLD	STACK
	SPHL
	RET			;TO CCP
;
; fcb for users file
;
users	db	0,'USERS      ',0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0
;
; 128 byte buffer containing 2 user records.
;
ubuff	db	'     , ,                     ,     ,        ,     ,     ,'
r1	db	'0000G',cr,lf
	db	'     , ,                     ,     ,        ,     ,     ,'
r2	db	'0001G',cr,lf
;
	DS	100		;STACK AREA
STACK	DS	2
;
;bdos equates
;
RDCON	EQU	1
WRCON	EQU	2
PRINT	EQU	9
CLOSE	EQU	16
SRCHF	EQU	17
ERASE	EQU	19
WRITE	EQU	21
MAKE	EQU	22
SETDMA	EQU	26
BDOS	EQU	5
FCB	EQU	5CH 
