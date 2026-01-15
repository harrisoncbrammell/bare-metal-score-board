;the constants
RCC EQU 0x40023800		;base address for RCC
AHB1ENR EQU 0x30 		;offset for this
DELAY_INTERVAL EQU 0x186004		;interval of time for led delay

GPIOA EQU 0x40020000	;base address for PA# stuff
GPIOD EQU 0x40020C00	;base address for PD# stuff

MODER EQU 0x00 			;mode selection register offset (it's 0)
IDR EQU 0x10			;input data register offset from base
ODR EQU 0x14 			;output data register offset from base

;actual code
	AREA Fall2023, CODE	;no longer use "RESET"
	ENTRY
	EXPORT __main	;lets other processes/code "see" our __main

__main PROC	;two underscores then lowercase main
	b Part1
Part1
	ldr r1, =Home ;loads in home score
	ldr r2, =Away ;loads in away score
	ldr r8, =HomeScoreNum
	ldr r9, =AwayScoreNum
	mov r0, #0
LoadingIn
	ldrb r3, [r1], #1 ;loads in vaule and then post index
	ldrb r4, [r2], #1 ;loads in vaule and post index
	cmp r3, #0 ;checks for ending 0
	beq Final ;Branches to the end
	cmp r3, #0x2C ; checks if comma
	beq LoadingIn ; if comma branches back to beginning
	add r0, #1 ;adds one to the gamecount
	bl ASCIISwapH ;Branches to subroutine that converts from ascii
	bl ASCIISwapA ;Branches to subroutine that converts from ascii
	strb r3, [r8], #1 ;stores home game score
	strb r4, [r9], #1 ;stores away game score
	bl Compare ;Branches to compare scores
	b LoadingIn ;Loops back through 
Final	
	bl Storing ;Branches to store subroutine
	
	;now part1 is finished
	mov r12, #0 ;clear the mode register so it starts in the off mode
	bl LEDSetup		;PD15-12
	bl ButtonSetup	;PA0
	


Loop
	;test PA0
	;if it's pressed, lights off
	;otherwise, lights on
	ldr r0, =GPIOA
	ldr r1, [r0, #IDR]	;r1 = inputs on PA# pins
	tst r1, #1		;test bit 0
	bne NextMode;branch if PA0 = 1 (pressed)
	b Loop;here if button not pressed (=0)
NextMode ;calls next mode in cycle
	cmp r12, #0 ;checking status of mode register
	beq ScoreMode
	cmp r12, #1
	beq RecordMode
	cmp r12, #2
	mov r12, #0 ;reset to 0 after all modes have been cycled
	beq Loop
	ENDP	;pair of PROC/ENDP
ScoreMode
	mov r6, #0
	add r12, #1 ;update mode register with new mode
	ldr r1, =NumGames
	ldr r2, [r1] ;number of games is stored in r2
	ldr r1, =HomeScoreNum
	ldr r3, =AwayScoreNum
ScoreLoop
	ldrb r7, [r1], #1 ;load home score for current game in r4 and incriment array pointer to next score
	ldrb r8, [r3], #1	;load away score for current game in r5 and incriment array pointer to next score
	mov r4, r7
	mov r5, r8
	bl Blink
	add r6, #1 ;loop counter incriment
	ldr r2, =NumGames
	ldrb r2, [r2]
	cmp r6, r2;if all games have been displayed go back to main loop (mode swithcing loop)
	beq Loop
	b ScoreLoop
RecordMode
	mov r12, #2 ;update mode register with new mode
	mov r6, #0 ;reset loop counter
	ldr r3, =HomeRecord
	;ldr r3, =AwayRecord
RecordLoop
	;load in record values and display tjem each
	;walks thru each of the home and away teams three record stats and calls blinkbinary for each
	ldrb r4, [r3], #1
	bl BlinkBinary
	ldrb r4, [r3], #1
	bl BlinkBinary
	ldrb r4, [r3], #1
	bl BlinkBinary
	bl Delay
	bl AllLightsOn ;long blink in between home and away
	bl Delay
	bl Delay
	bl LightsOff
	bl Delay
	ldrb r4, [r3], #1
	bl BlinkBinary
	ldrb r4, [r3], #1
	bl BlinkBinary
	ldrb r4, [r3], #1
	bl BlinkBinary
	bl LightsOff
	;add code for mode 2 here
	b Loop
	
BlinkBinary PROC ;used to blink given values in binary for mode2 
	push {R1}
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR
	lsl r4, #12 ;shifts given binary value over to be represented in the led register PD12-15
	orr r1, r4 ;sets needed lights
	;lsl r1, #4
	str r1, [r0, #ODR]
	pop {R1}
	push {LR}
	bl Delay ;delay that lets them stay on for more than a sec
	bl LightsOff
	bl Delay
	pop {LR}
	bx lr
	ENDP


Blink PROC ;blinks the green light for the value of r4 and the blue light for the value of r5 then does the closing sequence
	;check values of blinks left and blink the light if needed
	cmp r4, #0
	beq CheckBlue
	push {LR}
	bl GreenLightOn
	pop {r14}
	sub r4, #1
CheckBlue ;check is r5, the blue light/away team counter needs to be linked
	cmp r5, #0
	beq DelayAndReset
	push {LR}
	bl BlueLightOn
	pop {LR}
	sub r5, #1
DelayAndReset ;delays for half a second then turns off light and checks to see if there is anymore blinking to be done
	push {LR} ;push and pop used to ensure link register isnt lost when calling a sub inside a sub
	bl Delay
	bl LightsOff
	bl Delay
	pop {LR}
	add r10, r4, r5 ;checking to see if all the blinking is done and if so it continues down the line and flashes and exits, if not loops back to blink
	cmp r10, #0
	mov r10, #0
	bne Blink
	push {LR}
	bl AllLightsOn ;does all light blink to indicate current game is finished
	bl Delay
	bl LightsOff
	bl Delay
	pop {LR}
	bx lr
	ENDP
	

Delay PROC
	push {R2}
	LDR   R2,  =DELAY_INTERVAL
delay1
    CBZ	  R2,  turnOFFDELAY ;special instruction that jumps when register input is zero. learned from delay loop source mentioned in report
    SUBS  R2,  R2, #1
	B     delay1
turnOFFDELAY
	pop {R2}
	bx lr
	ENDP
;initialize all LED (PD15-12) to output, turned off
;only call this once
;modifies r0 and r1
LEDSetup	PROC
	;enable clock (read in, modify, store back)
	ldr r0, =RCC	;base address
	ldr r1, [r0, #AHB1ENR]	
	orr r1, #2_1000		;bit 3 = GPIOD (2 = GPIOC, 1 = GPIOB, 0 = GPIOA)		
	str r1, [r0, #AHB1ENR]	;put it back, now PD# clock is on
	
	;set GPIOD 15, 14, 13, 12 as outputs
	;modes: 00 input, 01 output (two bits per pin)
	;bit 31, 30 = PD15 (0,1 for output)
	;bit 29, 28 = PD14 (0,1 for output)
	;bit 27, 26 = PD13 (0,1 for output)
	;bit 25, 24 = PD12 (0,1 for output)
	; etc. ... bit 3, 2 = PD1; bit 1, 0 = PD0
	ldr r0, =GPIOD			;base address
	ldr r1, [r0, #MODER]	;read in with offset of 0 (modes)
	orr r1, #0x55000000		;2_010101010000....0000 set bits 30, 28, 26, 24
	bic r1, #0xAA000000		;2_101010100000....0000 clear 31, 29, 27, 25
	str r1, [r0, #MODER]	;store back (this is when it takes effect)

	;clear/off all four lights
	;IDR and ODR -> one bit per pin 
	;PD15 -> bit 15, etc.
	;clear bits 15, 14, 13, 12 to turn off PD15 - 12
	;blue red orange green
	ldr r1, [r0, #ODR]	;GPIOD's output data is in r1
	bic r1, #0xF000		;clear bits 15-12
	str r1, [r0, #ODR]	;stores new ODR value (PD15-12 definitely off)
	
	bx LR	;return
	ENDP

;set up PA0 as input
;modify r0 and r1
ButtonSetup	PROC
	;clock setup for GPIOA
	ldr r0, =RCC	;base address
	ldr r1, [r0, #AHB1ENR]	;current GPIO clock settings	
	orr r1, #2_0001			;setting bit 0 (0 -> GPIOA)
	str r1, [r0, #AHB1ENR]	;store it back (now GPIOA clock is going)
	
	;set PA0 mode as input (bits # 1 and 0)
	;bits to "mess with" = pin #*2 and (#*2)+1
	;01 setting for output, 00 for input
	ldr r0, =GPIOA			;base address for GPIOA stuff
	ldr r1, [r0, #MODER]	;offset of 0 to get mode settings
	bic r1, #0x03			;2_00000011 -> clears bits 1 and 0
	str r1, [r0, #MODER]	;store it, now PA0 is input

	bx LR
	ENDP

;turn on all four LEDs (PD15-12)
;modify r0 and r1
BlueLightOn	PROC
	push{R0,R1}
	;get current ODR for GPIOD
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR
	;set bits 15-12
	orr r1, #2_1000000000000000 
	;store back
	str r1, [r0, #ODR]	;takes effect, lights on
	pop{R0,R1}
	bx LR
	ENDP
		
GreenLightOn PROC
	push{R0,R1}
	;get current ODR for GPIOD
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR
	orr r1, #2_0001000000000000 
	;store back
	str r1, [r0, #ODR]	;takes effect, lights on
	pop{R0,R1}
	bx LR
	ENDP
		
RedLightOn PROC ;turns on the red light, used for debugging purposes
	push {R0, R1}
	;get current ODR for GPIOD
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR
	;set bits 15-12
	orr r1, #2_0100000000000000 
	;store back
	str r1, [r0, #ODR]	;takes effect, lights on
	pop {R0, R1}
	bx LR
	ENDP
		
AllLightsOn PROC
	push{R0,R1}
	;get current ODR for GPIOD
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR
	;set bits 15-12
	orr r1, #2_1111000000000000 
	;store back
	str r1, [r0, #ODR]	;takes effect, lights on
	pop{R0,R1}
	bx lr
	ENDP
		
;turn off all four LEDs (PD15-12)
;modify r0 and r1
LightsOff	PROC
	push{R0,R1}
	;get current ODR for GPIOD
	ldr r0, =GPIOD	;base address
	ldr r1, [r0, #ODR]	;r1 = PD ODR

	;clear bits 15-12
	bic r1, #2_1111000000000000 ;0xF000, clears bits 15-12

	;store back
	str r1, [r0, #ODR]	;takes effect, lights off
	pop{R0,R1}
	bx LR
	ENDP
		

ASCIISwapH PROC
	sub r3, #0x30 ;subtracts to get vaule out of ascii	
	bx LR ; branches back
	ENDP
ASCIISwapA PROC
	sub r4, #0x30 ;subtracts to get vaule out of ascii	
	bx LR ; branches back
	ENDP
Compare	PROC
	cmp r3, r4; compares Home and away scores
	bgt Greater ;branch if greater
	blt Smaller ;Branch if smaller
	add r5, #1	;adds one to Home Tie counter
	bx LR
	ENDP
Greater PROC
	add r6, #1 ;adds one to win counter
	bx LR
	ENDP
Smaller PROC
	add r7, #1 ;adds one to lose counter
	bx LR
	ENDP
Storing PROC
	ldr r3, =NumGames
	strb r0, [r3] ;Stores amount of games
	ldr r4, =HomeRecord
	ldr r3, =AwayRecord
	strb r6, [r4], #1 ;stores the win for home and index
	strb r7, [r3], #1 ;store the win for away and index
	strb r7, [r4], #1 ;stores loses for home
	strb r6, [r3], #1 ;stores loses for away
	strb r5, [r4] ;stores tie
	strb r5, [r3] ;stores tie
	bx LR
	ENDP
	;single digit number then comma, no spaces, all in ""
	;always have same number of Home and Away scores
Home dcb "4,3,6,1,", 0
Away dcb "4,2,1,1,", 0
	;0x33 in ASCII = 3
	;0x2C in ASCII = ","
	;0x35 in ASCII = 5
	;et cetera for the ASCII
	AREA Project, DATA
	;this is what you'll populate
HomeScoreNum space 20
AwayScoreNum space 20
NumGames space 1 ;how many games
HomeRecord space 3 ;wins, losses, ties
AwayRecord space 3


	END