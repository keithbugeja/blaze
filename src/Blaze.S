*****************************************************************
* Blaze.S 							*
*****************************************************************
* DISCLAIMER: 							*
* 	This source code is ancient! 				*
*	It was written when I had very little programming 	*
*	experience; treat it as an example of how *not*	to	*
*	do things!						*
*							Keith	*
*****************************************************************

 Section Blaze_Code			
 opt o+				

***** Constants **************
Old_Mode	= 1005
Open		= -30
Close		= -36
Read		= -42
Write		= -48
Output		= -60
Forbid		= -132
IoErr		= -132
Permit		= -138
SetSR   	= -144
AllocMem	= -198
AllocRaster = -492
FreeRaster	= -498
Openlib     = -552

**** Comp. Int. Adap. *********
Error		= $fffffffe
Mousekey	= $bfe001
Keys        = $bfec01

**** Chip Registers ***********
Cop1lch     = $dff080
Cop1lcl     = $dff082
Cop2lch		= $dff084
Cop2lcl		= $dff086
Copjmp2		= $dff08a
Colours		= $dff180
Bltsize     = $dff058
Bltapth     = $dff050
Bltbpth     = $dff04c
Bltcpth     = $dff048
Bltdpth     = $dff054
Bltcon0     = $dff040
Bltcon1     = $dff042
Bltafwm     = $dff044
Bltalwm     = $dff046
Bltamod     = $dff064
Bltbmod     = $dff062
Bltcmod     = $dff060
Bltdmod     = $dff066
Bplcon1		= $dff102
Dmacon		= $dff096
Joydat      = $dff00c
Vposr		= $dff004
Intena		= $dff09a
Intreqr		= $dff01e
Intreq		= $dff09c

**** Disk Errors **************
Object_Not_Found      =  205
Disk_Not_Validated    =  213
Disk_Write_Protected  =  214
Device_Not_Mounted    =  218
Disk_Full             =  221
Not_A_Dos_Disk        =  225
No_Disk               =  226

**** Macros *******************
TIME_UPDATE MACRO
	Lea	Panel_Vals,a0

	Tst.b	In_Game_Timer
	Bne	\@0
	
	Move.l	#' OFF',2(a0)
	Bra	\@3

\@0:
	Subi.w	#1,TDelay
	Bpl	\@1

	Move.w	#25,TDelay
	Subi.w	#1,Time

\@1:		
	Cmpi.w	#99,Time
	Bhi	\@2

	Tst.w	Flick_Ctr
	Beq	\@2

	Move.l	#$006A6A6A,2(a0)
	Bra	\@3
\@2:	
	Move.w	Time,d1
	
	Move.w	d1,d0
	Divu	#10,d0
	Swap	d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,5(a0)
	
	Move.w	d1,d0
	Divu	#10,d0
	Andi.l	#$FF,d0
	Divu	#10,d0
	Swap	d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,4(a0)
	
	Move.w	d1,d0
	Divu	#100,d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,3(a0)
\@3:
	Nop
	ENDM

LIVES_UPDATE	MACRO
	Lea	Panel_Vals,a0
	Move.b	Lives,d0
	Addi.b	#48,d0
	Move.b	d0,11(a0)

	ENDM

JEWELS_UPDATE	MACRO
	Lea	Panel_Vals,a0

	Move.w	Emeralds,d1

	Move.w	d1,d0
	Divu	#10,d0
	Swap	d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,16(a0)
	
	Move.w	d1,d0
	Divu	#10,d0
	Andi.l	#$FF,d0
	Divu	#10,d0
	Swap	d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,15(a0)
	
	Move.w	d1,d0
	Divu	#100,d0
	Andi.l	#$FF,d0
	Addi.b	#48,d0
	Move.b	d0,14(a0)

	ENDM

ENERGY_UPDATE	MACRO
	Lea	Panel_Vals,a0
	Move.b	#$65,d0	
	Sub.b	Energy,d0

	Cmpi.b	#$65,d0
	Blo	\@1
	Moveq.l	#106,d0
\@1:		
	Move.b	d0,8(a0)
	ENDM

SETDUMMYCOP MACRO
	Move.l	#Cop_Dummy,$dff080
	ENDM

ENSIZE MACRO
	Move.w	\1,NFrames	; Default 10
	Move.w	\2,XBytes	; Default 4
	Move.w	\3,YBytes	; Default $500
	Move.w	\4,Enmsize	; Default $803
	Move.w	\5,Emod		; Default 34
	ENDM

COLSIZE	MACRO
	Move.l	\1,Coll_X1	; Default 112
	Move.l	\2,Coll_X2	; Default 176 (Strt + Size*2)
	Move.l	\3,Coll_Y1	; Default 96
	Move.l	\4,Coll_Y2	; Default 160 (Strt + Size*2)
	ENDM
	
SETCOPJMP MACRO
	Move.l	#Cop_Pan,$dff084

	Lea	Cop_Pan2,a0
	Move.l	Panel,d0
	Addi.l	#2,d0

	Move.w	d0,6(a0)
	Swap	d0
	Move.w	d0,2(a0)

	ENDM

SETERRCOP MACRO
	Lea	Error_Cop2,a0
	Move.l	Buffer1,d0
	
	Move.w	d0,6(a0)
	Swap	d0
	Move.w	d0,2(a0)
	ENDM

HOLD_FIRE MACRO
\@1:
	Btst	#7,Mousekey
	Beq	\@1
	ENDM

WAIT_FIRE MACRO
\@1:
	Btst	#7,Mousekey
	Bne	\@1
	ENDM

LOADPIC	MACRO	
	Bsr	Clear_Buffers
	Bsr	Flip_Screen

	OPENF	\1,#Old_Mode			; Load Picture
	READF	Handle,Currbuffer,\2
	CLOSEF	Handle
	
	Bsr	Flip_Screen
	ENDM

PRINTAT	MACRO
	Move.l	\1,Dest
	LOCATE	\2,\3,Dest
	Add.l	\6,Dest	
	PRINT	\4,\5,Dest
	ENDM

PRINTAM	MACRO
	Move.l	\1,Dest
	LOCATE	\2,\3,Dest
	PRINTM	\4,\5,Dest
	ENDM

LOCATE	MACRO
	Move.l	\1,d0
	Move.l	\2,d1
	Mulu	#640,d1
	Mulu	#2,d0
	Add.l	d0,d1
	Add.l	d1,Dest
	ENDM
	
COPY	MACRO
	Move.l	\1,a0
	Move.l	\2,a1
	Move.l	\3,d0
	
\@:
	Move.b	(a0)+,(a1)+
	Dbra	d0,\@	
	ENDM

PRINTM	MACRO
	Move.l	\1,a0
	Move.l	\2,d0
	Move.l	\3,d3
	
\@1:
	Move.l	Font,d4

	Move.l	#0,d1
	Move.l	#0,d2
	
	Move.b	(a0)+,d1

	Cmp.b	#255,d1
	Bne	\@3
	Addi.l	#(40*16),d3
	Bra	\@2
\@3:	

	Subi.b	#48,d1
	Bmi	\@2
	
	Ext.w	d1
	Divu	#20,d1

	Move.w	d1,d2
	Mulu	#640,d2

	Swap	d1
	Andi.l	#$FF,d1
	Mulu	#2,d1
	
	Add.l	d1,d2
	Add.l	d2,d4
	
	Move.l	d3,d5
	Move.l	#4,d6

\@4:
	BLITM	d4,d5,#$401,#38,#38,#0,#$FFFF,#$FFFF,d4
	Addi.l	#10240,d5
	Dbra	d6,\@4

\@2:
	Addi.l	#2,d3
	Dbra	d0,\@1
	ENDM

PRINT	MACRO
	Move.l	\1,a0
	Move.l	\2,d0
	Move.l	\3,d3
	
\@1:
	Move.l	Font,d4

	Move.l	#0,d1
	Move.l	#0,d2
	
	Move.b	(a0)+,d1

	Cmp.b	#255,d1
	Bne	\@3
	Addi.l	#(40*16),d3
	Bra	\@2
\@3:	

	Subi.b	#48,d1
	Bmi	\@2
	
	Ext.w	d1
	Divu	#20,d1

	Move.w	d1,d2
	Mulu	#640,d2

	Swap	d1
	Andi.l	#$FF,d1
	Mulu	#2,d1
	
	Add.l	d1,d2
	Add.l	d2,d4
	
	BLIT	d4,d3,#$401,#38,#38,#0,#$FFFF,#$FFFF
\@2:
	Addi.l	#2,d3
	Dbra	d0,\@1
	ENDM

OPENF	MACRO
\@0:
	Move.l	Dosbase,a6
	Move.l	\1,d1	; Filename
	Move.l	\2,d2	; Mode
	Jsr	Open(a6)
	Tst.l	d0
	Beq	\@1	
	Move.l	d0,Handle		; Global Handle For Disk I/O
	Bra	\@2		
\@1:
	Movem.l	d0-d7/a0-a7,-(sp)
	Jsr	Disk_Error
	Movem.l	(sp)+,d0-d7/a0-a7
	Bra	\@0
\@2:
	ENDM
	
CLOSEF	MACRO	
	Move.l	Dosbase,a6
	Move.l	\1,d1	; Handle
	Jsr	Close(a6)
	ENDM
	
WRITEF	MACRO	
	Move.l	Dosbase,a6
	Move.l	\1,d1	; Handle
	Move.l	\2,d2   ; #Data
	Move.l	\3,d3	; #Length
	Jsr	Write(a6)
	ENDM
	
READF	MACRO
	Move.l	Dosbase,a6
	Move.l	\1,d1	; Handle
	Move.l	\2,d2	; Buffer
	Move.l	\3,d3 	; #Length
	Jsr	Read(a6)	
	ENDM

COLOUR MACRO
	Move.w	\1,d0
	Move.w	\2,d1
	Lea	$dff000,a0
	Mulu	#2,d0
	Move.w	d1,(a0,d0)
	ENDM
	
BLIT MACRO
	Move 	\7,Bltafwm	; First Word Mask	
	Move 	\8,Bltalwm	; Last Word Mask
	Move.w  d0,-(sp)	
	Move.w	\6,d0		; Shifting

	Rol.w	#6,d0
	Rol.w	#6,d0

	Andi.w	#$f000,d0
	Addi.w 	#%0000100111110000,d0
	Move.w	d0,Bltcon0
	Move.w	(sp)+,d0
	Move 	#0,Bltcon1
	Move 	\4,Bltamod	; Modulo
	Move 	\5,Bltdmod	
	Move.l 	\1,Bltapth	; Source A
	Move.l  \2,Bltdpth	; Combined D
	Move 	\3,Bltsize	; Size
	ENDM

BLITM MACRO
	Move 	\7,Bltafwm	; First Word Mask	
	Move 	\8,Bltalwm	; Last Word Mask
	Move.w  d0,-(sp)
	Move.w	\6,d0		; Shifting

	Rol.w	#6,d0
	Rol.w	#6,d0

	Andi.w	#$f000,d0
	Move.w	d0,Bltcon1
	Addi.w 	#%0000111111001010,d0
	Move.w	d0,Bltcon0
	Move 	\4,Bltamod	; Modulo
	Move	\4,Bltbmod
	Move	\5,Bltcmod
	Move 	\5,Bltdmod	
	Move.l 	\9,Bltapth	; Source A
	Move.l	\1,Bltbpth
	Move.l	\2,Bltcpth
	Move.l  \2,Bltdpth	; Combined D
	Move 	\3,Bltsize	; Size
	Move.w	(sp)+,d0
	ENDM

INTBLIT MACRO
	Move 	#$FFFF,Bltafwm	
	Move 	#$FFFF,Bltalwm
	Move.w 	#%0000100111110000,Bltcon0
	Move 	#0,Bltcon1
	Move 	\1,Bltamod
	Move 	\1,Bltdmod
	ENDM

INTBLITM MACRO
	Move 	#$FFFF,Bltafwm	
	Move 	#$FFFF,Bltalwm
	Move.w 	#%0000111111001010,Bltcon0
	Move 	#0,Bltcon1
	Move 	\1,Bltamod
	Move 	\1,Bltbmod
	Move 	\1,Bltcmod
	Move 	\1,Bltdmod
	ENDM
	
FBLIT	MACRO
	Move.l 	\1,Bltapth
	Move.l  \2,Bltdpth
	Move 	\3,Bltsize
	ENDM	

FBLITM	MACRO
	Move.l 	\1,Bltapth
	Move.l	\2,Bltbpth
	Move.l	\3,Bltcpth
	Move.l  \3,Bltdpth
	Move 	\4,Bltsize
	ENDM	

	
BLOCK MACRO
	Move.l	\1,d0
	Mulu	#4,d0
	Move.l	\2,d1
	Mulu	#1280,d1
	Add.l	d1,d0
	Add.l	\3,d0
	Move.l	\4,d1
	Mulu	#4,d1
	Move.l	\5,d2
	Mulu	#1280,d2
	Add.l	d2,d1 
	Add.l	\6,d1
	
	Cmpi.w	#6,d3
	Bne	\@4
	
	Movem.w	d3-d4,-(SP)

	Move.w	Yoff,d3
	Move.w	#32,d4
	Sub.w	d3,d4
	Bmi	\@4
	
	Lsl.w	#6,d4
	
	Tst.w	d4
	Beq	\@5
	
	Bset	#1,d4

	FBLIT 	d0,d1,d4

	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4

\@5:
	Movem.w	(SP)+,d3-d4
	Bra	\@2	
	
\@4:
	Tst.w	d3
	Bne	\@1
	
	Movem.w	d3-d4,-(SP)

	Move.w	#32,d3
	Move.w	Yoff,d4
	Sub.w	d4,d3
	Bmi	\@3
	
	Lsl.w	#6,d4
	
	Tst.w	d4
	Beq	\@3
	
	Bset	#1,d4

	Mulu	#40,d3
	Add.l	d3,d0
	Add.l	d3,d1

	FBLIT 	d0,d1,d4

	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,d4

\@3:
	Movem.w	(SP)+,d3-d4
	Bra	\@2	

\@1:	
	FBLIT 	d0,d1,#$802

	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLIT 	d0,d1,#$802
\@2:
	ENDM

BLOCKM MACRO
	Move.l	\1,d0		; X
	Mulu	#4,d0
	
	Move.l	\2,d1
	Mulu	#1280,d1	; Y
	
	Add.l	d1,d0		; Final Pos

	Move.l	\7,d5
	Add.l	d0,d5		; Mask Pos
	
	Add.l	\3,d0		; Source Pos
	
	Move.l	\4,d1		; Dest X
	Mulu	#4,d1
	
	Move.l	\5,d2
	Mulu	#1280,d2	* Dest Y
	
	Add.l	d2,d1 
	Add.l	\6,d1	
	
	FBLITM 	d5,d0,d1,#$802

	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLITM 	d5,d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLITM 	d5,d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLITM 	d5,d0,d1,#$802
	
	Add.l	#$8200,d0
	Add.l	#10240,d1
	FBLITM 	d5,d0,d1,#$802
	ENDM

SINE 	MACRO
	Movem.l	d0/a0,-(SP)

	Cmpi.w	#360,d0
	Blo	\@1
	Subi.w	#359,d0
\@1:	
	Lea	Sine_Data,a0
	Mulu	#2,d0
	Move.w	0(a0,d0.w),d1

	Movem.l	(SP)+,d0/a0
	ENDM

COSINE 	MACRO
	Movem.l	d0/a0,-(SP)

	Cmpi.w	#360,d0
	Blo	\@1
	Subi.w	#359,d0
\@1:	
	Lea	Cosine_Data,a0
	Mulu	#2,d0
	Move.w	0(a0,d0.w),d1
	Movem.l	(SP)+,d0/a0
	ENDM

SQROOT	MACRO
	Clr.l	d2
	Move.w  \1,d2
	Clr.l	d1
	Clr.l	d0
\@
	Addi.w	#2,d1
	Addi.w	#1,d0
	Sub.w	d1,d2
	Bpl.s	\@
	ENDM
		
PLOT MACRO
	Clr.l   d0
	Clr.l   d1
	Clr.l	d2
	Move.w  \4,d2	; Plane
    Mulu    #10240,d2	

    Move.l  \3,a0	; Raster Bmap
    Add.l   a0,d2

 	Move    \2,d0	; Y Pos
    Mulu 	#320,d0

    Add     \1,d0	; X Pos
    Divu    #8,d0
    Add	d0,a0
    Swap    d0
   	Sub	#7,d0
    Neg     d0
    Bset    d0,(a0)
    ENDM  	

		
SPLOT MACRO
	Clr.l   d0
    Move.l  \3,a0	; Raster Bmap
        
 	Move    \2,d0	; Y Pos
    Mulu 	#320,d0

    Add     \1,d0	; X Pos
    Divu    #8,d0
    Add	d0,a0
    Swap    d0
   	Sub	#7,d0
    Neg     d0
        
	Move.l	a0,a5

	Btst	d0,(a5)
	Bne	No_Plot

	Adda.l	#10240,a5
	Btst	d0,(a5)
	Bne	No_Plot

	Adda.l	#10240,a5
	Btst	d0,(a5)
	Bne	No_Plot

	Adda.l	#10240,a5	
	Btst	d0,(a5)
	Bne	No_Plot

	Adda.l	#10240,a5
	Btst	d0,(a5)
	Bne	No_Plot

    Bset    d0,(a0)		; White
No_Plot:	
    ENDM  
  	

INSCOP  MACRO
	Move.l  \1,d0
   	Add.l	\3,d0
    Move.l	\2,a0

	COPPER  d0,10(a0),6(a0)
  	Swap    d0
 	Add.l   #10240,d0
	COPPER  d0,18(a0),14(a0)
	Swap    d0
	Add.l   #10240,d0
	COPPER  d0,26(a0),22(a0)
	Swap    d0
 	Add.l   #10240,d0
	COPPER  d0,34(a0),30(a0)
	Swap    d0
	Add.l   #10240,d0
	COPPER  d0,42(a0),38(a0)
	ENDM
	
SPRCOP	MACRO
	Move.l	\1,a0
	Move.l	\2,d0
	COPPER	d0,94(a0),90(a0)
	Move.l	\3,d0
	COPPER	d0,102(a0),98(a0)
	Move.l	\4,d0
	COPPER	d0,110(a0),106(a0)
	Move.l	\5,d0
	COPPER	d0,118(a0),114(a0)
	Move.l	\6,d0
	COPPER	d0,126(a0),122(a0)
	Move.l	\7,d0
	COPPER	d0,134(a0),130(a0)
	Move.l	\8,d0
	COPPER	d0,142(a0),138(a0)
	Move.l	\9,d0
	COPPER	d0,150(a0),146(a0)
	ENDM	

COPPER MACRO
    Move.w  \1,\2
    Swap    \1
    Move.w  \1,\3
    ENDM

COPIN	MACRO
	Move.l  \1,Cop1lch
	ENDM
	
COPON 	MACRO
	Bsr	Wait_VBL
	Move.l  \1,Cop1lch
	Move.w  #%1000011111110000,$dff096  * Turn On Almost Every Thing 
	ENDM

SPRITESOFF MACRO
	Move.w  #%0000000000100000,$dff096
	ENDM
		
SAMPLAY	MACRO   				; start,Length,Volume,Period
	Move.l	\1,$dff0a0			; start
	Move.w	\2,$dff0a4			; length
	Move.w	\3,$dff0a8			; volume
	Move.w	\4,$dff0a6			; period 1Khz = 447 clock ticks
	Move.w	#$8001,$dff096
	ENDM

MTSKOFF MACRO
	Move.l	$4.w,a6
	Jsr	Forbid(a6)
	ENDM
	
MTSKON	MACRO
	Move.l	$4.w,a6
	Jsr	Permit(a6)
	ENDM	

INTON	MACRO
	Move.w	#$C028,Intena
	ENDM
	
INTOFF	MACRO
	Move.w	#$7fff,Intena
	ENDM	
	
KEYSON	MACRO
	Move.w	#$C028,Intena	
	ENDM
	
OLDINT	MACRO
	Move.l	Old_Int,$6c
	ENDM

WAITDBF	MACRO
	ENDM
	
TURNOFFDMA MACRO
	Jsr	Wait_VBL
	Jsr	Fade
	Move.w	#$0080,Dmacon
	ENDM

TURNONDMA MACRO	
	Jsr	Wait_VBL
	Move.w	#$8080,Dmacon
	ENDM	

TURNOFFAUDIO MACRO
	Bsr	Wait_VBL
	Move.w	#%1111,Dmacon
	ENDM

TESTENHANCED MACRO
			
	ENDM
*************************************************
*	Open Libraries 								*
*************************************************
	Move.l  $4.w,a6

	Lea     Gfxname,a1
	Moveq.l #0,d0
	Jsr     Openlib(a6)
	Move.l  d0,Gfxbase

	Lea	Dosname,a1
	Move.l	#0,d0
	Jsr	Openlib(a6)
	Move.l	d0,Dosbase

	Move.l	d0,a6
	Jsr	Output(a6)
	Move.l	d0,Doshandle

	CLOSEF	Doshandle
	
*************************************************	
*	Allocate Memory Needed 						*
*************************************************	

;	Move.l	#Program_Code,$20	; No supervisor
;	Move.w	#$2000,SR			; until we keep 
								; using the DOS
;Program_Code:					; disk routines
;	Move.w	#$2000,SR			

	Move.l	#CPU_Trap,$C
	Move.l	#CPU_Trap,$10
	Move.l	#CPU_Trap,$14
	Move.l	#CPU_Trap,$28
	Move.l	#CPU_Trap,$2C

	MTSKOFF
	INTOFF
	INTON
	
	Jsr Allocate_Raster    		; bitmap allocation
	Jsr	Allocate_Fast

*************************************************
*	Load Data									*
*************************************************
	Jsr	Load_Logo	
	Jsr	Load_Sprites
	Jsr	Fade

Main_Game_Start:
	Jsr	Title_Screen

	*>
;	Jsr	Hi_Score_Table
	*>

	Jsr	Init_New_Addr
	Jsr	Show_Zone

	Move.b	Level,d0
	Cmp.b	Current_Level,d0
	Beq	New_Map
	
	Jsr	Load_Blocks

New_Map:
	Jsr	Init_Addr

	*>
;	Jsr	Load_Music
;	Jsr	mt_init
	*>

	Jsr	Load_Map
	Jsr	Fade

Retry_Another_Life:
	TURNOFFDMA

	Jsr	Clear_Buffers
	Jsr	Recopy_Map_Data

	*>
	Jsr	Set_Int3
	*>

	PRINT	#Panel_Data,#Panel_Data_End-Panel_Data,Panel
	PRINT	#Panel_Vals,#Panel_Vals_End-Panel_Vals,Panel

	JEWELS_UPDATE
	TIME_UPDATE
	ENERGY_UPDATE
	LIVES_UPDATE
	
*************************************************
*	Initialise	 								*
*************************************************
	Bsr	Copper_Setup

	SPRCOP	Copper1,#Back0,#Back1,#Back2,#Back3,#Back4,#Back5,#Back6,#Back7
	SPRCOP	Copper2,#Back0,#Back1,#Back2,#Back3,#Back4,#Back5,#Back6,#Back7

	Move.l	Buffer1,Currbuffer		; Initialise variables for double buffering
	Move.l	Buffer1,Showbuffer	

	COPIN	Copper1

	SETCOPJMP
	TURNONDMA

	Jsr	Flip_Screen					; Flip buffers
	Jsr	Wait_VBL					; Wait VBL

*************************************************
*	Main Loop (Game Loop)			*
*************************************************
Loop:
	Cmpi.b	#2,Energy
	Bls	Not_Dead
	Jsr	Dead_Cat
	Jsr	Restart_Loading			
	Bra	Retry_Another_Life

Not_Dead:
	Cmpi.b	#$df,Keys		; Abort Game
	Beq	Quit_Game			

Test_Bonus:
	Cmpi.b	#$95,Keys		; Test Bonus
	Bne	Test_Next_Level			
	Bsr	Bonus_Checks
						
Test_Next_Level:				
	Tst.w	Level_Complete			
	Bne	Next_Level			
						
	Cmpi.b	#$bf,Keys		; Next Level	
	Bne	Check_Pause			

Next_Level:					
	Jsr Level_Complete_Run		
	Jsr	Restart_Loading			
	Jsr	Give_Bonus			
	Jsr	Increase_File_Names		
	Bra	New_Map				
						
Check_Pause:					
	Cmpi.b	#$CD,Keys		; Pause		
	Bne	No_Pause			
	Jmp	Pause_Game			

No_Pause:	
	Cmp.b	#$b3,Keys		; Debug jump key 'j' allows 
	Bne	No_Jump				; us to jump when in the air
	Move.w	#16,Vely		; for test purposes

No_Jump:	
	Bsr	Check_Hit
	Bsr	Diagonal_Stuff		; Handle plain diagonal surfaces
							
	Tst.w	NMCtr	
	Bne	No_Check			; check if player was ejected from curve/surface
	Bsr	Check_Horizontal_Controls	

No_Check:
	Bsr	Get_Max_Jump
	Bsr	Check_Vertical_Controls		; Check jump and fast descend
	Bsr	Increase_Vel
	Bsr	Change_Vectors				; Handle switching of major axes (x<->y)
	Bsr	Dec_NMCtr					; Manage counters

	Tst.w	Standpfrm
	Bne	No_Vert_Eval
	Bsr	Vertical_Evaluation			; Handle vertical movement

No_Vert_Eval:
	Cmpi.w	#2,Standpfrm
	Beq	No_Execute_B

	Tst.w	Inc_Vel
	Bne	No_Execute
	Bsr	Horizontal_Evaluation		; Handle horizontal movement

No_Execute:
	Bsr	Set_SPtile_Middle

No_Execute_B:
	Bsr	Restore_Vectors				; Restore axes (x<->y)
	Bsr	Get_Final_Velocity			; Get player direction
	Bsr	Check_Brake					; Check if we are currently braking

	Tst.w	Standpfrm
	Bne	No_Surface_Check
	Bsr	Set_SPtile_Down				; Test for surface tiles
	Bsr	Check_Near_Tiles

No_Surface_Check:	
	Bsr	Draw_Blocks			; Draw background blocks (behind player)
	Bsr	Dust_Routine
	Bsr	Eval_Dir			; Determine player sprite direction (where player faces)
	Bsr	Rotate_Hero			; Determine player angle
	Bsr	Draw_Hero			; Draw player bob

	Tst.b 	Do_Mask_Routine
	Beq	No_Draw_FG_Blocks
	Bsr	Draw_FG_Blocks		; Draw foreground blocks (cover player)

No_Draw_FG_Blocks:
	Tst.w	Enemy_Check
	Bne	No_Enemy_Check
	Bsr	Start_Enemies		; Handle enemies

No_Enemy_Check:
	Jsr	Update_Panel
	Jsr	Scroll_Copper

	Bsr	Flip_Screen			; Double buffering
	Bsr	Wait_VBL			; Wait VBL
	Bra     Loop	

*************************************************
*	Routines									*
*************************************************
*************************************************
*	Bonus Checks								*
*************************************************
Bonus_Checks:
	Move.l	#Bonus_Messages,d7

	PRINTAM Showbuffer,#0,#3,d7,#80
	WAIT_FIRE
	Rts

*************************************************
*************************************************
Get_Max_Jump:
	Move.w	Xjump,d0
	Move.w	Yjump,d1
	
	Cmpi.w	#$7fff,d0
	Bls	Now_YJump
	Neg.w	d0

Now_YJump:	
	Cmpi.w	#$7fff,d1
	Bls	Now_PJump
	Neg.w	d1

Now_PJump:	
	Cmp.w	d0,d1
	Bne	PJump_2
	Move.w	#0,Max_Jump
	Rts

PJump_2:
	Tst.w	d0
	Beq	Set_Max
	
	Tst.w	d1
	Beq	Set_Max
	
	Move.w	#1,Max_Jump
	Rts

Set_Max:
	Move.w	#2,Max_Jump
	Rts	
	
*************************************************
*	Abort game in progress						*
*************************************************
Quit_Game:
	PRINT	#Quit_Text,#Quit_Text_End-Quit_Text,Panel
	Bsr	Restart_Loading
	Bra	Main_Game_Start

*************************************************
*	Handles death sequence (lose a life)		*
*************************************************
Dead_Cat:
	Move.w	#$FFF0,d0
	Move.w	#$FFFF,Vely

	Clr.b	Spin
	Clr.b	Slide
	Clr.b	Braking
	Clr.b	Super_Run
	Clr.b	Invulnerable	
	Clr.b	Whoopie
	Clr.b	Ext_Whoopie

	Clr.w  	Velx
	Clr.w	YFlip
	Clr.w	Surface
	Clr.w	XORFrame
	Clr.w	Left_Blocked
	Clr.w	Right_Blocked
	
Die_Loop:
	Addi.w	#1,d0
	Add.w	d0,YChar
	Move.w	#1,Hit

	Move.w	d0,-(SP)
	Jsr	Draw_Blocks			; Draw blocks
	Jsr	Draw_Hero			; Draw player
	Jsr	Start_Enemies		; Handle enemies

	Jsr	Scroll_Copper
	Jsr	Flip_Screen			; Double buffering
	Jsr	Wait_VBL			; VBL

	Move.w	(SP)+,d0

	Cmpi.w	#224,YChar
	Blo	Die_Loop

	Subi.b	#1,Lives
	Move.b	Start_Energy,Energy

	Move.w	#1,Stand
	Move.w	#999,Time
	Move.w	#127,YChar
	
	Move.w	XStartb,Xoff
	Move.w	YStartb,Yoff
	Move.l	XStart,Xmap
	Move.l	YStart,Ymap

	Jsr	Life_Lost_Reset
	Rts	

*************************************************
*	Animation on level complete (player exits 	*
*	screen from right hand side)				*
*************************************************
Level_Complete_Run:
	Clr.b	Invulnerable
	Clr.b	Slide
	Clr.b	Spin
	Clr.b	Braking
	Clr.b	Super_Run
	Clr.w	Surface
	Move.w	#$FFF8,Velx
	Move.w	#1,Dir

Level_Complete_Loop:	
	Bsr	Draw_Blocks			; Draw blocks
	Bsr	Draw_Hero			; Draw player

	Jsr	Scroll_Copper
	Bsr	Flip_Screen			; Double buffer
	Bsr	Wait_VBL			; VBL

	Addi.w	#8,XChar
	Cmpi.w	#288,XChar
	Bls	Level_Complete_Loop

	Move.w	#144,XChar
	Rts

*************************************************
*	Rewards for slick play 						*
*************************************************
Give_Bonus:
	OPENF	#Copper3_Name,#Old_Mode
	READF	Handle,Copper1,#3380
	CLOSEF	Handle

	OPENF	#Copper3_Name,#Old_Mode
	READF	Handle,Copper2,#3380
	CLOSEF  Handle

	Move.l	Buffer1,Currbuffer
	Move.l	Buffer2,Showbuffer

	INSCOP	Buffer1,Copper1,#0
	INSCOP	Buffer2,Copper2,#0
	COPON   Copper1
	
	Jsr	Wait_VBL

	TURNONDMA
	LOADPIC	#Overview_Name,#40960

	Jsr	Clear_Text_Buffers
	PRINTAT	Showbuffer,#0,#5,#Bonus,#Bonus_End-Bonus,#40960
	Jsr	Copy_Buffers
	Moveq.l	#0,d7
	
