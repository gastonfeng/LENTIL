;	150W square waveform inverter & solar charger
;	filename:000228.asm
;	author:Fengjiantao
;	begin from:2000.02.28

	include "p16c711.inc"

;Constant definitions
OPTIONVAL	equ 0xc8	;Option register value
;	1 1 0 0 1 0 0 0
;       | | | | | | | | 
;       | | | | | |_|_|_PS2,PS1,PS0,Prescaler,000=1:1
;       | | | | |_______PSA,Prescaler select,1=WDT(Watch dog timer),0=RTCC
;       | | | |_________RTE,RTCC trig,0=Low to High
;       | | |___________RTS,RTCC input select,0=clkout(fosc/4),1=External
;       | |_____________INTEDG,int trig edge,0=falledge,1=raise edge
;       |_______________RBPU,RB pump up,0=Enable,1=Disable

INTCONVAL 	equ 0xb0	;interrupt control
;	1 0 1 1 0 0 0 0
;	| | | | | | | |_RBIF
;	| | | | | | |___INTF
;	| | | | | |_____T0IF
;	| | | | |_______RBIE,0=Disable
;	| | | |_________INTE,0=Disable
;	| | |___________T0IE,1=Enable
;	| |_____________ADIE,0=Disable
;	|_______________GIE,Globe interrupt control ,1=Enable

ADCON0VAL	equ 0x81	;AD control register 0,CH0
;	1 0 0 0 0 0 0 1
;	| | | | | | | |_ADON,1=Enable AD
;	| | | | | | |___ADIF,set when AD complete
;	| | | | | |_____GO/DONE,AD start when set
;	| | | |_|_______CHS1,CHS0,CH select
;	| | |___________reserve
;	|_|_____________,ADCS1,ADCS0,AD clock select,10=fosc/32

ADCON0VAL1	equ 0x89	;AD control register 0,CH1

PWMADJUSTVAL	equ .20
PWMMAXVAL	equ .29
hightimes	equ .27
lowtimes	equ .12
LVD		equ .140	;3k:1k,10.95V=2.74v,
midvol		equ .154	;12V=3V
hivol		equ .169	;13.2V=3.3V
recon		equ .174	;13.6V=3.4v
HVD		equ .183	;14.3V=3.58v

;Port definitions
;PORTA
TRISAVAL	equ 0x3
ADCON1VAL	equ 2
POWERON		equ 2

;PORTB
TRISBVAL	equ 0x11
TRISBVAL1	equ 0x10
EN3525		equ 0
LEDG		equ 1
LEDR		equ 2
LED		equ 3
TX		equ 2
SCK		equ 3
KEY		equ 4
OUTP		equ 5
PWMOUTBIT	equ 6
OUTN		equ 7

;flag bit definitions
polarity	equ 0
edge		equ 1
falege		equ 2
standby		equ 3
flash		equ 4

;Register definitions
flag 		equ .12		;flag register
STACKW 		equ .13		;w stack
STACKS		equ .14		;flag stack
PWMDESIRED	equ .15		;PWM pluse width
PWMHELP		equ .16		;PWM help register
PWMMAX		equ .17		;maximum pluse with with count MODE
COUNTER		equ .18		;flash LED counter
times		equ .19		;50Hz Waveform counter
KEYPRESS	equ .20		;key press counter
;LOOPER		equ .21		;
;LOWCOUNT	equ .22
adtimes		equ .23		;A/D operation counter
sumhi		equ .24		;
sumlo		equ .25
voltage		equ .26
ddelay		equ .27		;status change counter
ddelay1		equ .28		;status change help counter
delaytype	equ .29		;status change type
keypress2	equ .30		;key press counter
outcount	equ .31		;display number bit counter
xmsreg		equ .32		;display number

;Program Entry
	org 0
	goto begin

;Interrupt Entry
	ORG 04h 			; timer interrupt
	btfsc TMR0,0 			; compensate comp time of 1/2 cyc
	goto PwmInt 			; instruc when timer int occured
PwmInt:
	movwf STACKW 			; copy W register... to "stack"
	swapf STACKW,F 			; ...to "stack"
	swapf STATUS,W 			; copy STATUS register...
	movwf STACKS 			; ...to "stack"
	btfss INTCON,INTF
	goto T0INT
	btfsc INTCON,INTE
	goto EXTINT
