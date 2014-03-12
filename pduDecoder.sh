#!/bin/bash -

###################################################################
#			pduDecoder.sh
#==================================================================
#
#	Shell scrit to decode PDU in SMS (Short Message Service)
#
#==================================================================
#
# 	CREATED IN:
#	===========
#
#	Jun 27, 2012
#	Arthur Alves < arthuralves.p@gmail.com >
#	(c) Alves Development.
#	Alagoas, Brazil.
#
#------------------------------------------------
#
#	LAST MODIFIED:
#	=============
#
#	Jun 30, 2012
#	Arthur Alves < arthuralves.p@gmail.com >
#	(c) Alves Development.
#	Alagoas, Brazil.
#
###################################################################

# Few utility functions
# _ord gets ASCII code of a char
function _ord() {
	local char=$1
    printf '%d' "'$char"
}

# _chr gets the character corresponding to the ASCII code (integer)
function _chr() {
      printf \\$(printf '%03o' $1);
}

# Now the migrated functions
# function to convert a bit string into a intege
function binToInt() {
    echo "ibase=2; $1"|bc
}

# function to convert a integer into a bit String
function intToBin() {
    local bin=$(echo "obase=2; $1"|bc)
    printf "%0$2d" $bin
}

# function to convert a Hexnumber into a 10base number
function HexToNum() {
    echo "ibase=16; $1"|bc
}

# helper function for HexToNum
function MakeNum() {
    char=$1;
	if echo $char | grep -iq "[0-9A-F]"
	then
	    echo "ibase=16;$char"|bc
	else
		echo 16
	fi
}

# function to convert integer to Hex
function intToHex() {
    printf "%X" $1
}

function getSevenBit() {
    sev=$(printf '%d' "'$1")
    if [ $sev -lt 128 ]; then
        echo $sev;
    else
        return 0;
    fi
}

function getEightBit() {
    echo $1
}

function get16Bit() {
    echo $1
}

function phoneNumberMap() {
    if echo "$1" | grep -q '[0-9*#A-Ca-c]'; then
        echo "$1" | tr '0-9*#A-Ca-c' '0-9ABCDECDE'
    else
        echo F
    fi
}

function phoneNumberUnMap() {
    if [ $1 -le 9 ]; then
        echo $1;
    elif [ $1 -le 14 ]; then
        printf "%X" $1 | tr "A-E" "*#A-C";
    else
        echo F;
    fi
}

