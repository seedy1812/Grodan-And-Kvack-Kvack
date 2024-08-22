
vscroll_num_letters equ  ((192/16)+1)


vscroll_y:          db 0
vscroll_letters:    ds vscroll_num_letters

vscroll_text_addr:  dw vscroll_text

vscroll_text:       db "                           TANIS, THE FAMOUS GRAFIXX-MAN, IS A NEW MEMBER OF TCB.  HE MADE ALL THE GRAPHICS IN THIS SCREEN PLUS LOTSA LOGOS IN THE MAIN MENU.  WE AGREE THAT THIS 'ONE-BIT-PLANE-MANIA' DOESN'T LOOK VERY GOOD, BUT IT HAD TO BE DONE BY SOMEONE........   BAD LUCK FOR TANIS THAT WE WON'T MAKE MORE DEMOS, THOUGH....       9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9  ..................                 LET'S WRAP (WE SPELLED IT CORRECTLY!!!).......   ",0


vscroll_text_to_sprite: incbin "gfx/upfonts.nxm"

    SEG_GFX

vscroll_sprites:        incbin "gfx/upfonts.nxt"
vscroll_sprites_size: equ *-vscroll_sprites
    SEG_CODE



vscroller_init:
    nextreg CLIP_WINDOW_CTRL,%00000010

    nextreg SPRITE_CLIP_WINDOW,0
    nextreg SPRITE_CLIP_WINDOW,255
    nextreg SPRITE_CLIP_WINDOW,0
    nextreg SPRITE_CLIP_WINDOW,191


    ld a,1
    ld (vscroll_y),a

    ld b,vscroll_num_letters
    ld hl,vscroll_letters
    ld a,0                  ; 0 = no sprite
.lp:
    ld (hl),a
    inc hl
    djnz .lp


    ; now copy sprites up

    ld hl,vscroll_sprites

    nextreg SPRITE_NUMBER, VERTICAL_SPRITES

    ld a,HI(vscroll_sprites_size)

    ld bc,$005b + (16*16)*256

.sprite_loop
 
    otir ;; send 256 bytes to port 0x5b

    dec a
    jr nz, .sprite_loop

    ret

vscroller_update:
    ld a,(vscroll_y)
    dec a
    ld (vscroll_y),a
    jr nz,.just_draw 
    add 16
    ld (vscroll_y),a

    ld hl,vscroll_letters+1
    ld de,vscroll_letters
    ld bc,vscroll_num_letters-1
    ldir

    ;; de is where next letter will be stored
    
    ld hl,(vscroll_text_addr)
.again:
    ld a,(hl)
    or a
    jr nz , .got_letter
    ld hl,vscroll_text
    jr .again
.got_letter:
    inc hl
    ld (vscroll_text_addr),hl

    ld hl,vscroll_text_to_sprite
    sub $20
    add hl,a
    ld a,(hl)

    ld (de),a


 .just_draw:

    ld bc, SPRITE_INDEX_OUT

    xor a
    out (c),a ; start at pattern 0

    ld hl,vscroll_letters
    ld b,vscroll_num_letters
    ld a,(vscroll_y)
    add 32-16
    ld e,a
.draw_lp:
    ld a,(hl)
    inc hl

    ld d,0              
    call draw_me        ; d = x , e = y
    ld d,32
    call draw_me
    ld d,64
    call draw_me

    ld d,256-16-0
    call draw_me
    ld d,256-16-32
    call draw_me
    ld d,256-16-64
    call draw_me
.nowt:
    ld a,16
    add a,e
    ld e,a
    djnz .draw_lp
    ret

 draw_me:

    push af
    push bc

    ld b,a

    ld c,SPRITE_ATTRIBUTE_OUT

    ld a,d
    add a,32
    out (c),a  ; x:lo

    out (c),e ; y

    ld a,0
    adc a,a     ; palette offset = 0
    out (c),a   ; bit 0 msb:x

    ld a,b      ;sprite index
    or a
    jr nz,.show
    srl a
    jr .go

.show:
    srl a
 ;   or a       ; dont hide blank sprites as we would have to blank sprites at end due to variable numbers
 ;   jr z,.hidden
    set 7,a     ; visible
.go:
    set 6,a     ; extended data
.hidden
    out (c),a
    ld a,$80
    jr nc,.no_n6
    set 6,a
.no_n6:
    out (c),a

    pop bc
    pop af
    ret


