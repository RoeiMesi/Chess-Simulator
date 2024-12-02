#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>

#define MAX_ARGS 100
#define HISTORY_LIMIT 100

// Array to store history of commands
char** history;
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
        fprintf(stderr, "chdir failed: Bad address\n");
    } else if (chdir(path) != 0) {
        perror("chdir failed");
    }
}

// Function to add a command to the history
void add_history(char* cmd) {
    history[history_index] = strdup(cmd);
    if (history[history_index] == NULL) {
        perror("strdup failed");
        exit(EXIT_FAILURE);
    }
    history_index++;
}

// Function to display the command history
void show_history() {
    for (int i = 0; i < history_index; i++) {
        printf("%s", history[i]);
    }
}

// Function to print the current working directory
void print_current_dir() {
    char* cwd = getcwd(NULL, 0);
    if (cwd != NULL) {
        printf("%s\n", cwd);
        free(cwd);
    } else {
        perror("getcwd failed");
    }
}

// Function to parse the input command into arguments
char** tokenize_command(char* cmd) {
    char** args = (char**) malloc(MAX_ARGS * sizeof(char*));
    if (!args) {
        perror("malloc failed");
        exit(EXIT_FAILURE);
    }
    char* token;
    int index = 0;

    token = strtok(cmd, " \n");
    while (token != NULL && index < MAX_ARGS - 1) {
        args[index] = (char*) malloc((strlen(token) + 1) * sizeof(char));
        if (!args[index]) {
            perror("malloc failed");
            exit(EXIT_FAILURE);
        }
        strcpy(args[index++], token);
        token = strtok(NULL, " \n");
    }
    args[index] = NULL;
    return args;
}

// Function to execute a command
void run_command(char** args, char** search_paths, int path_count) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork failed");
        exit(EXIT_FAILURE);
    } else if (pid == 0) {
        execvp(args[0], args);

        // Search for the executable in custom paths
        for (int i = 0; i < path_count; i++) {
            char* cmd_path = (char*) malloc((strlen(search_paths[i]) + strlen(args[0]) + 2) * sizeof(char));
            if (!cmd_path) {
                perror("malloc failed");
                exit(EXIT_FAILURE);
            }
            snprintf(cmd_path, strlen(search_paths[i]) + strlen(args[0]) + 2, "%s/%s", search_paths[i], args[0]);
            execv(cmd_path, args);
            free(cmd_path);
        }

        perror("exec failed");
        exit(EXIT_FAILURE);
    } else {
        // Parent process waits for the child to complete
        int status;
        if (waitpid(pid, &status, 0) < 0) {
            perror("waitpid failed");
        }
    }
}

int main(int argc, char *argv[]) {
    char* input = NULL;
    size_t input_size = 0;
    ssize_t input_len;
    char** args;

    // Array to hold paths passed as arguments, initialize to null.
    char** search_paths = (char**) malloc(MAX_ARGS * sizeof(char*));
    if (!search_paths) {
        perror("malloc failed");
        exit(EXIT_FAILURE);
    }
    int path_count = 0;

    // Allocate memory for the history array
    history = (char**) malloc(HISTORY_LIMIT * sizeof(char*));
    if (!history) {
        perror("malloc failed");
        exit(EXIT_FAILURE);
    }

    // Store the provided directories in search_paths
    for (int i = 1; i < argc; i++) {
        if (path_count < MAX_ARGS) {
            search_paths[path_count] = (char*) malloc((strlen(argv[i]) + 1) * sizeof(char));
            if (!search_paths[path_count]) {
                perror("malloc failed");
                exit(EXIT_FAILURE);
            }
            strcpy(search_paths[path_count++], argv[i]);
        } else {
            fprintf(stderr, "Too many arguments provided\n");
            exit(EXIT_FAILURE);
        }
    }

    while (1) {
        print_prompt();
        input_len = getline(&input, &input_size, stdin);
        if (input_len == -1) break;
        if (strcmp(input, "\n") == 0) continue;

        add_history(input);
        args = tokenize_command(input);
        if (args[0] == NULL) {
            for (int i = 0; args[i] != NULL; i++) {
                free(args[i]);
            }
            free(args);
            continue;
        }
        if (strcmp(args[0], "exit") == 0) {
            for (int i = 0; args[i] != NULL; i++) {
                free(args[i]);
            }
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
        for (int i = 0; args[i] != NULL; i++) {
            free(args[i]);
        }
        free(args);

        // If we reached the maximum amount of arguments acceptable (100), break out of the loop and exit.
        if (history_index == HISTORY_LIMIT) {
            break;
        }
    }

    // Free the memory allocated for the command history
    for (int i = 0; i < history_index; i++) {
        free(history[i]);
    }
    free(history);
    free(input);

    // Free the memory allocated for the search paths
    for (int i = 0; i < path_count; i++) {
        free(search_paths[i]);
    }
    free(search_paths);

    return 0;
}