T0INT:
	bcf INTCON,T0IF 		; clear interrupt flag
	btfsc PORTB,PWMOUTBIT 		; which edge is required?
	goto Lowpulse 			; -> goto falling edge
Highpulse:
	comf PWMDESIRED,W 		; get desired PWM value
	movwf PWMHELP 			; store val for the foll low pulse
	addwf PWMMAX,F 			; calc number of inst’s to skip
	btfss STATUS,C 			; which method to use?
	goto HighImpInt 		; -> using interrupt
HighImpShrt:
	movf PWMMAX,W 			; get number of inst’s to skip
	addwf PCL,F 			; skip n instructions
	bsf PORTB,PWMOUTBIT 	; rising edge, 28 cycles hi pulse
	bsf PORTB,PWMOUTBIT 	; 27 cycles
	bsf PORTB,PWMOUTBIT 	; 26 cycles
	bsf PORTB,PWMOUTBIT 	; 25 cycles
	bsf PORTB,PWMOUTBIT 	; 24 cycles
	bsf PORTB,PWMOUTBIT 	; 23 cycles
	bsf PORTB,PWMOUTBIT 	; 22 cycles
	bsf PORTB,PWMOUTBIT 	; 21 cycles
	bsf PORTB,PWMOUTBIT 	; 20 cycles
	bsf PORTB,PWMOUTBIT 	; 19 cycles
	bsf PORTB,PWMOUTBIT 	; 18 cycles
	bsf PORTB,PWMOUTBIT 	; 17 cycles
	bsf PORTB,PWMOUTBIT 	; 16 cycles
	bsf PORTB,PWMOUTBIT 	; 15 cycles
	bsf PORTB,PWMOUTBIT 	; 14 cycles
	bsf PORTB,PWMOUTBIT 	; 13 cycles
	bsf PORTB,PWMOUTBIT 	; 12 cycles
	bsf PORTB,PWMOUTBIT 	; 11 cycles
	bsf PORTB,PWMOUTBIT 	; 10 cycles
	bsf PORTB,PWMOUTBIT 	; 9 cycles
	bsf PORTB,PWMOUTBIT 	; 8 cycles
	bsf PORTB,PWMOUTBIT 	; 7 cycles
	bsf PORTB,PWMOUTBIT 	; 6 cycles
	bsf PORTB,PWMOUTBIT 	; 5 cycles
	bsf PORTB,PWMOUTBIT 	; 4 cycles
	bsf PORTB,PWMOUTBIT 	; 3 cycles
	bsf PORTB,PWMOUTBIT 	; 2 cyclesbsf PORTB,PWMOUTBIT ; 1 cycle
	bsf PORTB,PWMOUTBIT 	; 1 cyclesbsf PORTB,PWMOUTBIT ; 1 cycle
	bcf PORTB,PWMOUTBIT 	; fall edge;start of the following
					; low pulse using the interrupt
;	incf COUNTER,F 			; trigger COUNTER, cause there was
	bsf flag,falege				; a rising edge
	comf PWMHELP,W 			; get required low pulse length
	addlw PWMADJUSTVAL+6 		; calculate timer loading value
					; Edge was generated 5 cycles before
					; usual point of time.
	movwf TMR0 			; put value into timer
	goto LowImpInt2 		; low pulse using int is running
HighImpInt: 				; high pulse using interrupt
	addlw PWMADJUSTVAL 		; calculate timer loading value
	movwf TMR0 			; put value into timer
HighImpInt2:
	bsf PORTB,PWMOUTBIT 		; generate rising edge
;	incf COUNTER,F 			; trigger counter, because there
					; was a rising edge
	movlw PWMMAXVAL-1 		; "repair"...
	movwf PWMMAX 			; ...support register

	btfss flag,falege
	goto intreth
	bcf flag,falege
	btfsc PORTB,KEY			;
	clrf KEYPRESS
	incf KEYPRESS,f
	incf ddelay1,f
	btfss ddelay1,7
	goto nexth
	incf COUNTER,f
	incf ddelay,f
	clrf ddelay1
nexth:
	btfsc flag,standby
	goto NOTON
	bcf flag,flash
	bsf PORTB,LED
	bsf STATUS,RP0
	movlw TRISBVAL
	movwf TRISB
	bcf STATUS,RP0
	bcf PORTB,EN3525
	bsf PORTA,POWERON
	bcf INTCON,INTF
	bsf INTCON,INTE
	decfsz times,f			;50Hz Waveform gen
	goto intreth
	btfss flag,polarity		;positive or negative
	goto neg_genh
	btfss flag,edge			;rising edge or falling edge
	goto fallingedgeh
	bsf PORTB,OUTP
	movlw hightimes
	movwf times
	bcf flag,edge
	goto intreth
