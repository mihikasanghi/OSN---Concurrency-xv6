#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

// Structure to hold machine information
typedef struct {
    int id;
    int start_time;
    int stop_time;
    pthread_t thread_id;
} Machine;

// Structure to hold flavour information
typedef struct {
    char *name;
    int prep_time;
} Flavour;

// Structure to hold topping information
typedef struct {
    char *name;
    int quantity;
    sem_t semaphore;
} Topping;

// Structure to hold customer information
typedef struct {
    int id;
    int arrival_time;
    int num_ice_creams;
    // Details for each ice cream would be stored in separate structures
    // ...
} Customer;

// Global variables
Machine *machines;
Flavour *flavours;
Topping *toppings;
int N, K, F, T;
sem_t customer_capacity;

// Function to handle the logic for each machine
void *machine_logic(void *arg) {
    Machine *machine = (Machine *)arg;
    
    // Wait for the machine's start time
    // while (/* current time */ < machine->start_time) {
    //     sleep(1);
    // }
    sleep(machine->start_time);

    printf("\033[0;33mMachine %d has started working at %d second(s)\033[0m\n", machine->id, /* current time */);

    // Machine's main loop
    while (/* current time */ < machine->stop_time) {
        // Check for customers and prepare orders if possible
        
        // Simulate order preparation by sleeping the required time
        
        // Update topping quantities and handle customer logic
    }
    
    printf("\033[0;33mMachine %d has stopped working at %d second(s)\033[0m\n", machine->id, /* current time */);
    pthread_exit(NULL);
}

// Function to handle the logic for each customer
void *customer_logic(void *arg) {
    Customer *customer = (Customer *)arg;
    
    // Wait for the customer's arrival time
    while (/* current time */ < customer->arrival_time) {
        sleep(1);
    }
    
    sem_wait(&customer_capacity);
    
    printf("\033[0;37mCustomer %d enters at %d second(s)\033[0m\n", customer->id, /* current time */);
    // Print customer's order in yellow
    printf("\033[0;33mCustomer %d orders %d ice cream(s)\033[0m\n", customer->id, customer->num_ice_creams);
    
    // Check if the order can be fulfilled
    // If not, reject the customer
    // If yes, wait for a machine to become available and process the order

    sem_post(&customer_capacity);
    pthread_exit(NULL);
}

int main() {
    // Read the initial setup values for N, K, F, and T
    
    // Allocate memory for machines, flavours, toppings, and semaphores
    machines = malloc(N * sizeof(Machine));
    flavours = malloc(F * sizeof(Flavour));
    toppings = malloc(T * sizeof(Topping));
    
    // Initialize semaphores
    sem_init(&customer_capacity, 0, K);
    
    // Read machine timings and initialize them
    for (int i = 0; i < N; ++i) {
        // Read machine[i]'s start and stop times
        machines[i].id = i + 1;
        pthread_create(&machines[i].thread_id, NULL, machine_logic, &machines[i]);
    }

    // Read flavour preparation times
    for (int i = 0; i < F; ++i) {
        // Read flavour[i]'s name and preparation time
    }

    // Read topping quantities and initialize semaphores
    for (int i = 0; i < T; ++i) {
        // Read topping[i]'s name and quantity
        // If quantity is not -1, initialize the semaphore with the quantity
    }
    
    // Logic to read and handle customer arrivals would be here
    
    // Wait for all machine threads to finish
    for (int i = 0; i < N; ++i) {
        pthread_join(machines[i].thread_id, NULL);
    }
    
    // Clean up semaphores and dynamically allocated memory
    sem_destroy(&customer_capacity);
    for (int i = 0; i < T; ++i) {
        if (toppings[i].quantity != -1) {
            sem_destroy(&toppings[i].semaphore);
        }
    }
    free(machines);
    free(flavours);
    free(toppings);

    printf("Parlour Closed\n");

    return 0;
}

