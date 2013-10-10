#!/bin/bash

AWSID=$1
shift
AWSSEC=$1
shift
SRC_BUCKET=$1
shift
DEST_BUCKET=$1
shift

if [[ -z $AWSID ]]
then echo "missing awsid parameter" >&2
    exit 1
fi
if [[ -z $AWSSEC ]]
then echo "missing awssec parameter" >&2
    exit 1
fi
if [[ -z $SRC_BUCKET ]]
then echo "missing source bucket parameter" >&2
    exit 1
fi
if [[ -z $DEST_BUCKET ]]
then echo "missing destination bucket parameter" >&2
    exit 1
fi

SCRIPTS_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd /mnt/tmp
mkdir -p copy_bucket/$$
cd copy_bucket/$$

NUM_COPIED=0
for file in `$SCRIPTS_DIR/s3_list.sh $AWSID $AWSSEC $SRC_BUCKET all | grep -v '/$' | awk '{print $NF}'`
{
    STATUS_CODE=`$SCRIPTS_DIR/s3_head.sh $AWSID $AWSSEC $file $DEST_BUCKET 2>/dev/null | head -n 1 | awk '{print $2}'`
    if [[ $STATUS_CODE -ne 200 ]] ; then
        echo $file
        mkdir -p `dirname $file`
        $SCRIPTS_DIR/s3_get.sh $AWSID $AWSSEC $file $SRC_BUCKET
        $SCRIPTS_DIR/s3_put.sh $AWSID $AWSSEC $file $DEST_BUCKET $file
        rm $file
        NUM_COPIED=$(( NUM_COPIED + 1 ))
    fi
}

echo "copied $NUM_COPIED files"
cd ..
rm -rf $$