fallingedgeh:
	bcf PORTB,OUTP
	movlw lowtimes
	movwf times
	bsf flag,edge
	bcf flag,polarity
	goto intreth
neg_genh:
	btfss flag,edge
	goto falledgeh
	bsf PORTB,OUTN
	movlw hightimes
	movwf times
	bcf flag,edge
	goto intreth
falledgeh:
	bcf PORTB,OUTN
	movlw lowtimes
	movwf times
	bsf flag,edge
	bsf flag,polarity
intreth:	

	swapf STACKS,W 			; restore...
	movwf STATUS 			; ...STATUS register
	swapf STACKW,W 			; restore W register
	retfie 				; return to main program
NOTON:
	bcf PORTB,OUTP
	bcf PORTB,OUTN
	btfss flag,flash
	bcf PORTB,LED
	bcf PORTA,POWERON
	bsf STATUS,RP0
	bcf INTCON,INTE
	movlw TRISBVAL1
	movwf TRISB
	bcf STATUS,RP0
	bsf PORTB,EN3525
	goto intreth
	
Lowpulse:
	comf PWMHELP,W 			; get required pulse length
	addwf PWMMAX,F 			; calc number of inst’s to skip
	btfss STATUS,C 			; which method is to use?
	goto LowImpInt 			; ->using interrupt
LowImpShrt:
	movf PWMMAX,W 			; get number of inst’s to skip
	addwf PCL,F 			; skip n instructions
	bcf PORTB,PWMOUTBIT 		; falling edge, 27 cycles low pulse
	bcf PORTB,PWMOUTBIT 		; 26 cycles
	bcf PORTB,PWMOUTBIT 		; 25 cycles
	bcf PORTB,PWMOUTBIT 		; 24 cycles
	bcf PORTB,PWMOUTBIT 		; 23 cycles
	bcf PORTB,PWMOUTBIT 		; 22 cycles
	bcf PORTB,PWMOUTBIT 		; 21 cycles
	bcf PORTB,PWMOUTBIT 		; 20 cycles
	bcf PORTB,PWMOUTBIT 		; 19 cycles
	bcf PORTB,PWMOUTBIT 		; 18 cycles
	bcf PORTB,PWMOUTBIT 		; 17 cycles
	bcf PORTB,PWMOUTBIT 		; 16 cycles
	bcf PORTB,PWMOUTBIT 		; 15 cycles
	bcf PORTB,PWMOUTBIT 		; 14 cycles
	bcf PORTB,PWMOUTBIT 		; 13 cycles
	bcf PORTB,PWMOUTBIT 		; 12 cycles
	bcf PORTB,PWMOUTBIT 		; 11 cycles
	bcf PORTB,PWMOUTBIT 		; 10 cycles
	bcf PORTB,PWMOUTBIT 		; 9 cycles
	bcf PORTB,PWMOUTBIT 		; 8 cycles
	bcf PORTB,PWMOUTBIT 		; 7 cycles
	bcf PORTB,PWMOUTBIT 		; 6 cycles
	bcf PORTB,PWMOUTBIT 		; 5 cycles
	bcf PORTB,PWMOUTBIT 		; 4 cycles
	bcf PORTB,PWMOUTBIT 		; 3 cycles
	bcf PORTB,PWMOUTBIT 		; 2 cycles
	bcf PORTB,PWMOUTBIT 		; 1 cycle
	bsf PORTB,PWMOUTBIT 		; rising edge; start of the next
					; high pulse using the interrupt
	comf PWMDESIRED,W 		; get desired PWM value
	movwf PWMHELP 			; store val for the next lo pulse
	addlw PWMADJUSTVAL+5 		; calculate timer loading value
					; Edge was gen'd 5 cycles before
					; usual point of time.
	movwf TMR0 			; put value into timer
	bsf flag,falege
	goto HighImpInt2 		; high pulse using int is running
LowImpInt: 				; low pulse using interrupt
	addlw PWMADJUSTVAL 		; calculate timer loading value
	movwf TMR0 			; put value into timer
