.var music = LoadSid("turku_demoedit.sid")

.var demopart_jmp = $000e
.var pointer_lo = $000f
.var pointer_hi = $0010

.var textpointer_lo = $0011
.var textpointer_hi = $0012

.align $100

framecounter: .byte 0
current_pattern: .byte 0
current_pattern_pointer: .byte 0

.var num_patterns = 2

pattern_orderlist_module:
			.word writer, writer, writer, writer, loop

pattern_orderlist_params:
			.word writer1_params, writer2_params, writer3_params, writer4_params

:BasicUpstart2(start)
start:

			ldx #0
!loop:
			.for(var i=0; i<4; i++) {
				lda #$20
				sta $0400+i*$100,x
				lda #$02
				sta $d800+i*$100,x
			}
			inx
			bne !loop-

			lda #$00
			sta $d020
			sta $d021

			ldx #0
			ldy #0

			lda #music.startSong-1
			jsr music.init	
			sei
			lda #<irq1
			sta $0314
			lda #>irq1
			sta $0315
			asl $d019
			lda #$7b
			sta $dc0d
			lda #$81
			sta $d01a
			lda #$1b
			sta $d011
			lda #$80
			sta $d012
			cli

			lda #$4c // jmp-opcode
			sta demopart_jmp

mainloop:       
			// render current module from current pattern order and tick
		
			ldx current_pattern_pointer

			lda pattern_orderlist_module,x
			sta pointer_lo

			lda pattern_orderlist_module+1,x
			sta pointer_hi

			jsr demopart_jmp

module_exit:
			
			jmp mainloop // main logic loop complete

// -- modules ---------------------------------------------

// -- loop module -----------------------------------------

loop:
	lda #0
	sta current_pattern_pointer
	jmp module_exit

// -- writer module ---------------------------------------

textline_ypos: .byte 0, 0, 0
textline_color: .byte 0, 0, 0
text_animspeed: .byte 0

cur_textline_xpos: .byte 0
cur_textline_ypos: .byte 0
cur_textline_len: .byte 0
text_param_bytecounter: .byte 0
new_screen_flag: .byte 0

textline_offsets: .byte 0, 40*2, 40*4
textdata_offset: .byte 0
current_line: .byte 0

color_offset: .byte 0

.var screen = $0400

// line entry
// byte ypos (0-4)
// byte color (c64 color)
// word text_data
// byte $FF text end
//
// byte $FF lines end
// byte animspeed // update animation after how many frames? 

// Simple 2x2 text writer for all the demo textscreens

writer:
			// set correct charset bank
			lda #$1e
			sta $d018

			lda new_screen_flag
			cmp #0 // are we starting a new writerscreen?
			beq init_new_screen

			jmp update_writer // just update if not new

init_new_screen:

			// --- init new writerscreen

			ldx #255
clearloop:
			lda #$20
			sta screen+400,x
			dex
			bne clearloop

			lda #0
			sta text_param_bytecounter
			sta cur_textline_len
			sta color_offset

			lda #1
			sta new_screen_flag

			ldx current_pattern_pointer // get params for current pattern

			lda pattern_orderlist_params,x
			sta textpointer_lo

			lda pattern_orderlist_params+1,x
			sta textpointer_hi
		
writerloop:
			lda textpointer_lo
			clc
			adc text_param_bytecounter
			sta textpointer_lo // advance param bytepointer
			bcs writer_hiadd
			jmp no_hiadd
writer_hiadd:
			inc textpointer_hi // add to hibyte of the address if overflown
no_hiadd:

			lda #0
			sta text_param_bytecounter

			// param byte 0: text ypos
			ldy #0
			lda (textpointer_lo),y
			tax
			
			lda textline_offsets,x // get vertical screen offset for line ypos
			sta textline_ypos,x    // store it here
			sta cur_textline_ypos
			stx current_line

			inc text_param_bytecounter

			// param byte 1: text color
			ldy #1
			lda (textpointer_lo),y
			sta textline_color,x
			inc text_param_bytecounter
		
			// text writing loop

			lda #0
			sta cur_textline_len
			sta cur_textline_xpos

			// calculate line length	
			// param byte 2: text start
