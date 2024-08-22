;MAP_ADDR:   equ $4000
;TILE_ADDR:  equ $4600

memcpy3 macro 
        ld hl,\0
        ld de,\2
        ld bc,\1
        ldir
        endm

memcpy2 macro 
        ld hl,\0
        ld bc,\1
        ldir
        endm

a_map_s macro 
\0_map: include "gfx/\0.txm"
\0_map_length: equ *-\0_map
\0_pal: incbin "gfx/\0.nxp"
\0_pal_length: equ *-\0_pal
\0_tiles: incbin "gfx/\0.nxi"
\0_tiles_length: equ *-\0_tiles
    endm

a_map macro 
\0_map: incbin "gfx/\0.nxm"
\0_map_length: equ *-\0_map
\0_pal: incbin "gfx/\0.nxp"
\0_pal_length: equ *-\0_pal
\0_tiles: incbin "gfx/\0.nxt"
\0_tiles_length: equ *-\0_tiles
    endm

set_layer3pal:
        nextreg PAL_INDEX ,a
        ld b,16
.loop:
        ld a,(hl)
        inc hl
        Nextreg PAL_VALUE_8BIT,a
        djnz .loop
        ret

black_pal: ds 16
alt_land_pal: ds 2

saved_MMU6 ds 2 

swap_out_MMU_67

if NO_PAGING = 0

        ld a,MMU_6
        call ReadNextReg
        ld (saved_MMU6+0),a
       

        ld a,MMU_7
        call ReadNextReg
        ld (saved_MMU6+1),a

        ld a,SEG_GFX
        nextreg MMU_6,a
        inc a
        nextreg MMU_7,a
endif
        ret

swap_back_MMU_67
if NO_PAGING = 0
        ld a,(saved_MMU6+1)
        nextreg MMU_7,a

        ld (saved_MMU6+0),a
        nextreg MMU_6,a
endif
        ret




backdrop_init:

	nextreg LAYER3_TRANS_INDEX,15 ; set transparent colour for tilemap


        call swap_out_MMU_67

        ; layer 3 pal 1 to edit
        nextreg PAL_CTRL,%00110001
        ld a,0
        ld hl,bg_pal
        call set_layer3pal

        ld a,16
        ld hl,checker21_pal
        call set_layer3pal

        ld hl,checker21_pal
        ld b,(hl)
        inc hl
        ld c,(hl)

        ld hl,alt_land_pal+1
        ld (hl),b
        dec hl
        ld (hl),c

        ld a,32
        ld hl,alt_land_pal
        call set_layer3pal



        ld a,48
        ld hl,fonts2ax_pal
        call set_layer3pal

        ld a,64
        ld hl,black_pal
        call set_layer3pal

;        cls top 4 lines
        ld hl,MAP_ADDR
        ld de,MAP_ADDR+1
        ld (hl),0
        ld bc,40*4-1
        ldir

; TLB logo
        memcpy2 bg_map,bg_map_length
; landscape
        memcpy2 checker21_map,checker21_map_length

        ld (scroller_map),de
        ld h,d
        ld l,e
        inc de
        ld (hl),3
        ld bc,40*5
        ldir

        add de,255
        ld e,0
        ld (addr_bg),de
        memcpy2 bg_tiles,bg_tiles_length
        add de,255
        ld e,0
        ld (addr_checkers),de
        ld a,d
        ld (copper_tweak1+1),a
        memcpy2 checker21_tiles,checker21_tiles_length
        add de,255
        ld e,0
        ld a,d
        ld (copper_tweak2+1),a
        ld (addr_font),de
        memcpy2 fonts2ax_tiles,fonts2ax_tiles_length

        ld a,(addr_bg+1)
        ld (copper_tweak0+1),a
        nextreg LAYER3_TILE_HI,a


        ld a,(addr_checkers+1)
        ld (copper_tweak1+1),a

        nextreg PAL_CTRL,%10110001

        nextreg LAYER_3_CTRL,%10100101

        nextreg TILE_DEF_ATTR,%000000000
        nextreg LAYER3_MAP_HI,HI(MAP_ADDR)

        call land_fill_y


        call swap_back_MMU_67


        ret

Y_LAND_POS equ 80

land_fill_y:
        ld a,(land_frame)
        and 7
        jr nz ,.ok
        inc a
.ok:
        ld d,a
        ld e,6
        mul
        add de, LandY0  ; de ,scanlimes

        ld hl,copper_landy1 +1

        ld b,6
.loop:
        ld a,(de)
        inc de
        add Y_LAND_POS
        ld (hl),a
        add hl,copper_landy2-copper_landy1
        djnz .loop


        ld b,+(1*16)
        ld c,+(2*16)
        ld a,(land_frame)
        and 8
        jr z,.no_swap:
        ld a,b
        ld b,c
        ld c,a
.no_swap:
        ld ix,Cland0+1

        ld (ix+0),b
        ld (ix+4),c
        ld (ix+8),b
        ld (ix+12),c
        ld (ix+16),b
        ld (ix+20),c
        ld (ix+24),b




        ret


t_copper_start:
        COPPER_MOVE(PAL_CTRL,%10110001)

        COPPER_WAIT(0,0)
        COPPER_MOVE(TILE_DEF_ATTR,+(0*16))
        COPPER_MOVE(PAL_INDEX,0)
copper_tweak0:
        COPPER_MOVE(LAYER3_TILE_HI,0)
 

        COPPER_WAIT(80,0)
