#!/bin/bash

print_game_details() {
    echo "Metadata from PGN file:"
    game_description=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            game_description+="$line\n"
        else
            echo -e "$game_description"
            break
        fi
    done < "$1"
}

save_game_moves() {
    game_moves=""
    in_moves_section=false
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            in_moves_section=true
            continue
        fi
        if $in_moves_section; then
            if [[ "$line" == *"0-1"* || "$line" == *"1-0"* || "$line" == *"1/2-1/2"* ]]; then
                line=$(echo "$line" | sed -e 's/0-1//' -e 's/1-0//' -e 's/1\/2-1\/2//')
            fi
            game_moves+="$line "
        fi
    done < "$1"
}

parse_moves() {
    moves=$(python3 parse_moves.py "$game_moves")
    echo "$moves"
}

initialize_board() {
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

display_board() {
    echo "Move ${move_index}/${#moves[@]}"
    echo "  a b c d e f g h"
    for ((i=0; i<8; i++)); do
        row=${board[i]}
        echo "$((8-i)) $row $((8-i))"
    done
    echo "  a b c d e f g h"
}

begin_game() {
    move_index=0  # Initialize move index

while true; do
    echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
    read -n 1 -s key
    case $key in
        d)
            if (( move_index < ${#moves[@]} )); then
                move_piece "${moves[move_index]}"
                move_index=$((move_index + 1))
                display_board
            else
                echo "No more moves available."
            fi
            ;;
        a)
            if (( move_index > 0 )); then
                move_index=$((move_index - 1))
                undo_move
                display_board
            fi
            ;;
        w)
            move_index=0
            initialize_board
            display_board
            ;;
        s)
            move_index=${#moves[@]}
            apply_all_moves
            display_board
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

move_piece() {
    local move=$1
    # Extracts the first two characters from the python output.
    local from=${move:0:2}
    # Extracts the last two characters from the python output.
    local to=${move:2:2}
    local promotion=${move:4:1}

    local from_x=$((8-$(echo $from | cut -c2)))
    local from_y=$(($(echo $from | cut -c1 | tr 'a-h' '1-8') - 1))
    local to_x=$((8-$(echo $to | cut -c2)))
    local to_y=$(($(echo $to | cut -c1 | tr 'a-h' '1-8') - 1))

    echo "Moving from $from ($from_x, $from_y) to $to ($to_x, $to_y)"

    # Convert the board row into an array of characters
    from_row=(${board[$from_x]})
    to_row=(${board[$to_x]})

    # Get the piece to move
    piece=${from_row[$from_y]}

    # Handle castling moves
    if [[ "$from" == "e1" && "$to" == "g1" ]]; then
        from_row[4]="."  # Clear the king's original position
        from_row[7]="."  # Clear the rook's original position
        from_row[6]="K"  # Move the king to the correct position
        from_row[5]="R"  # Move the rook to the correct position
        board[7]=$(IFS=' '; echo "${from_row[*]}")
    elif [[ "$from" == "e1" && "$to" == "c1" ]]; then
        from_row[4]="."  # Clear the king's original position
        from_row[0]="."  # Clear the rook's original position
        from_row[2]="K"  # Move the king to the correct position
        from_row[3]="R"  # Move the rook to the correct position
        board[7]=$(IFS=' '; echo "${from_row[*]}")
    elif [[ "$from" == "e8" && "$to" == "g8" ]]; then
        from_row[4]="."  # Clear the king's original position
        from_row[7]="."  # Clear the rook's original position
        from_row[6]="k"  # Move the king to the correct position
        from_row[5]="r"  # Move the rook to the correct position
        board[0]=$(IFS=' '; echo "${from_row[*]}")
    elif [[ "$from" == "e8" && "$to" == "c8" ]]; then
        from_row[4]="."  # Clear the king's original position
        from_row[0]="."  # Clear the rook's original position
        from_row[2]="k"  # Move the king to the correct position
        from_row[3]="r"  # Move the rook to the correct position
        board[0]=$(IFS=' '; echo "${from_row[*]}")
    else
        # Handle en passant capture
        if [[ "$piece" == "P" && "$((from_x - to_x))" == 1 && "$((from_y - to_y))" != 0 && "${to_row[$to_y]}" == "." ]]; then
            from_row[$to_y]="."
            echo "Captured piece: ${from_row[$to_y]}"  # Debug statement
            board[$from_x]=$(IFS=' '; echo "${from_row[*]}")
        elif [[ "$piece" == "p" && "$((from_x - to_x))" != 0 && "$((from_y - to_y))" != 0 && "${to_row[$to_y]}" == "." ]]; then
            from_row[$to_y]="."
            echo "Captured piece: ${from_row[$to_y]}"  # Debug statement
            board[$from_row]=$(IFS=' '; echo "${from_row[*]}")
        fi

        # Move the piece
        echo "From is: ${from_row[$from_y]}"
        from_row[$from_y]="."
        # Checks if the promotion is not empty, if not it means that there is a promotion.
        if [[ -n "$promotion" ]]; then
            if [[ $from_x -ge 6 ]]; then
                # White promotion
                to_row[$to_y]=$(echo "$promotion" | tr 'a-z' 'A-Z')
            else
                # Black promotion
                to_row[$to_y]=$(echo "$promotion" | tr 'A-Z' 'a-z')
            fi
        else
            if [[ $from_x -eq $to_x ]]; then
                to_row[$from_y]="."
            fi
            to_row[$to_y]=$piece
        fi

        # Handle promotion
        if [[ -n "$promotion" ]]; then
            to_row[$to_y]=$(echo "$promotion" | tr 'a-z' 'A-Z')  # Assuming promotion is to a queen
        fi

        # Update the board with the new rows
        board[$from_x]=$(IFS=' '; echo "${from_row[*]}")
        board[$to_x]=$(IFS=' '; echo "${to_row[*]}")
    fi
}

# Main function and other parts of the script remain unchanged

undo_move() {
    initialize_board
    for ((i=0; i<=$move_index-1; i++)); do
        move_piece "${moves[i]}"
    done
}

apply_all_moves() {
    initialize_board
    for ((i=0; i<${#moves[@]}; i++)); do
        move_piece "${moves[i]}"
    done
}

# Main function
if [ "$#" -ne 1 ]; then
    echo "Invalid amount of arguments."
    exit 1
fi

game_file="$1"
if [ ! -f "$game_file" ]; then
    echo "File does not exist: $game_file"
    exit 1
fi

print_game_details "$game_file"
save_game_moves "$game_file"

moves=$(parse_moves)
moves=($moves)  # Convert string to array

initialize_board
display_board

begin_game
