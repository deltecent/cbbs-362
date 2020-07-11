;CBBS V3.6.2 	CBBSSUB3.ASM - NON-DISK ROUTINES # 3
;10/02/83 22:51:56
;	LINKS TO CBBSIDS	IDS
;		 CBBSHAYS	HAYES
;		 CBBSPMMI	PMMI
;		 CBBSMODM	SERIAL
;		 CBBSWORK	TEST (no modem)
;
;	O O O	O   O	O O	 O O
;	O 	O   O	O   O	O   O
; CBBS	O O O	O   O	O O	   O 	.ASM
;	    O	O   O	O   O	O   O
;	O O O	O O O	O O	 O O
;
;MOD LOG: (THRU 3.2 MOVED TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;
;08/05/83 Change "U" switch back to "G" on adding name to user file
;04/24/83 Allow var extent mask, user logging: 512 or 1024 entries
;04/02/83 in User logging, log overlaid user to log tty.
;	  Add stacked "/" at logon to mean "don't update
;	  the user log".
;10/15/82	Add user logging routines.
;
;
;---->	SETTAB CONVERTS SPACES IN A LINE TO TABS.
;CALLED PRIOR TO WRITING A LINE TO DISK, TO SAVE
;DISK SPACE.
;
;INPUT	HL = LINE TO CONVERT.
;OUTPUT	HL = CONVERTED LINE (CONVERTED IN PLACE)
;
SETTABS	push	d
	PUSH	H	;SAVE BUFF ADDR
;
;SETTABS PASS 1: STORES TABS EVERY 8 COLUMNS, PROVIDING
;THERE IS A SPACE IN THE COLUMN.
;
	MVI	B,1	;SET COLUMN
STTBL	MOV	A,M	;GET CHAR
	CPI	CR	;END?
	JZ	STTB2	;YES, TO PASS 2
	MOV	A,B	;AT A..
	ANI	7	;..TAB STOP?
	JNZ	STTNT	;NOT TIME FOR TAB
	MOV	A,M	;STORE TAB IF..
	CPI	' '	;..IT'S A SPACE
	JNZ	STTNT	;..NOT A SPACE
	MVI	M,TAB	;OVERLAY SPACE
STTNT	INX	H	;TO NEXT CHAR
	INR	B	;BUMP COLUMN
	JMP	STTBL	;LOOP
;
;SETTABS PASS 2: BACKS UP THRU THE LINE STORING 00H
;IN EVERY BYTE PRECEDING A TAB.
;
STTB2	DCR	B	;BACK UP COL #
	JZ	STTB3	;DONE?
	DCX	H	;BACK UP COL ADDR
	MOV	A,M	;GET CHAR
	CPI	TAB
	JZ	STTB2T	;GOT A TAB
	ORA	A	;GET A NULL?
	JNZ	STTB2	;NO, LOOP
STTB2T	DCR	B	;BACK UP COL
	JZ	STTB3	;TO PASS 3 IF DONE
	DCX	H	;BACK UP COL
	MOV	A,M	;GET CHAR
	CPI	TAB	;IF TAB SKIP..
	JZ	STTB2T	;..BACK OVER IT
	CPI	' '	;IF NOT SPACE,..
	JNZ	STTB2	;..DON'T..
	MVI	M,0	;OVERLAY ' ' WITH OOH
	JMP	STTB2T	;LOOP
;
;SETTABS PASS 3: DELETE NON-ESSENTIAL TABS,
;I.E. ONES WHICH FUNCTIONALLY CAN BE REPLACED
;BY A SINGLE SPACE.
;
STTB3	INX	H	;TO NEXT CHAR
	MOV	A,M	;GET CHAR
	CPI	CR	;END?
	JZ	STTB4	;TO PASS 4
	CPI	TAB	;LOOP IF..
	JNZ	STTB3	;..NOT A TAB
	DCX	H	;PREVIOUS
	MOV	A,M
	INX	H	;A NULL?
	ORA	A
	JZ	STTB3	;YES, OK
	MVI	M,' '	;CHANGE TAB TO SPACE
	JMP	STTB3
;
;SETTABS PASS 4: DELETES THE NULLS (00H)
;PACKING THE LINE IN PLACE.
;
STTB4	POP	H	;GET BUFF ADDR
	PUSH	H	;SAVE BACK
	MOV	D,H	;HL = INPUT POINTER
	MOV	E,L	;DE = OUTPUT POINTER
STTB4L	MOV	A,M	;GET CHAR
	ORA	A	;NULL?
	JZ	STTB4N	;YES, SKIP STORE
	STAX	D	;SAVE OUTPUT
	INX	D
STTB4N	INX	H
	CPI	CR	;END OF BUFF?
	JNZ	STTB4L	;NO, LOOP
;
;SETTABS PASS 5: deblank end of line
;
sttb5	POP	H	;GET BUFF
	push	h	;save back
	mvi	b,0	;init "prev char".
sttb5l	mov	a,m	;get char
	inx	h
	mov	c,b	;prev to c
	mov	b,a	;curr to b
	cpi	0dh	;loop until
	jnz	sttb5l	;	at end
;
;	got c/r, see if previous was space or tab
;
	mov	a,c
	cpi	' '	;space?
	jz	sttb5t	;	y/truncate
	cpi	tab	;tab?
	jnz	sttb5r	;	n/return
sttb5t	dcx	h	;to c/r
	dcx	h	;to space/tab
	mvi	m,cr	;new end
	jmp	sttb5	;loop until done.
;
sttb5r	pop	h
	pop	d
	RET
01;START OF MODS
;
;ROUTINE TO FLUSH THE BUFFERS IF RUNNING UNDER FAST
;
 	IF	FAST	;OPTIONAL BUFFERING?
;
FLUSH	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	1	;GET WARM BOOT
	INX	H	;POINT TO LO(W.BOOT)
02	INX	H	;POINT TO HI(W.BOOT)
	MOV	A,M	;SEE WHERE WBOOT IS
	CMP	H	;JUMPING LOWER IN MEM?
	JZ	FLUSHRT	;NO, NO FAST
	JNC	FLUSHRT	;NO FAST
;
;FLUSH BUFFERS
;
	LHLD	6	;GET BDOS ADDR
	DCX	H
	DCX	H
	DCX	H	;BACK UP TO FLUSH ENTRY
	MOV	A,M	;MAKE SURE ITS A JMP
	CPI	0C3H
	CZ	PCHLIT	;GO FLUSH
FLUSHRT	POP	H
	POP	D
	POP	B
	RET
;
PCHLIT	PCHL
	ENDIF		;FAST
01;END OF MODS '01'
;
;	----------------
;
 if ulog
;
; ====>	Find a user in the USER file, at logon time.
;
ULogin	equ	$
;
; use ORG and DS technique to map displacements in
;	the user log record.  Each record is 64 bytes.
;	Each field is ',' terminated, so each DS is 1
;	byte longer than the data field to account for the ','
;
	org	0		;dummy org to set displacements
;
usrno	ds	5+1		;00-05 caller #
usrspec	ds	1+1		;06-07 1-byte "special user" flag
usrname	ds	21+1		;08-29 user name
usrpass	ds	5+1		;30-35 user's password, hashed
usrdate	ds	8+1		;36-44 date of last call
usrtime	ds	5+1		;45-50 time of last call
usrmsgn	ds	5+1		;51-56 high msg #
usrpad	ds	4		;57-60 unused area
usru	ds	1+2		;61=byte stored by "U" cmd, then CR/LF
usrend	equ	$		;should be 64
;
	org	ULogin		;org back to code generation
;
	lda	twitsw		;twits don't
	ora	a		;	get to
	rnz			;	log in.
;
	call	ulfind		;find the name
	jc	uladdn		;add if not found
;
;	found user
;
 endif				;ulog
 if ulog and upass
	call	ulpass		;get password if approp
 endif
 if ulog
	lda	twitsw		;see if got name wrong		|3.6.3
	ora	a		;	yes, don't print stats 	|3.6.3
	rnz			;	or update		|3.6.3
	call	ulstats		;print prev stats
	call	ulupdat		;update date, time, hi msg #
	lda	inbuf
	cpi	'/'
	push	psw
	cnz	ulwrbak		;write the record back.
	pop	psw
	rnz
	CALL	GETVAR		;dummy getvar to get "/"
	DB	0		;	out of inbuf.
	DW	WKBUF
	DW	0
	DB	2
	ret
;	________
;
; user wants to change password or save status
;
uluser	lda	twitsw		;if twit, don't allow
	ora	a		;	password change.
	jnz	whatm
	call	ulfind
	cc	ulerr
	lda	inbuf
	cpi	'Y'
	jnz	ulrbits
 endif
 if ulog and upass	;---------------;
	call	ilprt			;
	db	'Want to change passwords',0
	call	iqans		;get yes/no answer
	jc	funct		;	said "Q"
	cpi	'N'			;
	jz	ulrbits		;just set bits.
	call	ilprt			;
	db	'Enter new password.',cr,lf,0
	call	ulgp			;
 endif			;---------------;
 if ulog
;
;	record various flags in one byte of record
;	value will be 40-5FH
;
; bits:  __80______40______20______10______08______04______02______01___
;	|	|	|	|	|	|	|	|	|
;	|   0	|   1	|   0 	| short	| expert| bell	| duplex| case	|
;	|_______|_______|_______|_______|_______|_______|_______|_______|
;
ulrbits	call	ilprt
	db	'(C)ase (D)uplex (P)rompt e(X)pert and '
	db		'SHORT set for next time',cr,lf,0
	mvi	b,4		;init bit pattern "100".
	lxi	h,noneflg	;1 means "short" - 	10H
	call	ulrdbit		;turn on next bit of (B)
	lxi	h,expert	;1 means expert		08
	call	ulrdbit
	lxi	h,bellf		;1 means want bell	04
	call	ulrdbit
	lxi	h,echoflg	;1 means echo chars	02
	call	ulrdbit
	mvi	a,usrpad+4	;to last byte of record
	call	uldisp		;point to it
	lda	case		;get ff = upper/lower
	rlc			;ff sets 1 bit on, 5f doesn't
	ani	1
	add	b
	mov	m,a		;store flag.
	call	ulwrbak		;write the record back.
	jmp	funct
;
;	turn on low bit in (B) if m(hl) has low bit on
;
ulrdbit	mov	a,m		;get flag (bell, expert, etc)
	ani	1		;isolate meaningful bit
	add	b		;add to prev total
	add	a		;shift for next bit
	mov	b,a
	ret
;
; set up fcb, other init's
;
ulsetup	lxi	h,userfil	;point to filename
	lxi	d,fcb
	mvi	b,12		;set up move
	call	move
	call	ulhash		;hash the name to B reg
;
;	(A) now = 8-bit hash.  Use it as extent and sector #
;
	mov	a,b		;get hash
	rlc			;move hi bit to low
	ani	ulexm		;get extent (0 or 1)
	sta	fcbext		;	(or 0-3 if ulexm=3)
	mov	a,b		;re-get hash
	ani	7fh		;get record #
;
; Multiply record number by (127-10)/128 to prevent
; crossing extent boundary, and prevent fear of "EOF".
;
	lxi	h,0		;init product
	mvi	b,8		;init loop count
	lxi	d,256*117/128	;set 117/128'ths fraction
ulmulp	dad	h
	add	a
	jnc	ulmunc
	dad	d
ulmunc	dcr	b
	jnz	ulmulp		;(A) = 117/128 * old (A)
	mov	a,h
;
ulext0	sta	fcbrno
	call	setopen		;open the file
	cc	ulerr
	xra	a
	sta	eoflg
;
;	set low caller # to 99999 to force replace
;
	lxi	h,savmsg	;where hi match performed
	mvi	b,5
ul9	mvi	m,'9'
	inx	h
	dcr	b
	jnz	ul9
	mvi	a,20		;limit of scan after hash
	sta	tries
	ret
;
; find user in user file
;
ulfind	call	ulsetup		;set up fcb, etc, then...
;
; scan for the name.
;	Store caller # in "missmsg".
;
ulscan	lxi	h,missmsg	;where to store caller # read.
	push	h
	mvi	b,5		;length of caller #
	call	ulstor		;save in missmsg
	cc	ulerr		;eof - shouldn't happen
;
;	missmsg now has caller # - see if lower
;
	pop	h
	cpi	' '		;open entry (' ' last digit)?
	jnz	ulnbe		;not a blank entry
	lda	bufptr
	ani	0c0h
	sta	scanptr
	lda	fcbrno		;save
	dcr	a		;	rec # for
	sta	scanptr+1	;	positioning
	stc			;show not found
	ret
;
;	did not find a blank entry - continue scan
;
ulnbe	call	rdbyte		;get ','
	call	rdbyte		;get special user flag
	cpi	'S'
	jz	ulnlow		;don't replace a special user
	lxi	d,savmsg
	mvi	b,5
	call	compr
	jc	ulnlow
;
;	got lower caller # - save positioning.
;
	lxi	h,missmsg	;from
	lxi	d,savmsg	;to
	call	move5
	call	ulbsave		;reset buf ptr
;
ulnlow	call	rdbyte		;get ','
;
;	now pointing to name.  Check it.
;
	lxi	h,fname
	call	ulmat		;match
	jc	ulnext
	lxi	h,lname
	call	ulmat
	jc	ulnext
	call	ulbsave		;reset buffer pointer
	ora	a		;no carry means "found"
	ret
;
; save buffer pointer @ front of record.
;
ulbsave	lda	bufptr		;get sector displ.
	ani	0c0h		;point to front
	sta	scanptr
	lda	fcbrno
	dcr	a
	sta	scanptr+1
	ret
 endif
 if ulog and upass
;
; See if password.
;
ulpass	mvi	a,usrpass
	call	uldisp		;point to password
	mov	a,m
	cpi	' '
	rz
	shld	strptr		;save pw pointer
;
;	got password - validate it
;
	mvi	a,ctlkoff
	sta	ctlksw		;don't let 'em go.
	mvi	a,4
ulrepas	sta	tries
	call	getpass
	db	'Password: your 1-5 char password',0
	dw	answer
	dw	0		;help msg #
	db	5		;length
	call	ulpas5a		;pad to 5
	lxi	d,answer
	lhld	strptr
	mvi	b,5
;
;	compare the password, with hashing
;
ulpc	ldax	d		;get actual char
	call	hashpw		;turn into hash
	cmp	m
	jnz	ulpwb
	inx	h
	inx	d
	dcr	b
	jnz	ulpc
	ret
;
ulpwb	call	ilprt
	db	'++ Incorrect ++',cr,lf,0
	lda	tries
	dcr	a
	jnz	ulrepas
	call	ilprt
	db	'++ Sorry, access restricted ++',cr,lf,0
	mvi	a,1
	sta	twitsw
	ret
 endif
 if ulog
;
; print statistics
;
ulstats	call	ilprt
	db	cr,lf,'Prev. call ',0
 endif	;ulog
 if ulog and clock
	mvi	a,usrdate
	call	uldisp
	call	ultypec
	call	ilprt
	db	' @ ',0
	call	ultypec
 endif
 if ulog
	call	ilprt
	db	', next msg was ',0
	mvi	a,usrmsgn
	call	uldisp
	push	h
	call	ultypec
	call	ilprt
	db	cr,lf
	db	' (* refers to prev. hi: '
	db		's;* - o;* - r;*;+)',cr,lf,0
	pop	h
	lxi	d,prevhi
	call	move5
;
;	restore the various flag values from last setting
;
	mvi	a,usrpad+4	;to last byte of record
	call	uldisp		;point to it
	mov	a,m		;get flag
	cpi	' '		;not set?
 	rz
	add a ! add a ! add a	;next shift is "short" flag bit
	lxi	h,noneflg	;1 means "short" - 	10H
	call	ulwrbit		;turn on next bit of (B)
	lxi	h,expert	;1 means expert		08
	call	ulwrbit
	lxi	h,bellf		;1 means want bell	04
	call	ulwrbit
	lxi	h,echoflg	;1 means echo chars	02
	call	ulwrbit
	add	a		;shift case bit to carry
	mvi	a,0ffh
	jc	ulstcas		;store case
	mvi	a,5fh		;user is upper-case only
ulstcas	sta	case
	ret
;
;	write a bit based on (a)
;
ulwrbit	add	a		;bit to carry
	mov	b,a		;save byte
	ral			;carry to 01 bit
	ani	1
	mov	m,a		;set appropriate flag
	mov	a,b		;restore reg
	ret
;
; (A) = field displacement, type the field.
;
ultypec	mvi	b,','
	call	typem
	ret
;
; update user statistics
;
ulupdat	mvi	a,usrno		;disp to caller #
	call	uldisp		;to hl
	lxi	d,callern	;get caller #
	xchg			;set up for move
	call	move5		;move in caller #
;
	mvi	a,usrdate	;point to date
	call	uldisp
	xchg			;to de
 endif
 if ulog and clock
	lxi	h,date		;get from
 endif
 if ulog and not clock
	lxi	h,spaces
 endif
 if ulog
	mvi	b,8
	call	move		;move in the date
	inx	d		;point to time
 endif
 if ulog and clock
	lxi	h,lgintim	;to time
 endif
 if ulog and not clock
	lxi	h,spaces
 endif
 if ulog
	call	move5		;move the time
	inx	d		;point to hi msg
	lxi	h,highmsg	;to hi msg #
	call	move5		;move it
	ret
;
spaces	db	'        '
;
; write the updated record back
;
ulwrbak	call	ilprt
	db	'Recording logon for next time...',0
	lxi	h,fcbrno	;point to rec #
	dcr	m		;back up to "current" sector
	lxi	d,fcb		;
	push	d
	mvi	c,write
	call	bdos
	ora	a
	pop	d
	jnz	ulwrer
	mvi	c,close
	call	bdos
	cpi	0ffh
	rnz
	call	ilprt
	db	'close ',0
	call	ulerr
;
ulwrer	call	ilprt
	db	'write ',0
	call	ulerr
;
; position to next caller
;
ulnext	lxi	h,tries
	dcr	m
	stc
	rz			;use oldest of the 20
ulnlp	call	rdbyte
	cc	ulerr
	cpi	lf
	jnz	ulnlp
	jmp	ulscan
;
; add name to file
;
uladdn	lxi	h,fname+1	;04/24/83 mod: ignore names < 4 chars
	mov	a,m		;or 1-letter 1st or last names
	cpi	cr
	rz
	call	countc0		;init b=0, count chars
	lxi	h,lname+1
	mov	a,m
	cpi	cr
	rz
	call	countc
	mov	a,b
	cpi	4
	rc			;ret if short name (twit)
	lda	scanptr+1	;get rec # to write
	sta	fcbrno
	lxi	d,fcb
	mvi	c,read
	call	bdos
	ora	a
	cnz	ulerr
	lda	scanptr		;get base addr
	mov	e,a
	mvi	d,0		;DE = pointer to record
;
 endif
 if ulog and tty

	push	d		;log old contents if log.
	call	loguser		;	is enabled
	pop	d
 endif
 if ulog
	lxi	h,callern
	call	move5		;move in this caller #
	inx d ! inx d ! inx d	;skip to name
	lxi	h,fname
	call	ulmvn		;move name
	mvi	a,' '
	stax	d
	inx	d
	lxi	h,lname
	call	ulmvn
;
;	pad name w ' ' to fill field
;
	mvi	b,usrpass-2
	call	ulpadsp
 endif
 if ulog and upassn
	call	ulgp		;get password
 endif
 if ulog and not upassn
;
; no passwords - blank it out
;
	mvi	a,usrpass		;
	call	uldisp		;point hl to pw.
	xchg			;move to de for ulpadsp
	mvi	b,usrdate-2	;last location to blank
	call	ulpadsp
 endif
 if ulog
	mvi	a,usru		;restore to default switches
	call	uldisp		;	for case etc.
	mvi	m,'G'
	call	ulupdat		;update info
	jmp	ulwrbak		;	then write back, ret.
;
 endif
 if ulog and upass	;---------------;
uldiff	call	ilprt			;
	db	'No match, try again..',cr,lf,0
;					;
; get user password (first time, or to change it)
;					;
ulgp	mvi	a,cr		;kill	;
	sta	inbuf		;	stacked input
	call	getpass			;
	db	'Enter 1-5 char password if you wish to ensure',cr,lf
	db	'no one may log-on under your name,',cr,lf
	db	'==> just press return to NOT HAVE a password.',0
	dw	answer			;
	dw	0			;
	db	6			;
	lda	answer			;
	cpi	cr			;
	jz	ulnpw			;
;					;
;	entered PW, validate by double compare
;					;
	call	getpass			;
	db	'Please enter it again, to ensure I got it right',0
	dw	answer+10		;
	dw	0			;
	db	6			;
	lxi	h,answer		;
	lxi	d,answer+10		;
ulcpw	ldax	d			;
	cmp	m			;
	jnz	uldiff			;
	inx	d			;
	inx	h			;
	cpi	cr			;
	jnz	ulcpw			;
;					;
ulnpw	call	ulpas5a		;pad to 5
;					;
;	store password (hashed) then return
;		to update rest of info	;
;					;
	mvi	a,usrpass		;
	call	uldisp		;point hl to pw.
	lxi	d,answer		;
	mvi	b,5			;
ulstpw	ldax	d		;get char
	call	hashpw		;hash it to garbage
	mov	m,a			;
	inx	d			;
	inx	h			;
	dcr	b			;
	jnz	ulstpw			;
	ret				;
;					;
; extend the password to 5 chars with spaces if necess.
;					;
ulpas5a	lxi	h,answer		;
ulpass5	mvi	b,5			;
ulp5l	mov	a,m			;
	cpi	cr			;
	jz	ulp5c			;
	inx	h			;
	dcr	b			;
	jnz	ulp5l			;
	ret				;
;					;
ulp5c	mvi	m,' '			;
	inx	h			;
	dcr	b			;
	jnz	ulp5c			;
	ret				;
 endif			;---------------;
 if ulog
;
; pad field with spaces, b = end displacement
;
ulpadsp	mvi	a,' '
	stax	d
	inx	d
	mov	a,e
	ani	3fh		;get displ w/in 64 byte entry.
	cmp	b		;at end?
	jc	ulpadsp
	ret
;
; move a name
;
ulmvn	mov	a,m
	cpi	cr
	rz
	cpi	','
	jnz	ulmnnc
	mvi	a,' '
ulmnnc	stax	d
	inx	h
	inx	d
	jmp	ulmvn
;
; get displacement to field
;
uldisp	lxi	h,scanptr	;point to buffer
	add	m		;add displ
	mov	l,a
	mvi	h,0
	ret			;hl = field
;
; hash the caller's name. (first & last)
;
ulhash	mvi	b,0		;init hash
	lxi	h,fname
	call	hashsub
	lxi	h,lname
	call	hashsub
	ret
;
hashsub	mov	a,m
	cpi	cr
	rz
	add	b		;twiddle the bits...
	aci	0
	mov	b,a
	inx	h
	jmp	hashsub
;
; match the name
;
ulmat	call	rdbyte
	cpi	','
	rz			;at end of name
	cmp	m
	inx	h
	jz	ulmat
	cpi	' '
	jz	ulsp		;at end of name 
;				 or between first/middle
	stc			;show not found
	ret
;
;	got space, if @ end of name, OK.
;
ulsp	dcx	h
	mov	a,m
	inx	h		;setup for next compare if =
	cpi	cr
	rz
	stc			;show not found
	ret
 endif
 if ulog and upass	;---------------;
;					;
; hash a password char			;
;					;
hashpw	cpi	' '		;don't hash
	rz			;	spaces
	mov	c,a		;save it;
	ora	a			;
	rar				;
	cma				;
	xra	c			;
	ani	0fh			;
	adi	'@'			;
	ret				;
 endif			;---------------;
 if ulog
;
; store bytes from file into (hl), length in (b)
;
ulstor	call	rdbyte
	rc
	mov	m,a
	inx	h
	dcr	b
	jnz	ulstor
	ora	a
	ret
;
; print a field from disk, skipping thru ','
;
ulprf	call	rdbyte
	cc	ulerr
	cpi	','
	rz
	call	type
	jmp	ulprf
;
; error exit - no file, or read or format error
;
ulerr	call	ilprt
	db	'++ user file error ',0
;
;	print the addr of the call to ulerr for debugging.
;
	pop	h
	mov	a,h
	call	hex
	mov	a,l
	call	hexb
	jmp	tellus
;
 endif	;ulog
;
;LINK TO APPROPRIATE NEXT .ASM FILE
;
	IF	IDS
	LINK	CBBSIDS
	ENDIF
;
	IF	HAYES
	LINK	CBBSHAYS
	ENDIF
;
	IF	PMMI
	LINK	CBBSPMMI
	ENDIF
;
	IF	SERMODM
	LINK	CBBSMODM
	ENDIF
;
	IF	test
	LINK	CBBSwork
	ENDIF
;
..ERROR AT END OF 'CBBSSUB3.ASM': NO MODEM SELECTED
;
;- YOU DID NOT SELECT ANY OF THE SUPPORTED
;MODEMS, AND SET ONE OF THE FOLLOWING TO TRUE:
;
;	PMMI, IDS, HAYES, OR SERMODM
;
                                                     