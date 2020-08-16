;CBBS V3.6.2 	FILE CBBS.ASM - MAINLINE
;08/14/20 19:47:00
;
;LINKS TO CBBSMAIN.ASM
;
VERS	EQU	3	;PRINTED AT SIGNON
MODIF	EQU	6	;(9 MAX)
LEV	EQU	2	;(9 MAX) or 'alpha char'-'0'
hack	equ	'g'	;' ' if none, else one ascii char
;
;	O O O	O O	O O	O O O
;	O	O   O	O   O	O
;	O	O O	O O	O O O  .ASM
;	O	O   O	O   O	    O
;	O O O	O O	O O	O O O
;
;	 ##################################
;	# This module is the only one that #
;	# need to be changed to customize  #
;	# for a particular system, if you  #
;	# are running a PMMI modem.        #
;	 ##################################
;
;========================================
;
;	O   O	O O O	O O O	O O O
;	OO  O   O   O	  O	O
;	O O O	O   O	  O	O O	O
;	O  OO	O   O	  O	O
;	O   O	O O O	  O	O O O	O
;
;	this program must be assembled with
;	"LINKASM.COM" which handles the "LINK"
;	pseudo-ops at the end of each file,
;	which links to the next .ASM file
;		----------------
;
;"CBBS"(R)  COMPUTERIZED BULLETIN BOARD SYSTEM (R)
;IS COPYRIGHT (C) WARD CHRISTENSEN, 1978, 1979, 1980, 
;1981, 1982, 1983.  Not for general distribution.
;
;	01/26/78
;ORIGINALLY WRITTEN, SITTING HOME SNOWBOUND
;BY WARD CHRISTENSEN
;
;ALL COMMENTS REGARDING MODIFICATION are recorded
;in "HISTORY" files.  Due to disk space limitations,
;these files are no longer distributed except for the
;one related to the changes in the most recent version.
;
;At times, modifications are indicated in the margin by 
;a number, corresponding to the number in the HIST... file.
;This idea was later abandoned as being "too much house-
;keeping".
;
;04/24/83	Add ulexm.  to support other thn 512 entry user file.
;		value/# users/user file size in K: 1/512/32K, 
;		3/1024/64K, 7/2048/128K. (latter not tested)
;10/17/82	Split out CBBS.ASM to CBBS.ASM and CBBSMAIN.ASM
;		to facilitate CBBS.ASM containing A-L-L the
;		equates, messages, etc. needed to customize CBBS.
;
FALSE	EQU	0
TRUE	EQU	NOT FALSE
;
FAST	EQU	FALSE		;running cbbs under "fast"?
CCOUNT	EQU	40		;max comment lines/call
ECOUNT	EQU	10		;max msgs entered/call
maxl	equ	20		;max lines in a message
notify	equ	true 		;notify from "next" file?
chat	equ	true		;want operator chat mode?
;
KBUFPG	EQU	08		;8 PAGE, 2K buffer FOR KILLING	
;----
;		----------------
;DIVISOR FOR # OF MSG FILES.  LAST 2 DIGITS
;OF MSG FILE ARE DIVIDED BY THIS #.  THEREFORE:
;	2	 MEANS	50 FILES 	(Standard)
;	3		34 FILES
;	4		25 FILES
;	5		20 FILES ..ETC.
;
FILEDIV	EQU	2		;50 MSG FILES IN CBBS/CHICAGO
				;	(and most others)
EJECT	EQU	FALSE		;EJECT TTY EVERY 60 LINES?
TWITCK	EQU	TRUE		;ABORT IF INVALID USER NAME
;
B450600	EQU	TRUE 		;450, 600 BAUD (PMMI, IDS ONLY)
;
CR	EQU	0DH
LF	EQU	0AH
EOF	EQU	1AH
TAB	EQU	09H
;
; -------->   NOTE THE FOLLOWING <---------
;
;The following address is OUTSIDE of this program.  It is a
;byte which contains a continually running line count for the
;logging tty.  It need not be initialized, because the
;counter will eventually reach 60, and get in sync.  THE
;COUNTER IS N-O-T REFERENCED IF EITHER 'EJECT' OR 'TTY' IS
;FALSE.
;
TTYLCT	EQU	042H
;
;	############
;
	ORG	100H
	JMP	START
;
;if clock board, define current year so it
;may be easily patched at year change (they
;become the 4th and 5th bytes of the .com file)
;
;following used if clock board doesn't keep YEAR.
;
y1	db	'8'	;define current..
y2	db	'3'	;..year printed
;
	db	'< COPYRIGHT (C) 1978-83, Ward Christensen >'
	db	'[09/20/83 21:28:20]'
	db	1ah	;^Z to allow "type cbbs.com"	
