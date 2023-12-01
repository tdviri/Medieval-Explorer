#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

typedef struct Room {
    int id;
    char *name;
    char *description;
    int south;
    int north;
    int east;
    int west;
    int object;
    bool starting;
} Room;

typedef struct Object {
    int id;
    char *name;
    char *description;
} Object;

bool loadData();
int extractInt(char *line);
char* extractString(char *line);
void gameLoop();
void showRoom(int current);
char* getObjectName(int objectID);
char* getObjectDescription(int objectID);
void showInventory(int *inventory);

Room *rooms;
Object *objects;
int *inventory;
int objectCount = 0;
int inventoryCount = 0;

int main(){
    printf("Welcome to C-Mud\n");
    rooms = (Room*)malloc(sizeof(Room)*1000);
    objects = (Object*)malloc(sizeof(Object)*1000);

    if (loadData()){

    }
    else{
        return 99;
    }

    gameLoop();
    free(rooms);
    free(objects);
    return 0;
}

bool loadData(){
    FILE *file = fopen("world.json", "r");

    if (file == NULL){
        return false;
    }

    char *line = NULL;
    size_t read;
    size_t len;
    bool inRoomsStruct = false;
    bool inObjectsStruct = false;
    while ((read = getline(&line, &len, file)) != -1){
        if (line[read - 1] == '\n'){
            line[read - 1] = 0;
            read--;
        }

        Room r;
        Object o;

        if (strstr(line, "\"rooms\"")){
            inRoomsStruct = true;
        }
        if (strstr(line, "\"objects\"")){
            inObjectsStruct = true;
            inRoomsStruct = false;
        }

        if (strstr(line, "\"id\"") && inRoomsStruct){
            r.north = -1;
            r.south = -1;
            r.east = -1;
            r.west = -1;
            r.id = extractInt(line);
        }

        if (strstr(line, "\"name\"") && inRoomsStruct){
            r.name = extractString(line);
        }

        if (strstr(line, "\"description\"") && inRoomsStruct){
            r.description = extractString(line);
        }

        if (strstr(line, "\"south\"") && inRoomsStruct){
            if (!strstr(line, "null")){
                r.south = extractInt(line);
            }
        }

        if (strstr(line, "\"north\"") && inRoomsStruct){
            if (!strstr(line, "null")){
                r.north = extractInt(line);
            }
        }

        if (strstr(line, "\"east\"") && inRoomsStruct){
            if (!strstr(line, "null")){
                r.east = extractInt(line);
            }
        }

        if (strstr(line, "\"west\"") && inRoomsStruct){
            if (!strstr(line, "null")){
                r.west = extractInt(line);
            }
        }

        if (strstr(line, "\"object\"") && inRoomsStruct){
            r.object = extractInt(line);
        }

        if (strstr(line, "}") && inRoomsStruct){
            if (r.id == 1){
                r.starting = true;
            }
            rooms[r.id] = r;
        }


     if (strstr(line, "\"id\"") && inObjectsStruct){
            o.id = extractInt(line);
        }

        if (strstr(line, "\"name\"") && inObjectsStruct){
            o.name = extractString(line);
        }

        if (strstr(line, "\"description\"") && inObjectsStruct){
            o.description = extractString(line);
        }

        if (strstr(line, "}") && inObjectsStruct){
            objects[objectCount] = o;
            objectCount++;
        }
    }

    return true;
}

int extractInt(char *line){
    char *copy = strdup(line);
    char *token = NULL;
    token = strtok(copy, ":");
    token = strtok(NULL, ":");

    token[strlen(token) - 1] = 0;
    int extractedInt = 0;
    sscanf(token, "%d", &extractedInt);
    free(copy);
    return extractedInt;
}

char* extractString(char *line){
    char *copy = strdup(line);
    char *token = NULL;
    token = strtok(copy, ":");
    token = strtok(NULL, ":");

    token[strlen(token) - 1] = 0;
    token++;
    token++;
    token[strlen(token) - 1] = 0;
    char *output = strdup(token);
    free(copy);
    return output;
}

