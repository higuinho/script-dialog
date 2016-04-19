#!/bin/bash
#multi-ui scripting

if [ "$XDG_CURRENT_DESKTOP" = "" ]; then
  desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
else
  desktop=$XDG_CURRENT_DESKTOP
fi

desktop=${desktop,,}  # convert to lower case

[ -t 0 ] && terminal=1

if xdpyinfo | grep X.Org > /dev/null; then
	if [ $terminal ] ; then
		GUI=false
	else
		GUI=true
	fi
else
	GUI=false
fi

if which kdialog > /dev/null; then
	hasKDialog=true
else
	hasKDialog=false
fi

if which zenity > /dev/null; then
	hasZenity=true
else
	hasZenity=false
fi

if which dialog > /dev/null; then
	hasDialog=true
else
	hasDialog=false
fi

if which whiptail > /dev/null; then
    hasWhiptail=true
else
    hasWhiptail=false
fi

if [ "$desktop" == "kde" ] || [ "$desktop" == "razor" ]  || [ "$desktop" == "lxqt" ]  || [ "$desktop" == "maui" ] ; then
	if  [ $hasKDialog == true ] && [ $GUI == true ] ; then
		INTERFACE="kdialog"
		GUI=true
	elif [ $hasZenity == true ] && [ $GUI == true ] ; then
		INTERFACE="zenity"
		GUI=true
    elif  [ $hasDialog == true ] ; then
        INTERFACE="dialog"
        GUI=false
	elif  [ $hasWhiptail == true ] ; then
		INTERFACE="whiptail"
		GUI=false
	fi
elif [ "$desktop" == "unity" ] || [ "$desktop" == "gnome" ]  || [ "$desktop" == "xfce" ]  || [ -n $INTERFACE ]; then
    if [ $hasZenity == true ] && [ $GUI == true ] ; then
        INTERFACE="zenity"
        GUI=true
    elif  [ $hasDialog == true ] ; then
        INTERFACE="dialog"
        GUI=false
    elif  [ $hasWhiptail == true ] ; then
        INTERFACE="whiptail"
        GUI=false
    fi
else
    if  [ $hasDialog == true ] ; then
        INTERFACE="dialog"
        GUI=false
    elif  [ $hasWhiptail == true ] ; then
        INTERFACE="whiptail"
        GUI=false
    fi
fi

# which sudo to use
if [ "`which kdesudo`" > /dev/null ] && [ "$INTERFACE" == "kdialog" ]; then
    SUDO="kdesudo"
elif [ `which gksudo` > /dev/null ] && [ "$INTERFACE" == "zenity" ]; then
    SUDO="gksudo"
elif [ `which gksu` > /dev/null ] && [ "$INTERFACE" == "zenity" ]; then
    SUDO="gksu"
elif [ `which sudo` > /dev/null ]; then
    SUDO="sudo"
fi

APP_NAME="Script"
ACTIVITYEAR=""
WINDOW_ICON=""
GUI_TITLE="$APP_NAME"

