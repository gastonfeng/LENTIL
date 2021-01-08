;	150W square waveform inverter
;	filename:lentil.asm
;	author:Fengjiantao
;	Email:fjt@yeah.net
;	begin from:1999.10.10

	include p16c711.inc

;Constant definitions
; PWM-module-constant
PWMADJUSTVAL 	equ .25
VOLTAGER	equ .162	;Voltage request
LOWVOLTAGE	equ .184
OVER150		equ .164
OVER125		equ .137
KP		equ .40	;Proportional gain
KI		equ .1	;Integral gain
KD		equ .1	;Differential gain
PWMMAXVAL	equ .29
INTCONVAL 	equ 0b0h ; set GIE, T0IE
OPTIONVAL 	equ 4fh ; portB have pull-up, tmr0 int.


;Register Equates

HITIMES		equ 0ch
HI		equ 0dh
LOTIMES		equ 0eh
LO		equ 0fh
TIMES		equ 10h
STACKW 		equ 11h ; stack to push/pop the W-register
STACKS 		equ 12h ; stack to push/pop the STATUS-reg
LOWCOUNT	equ 13h	; Low Voltage counter
COUNTER1 	equ 14h ; counter2: input frequency
count150	equ 15h;
PWMMAX 		equ 16h 	; register to support generating PWM
count125	equ 17h;
FLAG		equ 18h	;
ERR		equ 19h	;
SUMLO		equ 1ah	;PROGRESSIVE SUM OF the PID terms
ACCUM		equ 1bh	;Error accumulator
ERR_O		equ 1ch		;error history(last error)
VOLTAGEA	equ 1dh	;Voltage actual
mulcnd		equ 1eh	;8 bit multiplicand
mulplr		equ 1fh	;8 bit multiplier
ACCaLO		equ 20h	;for the add routine
ACCbLO		equ 21h	;
H_byte		equ 22h	;High byte of the 16 bit result
L_byte 		equ 23h	;Low byte of the 16 bit result
ACCaHI		equ 24h
ACCbHI		equ 25h
count		equ 26h	;Loop counter
SUMHI		equ 27h	;High byte of the loop sum
KEYPRESS	equ 28h	;KEY counter
LOOPER		equ 29H;

polarity	equ 0
ER_SGN		equ 1	;Sign bit for the error in flag register
AC_SGN		equ 2	;Sign bit for the error accumulator
DE_SGN		equ 3	;Sign bit for DE/DT
OER_SGN		equ 4	;sign bit for the old error
INT		equ 5


;port A:
EN3525		equ 4
TRISAVAL 	equ 0Fh ; RA0-RA3: input;RA4:Output
ADCON1VAL 	equ 0 ; A0-A3 analog in
ADCON0VAL 	equ 89h ; fosc/32, channel 2
ADCON0V0	equ 81h
ADCON0V3	equ 99h

;port B:
LEDR		equ 1
LEDG		equ 2
PWMAU		equ 3
PWMAD		equ 4
PWMBU		equ 5
PWMBD		equ 6
KEY		equ 7
TRISBVAL 	equ h'81' 	


;Program entrance
	org 0
	goto start
	
	org 0004
	btfsc INTCON,INTF
	goto short
	movwf STACKW
	swapf STACKW,F
	swapf STATUS,W
	movwf STACKS
	bcf INTCON,T0IF
	decfsz TIMES,F
	goto ret1
	goto pulse
ret1	
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
pulse
	btfsc FLAG,polarity
	goto polarityb
	btfsc PORTB,PWMAD
	goto Lowpulse
	comf HI,w
	addwf PWMMAX,f
	btfss STATUS,C
	goto HIGHIMPINT
	movf PWMMAX,w
	addwf PCL,f
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	bsf PORTB,PWMAD
	movlw PWMADJUSTVAL+1
	movwf TMR0
	movf HITIMES,w
	movwf TIMES
	goto ret2
HIGHIMPINT
	addlw PWMADJUSTVAL
	movwf TMR0
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
	movf HITIMES,w
	movwf TIMES
	incf TIMES,f
