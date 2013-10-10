#!/bin/bash

AWSID=$1
shift
AWSSEC=$1
shift
FILE=$1
shift
BUCKET=$1
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

DATE=`date '+%a, %d %b %Y %T %Z'`
SIGNATURE=`echo -ne "PUT\n\n\n\nx-amz-acl:public-read\nx-amz-date:$DATE\n/$BUCKET/$FILE?acl" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"
ACL_HEADER="X-amz-acl: public-read"
DATE_HEADER="X-amz-date: $DATE"
HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"
CONTENT_HEADER="Content-Type:"

curl -X PUT -H "$CONTENT_HEADER" -H "$ACL_HEADER" -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" "http://s3.amazonaws.com/$FILE?acl"