function superuser() {
    ARGS=""
    while (( $# )); do
        ARGS="$ARGS $1"
        shift
    done
	$SUDO $ARGS
}

function updateGUITitle() {
    if [ -n "$ACTIVITY" ]; then
        GUI_TITLE="$ACTIVITY - $APP_NAME"
    else
        GUI_TITLE="$APP_NAME"
    fi
}

MIN_HEIGHT=10
MIN_WIDTH=40
MAX_HEIGHT=$MIN_HEIGHT
MAX_WIDTH=$MIN_WIDTH

function updateDialogMaxSize() {
	if [ $GUI == true ] ; then
        MAX_HEIGHT=$( xdpyinfo | grep "dimensions" | awk '{ print $2 }' | cut -d'x' -f2)
        MAX_WIDTH=$( xdpyinfo | grep "dimensions" | awk '{ print $2 }' | cut -d'x' -f1)
	else
        MAX_HEIGHT=$(tput lines)
        MAX_WIDTH=$(tput cols)
    fi

    # Never really fill the whole screen space
    MAX_HEIGHT=$(( $MAX_HEIGHT / 2 ))
    MAX_WIDTH=$(( $MAX_WIDTH * 3 / 4 ))
}

RECMD_HEIGHT=10
RECMD_WIDTH=40
RECMD_SCROLL=false
TEST_STRING=""

function calculateTextDialogSize() {
	updateDialogMaxSize
	CHARS=${#TEST_STRING}
	RECMD_SCROLL=false
	ORIG_RECMD_HEIGHT=$(($CHARS  / $MIN_WIDTH))
	ORIG_RECMD_WIDTH=$(($CHARS / $MIN_HEIGHT))
	RECMD_HEIGHT=$(($CHARS  / $MIN_WIDTH))
	RECMD_WIDTH=$(($CHARS / $MIN_HEIGHT))

	if [ "$RECMD_HEIGHT" -gt "$MAX_HEIGHT" ] ; then
		RECMD_HEIGHT=$MAX_HEIGHT
		RECMD_SCROLL=true
	fi
	if [ "$RECMD_WIDTH" -gt "$MAX_WIDTH" ]; then
		RECMD_WIDTH=$MAX_WIDTH
		#RECMD_SCROLL=true
	fi

	if [ "$RECMD_HEIGHT" -lt "$MIN_HEIGHT" ] ; then
		RECMD_HEIGHT=$MIN_HEIGHT
		RECMD_SCROLL=false
	fi
	if [ "$RECMD_WIDTH" -lt "$MIN_WIDTH" ]; then
		RECMD_WIDTH=$MIN_WIDTH
		RECMD_SCROLL=false
	fi

	TEST_STRING="" #blank out for memory's sake
}

function relaunchIfNotVisible() {
	parentScript=$(basename `readlink -f ${BASH_SOURCE[0]}`)

	if [ $GUI == false ] && [ $terminal == false ]; then
		x-terminal-emulator --hold -e "./$parentScript"
		exit $?;
	fi
}

function messagebox() {
    updateGUITitle
	TEST_STRING="$1"
	calculateTextDialogSize

	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --clear $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" $RECMD_HEIGHT $RECMD_WIDTH
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" $RECMD_HEIGHT $RECMD_WIDTH
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --info --text "$1"
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --msgbox "$1"
	else
		echo "$1"
	fi
}

function yesno() {
    updateGUITitle
	TEST_STRING="$1"
	calculateTextDialogSize

	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" $RECMD_HEIGHT $RECMD_WIDTH
		answer=$?
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" $RECMD_HEIGHT $RECMD_WIDTH
		answer=$?
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --question --text "$1"
		answer=$?
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --yesno "$1"
		answer=$?
	else
		echo "$1 (y/n)" 3>&1 1>&2 2>&3
		read answer
		if [ "$answer" == "y" ]; then
			answer=0
		else
			answer=1
		fi
	fi

	return $answer
}

function inputbox() {
    updateGUITitle
	TEST_STRING="$1"
	calculateTextDialogSize

	if [ "$INTERFACE" == "whiptail" ]; then
        INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" $RECMD_HEIGHT $RECMD_WIDTH  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "dialog" ]; then
        INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" $RECMD_HEIGHT $RECMD_WIDTH  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "zenity" ]; then
		INPUT="`zenity --entry --title="$GUI_TITLE" --window-icon "$WINDOW_ICON" --text="$1" --entry-text "$2"`"
	elif [ "$INTERFACE" == "kdialog" ]; then
		INPUT="`kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --inputbox "$1" "$2"`"
	else
		read -p "$1: " INPUT
	fi

	echo "$INPUT"
}

function userandpassword() {
    updateGUITitle
	TEST_STRING="$1"
	calculateTextDialogSize

	if [ "$INTERFACE" == "whiptail" ]; then
        USERNAME=$(inputbox "$1")
        PASSWORD=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$2" $RECMD_HEIGHT $RECMD_WIDTH 3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "dialog" ]; then
#         USERNAME=$(inputbox "$1")
# 		PASSWORD=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$2" $RECMD_HEIGHT $RECMD_WIDTH 3>&1 1>&2 2>&3)
		ENTRY=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --insecure --mixedform "Login:" $RECMD_HEIGHT $RECMD_WIDTH 0 "Username: " 1 1 "" 1 11 22 0 0 "Password :" 2 1 "" 2 11 22 0 1   3>&1 1>&2 2>&3)
		ENTRY=${ENTRY//$'\n'/$'|'}
        USERNAME=`echo $ENTRY | cut -d'|' -f1`
        PASSWORD=`echo $ENTRY | cut -d'|' -f2`
	elif [ "$INTERFACE" == "zenity" ]; then
        ENTRY=`zenity --title="$GUI_TITLE" --window-icon "$WINDOW_ICON" --password --username`
        USERNAME=`echo $ENTRY | cut -d'|' -f1`
        PASSWORD=`echo $ENTRY | cut -d'|' -f2`
	elif [ "$INTERFACE" == "kdialog" ]; then
        USERNAME=$(inputbox "$1")
		password=`kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --password "$2"`
	else
		read -p "username: " USERNAME
        read  -sp "password: " PASSWORD
	fi
	echo "$USERNAME|$PASSWORD"
}

function displayFile() {
    updateGUITitle
	TEST_STRING="`cat $1`"
	calculateTextDialogSize

    if [ "$INTERFACE" == "whiptail" ]; then
        whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" $RECMD_HEIGHT $RECMD_WIDTH
    elif [ "$INTERFACE" == "dialog" ]; then
        dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" $RECMD_HEIGHT $RECMD_WIDTH
    elif [ "$INTERFACE" == "zenity" ]; then
        zenity --title="$GUI_TITLE" --window-icon "$WINDOW_ICON" --text-info --filename="$1"
    elif [ "$INTERFACE" == "kdialog" ]; then
        kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --textbox "$1" 512 256
    else
        less $1
    fi
}

function checklist() {
    updateGUITitle
    TEXT=$1
    NUM_OPTIONS=$2
    shift
    shift

	if [ "$INTERFACE" == "whiptail" ]; then
		CHOSEN=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --checklist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH $NUM_OPTIONS "$@"  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "dialog" ]; then
		CHOSEN=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --quoted --checklist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH $NUM_OPTIONS "$@"  3>&1 1>&2 2>&3)
		#TODO quote the resulting items
	elif [ "$INTERFACE" == "zenity" ]; then
        OPTIONS=()
        while test ${#} -gt 0;  do
            if [ "$3" == "ON" ]; then
                OPTIONS+=("TRUE")
            else
                OPTIONS+=("FALSE")
            fi
            OPTIONS+=("$1")
            OPTIONS+=("$2")
            shift
            shift
            shift
        done
		CHOSEN_LIST=$(zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --list --text "$TEXT" --checklist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")

        ORIG_IFS="$IFS"
        IFS="|"
        CHOSEN_LIST=( $CHOSEN_LIST )
        IFS="$ORIG_IFS"

        CHOSEN=""
        for i in "${CHOSEN_LIST[@]}"; do
            CHOSEN+="\"$i\" "
        done

	elif [ "$INTERFACE" == "kdialog" ]; then
        CHOSEN=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --checklist "$TEXT" "$@")
	else
		echo "$ACTIVITY\n $TEXT:" 3>&1 1>&2 2>&3
		CHOSEN=""
		while test ${#} -gt 0; do
            $(yesno "$2 (default: $3)?")
            if [ $? -eq 0 ]; then
                CHOSEN+="\"$1\" "
            fi
            shift
            shift
            shift
        done
	fi

    echo $CHOSEN
}

function radiolist() {
    updateGUITitle
    TEXT=$1
    NUM_OPTIONS=$2
    shift
    shift

	if [ "$INTERFACE" == "whiptail" ]; then
        CHOSEN=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH $NUM_OPTIONS "$@"  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "dialog" ]; then
		CHOSEN=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --quoted --radiolist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH $NUM_OPTIONS "$@"  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "zenity" ]; then
		OPTIONS=()
        while test ${#} -gt 0;  do
            if [ "$3" == "ON" ]; then
                OPTIONS+=("TRUE")
            else
                OPTIONS+=("FALSE")
            fi
            OPTIONS+=("$1")
            OPTIONS+=("$2")
            shift
            shift
            shift
        done
        CHOSEN=$(zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --list --text "$TEXT" --radiolist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")
	elif [ "$INTERFACE" == "kdialog" ]; then
        CHOSEN=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --radiolist "$TEXT" "$@")
	else
        echo "$ACTIVITY: " 3>&1 1>&2 2>&3
        OPTIONS=""
        while test ${#} -gt 0;  do
            OPTIONS+="$1 ($2)\n"
            shift
            shift
            shift
        done
        read -p "$(echo -e "$OPTIONS$TEXT: ")" CHOSEN
    fi

    echo $CHOSEN
}

#TODO have the progressbar updating actually mean something.
function progressbar() {
    updateGUITitle
    ACTIVITY+=" (Fake Progress, Intelligent Progressbars Not Implemented)"
    if [ "$INTERFACE" == "whiptail" ]; then
        {
            for ((i = 0 ; i <= 100 ; i+=5)); do
                sleep 0.1
                echo $i
            done
        } | whiptail --gauge "$ACTIVITY" $RECMD_HEIGHT $RECMD_WIDTH 0

    elif [ "$INTERFACE" == "dialog" ]; then
        {
            for ((i = 0 ; i <= 100 ; i+=5)); do
                sleep 0.1
                echo $i
            done
        } | dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "" $RECMD_HEIGHT $RECMD_WIDTH 0
    elif [ "$INTERFACE" == "zenity" ]; then
        {
            for ((i = 0 ; i <= 100 ; i+=5)); do
                sleep 0.1
                echo $i
            done
        } | zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --progress --text="$ACTIVITY" --auto-close --auto-kill --percentage 0

    elif [ "$INTERFACE" == "kdialog" ]; then
        dbusRef=`kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --progressbar "$ACTIVITY" 100`

        for ((i = 0 ; i <= 100 ; i+=5)); do
            sleep 0.1
            qdbus $dbusRef Set "" value $i
        done
        qdbus $dbusRef close
    else
        for ((i = 0 ; i <= 100 ; i+=5)); do
            sleep 0.1
            echo -ne "\r$ACTIVITY $i%"
        done
        echo ""
    fi
}

function filepicker() {
    updateGUITitle
    if [ "$INTERFACE" == "whiptail" ]; then
        #TODO support driving down into folders
        SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --menu YourTitle $RECMD_HEIGHT $RECMD_WIDTH 10 `ls $1/` 3>&1 1>&2 2>&3)
        FILE=$1/$SELECTED
    elif [ "$INTERFACE" == "dialog" ]; then
        FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --fselect $1/ 14 48)
    elif [ "$INTERFACE" == "zenity" ]; then
        FILE=$(zenity --title "$GUI_TITLE" --window-icon "$WINDOW_ICON" --file-selection --filename $1/ )
    elif [ "$INTERFACE" == "kdialog" ]; then
        if [ "$2" == "save" ]; then
            FILE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --getopenfilename $1/ )
        else #elif [ "$2" == "open" ]; then
            FILE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --getsavefilename $1/ )
        fi
    else
        read -e -p "You need to $2 a file in $1/. Hit enter to browse this folder" IGNORE
        less "$( ls $1/ )"
        read -e -p "Enter name of file to $2 in $1/: " SELECTED
        FILE=$1/$SELECTED
    fi

    echo $FILE
}

