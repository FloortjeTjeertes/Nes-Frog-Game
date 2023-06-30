.segment "HEADER"
    .byte "NES";characters nes  gets converted to hex value $4E $45 $53
    .byte $1A  ;ms dos end of line character
    .byte $02  ;2 * 16KB PRG ROM
    .byte $01  ; 1 * 8KB CHR ROM
    .byte %00000000 ;flags Mapper, mirroring, battery, trainer
    .byte $00 ; Mapper, VS/Playchoice, NES 2.0
    .byte $00 ;PRG-RAM size 
    .byte $00 ;TV system
    .byte $00 ;TV system, PRG-RAM presence   
    .byte $46, $52,$31,$4C,$59




JOYPAD1 = $4016





.zeropage
buttons: .res 1 ; 1 byte for buttons
counter: .res 1 


.segment "STARTUP"


jsr WAITVBLANK


jsr CLEANPPU




RESET:
  sei          ; disable IRQs
  cld          ; disable decimal mode
  ldx #$40
  stx $4017    ; disable APU frame IRQ
  ldx #$FF
  txs          ; Set up stack
  inx          ; now X = 0
  stx $2000    ; disable NMI
  stx $2001    ; disable rendering
  stx $4010    ; disable DMC IRQs
  
  lda #$00    ;store 0 in acumulator to clear counter
  sta counter ;store acumulator in counter (should be 0)

  jsr WAITVBLANK


CLRMEM:
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$FF
  sta $0200, x
  lda #$00
  inx
  bne CLRMEM
  ;vblank wait


  jsr WAITVBLANK

  jsr CLEANPPU

  

  lda #$3F
  sta $2006 ;store most significant value 3f in ppu write address 3f.. (the adress where you store the address you want to write too in the ppu)
  lda #$00
  sta $2006 ;store least significant value 00 in ppu write address ..00

  ldx #$00

LOADPALETTES:
  lda PALLETEDATA, x
  sta $2007 ; PPUDATA memory address to wright data to ppu (ppu puts this value in the adress defined in memory address from $2006) ppu auto increments memory address in $2006 on every wright in $2007
  inx 
  cpx #$20
  bne LOADPALETTES

  ldx #$00
  


  jsr LOADSPRITES





LOADBACKGROUND:

  lda #$20    ;load 20 into acumulator
  sta $2006   ;stores most significant byte in ppu
  lda #$00   ;stores least sugnificant byte in acumulator 
  sta $2006   ;stores least significant byte in ppu

  ldx #$00   ;load x with 0

  :
    txa       ;transfer x to acumulator
    sta $2007 ;stores acumulator in ppu address 2007
    inx
    cpx #$CE ;compare x with 255
  bne :-


;enable interupts
  cli

  lda #%10000000 ;enable nmi change background to use second char set
  sta $2000  ;PPUCTRL ppu controll register
  lda #%00011110   ;enable sprites and backgrounds for left most 8 pixels
  sta $2001

.segment "CODE"

;program loop


  jsr DISPLAYBACKGROUND



  ldx #$00
  ldy #$00

LOOP:

 

  jsr CHECKBUTTONS



  
jmp LOOP

CHECKBUTTONS:
  lda DOWN 
  and buttons
  cmp DOWN
  beq MOVEDOWN

  lda UP
  and buttons
  cmp UP
  beq MOVEUP

  lda LEFT 
  and buttons
  cmp LEFT
  beq MOVELEFT

  lda RIGHT 
  and buttons
  cmp RIGHT
  beq MOVERIGHT

  rts

MOVEDOWN:
  iny
  jmp MOVE

MOVEUP:
  dey
  jmp MOVE

MOVERIGHT:
  inx
  jmp MOVE

MOVELEFT:
  dex
  jmp MOVE

MOVE:
  jsr MOVEBLOCK

  jsr WAITVBLANK

rts


LOAD_META_SPRITE:
  ; Load meta sprite patterns
  ldx #$00         ; Initialize X register

  ; Load meta sprite tiles
  lda META_LOOKUP_TABLE, x      ;store length first
  sta $01                     
  lda META_LOOKUP_TABLE+1, x   ; then load the tile data
  sta $00           

  ldy #$00         ; Initialize Y register
  ldx #$00         ; Initialize X register

  ; Load each tile of the meta sprite
  LOAD_TILE:


    lda META_POSITION_DATA, y   ; Load the Y position data
    sta $0200,y                   ; Store the Y position in the OAM address register

    ; Load the tile data, attributes, and X position
    lda META_TILE_DATA, y       ; Load the tile data
    sta $0201,y                ; Store the tile data in the $0200 range

    lda META_COLOR_DATA, y      ; Load the attribute data
    sta $0202,y                ; Store the attribute data in the $0200 range

    lda META_POSITION_DATA+1, y ; Load the X position data
    sta $0203,y                ; Store the X position in the $0200 range

    iny                         ; Increment Y register to load the next position/tile
                             
    inx                         ; Increment X register to load the next tile

    cpx $01                     ;check if the sprite has the length of the meta sprite
                        
  bne LOAD_TILE                 ; If not, continue loading tiles



 

rts


LOADSPRITES:
  jsr LOAD_META_SPRITE   ; Initialize meta sprites

  ; Load regular sprites
  ; ldx #$00
  ; :
  ; lda SPRITEDATA,x
  ; sta $0200,x
  ; inx
  ; cpx #$20
  ; bne :-

rts


