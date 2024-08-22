
    align 32


IM_2_Table:
        dw      linehandler     ; 0 - line interrupt
        dw      inthandler      ; 1 - uart0 rx
        dw      inthandler      ; 2 - uart1 rx
        dw      ctc0handler     ; 3 - ctc 0
        dw      inthandler      ; 4 - ctc 1
        dw      inthandler      ; 5 - ctc 2
        dw      inthandler      ; 6 - ctc 3
        dw      inthandler      ; 7 - ctc 4
        dw      inthandler      ; 8 - ctc 5
        dw      inthandler      ; 9 - ctc 6
        dw      inthandler      ; 10 - ctc 7
        dw      vbl             ; 11 - ula
        dw      inthandler      ; 12 - uart0 tx
        dw      inthandler      ; 13 - uart1 tx
        dw      inthandler      ; 14
        dw      inthandler      ; 15

wait_vbl:
	border 0
    ld hl,irq_counter 
	ld a,(hl)
.loop:
	halt
    cp (hl)
    jr z,.loop
	ld (hl),0
	border 6
	ret

irq_counter: db 0
irq_last_count: db 0

init_vbl:

    nextreg $23,50

    di

    ld a,HI(IM_2_Table)
    ld i,a

    nextreg $c0, 1+(IM_2_Table & %11100000) ;low byte IRQ table  | base vector = 0xa0, im2 hardware mode
   	
	nextreg $c4,1+2				; ULA interrupt no Line
	nextreg $c5,0               ; disable CTC channels
	nextreg $c6,0               ; disable UART

    ; not dma
    nextreg $cc,%10000001    ; NMI will interrupt dma
    nextreg $cd,0            ; ct 0 no interrupt dma
    nextreg $ce,0            ; ct 0 no interrupt dma

    im 2

    ei
    ret


vbl:
	di
	push af

 	ld a,(irq_counter)
    inc a
 	ld (irq_counter),a

	pop af

    NextReg $c8,1
    ei
    reti

linehandler:
    push af
	border 5

    push bc
    push de
    push hl
    push ix
    call bottom_scroller_update
    pop ix
    pop hl
    pop de
    pop bc

	border 0
    pop af

    NextReg $c8,2
    ei
    reti

ctc0handler:
	my_break
    NextReg $c9,1
    ei
    reti

inthandler:
	my_break
    ei
    reti
    