function datepicker() {
    updateGUITitle
    DAY="0"
    MONTH="0"
    YEAR="0"

    if [ "$INTERFACE" == "whiptail" ]; then
        INPUT_DATE=$(inputbox "Input Date (DD/MM/YYYY)" " ")
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "dialog" ]; then
        INPUT_DATE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --calendar "Choose Date" 0 40)
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "zenity" ]; then
        INPUT_DATE=$(zenity --title="$GUI_TITLE" --window-icon "$WINDOW_ICON" --calendar "Select Date")
        MONTH=`echo $INPUT_DATE | cut -d'/' -f1`
        DAY=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "kdialog" ]; then
        INPUT_DATE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --calendar "Select Date")
        TEXT_MONTH=`echo $INPUT_DATE | cut -d' ' -f2`
        if [ "$TEXT_MONTH" == "Jan" ]; then
            MONTH=1
        elif [ "$TEXT_MONTH" == "Feb" ]; then
            MONTH=2
        elif [ "$TEXT_MONTH" == "Mar" ]; then
            MONTH=3
        elif [ "$TEXT_MONTH" == "Apr" ]; then
            MONTH=4
        elif [ "$TEXT_MONTH" == "May" ]; then
            MONTH=5
        elif [ "$TEXT_MONTH" == "Jun" ]; then
            MONTH=6
        elif [ "$TEXT_MONTH" == "Jul" ]; then
            MONTH=7
        elif [ "$TEXT_MONTH" == "Aug" ]; then
            MONTH=8
        elif [ "$TEXT_MONTH" == "Sep" ]; then
            MONTH=9
        elif [ "$TEXT_MONTH" == "Oct" ]; then
            MONTH=10
        elif [ "$TEXT_MONTH" == "Nov" ]; then
            MONTH=11
        else #elif [ "$TEXT_MONTH" == "Dec" ]; then
            MONTH=12
        fi

        DAY=`echo $INPUT_DATE | cut -d' ' -f3`
        YEAR=`echo $INPUT_DATE | cut -d' ' -f4`
    else
        read -p "Date (DD/MM/YYYY): " INPUT_DATE
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    fi

    echo "$DAY/$MONTH/$YEAR"
}

