
	seg    CODE_SEG


// not 100% right for X , but as all are starting at 0 we can cheat
// and y not going over 255 so this fine

INLINE_COPPER_WAIT	macro
        bit 0,(ix+0)
        jr nz,.exit
        set 0,(ix+0)
        ld c,\0
        set 7,c         ; indicate move
        ld (hl),c
        inc hl

        ld (hl),\1
        inc hl
.exit:
;	db	HI($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
;	db	LO($8000+(\0&$1ff)+(( ((\1/8) >>3) &$3f)<<9))
        endm

INLINE_COPPER_MOVE		macro
        ld (hl), \0
        inc hl
        ld (hl),\1
        inc hl
;	db	HI($0000+((\0&$ff)<<8)+(\1&$ff))
;	db	LO($0000+((\0&$ff)<<8)+(\1&$ff))
        endm

INLINE_PAL_SPRITE  macro
       INLINE_COPPER_MOVE PAL_CTRL,%10100001
        endm

INLINE_PAL_LAYER3  macro
       INLINE_COPPER_MOVE PAL_CTRL,%10110001
.exit:
        endm


INLINE_COPPER_HALT		macro
        INLINE_COPPER_WAIT 255,255
        endm

rasters_flags:  ds 1

rasters_init:
        ld hl, rasters_space
        ld (raster_ptr),hl

        ld hl,raster_y
        ld (hl),0

        ld ix, rasters_flags
        ld (ix+0),0
.loop:  res 0,(ix+0)
        push hl



        call do_raster_vscroll
        call do_raster_bottom

        call do_raster_small1
        call do_raster_small2

        pop hl
        inc (hl)
        ld a,192
        cp (hl)
        jr nz,.loop
;..copy raster

        ld hl,(raster_ptr)
        INLINE_COPPER_HALT
        ld (raster_ptr),hl

        ld      hl,(raster_ptr)
        ld      de,rasters_space
        xor a
        sbc    hl,de
        ret z ; if 0 length return

        ld b,h
        ld c,l                  ;bc = length
        ld  (raster_length),bc
        ret

copy_raster:
        ld  hl,rasters_space    ;hl = start
        ld  bc,(raster_length)    ;bc length

	nextreg COPPER_ADDR_LSB,0   ; LSB = 0
	nextreg COPPER_CTRL,0   ;// copper stop | MSBs = 00


        ld a,3
        and c
        jr nz,.lp0

.lp1:	ld	a,(hl)  ;// write the bytes of the copper
	nextreg COPPER_DATA,a
	inc	hl
        dec     bc
        
        ld	a,(hl)  ;// write the bytes of the copper
	nextreg COPPER_DATA,a
	inc	hl
        dec     bc
       
 .lp0:  ld	a,(hl)  ;// write the bytes of the copper
	nextreg COPPER_DATA,a
	inc	hl
        dec     bc
        
        ld	a,(hl)  ;// write the bytes of the copper
	nextreg COPPER_DATA,a
	inc	hl
        dec     bc

        ld a,b
        or c
        jp nz,.lp1
        retmy_
copy_raster_run:
	nextreg COPPER_CTRL,%01000000 ;// copper start | MSBs = 0
        ret


do_raster_vscroll:
        ld a,(raster_y)
        ld b,a
        srl a
        ret c


        ld hl,(raster_ptr)

       

        INLINE_COPPER_WAIT  0,b

        INLINE_PAL_SPRITE

        INLINE_COPPER_MOVE PAL_INDEX, 1

        ld de,raster_texture
        add de,a
        ld a,(de)
        ld de,raster_palette
        add de,a
        ld a,(de)

        INLINE_COPPER_MOVE     PAL_VALUE_8BIT,a

        ld (raster_ptr),hl
        ret


do_raster_small2:
        ld h,64/2
        ld iy,scroller2
        jr do_raster_small




do_raster_small1:
        ld h,4/2
        ld iy,scroller1

do_raster_small:
        ld a,(raster_y)
        srl a
        ld b,a
        ret c

        sub h
        ret c


        jr nz,.after_first_line


        res 7,(ix+0)
.after_first_line:        


        cp 20/2
        ret nc

        ld hl,(raster_ptr)

        INLINE_COPPER_WAIT  0,b

        INLINE_COPPER_MOVE PAL_INDEX, 16*2+1

        ld a,b
        ld de,raster_texture
        add de,a
        ld a,(de)
        ld de,raster_palette
        add de,a
        ld a,(de)

        INLINE_COPPER_MOVE     PAL_VALUE_8BIT,a

        ld (raster_ptr),hl
        ret


do_raster_bottom:
        ld a,(raster_y)
        ld b,a

        srl a
        ret c

        sub 92/2
        ret c

        cp 96/2
        ret nc

        ld hl,(raster_ptr)

        INLINE_COPPER_WAIT  1,b

        INLINE_COPPER_MOVE PAL_INDEX, 16+1

        ld de,bigscroller_texture
        add de,a
        ld a,(de)
        ld de,bigscroller_palette
        add de,a
        ld a,(de)

        INLINE_COPPER_MOVE     PAL_VALUE_8BIT,a

        ld (raster_ptr),hl
        ret

bigscroller_texture: incbin "gfx/bigscrollraster.nxi"
bigscroller_palette: incbin "gfx/bigscrollraster.nxp"

raster_texture: incbin "gfx/upscrollraster.nxi"
raster_palette: incbin "gfx/upscrollraster.nxp"

raster_y:       db 0
raster_ptr:     dw 0
raster_length:  dw 0
rasters_space:  ds 2048




