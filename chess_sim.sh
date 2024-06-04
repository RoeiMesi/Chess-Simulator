#!/bin/bash
# Name: Roei Mesilaty
# ID: 315253336

# Function to print the metadata from the PGN file
print_metadata() {
    echo "Metadata from PGN file:"
    local description=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            description+="$line\n"
        else
            echo -e "$description"
            break
        fi
    done < "$1"
}

# Function to extract and save game moves
extract_game_moves() {
    local moves_section=false
    local moves=""
    while IFS= read -r line || [ -n "$line" ]; do
        if $moves_section; then
            # Check if the line contains a result marker and remove it
            if [[ "$line" =~ (0-1|1-0|1/2-1/2) ]]; then
                line=$(echo "$line" | sed -e 's/0-1//' -e 's/1-0//' -e 's/1\/2-1\/2//')
                moves+="$line "
                moves_section=false
                continue
            fi
            moves+="$line "
        elif [ -z "$line" ]; then
            moves_section=true
        fi
    done < "$1"
    # Trim trailing whitespace
    moves=$(echo "$moves" | sed 's/[[:space:]]*$//')
    echo "$moves"
}


# Function to parse moves using a Python script
parse_moves_python() {
    local moves_string="$1"
    local parsed_moves
    parsed_moves=$(python3 parse_moves.py "$moves_string")
    echo "$parsed_moves"
}

# Function to initialize the chess board
initialize_chess_board() {
    board=(
        "r n b q k b n r"
        "p p p p p p p p"
        ". . . . . . . ."
        ". . . . . . . ."
        ". . . . . . . ."
        ". . . . . . . ."
        "P P P P P P P P"
        "R N B Q K B N R"
    )
}

# Function to display the chess board
show_chess_board() {
    echo "Move ${move_index}/${#moves[@]}"
    echo "  a b c d e f g h"
    for ((i=0; i<8; i++)); do
        row=${board[i]}
        echo "$((8-i)) $row $((8-i))"
    done
    echo "  a b c d e f g h"
}

# Function to handle game interactions
handle_game() {
    move_index=0
    initialize_chess_board
    show_chess_board

    while true; do
        echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit: "
        read -rsn1 key
        if [[ $key == $'\e' ]]; then
            read -rsn2 key
            key="$key"
        fi
        case $key in
            d)
                if (( move_index < ${#moves[@]} )); then
                    move_piece "${moves[move_index]}"
                    move_index=$((move_index + 1))
                    show_chess_board
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                if (( move_index > 0 )); then
                    move_index=$((move_index - 1))
                    undo_last_move
                    show_chess_board
                else
                    show_chess_board
                fi
                ;;
            w)
                move_index=0
                initialize_chess_board
                show_chess_board
                ;;
            s)
                move_index=${#moves[@]}
                apply_all_moves
                show_chess_board
                ;;
            q)
                echo "Exiting."
                echo "End of game."
                exit 0
                ;;
            *)
                echo "Invalid key pressed: $key"
                ;;
        esac
    done
}

# Function to execute a move on the board
move_piece() {
    local move=$1
    # Extracts the first and second characters from the python output.
    local from=${move:0:2}
    # Extracts the third and fourth characters from the python output.
    local to=${move:2:2}
    # Extracts the fifth character from the python output (will be empty unless this is a promotion move).
    local promotion=${move:4:1}

    local from_x=$((8-$(echo $from | cut -c2)))
    local from_y=$(($(echo $from | cut -c1 | tr 'a-h' '1-8') - 1))
    local to_x=$((8-$(echo $to | cut -c2)))
    local to_y=$(($(echo $to | cut -c1 | tr 'a-h' '1-8') - 1))

    # Convert the board row into an array of characters.
    from_row=(${board[$from_x]})
    to_row=(${board[$to_x]})

    # Get the piece type to move.
    piece=${from_row[$from_y]}

    # Handle castling moves
    # White king-side castling
    if [[ "$from" == "e1" && "$to" == "g1" ]]; then
        from_row[4]="."
        from_row[7]="."
        from_row[6]="K"
        from_row[5]="R"
        board[7]=$(IFS=' '; echo "${from_row[*]}")
    # White queen-side castling
    elif [[ "$from" == "e1" && "$to" == "c1" ]]; then
        from_row[4]="."
        from_row[0]="."
        from_row[2]="K"
        from_row[3]="R"
        board[7]=$(IFS=' '; echo "${from_row[*]}")
    # Black king-side castling
    elif [[ "$from" == "e8" && "$to" == "g8" ]]; then
        from_row[4]="."
        from_row[7]="."
        from_row[6]="k"
        from_row[5]="r"
        board[0]=$(IFS=' '; echo "${from_row[*]}")
    # Black queen-side castling
    elif [[ "$from" == "e8" && "$to" == "c8" ]]; then
        from_row[4]="."
        from_row[0]="."
        from_row[2]="k"
        from_row[3]="r"
        board[0]=$(IFS=' '; echo "${from_row[*]}")
    else
        # Handle en passant capture
        if [[ "$piece" == "P" && "$((from_x - to_x))" == 1 && "$((from_y - to_y))" != 0 && "${to_row[$to_y]}" == "." ]]; then
            from_row[$to_y]="."
            board[$from_x]=$(IFS=' '; echo "${from_row[*]}")
        elif [[ "$piece" == "p" && "$((from_x - to_x))" != 0 && "$((from_y - to_y))" != 0 && "${to_row[$to_y]}" == "." ]]; then
            from_row[$to_y]="."
            board[$from_row]=$(IFS=' '; echo "${from_row[*]}")
        fi
        # Change the place where the piece moved from to ".".
        from_row[$from_y]="."
        # Checks if the promotion is not empty, if not it means that this is a promotion move.
        if [[ -n "$promotion" ]]; then
            if [[ $from_x -ge 6 ]]; then
                # White promotion
                to_row[$to_y]=$(echo "$promotion" | tr 'A-Z' 'a-z')
            else
                # Black promotion
                echo "$promotion"
                to_row[$to_y]=$(echo "$promotion" | tr 'a-z' 'A-Z')
            fi
        else
            if [[ $from_x -eq $to_x ]]; then
                to_row[$from_y]="."
            fi
            to_row[$to_y]=$piece
        fi

        # Update the board with the updated rows.
        board[$from_x]=$(IFS=' '; echo "${from_row[*]}")
        board[$to_x]=$(IFS=' '; echo "${to_row[*]}")
    fi
}

# Function to undo the last move
undo_last_move() {
    initialize_chess_board
    for ((i=0; i<=$move_index-1; i++)); do
        move_piece "${moves[i]}"
    done
}

# Function to apply all moves to the board
apply_all_moves() {
    initialize_chess_board
    for ((i=0; i<${#moves[@]}; i++)); do
        move_piece "${moves[i]}"
    done
}

# Function to validate command line arguments
validate_args() {
    if [ "$#" -ne 1 ]; then
        echo "Invalid number of arguments."
        exit 1
    fi

    local file="$1"
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        exit 1
    fi
    game_file="$file"
}

# Main function
main() {
    validate_args "$@"
    print_metadata "$game_file"
    game_moves=$(extract_game_moves "$game_file")
    moves=$(parse_moves_python "$game_moves")
    moves=($moves)
    handle_game
}

# Start the script
main "$@"
