#!/bin/bash

print_usage_message() {
    echo "Usage: $0 <source_pgn_file> <destination_directory>"
    exit 1
}

check_if_file_exists() {
    input_file="$1"
    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' does not exist."
        exit 1
    fi
}

check_if_directory_not_exists() {
    output_dir="$1"
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo "Created directory '$output_dir'."
    fi
}

split_pgn_file() {
    input_file="$1"
    output_dir="$2"
    game_count=0
    game_content=""
    base_name=$(basename "$input_file" .pgn)  # Extract the base name of the input file without the extension

    while IFS= read -r line; do
        # This 'if' will stop once it sees a new [Event], meaning it needs to finish with the current event and proceed to the next one.
        if [[ $line == \[Event* && $line != \[EventDate* ]]; then
            if [[ -n $game_content ]]; then
                game_count=$((game_count + 1))
                echo "$game_content" > "$output_dir/${base_name}_${game_count}.pgn"
                echo "Saved game to $output_dir/${base_name}_${game_count}.pgn"
                game_content=""
            fi
        fi
        game_content+="{$line}\n"
    done < "$input_file"

    # This if statement is for the final game, because our while loop will exit before appending the final game into the output folder.
    if [[ -n $game_content ]]; then
        game_count=$((game_count + 1))
        echo "$game_content" > "$output_dir/${base_name}_${game_count}.pgn"
        echo "Saved game to $output_dir/${base_name}_${game_count}.pgn"
    fi

    echo "All games have been split and saved into '$output_dir'."
}

# Main script
# If the number of arguments are not 2, print the usage message.
if [ "$#" -ne 2 ]; then
    print_usage_message
fi

source_pgn_file="$1"
destination_directory="$2"

check_if_file_exists "$source_pgn_file"
check_if_directory_not_exists "$destination_directory"
split_pgn_file "$source_pgn_file" "$destination_directory"
