
BSCROLL_FIRST_SPRITE:  equ  34

bottom_scroller_init:

    ld ix,bottom_sprites
    ld (ix+BSCROLL_X+0),0             ;   16 bit 256
    ld (ix+BSCROLL_X+1),0

    ld (ix+BSCROLL_TOP),0
    ld (ix+BSCROLL_MID),0
    ld (ix+BSCROLL_BOTTOM),0

    ld hl,bottom_sprites
    ld de,bottom_sprites+BSCROLL_SIZE
    ld bc,NUM_BOTTOM_SPRITES *(BSCROLL_SIZE-1)-1
    ldir

    ld a ,BSCROLL_FIRST_SPRITE
    ld b, BSCROLL_SIZE-1
    ld ix,bottom_sprites
    ld de,BSCROLL_SIZE
.fill_sprite_numbers:
    ld (ix+BSCROLL_TOP),a
    inc a
    ld (ix+BSCROLL_MID),a
    inc a
    ld (ix+BSCROLL_BOTTOM),a
    inc a

    add ix,de
    djnz .fill_sprite_numbers

    ld hl,scrolltext
    ld (scroller_ptr),hl
 
    ret

bottom_sprites_go:
    call bottom_clear_sprites
    ld hl,bottom_scroller_done
    dec (hl)
    ret


scroller_get_letter:

    ld hl,bottom_sprites+BSCROLL_SIZE*(NUM_BOTTOM_SPRITES-1)
    ld de,temp_bottom_sprites
    ld bc ,BSCROLL_SIZE
    ldir

    ld de,bottom_sprites+BSCROLL_SIZE*(NUM_BOTTOM_SPRITES)-1
    ld hl,bottom_sprites+BSCROLL_SIZE*(NUM_BOTTOM_SPRITES-1)-1
    ld bc,BSCROLL_SIZE*(NUM_BOTTOM_SPRITES-1)
    lddr

    ld hl,temp_bottom_sprites
    ld de,bottom_sprites
    ld bc ,BSCROLL_SIZE
    ldir


    ld hl,(scroller_ptr)
    ld a,(hl)
    inc hl
    or a
    jr nz,.no_wrap
    ld hl,scrolltext
    ld a,(hl)
    inc hl
.no_wrap:
    ld (scroller_ptr),hl 
    call get_letter
    ret

get_letter:
 ;   ld a,(hl)
    sub ' '

    ld hl,bsfont_2_map
    add hl,a
    add hl,a
    add hl,a

; page in the sprites
    ld a,MMU_Slot6
    call ReadNextReg
    push af
    nextreg MMU_Slot6 , Bank(bsfont_2_tiles)+0

    ld a,MMU_Slot7
    call ReadNextReg
    push af
    nextreg MMU_Slot7 , Bank(bsfont_2_tiles)+1

    ld ix,bottom_sprites
    ld (ix+BSCROLL_X+0),0             ;   16 bit 256
    ld (ix+BSCROLL_X+1),1

    ld a, (hl)
    inc hl
    ld b,(ix+BSCROLL_TOP)
    call scroll_copy_sprite

    ld a, (hl)
    inc hl
    ld b,(ix+BSCROLL_MID)
    call scroll_copy_sprite

    ld a, (hl)
    ld b,(ix+BSCROLL_BOTTOM)
    call scroll_copy_sprite
    
    pop af
    nextreg MMU_Slot7 ,a
    pop af
    nextreg MMU_Slot6 ,a

    ret


scroll_copy_sprite: 
    push hl
    ld d,128    ; size in bytes of a 16 bit sprite
    ld e,a
    // point to the sprite image in ram
    ld hl,$c000
    mul 
    add hl,de

    ld a,b
    rrc a             ;bit7 - lsb : 5-0 are otherbits shifted down
    ld bc, SPRITE_INDEX_OUT
    out (c),a ; start at pattern a

    ld bc,$005b + (16*16/2)*256
    otir ;; send 256 bytes to port 0x5b
    pop hl
    ret


bottom_clear_sprites
    ld a,BSCROLL_FIRST_SPRITE
    rrc a             ;bit7 - lsb : 5-0 are otherbits shifted down
    ld bc, SPRITE_INDEX_OUT
    out (c),a ; start at pattern a

    ld b, 3*NUM_BOTTOM_SPRITES  
.outer:
    push af
    push bc

    ld a,0
    ld bc,$005b + (16*16/2)*256
.lp0
    out (c),a ;; send 256 bytes to port 0x5b
    djnz .lp0

    pop bc
    pop af
    dec a
    djnz .outer
    ret


bottom_scroller_update:

    ld a,(bottom_scroller_done)
    or a
    ret z


    ld ix,bottom_sprites
    ld a , 256-96
    cp (ix+BSCROLL_X+0)     ; if we have not moved 96 ? pixel then just show sprites 
    jr nz,.just_show

    call scroller_get_letter
.just_show:
;    ld a,SMALL_SPRITES_1
;    nextreg SPRITE_NUMBER, a

    ld a,SMALL_SPRITES_1
    ld bc, SPRITE_INDEX_OUT
    out (c),a

   
    ld a, NUM_BOTTOM_SPRITES
.loop:
    push af

    ld l,(ix+BSCROLL_X+0)             ;   16 bit 256
    ld h,(ix+BSCROLL_X+1)
    add hl,-8
    ld (ix+BSCROLL_X+0),l             ;   16 bit 256
    ld (ix+BSCROLL_X+1),h


    ld d,h
    ld e,l
    add de,32
 
    ld l ,192-4-64
    ld h,(ix+BSCROLL_TOP+0)
    call draw_me_8_2

    ld l, 192-4-64+32
    ld h,(ix+BSCROLL_MID+0)
    call draw_me_8_2

    ld l, 192-4-64+32*2
    ld h,(ix+BSCROLL_BOTTOM+0)
    call draw_me_8_2


    ld de,BSCROLL_SIZE
    add ix, de
    pop af
    dec a
    jr nz,.loop

    ret