Bonus_Loop:
	Jsr	Parallax_Scroll
	Jsr	Sin_Title
	Jsr	Flip_Screen
	Jsr	Wait_VBL
	
	Btst	#7,Mousekey
	Bne	Bonus_Loop

	Move.l	Copper1,Fading_Copper
	Bsr	Copper_Fade

	Move.l	Copper2,Fading_Copper
	Bsr	Copper_Fade
	
	Bsr	Clear_Buffers
	Rts
 
*************************************************
*	Fade out and restart loading				*
*************************************************
Restart_Loading:
	Move.l	Copper1,Fading_Copper
	Jsr	Copper_Fade

	Move.l	Copper2,Fading_Copper
	Jsr	Copper_Fade

	Jsr	Clear_Buffers

	TURNOFFDMA
	TURNOFFAUDIO
	SETDUMMYCOP	

	INTOFF
	OLDINT
	INTON

	Rts

*************************************************
*	Player collision test 						*
*************************************************
Check_Hit:
	Cmpi.w	#1,Hit
	Beq	Hit_Player_Character
	Rts	

Hit_Player_Character:
	Move.w	#1,Jump
	Move.w	#1,IJump
	Move.w	#4,NMCtr2
	Move.w	#25,NMCtr
	Move.w	Cf_Hit_Vely,Vely
	Move.w	#2,Hit
	Move.b	#100,Invulnerable
	Subi.b	#1,Energy

	Clr.b	Slide
	Clr.b	Spin
	Clr.b	Spring
	Clr.b	Crouch
	Clr.w	Inc_Vel
	Clr.w	XORFrame
	Clr.w	YFlip

	ENERGY_UPDATE

	Tst.w	Dir
	Beq	Fly_Opp
	Move.w	Cf_Hit_Velx_Lt,Velx
	Rts
Fly_Opp:	
	Move.w	Cf_Hit_Velx_Rt,Velx
	Rts

*************************************************
*	Handle enemy animation counters 			*
*************************************************
Start_Enemies:
	Addi.w	#1,Enemy_Anim_Ctr		; Compute enemy animations
	Cmpi.w	#11,Enemy_Anim_Ctr		; and update frame counters
	Bls	Next_Function				
	Clr.w	Enemy_Anim_Ctr

Next_Function:
	Clr.w	Standpploop
	
	Moveq.w	#4,d7
	Move.w	Estart,d6
	Mulu	#4,d6

	Lea	Enmx,a0
	Lea	0(a0,d6.w),a0
	
	Lea	Enmy,a1
	Lea	0(a1,d6.w),a1

	Divu	#2,d6

	Lea	Enmt,a2
	Lea	0(a2,d6.w),a2
	
	Lea	Enmvx,a3
	Lea	0(a3,d6.w),a3
	
	Lea	Enmvy,a4
	Lea	0(a4,d6.w),a4

	Lea	Enmpfrm,a5
	Lea	0(a5,d6.w),a5

Draw_Enemies:
	Move.l	(a0)+,Cenmx
	Move.l	(a1)+,Cenmy
	Move.w	(a2)+,Cenmt
	Move.w	(a3)+,Cenmvx
	Move.w	(a4)+,Cenmvy
	Move.w	(a5)+,Cenmpfrm

*************************************************
*	Determine enemy type and function 			*
*************************************************
Type_And_Function:
	Moveq.l	#0,d0
	Moveq.l	#0,d1
	Moveq.l	#0,d2
	Moveq.l	#0,d3
	Moveq.l	#0,d4
	Moveq.l	#0,d5

	Clr.b	Pend_Bob
	Clr.b	Destructable
	Clr.b	Enemy_Fire_Pause

	Clr.l	Savecx
	Clr.l	Savecy
	
	Cmpi.w	#$FFFE,Cenmt
	Bhs	Last_Type
	
*************************************************
*	$01 - Lava fish								*
*************************************************
	Tst.w	Cenmt
	Bne	Type_2

	ENSIZE	#20,#2,#$500,#$802,#36		; Size
	COLSIZE	#136,#168,#96,#158			; Collision size, detection

	Move.w	#9,Hit_Vely					; Collision response
	Move.w	#7,Hit_Velx_Lt				; when player collides
	Move.w	#$FFF9,Hit_Velx_Rt			; with enemy

	Lea	Enemy_Anim,a6					; Animation
	Move.w	Enemy_Anim_Ctr,d5
	Move.b	72(a6,d5),d5
	Move.w	d5,Enemy_Frame

	Bsr	Get_Enemy_Mpos					; Map position 
	Bsr	Give_Enemy_Offsets				; Offset from screen origin
	Bsr	Draw_Bob
	Bsr	Check_Coll

	ENSIZE	#20,#2,#$280,#$402,#36

	Subi.l	#$F,Offey					
	Move.w	#$D1,Enemy_Frame
	Bsr	Draw_Bob

****> Calculations For Motion

	Addi.w	#1,Cenmvy		; Position

	Cmpi.b	#177,d1			; Test collision with map
	Bne	Set_Enemy1_Velocity

	Move.w	Cenmvx,Cenmvy	

Set_Enemy1_Velocity:
	Move.w	Cenmvy,d0
	Move.w	d0,-(a4)
	Ext.l	d0
	Add.l	d0,-(a1)

	Adda.l	#4,a1
	Adda.l	#2,a4
	Bra	All_Work_Over

****> Calc. For Motion

*************************************************
*	$02 - Pendulum 								*
*************************************************
Type_2:
	Cmpi.w	#1,Cenmt
	Bne	Type_3

	ENSIZE	#20,#2,#$280,#$402,#36		; Enemy size

	Move.w	#10,Enemy_Frame				; Animation frame
	Move.w	#6,Hit_Vely					; Collision response
	Move.w	#5,Hit_Velx_Lt
	Move.w	#$FFFB,Hit_Velx_Rt

****> Calculation For Motion

	Lea	Velocities,a6
	Move.w	d7,d1
	Add.w	Estart,d1
	
	Mulu	#2,d1
	Move.w	0(a6,d1.w),d0

	Add.w	d0,-(a4)
	
	Cmpi.w	#180,(a4)
	Bhi	Dec_Velocity

	Addi.w  #1,d0
	Bra	No_Angle_Calc

Dec_Velocity:
	Subi.w	#1,d0

No_Angle_Calc:
	Move.w	d0,0(a6,d1.w)				; Restore velocity

****> Calc. For Motion

	Move.w	(a4)+,Angle					
	Move.w	Cenmvx,d6					
	Move.l	#8,Savecy					
	Move.w	#4,Bob_Frame				
	Move.w	#20,CSize					
	
	Bsr	Do_Pendulum
	Bsr	Check_Coll
	Bra	Position_Work_Over

*************************************************
* 	$03 - Moving platform 						*
*************************************************
Type_3:
	Cmpi.w	#2,Cenmt
	Bne	Type_4

	ENSIZE	#10,#4,#$500,#$803,#34
	Move.w	#7,Enemy_Frame		

	Bsr	Get_Enemy_Mpos		
	Bsr	Check_Enemy_Tiles	
	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		
	Bsr	Work_Early_Position

	Move.w	#8,Enemy_Frame		
	Addi.l	#32,Offex
	Bsr	Draw_Bob		
	Subi.l	#32,Offex
	
	Move.w	#1,d6			
	Bsr	Check_Lifts

	Bra	Position_Work_Over	

*************************************************
* 	$04 - Enemy 								*
*************************************************
Type_4:	
	Cmpi.w	#3,Cenmt
	Bne	Type_5

****> Enemy Fire Routine
	Move.l	Cenmx,d2
	Move.l	Cenmy,d3

	Move.w	Cenmvx,d0
	Ext.l	d0

	Mulu.w	#3,d0
	Move.w	d0,Enemy_Fire_Dirx
	Clr.w	Enemy_Fire_Diry

	Bsr	Enemy_Fire		; Is enemy going to fire?

	Move.l	d2,Cenmx
	Move.l	d3,Cenmy

****> Enemy Fire Routine

	ENSIZE	#10,#4,#$500,#$803,#34
	COLSIZE	#118,#170,#102,#154
	
	Move.w	#6,Hit_Vely			
	Move.w	#5,Hit_Velx_Lt		
	Move.w	#$FFFB,Hit_Velx_Rt	

	Lea	Enemy_Anim,a6		
	Move.w	Enemy_Anim_Ctr,d5	
	Move.b	(a6,d5),d5
	Move.w	d5,Enemy_Frame
	Move.b	#1,Destructable

	Bsr	Get_Enemy_Mpos
	Bsr	Check_Enemy_Tiles	
	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		
	Bsr	Check_Coll

	Tst.b	Enemy_Fire_Pause	; Show that enemy is about to fire	
	Bne	All_Work_Over		

	Bra	Work_New_Position	

*************************************************
* 	$05 - Water platforms						*
*************************************************
Type_5:
	Cmpi.w	#4,Cenmt
	Bne	Type_6

	ENSIZE	#10,#4,#$500,#$803,#34	
	
	Lea	Enemy_Anim,a6		
	Move.w	Enemy_Anim_Ctr,d5	
	Lea	12(a6),a6		
	Move.b	(a6,d5),d5
	Ext.w	d5
	Move.w	d5,Enemy_Frame

	Bsr	Get_Enemy_Mpos
	Bsr	Check_Enemy_Tiles	
	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		
	Bsr	Work_Early_Position
	Bsr	Lifts
	Bra	Position_Work_Over

*************************************************
*	$05 - Fish									*
*************************************************
Type_6:
	Cmpi.w	#5,Cenmt
	Bne	Type_7

	ENSIZE	#10,#4,#$500,#$803,#34		
	COLSIZE	#118,#170,#102,#154			
	
	Move.w	#6,Hit_Vely					
	Move.w	#5,Hit_Velx_Lt		
	Move.w	#$FFFB,Hit_Velx_Rt

	Move.b	#1,Destructable				
	Clr.w	Cenmpfrm					

	Move.w	-(a5),d5					
	Addi.w	#1,d5
	Move.w	d5,(a5)+
	
	Lea	Enemy_Anim,a6					
	Move.b	84(a6,d5),d5
	Move.w	d5,Enemy_Frame

	Bsr	Get_Enemy_Mpos
	Bsr	Give_Enemy_Offsets
	Bsr	Draw_Bob
	Bsr	Check_Coll

****> Calculations For Motion

	Addi.w	#1,Cenmvy					
	Cmpi.b	#177,d1						
	Bne	Set_Enemy2_Velocity

	Move.w	Cenmvx,Cenmvy	
	Clr.w	-(a5)
	Adda.l	#2,a5

Set_Enemy2_Velocity:
	Move.w	Cenmvy,d0
	Move.w	d0,-(a4)
	Ext.l	d0
	Add.l	d0,-(a1)

	Adda.l	#4,a1
	Adda.l	#2,a4
	Bra	All_Work_Over

**** Calc. For Motion

*************************************************
* 	$06 - Pendulum 								*
*************************************************
Type_7:
	Cmpi.w	#6,Cenmt
	Bne	Type_8

	ENSIZE	#20,#2,#$280,#$402,#36	
	
	Move.w	#10,Enemy_Frame		
	Move.w	#6,Hit_Vely		
	Move.w	#5,Hit_Velx_Lt
	Move.w	#$FFFB,Hit_Velx_Rt

	Lea	Angles,a6			; Load angle table 1 -> a6
	Move.w	d7,d1			; Get word offset
	Add.w	Estart,d1
	
	Mulu	#2,d1			
	Move.w	0(a6,d1.w),d0	; Push angle in D0

	Add.w	Cenmvy,d0		

	Cmpi.w	#359,d0			
	Bls	No_Revolution		
	Subi.w	#360,d0			

No_Revolution:	
	Move.w	d0,0(a6,d1.w)	

	Move.l	#8,Savecy		
	Move.w	#4,Bob_Frame	
	Move.w	#20,CSize		
	Move.w	Cenmvx,d6		
	Move.w	d0,Angle		

	Bsr	Do_Pendulum
	Bsr	Check_Coll
	Bra	Position_Work_Over

*************************************************
* 	$07 - Bird  								*
*************************************************
Type_8:
	Cmpi.w	#7,Cenmt
	Bne	Type_9

***> For Fire Routine
	Move.l	Cenmx,d2
	Move.l	Cenmy,d3

	Move.w	Cenmvx,Enemy_Fire_Dirx
	Move.w	#2,Enemy_Fire_Diry

	Bsr	Enemy_Fire		

	Move.l	d2,Cenmx
	Move.l	d3,Cenmy

***> For Fire Routine

	ENSIZE	#10,#4,#$500,#$803,#34
	COLSIZE	#134,#182,#102,#154
	
	Move.w	#6,Hit_Vely		
	Move.w	#5,Hit_Velx_Lt
	Move.w	#$FFFB,Hit_Velx_Rt
	
	Lea	Enemy_Anim,a6		
	Move.w	Enemy_Anim_Ctr,d5
	Lea	36(a6),a6
	Move.b	(a6,d5),d5
	Move.w	d5,Enemy_Frame

	Cmpi.w	#$7fff,Cenmvx	
	Bhi	Right_Dir_A
	Addi.w	#8,Enemy_Frame

Right_Dir_A:
	Bsr	Get_Enemy_Mpos
	Bsr	Check_Enemy_Tiles	
	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		

	Move.b	#1,Destructable
	Addi.w	#1,Enemy_Frame
	Addi.l	#32,Offex

	Bsr	Draw_Bob		
	Bsr	Check_Coll

	Tst.b	Enemy_Fire_Pause
	Bne	All_Work_Over
	Bra	Work_New_Position	

*************************************************
* 	$08 - Bee	  								*
*************************************************
Type_9:
	Cmpi.w	#8,Cenmt
	Bne	Type_10

***> For Fire Routine
	Move.l	Cenmx,d2
	Move.l	Cenmy,d3

	Move.w	Cenmvx,d0
	Ext.l	d0
	
	Muls.w	#3,d0
	Move.w	d0,Enemy_Fire_Dirx
	Move.w	#3,Enemy_Fire_Diry

	Bsr	Enemy_Fire

	Move.l	d2,Cenmx
	Move.l	d3,Cenmy

***> For Fire Routine

	ENSIZE	#10,#4,#$500,#$803,#34
	COLSIZE	#118,#170,#102,#154
	
	Move.w	#6,Hit_Vely
	Move.w	#5,Hit_Velx_Lt
	Move.w	#$FFFB,Hit_Velx_Rt
	Move.b	#1,Destructable		
	
	Move.w	#34,Enemy_Frame
	Move.w	Flick_Ctr,d0
	Add.w	d0,Enemy_Frame

	Tst.w	Cenmvx
	Bne	Enemy_Not_Still_A

	Addi.w	#23,Enemy_Frame
	Bra	Right_Dir_B

Enemy_Not_Still_A:
	Cmpi.w	#$7fff,Cenmvx
	Bhi	Right_Dir_B
	Addi.w	#2,Enemy_Frame

Right_Dir_B:	
	Bsr	Get_Enemy_Mpos
	Bsr	Check_Enemy_Tiles
	Bsr	Give_Enemy_Offsets
	Bsr	Draw_Bob
	Bsr	Check_Coll

	Tst.b	Enemy_Fire_Pause
	Bne	All_Work_Over
	Bra	Work_New_Position

*************************************************
* 	$09 - Crusher	  							*
*************************************************
Type_10:
	Cmpi.w	#9,Cenmt
	Bne	Type_11

	Bsr	Give_Enemy_Offsets	
	ENSIZE	#20,#2,#$500,#$402,#36	
	Move.w	#108,Enemy_Frame
	
	Move.w	-(a3),d0		
	Move.w	-(a4),d1		
	Ext.l	d0			
	Ext.l	d1			

	Cmp.l	d0,d1
	Bgt	Crusher_Limit_A

	Move.l	d1,d2
	Bra	Crusher_Limit_B

Crusher_Limit_A:
	Move.l	d0,d2

Crusher_Limit_B:
	Divu	#16,d2
	Ext.l	d2
	Move.l	Offey,d3
	
Crusher_Loop:	
	Bsr	Draw_Bob
	Addi.l	#16,Offey
	Dbra	d2,Crusher_Loop

	ENSIZE	#10,#4,#$280,#$403,#34	
	Move.l	d3,Offey

	Cmp.l	d0,d1			
	Bgt	No_Return_Up		

	Add.l	d1,Offey		
	Subi.w	#4,d1			
	Bpl	Crusher_Calc_Ready	

	Move.w	d0,d1		 
	Moveq.l	#0,d0
	Bra	Crusher_Calc_Ready

No_Return_Up:		
	Tst.l	d0
	Bne	Not_Top_Pos
	
	Move.w	Game_Timer_A,d2
	Andi.w	#$7F,d2
	Cmpi.w	#$70,d2
	Blo	Crusher_Calc_Ready

Not_Top_Pos:		
;	COLSIZE	#120,#168,#112,#160

	Add.l	d0,Offey		
	Addi.w	#4,d0			
	
Crusher_Calc_Ready:	
	Move.w	d0,(a3)+
	Move.w	d1,(a4)+

	Subi.l	#8,Offex
	Move.w	#115,Enemy_Frame
	Bsr	Draw_Bob
	
	Bra	All_Work_Over

*************************************************
* 	$0A - Pendulum platform  					*
*************************************************
Type_11:
	Cmpi.w	#10,Cenmt
	Bne	Type_12

	ENSIZE	#20,#2,#$280,#$402,#36
	Move.w	#1,Cenmpfrm

	Lea	Velocities,a6
	Move.w	d7,d1
	Add.w	Estart,d1
	
	Mulu	#2,d1
	Move.w	0(a6,d1.w),d0

	Add.w	d0,-(a4)
	
	Cmpi.w	#180,(a4)
	Bhi	Dec_Velocity_B

	Addi.w  #1,d0
	Bra	No_Angle_Calc_B

Dec_Velocity_B:
	Subi.w	#1,d0

No_Angle_Calc_B:
	Move.w	d0,0(a6,d1.w)			

	Move.w	(a4)+,Angle			
	Move.w	Cenmvx,d6			
	Move.w	#11,Enemy_Frame
	Move.w	#20,CSize
	Move.w	#62,Bob_Frame
	Bsr	Do_Pendulum

	Move.w	Angle,Dummy_Angle
	Move.w	d0,Dummy_Velocity
	Bsr	Get_Lift_Velocities
	Bsr	Velocity_Lifts
	Bra	Position_Work_Over

*************************************************
* 	$0B - Dino spring  							*
*************************************************
Type_12:
	Cmpi.w	#11,Cenmt
	Bne	Type_13

	ENSIZE	#20,#2,#$280,#$402,#36
	Move.w	#228,Enemy_Frame

	Move.w	#66,Bob_Frame		
	Move.w	#16,CSize		
	Move.w	Cenmvx,d6		
	Move.w	#0,Angle
	
	Bsr	Do_Pendulum

	Move.w	#0,Dummy_Angle		
	Move.w	Cenmvy,Dummy_Velocity   
	Bsr	Get_Lift_Velocities
	Bsr	Velocity_Lifts

	Tst.w	Standpfrm
	Beq	Position_Work_Over	

	Cmp.w	Platform_Number,d7
	Bne	Position_Work_Over	

	Tst.w	Standpfrmon
	Bne	Position_Work_Over	

	Bra	Position_Work_Over	

*************************************************
* 	$0C - Crumbling platforms 					*
*************************************************
Type_13:
	Cmpi.w	#12,Cenmt
	Bne	Type_14

	ENSIZE	#10,#4,#$280,#$403,#34	
	Move.w	#2,Enemy_Frame

	Lea	Enemy_Anim,a6
	Move.w	Cenmvy,d5
	Lea	120(a6),a6
	Move.b	(a6,d5),d5
	Move.w	d5,Enemy_Frame

	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		

	Move.w	Cenmvy,d0
	Move.w	d0,-(a4)
	Ext.l	d0
	Add.l	d0,-(a1)
	Move.l	(a1),Cenmy

	Clr.w	Cenmvx
	Bsr	Lifts

	Tst.w	Cenmvy
	Bne	Now_Go_On_Falling

	Tst.w	Standpfrm
	Beq	Position_Work_Over
	
 	Cmp.w	Platform_Number,d7
	Bne	Position_Work_Over
	
Now_Go_On_Falling:
	Tst.w	-(a3)
	Beq	Platform_Fall_A

	Subi.w	#1,(a3)
	Suba.l	#2,a0
	Bra	Position_Work_Over	

Platform_Fall_A:
	Suba.l	#2,a0
	Addi.w	#1,(a4)
	Move.w	#3,(a3)

	Cmpi.w  #11,(a4)
	Bls	Position_Work_Over

	Move.w	#$FFFF,-(a2)
	Adda.l	#2,a2
	Bra	Position_Work_Over	

*************************************************
* 	$0D - Rolling boulders 						*
*************************************************
Type_14:
	Cmpi.w	#13,Cenmt
	Bne	Type_15

	ENSIZE	#10,#4,#$500,#$803,#34
	COLSIZE	#118,#170,#102,#154
	Move.w	#6,Hit_Vely
	Move.w	#5,Hit_Velx_Lt
	Move.w	#$FFFB,Hit_Velx_Rt


	Move.w	Flick_Ctr,Enemy_Frame
	
	Tst.b	d1
	Beq	Nothing_Beneath

	Cmpi.b	#1,d1
	Bne	Nothing_Beneath
	
	Cmpi.w	#$7FFF,Cenmvy
	Blo	Nothing_Beneath
	
	Neg.w	Cenmvy
	Ori.w	#%111,Cenmvy
	
Nothing_Beneath:
	Addi.w	#1,Cenmvy

	Bsr	Get_Enemy_Mpos
	Bsr	Check_Enemy_Tiles	
	Bsr	Give_Enemy_Offsets	

	Subi.l	#32,Offey
	Bsr	Draw_Bob		
	Bsr	Check_Coll
	
	Bra	Work_New_Position

*************************************************
* 	$0E - Rotating lift  						*
*************************************************
Type_15:	
	Cmpi.w	#14,Cenmt
	Bne	Type_16

	ENSIZE	#20,#2,#$280,#$402,#36
	Move.w	#11,Enemy_Frame

	Lea	Angles,a6			
	Move.w	d7,d1			
	Add.w	Estart,d1
	
	Mulu	#2,d1			
	Move.w	0(a6,d1.w),d0	

	Add.w	Cenmvy,d0		

	Cmpi.w	#360,d0			
	Blo	No_Revolution_C		
	Subi.w	#359,d0			
	
No_Revolution_C:
	Move.w	d0,0(a6,d1.w)	

	Move.w	#62,Bob_Frame	
	Move.w	#20,CSize		
	Move.w	Cenmvx,d6		
	Move.w	d0,Angle
	
	Bsr	Do_Pendulum

	Move.w	d0,Dummy_Angle	
	Move.w	Cenmvy,Dummy_Velocity   
	Bsr	Get_Lift_Velocities
	Bsr	Velocity_Lifts
	Bra	Position_Work_Over	

*************************************************
* 	$10 - Lava flow	  							*
*************************************************
Type_16:
	Cmpi.w	#15,Cenmt
	Bne	Type_17

	ENSIZE	#10,#4,#$280,#$403,#34
	COLSIZE #112,#170,#112,#160

	Move.w	#6,Hit_Vely
	Move.w	#$FFF9,Hit_Velx_Lt
	Move.w	#$FFF9,Hit_Velx_Rt

	Bsr	Give_Enemy_Offsets	
	Addi.l	#16,Offey	
	Addi.l	#16,Offex

	Clr.w	Cenmpfrm
	Move.w	Cenmvy,d2

	Cmpi.w	#1,-(a5)		; Has lava already started flowing?
	Beq	Scroll_Lava			; Yes
	Bhi	Lava_Frame_Update
	
	Move.l	Xmap,d0			; No, but can it start?
	Mulu	#32,d0
	
	Cmp.l	Cenmx,d0		; No!
	Blo	Lava_Frame_Update
	Move.w	#1,(a5)			; Fry him!
	
Scroll_Lava:
	Addi.l	#4,-(a0)
	Subi.w	#4,-(a3)
	Bpl	Lava_Update

	Clr.w	(a3)
	Move.w	#2,(a5)
	
Lava_Update:	
	Move.l	(a0)+,Lava_Anim_X
	Move.l	Cenmy,Lava_Anim_Y
	Addi.l	#16,Lava_Anim_Y
	Adda.l	#2,a3

Lava_Frame_Update:	
	Lea	Enemy_Anim,a6
	Move.w	Enemy_Anim_Ctr,d5
	Lea	132(a6),a6
	Move.b	(a6,d5),d5

Lava_Loop:	
	Move.w	d5,Enemy_Frame
	Bsr	Draw_Bob

	Bsr	Check_Coll
	Subi.l	#32,Offex
	Move.w	#123,Enemy_Frame
	Bsr	Draw_Bob

	Addi.l	#16,Offex
	Subi.l	#16,Offey
	Dbra	d2,Lava_Loop

Do_No_Lava:
	Adda.l	#2,a5
	Bra	All_Work_Over

Type_17:
*************************************************
*	Explosion/Enemy Death						*
*************************************************
Last_Type:
	Cmpi.w	#$FFFE,Cenmt
	Beq	Dying_Enemy
	Bsr	Dead_Enemy_Fire
	Bra	All_Work_Over
	
Dying_Enemy:
	ENSIZE	#10,#4,#$500,#$803,#34
	
	Move.w	-(a5),d0
	Addi.w	#1,d0
	Move.w	d0,(a5)+

	Lea	Enemy_Anim,a6
	Lea	48(a6),a6
	Move.b	(a6,d0),d1
	Ext.w	d1
	Move.w	d1,Enemy_Frame

	Bsr	Give_Enemy_Offsets	
	Bsr	Draw_Bob		

	Cmpi.w	#22,d0
	Bls	Dead_Enemy
	Move.w	#$FFFF,-(a2)
	Adda.l	#2,a2
	
Dead_Enemy:
	Bsr	Dead_Enemy_Fire
	Bra	All_Work_Over

*************************************************
*	Work Out New Enemy Postion					*
*************************************************
Work_New_Position:
	Move.w	Cenmvx,d0
	Move.w	d0,-(a3)
	Ext.l	d0
	Add.l	d0,-(a0)

Work_New_Position_Y:
	Move.w	Cenmvy,d0
	Move.w	d0,-(a4)
	Ext.l	d0
	Add.l	d0,-(a1)

*************************************************
*	Terminate Enemy Loop Here					*
*************************************************
Position_Work_Over:	
	Adda.l	#4,a0
	Adda.l	#4,a1
	Adda.l	#2,a3
	Adda.l	#2,a4
	
All_Work_Over:	
	Dbra	d7,Draw_Enemies
	Rts

*************************************************
*	Get Enemy Position Relative To Map			*
*************************************************
Get_Enemy_Mpos:
	Move.l	Cenmx,d0
	Divu	#32,d0
	Andi.l	#$ffff,d0	

	Cmp.l 	Xmax,d0
	Bls	Not_GMX
	Move.l	Xmax,d0

Not_GMX:	
	Move.l	Cenmy,d1
	Divu	#32,d1
	Andi.l	#$ffff,d1
	
	Cmp.l 	Ymax,d1
	Bls	Not_GMY
	Move.l	Ymax,d1

Not_GMY:	
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Moveq.l	#0,d1

	Move.l	Map,a6
	Move.l	SMap,d2

	Lea	8(a6,d2.l),a6
	Move.b	0(a6,d0.l),d1
	Rts

*************************************************
*	Enemy firing logic 							*
*************************************************
Dead_Enemy_Fire:
	Movem.l	d0-d6/a0-a4,-(SP)
	Lea	Fire_Toggle,a0
	Lea	Enemy_Fire_X,a1
	Lea	Enemy_Fire_Y,a2
	Lea	Enemy_Fire_VX,a3
	Lea	Enemy_Fire_VY,a4

	Move.l	d7,d2			; d7 -> d2
	Mulu	#2,d2 			; d7 * 2
	
	Move.l	d7,d3			; d7 -> d3
	Mulu	#4,d3			; d7 * 4

	Cmpi.b	#1,0(a0,d7)
	Bne	Forget_Fire
	
	Move.w	0(a3,d2),d0		; BVX
	Ext.l	d0
	
	Move.w	0(a4,d2),d1		; BVY
	Ext.l	d1

	Add.l	d0,0(a1,d3)		; BVX + BX
	Bmi	Forget_Fire			; BX<0?

	Add.l	d1,0(a2,d3)		; BVY + BY
	Bmi	Forget_Fire			; BY<0?

	Move.l	0(a1,d3),Cenmx
	Move.l	0(a2,d3),Cenmy
	Bsr	Give_Enemy_Offsets

	Cmpi.l	#304,Offex
	Bhi	Forget_Fire

	Cmpi.l	#240,Offey
	Bhi	Forget_Fire

	ENSIZE	#20,#2,#$280,#$402,#36
	COLSIZE	#136,#168,#114,#154	* Collision Size,Detection
	
	Move.w	#30,Enemy_Frame
	Move.w	Flick_Ctr,d0
	Add.w	d0,Enemy_Frame

	Bsr	Draw_Bob
	Bsr	Check_Coll
	Movem.l	(SP)+,d0-d6/a0-a4
	Rts

Forget_Fire:
	Clr.b	0(a0,d7)
	Movem.l	(SP)+,d0-d6/a0-a4	
	Rts

*************************************************
*	Enemy firing logic							*
*************************************************
Enemy_Fire:
	Movem.l	d0-d6/a0-a4,-(SP)
	Lea	Fire_Toggle,a0
	Lea	Enemy_Fire_X,a1
	Lea	Enemy_Fire_Y,a2
	Lea	Enemy_Fire_VX,a3
	Lea	Enemy_Fire_VY,a4

	Move.l	d7,d2		; d7 -> d2
	Mulu	#2,d2 		; d7 * 2
	
	Move.l	d7,d3		; d7 -> d3
	Mulu	#4,d3		; d7 * 4

	Tst.b	0(a0,d7)
	Beq	No_Fire

	Cmpi.b	#1,0(a0,d7)
	Bhi	Going_To_Fire
	
	Move.w	0(a3,d2),d0	* BVX
	Ext.l	d0
	
	Move.w	0(a4,d2),d1	* BVY
	Ext.l	d1

	Add.l	d0,0(a1,d3)	* BVX + BX
	Bmi	Untoggle_Fire	* BX<0?

	Add.l	d1,0(a2,d3)	* BVY + BY
	Bmi	Untoggle_Fire	* BY<0?

	Move.l	0(a1,d3),Cenmx
	Move.l	0(a2,d3),Cenmy
	Bsr	Give_Enemy_Offsets

	Cmpi.l	#304,Offex
	Bhi	Untoggle_Fire

	Cmpi.l	#240,Offey
	Bhi	Untoggle_Fire

	ENSIZE	#20,#2,#$280,#$402,#36
	COLSIZE	#136,#168,#114,#154	* Collision Size,Detection
	
	Move.w	#30,Enemy_Frame
	Move.w	Flick_Ctr,d0
	Add.w	d0,Enemy_Frame

	Bsr	Draw_Bob
	Bsr	Check_Coll
	Movem.l	(SP)+,d0-d6/a0-a4
	Rts
	
