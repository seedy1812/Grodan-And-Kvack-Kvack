prepare_bg1_ula:
    ld a, MMU_Slot7
    call ReadNextReg
    push af

	ld a,Bank(BG1_SCR);

    Nextreg MMU_Slot7,Bank(BG1_SCR)

	ld hl, $e000|(BG1_SCR & $1fff)
	ld de,$4000
	ld bc,192*32
	ldir
	push de
	pop hl
	inc de
	ld (hl),0
	ld bc,24*32-1
	ldir

    pop af
    Nextreg MMU_Slot7,a


	nextreg PAL_CTRL,%10000001

	nextreg PAL_INDEX,0+0
	nextreg PAL_VALUE_8BIT,%10101110
	nextreg PAL_INDEX,1+0
	nextreg PAL_VALUE_8BIT,$e3



	ret
	
_bg1_Y: db 0
_bg1_X: db 0
_bg1_hY: db 0
_bg1_gox: db 0

update_bg1:
;w1.c:111: if(bg2_Y == 0)
	ld	a,(_bg1_Y)
	or	a
	jr	NZ,.l_bg2_00102
;w1.c:113: bg2_hY=2;
	ld	hl,_bg1_hY
	ld	(hl),$02
;w1.c:114: bg2_gox=16;
	ld	hl,_bg1_gox
	ld	(hl),$10
.l_bg2_00102:
;w1.c:117: if(bg2_Y>=192)
	ld	a,(_bg1_Y)
	sub	$c0
	jr	C,.l_bg2_00104
;w1.c:119: bg2_hY=-2;
	ld	hl,_bg1_hY
	ld	(hl),$fe
;w1.c:120: bg2_gox=-16;
	ld	hl,_bg1_gox
	ld	(hl),$f0
.l_bg2_00104:
;w1.c:123: bg2_X+=bg2_gox;
	ld	a,(_bg1_X)
	ld	hl,_bg1_gox
	add	a, (hl)
	ld	(_bg1_X),a
;w1.c:125: bg2_Y+=bg2_hY;
	ld	a,(_bg1_Y)
	ld	hl,_bg1_hY
	add	a, (hl)
	ld	(_bg1_Y),a
;w1.c:126: }
	nextreg ULA_SCROLL_Y,a

	ld a,(_bg1_X)
	nextreg ULA_SCROLL_X,a
	ret

    seg ULA_SEG
BG1_SCR: incbin "gfx/Grodan_green_256.scr"
    seg CODE_SEG

