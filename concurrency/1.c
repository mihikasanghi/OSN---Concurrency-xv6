#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

#define MAX_CUSTOMERS 100
#define MAX_BARISTAS 100

// Structure to hold coffee data
typedef struct
{
    char *name;
    int prep_time;
} CoffeeType;

// Structure to hold customer order data
typedef struct
{
    int id;
    CoffeeType *coffee;
    int arrival_time;
    int tolerance_time;
    int has_been_served;
    int delay;
    int barID;
    pthread_mutex_t lock;
} Customer;

// Global variables
CoffeeType coffee_types[MAX_CUSTOMERS];
Customer customers[MAX_CUSTOMERS];
sem_t barista_semaphore;
int B, K, N; // Number of baristas, coffee types, and customers

int barArr[MAX_CUSTOMERS] = {0};
int wastedCoffees = 0;

// Function declarations
void *barista_function(void *param);
void *customer_function(void *param);

int main()
{
    // Read input and initialize coffee_types and customers
    scanf("%d %d %d", &B, &K, &N);
    for (int i = 0; i < K; ++i)
    {
        coffee_types[i].name = malloc(100 * sizeof(char));
        scanf("%s %d", coffee_types[i].name, &coffee_types[i].prep_time);
    }
    for (int i = 0; i < N; ++i)
    {
        customers[i].id = i;
        customers[i].coffee = malloc(sizeof(CoffeeType));
        customers[i].arrival_time = 0;
        customers[i].tolerance_time = 0;
        customers[i].has_been_served = 0;
        customers[i].delay = 0;
        customers[i].barID = 0;
        char coffee_name[100];
        scanf("%d %s %d %d", &customers[i].id, coffee_name, &customers[i].arrival_time, &customers[i].tolerance_time);
        for (int j = 0; j < K; ++j)
        {
            if (strcmp(coffee_name, coffee_types[j].name) == 0)
            {
                customers[i].coffee = &coffee_types[j];
                break;
            }
        }
    }

    // Initialize semaphore
    sem_init(&barista_semaphore, 0, B);

    // Create customer threads
    pthread_t customer_threads[N];
    for (int i = 0; i < N; ++i)
    {
        pthread_mutex_init(&customers[i].lock, NULL);
        pthread_create(&customer_threads[i], NULL, customer_function, (void *)&customers[i]);
    }

    // Wait for all customers to be served or leave
    for (int i = 0; i < N; ++i)
    {
        pthread_join(customer_threads[i], NULL);
    }

    // Clean up
    sem_destroy(&barista_semaphore);
    for (int i = 0; i < N; ++i)
    {
        pthread_mutex_destroy(&customers[i].lock);
    }

    // Print number of coffees wasted
    printf("\n%d coffee wasted\n", wastedCoffees);

    return 0;
}

void *customer_function(void *param)
{
    Customer *customer = (Customer *)param;

    // Wait until the customer arrives
    sleep(customer->arrival_time);
    printf("Customer %d arrives at %d second(s)\n", customer->id, customer->arrival_time);
    int t1 = time(NULL);

    // Try to get a barista
    if (sem_wait(&barista_semaphore) == 0)
    {
        customer->barID = 0;
        for (int i = 0; i < B; i++)
        {
            if (barArr[i] == 0)
            {
                barArr[i] = -1;
                customer->barID = i + 1;
                break;
            }
        }
        int t2 = time(NULL);
        customer->delay = t2 - t1;
        
        // Customer orders
        printf("\033[1;33mCustomer %d orders a %s\033[1;0m\n", customer->id, customer->coffee->name);

        // Check if the customer can wait
        pthread_mutex_lock(&customer->lock);
        if (customer->tolerance_time >= customer->coffee->prep_time + customer->delay)
        {
            sleep(1);
            // Barista begins preparing
            printf("\033[1;36mBarista %d begins preparing the order of customer %d at %d second(s)\033[1;0m\n", customer->barID, customer->id, customer->arrival_time + 1 + customer->delay);

            // Simulate coffee preparation
            sleep(customer->coffee->prep_time);

            // Complete the order
            printf("\033[1;34mBarista %d completes the order of customer %d at %d second(s)\033[1;0m\n", customer->barID, customer->id, customer->arrival_time + 1 + customer->delay + customer->coffee->prep_time);
            customer->has_been_served = 1;
            printf("\033[1;32mCustomer %d leaves with their order at %d second(s)\033[1;0m\n", customer->id, customer->arrival_time + 1 + customer->delay + customer->coffee->prep_time);
        }
        else
        {
            sleep(1);
            // Barista begins preparing
            printf("\033[1;36mBarista %d begins preparing the order of customer %d at %d second(s)\033[1;0m\n", customer->barID, customer->id, customer->arrival_time + 1 + customer->delay);

            // Simulate coffee preparation
            sleep(customer->tolerance_time - customer->delay);

            // Customer leaves without order
            printf("\033[1;31mCustomer %d leaves without their order at %d second(s)\033[1;0m\n", customer->id, customer->arrival_time + 1 + customer->tolerance_time);

            // Simulate coffee preparation
            sleep(-customer->tolerance_time + customer->coffee->prep_time + customer->delay);

            // Complete the order
            printf("\033[1;34mBarista %d completes the order of customer %d at %d second(s)\033[1;0m\n", customer->barID, customer->id, customer->arrival_time + 1 + customer->delay + customer->coffee->prep_time);
            customer->has_been_served = 0;
            wastedCoffees++;
        }
        pthread_mutex_unlock(&customer->lock);

        barArr[customer->barID - 1] = 0;

        sem_post(&barista_semaphore);
    }

    return NULL;
}
