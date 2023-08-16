.export DEBUG




.proc DEBUG
.zeropage
    .importzp PPUMask
    Loaded: .res 1

.segment "CODE"
 


  ldx Loaded
    cpx #$00
    beq @Load
    bne @Continue
    @Load:
     jsr LOAD

  @Continue:
  jsr RENDER
  jsr RUNENTITIEBEHAVIOUR
rts

LOAD:
    lda #$01
    jsr LOADBACKGROUND

  
    lda #%00011110   ;enable sprites and backgrounds for left most 8 pixels
    sta PPUMask

    lda #$01
    sta Loaded
    
    lda #$00
    sta $00 ;index
    jsr LOADENTITIE


    lda #$01
    sta $00
    jsr LOADENTITIE



rts

.import LOADBACKGROUND
.import LOADENTITIE
.import RENDER
.import RUNENTITIEBEHAVIOUR
.endproc