;
; ONE of these five MUST be true, rest false;-----------;
;							;
cbbschi	equ	false 	;cbbs/chicago things.		;
wards	equ	false	;Ward's CPMUG system?		;
randys	equ	false	;Randy's system or CBBS CHI test;
cust	equ	false	;YOUR custom system		;
test	equ	true	;Test version for non-modem:	;
			;(All files default to 		;
			;logged on disk)		;
;						;-------;
;SET THE FOLLOWING EQUATES FOR THE VARIOUS DISKS:
;
;     VALUE   DISK
;
;	0     LOGGED IN DISK
;	1     DISK A
;	2     DISK B
;	3     DISK C
;	4     DISK D
;
;(NOTE CBBS "RUNS" ON 1 DISK, COMFORTABLY ON 2)
;
;IF YOU HAVE A 1 DISK SYSTEM, SET ALL EQUATES=0
;
;		--------
;	DISKMSG contains:
;NEXT, SUMMARIES, MESSAGES
;		--------
;	DISKRO contains:
;FIRSTIME, WELCOME, BULLETIN, HELP, ENTRHELP,
;SCANHELP, ENTINTRO, MODMHELP AND PASSWORD
;		--------
;	DISKLK contains:
;LOG, KILLED, NOTES, USERS
;
;Ward's CBBS/CPMUG, an example of one-disk CBBS, 
;	drive B: used for file transfers.
;
 if wards	;================
	db	'Wards'		;compile identifier
UKILL	EQU	1		;TRUE, USER CAN KILL OWN MSGS
mhz	equ	4		;4mhz system
ulog	equ	true		;want user logging?
ulexm	equ	1		;# names: 1:512 3:1024 7:2048
upass	equ	true 		;user passwords?
upassn	equ	false		;new user, password wanted?
viostat	equ	0f000h+23*80 	;VIO status line "If Wards"
xfer	equ	true 		;file xfer (2.2 stuff used)
msgapp	equ	false		;must msgs be approved to be read?
minfnc	equ	true		;is "M" cmd in fnc menu?
reinit	equ	false		;set true if sys not reloaded
diskmsg	set	'@'-'@'		;logged in disk
diskro	set	'@'-'@'		;help & other R/O files.
disklk	set	'@'-'@'		;killed, log, users, notes
tty	equ	true 		;is there a log tty?
ttylr	equ	false		;is tty status low ready?
ttyst	equ	2		;status bit (jz wait loop)
ttysp	equ	4		;tty status port	
ttydp	equ	5		;tty data port		
ttywid	equ	90		;width @ C/R
ttybs	equ	'\'		;char used on tty for b.s.
;
ttystat	in	ttysp
	ani	ttyst
	ret			;zero if not ready
;
ttyout	out	ttydp	;output it	added label 1/3/82
	ret
hayes	equ	false		;have hayes S-100 modem?
ids	equ	false		;have  ids  modem?
pmmi	equ	true 		;have pmmi  modem?
sermodm	equ	false		;have serial modem?
pmmib	equ	0c0h		;PMMI base address
bymsg2	db	'from Ward: thanks for calling, ',0
phoneop	db	'Ward (312) 849-6279',cr,lf,0
motctl	equ	false		;want drive motor on/off ctl?
; sense switch read, return non-zero if remote mode
ssw	equ	0ffh		;sense switch port
remote	equ	80h		;ssw on for remote
rdssw	in	ssw		;go to start if remote
	ani	remote		;	switch turned off
	ret
clock1	equ	false		;compupro ss1 clock? (file cbbsclk1.asm)
clockc	equ	false		;compu-time clock? (file cbbsclkc.asm)
clocks	equ	true 		;scitronics clock? (file cbbsclks.asm)
clockh	equ	false		;Hayes Cronograph? (file cbbsclkh.asm)
clock	equ	clock1 or clockc or clocks or clockh ;have hardware clock?
 endif			;wards
;
 if cbbschi	;================ CBBS/Chicago, N* hard disk system
	db	'Cbbschi'	;compile id
UKILL	EQU	1		;TRUE, USER CAN KILL OWN MSGS
mhz	equ	4		;4mhz system
;
ulog	equ	true 		;want user logging?
ulexm	equ	3		;64K, 1024 names
upass	equ	true 		;user passwords?
upassn	equ	false		;new user, password wanted?
xfer	equ	true 		;want file xfer (cp/m 2.2 stuff used)
msgapp	equ	false		;must msgs be approved to be read?
minfnc	equ	false		;is "M" cmd in fnc menu?
reinit	equ	true 		;set true if sys not reloaded
diskmsg	set	'B'-'@'		;msgs, summary, next
diskro	set	'B'-'@'		;help & other r/o files.
disklk	set	'C'-'@'		;killed, log, users, notes
tty	equ	true 		;is there a log tty?
ttylr	equ	false		;is tty status low ready?
ttyst	equ	20h		;status bit (jz wait loop)
;ttysp	equ	base+5		;tty status port	
;ttydp	equ	base		;tty data port		
ttywid	equ	79		;width @ C/R
ttybs	equ	'\'		;char used on tty for b.s.
ttystat	mvi	a,0ffh		;always true status
	ora	a
	ret