ret2
;	incf COUNTER,F
	movlw PWMMAXVAL
	movwf PWMMAX
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
Lowpulse
	comf LO,w
	addwf PWMMAX,f
	btfss STATUS,C
	goto LOWIMPINT
	movf PWMMAX,w
	addwf PCL,f
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bcf PORTB,PWMAD
	movlw PWMADJUSTVAL+3
	movwf TMR0
	movf LOTIMES,w
	movwf TIMES
	goto ret3
LOWIMPINT
	movlw PWMADJUSTVAL+3
	movwf TMR0
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	movf LOTIMES,w
	movwf TIMES
	incf TIMES,f
ret3	
	bsf FLAG,polarity
	movlw PWMMAXVAL
	movwf PWMMAX
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
polarityb
	btfsc PORTB,PWMBD
	goto Lowpulse2
	comf HI,w
	addwf PWMMAX,f
	btfss STATUS,C
	goto HIGHIMPINT2
	movf PWMMAX,w
	addwf PCL,f
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	bsf PORTB,PWMBD
	movlw PWMADJUSTVAL+5
	movwf TMR0
	movf HITIMES,w
	movwf TIMES
	goto ret4
HIGHIMPINT2
	addlw PWMADJUSTVAL+5
	movwf TMR0
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
	movf HITIMES,w
	movwf TIMES
	incf TIMES,f
ret4
	movlw PWMMAXVAL
	movwf PWMMAX
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
Lowpulse2
	comf LO,w
	addwf PWMMAX,f
	btfss STATUS,C
	goto LOWIMPINT2
	movf PWMMAX,w
	addwf PCL,f
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf PORTB,PWMBD
	movlw PWMADJUSTVAL+2
	movwf TMR0
	movf LOTIMES,w
	movwf TIMES
	goto ret5
LOWIMPINT2
	movlw PWMADJUSTVAL+2
	movwf TMR0
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	movf LOTIMES,w
	movwf TIMES
	incf TIMES,f
ret5	
	bcf FLAG,polarity
	movlw PWMMAXVAL
	movwf PWMMAX
	bsf FLAG,INT
	incf COUNTER1,f
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie

short
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
	bsf PORTB,LEDR
	bcf INTCON,T0IE
	movlw .100		;delay 100 times
	movwf LOOPER
	bsf STATUS,RP0
	movlw 47h
	movwf OPTION_REG
	bcf STATUS,RP0
sdelayloop	
	clrf TMR0
scheckagain
	btfss INTCON,T0IF
	goto scheckagain
	bcf INTCON,T0IF
	decfsz LOOPER,f
	goto sdelayloop
	bcf INTCON,INTF
	goto start

mpy_s				;8 bit multiply
	clrf H_byte
	clrf L_byte
	movlw 8
	movwf count
	movf mulcnd,w
	bcf STATUS,C
loop
	rrf mulplr,f
	btfsc STATUS,C
	addwf H_byte,f
	rrf H_byte,f
	rrf L_byte,f
	decfsz count,f
	goto loop
	retlw 0


D_sub				;Double precision add and subtract
	call neg_A
D_add
	movf ACCaLO,w
	addwf ACCbLO,f
	btfsc STATUS,C
	incf ACCbHI,f
	movf ACCaHI,w
	addwf ACCbHI,f
	retlw 00

neg_A				;negate ACCa
	comf ACCaLO,f
	incf ACCaLO,f
	btfsc STATUS,Z
	decf ACCaHI,f
	comf ACCaHI,f
	retlw 00

SHIFT	MACRO

	BCF STATUS,C
	RRF L_byte,f
	BCF STATUS,C
	RRF H_byte,f
	BTFSC STATUS,C
	BSF L_byte,7
	endM

DIV_LMT				;Divide by 16 and limit to 100 Decimal
	SHIFT
	SHIFT
	SHIFT
	SHIFT