No_Fire:
	Move.w	Game_Timer_A,d0
	Cmpi.b	#$F0,d0
	Blo	Untoggle_Fire

	Move.b	#10,0(a0,d7)	

	Move.l	Cenmx,d0
	Add.l	#8,d0

	Move.l	Cenmy,d1
	Add.l	#8,d1

	Move.l	d0,0(a1,d3)
	Move.l	d1,0(a2,d3)
	
	Move.w	Enemy_Fire_Dirx,0(a3,d2)
	Move.w	Enemy_Fire_Diry,0(a4,d2)
	Movem.l	(SP)+,d0-d6/a0-a4
	Rts

Untoggle_Fire:
	Clr.b	0(a0,d7)
	Movem.l	(SP)+,d0-d6/a0-a4	
	Rts

Going_To_Fire:
	Subi.b	#1,0(a0,d7)
	Move.b	#1,Enemy_Fire_Pause
	Movem.l	(SP)+,d0-d6/a0-a4
	Rts
		
*************************************************
*	Useful helper for pendulums!				*
*************************************************
Get_Lift_Velocities:	
	Move.w	Cenmvx,d2
	Addi.w	#1,d2
	Move.w	Dummy_Angle,d0
	Add.w	Dummy_Velocity,d0

	SINE

	Muls.w	CSize,d1	
	Muls.w	d2,d1		
	
	Divs.w	#1000,d1	
	Ext.l	d1			
	Add.l	(a0),d1		
	Sub.l	Cenmx,d1
	Move.w	d1,Cenmvx

	COSINE

	Muls.w	CSize,d1	
	Muls.w	d2,d1		
	
	Divs.w	#1000,d1	
	Ext.l	d1			
	Add.l	(a1),d1		
	Sub.l	Cenmy,d1
	Move.w	d1,Cenmvy
	Rts
	
*************************************************
*	Handling for lifts							*
*************************************************
Check_Lifts:
	Tst.w	Standpploop	* Number of lift segments
	Bne	Already_Found	* in d6 (32x32)
	Clr.w	Standpfrm	
						
Lift_Loop:
	Tst.w	Standpfrm
	Bne	Already_Found

	Bsr	Lifts	
	Addi.l	#32,Offex
	Dbra	d6,Lift_Loop	

Already_Found:
	Rts

*************************************************
*	Handling of pendulums 						*
*************************************************
Do_Pendulum:	
	Movem.l	d0-d4,-(SP)

	Subq.l	#4,a0
	Subq.l	#4,a1

	Cmpi.w	#$FE98,Angle
	Blo	Angle_Ok_A
	Addi.w	#360,Angle
	Bra	Angle_Ok_B

Angle_Ok_A:
	Cmpi.w	#360,Angle
	Blo	Angle_Ok_B
	Subi.w	#360,Angle

Angle_Ok_B:	
	Move.w	Angle,d0
	Move.l	d6,Max_Segments
	
	SINE
	Move.w	d1,Sine_Read

	COSINE
	Move.w	d1,Cosine_Read

Pend_Loop:
	Move.l	Max_Segments,d5
	Sub.l	d6,d5
	Addi.l	#1,d5
	
	Move.w	Sine_Read,d2
	Move.w	Cosine_Read,d3
	
	Muls	CSize,d2				
	Muls	d5,d2					
	
	Divs	#1000,d2				
	Ext.l	d2						
	Add.l	(a0),d2					

	Muls	CSize,d3				
	Muls	d5,d3					
	
	Divs	#1000,d3				
	Ext.l	d3						
	Add.l	(a1),d3					

	Move.l	d2,Cenmx
	Move.l	d3,Cenmy
	
	Bsr	Give_Enemy_Offsets

	Cmp.b	Pend_Bob,d6				
	Bne	Not_End						
	
	Move.l	Savecy,d2
	Subi.l	#8,Offex		
	Sub.l	d2,Offey

	ENSIZE	#10,#4,#$500,#$803,#34 	
	Move.w	Bob_Frame,Enemy_Frame	
	Bsr	Draw_Bob
	
	ENSIZE	#20,#2,#$280,#$402,#36
	Move.w	#229,Enemy_Frame

	Dbra	d6,Pend_Loop
	Suba.l	#2,a3
	Suba.l	#2,a4

	Movem.l	(SP)+,d0-d4
	Rts
	
Not_End:
	Bsr	Draw_Bob
	Dbra	d6,Pend_Loop
	
	Suba.l	#2,a3
	Suba.l	#2,a4

	Movem.l	(SP)+,d0-d4
	Rts

*************************************************
*	Retrieve data from enemy bank				*
*************************************************
Ret_Enemy_Data:
	Movem.l	d5/d7,-(SP)
	Move.w	#4,d5
	Sub.w	d7,d5
	Add.w	Estart,d5
	Mulu	#4,d5
	
	Lea	Enmdata,a6
	Lea	(a6,d5),a6

	Move.w	0(a6),d0
	Move.w	2(a6),d1
	Movem.l	(SP)+,d5/d7
	Rts

Put_Enemy_Data:
	Movem.l	d5/d7,-(SP)
	Move.w	#4,d5
	Sub.w	d7,d5
	Add.w	Estart,d5
	Mulu	#4,d5
	
	Lea	Enmdata,a6
	Lea	(a6,d5),a6

	Move.w	d0,0(a6)
	Move.w	d1,2(a6)
	Movem.l	d5/d7,-(SP)
	Rts

*************************************************
*	Work out new platform position				*
*************************************************
Work_Early_Position:
	Move.l	d0,-(SP)

	Moveq.l	#0,d0
	Move.w	Cenmvy,d0
	Move.w	d0,-(a4)
	Ext.l	d0
	Add.l	d0,-(a1)
	Move.l	(a1),Cenmy

	Moveq.l	#0,d0
	Move.w	Cenmvx,d0
	Move.w	d0,-(a3)
	Ext.l	d0
	Add.l	d0,-(a0)
	Move.l	(a0),Cenmx

	Move.l	(SP)+,d0
	Rts
	
*************************************************
*	Check enemy direction tiles					*
*************************************************
Check_Enemy_Tiles:
	Cmpi.b	#$F0,d1
	Bhs	Check_Enemy_Tiles_B
	Rts
	
Check_Enemy_Tiles_B:
	Cmpi.b	#$F0,d1
	Bne	Enemy_Tile_2
	Move.w	#1,Cenmvx
	Move.w	#1,Cenmvy
	Rts

Enemy_Tile_2:
	Cmpi.b	#$F1,d1
	Bne	Enemy_Tile_3
	Move.w	#$FFFF,Cenmvx
	Move.w	#$FFFF,Cenmvy
	Rts

Enemy_Tile_3:
	Cmpi.b	#$F2,d1
	Bne	Enemy_Tile_4
	Move.w	#$FFFF,Cenmvx
	Move.w	#1,Cenmvy
	Rts

Enemy_Tile_4:
	Cmpi.b	#$F3,d1
	Bne	Enemy_Tile_5
	Move.w	#1,Cenmvx
	Move.w	#$FFFF,Cenmvy
	Rts

Enemy_Tile_5:
	Cmpi.b	#$F8,d1
	Bne	Enemy_Tile_6
	Move.w	#1,Cenmvx
	Clr.w	Cenmvy
	Rts

Enemy_Tile_6:
	Cmpi.b	#$F9,d1
	Bne	Enemy_Tile_7
	Move.w	#$FFFF,Cenmvx
	Clr.w	Cenmvy
	Rts

Enemy_Tile_7:
	Cmpi.b	#$FA,d1
	Bne	Enemy_Tile_8
	Move.w	#$FFFF,Cenmvy
	Clr.w	Cenmvx
	Rts

Enemy_Tile_8:
	Cmpi.b	#$FB,d1
	Bne	Enemy_Tile_9	
	Move.w	#1,Cenmvy
	Clr.w	Cenmvx
	Rts
	
Enemy_Tile_9:
	Cmpi.b	#$F4,d1
	Bne	Enemy_Tile_10
	Addi.w	#1,Cenmvx
	Addi.w	#1,Cenmvy
	Rts

Enemy_Tile_10:
	Cmpi.b	#$F5,d1
	Bne	Enemy_Tile_11
	Subi.w	#1,Cenmvx
	Subi.w	#1,Cenmvy
	Rts

Enemy_Tile_11:
	Cmpi.b	#$F6,d1
	Bne	Enemy_Tile_12
	Subi.w	#1,Cenmvx
	Addi.w	#1,Cenmvy
	Rts

Enemy_Tile_12:
	Cmpi.b	#$F7,d1
	Bne	Enemy_Tile_13
	Addi.w	#1,Cenmvx
	Subi.w	#1,Cenmvy
	Rts

Enemy_Tile_13:
	Cmpi.b	#$FC,d1
	Bne	Enemy_Tile_14
	Addi.w	#1,Cenmvx
	Rts

Enemy_Tile_14:
	Cmpi.b	#$FD,d1
	Bne	Enemy_Tile_15
	Subi.w	#1,Cenmvx
	Rts

Enemy_Tile_15:
	Cmpi.b	#$FE,d1
	Bne	Enemy_Tile_16
	Subi.w	#1,Cenmvy
	Rts

Enemy_Tile_16:
	Cmpi.b	#$FF,d1
	Bne	Enemy_Tile_17
	Addi.w	#1,Cenmvy
	Rts
	
Enemy_Tile_17:
	Rts	

*************************************************
*	Convert map coordinates to offsets from the	*
*	screen origin used for rendering			*
*************************************************
Give_Enemy_Offsets:
	Movem.l	d0-d2,-(SP)

	Move.l	Cenmx,Offex
	Move.l	Cenmy,Offey

	Addi.l	#32,Offex
	Addi.l	#32,Offey
	
	Move.w	Xoff,d1
	Moveq.l	#32,d2
	Sub.l	d1,d2
	
	Move.l	Xmap,d0
	Mulu	#32,d0
	Add.l	d2,d0
		
	Sub.l	d0,Offex
	
	Move.w	Yoff,d1
	Moveq.l	#32,d2
	Sub.l	d1,d2
	
	Move.l	Ymap,d0
	Mulu	#32,d0
	Add.l	d2,d0
	
	Sub.l	d0,Offey	

	Movem.l	(SP)+,d0-d2
	Rts

*************************************************
*	Check lifts									*
*************************************************
Lifts:
	Movem.l	d0-d7,-(SP)
	Tst.w	Standpploop
	Bne	Lift_Standing

	Clr.w	Standpfrm	; Clear flag [player standing on lift]
	Clr.w	Platform_Number

	Move.w  Vely,d0
	Sub.w	Cenmvy,d0
	Addi.w	#96,d0
	Ext.l	d0
	
	Move.l	Offex,d1
	Move.l	Offey,d2

	Cmpi.l	#126,d1    	; True 112
	Blo	Off_Lift
	
	Cmpi.l	#158,d1		; True 172
	Bhi	Off_Lift
	
	Cmp.l	d0,d2		; True 96
	Blo	Off_Lift
	
	Cmpi.l	#160,d2		; True 160
	Bhi	Off_Lift
	
	Tst.w	Cenmpfrm	; Is this a lift?
	Beq	Off_Lift	

	Tst.w	Standpfrmon	; Was player already standing on a lift?
	Bne	Now_Check_Coll	

	Tst.w	Vely	
	Beq	Now_Check_Coll

	Cmpi.w	#$7fff,Vely	
	Bls	Off_Lift		; Try to avoid jittering seen in Zool lifts

Now_Check_Coll:
	Addi.l	#40,d0
	Cmp.l	d0,d2
	Blt	Off_Lift

	Move.w	#1,Standpploop

	Tst.w	Cenmvx
	Beq	Start_Cenmvy_Eval

	Move.w	Cenmvx,d0
	Neg.w	d0
	
	Cmpi.w	#$7FFF,d0
	Bhi	Cenmvx_Negative

	Add.w	d0,Xoff		
	Cmpi.w	#31,Xoff
	Bls	Start_Cenmvy_Eval

	Subi.w	#32,Xoff
	Subi.l	#1,Xmap
	Bra	Start_Cenmvy_Eval
	
Cenmvx_Negative:
	Neg.w	d0
	Sub.w	d0,Xoff		
	Bpl	Start_Cenmvy_Eval

	Addi.w	#32,Xoff
	Addi.l	#1,Xmap

Start_Cenmvy_Eval:
	Move.l	Cenmy,d0
	Addi.l	#1,d0
	Divu	#32,d0
	Move.w	d0,d1
	Subi.w	#4,d1
	Ext.l	d1
	Move.l	d1,Ymap
	
	Swap	d0
	Move.l	#32,d1
	Sub.w	d0,d1

	Move.w	d1,Yoff
	
	Move.w	Cenmvx,Momentum_X
	Neg.w	Momentum_X

	Move.w	Cenmvy,Momentum_Y
	Neg.w	Momentum_Y

	Clr.w	Left_Blocked
	Clr.w	Right_Blocked
	Clr.w	VChange
	Clr.w	AuxVelx
	Clr.w	AuxVely
	Clr.w	Surface
	Clr.w	Sidewalk
	Clr.b	Whoopie
	Clr.b	Ext_Whoopie
	Clr.w	Vely
	Clr.w	Jump
	Clr.b	Spring
	Clr.b	Spin
	Clr.w	Hit

	Move.w	d7,Platform_Number
	Move.w	#1,Standpfrm
	Move.w	#1,Standpfrmon
	Move.w	#1,Stand

Lift_Standing:
	Movem.l	(SP)+,d0-d7
	Rts

Off_Lift:	
	Clr.w	Standpfrmon
	Movem.l	(SP)+,d0-d7
	Rts

*************************************************
*	Player-lift interaction handling			*
*************************************************
Velocity_Lifts:
	Movem.l	d0-d7,-(SP)
	Tst.w	Standpploop
	Bne	Lift_Standing_B

	Clr.w	Standpfrm	; Clear flag [player standing on lift]
	Clr.w	Platform_Number

	Move.w  Vely,d0
	Sub.w	Cenmvy,d0
	Addi.w	#96,d0
	Ext.l	d0
	
	Move.l	Offex,d1
	Move.l	Offey,d2

	Cmpi.l	#126,d1    	; True 112
	Blo	Off_Lift_B
	
	Cmpi.l	#158,d1		; True 172
	Bhi	Off_Lift_B
	
	Cmp.l	d0,d2		; True 96
	Blo	Off_Lift_B
	
	Cmpi.l	#160,d2		; True 160
	Bhi	Off_Lift_B
	
	Tst.w	Cenmpfrm	
	Beq	Off_Lift_B	

	Tst.w	Standpfrmon	
	Beq	Now_Check_Coll_B 

	Tst.w	Vely	
	Beq	Now_Check_Coll_B

	Cmpi.w	#$7fff,Vely	
	Bls	Off_Lift_B		

Now_Check_Coll_B:
	Addi.l	#40,d0
	Cmp.l	d0,d2
	Blt	Off_Lift_B

	Move.w	#1,Standpploop

	Tst.w	Cenmvx
	Beq	Start_Cenmvy_Eval_B

	Move.w	Cenmvx,d0
	Neg.w	d0
	
	Cmpi.w	#$7FFF,d0
	Bhi	Cenmvx_Negative_B

	Add.w	d0,Xoff		
	Cmpi.w	#31,Xoff
	Bls	Start_Cenmvy_Eval_B

	Subi.w	#32,Xoff
	Subi.l	#1,Xmap
	Bra	Start_Cenmvy_Eval_B
	
Cenmvx_Negative_B:
	Neg.w	d0
	Sub.w	d0,Xoff		
	Bpl	Start_Cenmvy_Eval_B

	Addi.w	#32,Xoff
	Addi.l	#1,Xmap

Start_Cenmvy_Eval_B:
	Tst.w	Standpfrmon
	Bne	Velocity_Lift_Eval

	Move.l	Cenmy,d0
	Addi.l	#1,d0
	Divu	#32,d0
	Move.w	d0,d1
	Subi.w	#4,d1
	Ext.l	d1
	Move.l	d1,Ymap
	
	Swap	d0
	Move.l	#32,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	
Velocity_Lift_Eval:	
	Move.w	Cenmvy,d0
	Neg.w	d0
	
	Cmpi.w	#$7FFF,d0
	Bhi	Cenmvy_Negative

	Add.w	d0,Yoff		
	Cmpi.w	#31,Yoff
	Bls	End_Velocity_Eval

	Subi.w	#32,Yoff
	Subi.l	#1,Ymap
	Bra	End_Velocity_Eval

Cenmvy_Negative:
	Neg.w	d0
	Sub.w	d0,Yoff		
	Bpl	End_Velocity_Eval

	Addi.w	#32,Yoff
	Addi.l	#1,Ymap

End_Velocity_Eval:
	Move.w	Cenmvx,Momentum_X
	Neg.w	Momentum_X

	Move.w	Cenmvy,Momentum_Y
	Neg.w	Momentum_Y

	Clr.w	Left_Blocked
	Clr.w	Right_Blocked
	Clr.w	VChange
	Clr.w	AuxVelx
	Clr.w	AuxVely
	Clr.w	Surface
	Clr.w	Sidewalk
	Clr.b	Whoopie
	Clr.b	Ext_Whoopie
	Clr.w	Vely
	Clr.w	Jump
	Clr.b	Spring
	Clr.b	Spin
	Clr.w	Hit

	Move.w	d7,Platform_Number
	Move.w	#1,Standpfrm
	Move.w	#1,Standpfrmon
	Move.w	#1,Stand

Lift_Standing_B:
	Movem.l	(SP)+,d0-d7
	Rts

Off_Lift_B:	
	Clr.w	Standpfrmon
	Movem.l	(SP)+,d0-d7
	Rts

*************************************************
*	Check collosion								*
*************************************************
Check_Coll:
	Movem.l	d0-d1,-(SP)

	Tst.b	Cover_Cat
	Bne	No_Coll

	Move.l	Offex,d0
	Move.l	Offey,d1

	Cmp.l	Coll_X1,d0 	; True 112	(32x32)
	Blo	No_Coll
	
	Cmp.l	Coll_X2,d0	; True 172
	Bhi	No_Coll
	
	Cmp.l	Coll_Y1,d1	; True 96
	Blo	No_Coll
	
	Cmp.l	Coll_Y2,d1	; True 160
	Bhi	No_Coll
	
	Tst.w	Cenmpfrm	
	Bne	No_Coll

	Tst.b	Destructable
	Beq	Undestructable
	
	Tst.b	Slide
	Bne	Vely_Just_Right

	Tst.b	Spin
	Beq	Undestructable

	Cmpi.w	#$7FFF,Vely
	Bls	Vely_Just_Right
	Neg.w	Vely	

Vely_Just_Right:
	Clr.b	Destructable
	Addi.l	#100,Score
	
	Move.w	#$FFFE,-(a2)
	Move.w	#0,-(a3)
	Move.w	#0,-(a4)
	Move.w	#0,-(a5)
	
	Adda.l	#2,a2
	Adda.l	#2,a3
	Adda.l	#2,a4
	Adda.l	#2,a5
	Bra	No_Coll

Undestructable:
	Tst.w	Hit				; Check if player hit flag is set to avoid
	Bne	No_Coll				; going into a punishing hit loop

	Tst.b	Invulnerable
	Bne	No_Coll

	Move.w	#1,Hit				* Gotcha!
	Move.w	Hit_Vely,Cf_Hit_Vely
	Move.w	Hit_Velx_Lt,Cf_Hit_Velx_Lt
	Move.w	Hit_Velx_Rt,Cf_Hit_Velx_Rt
	Bra	No_Coll		
	
No_Coll:
	Movem.l	(SP)+,d0-d1
	Rts
		
*************************************************
*	Draw a 32x32 blitter object on the screen	*
*************************************************
Draw_Bob:
	Movem.l	d0-d7,-(SP)
	
	Cmpi.l	#224,Offey	; Check enemy against screen boundary
	Bhi	No_Enemies

	Cmpi.l	#288,Offex	; Check enemy against screen boundary
	Bhi	No_Enemies
	
*************************************************
*	Draw enemy sprites on screen				*
*************************************************
Go_On_Enemies:
	Moveq.l	#0,d0
	Moveq.l	#0,d1

	Move.l	Enemies,Src
	Move.l	MKEnemies,SrcMask
	Move.l	Currbuffer,Dest

	Move.w	Enemy_Frame,d0
	Divu	NFrames,d0
	Move.w	d0,d1
	Swap	d0

	Andi.l	#$FFFF,d0
	Andi.l	#$FFFF,d1

	Mulu	XBytes,d0
	Mulu	YBytes,d1

	Add.w	d1,d0
	
	Add.l	d0,Src
	Add.l	d0,SrcMask

	Move.l	Offey,d0
	Mulu	#40,d0

	Move.l	Offex,d1
	Divu	#16,d1
	Swap	d1
	Move.w	d1,d2
	Swap	d1
	Andi.l	#$ffff,d1
	Mulu	#2,d1

	Move.w	Offx,d3
	Andi.w	#$F,d3
	Sub.w	d3,d2

	Bpl	Shift_All_Right
	Addi.w	#16,d2
	Subi.l	#2,d1

	Bpl	Shift_All_Right
	Moveq.l	#0,d0

Shift_All_Right:
	Move.w	d2,Rten

	Add.l	d1,d0
	Add.l	d0,Dest
	Move.w	Enmsize,d3
	Move.w	Emod,d4

	BLITM	Src,Dest,d3,d4,d4,Rten,#$FFFF,#0,SrcMask
	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d3
	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d3
	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d3
	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d3

No_Enemies:	
	Movem.l	(SP)+,d0-d7
	Rts

*************************************************
*	Determine angle of rotation of player		*
*************************************************
Rotate_Hero:
	Subi.w	#1,RDelay
	Bpl	No_Rotate_Hero
	Move.w	#8,RDelay

	Tst.w	Stand
	Beq	RCheck8
	Rts

RCheck8:	
	Cmpi.w	#8,FrDir
	Bne	RCheck7	
	Move.w	#1,FrDir
	Rts
	
RCheck7:	
	Cmpi.w	#7,FrDir
	Bne	RCheck6	
	Move.w	#8,FrDir
	Rts
	
RCheck6:		
	Cmpi.w	#6,FrDir
	Bne	RCheck5	
	Move.w	#7,FrDir
	Rts
	
RCheck5:		
	Cmpi.w	#5,FrDir
	Bne	RCheck4	
	Move.w	#6,FrDir
	Rts
	
RCheck4:		
	Cmpi.w	#4,FrDir
	Bne	RCheck3	
	Move.w	#3,FrDir
	Rts
	
RCheck3:		
	Cmpi.w	#3,FrDir
	Bne	RCheck2	
	Move.w	#2,FrDir
	Rts
	
RCheck2:		
	Cmpi.w	#2,FrDir
	Bne	No_Rotate_Hero
	Move.w	#1,FrDir
No_Rotate_Hero:
	Rts	

*************************************************
*	Update snow particles						*
*************************************************
Snow_Routine:
	Move.w  Xoff,d5
	Andi.w	#%1111,d5
	Move.w	d5,Obx
	Move.w	#16,d5
	Sub.w	Obx,d5
	Move.w	d5,Obx
	
	Lea	Snowy,a1
	Lea	Snowx,a2
	Lea	Snows,a3
	Move.w	#19,d6

Snow_Loop:	
	Move.w	(a1),d4
	Move.w	(a3)+,d7
	Add.w	d7,d4
	Cmpi.w	#232,d4
	Blo	Snow_In_Range
	Moveq.w	#32,d4
	
Snow_In_Range:
	Move.w	d4,(a1)+
	Move.w	(a2),d5
	
	Move.w	d5,(a2)+	
	Add.w	Obx,d5
	
	SPLOT	d5,d4,Currbuffer
	Dbra	d6,Snow_Loop
	Rts

*************************************************
*	Axes swap (X<->Y) 							*
*************************************************
Change_Vectors:
	Subi.w	#5,Surface	
	Bmi	No_Change
	
	Tst.w	Surface
	Bne	Loop_Surf2

	Cmpi.w	#$ffff,Velx
	Beq	Down_Right
	
	Subi.w	#1,LDelay
	Bpl	Loop_Del1
	
	Move.w	#2,LDelay
	Addi.w	#1,Velx

	Tst.w	Velx
	Bne	Loop_Del1
	Bra	Down_Right2

Down_Right:
	Move.w	#4,Velx
	Move.w	#8,NMCtr
Down_Right2:
	Move.w	#1,Jump
	Bra	No_Change
	
Loop_Del1:	
	Move.w	#1,VChange
	Move.w	Velx,AuxVelx
	Move.w	Vely,AuxVely
	Move.w	Velx,Vely
	Neg.w	Vely
	Clr.w	Velx
	Move.w	#1,Sidewalk
	Rts

Loop_Surf2:
	Cmpi.w	#1,Surface
	Bne	Loop_Surf3
	
	Move.w	Velx,d0
	
	Cmpi.w	#$7fff,d0
	Bls	Velx_Loop_Pos
	Neg.w	d0

Velx_Loop_Pos:
	Cmpi.w	#3,d0
	Bgt	Loop_Del2

	Move.w	#1,Jump
	Bra	No_Change

Loop_Del2:	
	Move.w	#1,VChange
	Move.w	Velx,AuxVelx
	Move.w	Vely,AuxVely
	Neg.w	Velx
	Move.w	#2,Sidewalk
	Rts
	
Loop_Surf3:	
	Cmpi.w	#2,Surface
	Bne	No_Change
	
	Cmpi.w	#1,Velx
	Beq	Down_Left

	Subi.w	#1,LDelay
	Bpl	Loop_Del3
	
	Move.w	#2,LDelay
	Subi.w	#1,Velx
	
	Tst.w	Velx
	Bne	Loop_Del3
	
	Bra	Down_Left2

Down_Left:
	Move.w	#$fffb,Velx	
	Move.w	#8,NMCtr

Down_Left2:
	Move.w	#1,Jump
	Bra	No_Change

Loop_Del3:	
	Move.w	#1,VChange
	Move.w	Velx,AuxVelx
	Move.w	Vely,AuxVely
	Move.w	Velx,Vely
	Clr.w	Velx
	Move.w	#3,Sidewalk
	Rts

No_Change:	
	Clr.w	VChange
	Clr.w	Sidewalk
	Rts

*************************************************
*	Increase velocity							*
*************************************************	
Increase_Vel:
	Tst.w	Inc_Vel
	Beq	Ret_Loop

	Clr.b	Slide
	Subi.w	#1,Inc_Vel
	Tst.w	Dir
	Beq	Add_Left
	
	Move.w	Velx,d0
	Neg.w	d0
	Cmpi.w	#12,d0
	Bgt	Ret_Loop
	Subi.w	#1,Velx
	Rts
		
Add_Left:
	Cmpi.w	#12,Velx
	Bgt	Ret_Loop	
	Addi.w	#1,Velx	

Ret_Loop:	
	Rts

*************************************************
*	Restore forces								*
*************************************************
Restore_Vectors:
	Tst.w	NVChange
	Bne	No_Restoration

	Tst.w	VChange
	Beq	No_Restoration

	Move.w	AuxVelx,Velx
	Move.w	AuxVely,Vely

No_Restoration:	
	Clr.w	VChange
	Rts	

*************************************************
*	Decrease NM counters						*
*************************************************
Dec_NMCtr:
	Tst.w	NMCtr
	Beq	Dec_NMCtr2
	Subi.w	#1,NMCtr
	
Dec_NMCtr2:	
	Tst.w	NMCtr2
	Beq	Dec_NMCtr3
	Subi.w	#1,NMCtr2
	Rts
		
Dec_NMCtr3:	
	Clr.w	IJump
	Rts

*************************************************
*	Parallax scrolling							*
*************************************************
Calc_Parallax:
	Tst.w	Velx
	Bne	PScroll
	Rts
PScroll:
	Tst.w	Fdir
	Bne	PRight
	Move.w	Velx,d0
	Sub.w	d0,PShift
	Divs	#2,d0		
	Add.w	d0,PShift
	Andi.w	#%1111,PShift
	Rts
PRight:		
	Move.w	Velx,d0
	Neg.w	d0
	Add.w	d0,PShift
	Divs	#2,d0
	Sub.w	d0,PShift
	Andi.w	#%1111,PShift
	Rts 

*************************************************
* 	Work out diagonal surface stuff				*
************************************************* 
Diagonal_Stuff:

	Tst.w	Stand
	Beq	Surf1

	Cmpi.w	#4,Surface
	Bgt	DCheck_Over

	Move.w	#2,Yjump
	Clr.w	Xjump

Surf1:
	Cmpi.w	#1,Surface
	Bne	Surf2
	
	Move.w	#$fffe,Xjump
	Move.w	#2,Yjump
	
	Tst.w	Velx
	Beq	DCheck_Over

	Tst.w   Fdir
	Bne	Go_Down1
	Cmpi.w	#2,Velx
	Bls	DCheck_Over

Go_Down1:
	Subi.w	#1,SDelay
	Bpl	DCheck_Over
	Move.w	#2,SDelay
	Subi.w	#1,Velx
	Rts

Surf2:
	Cmpi.w	#2,Surface
	Bne	Surf3

	Move.w	#2,Xjump
	Move.w	#2,Yjump
	
	Tst.w	Velx
	Beq	DCheck_Over

	Tst.w   Fdir
	Beq	Go_Down2
	Cmpi.w	#$FFFE,Velx
	Bhs	DCheck_Over

Go_Down2:
	Subi.w	#1,SDelay
	Bpl	DCheck_Over
	Move.w	#2,SDelay
	Addi.w	#1,Velx
	Rts

Surf3:
	Cmpi.w	#3,Surface
	Bne	Surf4
	
	Move.w	#$ffff,Xjump
	Move.w	#2,Yjump

	Tst.w	Velx
	Beq	DCheck_Over

	Tst.w   Fdir
	Bne	Go_Down3
	Cmpi.w	#5,Velx
	Bls	DCheck_Over

Go_Down3:
	Subi.w	#1,SDelay
	Bpl	DCheck_Over
	Move.w	#4,SDelay
	Subi.w	#1,Velx
	Rts

Surf4:
	Cmpi.w	#4,Surface
	Bne	DCheck_Over

	Move.w	#1,Xjump
	Move.w	#2,Yjump

	Tst.w	Velx
	Beq	DCheck_Over

	Tst.w   Fdir
	Beq	Go_Down4
	Cmpi.w	#$FFFB,Velx
	Bhs	DCheck_Over

Go_Down4:
	Subi.w	#1,SDelay
	Bpl	DCheck_Over
	Move.w	#4,SDelay
	Addi.w	#1,Velx
	Rts	

DCheck_Over:
	Tst.w	Surface
	Bne	Surfset
	Tst.w	Velx
	Bne	Surfset
	Cmpi.w	#4,XDelay
	Bls	Surfset
	Move.w	#4,XDelay
Surfset:	
	Rts	
	
*************************************************
*	Get final velocity of player				*
*************************************************
Get_Final_Velocity:
	Move.w	Velx,d0
	Tst.w	d0
	Beq	Still_Vel

	Clr.w	Left_Blocked
	Clr.w	Right_Blocked

	Cmpi.w	#$7FFF,d0
	Bhs	Right_Vel	
	Clr.w	Fdir
	Rts

Right_Vel:	
	Move.w	#1,Fdir
Still_Vel:	
	Rts

*************************************************
*	Check if player is braking					*
*************************************************
Check_Brake:
	Tst.w	Stand
	Beq	Stop_Brake
	
	Tst.w	Sidewalk
	Bne	Stop_Brake
	
	Tst.w	Velx
	Beq	Stop_Brake
	
	Tst.b	Braking
	Bne	Brake_Mate
	
	Move.w	Velx,d0
	Tst.w	Fdir
	Beq	Bleft
	Neg.w	d0
