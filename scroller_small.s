

SMALL_BUFFER_SIZE:   equ (1+(256/16))
SMALL_SPRITE_SIZE:  equ 128

scroll_text_1_first_sprite: equ 6*8
scroll_text_2_first_sprite: equ SMALL_BUFFER_SIZE+scroll_text_1_first_sprite

            RSRESET
SMALL_HALF:     equ RS              ; 0 or 8 - pixel offset into sprite
        RSSET(SMALL_HALF+1)
SMALL_OFFSET:   equ      RS
            RSSET (SMALL_OFFSET+2)    ; 0 - 7 pixels left before moving to next letter
SMALL_SPRITE_INDEX:   equ      RS
            RSSET (SMALL_SPRITE_INDEX+1)
SMALL_SPEED:   equ      RS
            RSSET (SMALL_SPEED+2)    ; 0 - 7 pixels left before moving to next letter
SMALL_START: equ      RS
            RSSET (SMALL_START+2)     ; start address of the text
SMALL_CURRENT: equ      RS
            RSSET (SMALL_CURRENT+2)     ; current letter to displa
SMALL_Y: equ   RS 
            RSSET (SMALL_Y+1)     ; screen
SMALL_BUFFER:   equ RS
            RSSET (SMALL_BUFFER+SMALL_BUFFER_SIZE)     ; screen
SMALL_FIRST_SPRITE: equ RS
        RSSET(SMALL_FIRST_SPRITE+1)
SMALL_FLAGS:    equ RS
        RSSET(SMALL_FIRST_SPRITE+1)
SMALL_SPRITE_BUFFER:   equ RS
            RSSET (SMALL_SPRITE_BUFFER+SMALL_SPRITE_SIZE)     ; sprite to fill in 
SMALL_SIZE: equ RS


init_scroller:
    ld (ix+SMALL_FLAGS),0       ; 1st char of the two in the sprite
    ld (ix+SMALL_OFFSET) ,0     ; force it to get a new letter
    ld (ix+SMALL_START+0) ,d        ; start address of scroller
    ld (ix+SMALL_START+1) ,e
    ld (ix+SMALL_CURRENT+0) ,d      ; current address of scroller
    ld (ix+SMALL_CURRENT+1) ,e      ; speed too scroll
    ld (ix+SMALL_SPEED) ,b
    ld (ix+SMALL_Y) ,a
    ld (ix+SMALL_FIRST_SPRITE),h
    ld (ix+SMALL_HALF),0
    ld (ix+SMALL_SPRITE_INDEX),c
    call small_clear_sprite_buffer
    call small_clear_sprites
    call small_prepare_buffer
    ret

small_clear_sprite_buffer:
    ld d,ixh
    ld e,ixl
    add de,SMALL_SPRITE_BUFFER
    ld h,d
    ld l,e
    ld (hl),$ff
    inc de
    ld bc , SMALL_SPRITE_SIZE-1
    ldir
    ret

; this fills the SMALL_BUFFER with sprite indicies
small_prepare_buffer:
    ld hl,SMALL_BUFFER
    ld d,ixh
    ld e,ixl
    add hl,de

    ld a, (IX+SMALL_FIRST_SPRITE)
    ld b,SMALL_BUFFER_SIZE
.lp
    ld (hl),a
    inc hl
    inc a
    djnz .lp
    ret


; clear the sprites out as they are empty to start with
small_clear_sprites:
    ld b, SMALL_BUFFER_SIZE
    ld a, (IX+SMALL_FIRST_SPRITE)
    ld l,0
 
    push bc
           ;bit7 - lsb : 5-0 are otherbits shifted down
    ld bc, SPRITE_INDEX_OUT
    rrc a
    out (c),a ; start at pattern a
    pop bc
 .lp:     
    push bc
    ld bc,$005b + (SMALL_SPRITE_SIZE)*256
.lp0:
    out (c),l ;; send 256 bytes to port 0x5b
    djnz .lp0
    pop bc
    djnz .lp

    ret

small_scrollers_init:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld a,32+4         ;y offset
    ld b,2          ; speed
    ld c, SMALL_SPRITES_1
    ld h,scroll_text_1_first_sprite

    ld de,scroll_text_1

    ld ix, scroller1
    call init_scroller




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ld a,32+4+28          ;y offset
    ld b,1          ; speed
    ld c,SMALL_SPRITES_2
    ld h,scroll_text_2_first_sprite

    ld de,scroll_text_2

    ld ix, scroller2
    call init_scroller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ret

small_scrollers_update:

    ld ix, scroller1
    call update_scroller

    ld ix, scroller2
    call update_scroller

    ret




update_scroller:

    ld a, (ix+SMALL_OFFSET)
    sub (ix+SMALL_SPEED)
    ld (ix+SMALL_OFFSET),a
    jp nc,just_draw
    add a,8
    ld (ix+SMALL_OFFSET),a

    ld h,(ix+SMALL_CURRENT+0)
    ld l,(ix+SMALL_CURRENT+1)
    ld a,(hl)
    or a
    jr nz ,.cont

    ld h,(ix+SMALL_START+0)
    ld l,(ix+SMALL_START+1)
    ld a,(hl)
