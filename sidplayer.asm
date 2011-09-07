.var music = LoadSid("turku_demoedit.sid")

.align $100

.var framecounter = 0
.var current_pattern = 0

.var num_patterns = 1

.var pattern_orderlist_module = List().add(writer, start)
.var pattern_orderlist_params = List().add(writer1_params, writer1_params, writer1_params)

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

mainloop:       
			// render current module from current pattern order and tick
			jmp pattern_orderlist_module.get(current_pattern)

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
			.eval framecounter++

// frame-based timing, change to goat-timing etc.
			lda framecounter 
			cmp #64
			beq nextpattern
			jmp pattern_logic_done
nextpattern:
			.eval current_pattern = current_pattern + 1
			.eval framecounter = 0
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