LowImpInt2:
	bcf PORTB,PWMOUTBIT 		; generate falling edge
	movlw PWMMAXVAL
	movwf PWMMAX
	bsf flag,falege
	
	btfss flag,falege
	goto intret
	bcf flag,falege
	btfsc PORTB,KEY			;
	clrf KEYPRESS
	incf KEYPRESS,f
	incf ddelay1,f
	btfss ddelay1,7
	goto nextl
	incf ddelay,f
	incf COUNTER,f
	clrf ddelay1
nextl:
	btfsc flag,standby
	goto NOTON
	bcf flag,flash
	bsf PORTB,LED
	bsf STATUS,RP0
	movlw TRISBVAL
	movwf TRISB
	bcf STATUS,RP0
	bcf PORTB,EN3525
	bsf PORTA,POWERON
	bcf INTCON,INTF
	bsf INTCON,INTE
	decfsz times,f			;50Hz Waveform gen
	goto intret
	btfss flag,polarity		;positive or negative
	goto neg_gen
	btfss flag,edge			;rising edge or falling edge
	goto fallingedge
	bsf PORTB,OUTP
	movlw hightimes
	movwf times
	bcf flag,edge
	goto intret
fallingedge:
	bcf PORTB,OUTP
	movlw lowtimes
	movwf times
	bsf flag,edge
	bcf flag,polarity
	goto intret
neg_gen:
	btfss flag,edge
	goto falledge
	bsf PORTB,OUTN
	movlw hightimes
	movwf times
	bcf flag,edge
	goto intret
falledge:
	bcf PORTB,OUTN
	movlw lowtimes
	movwf times
	bsf flag,edge
	bsf flag,polarity
intret:	
	movlw PWMMAXVAL 		; "repair" ...
	movwf PWMMAX 			; ...support register
	swapf STACKS,W 			; restore ...
	movwf STATUS 			; ...STATUS register
	swapf STACKW,W 			; restore W register
	retfie 				; return to main program

EXTINT:
	bcf INTCON,INTF
	bsf flag,standby
	bsf STATUS,RP0
	movlw TRISBVAL1
	movwf TRISB
	bcf INTCON,INTE 
	bcf STATUS,RP0
	bcf PORTA,POWERON
	bsf PORTB,EN3525
	bsf flag,flash
	swapf STACKS,W
	movwf STATUS
	swapf STACKW,W
	retfie

vtable:					;Temperature comp coefficient table
	addwf PCL,f
	retlw .21
	retlw .20
	retlw .18
	retlw .17
	retlw .15
	retlw .13
	retlw .12
	retlw .10
	retlw .8
	retlw .7
	retlw .5
	retlw .4
	retlw .2
	retlw .0
	retlw .255
	retlw .253
	retlw .251
	retlw .250
	retlw .248
	retlw .247
	retlw .245
	retlw .243
	retlw .242
	retlw .240
	retlw .238
	retlw .237
	retlw .235
	retlw .234
	retlw .232
	retlw .230
	retlw .229
	retlw .227
	
outchar:
	movlw 8
	movwf outcount
out1:
	rrf xmsreg,f
	btfss STATUS,C
	bcf PORTB,TX
	btfsc STATUS,C
	bsf PORTB,TX
	bcf PORTB,SCK
	bsf PORTB,SCK
	decfsz outcount,f
	goto out1
	return

table:
	addwf 2,f
	retlw 3
	retlw 0x9f
	retlw 0x25
	retlw 0xd
	retlw 0x99
	retlw 0x49
	retlw 0x41
	retlw 0x1f
	retlw 1
	retlw 9
	retlw 0x11
	retlw 0xc1
	retlw 0x63
	retlw 0x85
	retlw 0x61
	retlw 0x71
	
	
display:
	movlw 0
	call table
	movwf xmsreg
	call outchar
	call outchar
	movlw 0xf
	andwf sumhi,w
	call table
	movwf xmsreg
	call outchar
	swapf sumhi,f
	movlw 0xf
	andwf sumhi,w
	call table
	movwf xmsreg
	call outchar
	return
	
	
adc:
	clrf adtimes
	clrf sumhi
	clrf sumlo
	movwf ADCON0
	clrwdt
	clrwdt
	clrwdt
	clrwdt
WaitNoInt:
	movf TMR0,W
	movf TMR0,w
	movf TMR0,W
	movf TMR0,w
	clrwdt
	clrwdt
	clrwdt
	clrwdt
	bsf ADCON0,GO
