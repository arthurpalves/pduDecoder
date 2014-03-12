#!/bin/bash

. pduDecoder.sh

function pdu_main() {
    echo -n "Input Hexadecimal PDU Message:";
    read code;
#    code="$1"
    echo "Computing...";
    string=`getPDUMetaInfo $code`;
    echo "--------------------------------------------------------------------------------";
    echo " 7/8/16 Bit PDU Message (readable) "
    echo "--------------------------------------------------------------------------------";
    echo -e $string;
    echo "--------------------------------------------------------------------------------";
}

pdu_main;