Bleft:		
	Andi.w	#%11111,d0
	Cmpi.w	#3,d0
	Bhs	Brake_Mate
	Clr.b	Braking
	Rts

Brake_Mate:	
	Tst.w	Fdir
	Bne	Right_Brake
	Cmpi.w	#2,XMotion
	Bne	No_Brake
	Move.b	#1,Braking
	Rts

Right_Brake:	
	Cmpi.w	#1,XMotion
	Bne	No_Brake
	Move.b	#2,Braking
	Rts

Stop_Brake:
	Clr.b	Braking
No_Brake:
	Rts

*************************************************
*	X Control Check								*
*************************************************
Check_Horizontal_Controls:
	Clr.w	XMotion

	Move.w	Joydat,d6
	Btst	#9,d6			; Input = left?
	Beq	Check_Right			

	Cmpi.b	#1,Braking
	Bne	Brake_Ok1
	Clr.b	Braking
	
Brake_Ok1:	

	Cmpi.w	#1,Fdir			; Looking right?
	Beq	Brake_Left			

	Cmpi.w	#10,Velx		; If player velocity < 10,
	Bhs	Max_Left			; we can move faster

No_Maxleft:	
	Tst.w	Left_Blocked
	Bne	Max_Left

	Subi.w	#1,XDelay		; Decrease delay
	Bpl	Max_Left		

Left_Delay:
	Lea	XDelay_Vals,a0		; Set new delay
	Bsr	Get_XDelay_Value	
	Move.w	d1,XDelay
	Addi.w	#1,Velx			

Max_Left:
	Move.w	#1,XMotion
	Clr.w	Dir
	Rts

Brake_Left:
	Subi.w	#4,XDelay
	Bpl	No_Maxleft
	Bra	Left_Delay	

Check_Right:
	Move.w	Joydat,d6
	Btst    #1,d6			; Input = right?
	Beq	XCheck_Over			

	Cmpi.b	#2,Braking
	Bne	Brake_Ok2
	Clr.b	Braking

Brake_Ok2:	
	Tst.w	Fdir			; Looking left?
	Beq	Brake_Right			
	
	Tst.w	Velx
	Beq	No_Maxright

	Cmpi.w	#$FFF5,Velx		
	Bls	Max_Right

No_Maxright:	
	Tst.w	Right_Blocked
	Bne	Max_Right

	Subi.w	#1,XDelay		
	Bpl	Max_Right
	
Right_Delay:
	Lea	XDelay_Vals,a0		
	Bsr	Get_XDelay_Value	
	Move.w	d1,XDelay
	Subi.w  #1,Velx			

Max_Right:
	Move.w	#2,XMotion		
	Move.w	#1,Dir

XCheck_Over:				
	Rts
	
Brake_Right:
	Subi.w	#4,XDelay
	Bpl	No_Maxright
	Bra	Right_Delay

*************************************************
*	Check vertical controls						*
*************************************************
Check_Vertical_Controls:	
	Tst.w	NJump
	Bne	Check_Down
	
	Tst.b	Crouch
	Bne	Check_Down
	
	Tst.w	Inc_Vel
	Bne	Check_Down

	Btst	#$7,Mousekey		
	Bne	Check_Down		

	Tst.w	Power
	Bne	Contjump

	Tst.w	Stand			
	Beq	Check_Down
		
	Tst.w	Jump
	Bne	Check_Down	

	Tst.w	Standpfrm
	Beq	No_Lift_Stand

	Move.w	Momentum_Y,d3		; If currently standing on 
	Ext.l	d3					; a moving platform, then
								; transfer momentum into jump
	Move.w	Momentum_X,d2
	Ext.l	d2
	Bra	Lift_Stand

No_Lift_Stand:					
	Moveq.l	#0,d2			
	Moveq.l	#0,d3
	
Lift_Stand:	
	Cmpi.w	#5,Surface
	Bhs	Do_XJump

	Move.w	Xjump,d0
	Muls	#6,d0
	Andi.l	#$FFFF,d0
	
	Tst.w	Velx
	Beq	Do_XJump
	
	Cmpi.w	#$7FFF,Velx
	Bls	Velx_Jump_Pos

	Cmp.w	Velx,d0
	Blo	Do_XJump
	
	Clr.w	Xjump
	Bra	Do_XJump
	
Velx_Jump_Pos:
	Cmp.w	Velx,d0
	Bhi	Do_XJump
	
	Clr.w	Xjump

Do_XJump:
	Move.w	Xjump,d0
	Muls	#4,d0			

	Cmpi.w	#5,Surface
	Blo	Add_Not_Move
	
	Move.w	d0,Velx
	Bra	Now_Y_Component

Add_Not_Move:	
	Add.w	d0,Velx

Now_Y_Component:
	Add.w	d2,Velx
	
	Move.w	Yjump,d0
	Muls	#6,d0
	Andi.l	#$FFFF,d0
	
	Tst.w	Vely
	Beq	Do_YJump
	
	Cmpi.w	#$7FFF,Vely
	Bls	Vely_Jump_Pos

	Cmp.w	Vely,d0
	Blo	Do_YJump
	
	Clr.w	Yjump
	Bra	Do_YJump
	
Vely_Jump_Pos:
	Cmp.w	Vely,d0
	Bhi	Do_YJump
	
	Clr.w	Yjump

Do_YJump:
	Move.w	Yjump,d0
	Muls	#4,d0			
	Add.w	d0,Vely
	Add.w	d3,Vely
	
	Move.w	#1,Jump
	Move.w	#1,IJump
	Move.w	#2,NMCtr2
	Move.b	#1,Spin

	Clr.w	VChange
	Clr.w	AuxVelx
	Clr.w	AuxVely

	Clr.w	Standpfrmon
	Clr.w	Standpfrm
	Clr.w	Stand
	Clr.w	Surface
	Clr.w	Sidewalk
	Clr.w	Momentum_X
	Clr.w	Momentum_Y
	Clr.b	Dino_Platform

Contjump:
	Move.w	Power,d0
	
	Cmp.w	Max_Jump,d0
	Bhi	Check_Down
	
	Addi.w	#1,Power

	Move.w	Yjump,d0
	Add.w	d0,Vely
	
	Move.w	Xjump,d0
	Add.w	d0,Velx
	Rts
	
Check_Down:	
	Clr.w	Power
	Clr.b	Crouch
	Clr.b	Slide
	
	Btst	#1,d6
	Seq.b	Jdown1
	Btst	#0,d6
	Seq.b	Jdown2
	
	Clr.b	d0
	Move.b	Jdown2,d0
	
	Cmp.b	Jdown1,d0
	Beq	YCheck_Over		; Pushing joystick down when jumping

	Tst.w	Stand			
	Beq	No_Crouch		

	Tst.w	Velx
	Bne	Blaze_Slide
	
	Move.b	#1,Crouch
	Move.w	#50,CtrDelay

	Btst	#$7,Mousekey		
	Bne	YCheck_Over
	
	Move.w	#20,NMCtr
	Move.w	#20,Inc_Vel
	Rts

No_Crouch:
	Tst.w	Stand
	Bne	YCheck_Over

	Tst.w	Standpfrmon
	Bne	YCheck_Over
	
	Subi.w  #1,Vely			
YCheck_Over:
	Rts
	
Blaze_Slide:
	Tst.w	XMotion
	Bne	YCheck_Over
	Move.b	#1,Slide
	Rts
	
*************************************************
*	X Control Evaluation						*
*************************************************
Horizontal_Evaluation:
	Tst.w	Velx
	Bne	In_Limit0
	Clr.b	Braking
	Bra	XEval_Over

In_Limit0:
	Move.w	Velx,d0
	Cmpi.w	#$7FFF,d0
	Bhi	Velx_Negative

	Cmpi.w	#31,Velx
	Bls	In_Limit1
	Move.w	#31,Velx
	
In_Limit1:	
	Cmpi.w	#1,XMotion
	Beq	No_MoveX1
	
	Subi.w	#1,BDelay
	Bpl	No_MoveX1
	Move.w	#4,BDelay
	Subi.w	#1,Velx		
	Move.w	Velx,d0

No_MoveX1:	
	Add.w	d0,Xoff		
	Cmpi.w	#31,Xoff
	Bls	XEval_Over

	Subi.w	#32,Xoff
	Subi.l	#1,Xmap
	Bpl	XEval_Over

	Clr.w	Velx
	Move.l	#0,Xmap
	Move.w	#31,Xoff
	Bra	XEval_Over
	
Velx_Negative:
	Cmpi.w	#$FFE1,Velx
	Bhs	In_Limit2
	Move.w	#$FFE1,Velx

In_Limit2:	
	Move.w	Velx,d0
	Neg.w	d0

	Cmpi.w	#2,XMotion	; Left->right force?
	Beq	No_MoveX2		; Yeah!

	Subi.w	#1,BDelay
	Bpl	No_MoveX2
	Move.w	#4,BDelay
	Addi.w	#1,Velx		; Slow down

No_MoveX2:	
	Sub.w	d0,Xoff		
	Bpl	XEval_Over

	Addi.w	#32,Xoff
	Addi.l	#1,Xmap
XEval_Over:
	Rts

*************************************************
*	Evaluate vertical control					*
*************************************************
Vertical_Evaluation:
	Tst.w	Stand
	Bne	Touch_Ground
	
	Tst.w	Momentum_X
	Bne	Give_Mom

	Tst.w	Momentum_Y
	Bne	Give_Mom

	Bra	No_Mom

Give_Mom:
	Move.w	Momentum_X,d0
	Ext.l	d0
	Add.w	d0,Velx

	Move.w	Momentum_Y,d0
	Ext.l	d0
	Add.w	d0,Vely

	Move.w	#1,Jump
	Move.w	#1,IJump
	Move.w	#1,NMCtr2

	Clr.w	Momentum_X
	Clr.w	Momentum_Y

No_Mom:
	Subi.w	#1,Vely
	Clr.b	Dino_Platform
	Clr.w	Standpfrmon
	Clr.w	Standpfrm
	Clr.w	Stand
	Clr.w	Surface
	Clr.w	Sidewalk
	Clr.w	Left_Blocked
	Clr.w	Right_Blocked
	
Touch_Ground:	
	Move.w	Vely,d0
	Cmpi.w	#$7FFF,d0
	Bhi	Vely_Negative

	Move.w	Vely,d0		
	Cmpi.w	#31,d0
	Ble.s	In_Range1
	Move.w	#31,Vely
	Move.w	#31,d0

In_Range1:	
	Add.w	d0,Yoff	
	Cmpi.w	#31,Yoff
	Bls	YEval_Over

	Subi.w	#32,Yoff
	Subi.l	#1,Ymap
	Bpl	YEval_Over

	Move.l	#0,Ymap
	Move.w	#31,Yoff
	Bra	YEval_Over

Vely_Negative:
	Move.w	Vely,d0
	Neg.w	d0
	Cmpi.w	#19,d0
	Ble.s	In_Range2
	Move.w	#$FFED,Vely		; (-19) Terminal velocity
	Move.w	#19,d0

In_Range2:	
	Sub.w	d0,Yoff
	Bpl	YEval_Over

	Addi.w	#32,Yoff
	Addi.l	#1,Ymap
YEval_Over:
	Rts

*************************************************
*	Set player direction						*
*************************************************
Eval_Dir:
	Clr.b	Super_Run

	Cmp.w 	#1,FrDir
	Bne	Sfrm2
	Clr.w	YFlip
	Clr.w	Surfframe
	Bra	Check_Super_Run
	
Sfrm2:
	Cmpi.w	#2,FrDir
	Bne	Sfrm3
	Clr.w	YFlip
	Move.w	#12,Surfframe
	Rts
	
Sfrm3:
	Cmpi.w	#3,FrDir
	Bne	Sfrm4
	Tst.w	Dir
	Bne	No_Flip_62
	Move.w	#1,YFlip
	Move.w	#1,XORFrame
No_Flip_62:
	Move.w	#24,Surfframe
	Rts

Sfrm4:	
	Cmpi.w	#4,FrDir
	Bne	Sfrm5
	Move.w	#1,YFlip
	Move.w	#12,Surfframe
	Rts
	
Sfrm5:
	Cmpi.w	#5,FrDir
	Bne	Sfrm6
	Move.w	#1,YFlip
	Clr.w	Surfframe
	Rts

Sfrm6:
	Cmpi.w	#6,FrDir
	Bne	Sfrm7
	Move.w	#1,YFlip
	Move.w  #36,Surfframe
	Rts

Sfrm7:
	Cmpi.w	#7,FrDir
	Bne	Sfrm8
	Move.w	#1,XORFrame
	Tst.w	Dir
	Beq	No_Flip_61
	Move.w	#1,YFlip
No_Flip_61:
	Move.w	#30,Surfframe
	Rts
	
Sfrm8:
	Cmpi.w	#8,FrDir
	Bne	Sfrm_Over
	Clr.w	YFlip
	Move.w	#36,Surfframe
Sfrm_Over:
	Rts
	
Check_Super_Run:
	Move.w	Velx,d0
	Cmpi.w	#$7fff,d0
	Bls	Velx_Pos
	Neg.w	d0
Velx_Pos:
	Cmpi.w	#10,d0
	Blo	No_Super_Run

	Move.b	#1,Super_Run
	
	Tst.b	Spin
	Bne	No_Super_Run
	
	Cmpi.w	#4,Frame
	Bls	No_Super_Run
	Move.w	#1,Frame

No_Super_Run:				
	Rts
	
*************************************************
*	Test for player interaction with special	*
*	tile map.									*
*************************************************

Set_SPtile_Down:
	Move.w	#127,YChar

	Tst.w	IJump
	Bne	Return_Loop

	Tst.w	Stand
	Beq	Land_And_Dust
	Clr.w	Can_Dust
	
	Tst.w	Vely
	Bne	No_Vygone_Check
	Move.w	#$ffff,Vely
	Bra	No_Vygone_Check

Land_And_Dust:
	Cmpi.w	#2,Can_Dust	
	Beq	Clear_Can_Dust
	Move.w	#1,Can_Dust
	Bra	No_Vygone_Check

Clear_Can_Dust:
	Clr.w	Can_Dust	
	Clr.w	Dust_Delay
	Move.w	#152,XDust
	Move.w	#143,YDust

No_Vygone_Check:	
	Clr.w	Stand
	Clr.w	Standpfrm
	Clr.w	Standpfrmon
	Clr.w	YFlip
	Clr.w	XORFrame
	Clr.w	Brgdn
	Clr.w	Fpform
	Clr.w	NJump

	Move.w	Yoff,d7
	Subi.w	#2,d7
	Move.w	d7,d5

	Move.w	Vely,d6
	Neg.w	d6
	Sub.w	d6,d5

	Bpl	Yoff_In_Range
	Moveq.l	#0,d7

Yoff_In_Range:
	Tst.w	Vely
	Beq	No_Loop
	
	Cmpi.w	#$7fff,Vely
	Blo	No_Loop
	Clr.b	Spring
	
No_Loop:
	
	Move.l	Map,a0
	Move.l	SMap,d0

	Lea	8(a0,d0.l),a0

	Moveq.l	#4,d0
	Moveq.l	#4,d1
	
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Platform_Detected

Return_Loop:
	Clr.w	Can_Dust
	Clr.w	Dust_Delay
	Move.w	#152,XDust
	Move.w	#143,YDust	

	Tst.w	NVChange
	Beq	Side_Check1

	Clr.w	NVChange
	Bra	Side_Check4

Side_Check1:	
	Tst.w	Sidewalk
	Beq	Side_Check4

	Cmpi.w	#1,Sidewalk
	Bne	Side_Check2
	Move.w	#5,Surface
	Move.w	#1,NVChange
	Bra	Side_Check4

Side_Check2:		
	Cmpi.w	#2,Sidewalk
	Bne	Side_Check3
	Move.w	#6,Surface
	Move.w	#1,NVChange
	Bra	Side_Check4

Side_Check3:		
	Cmpi.w	#3,Sidewalk
	Bne	Side_Check4
	Move.w	#7,Surface
	Move.w	#1,NVChange
	Bra	Side_Check4

Side_Check4:
	Clr.w	VChange
	Clr.w	Sidewalk
	Clr.w	Standon
	Move.w	#1,Jump
	Rts
	
Platform_Detected:
	Clr.w	Momentum_X
	Clr.w	Momentum_Y

	Cmpi.b	#10,d2
	Bls	Pfrm1
	
	Cmpi.b	#20,d2
	Bls	Pfrm10
	
	Cmpi.b	#30,d2
	Bls	Pfrm20

	Cmpi.b	#40,d2
	Bls	Pfrm30

	Cmpi.b	#50,d2
	Bls	Pfrm40

	Cmpi.b	#60,d2
	Bls	Pfrm50

	Cmpi.b	#70,d2
	Bls	Pfrm60

	Cmpi.b	#80,d2
	Bls	Pfrm70
	
	Cmpi.b	#90,d2
	Bls	Pfrm80
	
	Cmpi.b	#100,d2
	Bls	Pfrm90
	
	Cmpi.b	#110,d2
	Bls	Pfrm100

	Cmpi.b	#120,d2
	Bls	Pfrm110

	Cmpi.b	#160,d2
	Bls	Pfrm240

	Cmpi.b	#170,d2
	Bls	Pfrm160
	
	Cmpi.b	#180,d2
	Bls	Pfrm170
	
	Cmpi.b	#190,d2
	Bls	Pfrm180
	
	Cmpi.b	#200,d2
	Bls	Pfrm190

	Cmpi.b	#210,d2
	Bls	Pfrm200

	Cmpi.b	#220,d2
	Bls	Pfrm210

	Cmpi.b	#230,d2
	Bls	Pfrm220
	
	Cmpi.b	#240,d2
	Bls	Pfrm230
	
	Bra	Pfrm240
	
Pfrm1:
	Cmpi.b	#1,d2		; Horizontal
	Bne	Pfrm2

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Move.w	#1,FrDir
	Clr.w	Surface
	Move.w	#31,Yoff
	Bra	Settle

Pfrm2:					; 45° Left
	Cmpi.b	#2,d2
	Bne	Pfrm3

	Tst.w	Standon
	Bne	Pfrm2b

	Cmpi.w	#24,d7
	Bgt	Return_Loop

Pfrm2b:
	Move.w	#8,FrDir
	Move.w	#1,Surface

	Move.w	Xoff,Yoff
	Bra	Settle

Pfrm3:					; 45° Right
	Cmpi.b	#3,d2
	Bne	Pfrm4

	Tst.w	Standon
	Bne	Pfrm3b

	Cmpi.w	#24,d7
	Bgt	Return_Loop

Pfrm3b:
	Move.w	#2,Surface
	Move.w	#2,FrDir
	
	Move.w	Xoff,d0
	Moveq.w	#32,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm4:	
	Cmpi.b	#4,d2		; 22° Left (1)
	Bne	Pfrm5

	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Divu	#2,d0
	Addi.w	#16,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm5:					; 22° Left (2)
	Cmpi.b	#5,d2
	Bne	Pfrm6

	Tst.w	Standon
	Bne	Pfrm5b

	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm5b:
	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Divu	#2,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm6:	
	Cmpi.b	#6,d2		; 22° Right(1)
	Bne	Pfrm7

	Tst.w	Standon
	Bne	Pfrm6b

	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm6b:	
	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Moveq.w	#32,d1
	Divu	#2,d0
	Addi.w	#16,d0
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm7:	
	Cmpi.b	#7,d2		; 22° Right(2)
	Bne	Pfrm10

	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Moveq.w	#32,d1
	Divu	#2,d0
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm10:
	Cmpi.b	#10,d2
	Bne	Pfrm11

	Move.w	#$fffe,Xjump
	Move.w	#$0000,Yjump
	Clr.b	Braking

	Tst.w	Jump
	Bne	Return_Loop

	Tst.w	Sidewalk
	Beq	Return_Loop
	
	Move.w	#25,Xoff
	Move.w	#7,FrDir
	Move.w	#7,Surface
	Bra	Settle

Pfrm11:
	Cmpi.b	#11,d2
	Bne	Pfrm12
	
	Move.w	#$0002,Xjump
	Move.w	#$0000,Yjump
	Clr.b	Braking

	Tst.w	Jump
	Bne	Return_Loop
	
	Tst.w	Sidewalk
	Beq	Return_Loop
	
	Move.w	#7,Xoff
	Move.w	#3,FrDir
	Move.w	#5,Surface
	Bra	Settle
		
Pfrm12:	
	Cmpi.b	#12,d2		; Top-left corner
	Bne	Pfrm13

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Move.w	#1,FrDir
	Move.w	#31,Yoff
	Clr.w	Surface

	Bra	Settle

Pfrm13:		
	Cmpi.b	#13,d2		; Top-right corner
	Bne	Pfrm22

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Move.w	#1,FrDir
	Clr.w	Surface
	Move.w	#31,Yoff

	Bra	Settle

Pfrm14:
Pfrm15:
Pfrm16:
Pfrm17:
Pfrm18:
Pfrm19:
Pfrm20:
Pfrm21:

Pfrm22:	
	Cmpi.b	#22,d2		; 11° Left (1)
	Bne	Pfrm23

	Tst.w	Standon
	Bne	Pfrm22b

	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm22b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Divu	#4,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm23:					; 11° Left (2)
	Cmpi.b	#23,d2
	Bne	Pfrm24

	Tst.w	Standon
	Bne	Pfrm23b
	
	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm23b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Divu	#4,d0
	Addi.w	#8,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm24:					; 11° Left (3)
	Cmpi.b	#24,d2
	Bne	Pfrm25

	Tst.w	Standon
	Bne	Pfrm24b
	
	Cmpi.w	#24,d7
	Bgt	Return_Loop

Pfrm24b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Divu	#4,d0
	Addi.w	#16,d0
	Move.w	d0,Yoff

	Bra	Settle

Pfrm25:					; 11° Left (4)
	Cmpi.b	#25,d2
	Bne	Pfrm26

	Move.w	Xoff,d0
	Divu	#4,d0
	Addi.w	#24,d0
	Move.w	d0,Yoff

	Move.w	#1,FrDir
	Clr.w	Surface
	Bra	Settle

Pfrm26:	
	Cmpi.b	#26,d2		; 11° Right (1)
	Bne	Pfrm27

	Tst.w	Standon
	Bne	Pfrm26b

	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm26b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Divu	#4,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm27:					; 11° Right (2)
	Cmpi.b	#27,d2
	Bne	Pfrm28

	Tst.w	Standon
	Bne	Pfrm27b
	
	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm27b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Divu	#4,d0
	Addi.w	#8,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm28:					; 11° Right (3)
	Cmpi.b	#28,d2
	Bne	Pfrm29

	Tst.w	Standon
	Bne	Pfrm28b
	
	Cmpi.w	#24,d7
	Bgt	Return_Loop

Pfrm28b:	
	
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Divu	#4,d0
	Addi.w	#16,d0
	Move.w	d0,Yoff

	Bra	Settle

Pfrm29:					; 11° Right (4)
	Cmpi.b	#29,d2
	Bne	Pfrm30

	Move.w	Xoff,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Divu	#4,d0
	Addi.w	#24,d0
	Move.w	d0,Yoff

	Move.w	#1,FrDir
	Clr.w	Surface
	Bra	Settle

Pfrm30:		
	Cmpi.b	#30,d2		; 45° Curve Left (1)
	Bne	Pfrm31

	Tst.w	Standon
	Bne	Pfrm30b
	
	Cmpi.w	#24,d7
	Bgt	Return_Loop

Pfrm30b:
	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#128,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm31:	
	Cmpi.b	#31,d2		; 45° Curve Left (2)
	Bne	Pfrm32

	Tst.w	Standon
	Bne	Pfrm31b
	
	Cmpi.w	#18,d7
	Bgt	Return_Loop

Pfrm31b:
	Move.w	#8,FrDir
	Move.w	#1,Surface

	Move.w	Xoff,d0
	Moveq.w	#63,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#128,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm32:	
	Cmpi.b	#32,d2		; 45° Curve Right (1)
	Bne	Pfrm33

	Tst.w	Standon
	Bne	Pfrm32b
	
	Cmpi.w	#18,d7
	Bgt	Return_Loop

Pfrm32b:
	Move.w	#2,FrDir
	Move.w	#2,Surface

	Move.w	Xoff,d0
	Addi.w	#32,d0
	Mulu	d0,d0
	Divu	#128,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm33:	
	Cmpi.b	#33,d2		; 45° Curve Right (2)
	Bne	Pfrm34

	Tst.w	Standon
	Bne	Pfrm33b
	
	Cmpi.w	#26,d7
	Bgt	Return_Loop

Pfrm33b:	
	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Mulu	d0,d0
	Divu	#128,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm34:	
	Cmpi.b	#34,d2		; 45° Curve Left (3)
	Bne	Pfrm35

	Tst.w	Standon
	Bne	Pfrm34b
	
	Cmpi.w	#14,d7
	Bgt	Return_Loop

Pfrm34b:		
	Move.w	#8,FrDir
	Move.w	#1,Surface

	Move.w	Xoff,d0
	Addi.w	#32,d0
	Mulu	d0,d0
	Divu	#128,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm35:	
	Cmpi.b	#35,d2		; 45° Curve Left (4)
	Bne	Pfrm36	

	Tst.w	Standon
	Bne	Pfrm35b
	
	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm35b:
	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Mulu	d0,d0
	Divu	#128,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm36:	
	Cmpi.b	#36,d2		; 45° Curve Right (3)
	Bne	Pfrm37	
	
	Tst.w	Standon
	Bne	Pfrm36b
	
	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm36b:
	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#128,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm37:	
	Cmpi.b	#37,d2		; 45° Curve Right (4)
	Bne	Pfrm38

	Tst.w	Standon
	Bne	Pfrm37b
	
	Cmpi.w	#14,d7
	Bgt	Return_Loop

Pfrm37b:		
	Move.w	#2,FrDir
	Move.w	#2,Surface

	Move.w	Xoff,d0
	Moveq.w	#63,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#128,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm38:	
	Cmpi.b	#38,d2		; 22° Curve Left (1)
	Bne	Pfrm39
	
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#256,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm39:	
	Cmpi.b	#39,d2		; 22° Curve Left (2)
	Bne	Pfrm40
	
	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Moveq.w	#63,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#256,d1
	Moveq.w	#31,d0
	Sub.w	d1,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm40:	
	Cmpi.b	#40,d2		; 22° Curve Right (1)
	Bne	Pfrm41
	
	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Addi.w	#32,d0
	Mulu	d0,d0
	Divu	#256,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm41:	
	Cmpi.b	#41,d2		; 22° Curve Right (2)
	Bne	Pfrm42
	
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Mulu	d0,d0
	Divu	#256,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm42:	
	Cmpi.b	#42,d2		; 22° Curve Left (3)
	Bne	Pfrm43

	Tst.w	Standon
	Bne	Pfrm42b

	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm42b:
	Move.w	#1,FrDir
	Move.w	#3,Surface

	Move.w	Xoff,d0
	Addi.w	#32,d0
	Mulu	d0,d0
	Divu	#256,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm43:	
	Cmpi.b	#43,d2		; 22° Curve Left (4)
	Bne	Pfrm44
	
	Tst.w	Standon
	Bne	Pfrm43b

	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm43b:	
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Mulu	d0,d0
	Divu	#256,d0
	Move.w	d0,Yoff
	Bra	Settle

Pfrm44:	
	Cmpi.b	#44,d2		; 22° Curve Right (3)
	Bne	Pfrm45

	Tst.w	Standon
	Bne	Pfrm44b

	Cmpi.w	#8,d7
	Bgt	Return_Loop

Pfrm44b:		
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Moveq.w	#31,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#256,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm45:	
	Cmpi.b	#45,d2		; 22° Curve Right (4)
	Bne	Pfrm46

	Tst.w	Standon
	Bne	Pfrm45b

	Cmpi.w	#16,d7
	Bgt	Return_Loop

Pfrm45b:
	Move.w	#1,FrDir
	Move.w	#4,Surface

	Move.w	Xoff,d0
	Moveq.w	#63,d1
	Sub.w	d0,d1
	Mulu	d1,d1
	Divu	#256,d1
	Move.w	d1,Yoff
	Bra	Settle

Pfrm46:
	Cmpi.b	#46,d2
	Bne 	Pfrm47

	Move.w	#$fffe,Xjump
	Move.w	#$fffe,Yjump
	Clr.b	Braking
	
	Tst.w	Fdir
	Bne	Pfrm46b
	
	Move.w	#31,Xoff
	Addi.l	#1,Xmap
	
	Bra	Set_SPtile_Down
Pfrm46b:	
	Move.w	#31,Yoff
	Addi.l	#1,Ymap
	
	Bra	Set_SPtile_Down

Pfrm47:
	Cmpi.b	#47,d2
	Bne	Pfrm48

	Clr.b	Braking
	Move.w	#$ffff,Xjump
	Move.w	#$fffe,Yjump
	
	Cmpi.w	#$7fff,Vely
	Blo	Godn_47	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Xoff,d0
	Clr.w	d1
	Bsr	Get_Coord
	Move.w	d1,Yoff

	Move.w	#5,FrDir
	Move.w	#6,Surface
	Bra	Settle
Godn_47:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Clr.w	d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Return_Loop

Pfrm48:
	Cmpi.b	#70,d2
	Bhs	Pfrm70

	Cmpi.b	#48,d2
	Bne	Pfrm49

	Move.w	#$fffe,Yjump
	Move.w	#$0000,Xjump
	Clr.b	Braking

	Cmpi.w	#$7fff,Vely
	Blo	Godn_48	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Xoff,d0
	Moveq.w	#1,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff

	Move.w	#5,FrDir
	Move.w	#6,Surface
	Bra	Settle
Godn_48:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Clr.b	Braking

	Move.w	Xoff,d0
	Moveq.w	#1,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Return_Loop
	
Pfrm49:
	Cmpi.b	#49,d2
	Bne	Pfrm50

	Clr.b	Braking
	Move.w	#$fffe,Yjump
	Move.w	#$0000,Xjump
		
	Cmpi.w	#$7fff,Vely
	Blo	Godn_49	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Xoff,d0
	Moveq.w	#2,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff

	Move.w	#5,FrDir
	Move.w	#6,Surface
	Bra	Settle
Godn_49:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#2,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Return_Loop
	
Pfrm50:
	Cmpi.b	#50,d2
	Bne	Pfrm51

	Clr.b	Braking
	Move.w	#$fffe,Yjump
	Move.w	#$0001,Xjump
	
	Cmpi.w	#$7fff,Vely
	Blo	Godn_50	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Xoff,d0
	Moveq.w	#3,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff

	Move.w	#4,FrDir
	Move.w	#6,Surface
	Bra	Settle
Godn_50:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#3,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Return_Loop

Pfrm51:
	Cmpi.b	#51,d2
	Bne 	Pfrm52

	Clr.b	Braking
	Move.w	#$fffe,Yjump
	Move.w	#$0002,Xjump
	
	Tst.w	Fdir
	Beq	Pfrm51b
	
	Clr.w	Xoff
	Subi.l	#1,Xmap
	
	Bra	Set_SPtile_Down
Pfrm51b:	
	Move.w	#31,Yoff
	Addi.l	#1,Ymap
	
	Bra	Set_SPtile_Down