;     de = 16 bit x ...

;     h = spr index
;     l = y

draw_me_8_2:

    push af
    push bc

    ld c,SPRITE_ATTRIBUTE_OUT

    out (c),e  ; x:lo

    out (c),l ; y

    ld a,1      ; bit 0 msb:x
    and d     
    or $10  
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
    ld a,$80 | %11000 | %010  ; visible | xScale *8 | yScale *2
    jr nc,.no_n6 ; carry from the srl a
    set 6,a
.no_n6:
    out (c),a

    pop bc
    pop af
    ret

            RSRESET
BSCROLL_X:   equ      RS
            RSSET (BSCROLL_X+2)     ; -width to +256
BSCROLL_TOP: equ      RS
            RSSET (BSCROLL_TOP+1)     ; top sprite index
BSCROLL_MID: equ      RS
            RSSET (BSCROLL_MID+1)     ; top sprite index
BSCROLL_BOTTOM: equ   RS 
            RSSET (BSCROLL_BOTTOM+1)     ; bottom sprite index
BSCROLL_SIZE:   equ   RS 

NUM_BOTTOM_SPRITES: equ 4
bottom_sprites: ds NUM_BOTTOM_SPRITES *BSCROLL_SIZE
bottom_sprites_size: equ *-bottom_sprites

temp_bottom_sprites: ds BSCROLL_SIZE

bottom_scroller_done: db 0

letter:         ds 1
letter_top:     ds 2

scroll_shift:   ds 1  ; how many pixels left
scroller_ptr:   ds 2

scroller_map:   ds 2
scrolltext:     db "      A HAPPY HI TO EVERYBODY ON THE GLOBE WE LOVINGLY CALL EARTH, AND WELCOME TO THE BEATNIC DEMO SCREEN. ALL CODE BY MANIKIN WITH SOME ASSISTANCE FROM CHRIS JUNGEN, GRAPHICS BY SPAZ, MUSIC BY MAD MAX, SCROLL TEXT BY CRONOS. THIS SCREEN IS DEDICATED TO HE WHO THINKS HE IS THE BEST DEMO PROGRAMMER AROUND, NIC OF THE CAREBEARS. THIS DEMO HAS BEEN SPECIALLY DESIGNED TO ANNOY HIM A BIT, BUT IT WAS ONLY MEANT TO BE THIS IN A VERY FRIENDLY WAY AS HE ACTUALLY IS A VERY NICE PERSON, AND SO ARE THE OTHER CAREBEARS. JUST FOR YOUR INFORMATION, NIC, THIS ROUTINE USES THE SOCALLED CLF CODING FOR VECTOR GRAPHICS, WHERE CLF STANDS FOR CHEAT LIKE FUCK. THE ROUTINES WERE NOT NICKED FROM ANY OF YOUR CODE! AND THE CLF METHOD WAS WRITTEN IN LESS THAN TWO BLOODY HOURS!! WE HAVE NOW PROVEN THAT WE ARE NOT JUST THE MOST MAJOR PAIN IN YOUR ASS. NO! WE HAVE PROVEN THAT WE SHOT YOUR ASS CLEAN OFF!! SO FAR THIS BIT OF LAMING. WE DO NOT LIKE TO DO THIS, BUT COULD NOT RESIST. PLEASE, CAREBEARS, DO NOT MAKE THE DEMO CODING WORLD INTO A WARZONE. LET US JUST ALL HAVE FUN AND CODE NICE DEMO SCREENS!         GOOD.    WELCOME TO THE BEATNIC SCREEN AGAIN. IT FEATURES THE FASTEST 3D VECTOR GRAPHICS IN THE KNOWN UNIVERSE PLUS MORE! WE CONSIDER 3D VECTOR GRAPHICS IN THEIR PURE FORM, NO MATTER HOW FAST, TO BE EXTREMELY BORING. SO THAT IS WHY WE INCLUDED QUITE A BIT MORE TO MAKE IT LESS BORING. WE HAD OVER 75% OF PROCESSOR TIME LEFT ANYWAY...  SO THAT IS WHY A LANDSCAPE SCROLLER, A BIG SCROLLER TEXT AND SOME MUSIC WITH DIGI DRUMS HAVE BEEN INCLUDED. THERE IS STILL SOME PROCESSOR TIME LEFT, BUT WHATTAHECK. I REALLY DO NOT FEEL LIKE WRITING A LOT, ALSO BECAUSE IT HAS BEEN A TIRING DAY AND ALL KINDS OF COMPLICATIONS IN ALL KINDS OF FIELDS HAVE POPPED UP. ALSO, I MISS MY GIRL. SO THAT IS IT THEN. OF COURSE, WE HAVE TO GREET A COUPLE OF PEOPLE WHICH WE HEREBY DO. THE GREETINGS GO TO THE GIGABYTE CREW, THE UNION AND THE RESPECTASETTABLES WHO WE WOULD VERY MUCH LIKE TO THANK FOR ARRANGING THE TEE SHIRTS. THAT IS IT, FELLAS!   WRAP TIME....... ",0

bsfont_2_map: incbin "gfx/bsfont_2.nxm"

        seg GFX_SEG

bsfont_2_tiles: incbin "gfx/bsfont_2.nxt"
bsfont_2_tiles_size: equ *-bsfont_2_tiles

        seg CODE_SEG

