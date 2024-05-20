;wla-dx asm

;.ROMSIZE
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
bankstotal $80
banksize $4000
banks $80
.endro

.BACKGROUND "../Card Hero (English).gbc"   ;to patch an existing file

.def quadsRendered $FE ;free HRAM byte, keep track how many sets of 4 bytes we've rendered to the current tile
.def storevram1 $FD
.def storevram2 $FC  
.def vram1 $8B
.def vram2 $8C			


.SECTION "Font" OVERWRITE bank $64 slot 1 orga $63A0
	.incbin "..\graphics\font3x7.til" 
.ENDS

.SECTION "Hook1-CharLoaded" OVERWRITE bank $00 slot 0 orga $2FF5
	jp PrepRenderHalf
.ENDS

.SECTION "Hook2-RenderStart" OVERWRITE bank $00 slot 0 orga $3239
	call RenderHalf
	pop hl
	call RenderHalf
.ENDS

;.SECTION "Hook3-RenderDone" OVERWRITE bank $12 slot 1 orga $7B8F
;	jp updateQuadCount
;.ENDS

.SECTION "MainExpansion" OVERWRITE bank $00 slot 0 orga $3E19 size $E7
PrepRenderHalf:
	ldh a,(quadsRendered)
	cp a,$08
	jr Z,@MoveLeft ;if a==8, left side done,move back to same tile
	jr NC,@RenderRight ;if a>8
	or A,$00 ;if a=0
	jr NZ,@Finish
	ldh a,(vram1)	;new tile, store position
	ldh (storevram1),a
	ldh a,(vram2)
	ldh (storevram2),a
	jr @Finish
@MoveLeft: ;vram go back to tile start
	ldh a,(storevram1)	
	ldh (vram1),a
	ldh a,(storevram2)
	ldh (vram2),a
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
	ldh a,(quadsRendered)
	cp a,$08
	jr NC,@RenderRight ;if a>8
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
@RenderRight:
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
	jr Z,updateQuadCount
	dec hl
	dec hl
	dec hl
	dec hl
	jr @Try2
updateQuadCount:
	ldh a,(quadsRendered)
	inc a
	and a,$0F ;roll around at 16
	ldh (quadsRendered),a
	ret
.ENDS

;.SECTION "B12_Expansion" OVERWRITE bank $12 slot 1 orga $7F8D
;updateQuadCount:
;	ldh a,(quadsRendered)
;	inc a
;	and a,$07
;	ldh (quadsRendered),a
;	ld hl,$FF8D
;	jp $7B92
;.ENDS

; todo: half-width render

;reset side on: new message&line feed (12:76eb)
;, adjust vram advance