;===========================================================
;  Device : PIC16F84A
;  File   : guess_game.asm
;  Name   : Pavel Hardey
;===========================================================
        LIST P=16F84A
        #include <p16f84a.inc>

        __CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC

; Variable Definitions
        CBLOCK 0x0C ; start of GPR in bank 0
STATE           ; current state
GIN             ; last read of G1..G4 (RA0..RA3)
D1              ; delay loop counter 1
D2              ; delay loop counter 2
        ENDC

;-----------------------------------------------------------
;  State encoding
;-----------------------------------------------------------
STATE_S1 EQU 0x00 ; rotating light 1
STATE_S2 EQU 0x01
STATE_S3 EQU 0x02
STATE_S4 EQU 0x03
STATE_SOK EQU 0x04 ; WIN asserted
STATE_SERR EQU 0x05 ; ERR asserted

;-----------------------------------------------------------
;  Reset and interrupt vectors
;-----------------------------------------------------------
        ORG 0x000
        GOTO START ; reset vector

        ORG 0x004
ISR:    RETFIE ; no interrupts used

;  STARTUP / INITIALIZATION
START:
        ; sets STATUS.RP0 = 1 which selects Bank 1
        BSF STATUS, RP0

        ; set the 4 guess buttons
        MOVLW b'00001111'
        MOVWF TRISA

        ; set the lights L1 - L4, ERR, WIN
        MOVLW b'00000000'
        MOVWF TRISB

        ; back to bank 0
        BCF STATUS, RP0

        ; clear ports
        CLRF PORTA
        CLRF PORTB

        ; initial state = S1
        MOVLW STATE_S1 ; W = 0x00
        MOVWF STATE ; 0x00

        GOTO MAIN_LOOP

;-------------------------------------
MAIN_LOOP:
        ; Load STATE into W 
        MOVF STATE, W

        ; Check if STATE == STATE_S1
        XORLW STATE_S1
        BTFSC STATUS, Z
        GOTO STATE_S1_LABEL


        MOVF STATE, W
        XORLW STATE_S2
        BTFSC STATUS, Z
        GOTO STATE_S2_LABEL


        MOVF STATE, W
        XORLW STATE_S3
        BTFSC STATUS, Z
        GOTO STATE_S3_LABEL

       
        MOVF STATE, W
        XORLW STATE_S4
        BTFSC STATUS, Z
        GOTO STATE_S4_LABEL

        ; Check if STATE == STATE_SOK
        MOVF STATE, W
        XORLW STATE_SOK
        BTFSC STATUS, Z
        GOTO STATE_SOK_LABEL

        ; Otherwise it must be STATE_SERR
        GOTO STATE_SERR_LABEL

;  STATE S1  
STATE_S1_LABEL:
        ; L1 = 1, others off, ERR=0, WIN=0
        MOVLW b'00000001' ; 0000 0001
        MOVWF PORTB

        CALL DELAY_1S ; 1 second

        CALL READ_G_INPUTS ; GIN = G4..G1 (RA3..RA0)

        ; --- Decide next state based on GIN ---
        MOVF GIN, W
        BTFSC STATUS, Z ; GIN == 0 ?
        GOTO S1_NO_GUESS ; pulls it to s1_no_guess

        XORLW b'00000001' ; was it exactly 0001
        BTFSC STATUS, Z
        GOTO TO_SOK ; correct guess 

        GOTO TO_SERR ; error

S1_NO_GUESS:
        MOVLW STATE_S2 ; rotate to next node S2
        MOVWF STATE
        GOTO MAIN_LOOP

;  STATE S2  
STATE_S2_LABEL:
        ; L2 = 1
        MOVLW b'00000010' ; 0000 0010
        MOVWF PORTB

        CALL DELAY_1S

        CALL READ_G_INPUTS

        MOVF GIN, W
        BTFSC STATUS, Z 
        GOTO S2_NO_GUESS

        XORLW b'00000010' 
        BTFSC STATUS, Z
        GOTO TO_SOK 

        GOTO TO_SERR

S2_NO_GUESS:
        MOVLW STATE_S3
        MOVWF STATE
        GOTO MAIN_LOOP

	
;  STATE S3  (L3 ON)
STATE_S3_LABEL:
        MOVLW b'00000100' ; 0000 0100
        MOVWF PORTB

        CALL DELAY_1S

        CALL READ_G_INPUTS

        MOVF GIN, W
        BTFSC STATUS, Z 
        GOTO S3_NO_GUESS

        XORLW b'00000100'
        BTFSC STATUS, Z
        GOTO TO_SOK 

        GOTO TO_SERR

S3_NO_GUESS:
        MOVLW STATE_S4
        MOVWF STATE
        GOTO MAIN_LOOP


;  STATE S4  (L4 ON)

STATE_S4_LABEL:

        MOVLW b'00001000'
        MOVWF PORTB

        CALL DELAY_1S

        CALL READ_G_INPUTS

        MOVF GIN, W
        BTFSC STATUS, Z 
        GOTO S4_NO_GUESS

        XORLW b'00001000' 
        BTFSC STATUS, Z
        GOTO TO_SOK 

        GOTO TO_SERR 

S4_NO_GUESS:
        MOVLW STATE_S1
        MOVWF STATE
        GOTO MAIN_LOOP

	
;-----------

	
;  COMMON TRANSITIONS

; correct guess occurred
TO_SOK:
        MOVLW STATE_SOK
        MOVWF STATE
        GOTO MAIN_LOOP

; wrong guess occurred
TO_SERR:
        MOVLW STATE_SERR
        MOVWF STATE
        GOTO MAIN_LOOP


;  STATE SOK  (correct guess, WIN asserted)

STATE_SOK_LABEL:
        ; WIN = 1, others off if you like
        MOVLW b'00100000' ; 0010 0000
        MOVWF PORTB

SOK_WAIT_KEY:
        CALL READ_G_INPUTS
        MOVF GIN, W
        BTFSC STATUS, Z ;no key pressed
        GOTO SOK_WAIT_KEY

        ; any key pressed = restart at S1
        MOVLW STATE_S1
        MOVWF STATE
        GOTO MAIN_LOOP

	
	
;  STATE SERR 
	
STATE_SERR_LABEL:
        ; ERR = 1 
        MOVLW b'00010000' ; 0001 0000
        MOVWF PORTB

SERR_WAIT_KEY:
        CALL READ_G_INPUTS
        MOVF GIN, W
        BTFSC STATUS, Z ; no key pressed
        GOTO SERR_WAIT_KEY

        ; any key = restart at S1
        MOVLW STATE_S1
        MOVWF STATE
        GOTO MAIN_LOOP

	
	
;  SUBROUTINES
	
; Read RA0?RA3 into GIN
READ_G_INPUTS:
        MOVF PORTA, W
        ANDLW b'00001111' ; keep only  4 bits
        MOVWF GIN
        RETURN

; 1 second delay 
DELAY_1S:
        MOVLW d'60' ; outer count
        MOVWF D1
DELAY_OUTER:
        MOVLW d'100' ; inner count
        MOVWF D2
DELAY_INNER:
        NOP
        DECFSZ D2, F
        GOTO DELAY_INNER
        DECFSZ D1, F
        GOTO DELAY_OUTER
        RETURN

        END
