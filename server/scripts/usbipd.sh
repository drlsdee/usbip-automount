#!/bin/sh

# Set path 
PATH=$PATH

# This variable lists all available devices
# and filters output by the keyword "busid".
# Then, with the "cut", only the bus IDs are cut
# (space as a separator, 4th field is selected).
#
# BUSIDS=$(usbip list -l | grep busid | cut -d ' ' -f 4)

# Another variant with "usbip list" command with -p - parsable list format
# Here we filter output by vendor's ID (0529 is Aladdin Knowledge Systems),
# define separators "=" and "#" and select column with bus IDs
#
VENDOR=$"0529"
#
BUSIDS=$(usbip list -p -l | grep $VENDOR | awk -F '[=#]' '{print $2}')

# Filter by vendor's name:
# VENDOR=$"Aladdin"
#
# Select string with the specified vendor's name and string before.
# BUSIDS=$(echo "$(usbip list -l | grep -B 1 $VENDOR | grep busid)" | cut -d ' ' -f 4)

# This variable shows the port used when the device is connected locally.
# We need to connect the device and disconnect it. Due to a bug in the server
# software, when you try to mount on the client, an error of the following
# type occurs:
# "usbip err: usbip_windows.c: 829 (attach_device) cannot find device".
# Here we look for the string by mask, then we cut off the word "Port"
# at the beginning, (with a space!).
# Then we reduce the output, leaving only the port number.

PORT=$(usbip port | grep 'Port in Use' | cut -d ' ' -f 2 | tr -dc '0-9')

case $1 in
        "start")
                # Service start
                usbipd -D

                # For each of discovered devices:
                for ID in $BUSIDS
                        do
                                usbip bind -b $ID # bind device
                                usbip attach --remote=localhost --busid=$ID # attach locally
                                sleep 2 # wait a bit
                                usbip detach --port=$PORT # and detach
                        done # devices are ready to mount remotely
        ;;
        "stop")
                for ID in $BUSIDS
                        do
                                usbip unbind -b $ID # unbind device
                        done # devices are unbinded
				pkill usbip*
		;;
esac
