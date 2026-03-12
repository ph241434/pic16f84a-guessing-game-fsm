# PIC16F84A Guessing Game FSM

This project implements a **finite state machine (FSM)** guessing game on the **PIC16F84A microcontroller** using assembly language.

The program cycles through four LEDs. A player must press the button corresponding to the active LED within the time window. The system evaluates the guess and signals either a win or error state.

---

## Features

- Finite state machine implemented in PIC assembly
- Rotating LED pattern across four outputs
- Button input detection
- Correct / incorrect guess validation
- Win and error output states
- Restart logic after game completion
- Software timing delay (~1 second per state)

---

## Hardware Mapping

### Inputs (PORTA)

| Pin | Function |
|----|----|
| RA0 | G1 button |
| RA1 | G2 button |
| RA2 | G3 button |
| RA3 | G4 button |

### Outputs (PORTB)

| Pin | Function |
|----|----|
| RB0 | L1 LED |
| RB1 | L2 LED |
| RB2 | L3 LED |
| RB3 | L4 LED |
| RB4 | ERR indicator |
| RB5 | WIN indicator |

---

## State Machine

The system rotates through the following states: S1 → S2 → S3 → S4 → repeat


If a button is pressed during a state:

- Correct guess → **SOK (WIN)**
- Incorrect guess → **SERR (ERROR)**

After either WIN or ERROR, the system waits for a new button press and restarts at **S1**.

---

## File Structure
guess_game.asm Main assembly implementation

## Author

Pavel Hardey