void gameLoop(){
    char input[100];
    int currentRoom;
    inventory = (int*)malloc(0);

    for (int i = 0; i < 1000; i++){
        if (rooms[i].starting){
            currentRoom = i;
            break;
        }
    }
    while (true){
        showRoom(currentRoom);
        printf("> ");

        fgets(input, sizeof(input), stdin);
        if (input[strlen(input) - 1] == '\n'){
            input[strlen(input) - 1] = 0;
        }

        if (strcmp(input, "quit") == 0 || strcmp(input, "q") == 0){
            printf("Thanks for playing...\n");
            free(inventory);
            break;
        }

        if (strcmp(input, "north") == 0 || strcmp(input, "n") == 0){
            if (rooms[currentRoom].north != -1){
                currentRoom = rooms[currentRoom].north;
                // printf("Moving north? %d\n", rooms[currentRoom].north);
            }
        }

         if (strcmp(input, "west") == 0 || strcmp(input, "w") == 0){
            if (rooms[currentRoom].west != -1){
                currentRoom = rooms[currentRoom].west;
                // printf("Moving west? %d\n", rooms[currentRoom].west);
            }
        }

         if (strcmp(input, "east") == 0 || strcmp(input, "e") == 0){
            if (rooms[currentRoom].east != -1){
                currentRoom = rooms[currentRoom].east;
                // printf("Moving east? %d\n", rooms[currentRoom].east);
            }
        }

         if (strcmp(input, "south") == 0 || strcmp(input, "s") == 0){
            if (rooms[currentRoom].south != -1){
                currentRoom = rooms[currentRoom].south;
                // printf("Moving south? %d\n", rooms[currentRoom].south);
            }
        }

        if (strcmp(input, "get") == 0 || strcmp(input, "g") == 0){
            if (strcmp(getObjectName(rooms[currentRoom].object), "There are no items here.\n") == 0){
                printf("%s\n", getObjectName(rooms[currentRoom].object));
            }
            else{
                printf("You picked up a %s and put it in your backpack\n", getObjectName(rooms[currentRoom].object));
                inventoryCount++;
                inventory = realloc(inventory, sizeof(int) * inventoryCount);
                inventory[(inventoryCount - 1)] = rooms[currentRoom].object;
                rooms[currentRoom].object = -1;
            }
        }

        if (strcmp(input, "look") == 0 || strcmp(input, "l") == 0){
            printf("%s\n", getObjectDescription(rooms[currentRoom].object));
        }

        if (strcmp(input, "drop") == 0 || strcmp(input, "d") == 0){
           showInventory(inventory);
            if (inventoryCount != 0){
                printf("Enter item id number: \n");
                printf("> ");
                fgets(input, sizeof(input), stdin);
                if (input[strlen(input) - 1] == '\n'){
                    input[strlen(input) - 1] = 0;
                }
                int itemID;
                sscanf(input, "%d", &itemID);
                rooms[currentRoom].object = itemID;
                int i = 0;
                int index = 0;
                while (i < inventoryCount){
                    if (inventory[i] == itemID){
                        index = i;
                    }
                    i++;
                }
                for (int j = index; j < inventoryCount - 1; j ++){
                    inventory[j] = inventory[j + 1];
                }
                inventoryCount--;
                inventory = realloc(inventory, sizeof(int) * inventoryCount);
            }
        }

        if (strcmp(input, "inventory") == 0 || strcmp(input, "i") == 0){
            showInventory(inventory);
        }
        sleep(2);
    }
}

void showInventory(int *inventory){
    if (inventoryCount == 0){
        printf("You currently have nothing in your backpack.\n");
        printf("\n");
    }
    else{
        int i = 0;
        printf("Your backpack of ininite holding contains:\n");
        while (i < inventoryCount){
            printf("+ [%d] %s\n", inventory[i], getObjectName(inventory[i]));
            i++;
        }
        printf("\n");
    }
}

void showRoom(int current){
    printf("#%d : %s\n", current, rooms[current].name);
    printf("%s\n", rooms[current].description);
    if (strcmp(getObjectName(rooms[current].object), "There are no items here.\n") != 0){
        printf(" \t You see a %s\n", getObjectName(rooms[current].object));
    }
    printf("[ ");
    if (rooms[current].north != -1){
        printf("[n]orth, ");
    }
    if (rooms[current].south != -1){
        printf("[s]outh, ");
    }
    if (rooms[current].east != -1){
        printf("[e]ast, ");
    }
    if (rooms[current].west != -1){
        printf("[w]est, ");
    }
    printf("[l]ook, [g]et, [i]nventory, [d]rop, [q]uit ]\n");
}

char* getObjectName(int objectID){
    for (int i = 0; i < objectCount; i++){
        if (objects[i].id == objectID){
            return objects[i].name;
        }
    }
     return "There are no items here.\n";
}

char* getObjectDescription(int objectID){
    for (int i = 0; i < objectCount; i++){
        if (objects[i].id == objectID){
            return objects[i].description;
        }
    }
    return "There are no items here.\n";
}