;
ttyout	ret
hayes	equ	false		;have hayes S-100 modem?
ids	equ	false		;have  ids  modem?
pmmi	equ	false		;have pmmi  modem?
sermodm	equ	true  		;have serial modem?
pmmib	equ	0D0h		;PMMI base address <=NOTE
bymsg2	db	'from Ward and Randy, thanks for calling, ',0
phoneop	db	'Randy (312) 545-7535 or Ward 849-6279',cr,lf,0
;
motctl	equ	false		;want drive motor on/off ctl?
;ctlport	equ	base+4		;out to this port
ctlmotr	equ	1		;motor on output
motoron	ret
motorof	ret
; sense switch read, return non-zero if remote mode
ssw	equ	0		;sense switch port
remote	equ	80h		;ssw on for remote
rdssw	in	ssw
	ani	remote		;	switch turned off
	ret
clock1	equ	false		;compupro ss1 clock? (file cbbsclk1.asm)
clockc	equ	false		;compu-time clock? (file cbbsclkc.asm)
clocks	equ	true 		;scitronics clock? (file cbbsclks.asm)
clockh	equ	false		;Hayes Cronograph? (file cbbsclkh.asm)
clock	equ	clock1 or clockc or clocks or clockh ;have hardware clock?
 endif			;randys
;
 if Randys	;================ old cbbs/chicago
	db	'Randys'	;compile id.
UKILL	EQU	1		;TRUE, USER CAN KILL OWN MSGS
mhz	equ	4		;4mhz system
ulog	equ	true		;want user logging?
ulexm	equ	1		;# names: 1:512 3:1024 7:2048
upass	equ	false		;user passwords?
upassn	equ	false		;new user, password wanted?
xfer	equ	false		;no file transfer
msgapp	equ	false		;must msgs be approved to be read?
minfnc	equ	false		;is "M" cmd in fnc menu?
reinit	equ	false
diskmsg	set	'A'-'@'		;next, summary, msgs
diskro	set	'B'-'@'		;help & other R/O files.
disklk	set	'C'-'@'		;killed, log, users, notes
tty	equ	true 		;is there a log tty?
ttylr	equ	false		;is tty status low ready?
ttyst	equ	2		;status bit (jz wait loop)
ttysp	equ	4		;tty status port	
ttydp	equ	5		;tty data port		
ttywid	equ	79		;width @ C/R
ttybs	equ	'\'		;char used on tty for b.s.
ttystat	IN	TTYSP
	ANI	TTYST
	ret			;zero if not ready
;
ttyout	out	ttydp	;output it	added label 1/3/82
	ret
hayes	equ	false		;have hayes S-100 modem?
ids	equ	false		;have  ids  modem?
pmmi	equ	true 		;have pmmi  modem?
sermodm	equ	false		;have serial modem?
pmmib	equ	0c0h		;PMMI base address
bymsg2	db	'from Ward & Randy: thanks for calling, ',0
phoneop	db	'Randy (312) 545-7535',cr,lf
	db	' or Ward (312) 849-6279',CR,LF,0
;
; disk drive motor control 
;
motctl	equ	true		;want drive motor on/off ctl?
motoron	MVI	A,3	 	;LEAVE DISKETTE
	OUT	40h		;	MOTOR ON
	ret
motorof	xra	a
	out	40h
	ret
; sense switch read, return non-zero if remote mode
ssw	equ	0ffh		;sense switch port
remote	equ	80h		;ssw on for remote
rdssw	in	ssw		;go to start if remote
	ani	remote		;	switch turned off
clock1	equ	false		;compupro ss1 clock? (file cbbsclk1.asm)
clockc	equ	false		;compu-time clock? (file cbbsclkc.asm)
clocks	equ	true 		;scitronics clock? (file cbbsclks.asm)
clockh	equ	false		;Hayes Cronograph? (file cbbsclkh.asm)
clock	equ	clock1 or clockc or clocks or clockh ;have hardware clock?
 endif			;cbbschi
;
 IF CUST	;================ Your custom system
	db	'cust'		;compile id
UKILL	EQU	1		;TRUE, USER CAN KILL OWN MSGS
mhz	equ	2		;2mhz system
ulog	equ	true 		;want user logging?
ulexm	equ	1		;# names: 1:512 3:1024 7:2048
upass	equ	false		;user passwords?
upassn	equ	false		;new user, password wanted?
xfer	equ	true		;Want file transfer?
msgapp	equ	false		;must msgs be approved to be read?
minfnc	equ	true		;is "M" cmd in fnc menu?
reinit	equ	true 		;re-init (cbbs stays in mem?)
diskmsg	set	'A'-'@'
diskro	set	'A'-'@'
disklk	set	'A'-'@'		;killed, log, users, notes
tty	equ	false 		;is there a log tty?
ttylr	equ	false		;is tty status low ready?
ttyst	equ	2		;status bit (jz wait loop)
ttysp	equ	4		;tty status port	
ttydp	equ	5		;tty data port		
ttywid	equ	79		;width @ C/R
ttybs	equ	'\'		;char used on tty for b.s.
ttystat	IN	TTYSP
	ANI	TTYST
	ret			;zero if not ready
;
ttyout	out	ttydp	;output it	added label 1/3/82
	ret
hayes	equ	false		;have Hayes S-100 modem?<<
ids	equ	false		;have IDS modem?	<<
pmmi	equ	true 		;have PMMI  modem?	<<
sermodm	equ	false		;have serial modem?	<<
pmmib	equ	0c0h		;PMMI base address
bymsg2	db	'From Patrick:  Thanks for calling, ',0
phoneop	db	'sysop@mitsaltair.com'
;			terminated by:  
	db	cr,lf,0
motctl	equ	false		;want drive motor on/off ctl?
motoron	ret	;drive motor on code
motorof	ret	;drive motor off code
; sense switch read, return non-zero if remote mode
ssw	equ	0ffh		;sense switch port
remote	equ	80h		;ssw on for remote
rdssw	in	ssw		;
	ani	remote		;switch turned off?
	ret			;
clock1	equ	true		;compupro ss1 clock? (file cbbsclk1.asm)
clockc	equ	false		;compu-time clock? (file cbbsclkc.asm)
clocks	equ	false 		;scitronics clock? (file cbbsclks.asm)
clockh	equ	false		;Hayes Cronograph? (file cbbsclkh.asm)
clock	equ	clock1 or clockc or clocks or clockh ;have hardware clock?
 endif			;cust
;
 if test	;===============;Non-modem-clock-tty
				;system for testing
UKILL	EQU	1		;TRUE, USER CAN KILL OWN MSGS
mhz	equ	2		;4mhz system?
ulog	equ	true 		;want user logging?
ulexm	equ	1		;# names: 1:512 3:1024 7:2048
upass	equ	false 		;user passwords?
upassn	equ	false		;new user, password wanted?
xfer	equ	false		;No file xfer.
msgapp	equ	false		;must msgs be approved to be read?
minfnc	equ	true		;is "M" cmd in fnc menu?
reinit	equ	false		;re-init (cbbs stays in mem?)	<<<<
diskmsg	set	'@'-'@'		;logged in disk
diskro	set	'@'-'@'		;help & other R/O files.
disklk	set	'@'-'@'		;killed, log, users, notes
tty	equ	false 		;is there a log tty?
ttylr	equ	false		;is tty status low ready?
ttyst	equ	2		;status bit (jz wait loop)
ttysp	equ	4		;tty status port	
ttydp	equ	5		;tty data port		
ttywid	equ	79		;width @ C/R
ttybs	equ	'\'		;char used on tty for b.s.
ttystat	ret			;dummy routine
;
ttyout	equ	ttystat
hayes	equ	false		;have Hayes S-100 modem?<<
ids	equ	false		;have IDS modem?	<<
pmmi	equ	true 		;have PMMI  modem?	<<
sermodm	equ	false		;have serial modem?	<<
pmmib	equ	0c0h		;PMMI base address
bymsg2	db	'From Patrick:  Thanks for testing, ',0
phoneop	db	'<< this is operator phone number msg area >>',cr,lf
	db	'<< which doesn''t exist in CBBSTEST.COM   >>'
	db	cr,lf,0
motctl	equ	false		;want drive motor on/off ctl?
motoron	equ	$		;drive motor on code
;	...
motorof	equ	$		;drive motor off code
;	...
	ret
; sense switch read, return non-zero if remote mode
ssw	equ	0ffh		;sense switch port
remote	equ	80h		;ssw on for remote
rdssw	mvi	a,remote	;fake up sense switch
	ora	a		;	since system has none:
	ret			;	always remote mode.
clock1	equ	true		;compupro ss1 clock? (file cbbsclk1.asm)
clockc	equ	false		;compu-time clock? (file cbbsclkc.asm)
clocks	equ	false		;scitronics clock? (file cbbsclks.asm)
clockh	equ	false		;Hayes Cronograph? (file cbbsclkh.asm)
clock	equ	clock1 or clockc or clocks or clockh ;have hardware clock?
 endif
;================
;
;	________
;
	LINK	CBBSMAIN 	;NEXT .ASM FILE