WaitAdc:
	btfsc ADCON0,GO
 	goto WaitAdc
	movf ADRES,W
	addwf sumlo,f
	btfsc STATUS,C
	incf sumhi,f
	incfsz adtimes,f
	goto WaitNoInt
	return



SLP:
	btfss KEYPRESS,7	;reach 128?
	return		;No
	clrf KEYPRESS
	incf keypress2,f
	btfss keypress2,4
	return
	clrf keypress2
	btfsc flag,standby
	goto goon
	bsf flag,standby
	return
goon:	
	bcf flag,standby
	return



begin:
	bsf STATUS,RP0			;Page 1
	MOVLW TRISAVAL
	movwf TRISA
	movlw TRISBVAL
	movwf TRISB
	movlw ADCON1VAL
	movwf ADCON1
	movlw OPTIONVAL
	movwf OPTION_REG
	bcf STATUS,RP0			;Page 0
	movlw 0x0
	movwf PORTB
	bsf PORTB,LEDG
	movlw .255
	movwf PWMDESIRED
	movlw PWMMAXVAL
	movwf PWMMAX
	movlw INTCONVAL
	movwf INTCON
;	bsf flag,standby
	clrf flag
idle:
	clrwdt
	btfss flag,flash
	goto noflash
	btfss COUNTER,5			;32ms*32
	goto die
	bsf PORTB,LED
;	clrf COUNTER
	goto noflash
die:
	bcf PORTB,LED
;	clrf COUNTER
noflash:
	call SLP
	movlw ADCON0VAL
	call adc		;voltage sample
	movf sumhi,w
	movwf voltage
;	movlw ADCON0VAL1
;	call adc		;temperature sample
;	bcf STATUS,C
;	rrf sumhi,f
;	bcf STATUS,C
;	rrf sumhi,f
;	bcf STATUS,C
;	rrf sumhi,w		;div by 8
;	call vtable
;	addwf voltage,f
	call SLP
;	call display
	movlw LVD
	subwf voltage,w
	btfss STATUS,C
	goto isLVD
	movlw HVD
	subwf voltage,w
	btfsc STATUS,C
	goto isHVD
	movlw midvol
	subwf voltage,w
	btfss STATUS,C
	goto isMID
	movlw recon
	subwf voltage,w
	btfss STATUS,C
	goto isrecon
	goto isHI
	goto idle

isLVD:
	movf delaytype,w
	xorlw LVD
	btfss STATUS,Z
	goto LVDset
	btfss ddelay,7
	goto idle
	bsf flag,standby
	bcf PORTB,LEDG
	bsf PORTB,LEDR
	clrf ddelay
	goto idle
LVDset:
	movlw LVD
	movwf delaytype
	clrf ddelay
	goto idle
	
	
isMID:
	movf delaytype,w
	xorlw midvol
	btfss STATUS,Z
	goto midset
	btfss ddelay,1
	goto idle
	bsf PORTB,LEDR
	bsf PORTB,LEDG
	clrf ddelay
	goto idle
midset:
	movlw midvol
	movwf delaytype
	clrf ddelay
	goto idle
	
isHI:
	movf  delaytype,w 
	xorlw hivol
	btfss STATUS,Z
	goto hiset
	btfss ddelay,1
	goto idle
	bsf PORTB,LEDG
	bcf PORTB,LEDR
	clrf ddelay
	goto idle
hiset:
	movf delaytype,w
	movwf hivol
	clrf ddelay
	goto idle
	
isrecon:
	movf delaytype,w
	xorlw recon
	btfss STATUS,Z
	goto reconset
	btfss ddelay,7
	goto idle
	movlw .255
	movwf PWMDESIRED
;	clrf PWMDESIRED
	clrf ddelay
	bcf PORTB,LEDR
	bsf PORTB,LEDG
	goto idle
reconset:
	movlw recon
	movwf delaytype
	clrf ddelay
	goto idle
	
isHVD:
	movf delaytype,w
	xorlw HVD
	btfss STATUS,Z
	goto HVDset
	btfss ddelay,7
	goto idle
	bsf PORTB,LEDG
	bcf PORTB,LEDR
	movf PWMDESIRED,w
	btfss STATUS,Z
	decf PWMDESIRED,w
	movwf PWMDESIRED
	clrf ddelay
	goto idle
HVDset:
	movlw HVD
	movwf delaytype
	clrf ddelay
	goto idle
	
	end
