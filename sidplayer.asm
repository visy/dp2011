.var music = LoadSid("turku_demoedit.sid")

.align $100

framecounter: .byte 0
current_pattern: .byte 0
current_pattern_pointer: .byte 0

.var num_patterns = 2

demopart_jmp:
	.byte 0
pointer_lo:
	.byte 0
pointer_hi:
	.byte 0

pattern_orderlist_module:
	.word writer, start

pattern_orderlist_params:
	.word writer1_params

:BasicUpstart2(start)
start:
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

// Simple 2x2 text writer for all the demo textscreens
writer:

	jmp module_exit

// writer params
//
// word text_data
// byte ypos (0-4)
// byte color (c64 color)
// byte animspeed // update animation after how many frames? 

//---------------------------------------------------------
writer1_params:
	.text "this is a test"
	.byte 2
	.byte 15
	.byte 0  

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
			cmp #64
			beq nextpattern
			jmp pattern_logic_done
nextpattern:
			inc current_pattern
			inc current_pattern_pointer
			inc current_pattern_pointer
			lda #0
			sta framecounter
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
// .pc = $0c00	"ScreenRam" 			.fill picture.getScreenRamSize(), picture.getScreenRam(i)
// .pc = $4c00	"ColorRam:" colorRam: 	.fill picture.getColorRamSize(), picture.getColorRam(i)
// .pc = $2000	"Bitmap"				.fill picture.getBitmapSize(), picture.getBitmap(i)

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