Pfrm52:
	Cmpi.b	#52,d2
	Bne	Pfrm53

	Move.w	#$fffe,Xjump
	Move.w	#$fffe,Yjump
	Clr.b	Braking

	Cmpi.w	#$7fff,Vely
	Blo	Godn_52	

	Tst.w	Jump
	Bne	Return_Loop
	
	Move.w	Yoff,d0
	Moveq.w	#4,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff

	Move.w	#6,FrDir
	Move.w	#7,Surface
	Bra	Settle
Godn_52:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#4,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Return_Loop
	
Pfrm53:
	Cmpi.b	#53,d2
	Bne	Pfrm54

	Move.w	#$0002,Xjump
	Move.w	#$fffe,Yjump
	Clr.b	Braking

	Cmpi.w	#$7fff,Vely
	Blo	Godn_53	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Yoff,d0
	Moveq.w	#5,d1	
	Bsr	Get_Coord
	Move.w	d1,Xoff

	Move.w	#4,FrDir
	Move.w	#5,Surface
	Bra	Settle
Godn_53:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#5,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Return_Loop

Pfrm54:
	Cmpi.b	#54,d2
	Bne	Pfrm55

	Move.w	#$fffe,Xjump
	Move.w	#$ffff,Yjump
	Clr.b	Braking

	Cmpi.w	#$7fff,Vely
	Blo	Godn_54	

	Tst.w	Jump
	Bne	Return_Loop
	
	Move.w	Yoff,d0
	Moveq.w	#6,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff

	Move.w	#7,FrDir
	Move.w	#7,Surface
	Bra	Settle
Godn_54:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#6,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Return_Loop

Pfrm55:
	Cmpi.b	#55,d2
	Bne	Pfrm56

	Move.w	#$0002,Xjump
	Move.w	#$ffff,Yjump
	Clr.b	Braking

	Cmpi.w	#$7fff,Vely
	Blo	Godn_55	

	Tst.w	Jump
	Bne	Return_Loop

	Move.w	Yoff,d0
	Moveq.w	#7,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff

	Move.w	#3,FrDir
	Move.w	#5,Surface
	Bra	Settle
Godn_55:
	Move.w	#$ffff,Vely
	Move.w	#1,Jump

	Move.w	Xoff,d0
	Moveq.w	#7,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Return_Loop

Pfrm56:
	Cmpi.b	#56,d2
	Bne	Pfrm57

	Tst.w	Standon
	Bne	Pfrm56b

	Cmpi.w	#16,Xoff
	Blo	Return_Loop

Pfrm56b:
	Move.w	#$fffe,Xjump
	Move.w	#$0001,Yjump
	Clr.b	Braking

	Move.w	#7,FrDir
	Move.w	#7,Surface

	Move.w	Yoff,d0
	Moveq.w	#8,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Settle
	
Pfrm57:
	Cmpi.b	#57,d2
	Bne	Pfrm58

	Tst.w	Standon
	Bne	Pfrm57b

	Cmpi.w	#16,Xoff
	Bgt	Return_Loop

Pfrm57b:
	Move.w	#$0002,Xjump
	Move.w	#$0001,Yjump
	Clr.b	Braking

	Move.w	#3,FrDir
	Move.w	#5,Surface

	Move.w	Yoff,d0
	Moveq.w	#9,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Settle

Pfrm58:
	Cmpi.b	#58,d2
	Bne	Pfrm59
		
	Clr.b	Braking
	Move.w	#$fffe,Xjump
	Move.w	#$0002,Yjump

	Move.w	#8,FrDir
	Move.w	#7,Surface
	
	Move.w	Yoff,d0
	Moveq.w	#10,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Settle

Pfrm59:
	Cmpi.b	#59,d2
	Bne	Pfrm60

	Move.w	#$0002,Xjump
	Move.w	#$0002,Yjump
	Clr.b	Braking

	Move.w	#2,FrDir
	Move.w	#5,Surface
	

	Move.w	Yoff,d0
	Moveq.w	#11,d1
	Bsr	Get_Coord
	Move.w	d1,Xoff
	Bra	Settle
	
Pfrm60:
	Cmpi.b	#60,d2
	Bne 	Pfrm61

	Move.w	#$0002,Yjump
	Move.w	#$fffe,Xjump
	Clr.b	Braking
	
	Tst.w	Fdir
	Beq	Pfrm60b
	
	Move.w	#31,Xoff
	Addi.l	#1,Xmap
	
	Bra	Set_SPtile_Down
Pfrm60b:	
	Clr.w	Yoff
	Subi.l	#1,Ymap
	
	Bra	Set_SPtile_Down

Pfrm61:
	Cmpi.b	#61,d2
	Bne	Pfrm62

	Tst.w	Standon
	Bne	Pfrm61b

	Cmpi.w	#12,d7
	Bgt	Return_Loop

Pfrm61b:
	
	Move.w	#8,FrDir
	Move.w	#3,Surface
	
	Move.w	Xoff,d0
	Moveq.w	#12,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Settle
	
Pfrm62:
	Cmpi.b	#62,d2
	Bne	Pfrm63
	
	Tst.w	Standon
	Bne	Pfrm62b

	Cmpi.w	#6,d7
	Bgt	Return_Loop

Pfrm62b:
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Moveq.w	#13,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Settle

Pfrm63:
	Cmpi.b	#63,d2
	Bne	Pfrm64

	Tst.w	Standon
	Bne	Pfrm63b

	Cmpi.w	#6,d7
	Bgt	Return_Loop

Pfrm63b:	
	Move.w	#1,FrDir
	Clr.w	Surface

	Move.w	Xoff,d0
	Moveq.w	#14,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Settle
	
Pfrm64:
	Cmpi.b	#64,d2
	Bne	Pfrm65

	Tst.w	Standon
	Bne	Pfrm64b

	Cmpi.w	#12,d7
	Bgt	Return_Loop

Pfrm64b:
	Move.w	#2,FrDir
	Move.w	#4,Surface
	
	Move.w	Xoff,d0
	Moveq.w	#15,d1
	Bsr	Get_Coord
	Move.w	d1,Yoff
	Bra	Settle

Pfrm65:
	Cmpi.b	#65,d2
	Bne 	Pfrm66
	
	Clr.b	Braking
	Move.w	#$0002,Yjump
	Move.w	#$0002,Xjump
	
	Tst.w	Fdir
	Beq	Pfrm65b
	
	Clr.w	Yoff
	Subi.l	#1,Ymap
	
	Bra	Set_SPtile_Down

Pfrm65b:	
	Clr.w	Xoff
	Subi.l	#1,Xmap
	
	Bra	Set_SPtile_Down

Pfrm66:	
	Cmpi.w	#2,Detect
	Bne	Pfrm68
	
	Cmpi.b	#66,d2
	Bne	Pfrm67
	
	Moveq.w	#46,d2
	Bra	Pfrm46

Pfrm67:	
	Cmpi.w	#2,Detect
	Bne	Pfrm68
	
	Cmpi.b	#67,d2
	Bne	Pfrm68
	
	Moveq.w	#47,d2
	Bra	Pfrm47

Pfrm68:	
	Cmpi.b	#68,d2
	Bne	Pfrm69
	
	Move.w	#2,Detect
	Moveq.w	#48,d2
	Bra	Pfrm48

Pfrm69:	
Pfrm70:	
Pfrm71:	
Pfrm72:	
	Cmpi.w	#2,Detect
	Bne	Pfrm73
	
	Cmpi.b	#72,d2
	Bne	Pfrm73
	
	Moveq.w	#52,d2
	Bra	Pfrm52

Pfrm73:
Pfrm74:	
	Cmpi.w	#2,Detect
	Bne	Pfrm75
	
	Cmpi.b	#74,d2
	Bne	Pfrm75
	
	Moveq.w	#54,d2
	Bra	Pfrm54

Pfrm75:
Pfrm76:	
	Cmpi.w	#2,Detect
	Bne	Pfrm77
	
	Cmpi.b	#76,d2
	Bne	Pfrm77
	
	Moveq.w	#56,d2
	Bra	Pfrm56

Pfrm77:	
Pfrm78:	
	Cmpi.w	#2,Detect
	Bne	Pfrm79
	
	Cmpi.b	#78,d2
	Bne	Pfrm79
	
	Moveq.w	#58,d2
	Bra	Pfrm58

Pfrm79:	
Pfrm80:	
	Cmpi.w	#2,Detect
	Bne	Pfrm81
	
	Cmpi.b	#80,d2
	Bne	Pfrm81
	
	Moveq.w	#60,d2
	Bra	Pfrm60

Pfrm81:	
	Cmpi.w	#2,Detect
	Bne	Pfrm83
	
	Cmpi.b	#81,d2
	Bne	Pfrm82
	
	Moveq.w	#61,d2
	Bra	Pfrm61

Pfrm82:	
	Cmpi.w	#2,Detect
	Bne	Pfrm83
	
	Cmpi.b	#82,d2
	Bne	Pfrm83
	
	Moveq.w	#62,d2
	Bra	Pfrm62

Pfrm83:	
	Cmpi.w	#1,Detect
	Bne	Pfrm86
	
	Cmpi.b	#83,d2
	Bne	Pfrm84
	
	Moveq.w	#63,d2
	Bra	Pfrm63
Pfrm84:	
Pfrm85:	
Pfrm86:
	Cmpi.w	#1,Detect
	Bne	Pfrm90
	
	Cmpi.b	#86,d2
	Bne	Pfrm87
	
	Moveq.w	#26,d2
	Bra	Pfrm26

Pfrm87:
	Cmpi.b	#87,d2
	Bne	Pfrm88
	
	Moveq.w	#26,d2
	Bra	Pfrm26

Pfrm88:
	Cmpi.b	#88,d2
	Bne	Pfrm89
	
	Moveq.w	#27,d2
	Bra	Pfrm27

Pfrm89:
	Cmpi.b	#89,d2
	Bne	Pfrm90
	
	Moveq.w	#28,d2
	Bra	Pfrm28

Pfrm90:
	Cmpi.w	#2,Detect
	Bne	Pfrm91
	
	Cmpi.b	#90,d2
	Bne	Pfrm91
	
	Moveq.w	#2,d2
	Bra	Pfrm2

Pfrm91:
	Cmpi.w	#1,Detect
	Bne	Pfrm92
	
	Cmpi.b	#91,d2
	Bne	Pfrm92
	
	Moveq.w	#3,d2
	Bra	Pfrm3

Pfrm92:
	Cmpi.w	#1,Detect
	Bne	Pfrm94
	
	Cmpi.b	#92,d2
	Bne	Pfrm93
	
	Moveq.w	#4,d2
	Bra	Pfrm4

Pfrm93:	
	Cmpi.b	#93,d2
	Bne	Pfrm94
	
	Moveq.w	#5,d2
	Bra	Pfrm5
	
Pfrm94:	
	Cmpi.w	#2,Detect
	Bne	Pfrm96
	
	Cmpi.b	#94,d2
	Bne	Pfrm95
	
	Moveq.w	#6,d2
	Bra	Pfrm6

Pfrm95:	
	Cmpi.b	#95,d2
	Bne	Pfrm96
	
	Moveq.w	#7,d2
	Bra	Pfrm7
	
Pfrm96:
	Cmpi.w	#1,Detect
	Bne	Pfrm100
	
	Cmpi.b	#96,d2
	Bne	Pfrm97
	
	Moveq.w	#22,d2
	Bra	Pfrm22

Pfrm97:
	Cmpi.b	#97,d2
	Bne	Pfrm98
	
	Moveq.w	#23,d2
	Bra	Pfrm24

Pfrm98:
	Cmpi.b	#98,d2
	Bne	Pfrm99
	
	Moveq.w	#24,d2
	Bra	Pfrm24

Pfrm99:
	Cmpi.b	#99,d2
	Bne	Pfrm100
	
	Moveq.w	#25,d2
	Bra	Pfrm25
	
Pfrm100:	
;	Cmpi.w	#2,Detect
;	Bne	Pfrm101
	
;	Cmpi.b	#100,d2
;	Bne	Pfrm101
	
;	Moveq.b	#8,d2
;	Bra	Pfrm8

Pfrm101:
;	Cmpi.w	#1,Detect
;	Bne	Pfrm102
	
;	Cmpi.b	#101,d2
;	Bne	Pfrm102
	
;	Moveq.b	#9,d2
;	Bra	Pfrm9

Pfrm102:
	Cmpi.w	#2,Detect
	Bne	Pfrm103
	
	Cmpi.b	#102,d2
	Bne	Pfrm103
	
	Move.w	#10,d2
	Bra	Pfrm10

Pfrm103:		
	Cmpi.w	#1,Detect
	Bne	Pfrm104

	Cmpi.b	#103,d2
	Bne	Pfrm104	
	
	Move.w	#11,d2
	Bra	Pfrm11

Pfrm104:
	Cmpi.b	#104,d2
	Bne	Pfrm105

	Cmpi.w	#1,Detect
	Bne	Pfrm104b

	Moveq.w	#1,d2
	Bra	Pfrm1
	
Pfrm104b:	
	Cmpi.w	#2,Detect
	Bne	Pfrm105

	Move.w	#10,d2
	Bra	Pfrm10

Pfrm105:
	Cmpi.b	#105,d2
	Bne	Pfrm106

	Cmpi.w	#2,Detect
	Bne	Pfrm105b

	Moveq.w	#1,d2
	Bra	Pfrm1

Pfrm105b:	
	Cmpi.w	#1,Detect
	Bne	Pfrm106

	Move.w	#11,d2
	Bra	Pfrm11
	
Pfrm106:
	Cmpi.b	#106,d2
	Bne	Pfrm107

	Move.w	#$0000,Xjump
	Move.w	#$fffe,Yjump
	Cmpi.w	#$7fff,Vely
	Blo	Godn_106	

	Tst.w	Jump
	Bne	Return_Loop

	Tst.w	Sidewalk
	Beq	Return_Loop
		
	Move.w	#5,FrDir
	Move.w	#6,Surface
	Bra	Settle

Godn_106:
	Move.w	#1,Jump
	Bra	Return_Loop

Pfrm107:
	Cmpi.b	#107,d2	
	Bne	Pfrm108
	
	Cmpi.w	#2,Detect
	Bne	Pfrm107b

	Moveq.b	#1,d2
	Bra	Pfrm1

Pfrm107b:
	Moveq.b	#114,d2		
	Bra	Pfrm114

Pfrm108:
	Cmpi.b	#108,d2	
	Bne	Pfrm109
	
	Cmpi.w	#1,Detect
	Bne	Pfrm108b

	Moveq.b	#1,d2
	Bra	Pfrm1
	
Pfrm108b:
	Moveq.b	#114,d2		
	Bra	Pfrm114

Pfrm109:
	Cmpi.b	#109,d2		; (Spikes)
	Bne	Pfrm110

	Clr.b	Invulnerable	
	Move.w	#8,Cf_Hit_Vely			; Impact velocity adjustment 
	Move.w	#7,Cf_Hit_Velx_Lt
	Move.w	#$FFF9,Cf_Hit_Velx_Rt
	Move.w	#1,Hit
	Rts

Pfrm110:
	Cmpi.b	#110,d2
	Bne	Pfrm111
	
	Clr.w	Surface
	Move.w	#1,Detect
	Move.w	#31,Yoff
	Bra	Settle

Pfrm111:
	Cmpi.b	#111,d2
	Bne	Pfrm112

	Move.w	#1,Detect
	Bra	Return_Loop
	
Pfrm112:
	Cmpi.b	#112,d2
	Bne	Pfrm113

	Move.w	#2,Detect
	Bra	Return_Loop

Pfrm113:
	Cmpi.b	#113,d2
	Bne	Pfrm114
	
	Clr.w	Surface
	Move.w	#2,Detect
	Move.w	#31,Yoff
	Bra	Settle

Pfrm114:	
	Cmpi.b	#114,d2
	Bne	Pfrm115

	Move.w	#2,Can_Dust
	Subi.l	#1,Ymap
	Clr.w	Yoff

	Bra	Set_SPtile_Down
	Bra	Settle

Pfrm115:	
	Cmpi.b	#115,d2
	Bne	Pfrm116

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Tst.w	Standon
	Beq	Return_Loop
	
	Move.w	#2,Can_Dust
	Addi.l	#1,Ymap
	Move.w	#31,Yoff

	Bra	Set_SPtile_Down
	Bra	Settle

Pfrm116:
	Cmpi.w	#2,Detect
	Bne	Pfrm118

	Cmpi.b	#116,d2
	Bne	Pfrm117

	Move.w	#114,d2
	Bra	Pfrm114
	
Pfrm117:	
	Cmpi.b	#117,d2
	Bne	Pfrm118

	Move.w	#115,d2
	Bra	Pfrm115

Pfrm118:
Pfrm119:
Pfrm120:
Pfrm121:
Pfrm122:
Pfrm123:
Pfrm124:
Pfrm125:
Pfrm126:
Pfrm127:
Pfrm128:
Pfrm129:
Pfrm130:
Pfrm131:
Pfrm132:
Pfrm133:
Pfrm134:
Pfrm135:
Pfrm136:
Pfrm137:
Pfrm138:
Pfrm139:
Pfrm140:
Pfrm141:
Pfrm142:
Pfrm143:
Pfrm144:
Pfrm145:
Pfrm146:
Pfrm147:
Pfrm148:
Pfrm149:
Pfrm150:
Pfrm151:
Pfrm152:
Pfrm153:
Pfrm154:
Pfrm155:

Pfrm156:
	Cmpi.b	#156,d2
	Bne	Pfrm157
	Bra	Return_Loop

Pfrm157:
	Cmpi.b	#157,d2
	Bne	Pfrm158
	Bra	Return_Loop

Pfrm158:
Pfrm159:
Pfrm160:
Pfrm161:

Pfrm162:
	Cmpi.b	#162,d2
	Bne	Pfrm163
	
	Cmpi.w	#20,d7
	Bhi	Pfrm162b
	
	Addi.w	#1,Emeralds
	Move.b	#187,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)
	JEWELS_UPDATE

Pfrm162b:
	Move.b	#115,d2
	Bra	Pfrm115
		
Pfrm163:			
	Cmpi.b	#163,d2
	Bne	Pfrm164
	
	Cmpi.w	#20,d7
	Bhi	Return_Loop
	
	Addi.w	#1,Emeralds
	Move.b	#188,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)
	JEWELS_UPDATE
	Bra	Return_Loop

Pfrm164:			
	Cmpi.b	#164,d2
	Bne	Pfrm165
	
	Cmpi.w	#20,d7
	Bhi	Return_Loop
	
	Addi.w	#1,Emeralds
	Move.b	#189,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)
	JEWELS_UPDATE
	Bra	Return_Loop

Pfrm165:
Pfrm166:
Pfrm167:	
	Cmpi.b	#167,d2
	Bne	Pfrm168

	Bra	Return_Loop
Pfrm168:
Pfrm169:	
	Cmpi.b	#169,d2
	Bne	Pfrm170
	
	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Cmpi.w	#20,d7
	Bhi	Return_Loop

	Move.b	#1,Spring	
	Move.w	#24,Vely
	Clr.w	Hit
	Clr.b	Spin
	Clr.b	Slide
	
	Move.b	#185,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	(a0,d0)
	Bra	Return_Loop

Pfrm170:
Pfrm171:
Pfrm172:
	Cmpi.b	#172,d2
	Bne	Pfrm173
	
	Cmpi.w	#20,Yoff
	Bhi	Return_Loop
	
	Move.w	#1,Hit
	Move.b	#$FF,Energy
	Clr.b	Invulnerable
	Bra	Return_Loop

Pfrm173:
	Cmpi.b	#173,d2
	Bne	Pfrm174
	
	Clr.w	Left_Blocked
	Clr.w	Right_Blocked

	Move.w	#1,FrDir
	Move.w	#31,Yoff
	Clr.w	Surface

	Subi.w	#2,Xoff
	Bpl	Settle
	Addi.w	#32,Xoff
	Addi.l	#1,Xmap
	Bra	Settle

Pfrm174:
	Cmpi.b	#174,d2
	Bne	Pfrm175
	
	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Move.w	#1,FrDir
	Clr.w	Brgdn
	Clr.w	Surface

	Cmpi.w	#16,Xoff
	Bhs	Sec_Brg
	Move.w	#1,Brgdn
	Move.w	#25,Yoff
	Bra	Settle

Sec_Brg:	
	Move.w	#2,Brgdn
	Move.w	#25,Yoff
	Bra	Settle
		
Pfrm175:
Pfrm176:
Pfrm177:
Pfrm178:	
Pfrm179:	
	Cmpi.b	#179,d2
	Bne	Pfrm180

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop
	
	Tst.w	Dpfstand
	Beq	Return_Loop
	Move.w	#31,Yoff
	Move.w	#1,FrDir
	Clr.w	Surface

	Bra	Settle
Pfrm180:
Pfrm181:
Pfrm182:
	Cmpi.b	#182,d2
	Bne	Pfrm183

	Cmpi.w	#$7fff,Vely
	Blo	Return_Loop

	Clr.w	Surface
	Move.w	#1,FrDir
	Move.w	#1,Fpform
	Move.w	#28,Yoff
	Bra	Settle	

	Clr.w	Standon
	Bra	Return_Loop

Pfrm183:
Pfrm184:
Pfrm185:
Pfrm186:
Pfrm187:
Pfrm188:
Pfrm189:
Pfrm190:
Pfrm191:
Pfrm192:
Pfrm193:
Pfrm194:
Pfrm195:
Pfrm196:
Pfrm197:
Pfrm198:
Pfrm199:
Pfrm200:
Pfrm201:
Pfrm202:
Pfrm203:
Pfrm204:
	Cmpi.b	#204,d2
	Bne	Pfrm205

	Move.b	#209,d2
	Bra	Pfrm209

Pfrm205:
	Cmpi.b	#205,d2
	Bne	Pfrm206
	
	Cmpi.w	#1,Detect
	Bne	Pfrm205b
	
	Move.w	#2,d2
	Bra	Pfrm2

Pfrm205b:	
	Move.w	#3,d2
	Bra	Pfrm3

Pfrm206:
	Cmpi.b	#206,d2
	Bne	Pfrm207

	Cmpi.w	#1,Detect
	Bne	Pfrm206b

	Moveq.w	#1,d2
	Bra	Pfrm1
	
Pfrm206b:	
	Cmpi.w	#2,Detect
	Bne	Pfrm207

	Move.w	#10,d2
	Bra	Pfrm10

Pfrm207:
	Cmpi.b	#207,d2
	Bne	Pfrm208

	Cmpi.w	#2,Detect
	Bne	Pfrm207b

	Moveq.w	#1,d2
	Bra	Platform_Detected
Pfrm207b:	
	Cmpi.w	#1,Detect
	Bne	Pfrm208

	Move.w	#11,d2
	Bra	Pfrm11

Pfrm208:
Pfrm209:
	Cmpi.b	#209,d2
	Bne	Pfrm210

	Move.w	#1,FrDir
	Move.w	#31,Yoff
	Move.w	#1,NJump
	Clr.w	Surface
	Bra	Settle
	
Pfrm210:	
	Cmpi.b	#210,d2
	Bne	Pfrm211
	
	Move.w	#1,Detect
	Moveq.w	#49,d2
	Bra	Pfrm49

Pfrm211:	
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#211,d2
	Bne	Pfrm212
	
	Moveq.w	#50,d2
	Bra	Pfrm50


Pfrm212:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#212,d2
	Bne	Pfrm213
	
	Moveq.w	#51,d2
	Bra	Pfrm51

Pfrm213:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#213,d2
	Bne	Pfrm214
	
	Moveq.w	#53,d2
	Bra	Pfrm53

Pfrm214:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#214,d2
	Bne	Pfrm215
	
	Moveq.w	#55,d2
	Bra	Pfrm55

Pfrm215:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#215,d2
	Bne	Pfrm216
	
	Moveq.w	#57,d2
	Bra	Pfrm57

Pfrm216:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#216,d2
	Bne	Pfrm217
	
	Moveq.w	#59,d2
	Bra	Pfrm59

Pfrm217:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#217,d2
	Bne	Pfrm218
	
	Moveq.w	#63,d2
	Bra	Pfrm63

Pfrm218:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#218,d2
	Bne	Pfrm219
	
	Moveq.w	#64,d2
	Bra	Pfrm64

Pfrm219:
	Cmpi.w	#1,Detect
	Bne	Pfrm220
	
	Cmpi.b	#219,d2
	Bne	Pfrm220
	
	Moveq.w	#65,d2
	Bra	Pfrm65

Pfrm220:

Pfrm221:		
	Cmpi.b	#221,d2
	Bne	Pfrm222

	Clr.w	Surface
	Moveq.b	#1,d2
	Bra	Pfrm1

Pfrm222:
	Cmpi.b	#222,d2
	Bne	Pfrm223
	
	Moveq.w	#2,d2
	Bra	Pfrm2
Pfrm223:
	Cmpi.b	#223,d2
	Bne	Pfrm224

	Moveq.w	#3,d2
	Bra	Pfrm3
Pfrm224:
	Cmpi.b	#224,d2
	Bne	Pfrm225

	Moveq.w	#4,d2
	Bra	Pfrm4
Pfrm225:
	Cmpi.b	#225,d2
	Bne	Pfrm226
	
	Moveq.w	#5,d2
	Bra	Pfrm5
Pfrm226:
	Cmpi.b	#226,d2
	Bne	Pfrm227
	
	Moveq.w	#6,d2
	Bra	Pfrm6
Pfrm227:
	Cmpi.b	#227,d2
	Bne	Pfrm228
	
	Moveq.w	#7,d2
	Bra	Pfrm7
Pfrm228:
	Cmpi.b	#228,d2
	Bne	Pfrm229
	
	Moveq.w	#114,d2
	Bra	Pfrm114
Pfrm229:
	Cmpi.b	#229,d2
	Bne	Pfrm230
	
	Moveq.w	#115,d2
	Bra	Pfrm115

Pfrm230:
	Cmpi.b	#230,d2
	Bne	Pfrm231

	Moveq.w	#22,d2
	Bra	Pfrm22

Pfrm231:
	Cmpi.b	#231,d2
	Bne	Pfrm232

	Moveq.w	#23,d2
	Bra	Pfrm23

Pfrm232:
	Cmpi.b	#232,d2
	Bne	Pfrm233

	Moveq.w	#24,d2
	Bra	Pfrm24

Pfrm233:
	Cmpi.b	#233,d2
	Bne	Pfrm234

	Moveq.w	#25,d2
	Bra	Pfrm25

Pfrm234:
	Cmpi.b	#234,d2
	Bne	Pfrm235
	
	Moveq.w	#26,d2
	Bra	Pfrm26

Pfrm235:
	Cmpi.b	#235,d2
	Bne	Pfrm236
	
	Moveq.w	#27,d2
	Bra	Pfrm27

Pfrm236:
	Cmpi.b	#236,d2
	Bne	Pfrm237
	
	Moveq.w	#28,d2
	Bra	Pfrm28

Pfrm237:
	Cmpi.b	#237,d2
	Bne	Pfrm238

	Moveq.w	#29,d2
	Bra	Pfrm29

Pfrm238:
;	Cmpi.w	#2,Detect
;	Bne	Pfrm239
	
;	Cmpi.b	#238,d2
;	Bne	Pfrm239
	
;	Moveq.b	#8,d2
;	Bra	Pfrm8

Pfrm239:
;	Cmpi.w	#1,Detect
;	Bne	Pfrm240
	
;	Cmpi.b	#239,d2
;	Bne	Pfrm240
	
;	Moveq.b	#9,d2
;	Bra	Pfrm9

Pfrm240:
	Clr.w	Standon
	Bra	Return_Loop
		
Settle:
	Tst.w	Standon
	Bne	Settle_On

	Cmpi.w	#7,Surface
	Bne	Set2
	Move.w	Vely,Velx
	Bra	Settle_On

Set2:
	Cmpi.w	#5,Surface
	Bne	Set3
	Move.w	Vely,Velx
	Neg.w	Velx
	Bra	Settle_On

Set3:
	Cmpi.b	#61,d2
	Bne	Set4
	Move.w	Vely,d0
	Ext.l	d0
	Divs	#2,d0
	Move.w	d0,Velx
	Bra	Settle_On

Set4:
	Cmpi.b	#64,d2
	Bne	Settle_On
	Move.w	Vely,d0
	Neg.w	d0
	Ext.l	d0
	Divu	#2,d0
	Move.w	d0,Velx
	Bra	Settle_On	

Settle_On:
	Tst.w	Can_Dust
	Beq	No_Dust_On_Land
	Move.w	#1,Dust_Delay
	Move.w	#152,XDust
	Move.w	#143,YDust	

No_Dust_On_Land:
	Clr.w	Vely
	Clr.w	Jump
	Clr.b	Spring
	Move.w	#1,Stand
	Move.w	#1,Standon
	Clr.b	Spin
	Clr.w	Hit
	Rts	
	
*****************************************
*	Determine what is to the left, 		* 
*   right and above player sprite 		*
*****************************************
Set_SPtile_Middle:
	Clr.b	Hang

	Move.l	SMap,d0		; Mid-tile
	Move.l	Map,a0
	
	Lea	8(a0,d0.l),a0

	Moveq.l	#4,d0
	Moveq.l	#3,d1
	
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Pfrm1_CMid
	Bra	Check_Over

Pfrm1_CMid:
	Cmpi.b	#8,d2		;(Wall)
	Bne	Pfrm2_CMid

	Clr.b	Braking
	Move.w	#3,Velx
	Rts

Pfrm2_CMid:
	Cmpi.b	#9,d2		;(Wall)
	Bne	Pfrm3_CMid
	
	Clr.b	Braking
	Move.w	#$fffd,Velx
	Rts

Pfrm3_CMid
	Tst.w	Velx
	Beq	No_Lateral_Check

	Cmpi.b	#12,d2		;(Wall)
	Beq	Go_Left

	Cmpi.b	#13,d2
	Beq	Go_Right

	Cmpi.b	#14,d2		;(Wall)
	Beq	Go_Left

	Cmpi.b	#15,d2
	Beq	Go_Right

No_Lateral_Check:
	Cmpi.b	#17,d2
	Beq	Saqaf
	
	Cmpi.b	#18,d2
	Beq	Saqaf

	Cmpi.b	#19,d2
	Beq	Saqaf

Pfrm4_CMid:
	Cmpi.b	#20,d2
	Bne	Pfrm5_CMid

	Cmpi.w	#14,Yoff
	Blo	Return_Loop_Two

	Btst	#$7,Mousekey		
	Beq	Return_Loop_Two

	Move.w	#28,Yoff
	Move.w	#132,YChar
	Bra	Settle_On2

Pfrm5_CMid:	
	Cmpi.b	#21,d2
	Bne	Pfrm6_CMid
	Bra	Saqaf

Pfrm6_CMid:
	Cmpi.b	#160,d2		; Restart point (Animated computer)
	Bne	Pfrm7_CMid
	
	Tst.b	Crouch
	Beq	Not_Selected

	Move.l	Xmap,XStart
	Move.l	Ymap,YStart
	Move.w	#008,XStartb
	Move.w	Yoff,YStartb
	
	Clr.b	0(a0,d0)
	Sub.l	SMap,a0
	Move.b	#197,0(a0,d0)

Not_Selected:	
	Rts

Pfrm7_CMid:	
	Cmpi.b	#165,d2		; Barrier
	Bne	Pfrm8_CMid
	Bra	Go_Right		

Pfrm8_CMid:
	Cmpi.b	#166,d2		; Barrier
	Bne	Pfrm9_CMid
	Bra	Go_Right		

