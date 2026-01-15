# STM32F4 Assembly Sports Scoreboard 🏈

This project is a bare-metal ARM Assembly program developed for the **STM32F411E-DISCO** board. It processes raw sports data strings to calculate game outcomes and utilizes the board's GPIO peripherals to visualize scores and team records through distinct LED modes.

## 📋 Overview

The system reads two comma-separated ASCII strings representing "Home" and "Away" scores. It parses this data to determine the winner of each game, calculates the season record (Wins, Losses, Ties), and allows the user to cycle through display modes using the User Button.

### Key Features
* **String Parsing:** Converts ASCII strings (e.g., `"4,3,..."`) into integer data.
* **Logic Processing:** Compares scores to determine game outcomes and aggregates season statistics.
* **State Machine:** Implements a polling loop to switch between "Score Mode" and "Record Mode" via button press.
* **Direct Register Access:** Manages `RCC` (Clock) and `GPIO` (General Purpose I/O) registers without using HAL libraries.
* **Visual Output:** Uses the 4 on-board LEDs (Green, Orange, Red, Blue) to display data in both distinct blinks and binary formats.

## 🛠 Hardware Requirements

* **Board:** STM32F411E-DISCO (Discovery Board)
* **Processor:** ARM Cortex-M4
* **IDE:** Keil µVision (MDK-ARM)

## 🎮 Controls & Modes

The program polls the **User Button (PA0)** to cycle through the following modes:

### 1. Idle / Loop
The program waits for user input.

### 2. Score Mode (Mode 1)
Displays the score of each game sequentially.
* **Green LED:** Blinks $N$ times to represent the **Home** score.
* **Blue LED:** Blinks $N$ times to represent the **Away** score.
* *Note:* The Green LED blinks first, followed by the Blue LED for each game.

### 3. Record Mode (Mode 2)
Displays the aggregated season record (Wins, Losses, Ties) in binary using the 4 LEDs (PD12–PD15).
* **Sequence:**
    1.  **Wins** (Binary Display)
    2.  **Losses** (Binary Display)
    3.  **Ties** (Binary Display)
* *Transition:* An "All Lights On" long blink separates the Home record display from the Away record display.

## ⚙️ Technical Details

### Memory Map & Pinout
| Component | Pin | Function |
| :--- | :--- | :--- |
| **User Button** | `PA0` | Input (Mode Switching) |
| **Green LED** | `PD12` | Output (Home Score / Binary bit 0) |
| **Orange LED** | `PD13` | Output (Binary bit 1) |
| **Red LED** | `PD14` | Output (Binary bit 2) |
| **Blue LED** | `PD15` | Output (Away Score / Binary bit 3) |

### Code Structure
* **`Part1`**: Initializes memory, parses the ASCII strings (`Home`, `Away`), and stores the calculated W-L-T record in memory.
* **`Loop`**: The main polling loop that checks the IDR (Input Data Register) of `GPIOA`.
* **`BlinkBinary`**: A subroutine that shifts register values to map integer data onto LEDs PD12–PD15.
* **`Delay`**: A software delay loop to make LED blinks visible to the human eye.

## 🚀 How to Run
1.  Open the project in **Keil µVision**.
2.  Assemble and Build the `projectpart2.s` file.
3.  Flash the code onto the STM32F411E-DISCO board.
4.  Press the **Blue User Button** to start the display cycle.

---
*This code was written as part of a Microprocessors / Embedded Systems course project.*
