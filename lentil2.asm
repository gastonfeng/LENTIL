;	150W square waveform inverter
;	filename:lentil.asm
;	author:Fengjiantao
;	Email:fjt@yeah.net
;	begin from:1999.10.10

	include p16c711.inc

;Constant definitions
OUTCYC		equ 20000	;50Hz@4MHz fosc


;Register Equates

;HITIMES		equ 0ch
;HI		equ 0dh
;LOTIMES		equ 0eh
TMRVAL		equ 0fh
TIMES		equ 10h
STACKW 		equ 11h ; stack to push/pop the W-register
STACKS 		equ 12h ; stack to push/pop the STATUS-reg
;COUNTER 	equ 13h ; counter: input frequency
			; f1 = crystalfreq. / 4 / 255
;COUNTER2 	equ 14h ; counter2: input frequency
			; f2 = f1 / 128
DESIRED		equ 14h			
PWMDESIRED 	equ 15h ; desired PWM value 0..255
;PWMMAX 		equ 16h 	; register to support generating PWM
		; You have to put PWMMAXVAL into it!
;PWMHELP 	equ 17h ; register to support generating PWM
FLAG		equ 18h	;
ERR		equ 19h	;
SUMLO		equ 1ah	;PROGRESSIVE SUM OF the PID terms
ACCUM		equ 1bh	;Error accumulator
ERR_O		equ 1ch		;error history(last error)
VOLTAGEA	equ 1eh	;Voltage actual

mulcnd		equ 1fh	;8 bit multiplicand
mulplr		equ 20h	;8 bit multiplier
ACCaLO		equ 1fh	;for the add routine
ACCbLO		equ 20h	;
H_byte		equ 21h	;High byte of the 16 bit result
L_byte 		equ 22h	;Low byte of the 16 bit result
ACCaHI		equ 21h
ACCbHI		equ 22h
count		equ 23h	;Loop counter
SUMHI		equ 24h	;High byte of the loop sum
KEYPRESS	equ 25h	;KEY counter
LOOPER		equ 26H;


polarity	equ 0
ER_SGN		equ 1	;Sign bit for the error in flag register
AC_SGN		equ 2	;Sign bit for the error accumulator
DE_SGN		equ 3	;Sign bit for DE/DT
OER_SGN		equ 4	;sign bit for the old error


KP		equ .30	;Proportional gain
KI		equ .2	;Integral gain
KD		equ .20	;Differential gain
;PWMMAXVAL	equ .29
INTCONVAL equ 0a0h ; set GIE, T0IE

;port A:
EN3525		equ 4
TRISAVAL equ 0Fh ; RA0-RA3: input;RA4:Output
ADCON1VAL equ 0 ; A0-A3 analog in
ADCON0VAL equ 81h ; fosc/32, channel 2

;port B:
LEDR		equ 1
LEDG		equ 2
PWMAU		equ 3
PWMAD		equ 4
PWMBU		equ 5
PWMBD		equ 6
KEY		equ 7
TRISBVAL equ h'81' 	
OPTIONVAL equ 8h ; portB have pull-up, tmr0 int.

; PWM-module-constant
;PWMADJUSTVAL equ .22
VOLTAGER	equ .162	;Voltage request

;Program entrance
	org 0
	goto start
	
	org 0004
	btfsc TMR0,0	;compensate comp time of 1/2 cyc
	goto PwmInt
PwmInt
	movwf STACKW
	swapf STACKW,F
	swapf STATUS,W
	movwf STACKS
	bcf INTCON,T0IF
	movf TMRVAL,w
 	movwf TMR0
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
	movf PWMDESIRED,w
	movwf TIMES
	bsf PORTB,PWMAD
	bcf PORTB,PWMBU
;	incf COUNTER,F
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
Lowpulse
	comf PWMDESIRED,w
	movwf TIMES
	bcf PORTB,PWMAD
	bsf PORTB,PWMBU
	bsf FLAG,polarity
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
polarityb
	btfsc PORTB,PWMBD
	goto Lowpulseb
	movf PWMDESIRED,w
	movwf TIMES
	bsf PORTB,PWMBD
	bcf PORTB,PWMAU
;	incf COUNTER,F
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
Lowpulseb
	comf PWMDESIRED,w
	movwf TIMES
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bcf FLAG,polarity
	movf DESIRED,w
	movwf PWMDESIRED
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie

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
	btfss SUMHI,7
	goto LETDES
	comf SUMLO,f
	incf SUMLO,f
	movf SUMLO,w
	subwf DESIRED,w
	btfss STATUS,C
	movlw .5
	movwf DESIRED
	goto LET
LETDES
	movf DESIRED,w
	addwf SUMLO,w
	btfsc STATUS,C
	movlw .250
	movwf DESIRED
LET
;	movf VOLTAGEA,w
	return

SLP
;	bsf STATUS,RP0		;Page 1
;	movlw OPTIONVAL		;Reset Option register
;	movwf OPTION_REG
;	bcf STATUS,RP0		;resume page 0
;	btfss COUNTER,07h
;	goto Idle
	btfsc PORTB,KEY		;Key press?
	goto RUN		;No
	incf KEYPRESS,f		;Yes,counter +1
	btfss KEYPRESS,7	;reach 128?
	goto RUN1		;No
	bsf PORTA,EN3525	;Yes,go to bed
	bcf INTCON,GIE		;Disable intuppter
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
	bsf INTCON,GIE
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
	
start
	clrf TMR0
	clrf PWMDESIRED
	movlw .176
	movwf TMRVAL
	bcf PORTB,PWMAD
	bcf PORTB,PWMBD
	bsf PORTB,PWMAU
	bsf PORTB,PWMBU
;	movlw PWMMAXVAL
;	movwf PWMMAX
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
	movlw INTCONVAL
	movwf INTCON
	bsf PORTB,LEDG
Idle
	clrwdt
	call SLP
	call ADC
	call PIDTERM
	movwf DESIRED
	goto Idle
                               
	end

