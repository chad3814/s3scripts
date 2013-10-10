#!/bin/bash

AWSID=$1
shift
AWSSEC=$1
shift
BUCKET=$1
shift
ALL=$1
shift
MARKER=$1
shift

if [[ -z $AWSID ]]
then echo "missing awsid parameter" >&2
    exit 1
fi
if [[ -z $AWSSEC ]]
then echo "missing awssec parameter" >&2
    exit 1
fi
if [[ -z $BUCKET ]]
then echo "missing bucket parameter" >&2
    exit 1
fi
if [[ -n $MARKER ]]
then MARKER="?marker=$MARKER"
fi

DATE=`date '+%a, %d %b %Y %T %Z'`
SIGNATURE=`echo -ne "GET\n\n\n\nx-amz-date:$DATE\n/$BUCKET/" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"
DATE_HEADER="X-amz-date: $DATE"
HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"

# This curl line is just like in s3_get.sh, but then it's piped to bash -->
#curl -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" -s "http://s3.amazonaws.com/$MARKER"
curl -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" -s "http://s3.amazonaws.com/$MARKER" | bash -c '
ALL=$4

# this bash script breaks XML up, for a detailed description see:
# http://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash#7052168
read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
}

last_key=""
is_truncated=""
name=""
size=""
time=""
while read_dom
do
    if [[ $ENTITY = "Contents" ]]; then
        name=""
        size=""
        time=""
    fi
    if [[ $ENTITY = "Key" ]]; then
        last_key=$CONTENT
        name=$CONTENT
    fi
    if [[ $ENTITY = "Size" ]]; then
        size=$CONTENT
    fi
    if [[ $ENTITY = "LastModified" ]]; then
        time=$CONTENT
    fi
    if [[ $ENTITY = "/Contents" ]]; then
        echo -e "$time\t$size\t$name"
    fi
    if [[ $ENTITY = "IsTruncated" ]]; then
        is_truncated=$CONTENT
    fi
done

if [[ -n $ALL && $is_truncated = "true" ]]
then "$0" "$@" $last_key
fi' "$0" "$AWSID" "$AWSSEC" "$BUCKET" "$ALL"