Pfrm9_CMid:
	Cmpi.b	#161,d2     ; Replenish energy
	Bne	Pfrm10_CMid

	Cmpi.b	#2,Energy
	Blo	Add_Energy
	Rts

Add_Energy:
	Addi.b	#1,Energy
	ENERGY_UPDATE
	Rts

Pfrm10_CMid:			
	Cmpi.b	#162,d2		; Emerald
	Bne	Pfrm11_CMid
	
	Cmpi.w	#10,Yoff
	Blo	Check_Over
	
	Addi.w	#1,Emeralds

	Move.b	#187,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)

	JEWELS_UPDATE
	Rts

Pfrm11_CMid:			
	Cmpi.b	#163,d2		; Emerald
	Bne	Pfrm12_CMid
	
	Cmpi.w	#10,Yoff
	Blo	Check_Over
	
	Addi.w	#1,Emeralds

	Move.b	#188,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)
	
	JEWELS_UPDATE
	Rts		

Pfrm12_CMid:			
	Cmpi.b	#164,d2		; Emerald
	Bne	Pfrm13_CMid
	
	Cmpi.w	#10,Yoff
	Blo	Check_Over
	
	Addi.w	#1,Emeralds

	Move.b	#189,(a0,d0)
	Sub.l	SMap,a0
	Clr.b	0(a0,d0)

	JEWELS_UPDATE
	Rts

Pfrm13_CMid:			
	Cmpi.b	#170,d2		; (Spring -28)
	Bne	Pfrm14_CMid
	Move.w	#$FFE4,Velx
	Clr.b	Braking
	Rts

Pfrm14_CMid:
	Cmpi.b	#171,d2		; (Spring  28)
	Bne	Pfrm15_CMid
	Move.w	#28,Velx
	Clr.b	Braking
	Rts

Pfrm15_CMid:
	Cmpi.b	#109,d2					; Spikes
	Bne	Pfrm16_CMid

	Clr.b	Invulnerable
	Move.w	#8,Cf_Hit_Vely			; Impact from collision
	Move.w	#7,Cf_Hit_Velx_Lt
	Move.w	#$FFF9,Cf_Hit_Velx_Rt
	Move.w	#1,Hit
	Rts

Pfrm16_CMid:
	Cmpi.b	#238,d2	
	Bne	Pfrm17_CMid
	
	Cmpi.w	#1,Detect
	Bne	Pfrm17_CMid

	Moveq.b	#8,d2
	Bra	Pfrm1_CMid

Pfrm17_CMid:
	Cmpi.b	#100,d2	
	Bne	Pfrm18_CMid
	
	Cmpi.w	#2,Detect
	Bne	Pfrm18_CMid

	Moveq.b	#9,d2
	Bra	Pfrm2_CMid

Pfrm18_CMid:
	Cmpi.b	#101,d2	
	Bne	Pfrm19_CMid
	
	Cmpi.w	#1,Detect
	Bne	Pfrm19_CMid

	Moveq.b	#8,d2
	Bra	Pfrm1_CMid

Pfrm19_CMid:
	Cmpi.b	#239,d2	
	Bne	Check_Over
	
	Cmpi.w	#2,Detect
	Bne	Check_Over

	Moveq.b	#9,d2
	Bra	Pfrm2_CMid

Check_Over:
	Tst.w	VChange
	Bne	Return_Loop_Two

	Cmpi.w	#16,Xoff
	Bhi	Set_SPtile_Middle2

	Move.l	SMap,d0
	Move.l	Map,a0
	
	Lea	8(a0,d0.l),a0

	Moveq.l	#5,d0
	Moveq.l	#3,d1
	
	Cmpi.w	#16,Yoff
	Bhs	No_BCheck
	Addi.l	#1,d1

No_BCheck:	
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Platform_Detected_Mid
	Bra	Set_SPtile_Middle2
	
Platform_Detected_Mid:
	Cmpi.b	#12,d2
	Beq	Wall_Right

	Cmpi.b	#14,d2
	Beq	Wall_Right

	Cmpi.b	#18,d2
	Beq	Wall_Right

	Cmpi.b	#109,d2		; Spikes
	Beq	Wall_Right		

	Cmpi.b	#165,d2
	Beq	Wall_Right		

	Cmpi.b	#166,d2
	Beq	Wall_Right		

Set_SPtile_Middle2:
	Cmpi.w	#16,Xoff
	Blo	Return_Loop_Two

	Move.l	SMap,d0
	Move.l	Map,a0
	
	Lea	8(a0,d0.l),a0

	Moveq.l	#3,d0
	Moveq.l	#3,d1

	Cmpi.w	#16,Yoff
	Bhs	No_CCheck
	Addi.l	#1,d1

No_CCheck:		
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0

	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Pfrm13_BMid	
	Bra	Return_Loop_Two

Pfrm13_BMid:
	Cmpi.b	#13,d2
	Beq	Wall_Left

	Cmpi.b	#15,d2
	Beq	Wall_Left

	Cmpi.b	#19,d2
	Beq	Wall_Left

	Cmpi.b	#109,d2		; Spikes
	Beq	Wall_Left
	
	Cmpi.b	#165,d2
	Beq	Wall_Left		

	Cmpi.b	#166,d2
	Beq	Wall_Left	

Return_Loop_Two:
	Rts	
	
Settle_On2:
	Tst.w	Velx
	Beq	Hang_In_Limits

	Cmpi.w	#$7fff,Velx
	Blo	Now_Check_Pos_HVelx

	Cmpi.w	#$FFFD,Velx
	Bhs	Hang_In_Limits
	Move.w	#$FFFD,Velx
	Bra	Hang_In_Limits

Now_Check_Pos_HVelx:
	Cmpi.w	#3,Velx
	Bls	Hang_In_Limits
	Move.w	#3,Velx
	
Hang_In_Limits:
	Clr.w	Vely
	Clr.w	Jump	
	Clr.w	Hit
	Clr.b	Spin
	Clr.b	Slide
	Move.w	#1,Stand
	Move.b	#1,Hang
	Rts	

Saqaf:
	Move.w	#$ffff,Vely
	Add.l	#1,Ymap
	Move.w	#31,Yoff
	Bra	Check_Over

Go_Left:
	Clr.w	Velx
	Move.w	#16,Xoff
	Subi.l	#1,Xmap
	Rts

Go_Right:
	Clr.w	Velx
	Move.w	#16,Xoff
	Addi.l	#1,Xmap
	Rts

Wall_Right:
	Cmpi.w	#$7fff,Velx
	Blo	Return_Loop_Two

	Move.w	#1,Right_Blocked
	Clr.b	Braking
	Clr.w	Velx
	Move.w	#16,Xoff
	Bra	Return_Loop_Two
	
Wall_Left:
	Tst.w	Velx
	Beq	Return_Loop_Two

	Cmpi.w	#$7fff,Velx
	Bhi	Return_Loop_Two

	Move.w	#1,Left_Blocked
	Clr.b	Braking
	Clr.w	Velx
	Move.w	#16,Xoff
	Bra	Return_Loop_Two

; Fetch Word From Loop Data Table

Get_Coord:	
	Mulu	#2,d0
	Lea	Loop_Data,a0
	Mulu	#64,d1
	Add.w	d1,d0
	Move.w	0(a0,d0),d1
	Rts

*************************************************
*	Check which tiles are near player 			*
************************************************* 	
Check_Near_Tiles:
	Clr.b	Whoopie
	Clr.b	Ext_Whoopie

	Cmpi.w	#12,Xoff
	Bhs	Check_Other_Side

	Move.l	Map,a0
	Move.w	Xmax,d0
	Move.w	Ymax,d1
	Mulu	d1,d0
	
	Lea	8(a0,d0.l),a0
	Moveq.l	#5,d0
	Moveq.l	#4,d1
	
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Check_Other_Side
	
	Move.b	#1,Whoopie

	Cmpi.w	#5,Xoff
	Bhi	No_Ext_Whoopie_A
	Move.b	#1,Ext_Whoopie

No_Ext_Whoopie_A:
	Rts
	
Check_Other_Side:
	Cmpi.w	#20,Xoff
	Bls	Near_Check_Over

	Move.l	Map,a0
	Move.w	Xmax,d0
	Move.w	Ymax,d1
	Mulu	d1,d0
	
	Lea	8(a0,d0.l),a0
	Moveq.l	#3,d0
	Moveq.l	#4,d1
	
	Add.l	Xmap,d0
	Add.l	Ymap,d1
	Mulu	Xmax,d1
	Add.l	d1,d0
	
	Move.b	0(a0,d0),d2
	Tst.b	d2
	Bne	Near_Check_Over

	Move.b	#2,Whoopie

	Cmpi.w	#27,Xoff
	Blo	Near_Check_Over
	Move.b	#1,Ext_Whoopie

Near_Check_Over:
	Rts
	
*************************************************
*	Draw player sprite on screen				*
*************************************************
Draw_Hero:
	Move.l	Sprites,Src
	Move.l	Masks,SrcMask
	Bsr	Which_Frame

	Tst.w	Hit
	Bne	Still_Hit_Flying

	Tst.b	Invulnerable
	Beq	No_Dec_Invulnerable
	Subi.b	#1,Invulnerable

No_Dec_Invulnerable:
	Btst.b	#0,Invulnerable
	Bne	Blaze_Invulnerable

Still_Hit_Flying:
	Subi.w	#1,d0		* Frame
	Move.w	d0,d1		* Fr -> d1
	Divu	#8,d1		* D1 -> X Fr Y Fr
	Move.w	d1,d2		* Y Fr - > d2			
	Swap	d1			* d1 <-> d1
	Mulu.w	#4,d1		* D1 -> Bytes
	Mulu.w	#$400,d2	* D2 -> Bytes	

	Ext.l	d1
	Ext.l	d2
	Add.l	d1,d2
	
	Add.l	d2,Src
	Add.l	d2,SrcMask

	Moveq.l	#0,d0
	Moveq.l	#0,d1

	Move.w	YChar,d0	; Y coordinate
	Mulu	#40,d0
	
	Move.w	XChar,d1	; X coordinate
	Divu	#16,d1		
	Swap	d1		
	Move.w	d1,d2		
	Swap	d1		
	Andi.l	#$ffff,d1	
	Mulu	#2,d1		

	Move.w	Offx,d3		
	Andi.w	#$F,d3
	Sub.w	d3,d2

	Bpl	Shift_All_Right_B
	Addi.w	#16,d2
	Subi.l	#2,d1

	Bpl	Shift_All_Right_B
	Moveq.l	#0,d0

Shift_All_Right_B:
	Move.w	d2,Obx

	Add.l	d1,d0
	Add.l	Currbuffer,d0
	Move.l	d0,Dest

	Moveq.l	#0,d0
	Moveq.l	#0,d7
	
	Cmpi.b	#1,Spring
	Bne	Normal_Size
	Move.w	#$C03,d7
	Bra	Big_Size

Normal_Size:	
	Move.w	#$803,d7

Big_Size:	
	Tst.w	YFlip
	Beq	No_Flip
	
	Addi.l	#$500,Dest
	
	BLITM	Src,Dest,d7,#26,#-46,Obx,#$FFFF,#0,SrcMask
	Bra	Yes_Flip

No_Flip:
	BLITM	Src,Dest,d7,#26,#34,Obx,#$FFFF,#0,SrcMask

Yes_Flip:
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d7
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d7
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d7
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,d7

Blaze_Invulnerable:
	Rts

*************************************************
*	Handle dust animation 						*
*************************************************
Dust_Routine:
	Tst.w	Hit
	Bne	No_Dust

	Tst.b	Cover_Cat
	Bne	No_Dust

	Cmpi.w	#4,Surface
	Bhi	No_Dust

	Tst.b	Slide
	Bne	Do_Dust
	
	Tst.b	Braking
	Bne	Do_Dust

	Tst.w	Dust_Delay
	Bne	Do_Dust	

No_Dust:
	Rts

Do_Dust:
	Addi.w	#1,Dust_Delay
	Cmpi.w	#7,Dust_Delay
	Bls	No_Dust_Reset
	
	Move.w	#152,XDust
	Move.w	#143,YDust
	Clr.w	Dust_Delay
	Rts

No_Dust_Reset:
	Move.w	Velx,d1

	Tst.w	d1
	Beq	Dust_Lab_B
	
	Cmpi.w	#$7FFF,d1
	Bhi	Dust_Lab_A
	
	Cmpi.w	#7,d1
	Bls	Dust_Lab_B
	Move.w	#7,d1
	Bra	Dust_Lab_B
	
Dust_Lab_A:	
	Cmpi.w	#$FFF9,d1
	Bhs	Dust_Lab_B
	Move.w	#$FFF9,d1

Dust_Lab_B:
	Add.w	d1,XDust
	Subi.w	#1,YDust
	Andi.w	#$FF,YDust

	Move.w	Dust_Delay,d0
	Divu	#2,d0
	Andi.l	#%11,d0
	Addi.w	#422,d0	
	
	Move.w	XDust,XSprite_16
	Move.w	YDust,YSprite_16
	Bsr	Sprite_16
	Rts

Sprite_16:
	Move.l	Sprites,Src
	Move.l	Masks,SrcMask

	Subi.w	#1,d0		* Frame
	Move.w	d0,d1		* Fr -> d1
	Divu	#16,d1		* D1 -> X Fr Y Fr
	Move.w	d1,d2		* Y Fr - > d2			
	Swap	d1			* d1 <-> d1
	Mulu.w	#2,d1		* D1 -> Bytes
	Mulu.w	#$200,d2	* D2 -> Bytes	

	Ext.l	d1
	Ext.l	d2
	Add.l	d1,d2
	
	Add.l	d2,Src
	Add.l	d2,SrcMask

	Moveq.l	#0,d0
	Moveq.l	#0,d1

	Move.w	YSprite_16,d0	* Y Coord
	Mulu	#40,d0
	
	Move.w	XSprite_16,d1	* XCoord
	Divu	#16,d1		
	Swap	d1		
	Move.w	d1,d2		
	Swap	d1		
	Andi.l	#$ffff,d1	
	Mulu	#2,d1		

	Move.w	Offx,d3		
	Andi.w	#$F,d3
	Sub.w	d3,d2

	Bpl	Shift_All_Right_C
	Addi.w	#16,d2
	Subi.l	#2,d1

	Bpl	Shift_All_Right_C
	Moveq.l	#0,d0

Shift_All_Right_C:
	Move.w	d2,Obx

	Add.l	d1,d0
	Add.l	Currbuffer,d0
	Move.l	d0,Dest
	
	BLITM	Src,Dest,#$402,#28,#36,Obx,#$FFFF,#0,SrcMask
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,#$402
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,#$402
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,#$402
	Addi.l	#13824,Src
	Addi.l	#10240,Dest
	FBLITM	SrcMask,Src,Dest,#$402
	Rts 	

*************************************************
* Determine player animation frame 				*
*************************************************
Which_Frame:
	Move.w	Dir,Direction
	
	Tst.w	Hit
	Bne	Hit_Frames

	Tst.b	Hang
	Bne	Hanging

	Tst.w	XORFrame
	Bne	Not_Flipped

	Tst.w	YFlip
	Beq	Not_Flipped

	Eor.w	#1,Direction
Not_Flipped:	

	Tst.b	Spring
	Bne	Spring_Jump

	Tst.b	Spin	    	; Spinning?
	Bne	Spinning			; Yes!

	Tst.w	Sidewalk
	Bne	Cont_Move

	Tst.b	Slide
	Bne	Do_Slide

	Tst.w	Stand
	Beq	Cont_Move

	Tst.w	Velx			; Still spinning?
	Beq	Still				; Yes!
	
Cont_Move:
	Move.w	#50,CtrDelay

	Tst.b	Braking
	Bne	Brake_Now
	
	Tst.b	Super_Run
	Bne	Do_Super_Run

	Subi.w	#1,Delay
	Bpl	Cyc_Not_Yet1
		
	Addi.w	#1,Frame	; Increment frame
	Bsr	Get_Delay_Value	; S.F.I.!
	Cmpi.w	#6,Frame	; Repeat animation
	Bls	Cyc_Not_Yet1	; Not yet
	Move.w	#1,Frame	; Reformat frame

Cyc_Not_Yet1:
	Move.w	Frame,d0	

	Tst.w	XORFrame
	Bne	Good_Dir
	
	Tst.w	Direction	; Determine direction
	Bne	Good_Dir
	Addi.w	#6,d0

Good_Dir:	
	Add.w	Surfframe,d0
	Rts	

Do_Super_Run:
	Move.w	Dir,Direction

	Subi.w	#1,Delay
	Bpl	Cyc_Not_Yet0
		
	Addi.w	#1,Frame	; Increment frame
	Bsr	Get_Delay_Value	; S.F.I.!
	Cmpi.w	#4,Frame	
	Bls	Cyc_Not_Yet0
	Move.w	#1,Frame	; Reformat frame

Cyc_Not_Yet0:
	Move.w	Frame,d0	

	Tst.w	Direction	; Determine direction
	Bne	Good_SRun_Dir
	Addi.w	#4,d0

Good_SRun_Dir:	
	Add.w	#84,d0
	Rts	
	
Crouch_Me:
	Move.w	#72,d0
	Tst.w	Direction
	Beq	Good_Dir2
	Subi.w	#1,d0
	Rts	

Still:
	Tst.b	Whoopie
	Bne	Whoops

	Tst.b	Crouch
	Bne	Crouch_Me

	Tst.b	Energy
	Beq	Weak
	
	Tst.w	CtrDelay
	Beq	Sleepy
	Subi.w	#1,CtrDelay

	Move.w	#1,Frame
	Move.w	#59,d0
	Tst.w	Direction
	Bne	Good_Dir2
	Addi.w	#2,d0
Good_Dir2:	
	Rts	

Weak:
	Move.w	#1,Frame
	Move.w	#$61,d0	

	Tst.w	Direction
	Bne	Good_Dir5
	Addi.w	#2,d0

Good_Dir5:	
	Subi.w	#1,WDelay
	Bpl	No_Cyc2
	Move.w	#8,WDelay

	Addi.w	#1,Whoops_Frame
	Andi.w	#1,Whoops_Frame
No_Cyc2:
	Add.w	Whoops_Frame,d0
	Rts	

Stand_Wall_Left:
	Move.w	#$65,d0
	Move.w	#1,Frame
	Rts	

Stand_Wall_Right:
	Move.w	#$66,d0
	Move.w	#1,Frame
	Rts	

Sleepy:
	Tst.w	Left_Blocked
	Bne	Stand_Wall_Left

	Tst.w	Right_Blocked
	Bne	Stand_Wall_Right

	Move.w	#1,Frame
	Move.w	#73,d0	

	Tst.w	Direction
	Bne	Good_Dir6
	Addi.w	#2,d0

Good_Dir6:	
	Subi.w	#1,WDelay
	Bpl	No_Cyc3
	Move.w	#8,WDelay

	Addi.w	#1,Whoops_Frame
	Andi.w	#1,Whoops_Frame
No_Cyc3:
	Add.w	Whoops_Frame,d0
	Rts	

Whoops:
	Move.w	#77,d0
	Cmpi.b	#1,Whoopie
	Beq	Whoops_Over

	Add.w	#2,d0
Whoops_Over:	
	Subi.w	#1,WDelay
	
	Bpl	No_Cyc
	Move.w	#8,WDelay
	Addi.w	#1,Whoops_Frame
	Andi.w	#1,Whoops_Frame	
No_Cyc:
	Add.w	Whoops_Frame,d0
	Tst.b	Ext_Whoopie
	Beq	No_Ext_Whoopie
	Addi.w	#16,d0
No_Ext_Whoopie:	
	Rts	
	
Spinning:
	Move.w	#50,CtrDelay
	Addi.w	#1,Frame
	Cmpi.w	#6,Frame
	Bls	Cyc_Not_Yet2
	Move.w	#1,Frame
	
Cyc_Not_Yet2:	
	Move.w	Frame,d0
	Addi.w	#64,d0
	Tst.w	Direction
	Bne	Good_Dir3
	Move.w	#1,YFlip
Good_Dir3:	
	Rts		
	
Brake_Now:
	Move.w	#1,Frame
	Cmpi.b	#1,Braking
	Bne	Other_BSide
	Move.w	#62,d0
	Rts
	
Other_BSide:	
	Move.w	#60,d0
	Rts	
	
Spring_Jump:
	Move.w	#50,CtrDelay
	Cmpi.b	#2,Spring
	Beq	Hit_Frames

	Move.w	#$67,d0
	Tst.w	Direction
	Bne	Good_Dir4
	Addi.w	#1,d0
Good_Dir4:
	Rts	

Hit_Frames:
	Move.w	#1,Frame
	Move.w	#$52,d0
	Tst.w	Direction
	Bne	Good_Dir7
	Subi.w	#1,d0

Good_Dir7:	
	Rts
	
Do_Slide:
	Tst.w	VChange
	Bne	Cont_Move

	Move.w	#1,Frame
	Move.w	#$53,d0
	Tst.w	Direction
	Bne	Good_Dir8
	Addi.w	#1,d0

Good_Dir8:	
	Rts
	
Hanging:
	Tst.w	Velx
	Beq	Still2

	Move.w	Dir,Direction
	
	Subi.w	#1,Delay
	Bpl	Cyc_Not_Yet4
		
	Addi.w	#1,Frame	; Increase frame
	Bsr	Get_Delay_Value	; S.F.I.!
	Cmpi.w	#4,Frame	; Repeat animation?
	Bls	Cyc_Not_Yet4	; Not yet!
	Move.w	#1,Frame	; Reformat frame

Cyc_Not_Yet4:
	Move.w	Frame,d0	

	Tst.w	Direction	; Determine direction
	Bne	Good_Hang_Dir
	Addi.w	#4,d0

Good_Hang_Dir:	
	Add.w	#50,d0
	Rts	

Still2:
	Move.w	#1,Frame
	Move.w	#49,d0
	Tst.w	Direction
	Bne	Good_Hang_Dir2
	Addi.w	#1,d0
Good_Hang_Dir2:	
	Rts	
	
*************************************************
*	Compute values for delays 					*
*************************************************
Get_Delay_Value:
	Lea	Delay_Vals,a0
	Move.w 	Velx,d0
	Cmpi.w	#$7fff,d0
	Bls	Velx_Not_Negative
	Neg.w	d0

Velx_Not_Negative:
	Move.b	0(a0,d0),d1
	Ext.w	d1
	Move.w	d1,Delay
	Rts
	
*************************************************
*	Delay B										*
*************************************************
Get_XDelay_Value:
	Move.w 	Velx,d0
	Cmpi.w	#$7fff,d0
	Bls	Vx_Not_Negative
	Neg.w	d0

Vx_Not_Negative:
	Move.b	0(a0,d0),d1
	Ext.w	d1
	Rts

*************************************************
*	Wait VBL									*
*************************************************
Wait_VBL:
	Move.l	Vposr,d0
	Lsr.l	#8,d0
	Move.w  d0,d1
	Cmpi.w	#$FC,d1
	Blo.s	Wait_VBL
	Rts

*************************************************
*	Double buffer (flip screen)					*
*************************************************
Flip_Screen:
	Move.w	#$40,$dff096

	Move.l	Copper1,a0
	Move.w	Offx,$9a(a0)
	Move.l	Copper2,a0
	Move.w	Offx,$9a(a0)

	Move.w  #$8040,$dff096						*<--------+	
												*	  |	
*************************************************	  |	
*	Double buffer keeps Bplcon1 unaffected		*	  |	
*************************************************	  |	
												*	  |	
Screen_Swap:									*<--------+
	Move.l	Buffer1,d0
	Cmp.l	Showbuffer,d0
	Beq	Change_Buffer

	Move.l	Buffer1,Showbuffer
	Move.l	Buffer2,Currbuffer
	Move.l	Copper1,Cop1lch
	Move.l	Copper2,Current_Copper
	Bra	Screen_Flipped

Change_Buffer:
	Move.l	Buffer2,Showbuffer	
	Move.l	Buffer1,Currbuffer
	Move.l	Copper2,Cop1lch
	Move.l	Copper1,Current_Copper

Screen_Flipped:
	Rts	
	
*************************************************
*	Render map tiles on screen					*
*************************************************
Draw_Blocks:
	Clr.w	Enemy_Check
	Clr.b	Extra_Blocks
	Clr.b	Do_Mask_Routine

	Move.l	Blocks,Src		; Src = Source Bmap
	Move.l  Currbuffer,Dest
	Move.w	Yoff,d0
	Mulu	#40,d0
	Add.l	d0,Dest

	Moveq.l	#0,d0
	Move.w	Xoff,d0

	Cmpi.w	#16,Xoff
	Blo	No_Extra
	Addi.l	#2,Dest
	Andi.l	#$F,d0

No_Extra:	
	Mulu	#$11,d0
	Move.w	d0,Offx

	INTBLIT	#36
	Moveq.l	#6,d3			; Dest = Dest Bmap

Yloop:						; Xdum,Ydum = Dummy Vars.
	Moveq.l	#8,d4			; Map = Map Start Addr.

Xloop:						; Dummybuffer = Dummy Buf.
	Move.l	Map,a0			; Offx = Xoff mod 16
	Lea     8(a0),a0	
							; Currbuffer = Logical Buffer
	Move.l	Ymap,d6			; Showbuffer = Physical Buffer
	Add.l	d3,d6
	
	Mulu	Xmax,d6
	Add.l	Xmap,d6
	Add.l	d4,d6
	Bra	Animation

No_Anim:
	Move.b	0(a0,d6),d7

Anim_Found:
	Andi.l  #$FF,d7
	Tst.b	d7
	Bne	Nzero

	Move.l	#5,Xdum
	Move.l	#25,Ydum
	Bra	Yzero

Nzero:	
	Tst.b	Extra_Blocks
	Beq	Nzero_Again

	Addi.l	#256,d7
	Clr.b	Extra_Blocks

Nzero_Again:
	Subq.l	#1,d7
	Divu	#10,d7
	Move.l	d7,Ydum
	Swap	d7
	Move.l	d7,Xdum

Yzero:	
	BLOCK   Xdum,Ydum,Src,d4,d3,Dest,#0

No_Draw:
	Dbra	d4,Xloop
	Dbra	d3,Yloop
	
	Move.w	Anim_Ctr,FG_Anim_Ctr
	Addi.w	#1,Anim_Ctr
	Cmpi.w	#48,Anim_Ctr
	Blo	No_Cycle
	Clr.w	Anim_Ctr

No_Cycle:	
	Addi.w	#1,Flick_Ctr
	Andi.w	#1,Flick_Ctr
	Rts

*************************************************
*	Animation									*
*************************************************
Animation:
	Move.l	Map,a1
	Move.l	SMap,d0

	Lea	8(a1,d0.l),a1
	Move.b	0(a1,d6),d7

	Cmpi.b	#150,d7
	Bls	No_Anim
	
	Cmpi.b	#240,d7
	Bhi	No_Anim
	
	Cmpi.b	#200,d7
	Blo	Anim0
	
	Move.b	#1,Do_Mask_Routine
	
Anim0:
	Cmpi.b	#160,d7			; Flicker effect ?
	Bne	Anim0_B

	Move.b	0(a0,d6),d7
	Add.w	Flick_Ctr,d7
	Bra	Anim_Found
	
Anim0_B:
	Cmpi.b	#163,d7			; Round jewels (yellow lozenge)
	Bne	Anim1
	
	Moveq.b	#1,d7
	Move.w	Anim_Ctr,d5
	Andi.l	#%111,d5
	Divu	#4,d5
	Add.w	d5,d7
	Move.b	#1,Extra_Blocks
	Bra	Anim_Found	
	
Anim1:	
	Cmpi.b	#209,d7			; Waterfalls
	Beq	Covered_Anim

	Cmpi.b	#208,d7			; Waterfalls
	Bne	Anim2

Covered_Anim:
	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Move.b	$30(a2,d5),d7
	Bra	Anim_Found

Anim2:
	Cmpi.b	#164,d7			; Jewels (collectibles)
	Beq	Do_Jewel_Anim

	Cmpi.b	#162,d7
	Bne	Anim3
	
