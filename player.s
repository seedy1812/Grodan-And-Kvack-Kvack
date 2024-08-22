					RSRESET
VERTICAL_SPRITES: equ RS
					RSSET(VERTICAL_SPRITES+ 13*6)

SMALL_SPRITES_1: equ RS
					RSSET(SMALL_SPRITES_1+17)        ;78
SMALL_SPRITES_2: equ RS
					RSSET(SMALL_SPRITES_2+17 )    ;95
TCB_SPRITES:    equ RS 
					RSSET(TCB_SPRITES+12 )  ;112
LEFT_SPRITES: equ RS



;NextRegs
COPPER_DATA				equ $60
COPPER_ADDR_LSB			equ $61
COPPER_CTRL				equ $62

PERIPHERAL_1_SETTING	equ $05
PERIPHERAL_2_SETTING	equ $06
PERIPHERAL_3_SETTING	equ $08
PERIPHERAL_4_SETTING	equ $09

CPU_SPEED				equ $07

LINE_INT_CTRL		 	equ $22 
LINE_INT_LSB		 	equ $23

SPRITE_LAYERS_SYSTEM 	equ $15
ULA_CONTROL			 	equ $68

LAYER_2_ACTIVE_BANK	 	equ $12
LAYER_2_SHADOW_BANK	 	equ $13

LAYER2_CLIP_WINDOW	 	equ $18
SPRITE_CLIP_WINDOW		 equ $19
LAYER0_CLIP_WINDOW	 	equ $1a
LAYER3_CLIP_WINDOW	 	equ $1b
CLIP_WINDOW_CTRL	 	equ $1c 

ULA_SCROLL_X 		 	equ $26
ULA_SCROLL_Y 		 	equ $27

GLOBAL_TRANS_COLOR	 	equ $14

PAL_INDEX            	equ $40
PAL_VALUE_8BIT       	equ $41
PAL_VALUE_9BIT			equ $44
PAL_CTRL			 	equ $43
PAL_FALLBACK_COLOUR		equ $4A

SPRITE_NUMBER			equ $34
SPRITE_TRANS_INDEX	 	equ $4b

LAYER2_SCROLL_X_MSB  	equ $71 
LAYER2_SCROLL_X_LSB  	equ $16
LAYER2_SCROLL_Y		 	equ $17

LAYER3_SCROLL_X_MSB  	equ $2f 
LAYER3_SCROLL_X_LSB  	equ $30
LAYER3_SCROLL_Y		 	equ $31 

LAYER3_TRANS_COLOUR: 	equ $4b
LAYER3_CTRL		 	 	equ $6b
LAYER3_DEF_ATTR		 	equ $6c
LAYER3_MAP_HI		 	equ $6e
LAYER3_TILE_HI		 	equ $6f
LAYER3_TRANS_INDEX 		equ $4c

MMU_Slot0				equ $51
MMU_Slot1				equ $51
MMU_Slot2				equ $52
MMU_Slot3				equ $53
MMU_Slot4				equ $54
MMU_Slot5				equ $55
MMU_Slot6				equ $56
MMU_Slot7				equ $57


;; OUT ports

NEXT_DMA_PORT    	 	equ $6b ;//: zxnDMA
LAYER2_OUT			 	equ $123B
SPRITE_ATTRIBUTE_OUT    equ $57
SPRITE_INDEX_OUT    	equ $303b

;TILE_DEF_ATTR_PAL macro LO(\0*16) endm

CLS_INDEX equ $ff

bordera macro
         out ($fe),a
        endm

border macro
           ld a,\0
           bordera
        endm

MY_BREAK	macro
        db $dd,01
		endm

	OPT Z80
	OPT ZXNEXTREG    



    seg     CODE_SEG, 	 4:$0000,$8000

	seg		GFX_SEG,	 15:$0000,$c000
	seg 	LAYER2_SEG,  18:$0000,$0000
	seg     ULA_SEG, 	 27:$0000,$0000                 ; ULA "bank" (for Tilemaps)

    seg     CODE_SEG

start:

;; set the stack pointer
	ld sp , StackStart

	call init_vbl

;	ld a,PERIPHERAL_4_SETTING
;	call ReadNextReg
;	set 4,a
;	nextreg PERIPHERAL_4_SETTING,a
	
	call video_setup

	ld a,PERIPHERAL_2_SETTING
	call ReadNextReg
	and %01011111		; 
	Nextreg PERIPHERAL_2_SETTING,a

	ld a, PERIPHERAL_3_SETTING
	call ReadNextReg
	or %0100000
	Nextreg PERIPHERAL_3_SETTING,a

	nextreg CPU_SPEED,%11 ; 28mhz

	nextreg SPRITE_TRANS_INDEX,0            ; sprites transpanecy index


	nextreg PAL_FALLBACK_COLOUR ,0

	nextreg GLOBAL_TRANS_COLOR,$e3



	call bottom_scroller_init

	call tcb_init

	call vscroller_init

	call prepare_bg1_ula
	call prepare_bg2_layer2

	call rasters_init
	call small_scrollers_init

	call copy_raster

    call bottom_sprites_go


frame_loop:

	call copy_raster_run

	call vscroller_update
	call update_bg1
	call update_bg2

	call tcb_update

	call small_scrollers_update


;;;	call bottom_scroller_update


	call wait_vbl

	jp frame_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
StackEnd:
	ds	128*3
StackStart:
	ds  2

include "irq.s"
include "video.s"


	seg    CODE_SEG
include "layer_ula.s"
include "layer_2.s"

include "scroller_bottom.s"

include "scroller_vertical.s"
include "rasters.s"

include "scroller_small.s"

include "tcb.s"

include "sine.s"

	seg    LAYER2_SEG

BG2_NXI:	incbin "gfx/Grodan_pink_256.nxi"

 	savenex "player.nex",start,StackStart



