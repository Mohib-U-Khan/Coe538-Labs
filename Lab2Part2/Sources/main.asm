;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
Counter     DS.W 1
FiboRes     DS.W 1

; Definitions 
LCD_DAT     EQU   PTS             ; LCD data port S, pins PS7,PS6,PS5,PS4
LCD_CNTR    EQU   PORTE           ; LCD control port E, pins PE7(RS),PE4(E)
LCD_E       EQU   $10             ; LCD enable signal, pin PE4
LCD_RS      EQU   $80             ; LCD reset signal, pin PE7

; code section
            ORG   $4000


Entry:
_Startup:
            LDS   #$4000            ; initialize the stack pointer
            JSR   initLCD           ; initialize LCD
            
MainLoop    JSR   clrLCD            ; clear LCD & home cursor
            
            LDX   msg1              ; display msg1
            JSR   putsLCD           ; -"-
            
            LDAA  $3000             ; load contents at $3000 into A
            JSR   leftHLF           ; convert left half of A into ASCII
            STAA  $6000             ; store the ASCII byte into mem1
            
            LDAA  $3000             ; load contents at $3000 into A
            JSR   rightHLF          ; convert right half of A into ASCII
            STAA  $6001             ; store the ASCII byte into mem2
            
            LDAA  $3001             ; load contents at $3001 into A
            JSR   leftHLF           ; convert left half of A into ASCII
            STAA  $6002             ; store the ASCII byte into mem3
            
            LDAA  $3001             ; load contents at $3001 into A
            JSR   rightHLF          ; convert right half of A into ASCII
            STAA  $6003             ; store the ASCII byte into mem4
            
            LDAA  #$0000            ; load 0 into A
            STAA  $6004             ; store string termination character 00 into mem5
            
            LDX   #$6000            ; output the 4 ASCII characters
            JSR   putsLCD           ; -"-
            
            LDY   #$0002            ; Delay = 1s
            JSR   del_50us
            BRA   MainLoop          ; Loop
            
msg1        dc.b  "Hi There! ",0

; subroutine section
initLCD     BSET  DDRS,%11110000    ; configure pins PS7,PS6,PS5,PS4 for output
            BSET  DDRE,%10010000    ; configure pins PE7,PE4 for output
            LDY   #2000             ; wait for LCD to be ready
            JSR   del_50us          ; -"-
            LDAA  #$28              ; set 4-bit data, 2-line display
            JSR   cmd2LCD           ; -"-
            LDAA  #$0C             ; display on, cursor off, blinking off
            JSR   cmd2LCD           ; -"-
            LDAA  #$06              ; move cursor right after entering a character
            JSR   cmd2LCD           ; -"-
            RTS
           
clrLCD      LDAA  #$01              ; clear cursor and return to home position
            JSR   cmd2LCD           ; -"-
            LDY   #40               ; wait until "clear cursor" command is complete
            JSR   del_50us          ; -"-
            RTS
            
del_50us:   PSHX                    ;2 E-clk
eloop:      LDX   #30               ;2 E-clk -
iloop:      PSHA                    ;2 E-clk |
            PULA                    ;3 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            PSHA                    ;2 E-clk | 50us
            PULA                    ;3 E-clk |
            NOP                     ;1 E-clk |
            NOP                     ;1 E-clk |
            DBNE  X,iloop           ;3 E-clk -
            DBNE  Y,eloop           ;3 E-clk
            PULX                    ;3 E-clk
            RTS                     ;5 E-clk
            
cmd2LCD:    BCLR  LCD_CNTR,LCD_RS   ; select the LCD Instruction Register (IR)
            JSR   dataMov           ; send data to IR
            RTS 
            
putsLCD     LDAA  1,X+              ; get one character from the string
            BEQ   donePS            ; reach NULL character?
            JSR   putcLCD
            BRA   putsLCD
donePS      RTS

putcLCD     BSET  LCD_CNTR,LCD_RS   ; select the LCD Data register (DR)
            JSR   dataMov           ; send data to DR
            RTS   
            
dataMov     BSET  LCD_CNTR,LCD_E    ; pull the LCD E-sigal high
            STAA  LCD_DAT           ; send the upper 4 bits of data to LCD
            BCLR  LCD_CNTR,LCD_E    ; pull the LCD E-signal low to complete the write oper.
            LSLA                    ; match the lower 4 bits with the LCD data pins
            LSLA                    ; -"-
            LSLA                    ; -"-
            LSLA                    ; -"-
            BSET  LCD_CNTR,LCD_E    ; pull the LCD E signal high
            STAA  LCD_DAT           ; send the lower 4 bits of data to LCD
            BCLR  LCD_CNTR,LCD_E    ; pull the LCD E-signal low to complete the write oper.
            LDY   #1                ; adding this delay will complete the internal
            JSR   del_50us          ; operation for most instructions
            RTS
            
leftHLF     LSRA                    ; shift data to right
            LSRA
            LSRA
            LSRA
            
rightHLF    ANDA  #$0F              ; mask top half
            ADDA  #$30              ; convert to ascii
            CMPA  #$39
            BLE   out               ; jump if 0-9
            ADDA  #$07              ; convert to hex A-F
out         RTS
                                                                                                                
            
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