Do_Jewel_Anim:
	Lea	Anim,a2
	Move.w	Anim_Ctr,d5
	Lea	$150(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim3:
	Cmpi.b	#177,d7			; Lava
	Bne	Anim4

	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$90(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim4:
	Cmpi.b	#167,d7			; Spikes
	Bne	Anim5

	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$60(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim5:	
	Cmpi.b	#172,d7			; Conveyors/flames
	Bne	Anim6

	Move.w	Anim_Ctr,d5	
	Lea	Anim,a2
	Lea	$120(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim6:
	Cmpi.b	#174,d7			; Bridge
	Bne	Anim7
	
	Tst.w	Brgdn
	Beq	Bridge_Set
	
	Cmpi.w	#4,d3
	Bne	Bridge_Set

	Cmpi.w	#5,d4
	Bne	Check_1
	
	Cmpi.w	#1,Brgdn
	Bne	Bridge_Set

	Move.b	#170,d7
	Bra	Anim_Found
	
Check_1:	
	Cmpi.w	#4,d4
	Bne	Check_2
	
	Cmpi.w	#1,Brgdn
	Bne	Bridge_2

	Move.b	#169,d7
	Bra	Anim_Found
	
Bridge_2:
	Move.b	#170,d7
	Bra	Anim_Found		

Check_2:	
	Cmpi.w	#3,d4
	Bne	Bridge_Set

	Cmpi.w	#2,Brgdn
	Bne	Bridge_Set

	Move.b	#169,d7
	Bra	Anim_Found
	
Bridge_Set:
	Move.b	#166,d7
	Bra	Anim_Found	
		
Anim7:
	Cmpi.b	#165,d7			; Barrier 1
	Bne	Anim8
	
	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$C0(a2),a2
	Move.b	0(a2,d5),d7
	Bra	Anim_Found

Anim8:
	Cmpi.b	#166,d7			; Barrier 2
	Bne	Anim9
	
	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$F0(a2),a2
	Move.b	0(a2,d5),d7
	Bra	Anim_Found
	
Anim9:
	Cmpi.b	#182,d7			; Lowering platform
	Bne	Anim10
	
	Tst.w	Fpform
	Beq	Anim10

	Cmpi.w	#4,d3
	Bne	Anim10

	Cmpi.w	#4,d4
	Bne	Anim10

	Move.w	#175,d7
	Bra	Anim_Found
	
Anim10:	
	Cmpi.b	#178,d7			; Dithering flicker
	Bne	Anim11
	
	Tst.w	Flick_Ctr
	Beq	No_Anim

	Moveq.b	#0,d7
	Bra	Anim_Found

Anim11:
	Cmpi.b	#179,d7			; Disappearing platform
	Bne	Anim12

	Lea	Anim,a2
	Move.w	Anim_Ctr,d5
	Move.b	0(a2,d5),d7

	Clr.w	Dpfstand

	Cmpi.b	#153,d7
	Bne	Anim_Found
	
	Move.w	#1,Dpfstand
	Bra	Anim_Found

Anim12:
	Cmpi.b	#183,d7
	Bne	Anim13

	Move.w	#1,Enemy_Check
	Bra	No_Anim

Anim13:	
	Cmpi.b	#159,d7
	Bne	Anim14

	Move.w	#1,Level_Complete
	Bra	No_Anim

Anim14:
	Cmpi.b	#185,d7			; Spring
	Bne	Anim15
	
	Moveq.l	#0,d5
	Move.b	0(a0,d6),d5

	Lea	Anim,a2
	Lea	$1E0(a2),a2
	Move.b	(a2,d5),d7

	Addq.b	#1,d5
	Move.b	d5,0(a0,d6)

	Cmpi.w	#4,d5
	Bne	Anim_Found

	Move.b	#124,0(a0,d6)
	Move.b	#169,0(a1,d6)
	Bra	Anim_Found

Anim15:	
	Cmpi.b	#189,d7			; Gem explosion A (normal)
	Bne	Anim16
	
	Moveq.l	#0,d5
	Move.b	0(a0,d6),d5

	Lea	Anim,a2
	Lea	$1B0(a2),a2
	Move.b	(a2,d5),d7

	Addq.b	#1,d5
	Move.b	d5,0(a0,d6)

	Tst.b	d7
	Bne	Anim_Found

	Clr.b	0(a0,d6)
	Clr.b	0(a1,d6)
	Bra	Anim_Found

Anim16:	
	Cmpi.b	#190,d7			; Toggle enemy
	Blo	Anim17
	
	Cmpi.b	#200,d7
	Bhs	Anim17
	
	Moveq.l	#0,d5
	Move.b	d7,d5

	Subi.w	#190,d5
	Mulu	#5,d5
	Move.w	d5,Estart
	Bra	No_Anim

Anim17:
	Cmpi.b	#188,d7			; Gem explosion B (in front of wall block) 
	Bne	Anim18
	
	Moveq.l	#0,d5
	Move.b	0(a0,d6),d5
	Move.b	#1,Extra_Blocks

	Lea	Anim,a2
	Lea	$210(a2),a2
	Move.b	(a2,d5),d7

	Addq.b	#1,d5
	Move.b	d5,0(a0,d6)

	Cmpi.b	#177,d7
	Bne	Anim_Found

	Move.b	#177,0(a0,d6)
	Clr.b	0(a1,d6)
	Clr.b	Extra_Blocks
	Bra	Anim_Found
	
Anim18:	
	Cmpi.b	#187,d7			; Gem explosion C (over diagonal)
	Bne	Anim19
	
	Moveq.l	#0,d5
	Move.b	0(a0,d6),d5

	Lea	Anim,a2
	Lea	$1B0(a2),a2
	Move.b	(a2,d5),d7

	Addq.b	#1,d5
	Move.b	d5,0(a0,d6)

	Tst.b	d7
	Bne	Anim_Found

	Clr.b	0(a0,d6)
	Move.b	#115,0(a1,d6)
	Bra	Anim_Found

Anim19:
	Cmpi.b	#161,d7			; Replenisher
	Bne	Anim20

	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$240(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim20:
	Cmpi.b	#157,d7			; Lava
	Bne	Anim21

	Move.l	d3,d5
	Add.l	Ymap,d5
	Mulu	#32,d5
	Move.l	Lava_Anim_Y,d0
	
	Sub.l	d5,d0
	Bmi	No_Anim

	Move.l	Lava_Anim_X,d1
	Sub.l	d0,d1
	
	Move.l	d4,d5
	Add.l	Xmap,d5
	Mulu	#32,d5

	Cmp.l	d1,d5
	Bgt	No_Anim

	Cmpi.l	#4,d4			; Test if player has collided with lava
	Bne	No_Fry

	Cmpi.l	#3,d3
	Bne	No_Fry
	
	Move.w	#1,Hit
	Move.b	#$FF,Energy
	Clr.b	Invulnerable
	
No_Fry:
	Move.w	Anim_Ctr,d5
	Lea	Anim,a2
	Lea	$90(a2),a2
	Move.b	(a2,d5),d7
	Bra	Anim_Found

Anim21:
	Bra	No_Anim			

*************************************************
*	Draw foreground blocks						*
*************************************************
Draw_FG_Blocks:
	Clr.b	Cover_Cat		; Flag determines whether player is hidden

	Move.l	Blocks,Src		; Src = Source Bmap
	Move.l  Currbuffer,Dest
	Move.w	Yoff,d0
	Mulu	#40,d0
	Add.l	d0,Dest

	Cmpi.w	#16,Xoff
	Blo	FG_No_Extra
	Addi.l	#2,Dest
	Move.l	#3,MShift
	Bra	FG_No_Extra_MShift
	
FG_No_Extra:
	Move.l	#4,MShift

FG_No_Extra_MShift:	
	INTBLITM #36
	Move.l	#1,d3			; Dest = Dest Bmap
FG_Yloop:					; Xdum,Ydum = Dummy Vars.
	Move.l	#1,d4			; Map = Map Start Addr.
FG_Xloop:					; Dummybuffer = Dummy Buf.
	Move.l	Xmap,Xdum		; Currbuffer = Logical Buffer
	Move.l	Ymap,Ydum		; Showbuffer = Physical Buffer
	Add.l	d4,Xdum
	Add.l	d3,Ydum
	
	Move.l	MShift,d7
	Add.l	d7,Xdum
	
	Addi.l	#3,Ydum
	Move.l	Ydum,d6
	Mulu	Xmax,d6
	Add.l	Xdum,d6
	Bra	FG_Animation

FG_Anim_Found:
	Ext.l	d7
	Subq.l	#1,d7
	Divu	#10,d7
	Move.l	d7,Ydum
	Swap	d7
	Move.l	d7,Xdum
	
	Add.l	MShift,d4
	Addi.l	#3,d3

	BLOCKM  Xdum,Ydum,Src,d4,d3,Dest,MkBlocks
	Sub.l	MShift,d4
	Subi.l	#3,d3
	
FG_No_Draw:
	Dbra	d4,FG_Xloop
	Dbra	d3,FG_Yloop
	Rts

*************************************************
*	Animation									*
*************************************************
FG_Animation:
	Move.l	Map,a1
	Move.l	a1,a2
	Move.l	SMap,d0

	Lea	8(a1,d0.l),a1
	Move.b	0(a1,d6),d7

	Cmpi.b	#200,d7
	Blo	FG_No_Draw
	
	Cmpi.b	#240,d7
	Bhi	FG_No_Draw

	Move.b	#1,Cover_Cat

	Cmpi.b	#208,d7
	Beq	Anim_Hide
	
	Cmpi.b	#209,d7
	Beq	Anim_Hide

Hide:
	Move.b	8(a2,d6),d7

	Tst.b	d7
	Beq	FG_No_Draw

	Bra	FG_Anim_Found

Anim_Hide:
	Lea	Anim,a2
	Move.w	FG_Anim_Ctr,d5
	Move.b	$30(a2,d5),d7
	Bra	FG_Anim_Found

*************************************************
*	Allocate FAST memory for maps				*
*************************************************
Allocate_Fast:
	Move.l	$4.w,a6

	Clr.l	d1
   	Move.l	#130000,d0
	Jsr	AllocMem(a6)
	Move.l	d0,Map
	Rts

*************************************************
*	Allocate CHIP memory for graphics			*
*************************************************
Allocate_Raster:
	Move.l  Gfxbase,a6

	Move.w  #320,d0
	Move.w  #256*5,d1
	Jsr     AllocRaster(a6)
	Move.l  d0,Buffer1
	
	Move.w  #320,d0
	Move.w  #256*5,d1
	Jsr     AllocRaster(a6)
	Move.l  d0,Buffer2
   	
   	Move.w	#320,d0
	Move.w	#832*5,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Blocks

   	Move.w	#3388,d0
	Move.w	#8,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Copper1

   	Move.w	#3388,d0
	Move.w	#8,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Copper2

   	Move.w	#256,d0
	Move.w	#432*5,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Sprites

	Move.w	#256,d0
	Move.w	#432,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Masks

	Move.w	#320,d0
	Move.w	#832,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,MkBlocks
	
	Move.w	#320,d0
	Move.w	#256*5,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Enemies
	
	Move.w	#320,d0
	Move.w	#256,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,MKEnemies
	
	Move.w	#320,d0
	Move.w	#48,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Font

	Move.w	#320,d0
	Move.w	#16,d1
	Jsr	AllocRaster(a6)
	Move.l	d0,Panel

;	Move.w	#320,d0			; Mayby it works
;	Move.w	#256*4,d1		; on the 500+, 1200
;	Jsr	AllocRaster(a6)		; and 600 range of
;	Move.l	d0,Music_Start	; computers

	Rts

*************************************************
*	Set up copper lists							*
*************************************************
Copper_Setup:
	INSCOP	Buffer1,Copper1,#$502
	INSCOP	Buffer2,Copper2,#$502	
	Rts

*************************************************
*	Clear buffer (d0 = size)					*
*************************************************
Clear:
	Clr.l 	(a0)+
	Dbra  	d0,Clear
	Rts

*************************************************
*	Wait for mousekey							*
*************************************************
Mouse_Key:
	Btst 	#$6,$bfe001
	Bne.s   Mouse_Key
	Rts
	 
*************************************************
*	Clear double-buffered screen				*
*************************************************
Clear_Buffers:
	Move.l	Buffer1,a0
	Move.l	#12800,d0
	Bsr	Clear
	
	Move.l	Buffer2,a0
	Move.l	#12800,d0
	Bsr	Clear
	Rts

Clear_Text_Buffers:
	Move.l	Buffer1,a0
	Adda.l	#40960,a0
	Move.l	#2560,d0
	Bsr	Clear
	
	Move.l	Buffer2,a0
	Adda.l	#40960,a0
	Move.l	#2560,d0
	Bsr	Clear
	Rts

*************************************************
*	Load level 'zone' picture					*
*************************************************
Show_Zone:
	OPENF	#Copper2_Name,#Old_Mode
	READF	Handle,Copper1,#3380
	CLOSEF	Handle

	OPENF	#Copper2_Name,#Old_Mode
	READF	Handle,Copper2,#3380
	CLOSEF  Handle

	Move.l	Buffer1,Currbuffer
	Move.l	Buffer2,Showbuffer

	INSCOP	Buffer1,Copper1,#0
	INSCOP	Buffer2,Copper2,#0
	COPON   Copper1
	
	Bsr	Wait_VBL

	Move.w	#$2c81,$dff08e
	Move.w	#$2cc1,$dff090

	Bsr	Clear_Buffers
	Lea	Cmap5,a0
	Move.w	#31,d0
	Bsr	Get_Cmap
	Bsr	Set_Cmap

	LOADPIC	#Zone_Pic_Name,#51200
	Rts

*************************************************
*	Fade										*
*************************************************
Fade:
	Moveq.w	#0,d5
	Lea	Cmap,a0
	Move.w	#31,d4
	
Fade_Cycle:
	Clr.w	Fade_Not
	Move.w	(a0),d0	
	Clr.w	(a0)
	Move.w	d0,d1
	Move.w	d0,d2
	Move.w	d0,d3	
	
Get_RCol:
	Andi.w	#$F00,d1
	Subi.w	#$100,d1
	Bpl	Get_GCol
	Moveq.w	#0,d1
	Move.w	#1,Fade_Not

Get_GCol:
	Andi.w	#$F0,d2
	Subi.w	#$10,d2
	Bpl	Get_BCol
	Moveq.w	#0,d2
	Addi.w	#1,Fade_Not

Get_BCol:
	Andi.w	#$F,d3
	Subi.w	#$1,d3
	Bpl	Get_All_Col
	Moveq.w	#0,d3
	Addi.w	#1,Fade_Not

Get_All_Col:		
	Or.w	d1,(a0)
	Or.w	d2,(a0)
	Or.w	d3,(a0)+
	
	Cmpi.w	#3,Fade_Not
	Bne	Not_Faded
	Addi.w	#1,d5

Not_Faded:	
	Move.l	#$500,d6
Wait_Loop:
	Dbra	d6,Wait_Loop

	Dbra	d4,Fade_Cycle
	
	Bsr	Wait_VBL
	Bsr	Set_Cmap
	Cmpi.w	#32,d5
	Bne	Fade
	Rts

*************************************************
*	Fade copper list							*
*************************************************
Copper_Fade:
	Move.w	#16,d7
	
Fade_CCycle:
	Move.l	Fading_Copper,a0
	Move.w	#$300,d6

Find_Colour:
	Move.w	(a0),d0
	Btst	#0,d0
	Bne	Next_Instruction

	Cmpi.w	#$180,d0
	Blo	Next_Instruction
	
	Cmpi.w	#$1BE,d0
	Bgt	Next_Instruction
	
	Addq.l	#2,a0
	Move.w	(a0),d0
	Clr.w   (a0)

	Move.w	d0,d1
	Move.w	d0,d2
	Move.w	d0,d3	
	
Get_CRCol:
	Andi.w	#$F00,d1
	Subi.w	#$100,d1
	Bpl	Get_CGCol
	Moveq.w	#0,d1

Get_CGCol:
	Andi.w	#$F0,d2
	Subi.w	#$10,d2
	Bpl	Get_CBCol
	Moveq.w	#0,d2

Get_CBCol:
	Andi.w	#$F,d3
	Subi.w	#$1,d3
	Bpl	Get_All_CCol
	Moveq.w	#0,d3

Get_All_CCol:		
	Or.w	d1,(a0)
	Or.w	d2,(a0)
	Or.w	d3,(a0)+
	
	Dbra	d6,Find_Colour

	Move.w	#$A00,d5
WCloop:
	Dbra	d5,WCloop

	Dbra	d7,Fade_CCycle
	Rts
	
Next_Instruction:	
	Addq.l	#4,a0
	Dbra	d6,Find_Colour

	Move.w	#$A00,d5
WCloop2:
	Dbra	d5,WCloop2

	Dbra	d7,Fade_CCycle
	Rts
		
*************************************************
*	Get colour palette							*
*************************************************
Get_Cmap:
	Lea	Cmap,a1
Copy_Cmap:
	Move.w	(a0)+,(a1)+
	Dbra	d0,Copy_Cmap
	Rts

*************************************************
*	Set colour palette							*
*************************************************
Set_Cmap:
	Move.w	#31,d0
	Lea	$dff180,a1
	Lea	Cmap,a0
	
Move_Cmap:		
	Move.w	(a0)+,(a1)+
	Dbra	d0,Move_Cmap
	Rts
	
*************************************************
*	Parallax scrolling routine					*
*************************************************
Parallax_Scroll:
	Include	"PScroll.Mod"
	Rts
	
*************************************************
*	Copy front to back buffer					*
*************************************************	
Copy_Buffers:	
	Move.l	Showbuffer,Src
	Move.l	Currbuffer,Dest
	
	BLIT	Src,Dest,#$4014,#0,#0,#0,#$FFFF,#$FFFF

	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLIT	Src,Dest,#$4014

	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLIT	Src,Dest,#$4014

	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLIT	Src,Dest,#$4014

	Addi.l	#10240,Src
	Addi.l	#10240,Dest
	FBLIT	Src,Dest,#$4014
	Rts

*************************************************
*	Copy single bitplane text buffer			*
*************************************************	
Copy_Text_Buffer:	
	Move.l	Showbuffer,Src
	Move.l	Currbuffer,Dest
	
	Addi.l	#40960,Src
	Addi.l	#40960,Dest
	BLIT	Src,Dest,#$4014,#0,#0,#0,#$FFFF,#$FFFF
	Rts
	
*************************************************
*	Hiscore table								*
*************************************************
Hi_Score_Table:
	OPENF	#Copper4_Name,#Old_Mode
	READF	Handle,Copper1,#3380
	CLOSEF	Handle

	OPENF	#Copper4_Name,#Old_Mode
	READF	Handle,Copper2,#3380
	CLOSEF  Handle

	Move.l	Buffer1,Currbuffer
	Move.l	Buffer2,Showbuffer

	INSCOP	Buffer1,Copper1,#0
	INSCOP	Buffer2,Copper2,#0
	COPON   Copper1
	
	Bsr	Wait_VBL

	TURNONDMA
	LOADPIC	#Hi_Score_Name,#51200

	OPENF	#Hi_Score_Music_Name,#Old_Mode
	READF	Handle,Music_Start,#40960
	CLOSEF	Handle

	;Jsr	mt_init
	Jsr	Set_Int3

Hi_Score_Loop:
	Btst	#7,Mousekey
	Bne	Hi_Score_Loop

	Jsr	Restart_Loading
	Rts
	
*************************************************
*	Load option screen							*
*************************************************
Title_Screen:
	Move.l	Buffer1,Currbuffer
	Move.l	Buffer2,Showbuffer

	LOADPIC	#Overview_Name,#40960

	OPENF	#Copper3_Name,#Old_Mode
	READF	Handle,Copper1,#3380
	CLOSEF	Handle

	OPENF	#Copper3_Name,#Old_Mode
	READF	Handle,Copper2,#3380
	CLOSEF  Handle

	INSCOP	Buffer1,Copper1,#0
	INSCOP	Buffer2,Copper2,#0
	COPON   Copper1
	
	Bsr	Wait_VBL
	TURNONDMA

	***************************************	
	*****	Title_Screen Part 1		*******
	***************************************	
	Bsr	Clear_Text_Buffers
	PRINTAT	Showbuffer,#0,#5,#Credits,#Credits_End-Credits,#40960
	Bsr	Copy_Buffers

	Moveq.l	#0,d7
	
Credit_Loop:
	Bsr	Parallax_Scroll
	Bsr	Sin_Title
	Bsr	Flip_Screen
	Bsr	Wait_VBL
	
	Btst	#7,Mousekey
	Beq	Title_Part_2
	Bra	Credit_Loop
	
	***************************************	
	*****	Title_Screen Part 2		*******
	***************************************	
Title_Part_2:
	HOLD_FIRE

	Move.l	Buffer1,d1
	Addi.l	#40960,d1
	Move.l	d1,a0
	Move.l	#2560,d0
	Bsr	Clear

	Move.l	Buffer2,d1
	Addi.l	#40960,d1
	Move.l	d1,a0
	Move.l	#2560,d0
	Bsr	Clear

	Bsr	Print_Choice

Ov_Loop:
	Move.w	Joydat,d6
	Btst	#9,d6			; Left?
	Beq	Not_Left_Push

	Lea	Opt1,a0
	Lea	Opt2,a1
	Move.b	#105,(a0)
	Move.b	#106,(a1)
	Bsr	Print_Choice

Not_Left_Push:	
	Btst	#1,d6
	Beq	Not_Right_Push

	Lea	Opt1,a0
	Lea	Opt2,a1
	Move.b	#106,(a0)
	Move.b	#105,(a1)

	Bsr	Print_Choice

Not_Right_Push:	
	Bsr	Parallax_Scroll
	Bsr	Sin_Title
	Bsr	Screen_Swap
	Bsr	Wait_VBL
	
	Btst	#7,Mousekey
	Bne	Ov_Loop
	
	Lea	Opt1,a0
	Cmpi.b	#105,(a0)
	Beq	Fade_And_Start

	HOLD_FIRE

	***************************************	
	*****	Title_Screen Part 3		*******
	***************************************	

	Move.l	Buffer1,d1
	Addi.l	#40960,d1
	Move.l	d1,a0
	Move.l	#2560,d0
	Bsr	Clear

	Move.l	Buffer2,d1
	Addi.l	#40960,d1
	Move.l	d1,a0
	Move.l	#2560,d0
	Bsr	Clear

	Bsr	Print_Opts
	
Option_Screen:
	Bsr	Parallax_Scroll
	Bsr	Sin_Title
	Bsr	Screen_Swap
	Bsr	Wait_VBL
	
	Btst	#7,Mousekey
	Bne	Option_Screen
	
Fade_And_Start:	
	Move.l	Copper1,Fading_Copper
	Bsr	Copper_Fade

	Move.l	Copper2,Fading_Copper
	Bsr	Copper_Fade
	
	Bsr	Clear_Buffers
	Rts

*************************************************
*	Start/Options text routine					*
*************************************************
Print_Choice:
	PRINTAT	Showbuffer,#6,#10,#Opt1,#Opt1_End-Opt1,#40960
	PRINTAT	Showbuffer,#6,#11,#Opt2,#Opt2_End-Opt2,#40960
	Bsr	Copy_Text_Buffer
	Rts

Print_Opts:
	PRINTAT	Showbuffer,#0,#5,#Opts_Menu,#Opts_Menu_End-Opts_Menu,#40960
	Bsr	Copy_Text_Buffer
	Rts

*************************************************
*	Animate BLAZE title - make it wavy			*
*************************************************
Sin_Title:
	Addi.w	#2,d7
	Cmpi.w	#94,d7
	Bls	No_Sin_Reset
	Clr	d7

No_Sin_Reset:	
	Lea	Bpl1_Sin,a0
	Lea	(a0,d7),a0

	Move.l	Copper1,a1
	Lea	$11E(a1),a1

	Move.l	Copper2,a2
	Lea	$11E(a2),a2
	
	Move.w	#32,d0
	
Sin_Loop:	
	Move.w	(a0),(a1)
	Move.w	(a0)+,(a2)

	Addq.l	#8,a1
	Addq.l	#8,a2

	Dbra	d0,Sin_Loop
	Rts	

*************************************************
*	Load Warp logo screen						*	
*************************************************
Load_Logo:
	OPENF	#Copper2_Name,#Old_Mode
	READF	Handle,Copper1,#3380
	CLOSEF	Handle

	OPENF	#Copper2_Name,#Old_Mode
	READF	Handle,Copper2,#3380
	CLOSEF  Handle

	Move.l	Buffer1,Currbuffer
	Move.l	Buffer2,Showbuffer

	INSCOP	Buffer1,Copper1,#0
	INSCOP	Buffer2,Copper2,#0
	COPON   Copper1
	
	Bsr	Wait_VBL

	Move.w	#$2c81,$dff08e
	Move.w	#$2cc1,$dff090

	Lea	Cmap2,a0
	Move.w	#31,d0
	Bsr	Get_Cmap
	Bsr	Set_Cmap

	LOADPIC	#Logo_Pic_Name,#51200

	Rts
	
*************************************************
*	Load font, sprites and masks				*
*************************************************
Load_Sprites:	
	OPENF	#Font_Name,#Old_Mode	* Load Font In Memory
	READF	Handle,Font,#1920
	CLOSEF	Handle
	
	OPENF	#Sprites_Name,#Old_Mode	* Load Sprites In Memory
	READF	Handle,Sprites,#69120
	CLOSEF	Handle

	OPENF	#Masks_Name,#Old_Mode
	READF	Handle,Masks,#13824
	CLOSEF	Handle
	Rts
	
*************************************************
*	Load enemy and map tiles					*
*************************************************	
Load_Blocks:		
	Move.b	Level,Current_Level

	OPENF	#Blocks_Name,#Old_Mode	* Load Blocks In Memory
	READF	Handle,Blocks,#166400
	CLOSEF	Handle

	OPENF	#Block_Masks_Name,#Old_Mode	* Load Blocks In Memory
	READF	Handle,MkBlocks,#33280
	CLOSEF	Handle

	OPENF	#Enemy_Sprites_Name,#Old_Mode	* Load Sprites In Memory
	READF	Handle,Enemies,#51200
	CLOSEF	Handle

	OPENF	#Enemy_Masks_Name,#Old_Mode
	READF	Handle,MKEnemies,#10240
	CLOSEF	Handle
	Rts
	
*************************************************
* 	Load level maps								*
*************************************************	
Load_Map:
	Move.l	Map,d6
	Addi.l	#60008,d6
	Move.l	d6,Spare_Buffer

	OPENF	#Map_Name,#Old_Mode
	READF	Handle,d6,#60008
	CLOSEF	Handle

	Addi.l	#60008,d6
	
	OPENF	#EnemyMap_Name,#Old_Mode
	READF	Handle,d6,#900
	CLOSEF	Handle
	
	Addi.l	#900,d6

	OPENF	#Copper1_Name,#Old_Mode
	READF	Handle,d6,#3388
	CLOSEF	Handle

	Addi.l	#3388,d6

	OPENF	#Copper1_Name,#Old_Mode
	READF	Handle,d6,#3388
	CLOSEF  Handle

	Move.l	Spare_Buffer,a0
	Move.w	4(a0),Xmax
	Move.w	6(a0),Ymax

	Move.w	Xmax,d0
	Move.w	Ymax,d1
	Mulu	d1,d0
	Move.l	d0,SMap
	Rts

*************************************************
*	Recopy map data from source (avoid reload)	*
*************************************************	
Recopy_Map_Data:
	Move.l	Spare_Buffer,d4
	COPY	d4,Map,#60008

	Addi.l	#60008,d4
	COPY	d4,#Enmx,#900

	Addi.l	#900,d4
	COPY	d4,Copper1,#3388

	Addi.l	#3388,d4
	COPY	d4,Copper2,#3388
	Rts
	
*************************************************
*	Load level music							*
*************************************************
Load_Music:
	OPENF	#Music_Name,#Old_Mode
	READF	Handle,Music_Start,#40960
	CLOSEF	Handle
	Rts

*************************************************
*	Wait for VBL								*
*************************************************
Wait_Blit:
	Btst    #6,$dff003
	Bne.s   Wait_Blit     
	Rts

*************************************************
*	Increase filename index byte				*
*************************************************	
Increase_File_Names:
	Lea	Map_Name,a0
	Addi.b	#1,12(a0)

	Lea	EnemyMap_Name,a0
	Addi.b	#1,12(a0)
	Rts

*************************************************
*	Pause game 									*
*************************************************
Pause_Game:
	Clr.l $6a4
	Clr.l $6b0
	Clr.l d0

	PRINT	#Pause,#Pause_End-Pause,Panel
Main:
	Btst 	#$07,$bfe001
	Bne 	Main

	HOLD_FIRE

	PRINT	#Panel_Data,#Panel_Data_End-Panel_Data,Panel
	PRINT	#Panel_Vals,#Panel_Vals_End-Panel_Vals,Panel
	Jmp	No_Pause

*************************************************
*	Disk Error									*
*************************************************
Disk_Error:
	Bsr	Clear_Buffers
	
	PRINT	#Dk_Err,#Dk_Err_End-Dk_Err,Buffer1

	Move.l	Dosbase,a6
	Jsr	IoErr(a6)
	Move.l	d0,d5

	Move.l	#Insert_Disk,Text_Start
	PRINTAT	Buffer1,#0,#1,Text_Start,#20,#0

	SETERRCOP
	COPON   #Error_Cop
	SPRITESOFF
	TURNONDMA
	
Err_Main:
	Btst 	#$07,$bfe001
	Bne 	Err_Main

	TURNOFFDMA
	Rts

*************************************************
*	Fatal Trap									*
*************************************************
CPU_Trap:
	Bsr	Clear_Buffers
	PRINT	#CPU_Err,#CPU_Err_End-CPU_Err,Buffer1
	SETERRCOP
	COPON   #Error_Cop
	SPRITESOFF
	TURNONDMA
	
CPU_Err_Main:
	Btst 	#$07,$bfe001
	Bne 	CPU_Err_Main
	TURNOFFDMA
	Rte

*************************************************
*	Update HUD panel							*
*************************************************
Update_Panel:
	TIME_UPDATE	
	PRINT	#Panel_Vals,#Panel_Vals_End-Panel_Vals,Panel
	Rts	

*************************************************
*	Scroll copper list to match water level		*
*************************************************
Scroll_Copper:
	Move.l	Water_Lev_C,d0
	Cmp.l	Water_Lev_A,d0
	Beq	Convert_Water_Level
	Bhi	Lower_Water_Level
	Blo	Higher_Water_Level
		
Higher_Water_Level:		
	Move.w	#1,Water_Direction
	Subi.l	#1,Water_Lev_A
	Bra	Convert_Water_Level

Lower_Water_Level:
	Move.w	#2,Water_Direction
	Addi.l	#1,Water_Lev_A

Convert_Water_Level:
	Move.l	Water_Lev_A,d1
	Move.l	#$FD3DFFFE,Water_Lev_B
	
	Move.l	Ymap,d0
	Mulu	#32,d0

	Moveq.l	#0,d2
	Moveq.l	#0,d3

	Move.w	Yoff,d2
	Move.w	#32,d3
	Sub.w	d2,d3	
	Add.l	d3,d0
	
	Sub.l	d0,d1
	Bpl	No_Overflow
	
	Move.l	#$104DFFFE,Water_Lev_B
	Bra	Overflow
	
No_Overflow:
	Cmpi.l	#190,d1
	Bhi	Overflow
			
	Andi.l	#$FF,d1
	Addi.b	#60,d1
	
	Swap	d1
	Lsl.l	#8,d1
	Bset	#16,d1

	Move.w	#$FFFE,d1
	Ori.l	#$3D0000,d1
	Move.l	d1,Water_Lev_B

Overflow:
	Move.l	Water_Lev_B,d1
	Move.l	Current_Copper,a0

	Lea	$7E8(a0),a0
	Move.l	d1,(a0)

	Andi.l	#$FF00FFFF,d1
	Bset	#16,d1
	Addi.l	#$01000000,d1
	
	Lea	$8(a0),a0
	Move.l	d1,(a0)
	Rts

*************************************************
*	Scaling routine								*
*************************************************
Scale:
	Rts

*************************************************
*	Set Interrupt 3								*
*************************************************
Set_Int3:
	Move.w 	#$4000,Intena
	Move.l	$6c,Old_Int
	Move.l 	#Int3,$6c
    Move.w 	#$C000,Intena
	Rts

Int3:
	Movem.l d0-d7/a0-a7,-(Sp)
    Move.w 	Intreqr,d0   
    Btst 	#5,d0 
    Bne 	Play
    Bra		No_Play
Play:
;	Jsr	mt_music
	Addi.w	#1,Game_Timer_A

No_Play:
	Move.w	#$70,Intreq
        Movem.l (Sp)+,d0-d7/a0-a7
	Rte

*************************************************
*	New game									*
*************************************************
Init_New_Addr:
	Lea	Map_Name,a0
	Move.b	#49,12(a0)

	Lea	EnemyMap_Name,a0
	Move.b	#49,12(a0)

	Move.b	#1,Level
	Move.b	Start_Lives,Lives
	Move.b	Start_Energy,Energy
	Rts

*************************************************
*	Initialise all flags and variables			*
*************************************************
Init_Addr:
	Move.w	#127,YChar
	Move.w	#1,Frame
	Move.w	#1,Delay
	Move.w	#1,XDelay
	Move.w	#1,SDelay
	Move.w	#1,LDelay
	Move.w	#1,BDelay
	Move.w	#8,RDelay
	Move.w	#1,WDelay
	Move.w	#50,CtrDelay	
	Move.w	#25,TDelay	
	Move.w	#999,Time
	Move.l	#5,Xmap
	Move.l	#36,Ymap
	Move.l	#5,XStart
	Move.l	#36,YStart

	Clr.l	Score
	Clr.w	Xoff	 	
	Clr.w	Yoff	 	
	Clr.w	Offx	 	
	Clr.w	Obx

Life_Lost_Reset:
	Clr.l	Xdum
	Clr.l	Ydum
	Clr.l	MShift		
	Clr.l	Lava_Anim_X
	Clr.l	Lava_Anim_Y

	Clr.b	Slide
	Clr.b	Spin		
	Clr.b	Spring		
	Clr.b	Braking	
	Clr.b	Hang		
	Clr.b	Whoopie	
	Clr.b	Ext_Whoopie	
	Clr.b	Super_Run	
	Clr.b	Crouch		
	Clr.b	Invulnerable
	Clr.b	Dino_Platform
	Clr.b	Cover_Cat

	Clr.w	Velx
	Clr.w	Vely
	Clr.w	AuxVelx	
	Clr.w	AuxVely	

	Clr.w	VChange	
	Clr.w	NVChange	
	Clr.w	Power		
	Clr.w	Inc_Vel	

	Clr.w	Direction	
	Clr.w	Dir		
	Clr.w	Fdir		

	Clr.w	Flick_Ctr	
	Clr.w	Anim_Ctr	
	Clr.w	FG_Anim_Ctr	
	Clr.w	NMCtr		
	Clr.w	NMCtr2		
	Clr.w	NMCtr4		
	Clr.w	Estart
	Clr.w	Jump		
	Clr.w	IJump		
	Clr.w	Xjump		
	Clr.w	Yjump		
	Clr.w	NJump		

	Clr.w	XMotion	
	Clr.w	YFlip		
	Clr.w	XORFrame	
	Clr.w	Surfframe	
	Clr.w	Whoops_Frame	
	Clr.w	Emerald_Ctr	

	Clr.w	PShift			
	Clr.w	Detect		
	Clr.w	Standon	
	Clr.w	Stand		
	Clr.w	Standpploop
	Clr.w	Standpfrm
	Clr.w	Standpfrmon
	Clr.w	Surface	
	Clr.w	Sidewalk	
	Clr.w	Brgdn		
	Clr.w	Fpform		
	Clr.w	Dpfstand	
	Clr.w	Left_Blocked	
	Clr.w	Right_Blocked	
	Clr.w	FrDir		
	Clr.w	Rten		
	Clr.w	Level_Complete
	
	Clr.w	Emeralds		
	Clr.w	Hit		
	
	Move.b	Start_Energy,Energy

	Lea	Velocities,a0		; Clear velocities
	Move.l	#50,d0

Velclr_Loop:
	Clr.w	(a0)+
	Dbra	d0,Velclr_Loop

	Lea	Angles,a0			; Clear angles
	Move.l	#50,d0

Angclr_Loop:
	Clr.w	(a0)+
	Dbra	d0,Angclr_Loop

	Rts

*************************************************
*	Include music playback routines				*
*************************************************

;	Include	"Music_Routine.S"

*** Data **************

Bpl1_Sin:	
	Dc.w	$88,$77,$66,$55,$44,$44,$33,$33,$22,$22
	Dc.w	$11,$11,$00,$00,$00,$11,$11,$22,$22,$33
	Dc.w	$33,$44,$44,$55,$66,$77,$88,$99,$aa,$bb
	Dc.w	$cc,$cc,$dd,$dd,$ee,$ee,$ff,$ff,$ff,$ee
	Dc.w	$ee,$dd,$dd,$cc,$cc,$bb,$aa,$99

	Dc.w	$88,$77,$66,$55,$44,$44,$33,$33,$22,$22
	Dc.w	$11,$11,$00,$00,$00,$11,$11,$22,$22,$33
	Dc.w	$33,$44,$44,$55,$66,$77,$88,$99,$aa,$bb
	Dc.w	$cc,$cc,$dd,$dd,$ee,$ee,$ff,$ff,$ff,$ee
	Dc.w	$ee,$dd,$dd,$cc,$cc,$bb,$aa,$99

Bpl2_Sin:	
	Dc.w	$44,$44,$33,$33,$22,$22,$22,$11,$11,$11
	Dc.w	$11,$00,$00,$00,$00,$00,$11,$11,$11,$11
	Dc.w	$22,$22,$22,$33,$33,$44,$44,$55,$55,$66
	Dc.w	$66,$66,$77,$77,$77,$77,$88,$88,$88,$88
	Dc.w	$88,$77,$77,$77,$77,$66,$66,$66,$55,$55

	Dc.w	$44,$44,$33,$33,$22,$22,$22,$11,$11,$11
	Dc.w	$11,$00,$00,$00,$00,$00,$11,$11,$11,$11
	Dc.w	$22,$22,$22,$33,$33,$44,$44,$55,$55,$66
	Dc.w	$66,$66,$77,$77,$77,$77,$88,$88,$88,$88
	Dc.w	$88,$77,$77,$77,$77,$66,$66,$66,$55,$55
		
Xmax:		Dc.w	0
Ymax:		Dc.w	0
Xoff:	 	Dc.w 	0
Yoff:	 	Dc.w 	0					
Offx:	 	Dc.w 	0				
MShift:		Dc.l	0

Cf_Hit_Velx_Lt:	Dc.w	0
Cf_Hit_Velx_Rt:	Dc.w	0
Cf_Hit_Vely:	Dc.w	0

Hit_Velx_Lt:	Dc.w	0
Hit_Velx_Rt:	Dc.w	0
Hit_Vely:	Dc.w	0

Velx:		Dc.w 	0		
Vely:		Dc.w 	0	
AuxVelx:	Dc.w	0
AuxVely:	Dc.w	0
VChange:	Dc.w	0
NVChange:	Dc.w	0
Power:		Dc.w	0
Inc_Vel:	Dc.w	0

Obx:		Dc.w	0
XChar:		Dc.w	144
YChar:		Dc.w	127
XDust:		Dc.w	148
YDust:		Dc.w	143
XSprite_16:	Dc.w	0
YSprite_16:	Dc.w	0
Can_Dust:	Dc.w	0
Frame:		Dc.w	1


Direction:	Dc.w	0
Dir		Dc.w	0

Fdir:		Dc.w	0
Flick_Ctr:	Dc.w	0
Anim_Ctr:	Dc.w	0
Enemy_Anim_Ctr: Dc.w	0
FG_Anim_Ctr:	Dc.w	0
NMCtr:		Dc.w	0
NMCtr2:		Dc.w	0
NMCtr4:		Dc.w	0
XMotion:	Dc.w	0
YFlip:		Dc.w	0

XORFrame:	Dc.w	0
Surfframe:	Dc.w	0
Whoopie:	Dc.w	0
Whoops_Frame:	Dc.w	0
Ext_Whoopie:	Dc.w	0
Super_Run:	Dc.w	0
Crouch:		Dc.w	0

Jump:		Dc.w	0
IJump:		Dc.w	0
Xjump:		Dc.w	0
Yjump:		Dc.w	0
NJump:		Dc.w	0
Max_Jump:	Dc.w	0
Momentum_X:	Dc.w	0
Momentum_Y:	Dc.w	0

Delay:		Dc.w	1
XDelay:		Dc.w	1
SDelay:		Dc.w	1
LDelay:		Dc.w	1
BDelay:		Dc.w	1
RDelay:		Dc.w	8
WDelay:		Dc.w	1
CtrDelay:	Dc.w	50
TDelay:		Dc.w	26
Dust_Delay:	Dc.w	0
Emerald_Ctr:	Dc.w	0
PShift:		Dc.w	0
Level_Complete:	Dc.w	0	

Detect:		Dc.w	0
Standon:	Dc.w	0
Stand:		Dc.w	0
Standpfrm:	Dc.w	0
Standpfrmon:	Dc.w	0
Standpploop:	Dc.w	0
Surface:	Dc.w	0
Sidewalk:	Dc.w	0

Brgdn:		Dc.w	0
Fpform:		Dc.w	0
Dpfstand:	Dc.w	0
Platform_Number: Dc.w	0

Left_Blocked:	Dc.w	0
Right_Blocked:	Dc.w	0
FrDir:		Dc.w	0
Rten:		Dc.w	0
Emeralds:	Dc.w	0	
Hit:		Dc.w	0
Time:		Dc.w	999

Cust_Ctr_A:	Dc.w	0
Cust_Ctr_B:	Dc.w	0
Cust_Ctr_C:	Dc.w	0
Cust_Ctr_D:	Dc.w	0
Cust_Ctr_E:	Dc.w	0
Cust_Ctr_F:	Dc.w	0
Cust_Ctr_G:	Dc.w	0
Cust_Ctr_H:	Dc.w	0
Cust_Ctr_I:	Dc.w	0
Cust_Ctr_J:	Dc.w	0

Lava_Anim_X:	Dc.l	0
Lava_Anim_Y:	Dc.l	0

Coll_X1:	Dc.l	0
Coll_X2:	Dc.l	0
Coll_Y1:	Dc.l	0
Coll_Y2:	Dc.l	0

Offex:		Dc.l	0
Offey:		Dc.l	0
Savecx:		Dc.l	0
Savecy:		Dc.l	0
Cenmx:		Dc.l	0
Cenmy:		Dc.l	0
Cenmvy:		Dc.w	0
Cenmvx:		Dc.w	0
Cenmt:		Dc.w	0
Cenmpfrm:	Dc.w	0
Cenmfoh:	Dc.w	0

Velocities:	Ds.w	50
Angles:		Ds.w	50

Dummy_Velocity:	Dc.w	0
Dummy_Angle:	Dc.w	0
Angle:			Dc.w	0

Enemy_Check:	Dc.w	0
Enemy_Frame:	Dc.w	0

CSize:		Dc.w	12
NFrames:	Dc.w	0
XBytes:		Dc.w	0
YBytes:		Dc.w	0
Enmsize:	Dc.w	0
Emod:		Dc.w	0

* Enemy structures

Enmx:		Ds.l	50	; x position 
Enmy:		Ds.l	50	; y position
Enmt:		Ds.w    50	; type
Enmvx:		Ds.w	50	; x velocity
Enmvy:		Ds.w	50	; y velocity
Enmpfrm:	Ds.w 	50	; is plaform?
Enmfoh:		Ds.w	50	; is friend or foe?
Enmdata:
Estart:		Dc.w	0

*>	Bullets
Fire_Toggle:		Ds.b	50
Enemy_Fire_X:		Ds.l	50
Enemy_Fire_Y:		Ds.l	50
Enemy_Fire_VX:		Ds.w	50
Enemy_Fire_VY:		Ds.w	50
Enemy_Fire_Dirx: 	Dc.w	0
Enemy_Fire_Diry: 	Dc.w	0
*>	Bullets

Snowx:	Dc.w	035,065,090,120,155,180,200,230,250,260,280
		Dc.w	045,075,110,135,165,190,215,240,265,270,290
		
Snowy:	Dc.w	032,060,098,120,100,050,140,060,170,040,040
		Dc.w	044,070,130,150,110,160,100,080,120,070,090

Snows:	Dc.w	001,002,001,003,002,001,002,001,003,002,002
		Dc.w    002,003,002,001,003,001,002,002,003,002,001

Snow:	Dc.w	0
	
Sine_Read:		Dc.w	0
Cosine_Read:	Dc.w	0
Sin_Ptr:		Dc.w	0
SMode:			Dc.w	0
STab:			Dc.w	0
Water_Lev_A:		Dc.l	$5CA
Water_Lev_B:		Dc.l	0
Water_Lev_C:		Dc.l	$5CA
Water_Direction: 	Dc.w	0

Text_Start:		Dc.l	0
Music_Start:	Dc.l	$60C8
Map: 			Dc.l	0
Spare_Buffer:	Dc.l	0

Copper1:		Dc.l    0
Copper2:		Dc.l	0
Fading_Copper:	Dc.l	0
Current_Copper:	Dc.l	0

Font:		Dc.l	0
MKEnemies:	Dc.l	0
Enemies:	Dc.l	0
Sprites: 	Dc.l 	0
Masks:		Dc.l	0
Blocks:  	Dc.l 	0
MkBlocks:	Dc.l	0
Panel:		Dc.l	0

Buffer1: 	Dc.l 	0				
Buffer2: 	Dc.l 	0				
Currbuffer:	Dc.l 	0
Showbuffer:	Dc.l 	0	 

SrcMask:	Dc.l	0
Src:	 	Dc.l 	0	
Dest:	 	Dc.l 	0	

Doshandle	Dc.l	0
Handle:		Dc.l	0
Dosbase:	Dc.l 	0
Gfxbase:	Dc.l 	0
		
XChar_Map:	Dc.l	0
YChar_Map:	Dc.l	0		
Xdum:	 	Dc.l 	0				
Ydum:	 	Dc.l 	0				
Xmap:	 	Dc.l 	10				
Ymap:	 	Dc.l 	0	
XStart:		Dc.l	0
YStart:		Dc.l	0
XStartb:	Dc.w	0
YStartb:	Dc.w	0
SMap:		Dc.l	0	

Old_Int:		Dc.l	0
Game_Timer_A:	Dc.l	0
Game_Timer_B:	Dc.l	0
Score:			Dc.l	0

Prop:		Dc.w	0
LProp:		Dc.w	0
Bob_Frame:	Dc.w	0

Do_Mask_Routine: 	Dc.b 	0
Jdown1:				Dc.b	0
Jdown2:				Dc.b	0
Pend_Bob:			Dc.b	0
Destructable:		Dc.b	0
Cover_Cat:			Dc.b	0
Dino_Platform:		Dc.b	0
Extra_Blocks:		Dc.b	0
Enemy_Fire_Pause:	Dc.b	0

Start_Lives:	Dc.b	3
Start_Energy:	Dc.b	2
In_Game_Timer:	Dc.b	1
Lives:			Dc.b	3
Energy:			Dc.b	2
Level:			Dc.b	1
Current_Level:	Dc.b	0

Slide:			Dc.b	0
Spin:			Dc.b	0
Spring:			Dc.b	0
Braking:		Dc.b	0
Hang:			Dc.b	0
Invulnerable:	Dc.b	0

		Even
		
Max_Segments:	Dc.l	0
Scale_Buffer:	Dc.l	0
Dest_Buffer:	Dc.l	0
Max_Scale_X:	Dc.w	0
Max_Scale_Y:	Dc.w	0
Str_Scale_X:	Dc.w	0
Str_Scale_Y:	Dc.w	0
Draw:			Dc.w	0
Mag_Power:		Dc.w	0
Scale_Plane:	Dc.w	0

*********************************************************
*		Filename strings (null-terminated) 				*
*********************************************************

Gfxname: 			Dc.b 	"graphics.library",0
Dosname:			Dc.b	"dos.library",0	

Copper1_Name:		Dc.b	"BLAZE:Copper1.Cop",0
Copper2_Name:		Dc.b	"BLAZE:Copper2.Cop",0
Copper3_Name:		Dc.b	"BLAZE:Copper4.Cop",0
Copper4_Name:		Dc.b	"BLAZE:Copper7.Cop",0

Map_Name:			Dc.b 	"BLAZE:Level_1.Map",0
EnemyMap_Name:		Dc.b	"BLAZE:Level_1.Edata",0

Sprites_Name:		Dc.b	"BLAZE:Sprites.RAW",0
Masks_Name:			Dc.b	"BLAZE:Masks.RAW",0

Enemy_Sprites_Name:	Dc.b	"BLAZE:Enemies1.RAW",0
Enemy_Masks_Name:	Dc.b	"BLAZE:Emasks1.RAW",0

Blocks_Name:		Dc.b   	"BLAZE:Blocks1.RAW",0
Block_Masks_Name:	Dc.b	"BLAZE:BMasks1.RAW",0

Logo_Pic_Name:		Dc.b	"BLAZE:Logo.RAW",0
Title_Pic_Name:		Dc.b	"BLAZE:Title.RAW",0
Zone_Pic_Name:		Dc.b	"BLAZE:Zonepic_1.RAW",0
Overview_Name:		Dc.b	"BLAZE:Overview.RAW",0
Hi_Score_Name:		Dc.b	"BLAZE:Hi-Score.RAW",0
Font_Name:			Dc.b	"BLAZE:Font.RAW",0

Music_Name:		Dc.b	"BLAZE:Music.ST",0
Hi_Score_Music_Name:	Dc.b	"BLAZE:Music2.ST",0

*				 		12345678901234567890

Dk_Err:			Dc.b	"   DISK REQUESTER   "
Dk_Err_End:		Dc.b	0

CPU_Err:		Dc.b	"  FATAL CPU CRASH=  "
CPU_Err_End:	Dc.b	0

Err_A:			Dc.b	"   FILE NOT FOUND   ",0
Err_B:			Dc.b	" DISK NOT VALIDATED ",0
Err_C:			Dc.b	"DISK WRITE PROTECTED",0
Err_D:			Dc.b	" DEVICE NOT MOUNTED ",0
Err_E:			Dc.b	"      DISK FULL     ",0      
Err_F:			Dc.b	"   NOT A DOS DISK   ",0
Err_G:			Dc.b	"  NO DISK IN DRIVE  ",0               
Err_H:			Dc.b	" UNPRINTABLE ERROR= ",0

Insert_Disk:	Dc.b	"PLEASE INSERT DISK 1"
Insert_Disk_End: Dc.b	0
		
Loading:		Dc.b	"LOADING GAME..."
Loading_End:	Dc.b	0

Pause:			Dc.b	106,106,106,"GAME",106,"PAUSED==",106,106,106,106
Pause_End:		Dc.b	0

Quit_Text:		Dc.b	106,106,106,"GAME",106,"ABORTED=",106,106,106,106
Quit_Text_End:	Dc.b	0

Opt1:			Dc.b	105,"START"
Opt1_End:		Dc.b	0

Opt2:			Dc.b	106,"OPTIONS"	
Opt2_End:		Dc.b	0

*				   12345678901234567890

Bonus_Messages:		Dc.b	004,"   EACH 100 GEMS  ",255
			Dc.b	000,"   COLLECTED  AN  ",255
			Dc.b	000,"   EXTRA LIFE IS  ",255
			Dc.b	000,"      GAINED=     ",255
			
			Dc.b	005," SECRET ROOMS ARE ",255
			Dc.b	000,"SCATTERED ALL OVER",255
			Dc.b	000,"OVER THE LANDSCAPE",255
			Dc.b	000," AND CONTAIN LOTS ",255
			Dc.b	000,"   OF BONUSES==   ",255
			
			Dc.b	004," FINISH THE STAGE ",255
			Dc.b    000,"   QUICKLY AND A  ",255
			Dc.b	000,"  HUGE TIME BONUS ",255
			Dc.b	000," WILL BE AWARDED==",255
			
			Dc.b	003,"  THESE DEVICES   ",255
			Dc.b	000,"  REPLENISH THE   ",255
			Dc.b	000,"  ENERGY GAUGE=   ",255

			Dc.b	003,"  COLLECT ALL THE ",255
			Dc.b	000,"  GEMS IN A STAGE ",255
			Dc.b	000," TO EARN A PERFECT",255
			
			Dc.b	004," RESTART  MONITORS",255
			Dc.b	000," ARE  ACTIVATED BY",255
			Dc.b	000," CROUCHING INFRONT",255
			Dc.b	000,"      OF THEM=    ",255

			Dc.b	003,"   REMEMBER THAT  ",255
			Dc.b	000," MOMENTUM  AFFECTS",255
			Dc.b	000," JUMPS FROM LIFTS=",255

			Dc.b	002,"FIRE IN PITS KILLS",255
			Dc.b	000,"    ON CONTACT=   ",255
			
			Dc.b    004,"HIDING  BEHIND THE",255
			Dc.b	000," SCENERY PREVENTS ",255
			Dc.b	000,"  COLLISION WITH  ",255
			Dc.b	000,"   THE ENEMIES=   ",255
			
			Dc.b	003,"  BEWARE OF  THE  ",255
			Dc.b	000," CRUMBLING PIECES ",255
			Dc.b	000,"    OF SCENERY    ",255

			Dc.b	003," THE HEADS OF THE ",255
			Dc.b	000," GIANT SNAKES ACT ",255
			Dc.b	000," AS SPRINGBOARDS= ",255
			
			Dc.b	004," WHEN NO ENERGY IS",255
			Dc.b	000," LEFT WAITING FOR ",255
			Dc.b	000,"    100 SECONDS   ",255
			Dc.b	000," RESTORES ENERGY==",255
						
			
Credits:	Dc.b	000,"68000 PROGRAMMING ",255
			Dc.b	000,"KEITH BUGEJA      ",255
			Dc.b    000,"                  ",255
			Dc.b	000,"GRAPHICS          ",255
			Dc.b	000,"KEITH BUGEJA      ",255
			Dc.b    000,"                  ",255
			Dc.b    000,"PUSH START BUTTON=",255
			Dc.b    000,"                  ",255
			Dc.b	000,";2015 KEITH BUGEJA",255
Credits_End:		Dc.b	0

Hiscore_Table:		Dc.b	" TOP 1000000...KEITH",255
			Dc.b    " 2ND 0900000...COLIN",255
			Dc.b	" 3RD 0800000...JOHN ",255
			Dc.b	" 4TH 0700000...ROBBY",255
			Dc.b	" 5TH 0600000...STEVE",255
			Dc.b	" 6TH 0500000...CHRIS",255
			Dc.b	" 7TH 0400000...KEVIN",255
			Dc.b	" 8TH 0300000...JOE  ",255
			Dc.b	" 9TH 0200000...HENRY",255
Hiscore_Table_End:	Dc.b	0

Opts_Menu:	Dc.b	000,000,"  OPTIONS MENU   ",255
			Dc.b	000,105,"LIVES           3",255
			Dc.b	000,106,"HEALTH          3",255
			Dc.b	000,106,"CONTINUES       3",255
			Dc.b	000,106,"EXTRA LIVES    ON",255 
			Dc.b	000,106,"BONUS STAGE    ON",255
			Dc.b  	000,106,"TIME COUNTER   ON",255
			Dc.b	000,106,"CONTROL      JSTK",255
			Dc.b	000,106,"EXIT MENU        ",255
Opts_Menu_End:		Dc.b	0

Game_Type:	Dc.b    000,000,"CHOOSE GAME TYPE ",255
			Dc.b	000,000,"ONE PLAYER GAMES ",255
			Dc.b	000,105,"  BLAZE ALONE    ",255
			Dc.b	000,106,"  YUKI  ALONE    ",255
			Dc.b	000,000,"                 ",255
			Dc.b	000,000,"TWO PLAYER GAMES ",255
			Dc.b	000,106,"   TEAM MODE     ",255
			Dc.b	000,106,"   LINK MODE     ",255
			Dc.b	000,106,"  VERSUS MODE    ",255
Game_Type_End:		Dc.b	0

Bonus:		Dc.b	000,"    WELL DONE=    ",255
			Dc.b	000,"  ACT COMPLETE==  ",255
			Dc.b	000,"      BONUS=      ",255
			Dc.b	000," TIME         999 ",255
			Dc.b	000," JEWELS       999 ",255
			Dc.b	000," HEALTH       999 ",255
			Dc.b	000," PERFECT      999 ",255
			Dc.b	000," TOTAL    	  9999 ",255
			Dc.b	000," <BONUS CONTINUE< ",255
Bonus_End:		Dc.b	0			


Demo_Text:
			Dc.b	000,"	 WELL DONE=    ",255
			Dc.b	000,"                  ",255
			Dc.b	000,"YOU HAVE COMPLETED",255
			Dc.b	000,"THIS DEMO OF BLAZE",255
Demo_Text_End:		Dc.b	0
						
Panel_Data:			Dc.b	106,$5b,$5c,"999",$5d,$5e,$63,$5f,$60,"3",$61,$62,"000",106	
Panel_Data_End:		Dc.b	0	

Panel_Vals:			Dc.b	0,0,0,"999",0,0,$63,0,0,"3",0,0,"000",0	
Panel_Vals_End:		Dc.b	0	

* Values		001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,018,019,020,021,022,023,024,025,026,027,028,029,030,031,032,033,034,035,036,037,038,039,040,041,042,043,044,045,046,047,048

Anim:	Dc.b	153,153,153,153,153,153,153,153,153,153,154,154,154,154,154,155,155,155,155,155,156,156,156,156,156,156,156,000,000,000,000,000,000,000,000,000,000,155,155,155,155,155,154,154,154,154,154,154  * 0 None
		Dc.b	208,209,210,211,212,213,214,215,208,209,210,211,212,213,214,215,208,209,210,211,212,213,214,215,208,209,210,211,212,213,214,215,208,209,210,211,212,213,214,215,208,209,210,211,212,213,214,215  * 1 Water Fall
		Dc.b	184,184,184,184,184,184,185,185,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,185,185,184,184	 * 2 Spikes
		Dc.b	232,232,233,233,234,234,235,235,236,236,237,237,238,238,239,239,232,232,233,233,234,234,235,235,236,236,237,237,238,238,239,239,232,232,233,233,234,234,235,235,236,236,237,237,238,238,239,239	 * 3
		Dc.b	192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195	 * 5
		Dc.b	194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193,194,195,192,193	 * 6
    	Dc.b	115,115,116,116,119,119,172,172,115,115,116,116,119,119,172,172,115,115,116,116,119,119,172,172,115,115,116,116,119,119,172,172,115,115,116,116,119,119,172,172,115,115,116,116,119,119,172,172	 * 7
		Dc.b	183,183,187,187,131,131,132,132,183,183,187,187,131,131,132,132,183,183,187,187,131,131,132,132,183,183,187,187,131,131,132,132,183,183,187,187,131,131,132,132,183,183,187,187,131,131,132,132  * 8 Jewels
		Dc.b	176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179,176,177,178,179	 * Jets
		Dc.b	243,243,242,242,242,243,243,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000	 * Gem Implosion
		Dc.b	124,125,125,125,124,124,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000	 * Spring
		Dc.b	003,003,004,004,004,003,003,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177,177  * Gem Implosion B
		Dc.b	155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198,155,155,156,156,198,198	 * Replenisher 
		

Enemy_Anim:	
		Dc.b	023,024,025,024,023,024,025,024,023,024,025,024		* 000  Mutant Crab
		Dc.b	026,027,028,029,026,027,028,029,026,027,028,029		* 012 Water Fountain 
		Dc.b	034,035,036,037,034,035,036,037,034,035,036,037		* 024
		Dc.b	038,038,040,040,042,042,044,044,042,042,040,040		* 036 Vulture	
		Dc.b	074,074,075,075,076,076,077,077,078,078,079,079		* 048 KABOOM!
		Dc.b	076,076,077,077,078,078,079,079,075,075,074,074		* 060 KAPOW!
		Dc.b	120,121,122,123,120,121,122,123,120,121,122,123		* 072 Spflush!(Lava)
		Dc.b	011,011,011,011,011,011,011,011,011,011,011,011		* 084 Fish A
		Dc.b	012,012,013,013,014,014,015,015,015,015,015,015		* 096 Fish B
		Dc.b	015,015,015,015,015,015,015,015,015,015,015,015		* 108 Fish C
		Dc.b	002,002,002,012,012,012,003,003,003,013,013,013		* 120 Crumbling Platform
		Dc.b	124,124,133,133,134,134,124,124,133,133,134,134		* 132 Lavus


Delay_Vals:	
		Dc.b	4,3,3,2,2,2,1,1
		Dc.b	1,1,1,1,1,1,1,0
		Dc.b	0,0,0,0,0,0,0,0
		Dc.b	0,0,0,0,0,0,0,0
		Dc.b	0,0,0,0,0,0,0,0
		
XDelay_Vals:
		Dc.b	02,03,03,05,05,08,08,08
		Dc.b	09,09,10,11,12,13,14,14
		Dc.b	14,14,14,14,14,14,16,16
		Dc.b	16,16,16,16,16,16,16,16
	
Loop_Data:	Incbin "Loop.Data"

	Even	

*********************************************************
*	Inclusion Of Trig. Tables							*
*********************************************************

Sine_Data:		Incbin "Sine_Table.Data"
Cosine_Data:	Incbin "Cosine_Table.Data"

*************************************************
*	Colour Maps									*
*************************************************
Cmap:		Ds.w	32

Cmap1:		
		Dc.w 	$0000,$0FFF,$0DBE,$0B8C,$096B,$073A,$0518,$0407
		Dc.w	$000F,$016F,$01BF,$02FF,$0FF0,$0CA0,$0960,$0630
		Dc.w 	$0AAA,$0FFF,$0FEF,$0ECF,$0EBF,$0DAE,$0CAD,$0BAC
		Dc.w	$0AAF,$0ACF,$0AFF,$0CFF,$0FFA,$0EDA,$0DBA,$0CAA

Cmap2:		
		Dc.w $0000,$0FFF,$0FFB,$0FE8,$0FE4,$0FF0,$0FD0,$0FB0
 		Dc.w $0F90,$0F70,$0F50,$0F40,$0F20,$0F00,$0C00,$0900
 		Dc.w $0700,$0400,$0005,$0007,$0009,$000C,$000E,$004F
 		Dc.w $006F,$008F,$00AF,$00CF,$03DF,$06EF,$08FF,$0BFF


Cmap3:
		Dc.w 	$0000,$0FFF,$0000,$0900,$0F00,$0F70,$0FB0,$0FF0
		Dc.w	$0510,$0731,$0953,$0046,$0058,$006A,$007B,$0080
		Dc.w 	$009F,$08CF,$0330,$0444,$0666,$0888,$0306,$0528
		Dc.w	$084A,$0A7C,$0CBD,$0150,$0080,$00B0,$08F0,$0D80

Cmap4:
 		Dc.w 	$0124,$0FFF,$0CCE,$09AD,$068D,$046C,$0457,$0346
 		Dc.w 	$0235,$0110,$0230,$0341,$0453,$0563,$0674,$0210
 		Dc.w 	$0321,$0432,$0543,$0654,$0765,$0876,$0987,$0220
 		Dc.w 	$0331,$0441,$0652,$0764,$0875,$0BA9,$0EDB,$089D

Cmap5:
 		Dc.w 	$0000,$0FFF,$0DEE,$0BDE,$0ACD,$08BC,$07AC,$069B
 		Dc.w 	$048A,$037A,$0269,$0158,$0047,$0036,$0025,$0020
 		Dc.w 	$0030,$0150,$0260,$0470,$0690,$08A0,$09B2,$0FF0
 		Dc.w 	$0CC0,$0A00,$0C00,$0F00,$0AAA,$0CCC,$0FFF,$0FAA

Fade_Not:	Dc.w	0

	Even

*************************************************
*	Background Sprite Data (Chip RAM)			*
*	And Dummy Copper Lists (Chip RAM)			*
*************************************************

 Section Sprite_Data,Code_C
 
Cop_Pan:	
		Dc.w	$FF01,$FFFE	* WAIT
		Dc.w	$0102,$0008	* Bplcon1


Cop_Pan2:	
		Dc.w	$00E0,$0000	* Bplpth
 		Dc.w	$00E2,$0000	* Bplptl
 		Dc.w	$0092,$0040	* Ddfstrt
 		Dc.w	$0094,$00C0	* Ddfstp
 		Dc.w	$0108,$0007	* Bplmod1
 		Dc.w	$010A,$0007	* Bplmod2
 		Dc.w	$0100,$1000	* Bplcon0
		Dc.w	$0180,$0000	* Col0
		Dc.w	$0182,$0FFF	* Col1
		Dc.w	$FFFF,$FFFE	* End Cop


Cop_Dummy:	
		Dc.w	$0100,$0000	* Bplcon0
		Dc.w	$0180,$0000	* Col 0
		Dc.w	$0182,$0000	* Col 1
 		Dc.w	$FFFF,$FFFE	* End Cop


Error_Cop:	Dc.w	$0102,$0000	* Bplcon1

Error_Cop2:	
		Dc.w	$00E0,$0000	* Bplpth
 		Dc.w	$00E2,$0000	* Bplptl
		Dc.w	$008E,$5E81	* Diwstrt 
		Dc.w	$0090,$80C1	* Diwstop
 		Dc.w	$0092,$0038	* Ddfstrt
 		Dc.w	$0094,$00D0	* Ddfstop
 		Dc.w	$0108,$0000	* Bplmod1
 		Dc.w	$010A,$0000	* Bplmod2
 		Dc.w	$0100,$1000	* Bplcon0
		Dc.w	$0180,$0000	* Col0
		Dc.w	$0182,$0FFF	* Col1
		Dc.w	$FFFF,$FFFE	* End Cop
			
 Include "Sprites.mod"



