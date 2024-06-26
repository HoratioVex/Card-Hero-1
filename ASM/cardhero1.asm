;wla-dx asm

.ROMSIZE
.COMPUTEGBCHECKSUM
.COMPUTEGBCOMPLEMENTCHECK
.EMPTYFILL $FF

.memorymap
slotsize $4000
slot 0 $0000
slot 1 $4000
defaultslot 0
.endme

.rombankmap
bankstotal $100
banksize $4000
banks $100
.endro

.BACKGROUND "../Card Hero (English).gbc"   ;to patch an existing file

;free HRAM bytes we can use
.def Htemp1 $FE
.def Htemp2 $FD
.def Htemp3 $FC
.def Htemp4 $FB

;game variables
.def HvramLo $8B ;current render position
.def HvramHi $8C
.def charCount $C40E
.def lineCount $C40D
.def vramBase $C400
.def msgPointerLo $C406
.def msgPointerHi $C407
.def msgPointerBa $C408
.def dlgPointerBa $C405

.SECTION "Font" OVERWRITE bank $64 slot 1 orga $63A0
	.incbin "..\graphics\font3x7.til" 
.ENDS

.SECTION "Hook1-CharLoaded" OVERWRITE bank $00 slot 0 orga $2FF5
	jp PrepRenderHalf
.ENDS

.SECTION "Hook2-RenderStart" OVERWRITE bank $00 slot 0 orga $3239
	call RenderHalf
	pop hl
	call RenderHalf ;why call it twice?
.ENDS

.SECTION "Hook3-MsgPointerWritten" OVERWRITE bank $00 slot 0 orga $3790
	jp RedirectMsgPointer
ExitHook3:
.ENDS

;.SECTION "Hook3-RenderDone" OVERWRITE bank $12 slot 1 orga $7B8F
;	jp updateQuadCount
;.ENDS

.SECTION "MainExpansion" OVERWRITE bank $00 slot 0 orga $3E19 size $E7
PrepRenderHalf:
	ld a,(charCount)
	bit 0,a ;test if we are on odd char
	jr NZ,@MoveLeft ;if odd, left side done,move back to same tile
	jr @Finish
@MoveLeft: ;vram go back to tile start
	ldh a,(HvramLo)
	and a,$0F ;if at new tile start, move back 1 tile
	jr NZ,@RenderRight
	ldh a,(HvramLo)
	sub a,$10
	ldh (HvramLo),a
@RenderRight:
	swap c
	swap b
	swap e
	swap d
@Finish:
	jp $37D7 ;back to original
	
RenderHalf:
	ldh a,($41)
	and a,$03 ;lcd stat check
	jr Z,RenderHalf
@Try2:
	ldh a,($41)
	and a,$03 ;lcd stat check
	jr NZ,@Try2
	di
	ld a,(charCount)
	bit 0,a ;test if we are on odd char
	jr NZ,@RenderRight 
@RenderLeft:
	ld a,c
	ldi (hl),a
	ld a,b
	ldi (hl),a
	ld a,e
	ldi (hl),a
	ld (hl),d
	inc hl
	jr @Finish
@RenderRight: ;bytes are nibbleswapped and blended over old tile with AND
	ld a,c
	and a,(hl)
	ldi (hl),a
	ld a,b
	and a,(hl)
	ldi (hl),a
	ld a,e
	and a,(hl)
	ldi (hl),a
	ld a,d
	and a,(hl)
	ldi (hl),a
@Finish:
	ei
	ldh a,($41)
	and a,$03 ;lcd stat check
	ret Z
	dec hl
	dec hl
	dec hl
	dec hl
	jr @Try2
	
RedirectMsgPointer:
	ld hl,(msgPointerLo)
	ldi a,(hl)
	ld h,(hl)
	ld l,a
	ldi a,(hl)
	ld (msgPointerLo),a
	ldi a,(hl)
	ld (msgPointerHi),a
	ld a,(hl)
	ld (msgPointerBa),a
	xor a	;overwritten by hook
	ld ($C857),a
	jp ExitHook3
.ENDS

;.SECTION "B12_Expansion" OVERWRITE bank $12 slot 1 orga $7F8D

;.ENDS

;.SECTION "DEBUG msg test" OVERWRITE bank $54 slot 1 orga $4d16
;	.db $54,$84,$50,$51,$52,$ff,$53,$54,$55,$56,$85,$86,$87,$88,$ff,$89,$8a,$8b,$ff,$ff
;.ENDS

