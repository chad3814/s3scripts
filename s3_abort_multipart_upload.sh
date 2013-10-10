#!/bin/bash

AWSID=$1
shift
AWSSEC=$1
shift
FILE=$1
shift
BUCKET=$1
shift
UPLOADID=$1
shift

if [[ -z $AWSID ]]
then echo "missing awsid parameter" >&2
    exit 1
fi
if [[ -z $AWSSEC ]]
then echo "missing awssec parameter" >&2
    exit 1
fi
if [[ -z $FILE ]]
then echo "missing file parameter" >&2
    exit 1
fi
if [[ -z $BUCKET ]]
then echo "missing bucket parameter" >&2
    exit 1
fi
if [[ -z $UPLOADID ]]
then echo "missing uploadid parameter" >&2
    exit 1
fi

DATE=`date '+%a, %d %b %Y %T %Z'`
SIGNATURE=`echo -ne "DELETE\n\n\n\nx-amz-date:$DATE\n/$BUCKET/$FILE?uploadId=$UPLOADID" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"
DATE_HEADER="X-amz-date: $DATE"
HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"
CONTENT_HEADER="Content-Type:"

curl -X DELETE -H "$CONTENT_HEADER" -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" "http://s3.amazonaws.com/$FILE?uploadId=$UPLOADID"
