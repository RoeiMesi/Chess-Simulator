#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>

#define MAX_LENGTH 1024
#define MAX_ARGS 64
#define MAX_HISTORY 100
    
    char* command_history[MAX_HISTORY]; // Array to store history of commands
    int history_count = 0;              // Count of commands stored in history

void display_prompt() {
    printf("$ ");
    fflush(stdout); // Ensure that the prompt is displayed immediately
}

void change_directory(char* path) {
    if (!path) {
        printf("Expected path after cd, but nothing was inserted.\n");
    }
    else {
        if (chdir(path) != 0) { // If changing directory has failed, print error chdir.
            perror("chdir");
        }
    }

}

void add_to_history(char* command) {
    if (history_count < MAX_HISTORY) {
        command_history[history_count] = malloc(strlen(command) + 1);
        if (!command_history[history_count]) {
            perror("Memory allocation failed");
            exit(EXIT_FAILURE);
        }
        strcpy(command_history[history_count], command); // Copy the string.
        history_count++;
    } else {
        free(command_history[0]);
        for (int i = 1; i < MAX_HISTORY; i++) {
            command_history[i - 1] = command_history[i];
        }
        command_history[MAX_HISTORY - 1] = malloc(strlen(command) + 1); // Allocate memory for new command
        if (!command_history[MAX_HISTORY -1]){
            perror("Memory allocation failed");
            exit(EXIT_FAILURE);
        }
            strcpy(command_history[MAX_HISTORY - 1], command); // Copy new command
    }
}

void display_history() {
    for (int i = 0; i < history_count; i++) {
        printf("%d %s", i+1, command_history[i]);
    }
}

char** parse_command(char* input) {
    char** args = malloc(MAX_ARGS * sizeof(char*));
    char* token;
    int index = 0;

    token = strtok(input, " \n");
    while (token != NULL && index < MAX_ARGS -1) {
        args[index++] = token;
        token = strtok(NULL, " \n");
    }
    args[index] = NULL;
    return args;
}

void execute_command(char** args) {
    pid_t pid = fork();
    if (pid < 0) {
        exit(EXIT_FAILURE);
    }
    else if (pid == 0) {
        /* Child process */
        execvp(args[0], args);
        perror("Failed to execute command."); // This line is reached if the exec did not work properly.
        exit(EXIT_FAILURE);
    }
    else { // Parent Process
        int status;
        waitpid(pid, &status, 0); // This will make the parent wait until the child process is finished.
    }
}

int main() {
    char input[MAX_LENGTH];
    char** args;
    int i = 0;

    while (1) {
        display_prompt();
        if (fgets(input, MAX_LENGTH, stdin) == NULL) break; // Handle EOF (Ctrl+D)
        if (strcmp(input, "\n") == 0){
            continue; // Ignore empty commands
        }
        add_to_history(input);

        args = parse_command(input);
        if (strcmp(args[0], "exit") == 0)
            break; // Exit command to stop the shell
        else if (strcmp(args[0], "cd") == 0) {
            change_directory(args[1]);
            free(args);
            continue;
        }
        else if (strcmp(args[0], "history") == 0) {
            display_history();
            free(args);
        }

        else {
            execute_command(args);
            free(args);
        }
    }
    for (int i = 0; i < history_count; i++) {
        free(command_history[i]);
    }
    return 0;
}