# function to convert semioctets to a string
function semiOctetToString() {
    local inp=$1;
    local out="";
    local i=0;
    while [ $i -lt ${#inp} ]; do
        temp=${inp:$i:2};
#        echo "temp=$temp" > /dev/stderr
        out=$out$(phoneNumberMap ${temp:1:1})$(phoneNumberMap ${temp:0:1});
        i=$(expr $i + 2);
    done
    echo $out;
}

# Main function to translate the input to a "human readable" string
function getUserMessage() {
    local input=$1;
    local truelength=$2;
	local byteString="";
	local s=1;
	local count=0;
	local matchcount=0;
	local smsMessage="";

	local i;
	for (( i=0; i < ${#input}; i+=2 )); do
		local hex=${input:$i:2};
		byteString="$byteString"$(intToBin $(HexToNum $hex) 8)
#		if [ $(expr $i % 14) == 0 -a $i -ne 0 ]; then
#			calculation1="$calculation1\t+++++++";
#		fi
#		calculation1="$calculation1\t$hex"
	done
#	calculation1="$calculation1\t+++++++";
#	echo "byteString=$byteString" > /dev/stderr

	for (( i=0; i < ${#byteString}; i+=8 )); do
        octetArray[$count]=${byteString:$i:8};
		local smod8=$(expr $s % 8);
        restArray[$count]=${octetArray[$count]:0:$smod8};
		local slen=$(expr 8 - $smod8);
        septetsArray[$count]=${octetArray[$count]:$smod8:$slen};
#		if [ $(expr $i % 56) -eq 0 -a $i -ne 0 ]; then
#            calculation2="$calculation2<td align=center width=75>&nbsp;</td>";
#        fi
#        calculation2="calculation2<td align=center width=75><span style='background-color: #FFFF00'>${restArray[$count]}</span>${septetsArray[$count]}</td>";

        s=$(expr $s + 1);
        count=$(expr $count + 1);
        if [ $s -eq 8 ]; then
            s=1;
		fi
	done
#	echo "octetArray=${octetArray[@]}" > /dev/stderr
#	echo "restArray=${restArray[@]}" > /dev/stderr
#	echo "septetsArray=${septetsArray[@]}" > /dev/stderr

    # put the right parts of the array's together to make the sectets
    for (( i=0; i < ${#restArray[*]}; i++ )); do

        if [ $(expr $i % 7) -eq 0 ]; then
            if [ $i -ne 0 ]; then
				local ri=$(expr $i - 1);
                smsMessage="$smsMessage"$(_chr $(binToInt ${restArray[$ri]}));
#				echo "131:smsMessage=$smsMessage" > /dev/stderr
#                calculation3 = calculation3 + "<td align=center width=75><span style='background-color: #FFFF00'>&nbsp;" + restArray[i-1] + "</span>&nbsp;</td>";
#                calculation4 = calculation4 + "<td align=center width=75>&nbsp;" + sevenbitdefault[binToInt(restArray[i-1])] + "&nbsp;</td>";
                matchcount=$(expr $matchcount + 1); # AJA
            fi
            smsMessage="$smsMessage"$(_chr $(binToInt ${septetsArray[$i]}));
#			echo "137:smsMessage=$smsMessage" > /dev/stderr
#            calculation3 = calculation3 + "<td align=center width=75>&nbsp;" +septetsArray[i] + "&nbsp;</td>";
#            calculation4 = calculation4 + "<td align=center width=75>&nbsp;" + sevenbitdefault[binToInt(septetsArray[i])] + "&nbsp;</td>";
            matchcount=$(expr $matchcount + 1); # AJA
        else
			local ri=$(expr $i - 1);
            smsMessage="$smsMessage"$(_chr $(binToInt ${septetsArray[$i]}${restArray[$ri]}));
#				echo "144:smsMessage=$smsMessage" > /dev/stderr
#            calculation3 = calculation3 + "<td align=center width=75>&nbsp;" +septetsArray[i]+ "<span style='background-color: #FFFF00'>" +restArray[i-1] + "&nbsp;</span>" + "</td>"
#            calculation4 = calculation4 + "<td align=center width=75>&nbsp;" + sevenbitdefault[binToInt(septetsArray[i]+restArray[i-1])] + "&nbsp;</td>";
            matchcount=$(expr $matchcount + 1); # AJA
        fi

   done

   if [ $matchcount -ne $truelength ]; then # Don't forget trailing characters!! AJA
		local ri=$(expr $i - 1);
        smsMessage="$smsMessage"$(_chr $(binToInt ${restArray[$ri]})); #smsMessage + sevenbitdefault[binToInt(restArray[i-1])];
#		echo "155:smsMessage=$smsMessage" > /dev/stderr
#        calculation3 = calculation3 + "<td align=center width=75><span style='background-color: #FFFF00'>&nbsp;" + restArray[i-1] + "</span>&nbsp;</td>";
#        calculation4 = calculation4 + "<td align=center width=75>&nbsp;" + sevenbitdefault[binToInt(restArray[i-1])] + "&nbsp;</td>";
    else # Blank Filler
#        calculation3 = calculation3 + "<td align=center width=75>+++++++</td>";
#        calculation4 = calculation4 + "<td align=center width=75>&nbsp;</td>";
		echo > /dev/null
    fi

    #Put all the calculation info together
#    calculation =  "Conversion of 8-bit octets to 7-bit default alphabet<br><br>"+calculation1 + "</tr>" + calculation2 + "</tr></table>" + calculation3 + "</tr>"+ calculation4 + "</tr></table>";

    echo $smsMessage;
# ToDo: to code
}

function getUserMessage16() {
    local input=$1
    local truelength=$2
    calculation="Not implemented"
    local out="";
    local i=0;
    while [ $i -lt ${#inp} ]; do
        hex1=${inp:$i:2};
        local i2=$(expr $i + 2);
        hex2=${inp:$i2:2};
        code=$(expr $(HexToNum $hex1) \* 256 + $(HexToNum $hex2))
        out=$out$(_chr $code)
        i=$(expr $i + 4);
    done
    echo $out
}

function getUserMessage8() {
    local input=$1;
    local truelength=$2;
    calculation="Not implemented";
    local out="";
    local i=0;
    while [ $i -lt ${#inp} ]; do
        hex=${inp:$i:2};
#        echo "hex=$hex" > /dev/stderr
        out=$out$(_chr $(HexToNum $hex));
        i=$(expr $i + 2);
    done
    echo $out;
}

function showCalculation() {
    if [ ${#calcualation} -gt 0 ]; then
        echo $calcualation > /dev/stderr;
    fi
}

function printDefaultAlphabet() {
    local out="";
    out="\t#\tcharacter\tASCII Code\tbits";
	local i=0;
    while [ $i -lt 128 ]; do
		printf "\t%d\t%s\t%s\t%s" $i $(_chr $i) $i $(intToBin $i);
		i=$(expr $i + 1)
	done
}

function show() {
	local title=$1;
	local text=$2;
	echo $title:;
	echo "***********************";
	echo $text;
	echo "***********************";
}

function change() {
	local what=$1;
# ToDo: to code
}

function DCS_Bits() {
	local tp_DCS=$1;
	local AlphabetSize=7; # Set Default
	local pomDCS=$(HexToNum $tp_DCS);
	local pomDCSn192=$(expr $pomDCS / 64);
	# pomDCS & 192
	if [ $pomDCSn192 -eq 0 ]; then
		if [ $(expr $pomDCS / 32) -ne 0 ]; then
			echo > /dev/null; # tp_DCS_desc="Compressed Text\n";
		else
			echo > /dev/null; # tp_DCS_desc="Uncompressed Text\n";
		fi
		local pomDCSn12=$(echo "obase=2;$pomDCS/4%4"|bc);
		if [ $pomDCSn12 -eq 1 ]; then
			AlphabetSize=8;
		elif [ $pomDCSn12 -eq 11 ]; then
			AlphabetSize=16;
		fi
		echo > /dev/null
	elif [ $pomDCSn192 -eq 3 ]; then
		echo > /dev/null
		local pomDCSn48=$(echo "obase=2;$pomDCS/16%4"|bc);
		if [ "10" == "$pomDCSn48" ]; then
			AlphabetSize=16;
		elif [ "11" == "$pomDCSn48" ]; then
			local pomDCSn4=$(expr "$pomDCS / 4 % 2");
			if [ $pomDCSn4 -ne 0 ]; then
				echo > /dev/null;
			else
				AlphabetSize=8;
			fi
		fi
	fi
	echo $AlphabetSize;
}

function tpDCSMeaning() {
	local tp_DCS=$1;
	local tp_DCS_desc=$tp_DCS;
	local pomDCS=$(HexToNum $tp_DCS);
	local pomDCSn192=$(expr $pomDCS / 64);
	case $pomDCSn192 in
	0)	#echo Case pomDCSn192 is 0 > /dev/stderr;
		if [ $(expr $pomDCS / 32 % 2) -ne 0 ]; then
			tp_DCS_desc="Compressed Text\n";
		else
			tp_DCS_desc="Uncompressed Text\n";
		fi
#		echo "tp_DCS_desc=$tp_DCS_desc" > /dev/stderr;
		if [ $(expr $pomDCS / 16 % 2) -ne 0 ]; then
			tp_DCS_desc="${tp_DCS_desc}No class\n";
		else
			tp_DCS_desc="${tp_DCS_desc}class:";
            case $(expr $pomDCS % 4) in
			0)	tp_DCS_desc="${tp_DCS_desc}0\n" ;;
			1)	tp_DCS_desc="${tp_DCS_desc}1\n" ;;
			2)	tp_DCS_desc="${tp_DCS_desc}2\n" ;;
			3)	tp_DCS_desc="${tp_DCS_desc}3\n" ;;
			esac
		fi
#		echo "tp_DCS_desc after classification=$tp_DCS_desc" > /dev/stderr;
		tp_DCS_desc="${tp_DCS_desc}Alphabet:";
#		echo "tp_DCS_desc alphabet ready=$tp_DCS_desc" > /dev/stderr;
		case $(expr $pomDCS / 4 % 4) in
		0)	tp_DCS_desc="${tp_DCS_desc}Default\n" ;;
		1)	tp_DCS_desc="${tp_DCS_desc}8bit\n" ;;
		2)	tp_DCS_desc="${tp_DCS_desc}UCS2(16)bit\n" ;;
		3)	tp_DCS_desc="${tp_DCS_desc}Reserved\n" ;;
		esac
#		echo "tp_DCS_desc after pomDCS/4%4=$tp_DCS_desc" > /dev/stderr;
		;;
	1)	tp_DCS_desc="Reserved coding group\n"	;;
	2)	tp_DCS_desc="Reserved coding group\n"	;;
	3)	case $(expr $pomDCS / 16 % 4) in
		0)	tp_DCS_desc="Message waiting group\n";
			tp_DCS_desc="${tp_DCS_desc}Discard\n";
			;;
		1)	tp_DCS_desc="Message waiting group\n";
			tp_DCS_desc="${tp_DCS_desc}Store Message. Default Alphabet\n";
			;;
		2)
			tp_DCS_desc="Message waiting group\n";
			tp_DCS_desc="${tp_DCS_desc}Store Message. UCS2 Alphabet\n";
			;;
		3)
			tp_DCS_desc="Data coding message class\n";
			if [ $(expr $pomDCS / 4 % 2) ]; then
				tp_DCS_desc="${tp_DCS_desc}Default Alphabet\n";
			else
				tp_DCS_desc="${tp_DCS_desc}8 bit Alphabet\n";
			fi
			;;
		esac
		;;
	esac
	echo $tp_DCS_desc;
}

# now the main decoder function
function getPDUMetaInfo() {
    local inp=$1;
    local PDUString=$inp;
    local start=0;
    local out="";
	local sender_number;
	local messageLength;
	local ValidityPeriod;
	local tp_DCS;
	local tp_PID;
	local tp_DCS_desc;
	local userData;
	local i;

	# Silently Strip leading AT command
    if [ "${PDUString:0:2}" == "AT" ]; then
		for (( i=0; i<${#PDUString}; i++ )); do
			if [ $(_ord ${PDUString:$i:1}) -eq 10 ]; then
				local iplus=$(expr $i + 1);
				PDUString=${PDUString:$iplus}
				break;
			fi
		done
    fi

    # Silently strip whitespace
#	echo "PDUString=$PDUString" > /dev/stderr;
    local NewPDU="";
    for (( i=0; i<${#PDUString}; i++ )); do
        if [ $(MakeNum ${PDUString:$i:1}) -ne 16 ]; then
            NewPDU="$NewPDU${PDUString:$i:1}";
        fi
    done
	PDUString=$NewPDU;
#	echo "PDUString(NewPDU)=$PDUString" > /dev/stderr;

    local SMSC_lengthInfo=$(HexToNum ${PDUString:0:2});
	local sublen=$(expr $SMSC_lengthInfo \* 2);
    local SMSC_info=${PDUString:2:$sublen};
    local SMSC_TypeOfAddress=${SMSC_info:0:2};
    local SMSC_Number=${SMSC_info:2:$sublen};

#	echo "Initial SMSC_Number=$SMSC_Number" > /dev/stderr;
    if [ $SMSC_lengthInfo -ne 0 ]
    then
        SMSC_Number=$(semiOctetToString $SMSC_Number);

        # if the length is odd remove the trailing  F
		local substart=$(expr ${#SMSC_Number} - 1);
        if [ "${SMSC_Number:$substart:1}" == "F" -o "${SMSC_Number:$substart:1}" == "f" ]
        then
            SMSC_Number=${SMSC_Number:0:$substart};
        fi
#		echo "SMSC_Number first $substart=$SMSC_Number" > /dev/stderr;

        if [ $SMSC_TypeOfAddress -eq 91 ]
        then
            SMSC_Number="+$SMSC_Number";
        fi
    fi
#	echo "SMSC_Number=$SMSC_Number" > /dev/stderr;

    local start_SMSDeleivery=$(expr $SMSC_lengthInfo \* 2 + 2);

    start=$start_SMSDeleivery;
    local firstOctet_SMSDeliver=${PDUString:$start:2};
    start=$(expr $start + 2);
    if [ $(expr $(HexToNum $firstOctet_SMSDeliver) / 32 % 2) -eq 1 ]
    then
        out="${out}Receipt requested\n";
    fi
    local DataHeader=0;
    if [ $(expr $(HexToNum $firstOctet_SMSDeliver) / 64 % 2) -eq 1 ]
    then
        DataHeader=1;
        out="${out}Data Header\n";
    fi

#  bit1    bit0    Message type
#  0   0   SMS DELIVER (in the direction SC to MS)
#  0   0   SMS DELIVER REPORT (in the direction MS to SC)
#  1   0   SMS STATUS REPORT (in the direction SC to MS)
#  1   0   SMS COMMAND (in the direction MS to SC)
#  0   1   SMS SUBMIT (in the direction MS to SC)
#  0   1   SMS SUBMIT REPORT (in the direction SC to MS)
#  1   1   Reserved

    if [ $(expr $(HexToNum $firstOctet_SMSDeliver) % 4) -eq 1 -o $(expr $(HexToNum $firstOctet_SMSDeliver) % 4) -eq 3 ] # Transmit Message
    then
#		echo '$(HexToNum $firstOctet_SMSDeliver) % 4 -eq 1 -o $(HexToNum $firstOctet_SMSDeliver) % 4 -eq 3 ]' > /dev/stderr;
        if [ $(HexToNum $firstOctet_SMSDeliver) % 4 -eq 3 ]
        then
            out="Unknown Message\nTreat as Deliver\n";
        fi
        local MessageReference=$(HexToNum ${PDUString:$start:2});
        start=$(expr $start + 2);

        # length in decimals
        local sender_addressLength=$(HexToNum ${PDUString:$start:2});
        if [ $sender_addressLength % 2 -ne 0 ]
        then
            sender_addressLength=$(expr $sender_addressLength + 1);
        fi
        start=$(expr $start + 2);

        local sender_typeOfAddress=${PDUString:$start:2};
        start=$(expr $start + 2);

        sender_number=$(semiOctetToString ${PDUString:$start:$sender_addressLength});

		local sublen=$(expr ${#sender_number} - 1);
        if [ "${sender_number:$sublen:1}" == "F" -o "${sender_number:$sublen:1}" == "f" ]
        then
            sender_number=${sender_number:0:$sublen};
        fi
        if [ $sender_typeOfAddress -eq 91 ]
        then
            sender_number="+$sender_number";
        fi
		start=$(expr $start + $sender_addressLength);

        tp_PID=${PDUString:$start:2};
		start=$(expr $start + 2)

		tp_DCS=${PDUString:$start:2};
		tp_DCS_desc=$(tpDCSMeaning $tp_DCS);
        start=2;

        case $(expr $(HexToNum $firstOctet_SMSDeliver) / 16 % 4) in
            0) # Not Present
                ValidityPeriod="Not Present";
                ;;
            2) # Relative
                ValidityPeriod="Rel "$(cValid $(HexToNum ${PDUString:$start:2}));
				start=$(expr $start + 2);
                ;;
            1) # Enhanced
                ValidityPeriod="Enhanced - Not Decoded";
                start=$(expr $start + 14);
                ;;
            3) # Absolute
                ValidityPeriod="Absolute - Not Decoded";
				start=$(expr $start + 14);
                ;;
        esac
# Commonish...
        messageLength=$(HexToNum ${PDUString:$start:2});

		start=$(expr $start + 2);

        local bitSize=$(DCS_Bits $tp_DCS);
		local userData="Undefined format";
		local sublen=$(expr ${#PDUString} - $start);
        if [ $bitSize -eq 7 ]
        then
            userData=$(getUserMessage ${PDUString:$start:$sublen} $messageLength);
        elif [ $bitSize -eq 8 ]
        then
            userData=$(getUserMessage8 ${PDUString:$start:$sublen} $messageLength);
        elif [ $bitSize -eq 16 ]
        then
            userData=$(getUserMessage16 ${PDUString:$start:$sublen} $messageLength);
        fi

        userData=${userData:0:$messageLength};
        if [ $bitSize -eq 16 ]
        then
            messageLength=$(expr $messageLength / 2);
        fi

        out="${out}SMSC#$SMSC_Number\nReceipient:$sender_number\n\
Validity:$ValidityPeriod\nTP_PID:$tp_PID\nTP_DCS:$tp_DCS\n\
TP_DCS-popis:$tp_DCS_desc\n$userData\nLength:$messageLength";

	# Receive Message
    elif [ $(expr $(HexToNum $firstOctet_SMSDeliver) % 4) == 0 ] # Receive Message
	then
#		echo 'elif $(HexToNum $firstOctet_SMSDeliver) % 4 == 0' > /dev/stderr;
        # length in decimals
        local sender_addressLength=$(HexToNum ${PDUString:$start:2});

        start=$(expr $start + 2);

        local sender_typeOfAddress=${PDUString:$start:2};
        start=$(expr $start + 2);

		local _sl;
        if [ "$sender_typeOfAddress" == "D0" ]
        then
#			echo '$sender_typeOfAddress == D0' > /dev/stderr;
			_sl=$sender_addressLength;

			if [ $(expr $sender_addressLength % 2) -ne 0 ]
			then
				sender_addressLength=$(expr sender_addressLength + 1);
			fi

#alert(sender_addressLength);
#alert(_sl);

#alert(parseInt(sender_addressLength/2*8/7));
#alert(parseInt(_sl/2*8/7));

#alert(PDUString.substring(start,start+sender_addressLength));
#alert(PDUString.substring(start,start+_sl));

#          sender_number = getUserMessage(PDUString.substring(start,start+sender_addressLength),parseInt(sender_addressLength/2*8/7));
#		   echo Calling getUserMessage for ${PDUString:$start:$sender_addressLength} $(expr $_sl / 2 \* 8 / 7) > /dev/stderr;
           sender_number=$(getUserMessage ${PDUString:$start:$sender_addressLength} $(expr $_sl / 2 \* 8 / 7));
		   echo Got $sender_number
#alert(sender_number);
        else

			if [ $(expr $sender_addressLength % 2) -ne 0 ]
			then
				sender_addressLength=$(expr $sender_addressLength + 1);
			fi

#			echo "semiOctetToString ${PDUString:$start:$sender_addressLength}" > /dev/stderr;
            sender_number=$(semiOctetToString ${PDUString:$start:$sender_addressLength});

			local subpos=$(expr ${#sender_number} - 1);
            if [ "${sender_number:$subpos:1}" == 'F' -o "${sender_number:$subpos:1}" == 'f' ]
            then
                sender_number=${sender_number:0:$subpos}
            fi

            if [ $sender_typeOfAddress -eq 91 ]
            then
                sender_number="+$sender_number";
            fi
        fi
		start=$(expr $start + $sender_addressLength);

		tp_PID=${PDUString:$start:2};
		start=$(expr $start + 2);

		tp_DCS=${PDUString:$start:2};
		tp_DCS_desc=$(tpDCSMeaning $tp_DCS);
		start=$(expr $start + 2);

		local timeStamp=$(semiOctetToString ${PDUString:$start:14});

		# get date
		local year=${timeStamp:0:2};
		local month=${timeStamp:2:2};
		local day=${timeStamp:4:2};
		local hours=${timeStamp:6:2};
		local minutes=${timeStamp:8:2};
		local seconds=${timeStamp:10:2};

		timeStamp="$day/$month/$year $hours:$minutes:$seconds GMT ?";
		 #+" + timezone/4;

		start=$(expr $start + 14)

# Commonish...
		messageLength=$(HexToNum ${PDUString:$start:2});
		start=$(expr $start + 2)

		local bitSize=$(DCS_Bits $tp_DCS);
		local userData="Undefined format";
		local subpos=$(expr ${#PDUString} - $start);
#		echo "Calling getUserMessage$bitSize ${PDUString:$start:$subpos} $messageLength" > /dev/stderr;
		if [ $bitSize -eq 7 ]
		then
			userData=$(getUserMessage ${PDUString:$start:$subpos} $messageLength);
		elif [ $bitSize -eq 8 ]
		then
			userData=$(getUserMessage8 ${PDUString:$start:$subpos} $messageLength);
		elif [ $bitSize -eq 16 ]
		then
			userData=$(getUserMessage16 ${PDUString:$start:$subpos} $messageLength);
		fi

		userData=${userData:0:$messageLength};

		if [ $bitSize -eq 16 ]
		then
			messageLength=$(expr $messageLength / 2);
		fi

		out="SMSC#$SMSC_Number\nSender:$sender_number\nTimeStamp:$timeStamp\n\
TP_PID:$tp_PID\nTP_DCS:$tp_DCS\nTP_DCS-popis:$tp_DCS_desc\n$userData\nLength:$messageLength";

	else
		out="Status Report\n";

		local MessageReference=$(HexToNum ${PDUString:$start:2}); # ??? Correct this name
		start=$(expr $start + 2);

		# length in decimals
		local sender_addressLength=$(HexToNum ${PDUString:$start:2});
		if [ $(expr $sender_addressLength % 2) != 0 ]
		then
			sender_addressLength=$(expr $sender_addressLength + 1);
		fi
		start=$(expr $start + 2);

		local sender_typeOfAddress=${PDUString:$start:2};
		start=$(expr $start + 2)

		sender_number=$(semiOctetToString ${PDUString:$start:$sender_addressLength});

		local subpos=$(expr ${#sender_number} - 1);
		if [ "${sender_number:$subpos:1}" == 'F' -o "${sender_number:$subpos:1}" == 'f' ]
		then
			sender_number=${sender_number:0:$subpos};
		fi

		if [ $sender_typeOfAddress -eq 91 ]
		then
			sender_number="+$sender_number";
		fi
		start=$(expr $start + sender_addressLength);

		local timeStamp=$(semiOctetToString ${PDUString:$start:14});

		# get date
		local year=${timeStamp:0:2};
		local month=${timeStamp:2:2};
		local day=${timeStamp:4:2};
		local hours=${timeStamp:6:2};
		local minutes=${timeStamp:8:2};
		local seconds=${timeStamp:10:2};

		timeStamp="$day/$month/$year $hours:$minutes:$seconds GMT +"$(expr $timezone / 4);
		start=$(expr $start + 14)

		local timeStamp2=$(semiOctetToString ${PDUString:$start:14});

		# get date
		local year2=${timeStamp:0:2};
		local month2=${timeStamp:2:2};
		local day2=${timeStamp:4:2};
		local hours2=${timeStamp:6:2};
		local minutes2=${timeStamp:8:2};
		local seconds2=${timeStamp:10:2};
		local timezone2=${timeStamp:12:2};

		timeStamp2="$day2/$month2/$year2 $hours2:$minutes2:$seconds2 GMT +"$(expr $timezone2 / 4);
		start=$(expr $start + 14)

		local mStatus=${PDUString:$start:2};

		out="${out}SMSC#\n$SMSC_Number\nSender:\n$sender_number\nMessage Ref#:\n\
$MessageReference\nTimeStamp:\n$timeStamp\nTimeStamp2:\n$timeStamp2\nStatus Byte: $mStatus";
    fi

    echo $out;
}

function cValid() {
	local valid=$1;
	local out="";
	local value;
	if [ $valid -le 143 ]; then
		value=$(expr \( $valid + 1 \) \* 5); # Minutes
	elif [ $valid -le 167 ]; then
		value=$(expr \( $valid - 143 \) / 2 + 12 ); # Hours
		value=$(expr $value \* 60); # Convert to Minutes
	elif [ $valid -le 196 ]; then
		value=$(expr $valid - 166);	# days
		value=$(expr $value \* 60 \* 24); # Convert to Minutes
	else
        value=$(expr $valid - 192); # Weeks
        value=$(expr $value \* 7 \* 60 \* 24); # Convert to Minutes
	fi
    local mins,hours,days,weeks;

    local mins=$(expr $value % 60);
    local hours=$(expr $value / 60);
    local days=$(expr $hours / 24);
    local weeks=$(expr $days / 7);
    hours=$(expr $hours % 24);
    days=$(expr $days % 7);

    if [ $weeks -ne 0 ]; then
        out="$out${weeks}w ";
	fi

    if [ $days -ne 0 ]; then
        out="$out${days}d ";
	fi

    if [ $hours -ne 0 ]; then
        out="$out${hours}h ";
	fi

    if [ $mins -ne 0 ]; then
        out="$out${mins}m ";
	fi

	echo $out;
}
