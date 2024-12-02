# Chess Simulator

Chess Simulator is a command-line toolset designed for chess enthusiasts, developers, and learners. With this simulator, you can manage and analyze chess games stored in PGN files, parse moves, and interactively simulate chess games on a terminal-based chessboard.

---

## What is a PGN File?

PGN (Portable Game Notation) is a widely-used text format for recording chess games. It contains metadata about the game (e.g., players, date, result) and the sequence of moves played. This simulator utilizes PGN files to perform various operations, including splitting, parsing, and simulating games.

---

## Features

- **PGN File Management**  
  Split a PGN file containing multiple games into individual files with `split_pgn.sh`.

- **Move Parsing**  
  Convert SAN (Standard Algebraic Notation) moves into UCI (Universal Chess Interface) format using `parse_moves.py`.

- **Interactive Chess Simulation**  
  Simulate chess games interactively with an ASCII-based chessboard using `chess_sim.sh`.

- **Custom Shell**  
  Use the custom shell `myshell` to execute commands, navigate directories, and view history.

---

## Setup

### Prerequisites
- **Python 3.x**
- `python-chess` library (install via `pip install python-chess`)
- Linux or Unix-based system
- GCC (to compile `myshell.c`)

### Installation
1. Clone the repository:
    ```bash
    git clone https://github.com/<username>/Chess-Simulator.git
    cd Chess-Simulator
    ```

2. Compile the custom shell:
    ```bash
    gcc -o myshell myshell.c
    ```

3. Make the scripts executable:
    ```bash
    chmod +x split_pgn.sh chess_sim.sh
    ```

---

## How to Start

### Running the Chess Simulator
The Chess Simulator consists of several tools that can be executed individually:

1. **Splitting PGN Files**  
   Use the `split_pgn.sh` script to split a PGN file into individual games:
   ```bash
   ./split_pgn.sh <source_pgn_file> <destination_directory>
