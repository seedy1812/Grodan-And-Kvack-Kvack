prepare_bg2_layer2:

	nextreg LAYER_2_ACTIVE_BANK,BANK(BG2_NXI)/2

	nextreg MMU_Slot7,BANK(BG2_NXI)

    ld bc, LAYER2_OUT
	ld a,    %0010
	out (c),a

	nextreg PAL_CTRL,%10010001

	nextreg PAL_INDEX,0
	nextreg PAL_VALUE_9BIT,%01010100
	nextreg PAL_VALUE_9BIT,1
	nextreg PAL_INDEX,1
	nextreg PAL_VALUE_8BIT,$e3
	ret

_bg2_Y:		dw 0
_bg2_hY:	dw 1
_bg2_X:		dw 0
_bg2_gox:	dw 0

update_bg2:
;w1.c:111: if(bg2_Y<-400)
	ld	hl,_bg2_Y
	ld	a, (hl)
	sub	$70
	inc	hl
	ld	a, (hl)
	rla
	ccf
	rra
	sbc	$7e
	jr	NC,.l_bg2_00102
;w1.c:113: bg2_hY=2;
	ld	hl,_bg2_hY
	ld	(hl),$02
	xor	a
	inc	hl
	ld	(hl), a
;w1.c:114: bg2_gox=16;
	ld	hl,_bg2_gox
	ld	(hl),$10
	xor	a
	inc	hl
	ld	(hl), a
.l_bg2_00102:
;w1.c:117: if(bg2_Y>0)
	xor	a
	ld	hl,_bg2_Y
	cp	a, (hl)
	inc	hl
	sbc	a,(hl)
	jp	PO, .l_bg2_00131
	xor	$80
.l_bg2_00131:
	jp	P, .l_bg2_00104
;w1.c:119: bg2_hY=-2;
	ld	hl,$fffe
	ld	(_bg2_hY),hl
;w1.c:120: bg2_gox=-16;
	ld	hl,$fff0
	ld	(_bg2_gox),hl
.l_bg2_00104:
;w1.c:123: bg2_X+=bg2_gox;
	ld	hl,(_bg2_X)
	ld	bc,(_bg2_gox)
	add	hl,bc
	ld	(_bg2_X),hl
;w1.c:125: if(bg2_X<-710)
	ld	hl,_bg2_X
	ld	a, (hl)
	sub	$3a
	inc	hl
	ld	a, (hl)
	rla
	ccf
	rra
	sbc	a,$7d
	jr	NC,.l_bg2_00106
;w1.c:127: bg2_X=-710;
	dec	hl
	ld	(hl),$3a
	inc	hl
	ld	(hl),$fd
.l_bg2_00106:
;w1.c:130: if(bg2_X>0)
	xor	a
	ld	hl,_bg2_X
	cp	(hl)
	inc	hl
	sbc	a,(hl)
	jp	PO, .l_bg2_00132
	xor $80
.l_bg2_00132:
	jp	P, .l_bg2_00108
;w1.c:132: bg2_X=0;
	ld	hl,$0000
	ld	(_bg2_X),hl
.l_bg2_00108:
;w1.c:134: bg2_Y+=bg2_hY;
	ld	hl,(_bg2_Y)
	ld	de,(_bg2_hY)
	add	hl,de
	ld	(_bg2_Y),hl
;w1.c:135: }

	ld a,(_bg2_X)
	nextreg LAYER2_SCROLL_X_LSB,a

	ld a,(_bg2_Y)
	nextreg LAYER2_SCROLL_Y,a
	ret