.cont
    inc hl
    ld (ix+SMALL_CURRENT+0),h
    ld (ix+SMALL_CURRENT+1),l

    sub ' '

    ld hl ,lfont_map
    add hl,a

    ld d,(hl)
    ld e,8*8/2
    mul
    ld hl,lfont_tiles
    add hl,de                  ; hl points to the tile

    ld d,ixh
    ld e,ixl
    add de,SMALL_SPRITE_BUFFER         ;de points to spite to fill in

    push de



    ld a,(IX+SMALL_HALF)
    or a
    jr nz,.skip

    push de
    push ix
    ld b, SMALL_BUFFER_SIZE-1
    ld d,(ix+SMALL_BUFFER)
.cpy:
    ld c,(ix+SMALL_BUFFER+1)
    ld (ix+SMALL_BUFFER),c
    inc ix

    djnz .cpy
    ld (ix+SMALL_BUFFER),d
    pop ix
    pop de
.skip:



    ld a,(IX+SMALL_HALF)
    add de,a                    ;which half


    xor 4                       ; nex time round other half
    ld (IX+SMALL_HALF),a


    ld a,8
.letter:
    ldi
    ldi
    ldi
    ldi
    add de,4
    dec a
    jr nz,.letter

; lets upload the sprite , so whic number?

    pop hl
 
    ld a,(ix+SMALL_BUFFER+ SMALL_BUFFER_SIZE-1)
    ld bc, SPRITE_INDEX_OUT
    rrc a
    out (c),a ; start at pattern a
    ld bc,$005b + (SMALL_SPRITE_SIZE/2)*256
    otir 



just_draw:

    ld bc, SPRITE_INDEX_OUT
    ld a,(ix+SMALL_SPRITE_INDEX)
    out (c),a ; start at pattern 0

    ld b,SMALL_BUFFER_SIZE
    ld l, (ix+SMALL_Y)

    ld de,32

    ld a, (IX+SMALL_HALF)
    add a,a
    add a,(ix+SMALL_OFFSET)
    add a,e
    sub 16
    ld e,a
.stuff:
    push de
    ld h, (ix+SMALL_BUFFER)
    call small_draw_me
    pop de

    inc ix
    add de,16

    djnz .stuff
    ret


 small_draw_me:

    push bc
    ld c,SPRITE_ATTRIBUTE_OUT
    out (c),e  ; x:lo
    out (c),l ; y

    ld a,1      ; bit 0 msb:x
    and d     
 ;   or $10  
    out (c),a   ; palette offset = 0

    ld a,h      ;sprite index
 ;   or a
 ;   jr z,.no

;    add a,BOTTOM_SPRITES_START

    srl a
    set 7,a     ; visible
.no:
    set 6,a     ; extended data
.hidden
    out (c),a
    ld a,$80  ; visible
    jr nc,.no_n6 ; carry from the srl a
    set 6,a
.no_n6:
    out (c),a

    pop bc
    ret

scroller1: ds SMALL_SIZE
scroller2: ds SMALL_SIZE

lfont_map: incbin "gfx/lfont.nxm"
lfont_map_end:

;    seg GFX_SEG
lfont_tiles: incbin "gfx/lfont.nxt"
lfont_tiles_end:
lfont_tiles_size: equ lfont_tiles_end-lfont_tiles
;    seg CODE_SEG


scroll_text_1: db "                           TANIS, THE FAMOUS GRAFIXX-MAN, IS A NEW MEMBER OF TCB.  HE MADE ALL THE GRAPHICS IN THIS SCREEN PLUS LOTSA LOGOS IN THE MAIN MENU.  WE AGREE THAT THIS 'ONE-BIT-PLANE-MANIA' DOESN'T LOOK VERY GOOD, BUT IT HAD TO BE DONE BY SOMEONE........   BAD LUCK FOR TANIS THAT WE WON'T MAKE MORE DEMOS, THOUGH....       9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9  ..................                 LET'S WRAP (WE SPELLED IT CORRECTLY!!!).......   ",0
scroll_text_2: db "                                                           ONCE UPON A TIME, WHEN THE JUNK DEMO WAS ALMOST FINISHED - WHEN THE BEST DEMO ON THE ST-MARKET WAS 'LCD' BY TEX, WE VISITED IQ2-CREW (AMIGA-FREAKS). THEY SHOWED US A COUPLE OF DEMOS AND ONE OF THEM WAS THE TECHTECH-DEMO BY SODAN AND MAGICIAN 42. KRILLE AND PUTTE LAUGHED AT US AND SAID THAT IT WAS TOTALLY IMPOSSIBLE TO MAKE ON AN ST. WE STUDIED IT FOR HALF AN HOUR AND SAID: -OF COURSE IT'S POSSIBLE.   WHEN WE WERE BACK HOME (WHEN NO AMIGA-OWNER WAS LISTENING), WE CONCLUDED THAT THERE WAS SIMPLY TOO MUCH MOVEMENT FOR AN ST.        NOW, WE HAVE CONVERTED IT ANYWAY. THE AMIGA VERSION HAD SOME UGLY LINES WHIZZING AROUND, BUT WE HAVE 3 VOICE REAL DIGISOUND AND SOME UGLY SPRITES. BESIDES, WE HAVE SOME TERRIBLE RASTERS.......            WE AGREE THAT THERE ARE BETTER AMIGA-DEMOS NOW, AND PERHAPS WE WILL CONVERT SOME MORE IN THE FUTURE.......     LET'S WRAZZZZZZZ................",0