copper_tweak1:
        COPPER_MOVE(LAYER3_TILE_HI,0)
Cland0: COPPER_MOVE(TILE_DEF_ATTR,+(1*16))

copper_landy1
        COPPER_WAIT(80,0)
Cland1: COPPER_MOVE(TILE_DEF_ATTR,+(2*16))

copper_landy2:
        COPPER_WAIT(80,0)
.Cand2: COPPER_MOVE(TILE_DEF_ATTR,+(1*16))

        COPPER_WAIT(80,0)
Cland3: COPPER_MOVE(TILE_DEF_ATTR,+(2*16))

        COPPER_WAIT(80,0)
Cland4: COPPER_MOVE(TILE_DEF_ATTR,+(1*16))

        COPPER_WAIT(80,0)
Cland5: COPPER_MOVE(TILE_DEF_ATTR,+(2*16))

        COPPER_WAIT(80,0)
Cland6: COPPER_MOVE(TILE_DEF_ATTR,+(1*16))
 
        COPPER_WAIT(144,0)
 copper_tweak2:
        COPPER_MOVE(LAYER3_TILE_HI,0)
        COPPER_MOVE(TILE_DEF_ATTR,+(3*16))
        COPPER_MOVE(PAL_INDEX,32+16)
        COPPER_SET_COLOR(0)

        COPPER_MOVE(PAL_INDEX,33+16)

.l0     COPPER_SET_COLOR(COL_0)

.l1     COPPER_WAIT(144+1,0)
        COPPER_SET_COLOR(COL_1)

.l2     COPPER_WAIT(144+5,0)
        COPPER_SET_COLOR(COL_2)

.l3     COPPER_WAIT(144+7,0)
        COPPER_SET_COLOR(COL_3)

.l4     COPPER_WAIT(144+9,0)
        COPPER_SET_COLOR(COL_4)

.l5     COPPER_WAIT(144+11,0)
        COPPER_SET_COLOR(COL_5)

.l6     COPPER_WAIT(144+13,0)
        COPPER_SET_COLOR(COL_6)

.l7     COPPER_WAIT(144+15,0)
        COPPER_SET_COLOR(COL_7)

.l8     COPPER_WAIT(144+17,0)
        COPPER_SET_COLOR(COL_8)

.l9     COPPER_WAIT(144+19,0)
        COPPER_SET_COLOR(COL_9)

.la     COPPER_WAIT(144+21,0)
        COPPER_SET_COLOR(COL_a)

.lb     COPPER_WAIT(144+23,0)
        COPPER_SET_COLOR(COL_b)

.lc     COPPER_WAIT(144+25,0)
        COPPER_SET_COLOR(COL_c)

.ld     COPPER_WAIT(144+27,0)
        COPPER_SET_COLOR(COL_d)

.le     COPPER_WAIT(144+31,0)
        COPPER_SET_COLOR(COL_e)

.lf     COPPER_WAIT(144+35,0)
        COPPER_SET_COLOR(COL_f)

        COPPER_WAIT(184,0)

        COPPER_MOVE(TILE_DEF_ATTR,+(4*16))
        COPPER_HALT()
t_copper_end:


backdrop_vbl:
        ld a,(land_frame)
        inc a
        and 15
        jr nz,.miss_0
        inc a
.miss_0:
        ld (land_frame),a

        call land_fill_y


        ld      hl,t_copper_start
        ld      bc,+(t_copper_end-t_copper_start)
        call    do_copper
        ret

addr_bg: ds 2 
addr_checkers: ds 2
addr_font ds 2
land_frame: db 1


if NO_PAGING = 0
        SEG GFX_SEG
endif
GFX_EQU_ADDR_START:
a_map bg
a_map fonts2ax
a_map checker21
GFX_EQU_ADDR_END:

        SEG CODE_SEG

RGB_M0 macro
    \3: \4    ((\0>>5)<<5)+((\1>>5)<<2)+ (\2>>6)
    endm

RGB_M0 36,0,0,COL_0,EQU 
RGB_M0 72,0,0,COL_1,EQU 
RGB_M0 109,0,0,COL_2,EQU 
RGB_M0 145,0,0,COL_3,EQU 
RGB_M0 182,0,0,COL_4,EQU 
RGB_M0 218,0,0,COL_5,EQU 
RGB_M0 255,0,0,COL_6,EQU 
RGB_M0 255,36,0,COL_7,EQU 
RGB_M0 255,72,0,COL_8,EQU 
RGB_M0 255,109,0,COL_9,EQU 
RGB_M0 255,145,0,COL_a,EQU 
RGB_M0 255,182,0,COL_b,EQU 
RGB_M0 255,218,0,COL_c,EQU 
RGB_M0 255,255,0,COL_d,EQU 
RGB_M0 255,255,85,COL_e,EQU 
RGB_M0 255,255,170,COL_f,EQU 

LAND macro
LandY\6: db \0-(\6*64),\1-(\6*64),\2-(\6*64),\3-(\6*64),\4-(\6*64),\5-(\6*64)
        endm

LAND  2,   4, 10, 18, 14,  0    ,0
LAND 66,  68, 71, 75, 85,101    ,1
LAND 129,132,134,141,150,169    ,2
LAND 194,197,200,205,216,236    ,3
LAND 258,260,264,270,282,303    ,4
LAND 322,325,329,335,348,371    ,5
LAND 386,389,393,400,414,439    ,6
LAND 450,453,458,465,480,506    ,7