MOVEBLOCK:  ;move  the block sprite  (change it later to work whit any character that needs to be moved)

  tya
  sta $0200
  sta $0204
  adc #$08
  sta $0208
  sta $020c


  txa
  sta $0203
  sta $020B
  adc #$08
  sta $0207
  sta $020F


rts

DISPLAYBACKGROUND:


  lda #%00000000   ;enable sprites and backgrounds for left most 8 pixels
  sta $2001
  sei

  lda #$28
  sta $2006 ;store most significant value 3f in ppu write address 3f.. (the adress where you store the address you want to write too in the ppu)
  lda #$C0
  sta $2006 ;store least significant value 00 in ppu write address ..00

  ldx #$00
  

  lda #$20    ; load the value 32 into the accumulator
  sta $2006   ; store the most significant byte in the PPU write address (0x2006)
  lda #$00    ; load the value 0 into the accumulator
  sta $2006   ; store the least significant byte in the PPU write address (0x2006)
  
  ldx #$00    ; load the value 0 into the X register

  
  :
  lda MAPDATA,x   ; load the value at the address stored in X and Y into the accumulator
  sta $2007   ; store the value in the PPU data register (0x2007)
  inx         ; increment the X register
  cpx #$FF ; compare X with the value 4096 (the size of a nametable in bytes)
  bne :-

 ldx #$00    ; load the value 0 into the X register


  :
  lda MAPDATA+255,x   ; load the value at the address stored in X and Y into the accumulator
  sta $2007   ; store the value in the PPU data register (0x2007)
  inx         ; increment the X register
  cpx #$FF ; compare X with the value 4096 (the size of a nametable in bytes)
  bne :-
   
 ldx #$00    ; load the value 0 into the X register

  :
  lda MAPDATA+510,x   ; load the value at the address stored in X and Y into the accumulator
  sta $2007   ; store the value in the PPU data register (0x2007)
  inx         ; increment the X register
  cpx #$FF ; compare X with the value 4096 (the size of a nametable in bytes)
  bne :-
  ldx #$00    ; load the value 0 into the X register
   :
  lda MAPDATA+765,x   ; load the value at the address stored in X and Y into the accumulator
  sta $2007   ; store the value in the PPU data register (0x2007)
  inx         ; increment the X register
  cpx #$FF ; compare X with the value 4096 (the size of a nametable in bytes)
  bne :-
  
  ldx #$00    ; load the value 0 into the X register
    :
  lda MAPDATA+1020,x   ; load the value at the address stored in X and Y into the accumulator
  sta $2007   ; store the value in the PPU data register (0x2007)
  inx         ; increment the X register
  cpx #$05 ; compare X with the value 4096 (the size of a nametable in bytes)
  bne :-
 

  cli

  lda #%00011110   ;enable sprites and backgrounds for left most 8 pixels
  sta $2001
 

rts

BACKGROUNDFLICKER:
  lda #$3F
  sta $2006 ;store most significant value 3f in ppu write address 3f.. (the adress where you store the address you want to write too in the ppu)
  lda #$00
  sta $2006 
  ldx $0000
  inx
  stx $0000
  lda $0000
  sta $2007 ; PPUDATA memory address to wright data to ppu (ppu puts this value in the adress defined in memory address from $2006) ppu auto increments memory address in $2006 on every wright in $2007
  lda #$26
  sta $2007
  lda #$27
  sta $2007
  lda #$28
  sta $2007
  cpx #$3f

rts

;shifts 1 every loop until 8 bits are shifted from the nes controller
;the status of the controller is stored every loop in the buttons
READCONTROLLER: 
    lda #$01 
    sta JOYPAD1 ;write 1 to joypad 1
    sta buttons ;write 1 to buttons
    lsr a   ; shifts 1 out of acumulator to make acumulator 0
    sta JOYPAD1 ;write aculumator (0) to joypad 1 (clears strobe bit and controller will keep stored value (pressed buttons) static
    :                                                                    
      lda JOYPAD1 ;read joypad 1 into acumulator                           
      lsr a ;shift left shifts red byte to form a full 8 bits of the read controller                                                
      rol buttons ;shift left to eventually put 1 in carry (looping trough all bits in the buttons variable)      
    bcc :- ;branch to last ":" if carry flag is not set
rts



CLEANPPU:
  lda #$02 ;select most significant bite
  sta $4014 ;OAMDMA address
  nop
  

WAITVBLANK:
  BIT $2002 ;test if vblank is the same as address  2002 if negative flag is not high 
  BPL WAITVBLANK

  rts


VBLANK: ;nmi or vblank what happens in the vblank
  LDA #$02 ;copy sprite data from 0200 -> ppu memory for display
  sta $4014
  jsr READCONTROLLER
  rti




AButton:
 .byte %10000000
BButton:
 .byte %01000000
SELECT: 
 .byte %00100000
START:  
 .byte %00010000
UP:     
 .byte %00001000
DOWN:   
 .byte %00000100
LEFT:   
 .byte %00000010
RIGHT:  
 .byte %00000001

.include "metasprites.asm"

PALLETEDATA:
  .byte $00,$00,$10,$20,$07,$16,$25,$30,$00,$21,$31,$30,$00,$27,$06,$00  ;background palette data
  .byte $0D,$16,$27,$18,$22,$16,$27,$18,$22,$16,$27,$18,$22,$16,$27,$18;sprite palette data


MAPDATA:
 .incbin "../resource/test.nam"


.segment "VECTORS"
    .word VBLANK
    .word RESET

.segment "CHARS"  
      .incbin "../resource/elementzones.chr"
      