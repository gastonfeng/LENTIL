;	150W square waveform inverter
;	filename:lentil.asm
;	author:Fengjiantao
;	Email:fjt@yeah.net
;	begin from:1999.10.10

	include p16c711.inc

;Register Equates

HI	equ 0ch		;Pluse Hi
LO	equ 0dh		;Pluse Lo

COUNTER	equ 0eh
PWMMAXVAL	equ .29
OPTIONVAL equ 88h ; portB no pull-up, tmr0 int.
INTCONVAL equ 0a0h ; set GIE, T0IE

;port A:
UINPBIT equ 00h ; analog input for desired PWM
PWMOUTBIT equ 03h ; PWM output
TRISAVAL equ 17h ; A3 output
ADCON1VAL equ 2 ; A0,A1 analog; A2,A3 digital
ADCON0VAL equ 81h ; fosc/32, channel 0

;port B:
TRISBVAL equ 0 ; LED outputs

;------------------------------------------------------------------
	; Register Definitions
STACKW equ 0ch ; stack to push/pop the W-register
STACKS equ 0dh ; stack to push/pop the STATUS-reg
COUNTER equ 0eh ; counter: input frequency
			; f1 = crystalfreq. / 4 / 255
COUNTER2 equ 0fh ; counter2: input frequency
			; f2 = f1 / 128
PWMDESIRED equ 10h ; desired PWM value 0..255
PWMMAX equ 11h 	; register to support generating PWM
		; You have to put PWMMAXVAL into it!
PWMHELP equ 12h ; register to support generating PWM
; used as temp storage of PWMDESIRED
;------------------------------------------------------------------
; PWM-module-constant
PWMADJUSTVAL equ .22

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
	btfsc PORTA,PWMOUTBIT
	goto Lowpulse
Highpulse
	comf PWMDESIRED,W
	movwf PWMHELP
	addwf PWMMAX,F
	btfss STATUS,C
	goto HighImpInt
HighImpShrt
	movf PWMMAX,W
	addwf PCL,F
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	bsf PORTA,PWMOUTBIT
	incf COUNTER,F
	comf PWMHELP,W
	addlw PWMADJUSTVAL+5
	movwf TMR0
	goto LowImpInt2
HighImpInt
	addlw PWMADJUSTVAL
	movwf TMR0
HighImpInt2
	bsf PORTA,PWMOUTBIT
	incf COUNTER,F
	movlw PWMMAXVAL-1
	movwf PWMMAX
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie
Lowpulse
	comf PWMHELP,W
	addwf PWMMAX,F
	btfss STATUS,C
	goto LowImpInt
LowImpShrt
	movf PWMMAX,W
	addwf PCL,F
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	bcf PORTA,PWMOUTBIT
	comf PWMDESIRED,W
	movwf PWMHELP
	addlw PWMADJUSTVAL+5
	movwf TMR0
	goto HighImpInt2
LowImpInt
	addlw PWMADJUSTVAL
	movwf TMR0
LowImpInt2
	bcf PORTA,PWMOUTBIT
	movlw PWMMAXVAL
	movwf PWMMAX
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie



start
	clrf TMR0
	clrf PWMDESIRED
	bcf PORTA,PWMOUTBIT
	movlw PWMMAXVAL
	movwf PWMMAX
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

Idle
	clrwdt
	btfss COUNTER,07h
	goto Idle
	incf COUNTER2,F
	bcf COUNTER,07h
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
	movwf PWMDESIRED
	movwf PORTB
	goto Idle
                               
	org 01ffh
	goto start
	
	org 2007h
EEPROM	DW 16h	

	end



Build completed successfully.

Build completed successfully.
