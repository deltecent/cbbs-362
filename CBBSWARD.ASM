;cbbsward.asm	custom stuff for my own system
;09/26/82 15:48:21
;
; LOG IN DATE/TIME ON VIO
;
; blank vio status line
;
wcltime	lxi	h,viostat
	push	h
	lxi	d,viostat+1
	mvi	b,79
	mvi	m,' '
;
; move date/time to status line
;
	call	move
	lxi	h,answer	;move date/time
	pop	d		; to 
	mvi	b,17
	call	move
	xchg
	shld	viosptr
	xra	a
	sta	dkupsw		;for wards
	ret
;
;	SEND STRING (hl) TO STATUS LINE
;	Either 00 or CR terminated.
;
viotype	xchg			;input to de
	lhld	viosptr
viotm	ldax	d
	ora	a		;exit on zero
	jz	viotz
	cpi	cr		;	or
	jz	viotz		;	c/r
	mov	m,a
	inx	d
	inr	l
	jmp	viotm
;
; end
;
viotz	mvi	m,','
	inr	l
	shld	viosptr
	xchg
	ret
;
viosptr	dw	viostat
;
	link	cbbswork
                                           