LMT100
	MOVLW 1h
	SUBWF H_byte,0
	BTFSS STATUS,C
	GOTO L8_E
	MOVLW 64H
	MOVWF L_byte
	GOTO LMT_EXIT
L8_E
	MOVLW 64H
	SUBWF L_byte,w
	BTFSS STATUS,C
	GOTO LMT_EXIT
	movlw 64h
	movwf L_byte
LMT_EXIT
	retlw 00

PIDTERM
C_ERR				;Calculating the PID terms
	movf VOLTAGEA,w
	sublw VOLTAGER
	btfsc STATUS,C
	goto PLS_ER
	goto MNS_ER
PLS_ER
	MOVWF ERR
	bcf FLAG,ER_SGN
	goto CE_EXIT
MNS_ER
	movlw VOLTAGER
	subwf VOLTAGEA,w
	movwf ERR
	bsf  FLAG,ER_SGN
CE_EXIT
	clrf SUMLO
	clrf SUMHI
C_PROP				;Calculate the proportional term
	movf ERR,w
	movwf mulcnd
	MOVLW KP
	movwf mulplr
	CALL mpy_s
	call DIV_LMT
restorre_SGN
	btfss FLAG,ER_SGN
	goto ADDPROP
	comf L_byte,f
	INCF L_byte,f
ADDPROP
	movf L_byte,w
	addwf SUMLO,f
	btfsc STATUS,C
	incf SUMHI,f
	movlw 0
	Btfsc SUMLO,7
	movlw 0ffH
	addwf SUMHI,f
C_INT				;calculate the integral term
	movf ERR,w
	btfsc STATUS,Z
	goto ADDINT
	btfsc FLAG,ER_SGN
	goto MNS_1
PLS_1
	movlw KI
	addwf ACCUM,f
	goto LMTACM
MNS_1
	movlw KI
	subwf ACCUM,f
LMTACM
	btfsc ACCUM,7
	goto M_LMT
P_LMT
	MOVLW 9ch
	addwf ACCUM,w
	btfss STATUS,C
	goto ADDINT
	movlw 64h
	movwf ACCUM
	goto ADDINT
M_LMT
	movlw 9ch
	subwf ACCUM,w
	btfsc STATUS,C
	goto ADDINT
	movlw 9ch
	movwf ACCUM
ADDINT
	movf ACCUM,w
	addwf SUMLO,f
	btfsc STATUS,C
	incf SUMHI,f
	movlw 0
	btfsc ACCUM,7
	comf W,w
	addwf SUMHI,f
C_DIFF				;Calculate the differential term
	movf ERR,w
	btfss FLAG,ER_SGN
	goto LO_BYTE
	comf ERR,1
	incf ERR,w
	comf ERR,f
LO_BYTE
	movwf ACCbLO
	movlw 0
	btfsc FLAG,ER_SGN
	movlw 0ffH
	movwf ACCbHI
	movf ERR_O,w
	btfss FLAG,OER_SGN
	goto LO_BYTE0
	comf ERR_O,f
	incf ERR_O,w
LO_BYTE0
	movwf ACCaLO
	movlw 0
	btfsc FLAG,OER_SGN
	movlw 0ffH
	movwf ACCaHI
	call D_sub
STRIP_SGN
	btfsc ACCbHI,7
	goto NEG_ABS
	goto POS_ABS
NEG_ABS
	bsf FLAG,DE_SGN
	comf ACCbLO,f
	incf ACCbLO,w
	movwf ERR_O
	goto MULT_KD
POS_ABS
	BCF FLAG,DE_SGN
	movf ACCbLO,w
	movwf ERR_O
MULT_KD
	movf ERR_O,w
	movwf mulcnd
	movlw KD
	movwf mulplr
	call mpy_s
	call DIV_LMT
RE_SGN
	btfss FLAG,DE_SGN
	goto SAVE_DIFF
	comf L_byte,f
	incf L_byte,f
SAVE_DIFF
	movf L_byte,w
	btfsc STATUS,Z
	goto ROLL_ER
	movwf ERR_O
ADDDIF				;Add the diff term into the summ
	movlw 0
	btfsc FLAG,DE_SGN
	movlw 0ffH
	movwf ACCbHI
	movf ERR_O,W
	movwf ACCbLO
	movf SUMLO,w
	movwf ACCaLO
	movf SUMHI,w
	movwf ACCaHI
	call D_add
	movf ACCbLO,w
	movwf SUMLO
	movf ACCbHI,w
	movwf SUMHI
	
ROLL_ER
	Movf ERR,W
	movwf ERR_O
	bcf FLAG,OER_SGN
	btfsc FLAG,ER_SGN
	bsf FLAG,OER_SGN
	movf HITIMES,w
	movwf ACCaHI
	movf HI,w
	movwf ACCaLO
	movf SUMHI,w
	movwf ACCbHI
	movf SUMLO,w
	movwf ACCbLO
	call D_add
WaitNoIntt
	movf TMR0,W
	sublw 0c8h
	btfss STATUS,C
	goto WaitNoIntt
	
	movf ACCbHI,w
	sublw 24h
	movf ACCbHI,w
	btfss STATUS,C
	movlw 24h
	btfsc STATUS,Z
	movlw 1
	movwf HITIMES
	movwf ACCaHI
	movf ACCbLO,w
	movwf HI
	movf ACCbLO,w
	movwf ACCaLO
	movlw 27h
	movwf ACCbHI
	movlw 10h
	movwf ACCbLO
	call D_sub
	movf ACCbHI,w
	movwf LOTIMES
	movf ACCbLO,w
	movwf LO
	return

SLP
	btfsc PORTB,KEY		;Key press?
	goto RUN		;No
	incf KEYPRESS,f		;Yes,counter +1
	btfss KEYPRESS,7	;reach 128?
	goto RUN1		;No
	bsf PORTA,EN3525	;Yes,go to bed
	bcf INTCON,T0IE		;Disable intuppter
	bcf PORTB,LEDR		;Led OFF
	bcf PORTB,LEDG
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
waitnopress
	btfss PORTB,KEY		;wait key up
	goto waitnopress
	movlw .100		;delay 100 times
	movwf LOOPER
delayloop	
	clrf TMR0
checkagain
	btfss INTCON,T0IF
	goto checkagain
	bcf INTCON,T0IF
	decfsz LOOPER,f
	goto delayloop
	bcf INTCON,RBIF		;Set RB int
	bsf INTCON,RBIE
	sleep			;sleep until RB7 press
	bcf INTCON,RBIE
	bcf INTCON,RBIF
waitnoprs
	btfss PORTB,KEY		;wait key up
	goto waitnoprs
	bcf PORTA,EN3525
	bsf INTCON,T0IE
	bsf PORTB,LEDG
RUN
	clrf KEYPRESS		;clear key counter
RUN1
;	incf COUNTER2,F
;	bcf COUNTER,07h
	return

ADC
	movlw ADCON0VAL
	movwf ADCON0
WaitNoInt
	movf TMR0,W
	sublw 0d0h
	btfss STATUS,C
	goto WaitNoInt
	bsf ADCON0,GO
WaitAdc
	btfsc ADCON0,GO
 	goto WaitAdc
	movf ADRES,W
	movwf VOLTAGEA
	return

;LIGHT
;	btfss COUNTER1,4
;	return
;	movlw 0
;	movwf COUNTER1
;	btfss LEDREG,FLASHR
;	goto NOFLASH1
;	btfss PORTB,LEDR
;	goto LEDRL
;	goto LEDRH
;NOFLASH1
;	btfsc LEDREG,LEDR
;	goto LEDRH
;LEDRL
;	bsf PORTB,LEDR
;	goto LIGHTG
;LEDRH
;	bcf PORTB,LEDR
;LIGHTG
;	btfss LEDREG,FLASHG
;	goto NOFLASH2
;	btfss PORTB,LEDG
;	goto LEDGL
;	goto LEDGH
;NOFLASH2
;	btfsc LEDREG,LEDG
;	goto LEDGH
;LEDGL
;	bsf PORTB,LEDG
;	return
;LEDGH
;	bcf PORTB,LEDG
;	return

LOWDET
	movlw ADCON0V0
	movwf ADCON0
WaitNoIntl
	movf TMR0,W
	sublw 0d0h
	btfss STATUS,C
	goto WaitNoIntl
	bsf ADCON0,GO
WaitAdcl
	btfsc ADCON0,GO
 	goto WaitAdcl
	movf ADRES,W
	sublw LOWVOLTAGE
	btfss STATUS,C
	goto lret1
	incf LOWCOUNT,f
	btfss LOWCOUNT,7
	return
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
	bsf PORTA,EN3525
	bcf INTCON,T0IE
;	bsf LEDREG,LEDR
;	bcf LEDREG,FLASHR
;	bcf LEDREG,FLASHG
;	bcf LEDREG,LEDG
	bcf PORTB,LEDG
	bsf PORTB,LEDR
	bcf INTCON,RBIF		;Set RB int
	bsf INTCON,RBIE
	sleep			;sleep until RB7 press
	bcf INTCON,RBIE
	bcf INTCON,RBIF
	goto start
lret1
	clrf LOWCOUNT
	return

OVERCUT
	movlw ADCON0V3
	movwf ADCON0
WaitNoIntO
	movf TMR0,W
	sublw 0d0h
	btfss STATUS,C
	goto WaitNoIntO
	bsf ADCON0,GO
WaitAdcO
	btfsc ADCON0,GO
 	goto WaitAdcO
	movf ADRES,W
	sublw OVER150
	btfsc STATUS,C
	goto O125
	incf count150,f
	btfss count150,7
	goto O1251
	bsf PORTB,LEDR
	bcf PORTB,LEDG
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
	movlw .50		;delay 100 times
	movwf LOOPER
	movlw 47h
	bsf STATUS,RP0
	movwf OPTION_REG
	bcf STATUS,RP0
	bcf INTCON,T0IE
delayloop1
	clrf TMR0
checkagain1
	btfss INTCON,T0IF
	goto checkagain1
	bcf INTCON,T0IF
	decfsz LOOPER,f
	goto delayloop1
	goto start
O125
	clrf count150
O1251
	movf ADRES,W
	sublw OVER125
	btfsc STATUS,C
	goto ORET
	movf COUNTER1,w
	btfsc STATUS,Z
	incf count125,f
	BTfss count125,4
	return
	bsf PORTB,LEDR
	bcf PORTB,LEDG
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
	movlw .50		;delay 100 times
	movwf LOOPER
	movlw 47h
	bsf STATUS,RP0
	movwf OPTION_REG
	bcf STATUS,RP0
	bcf INTCON,T0IE
delayloop2
	clrf TMR0
checkagain2
	btfss INTCON,T0IF
	goto checkagain2
	bcf INTCON,T0IF
	decfsz LOOPER,f
	goto delayloop2
	goto start
ORET
	clrf count125
	return

start
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
	movlw PWMMAXVAL
	movwf PWMMAX
	movlw 25h
	movwf LOTIMES
	movlw 0
	movwf LO
	movlw 2
	movwf HITIMES
	movlw 10h
	movwf HI
	bsf STATUS,RP0
	movlw TRISAVAL
	movwf TRISA
	movlw TRISBVAL
	movwf TRISB
	movlw ADCON1VAL
	movwf ADCON1
	movlw OPTIONVAL
	movwf OPTION_REG
	bcf STATUS,RP0
	clrf TMR0
	movlw INTCONVAL
	movwf INTCON
	bsf PORTB,LEDG
	bcf PORTB,LEDR
	bcf PORTA,EN3525
Idle
	clrwdt
	call SLP
	btfss FLAG,INT
	goto Idle
	bcf FLAG,INT
	call ADC
	call PIDTERM
	call LOWDET
	call OVERCUT
;	call LIGHT
	goto Idle
                               
	end