linecounter:
			iny
			inc text_param_bytecounter
			inc cur_textline_len
			lda (textpointer_lo),y
			cmp #255
			bne linecounter

			// calculate centered xpos

			lda #20 // screenw / 2
			clc
			sbc cur_textline_len
			sta cur_textline_xpos
				
			ldy #2
			sty textdata_offset
printloop:
			ldy textdata_offset
			lda (textpointer_lo),y
			tax // save char to x for lower char printing

			pha

			tya
			clc
			adc cur_textline_xpos
			clc
			adc cur_textline_ypos // calculate screen position
			tay

			pla

			// print the new chars 2x2
			sta screen+400,y
			clc
			adc #$40
			sta screen+401,y

			txa
			ora #$80
			sta screen+440,y

			clc
			adc #$40
			sta screen+441,y

			inc cur_textline_xpos

			inc textdata_offset
			ldy textdata_offset

			lda (textpointer_lo),y
			cmp #255
			bne printloop // more chars in string

peeker:
			
			// peek if end of this screen
			iny
			lda (textpointer_lo),y
			cmp #255
			beq update_writer // all lines rendered!
			jmp writerloop	  // if not, render next line		
			
update_writer:

			// color and fading here

			// update line colors


			ldy #0
colorloop:
			ldx #80
			lda textline_offsets,y
			sta color_offset
colorloop0:
			inc color_offset
			txa
			pha
			
			lda textline_color,y
			ldx color_offset
			sta $d800+399,x
			pla
			tax
			dex
			bne colorloop0
			iny
			cpy #3
			bne colorloop

			jmp module_exit

// writer params
// 
// line entry
// byte ypos (0-2)
// byte color (c64 color)
// word text_data
// byte $FF text end
//
// byte $FF lines end
// byte animspeed // update animation after how many frames? 

//---------------------------------------------------------

writer1_params:
			.byte 0  // ypos
			.byte LIGHT_GREEN // color
			.text "hei rakkaat yst<v<t"  // max 20 chars
			.byte $FF

			.byte 1  // ypos
			.byte LIGHT_BLUE // color
			.text "ja tervetuloa"
			.byte $FF

			.byte 2  // ypos
			.byte LIGHT_GRAY // color
			.text "illan shown pariin."
			.byte $FF

			.byte $FF // end

writer2_params:
			.byte 0  // ypos
			.byte LIGHT_BLUE // color
			.text "t<m< on trilon"  // max 20 chars
			.byte $FF

			.byte 1  // ypos
			.byte RED // color
			.text "uusi j<nnitt<v<"
			.byte $FF

			.byte 2  // ypos
			.byte BLUE // color
			.text "ohjelmanumero"
			.byte $FF

			.byte $FF // end

writer3_params:
			.byte 0  // ypos
			.byte GREEN // color
			.text "nojaa taakse ja"  // max 20 chars
			.byte $FF

			.byte 1  // ypos
			.byte LIGHT_BLUE // color
			.text "rentoudu, sill<"
			.byte $FF

			.byte 2  // ypos
			.byte RED // color
			.text "pian aloitamme."
			.byte $FF

			.byte $FF // end

writer4_params:
			.byte 0  // ypos
			.byte WHITE // color
			.text "t<m<n teki visy"  // max 20 chars
			.byte $FF

			.byte 1  // ypos
			.byte BLUE // color
			.text "ja muut kummat"
			.byte $FF

			.byte 2  // ypos
			.byte LIGHT_GRAY // color
			.text "karvaturrit."
			.byte $FF

			.byte $FF // end


//---------------------------------------------------------
irq1:  	
			asl $d019
			inc $d020
			jsr music.play 
			dec $d020

pattern_logic:
			inc framecounter

// frame-based timing, change to goat-timing etc.
			lda framecounter 
			cmp #192
			beq nextpattern
			jmp pattern_logic_done
nextpattern:

			inc current_pattern
			inc current_pattern_pointer
			inc current_pattern_pointer
			lda #0
			sta framecounter
			sta new_screen_flag
pattern_logic_done:

			pla
			tay
			pla
			tax
			pla
			rti
//---------------------------------------------------------
.pc=music.location "Music"
.fill music.size, music.getData(i)

.pc = $3800
.import binary "font.bin"

.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright

.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength




