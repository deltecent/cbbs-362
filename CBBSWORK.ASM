;CBBS V3.6.2 	CBBSWORK.ASM - WORK AREA
;09/22/83 14:26:20
;	THIS IS THE LAST FILE, DOESN'T LINK
;	TO ANOTHER FILE.
;
;	O   O	O O O	O O O	O   O
;	O   O	O   O	O   O	O  O
; CBBS	O O O	O   O	O O O	O O	.ASM
;	OO OO	O   O	O O	O  O
;	O   O	O O O	O   O	O   O
;
;
;MODIFICATIONS LOG THRU 3.2 TO "HISTORY"
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;	then to history.036
;
;------------------ WORK AREA ----------------
;
;SUMMARY REQUEST OUTPUT AREA
;	(OVERLAID W/DATA FROM SUMMARY FILE)
;
SUMLN	DB	' MSG# LINES'
SUMDT	DB	'MM/DD/YY '
SUMFR	DB	'--------FROM-------- '
SUMTO	DB	'---------TO--------- '
	DB	CR,LF	;NEW LINE
04;MOD: (WAS 'SUBJECT:'
SUBJHD	DB	'   Subj:'
SUBJ	DB	'THIS IS THE MESSAGE SUBJECT   '
04;MOD: 1 CR/LF, NOT 2
	DB	CR,LF,0
;
; 10/17/82 Made brief alphabetized list of files used:
;
BULLIN	DB				'--->BULLETIN',CR
BULFL	DB	DISKRO,	'BULLETIN   '	;bulletin
CHATLOG	DB	DISKLK, 'CHATLOG    '	;" chat" command.
ENHLFL	DB	DISKRO,	'ENTRHELP   '	;HELP FOR ENTR Fncs
ENINFL	DB	DISKRO,	'ENTINTRO   '	;INTRO TO ENTER Fncs
FUNCFL	DB	DISKRO,	'FUNCTION   '	;FUNCTION SUMMARY
HELPFL	DB	DISKRO,	'HELP       '	;KEYWORD HELP
HELPIDX	DB	DISKRO,	'HELP    IDX'	;..AND ITS INDEX
HELP2FL	DB	DISKRO,	'HELP2      '	;"NAIVE USER" HELP
LOGFL	DB	DISKLK,	'LOG        '	;user log & comments.
MSGFN	DB	DISKMSG,'MESSAGE '	;msg FILENAME, type.
MSGFT	DB		'XNN'		;for ex. x02 (new way)
MSGLGFL	DB	DISKLK,	'KILLED     '	;killed msgs
NEWSFL	DB	DISKRO,	'NEWS       '	;"what's new" on CBBS
NEXTFL	DB	DISKMSG,'NEXT       '	;next caller, msg etc.
NOTEFL	DB	DISKLK,	'NOTES      '	;op-op notes
PASSFL	DB	DISKRO,	'PASSWORD   ',cr;system oper. password
SCHLFL	DB	DISKRO,	'SCANHELP   '	;help for searching
SUMFL	DB	DISKMSG,'SUMMARY    '	;message summaries
SYNFILE	DB	DISKRO,	'SYNONYM    '	;"BYE=G<CRLF>" etc.
TIME1	DB	DISKRO,	'FIRSTIME   '	;first time user stuff
USERFIL	DB	DISKLK,	'USERS      '	;user login file
WELCOM	DB	DISKRO,	'WELCOME    '	;WELCOME
WKFCB	DB	DISKMSG,'WORKFILE   '	; WORK FILE FCB --------;
					;USED IN KILLING	;
					;MSG & SUMM purge	;
WKEXT	DB	0	;EXTENT					;
	DS	19						;
WKRNO	DB	0	;SECTOR #				;
;	-	-	-	-	-	-	--------;
WKBFA	DW	$-$	;WORK BUFFER ADDR
WKCOUNT	DW	0	;BYTE COUNT
;
;POINTER TO MSG #'S STORED WHEN FLAGGING
;A MESSAGE DURING RETRIEVE.  0000 MEANS NONE
;
FLAGPTR	DW	0
;
;BELL FLAG, LOW BIT ON MEANS ECHO PROMPTING BELL
;
BELLF	DB	1
;
;MESSAGE TO TYPE WHEN BAD FUNCTION ENTERED
;
WHAT	DB	'I don''t understand ''',0
;
EOFLG	DB	0	;END OF FILE (1AH=EOF)
;
;FULL/HALF DUPLEX FLAG, 0=HALF
;
ECHOFLG	DB	1	;=0 MEANS NO ECHO
;
;NUMBER OF UNSUCCESSFUL KILL ATTEMPTS
;
NKILATT	DB	0	;CAN'T KILL IF 3 BAD
01;START OF MODS
;
;# OF MSG ENTRIES/CALL
;
ELEFT	DB	ECOUNT	;2 LEFT
;
;# OF COMMENT LINES PER CALL
;
CLEFT	DB	CCOUNT	;10 LEFT
01;END OF MODS
;
CARFLG	DB	0	;SET >0 IF CARRIER LOST
;
;EXPERT USER FLAG: >0 MEANS STOP PROMPT MSGS @ ':'
;
EXPERT	DB	0	;NOT EXPERT
;
; 10/17/82 delete "from so-and-so", move to CBBS.ASM
;
BYMSG	DB	CR,LF
	DB	'Char counts:'	;\acter\
NCHRE	DB	'        typed by you, '
NCHRT	DB	'        typed by system.',CR,LF,0
; next thing typed is "bymsg2" from CBBS.ASM
;
NOFMSG	DB	'THERE IS NO FILE: ',0
;
TABCOL	DB	1	;CURR. COL FOR TAB EXPAND
;
COL	DB	1	;CURRENT TTY OUTPUT COLUMN
;
SPEED	DB	'X',CR	;LOG 1ST DIGIT OF BAUD RATE
;
MSGNO	DB	'XXXXX'	;MESSAGE NUMBER..
	DB	CR	;..C/R
;
HILINE	DB	'00',CR ;HIGHEST LINE # ON ENTER
;
PASSWD	DB	'NONE',CR
;
NONE	DB	'NONE',CR ;DUMMY PASSWORD
;
PRINTSW	DB	0	;1 IF LOCAL PRINT
;
INHELP	DB	0	;>0 IF IN "HELP" AND
;			 GETVAR IS TO IGNORE "X"
;
echopas	db	0	;0 = echo input, 1= echo "X" when
;				entering a password.
;
;FOLLOWING FLAG SET =0 WHEN
;SYSTEM OPERATOR PASSWORD ENTERED
;
PASSFLG	DB	1	;0 = PASSWORD ENTERED
;
;FOLLOWING IS A MASK USED IN AN 'ANA' INSTRUCTION.
;THE MASK IS EITHER 0FFH (I.E. RESULTS IN NO CHANGE)
;OR IS A 5FH, WHICH TRANSLATES lower case TO UPPER
;
;THE DEFAULT (was) UPPER CASE BECAUSE OF THE
;#&$#@* HEATH H9 WHICH GARBAGES LOWER CASE.
;(EXCUSE THE EDITORIAL COMMENTARY)
;
CASE	DB	0ffh	;DEFAULT TO lower CASE \was 5FH, upper case\
;
CASEFLG	DB	0	;SET TO 1 IF WE HAVE ASKED
;			;IF LOWER CASE CAN BE HANDLED
;
TWITSW	DB	0	;1 ==> USER IS A TWIT,
;			;CAN'T KILL OR ENTER
;
;WHEN THE PHONE CONNECTION IS LOST AT AN UNEXPECTED
;TIME, THE FOLLOWING SWITCH IS INTERROGATED TO SEE
;IF A DISK UPDATE IS IN PROGRESS (>0) OR NOT (=0).
;IF NOT, WE CAN GO AWAY.  IF SO, WE HAVE TO CONTINUE
;UNTIL THE UPDATE IS DONE.
;
DKUPSW	DB	0
;
;offsets within NEXT file (symbolic to allow changing for
;>99999 callers on CBBS/Chicago
;
nxhmsg	equ	80h		;hi digit, next msg #
nxlmsg	equ	84h		;lo digit, next msg #
nxhclr	equ	87h		;hi digit, caller #
nxlclr	equ	8ch		;lo digit, caller #
nxhnmsg	equ	8eh		;hi digit, # active msgs
nxlnmsg	equ	92h		;lo digit, # active msgs
nxhmmsg	equ	95h		;hi digit, max msgs
nxlmmsg	equ	99h		;lo digit, max msgs
nxhapp	equ	9ch		;hi digit, hi approved msg
nxlapp	equ	0A0h		;lo digit, hi approved msg
;
;SWITCH TO SHOW IF CTL-K (FUNCTION ABORT) IS
;ENABLED (=0) OR NOT (>0)
;
ctlkoff	equ	1		;not allowed. (NCTLK)
ctlkent	equ	2		;to msg entry (ENCOMD)
ctlkrtv	equ	3		;to flagged rtrv (RTVFE)
ctlkfn	equ	4		;to first name q (getfn)
ctlkt1	equ	5		;ask "1st time?" (askt1)
ctlkmod	equ	6		;modem fnc. (mfunct)
;
CTLKSW	DB	ctlkt1	;CTL-K ENABLED, TO 1ST TIME Q.
;
;SWITCH TO SHOW IF CTL-C DISABLED (>0)
;
CTLCSW	DB	0	;ENABLED
;
;MESSAGE TO TYPE WHEN CTL-K ATTEMPTED BUT
;NOT PERMITTED
;
NOCTLK	DB	CR,LF
	DB	'++Can''t Ctl-K now',CR,LF,0
;
;MESSAGES FOR WHICH CASE WE ARE IN
;
LCASEM	DB	'lower/'
;
UCASEM	DB	'upper case mode',CR,LF,0
;
;DEFINE FLAG WHICH WILL PREVENT SYSTEM HANGING UP
;IF THE COMMENT FUNCTION GETS AN ERROR.  SET TO 'B'
;(BUSY) UPON ENTRY TO COMMENT, AND 'N' (NOT BUSY) UPON
;EXIT.  IF THE ROUTINE IS ENTERED AND FOUND BUSY, IT
;IS BYPASSED
;
COMFLG	DB	'N'
;
COMFRM	DB	'FROM: ',CR ;NOTES FILE HDR
;
;
	IF	TTY	;HAVE LOG TTY?
TTYSTP	DW	LOGBUF	;PTR: STORE CHAR FROM KB
TTYLDP	DW	LOGBUF	;PTR: LOAD CHAR TO TTY
	ENDIF
;
;NUMBER OF NULLS TO SEND TO USER
;
NULLS	DB	0
;
;USER-SELECTABLE BACKSPACE CHAR VIA "V" COMMAND
;
BSCHAR	DB	8	;DEFAULT TO ^H
;
;DECIMAL NUMBER STORED HERE (WRITTEN
;TO LOG FILE AS ELAPSED TIME)
;
DECNUM	DB	'000',CR
;
;"NONEFLG" IS >0 IF NO DUPLICATE CHARS
;	>= ' ' AND < '9' ARE TO BE TYPED.
;
NONEFLG	DB	0	;DEFAULT OFF
PREVCHR	DB	0	;PREVIOUS CHAR TYPED
;			 TO CHECK FOR DUPLICATES
;
 if xfer		;_______
;				;
; file transfer stuff		;
;				;
otdf	db	1		;one-time dir flag prompt
userno	db	$-$		;user # to log back to after xfer
xenable	db	0		;enabled (valid password) for xfer?
mroute	db	0		;>0 route funct to mfunct
xpasswd	db	1,0		;password then 0
	ds	20		;	filler for longer password.
xuser	db	0		;current
xminusr	db	0		;min authorized user
xmaxusr	db	0		;max authorized user
xdisk	db	1		;authorized disk (oper dflt = A)
xroflg	db	1		;0 means read only (note rev. logic)
mhelfl	db	diskro,	'MODMHELP   '
;				;
 endif			;_______;
;
;HOLDFLG IS >0 IF OPERATOR HAS REQUESTED "HOLD"
;SO PHONE WON'T HANG UP
;
HOLDFLG	DB	0
;
;FLAG SET NON-ZERO IF OPERATOR "CONT" COMMAND USED -
;	CONTINUES PREVIOUSLY ENTERED MESSAGE
;
MCONT	DB	0
;
THIRTY	DB	'00030'		;USED IN BINARY SUMMARY SEARCH
;
minesw	db	1		;0=already did mine or other summ.
				;1=have to exec "mine".
				;2=executing mine, no msgs so far
				;3=found msg
;
prevhi	db	0,0,0,0,0,0	;prev hi msg #, 0 ending delim
;
; When ^N is pressed, 5 nulls are added.  It sometimes occurs
; inadvertently.  Use NULLSET > 0 to indicate, at "FUNCTION..." prompt
; that nulls have been set.
;
nullset	db	0
flagreq	db	0	;^F = flag prev, ^M = flag some prev, etc.
markcnt	db	0	;# of msgs in marktbl.
chatdoc	db	0	;allow 1-line of "why chat" to be logged
;
;PATCH AREA FOR DEBUGGING
;
	ORG	($+15) AND 0FFF0H ;TO 16 BOUNDARY
PATCH	DB	' <<PATCH AREA>> '
	DB	' <<PATCH AREA>> '
	DB	' <<PATCH AREA>> '
	DB	' <<PATCH AREA>> '
;
;
QFNAME	DB	''', '	;FNAME MUST BE NEXT DS
;
;-------- DB'S ABOVE THIS LINE, DS'S BELOW ---------
;
FNAME	DS	20	;QFNAME MUST PRECEED THIS
LNAME	DS	20	;CALLER LAST NAME
DATE	DS	12	;MM/DD/YY (CR)
MSGTO	DS	30	;WHO IS MESSAGE TO
ANSWER	DS	82	;ANSWER GOES HERE
INBUF	DS	132	;INPUT BUFFER
SAVMSG	DS	5	;SAVE MSG # DURING "GET"
MISSMSG	DS	6	;MSG # MISSED IN SUMMARY
GVREPT	DS	2	;ADDR TO REPEAT TOO LONG INPUT
GVTRUNC	DS	2	;ADDR OF LINE FOR TRUNC PRINT
BUFPTR	DS	2	;FILE READ CHAR POINTER
NUM	DS	2	;POINTER TO # IN CE COMMAND
SCANPTR	DS	2	;POINTER PAST "," IN Q/S SCAN
SCLOG	DS	2	;POINTER FOR SCAN LOGICALS
STRPTR	DS	2	;ADDR OF STRING TO MATCH
SCDELIM	DS	1	;SCAN LOGICAL DELIMITER
SCANTYP	DS	1	;D/F/T/S/=
LENGTH	DS	1	;LENGTH OF INPUT VARIABLE
SUMTYP	DS	1	;SUMMARY: S=REG, Q=QUICK
COMPTYP	DS	1	;IS THIS A "NOT EQUAL" COMPARE?
STRFLG	DS	1	;',' MEANS STRING SEARCH
flagall	ds	1	;^F = flag all, otherwise 0
INFLG	DS	1	;CASE TRANSLATE ON INPUT (0=YES)
BYEFLG	DS	1	;COMMENTS TO WRITE?
T1FLAG	DS	1	;'Y'/'N', FIRST TIME?
RTOGO	DS	1	;# LEFT TO RETRIEVE (+)
SUMCNT	DS	1	;COUNT 50 TO PRINT HEADER
TRIES	DS	1	;SPEED SELECT TRY COUNT
FIRSTCH	DS	1	;FIRST CHAR IN ON A LINE
NPURG	DS	1	;# MSGS PURGED FR. SUMMARY
BLINO	DS	1	;BINARY LINE # IN MSG ENTRY/EDIT
CALLERN	DS	6	;CALLER # SO IT CAN BE LOGGED
highmsg	ds	6	;high message, used to stop "r;+"
highapp	ds	5	;high approved msg if msgapp equ true
marktbl	ds	5*9	;store 9 msg #'s for #n reference
;
	IF	CLOCK
LGINTIM	DS	9	;LOG IN HH:MM:SS,0
	ENDIF
;
LOSECT	DS	1	;FIELDS USED..
MIDSECT	DS	1	;..BY BINARY..
HISECT	DS	1	;..SEARCH FOR..
SRCHLVL	DS	1	;..SUMMARY
;
	DS	100	;STACK SPACE
STACK	EQU	$	;FOR 'LXI SP,STACK'
	ORG	($+255) AND 0FF00H ;TO PAGE BOUNDARY--->;
;							;
;KEEP THE NEXT 3 TOGETHER - LOGBUF MUST BE PAGE ALIGNED,;
;WKBUF SECTOR ALIGNED, AND MSGBUF AT LEAST ALIGNED	;
;ON 128 BYTE BOUNDARY.	 (was 64-byte boundary)		;
;							;
	IF	TTY	;HAVE LOG TTY?			;
LOGBUF	DS	256	;1 PAGE LOG BUFFER FOR TTY	;
	ENDIF						;
;							;
WKBUF	DS	128					;
MSGBF	DS	1+maxl*128 ;MESSAGE INPUT AREA (ALIGNED)	;
;				(was 16*64)
;
;MSGBF IS ALSO USED FOR A DISK BUFFER FOR
;WRITING TEMP FILE DURING KILL OF SUMMARY/MSG.
;
;IT IS ALSO USED TO STORE FLAGGED SUMMARY MESSAGE #'S
;
	ORG	MSGBF+KBUFPG*256 ;SIZE
;
KILLBUF	EQU	$	;KILLED MSG READ HERE
;
;------------------ EQUATES ----------------
;
;CP/M BDOS CALL FUNCTION CODES, REVISED 07/06/81
;
RDCON	EQU	1
WRCON	EQU	2
RDRDR	EQU	3
PUNPUN	EQU	4
LISTOUT	EQU	5
DIRCON	EQU	6
GETIOBY	EQU	7
PUTIOBY	EQU	8
PRINT	EQU	9
RDCONBF	EQU	10	;A
CONSTAT	EQU	11	;B
GETVERS	EQU	12	;C
RESETDK	EQU	13	;D
LGINDK	EQU	14	;E 0=A
OPEN	EQU	15	;F
CLOSE	EQU	16	;10
SRCHF	EQU	17	;11
SRCHN	EQU	18	;12
ERASE	EQU	19	;13
READ	EQU	20	;14
WRITE	EQU	21	;15
MAKE	EQU	22	;16
REN	EQU	23	;17
GETLGIN	EQU	24	;18
INQDISK	EQU	25	;19 0=A
SETDMA	EQU	26	;1A
INQALC	EQU	27	;1B
WRPROT	EQU	28	;1C
GETROV	EQU	29	;1D
SETATTR	EQU	30	;1E
GETPARM	EQU	31	;1F
SGUSER	EQU	32	;20
RDRAND	EQU	33	;21
WRRAND	EQU	34	;22
COMPSZ	EQU	35	;23
SETRAND	EQU	36	;24
BDOS	EQU	5
FCB	EQU	5CH 
FCB2	EQU	6CH
FCBEXT	EQU	FCB+12
FCBS2	EQU	FCB+14
FCBNSEC	EQU	FCB+15
FCBRNO	EQU	FCB+32
                                                                                                                             