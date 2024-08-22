// 1,536

tcb_init
   	ld hl,sprites
    ld bc, sprites_size
.again:
    ld a,(hl)
    ld d,a
    add a,a
    add a,d
    ld (hl),a
    inc hl
    dec bc
    ld a,b
    or c
    jr nz,.again

   	ld hl,sprites
    ld bc, SPRITE_INDEX_OUT

    ld a, 8*15
    rrc a
    out (c),a ; start at pattern a

    ld bc,$005b + (16*16)*256
	ld a, HI(sprites_size)
.next:

    otir ;; send 256 bytes to port 0x5b
	dec a
	jr nz,.next

    ; sprites first palette
	nextreg PAL_CTRL,%00100001

    nextreg PAL_VALUE_8BIT,16+1
   	nextreg PAL_VALUE_8BIT,%0011011

	ret

SPR_T equ (8*15)
SPR_H equ 1+SPR_T
SPR_E equ 1+SPR_H
SPR_C equ 1+SPR_E
SPR_A equ 1+SPR_C
SPR_R equ 1+SPR_A
SPR_B equ 1+SPR_R
SPR_S equ 1+SPR_B

tcb_sprs:   db    SPR_T,0,0
            db    SPR_H,0,0
            db    SPR_E,0,0
            db    SPR_C,0,0
            db    SPR_A,0,0
            db    SPR_R,0,0
            db    SPR_E,0,0
            db    SPR_B,0,0
            db    SPR_E,0,0
            db    SPR_A,0,0
            db    SPR_R,0,0
            db    SPR_S,0,0
tcb_sprs_num: equ +(*-tcb_sprs)/3

tcb_sp_xy    ds 2*tcb_sprs_num      ;byte x,y


tcb_swingx_addition: equ 0.02f
tcb_swingy_addition: equ 0.03f
tcb_swing_addition: equ 0.1f



tcb_ychange: dw 0
tcb_addy: dw tcb_swing_addition
tcb_sinx: dw 0
tcb_siny: dw 0
tcb_swingx: dw 0
tcb_swingy: dw 0
tcb_temp_swingx: dw 0
tcb_temp_swingy: dw 0

tcb_spx equ  304
tcb_spy equ 100



tcb_update:
;    if(tcb_ychange>50)
;    {
        ld hl,-tcb_swing_addition
        ld (tcb_addy),hl
;    }

;    if(tcb_ychange<-50)
;    {
        ld hl,tcb_swing_addition
        ld (tcb_addy),hl
;    }
;    tcb_ychange+=tcb_addy;

;    tcb_swingx += 0.02;
    ld hl,(tcb_swingx)
    add hl,tcb_swingx_addition
    ld (tcb_swingx),hl


;    tcb_swingy += 0.03;
    ld hl,(tcb_swingy)
    add hl,tcb_swingy_addition
    ld (tcb_swingy),hl


; 	tcb_siny=tcb_ychange*Math.sin(tcb_swingy);

    ld hl ,(tcb_siny)
    call get_sin_hl_to_de

    ld hl,(tcb_ychange)
    call mul_hl_de    
    ld (tcb_siny),hl

;tcb_temp_swingx = tcb_swingx

    ld hl,(tcb_swingx)
    ld (tcb_temp_swingx),hl

;tcb_temp_swingy = tcb_swingy

    ld hl,(tcb_swingy)
    ld (tcb_temp_swingy),hl

    ld ix ,tcb_sprs
    ld b, tcb_sprs_num


.lp:
    push bc

;    for(i = 0;<12;i++)
;    {
;        x = spx+290*Math.cos(temp_swingx);

        ld HL,(tcb_temp_swingx)
        call get_cos_hl_to_de

        ld hl,+(256*145);_290_00
        call mul_hl_de    

        ld de,(tcb_spx)
        add hl,de
        ld (ix+1),h             ; x = (ix+1) , y  = (ix+2)

;        y = tcb_spy+tcb_ychange*Math.sin(temp_swingy)+tcb_siny;

    ;   temp_swingx =  tcb_swingx += tcb_swingx_addition;
        ld hl,(tcb_temp_swingx)
        ld de,(tcb_swingx_addition)
        add hl,de
        ld (tcb_temp_swingx),hl
        
    ;    temp_swingy =  tcb_swingy += tcb_swingy_addition;
        ld hl,(tcb_temp_swingy)
        ld de,(tcb_swingy_addition)
        add hl,de
        ld (tcb_temp_swingy),hl

        inc ix
        inc ix
        inc ix

        pop bc
        djnz .lp


;    my_break
    ld a,TCB_SPRITES
    ld bc, SPRITE_INDEX_OUT
;    rrc a
    out (c),a ; start at pattern a


    ld HL,tcb_sprs
    ld b, tcb_sprs_num
    ld de,$0060
.dloop:
    ld a,(hl)           ; spr
    inc hl
;    ld d,(hl)           ; x
    inc hl
;    ld e,(hl)           ; y 
    inc hl

    push de
    call tcb_draw_me1
    pop de
    add de,$1200
    djnz .dloop

;    my_break

	ret


; all visible so no need to test
tcb_draw_me1:

    push bc

    ld b,a

    ld c,SPRITE_ATTRIBUTE_OUT

    ld a,d
    add a,32
    out (c),a  ; x:lo               ; attr 0

    out (c),e ; y                   ; attr 1

    ld a,0
    adc a,a     ; palette offset = 0
    or $10
    out (c),a   ; bit 0 msb:x       ; attr 2

    ld a,b      ;sprite index
    srl a
    set 7,a     ; visible
    set 6,a     ; extended data
    out (c),a                       ; attr 3
    ld a,$80
    jr nc,.no_n6
    set 6,a
.no_n6:
    out (c),a                       ; attr

    pop bc
    ret


get_cos_hl_to_de
    add hl,512/4
get_sin_hl_to_de
    ld a,h
    and 1   ; sine table of 512 entries 0 -> 1ff
    ld h,a
    add hl,hl
    add hl,sine_table

;    ld a,bank(sine_table)
;    nextreg MMU_7,a

    ld e,(hl)
    inc hl
    ld d,(hl)
    ret

    // not signed
mul_hl_de:       ; (uint16)HL = (uint16)HL x (uint16)DE
    ld      c,e
    ; HxD xh*yh is not relevant for 16b result at all
    ld      e,l
    mul             ; LxD xl*yh
    ld      a,e     ; part of r:8:15
    ld      e,c
    ld      d,h
    mul             ; HxC xh*yl
    add     a,e     ; second part of r:8:15
    ld      e,c
    ld      d,l
    mul             ; LxC xl*yl (E = r:0:7)
    add     a,d     ; third/last part of r:8:15
    ; result in AE (16 lower bits), put it to HL
    ld      h,a
    ld      l,e
    ret             ; =4+4+8+4+4+4+8+4+4+4+8+4+4+4+10 = 78T


    

sprites: incbin "gfx/sprite.nxt"
sprites_size: equ *-sprites



