#!/bin/bash
# Various tools for running a minecraft server.
# Change the constants below to specify the location of the folders.
# It is recommended to keep these at the default values.

# Exit codes:
#   0   -   Script exited cleanly.
#   1   -   World not found.
#   2   -   Invalid server status (on when it needs to be off, and vice-versa).
#   3   -   User cancelled operation.
#   4   -   Script reached somewhere it shouldn't.  Should not happen.

export SERVER_MAIN=/home/shamus03/mcserver

export FILES=$SERVER_MAIN/files
export WORLDS=$SERVER_MAIN/worlds
export SERVER_FOLDER=$SERVER_MAIN/server_folder
export PROCESS_PREFIX=mcserver
export SERVER_NAME_PREFIX="[Bloated Orange]"
cd $WORLDS

command=$1

while [ -z $command ]; do
        read -p "Command: " -e command
done

case $command in
    start)
        world=$2
        while [ -z $world ]; do
            read -p "World: " -e world
        done
        if [ -d $world ]; then
                cd $world
            if ! screen -list | grep -q $PROCESS_PREFIX-$world; then
                screen -dmS $PROCESS_PREFIX-$world \
                    java -Xmx2G -Xms2G -jar minecraft_server.jar nogui
                screen -x $PROCESS_PREFIX-$world -X screen ./beep.sh
                echo "Server \"$world\" started."
                exit 0
            else
                echo "Server already running."
                exit 2
            fi
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    stop)
        world=$2
        while [ -z $world ]; do
            read -p "Server to stop: " -e world
        done
        if [ -d $world ]; then
            if screen -list | grep -q $PROCESS_PREFIX-$world; then
                screen -x $PROCESS_PREFIX-$world -p 1 -X kill
                screen -x $PROCESS_PREFIX-$world -p 0 -X stuff `printf "stop\r"`
                screen -x $PROCESS_PREFIX-$world -p 0
                echo "Server successfully stopped." >> $world/server.log
                echo "Server \"$world\" stopped."
                exit 0
            else
                echo "Server \"$world\" not running."
                exit 2
            fi
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    restart)
        world=$2
        while [ -z $world ]; do
                read -p "Server to restart: " -e world
        done
        mcserver stop $world
        case $? in
            0)
                mcserver start $world
                exit 0
                ;;
            1)
                exit 1
                ;;
            2)
                exit 2
                ;;
            *)
                exit 4
                ;;
        esac
        ;;
    connect)
        world=$2
        while [ -z $world ]; do
            read -p "Server to connect to: " -e world
        done
        if [ -d $world ]; then
            if screen -list | grep -q $PROCESS_PREFIX-$world; then
                screen -r $PROCESS_PREFIX-$world -p 0
                exit 1
            else
                echo "Server not running."
                exit 2
            fi
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    edit)
        world=$2
        while [ -z $world ]; do
            read -p "Server to edit properties of: " -e world
        done
        if [ -d $world ]; then
            cd $world
            vi server.properties
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    relink)
        world=$2
        while [ -z $world ]; do
            read -p "Server to relink: " -e world
        done
        if [ -d $world ]; then
            cd $world
            ln -f -s $FILES/minecraft_server.jar minecraft_server.jar
            ln -f -s $FILES/LoginMessage.txt LoginMessage.txt
            ln -f -s $FILES/beep.sh beep.sh
            echo "Links recreated."
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    folder)
        world=$2
        while [ -z $world ]; do
            read -p "World: " -e world
        done
        if [ -d $world ]; then
            cd $world
            echo "$WORLDS/$world"
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    worlds)
            echo "$WORLDS"
        exit 0
        ;;
    servermain)
            echo "$SERVER_MAIN"
        exit 0
        ;;
    list)
            ls
        exit 0
        ;;
    new)
        world_to_create=$2
        while [ -z $world_to_create ]; do
            read -p "World name: " -e world_to_create
        done
        if [ -d $world_to_create ]; then
            echo "World already exits."
            exit 1
        else
            cp -R $SERVER_FOLDER $world_to_create
            cd $world_to_create
            mcserver relink $world_to_create > /dev/null
            perl -pi -e "s/level-name=.*/level-name=$world_to_create/g" \
                server.properties
            perl -pi -e \
                "s/motd=.*/motd=$SERVER_NAME_PREFIX$world_to_create/g" \
                server.properties
            echo "World \"$world_to_create\" created."
            exit 0
        fi
        ;;
    delete)
        world_to_delete=$2
        while [ -z $world_to_delete ]; do
            read -p "Delete world: " -e world_to_delete
        done
        if [ -d $world_to_delete ]; then
            if ! screen -list | grep -q $PROCESS_PREFIX-$world_to_delete; then
                while [ -z $confirm ]; do
                    read -p "Are you sure? " -e confirm
                done
                if [ $confirm = yes ]; then
                    rm -r $world_to_delete
                    echo "Deleted world \"$world_to_delete\"."
                    exit 0
                else
                    echo "Deletion of \"$world_to_delete\" cancelled."
                    exit 3
                fi
            else
                echo "Server is currently running."
                echo "Stop the server before deleting it."
                exit 2
            fi
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    update)
        confirm=$2
        install_mods=$3
        while [ -z $confirm ]; do
            read -p "Update minecraft_server.jar? " -e confirm
        done
        if [ $confirm = yes ]; then
            while [ -z $install_mods ]; do
                read -p "Install mods? " -e install_mods
            done
            cd $FILES
            curl -O https://s3.amazonaws.com/Minecraft.Download/versions/1.6.2/minecraft_server.1.6.2.jar
            rm minecraft_server.jar
            mv minecraft_server.1.6.2.jar minecraft_server.jar
            if [ $install_mods = yes ]; then
                mkdir temp
                unzip minecraft_Server.jar -d temp
                cp -R toadd/* temp
                cd temp
                zip -r ../minecraft_server.jar *
                cd ..
                rm -R temp
            fi
            cd $WORLDS
            echo "minecraft_server.jar updated."
            exit 0
        else
            echo "Did not update."
            exit 3
        fi
        ;;
    viewlog)
        world=$2
        all=$3
        while [ -z $world ]; do
            read -p "World name: " -e world
        done
        while [ -z $all ]; do
            all=current
        done
        if [ -d $world ]; then
            cd $world
            if [ $all = all ]; then
                if [ -d logs ]; then
                    cat logs/*
                fi
            fi
            cat server.log
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    clearlog)
        world=$2
        while [ -z $world ]; do
            read -p "World name: " -e world
        done
        if [ -d $world ]; then
            echo "" > $world/server.log
            echo "Server log for world \"$world\" cleared."
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    backuplog)
        world=$2
        while [ -z $world ]; do
            read -p "World name: " -e world
        done
        if [ -d $world ]; then
            cd $world
            if [ -d logs ]; then
                echo "Found log folder."
            else
                echo "No log folder.  Creating."
                mkdir logs
            fi
            cp server.log logs/server-$(date +%y-%m-%d\|%H:%M:%S).log
            echo -n "" > server.log
            echo "Backed up log files for world \"$world\""
            exit 0
        else
            echo "No world match found."
            exit 1
        fi
        ;;
    help)
            echo "\
    Commands:
start                           Starts a server.  Connects if already running.
stop                            Stops a server.
restart                         Restarts a server.
connect                         Connects to an already running server's console.
edit                            Edits a server's properties.
relink                          Recreates symbolic links for files.
folder                          Opens a server's folder.
worlds                          Opens the folder containing all the servers.
servermain                      Opens the main server folder.
list                            Lists all servers.
new                             Makes a new server.
delete                          Deletes a server.
update                          Updates server jarfile to most recent version.
viewlog                         Prints a server's log to the console.
clearlog                        Clears a server's log.
backuplog                       Backs up a server's log."
        exit 0
        ;;
    *)
            echo "Invalid Command."
            echo "Use \"mcserver help\" for a list of commands."
        exit 0
esac

exit 4