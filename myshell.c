// Name: Roei Mesilaty, ID: 315253336
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>

#define MAX_CMD_LEN 1024
#define MAX_ARGS 100
#define HISTORY_LIMIT 100

// Array to store history of commands
char* history[HISTORY_LIMIT];
// Number of commands stored in history
int history_index = 0;

// Function to display the shell prompt
void print_prompt() {
    printf("$ ");
    fflush(stdout);
}

// Function to change the current working directory
void change_dir(char* path) {
    if (path == NULL) {
        fprintf(stderr, "cd: argument required\n");
    } else if (chdir(path) != 0) {
        perror("chdir error");
    }
}

// Function to add a command to the history
void add_history(char* cmd) {
    if (history_index < HISTORY_LIMIT) {
        history[history_index] = strdup(cmd);
        if (history[history_index] == NULL) {
            perror("strdup error");
            exit(EXIT_FAILURE);
        }
        history_index++;
    } else {
        // Remove the oldest command when history is full
        free(history[0]);
        for (int i = 1; i < HISTORY_LIMIT; i++) {
            history[i - 1] = history[i];
        }
        history[HISTORY_LIMIT - 1] = strdup(cmd);
        if (history[HISTORY_LIMIT - 1] == NULL) {
            perror("strdup error");
            exit(EXIT_FAILURE);
        }
    }
}

// Function to display the command history
void show_history() {
    for (int i = 0; i < history_index; i++) {
        printf("%d %s", i + 1, history[i]);
    }
}

// Function to print the current working directory
void print_current_dir() {
    char cwd[MAX_CMD_LEN];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("%s\n", cwd);
    } else {
        perror("getcwd error");
    }
}

// Function to parse the input command into arguments
char** tokenize_command(char* cmd) {
    char** args = malloc(MAX_ARGS * sizeof(char*));
    if (!args) {
        perror("malloc error");
        exit(EXIT_FAILURE);
    }
    char* token;
    int index = 0;

    token = strtok(cmd, " \n");
    while (token != NULL && index < MAX_ARGS - 1) {
        args[index++] = token;
        token = strtok(NULL, " \n");
    }
    args[index] = NULL;
    return args;
}

// Function to execute a command
void run_command(char** args, char** search_paths, int path_count) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork error");
        exit(EXIT_FAILURE);
    } else if (pid == 0) {
        execvp(args[0], args);

        // Search for the executable in custom paths
        for (int i = 0; i < path_count; i++) {
            char cmd_path[MAX_CMD_LEN];
            snprintf(cmd_path, sizeof(cmd_path), "%s/%s", search_paths[i], args[0]);
            execv(cmd_path, args);
        }

        perror("exec error");
        exit(EXIT_FAILURE);
    } else {
        // Parent process waits for the child to complete
        int status;
        if (waitpid(pid, &status, 0) < 0) {
            perror("waitpid error");
        }
    }
}

int main(int argc, char *argv[]) {
    char input[MAX_CMD_LEN];
    char** args;

    // Array to hold paths passed as arguments
    char* search_paths[MAX_ARGS];
    int path_count = 0;

    // Store the provided directories in search_paths
    for (int i = 1; i < argc; i++) {
        search_paths[path_count++] = argv[i];
    }

    while (1) {
        print_prompt();
        if (fgets(input, MAX_CMD_LEN, stdin) == NULL) break;
        if (strcmp(input, "\n") == 0) continue;

        add_history(input);
        args = tokenize_command(input);
        if (args[0] == NULL) {
            free(args);
            continue;
        }
        if (strcmp(args[0], "exit") == 0) {
            free(args);
            break;
        } else if (strcmp(args[0], "cd") == 0) {
            change_dir(args[1]);
        } else if (strcmp(args[0], "history") == 0) {
            show_history();
        } else if (strcmp(args[0], "pwd") == 0) {
            print_current_dir();
        } else {
            run_command(args, search_paths, path_count);
        }
        free(args);
    }

    // Free the memory allocated for the command history
    for (int i = 0; i < history_index; i++) {
        free(history[i]);
    }

    return 0;
}