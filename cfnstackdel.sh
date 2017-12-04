#!/bin/bash
hn=$2

aws cloudformation describe-stacks | grep StackName | awk -F":" '{print $2}' | tr -d '\"' | tr -d '\,' | grep "\b${hn}\b" >> /dev/null

if [[ $? != "0" ]]
then
        aws cloudformation delete-stack --stack-name ${hn}
        CfnStackName=${hn}
        CfnStackRegion=us-west-2
        stackStatus="DELETE_IN_PROGRESS"

        while [[ 1 ]]; do
                echo aws cloudformation describe-stacks --region "${CfnStackRegion}" --stack-name "${CfnStackName}"
                response=$(aws cloudformation describe-stacks --region "${CfnStackRegion}" --stack-name "${CfnStackName}" 2>&1)
                responseOrig="$response"
                response=$(echo "$response" | tr '\n' ' ' | tr -s " " | sed -e 's/^ *//' -e 's/ *$//')

                if [[ "$response" != *"StackStatus"* ]]
                then
                        echo "Error occurred creating AWS CloudFormation stack. Error:"
                        echo "    $responseOrig"
                        exit -1
                fi

                stackStatus=$(echo $response | sed -e 's/^.*"StackStatus"[ ]*:[ ]*"//' -e 's/".*//')
                echo "    StackStatus: $stackStatus"

                if [[ "$stackStatus" == "ROLLBACK_IN_PROGRESS" ]] || [[ "$stackStatus" == "ROLLBACK_COMPLETE" ]]; then
                echo "Error occurred deleting AWS CloudFormation stack and returned status code ROLLBACK_IN_PROGRESS. Details:"
                echo "$responseOrig"
                exit -1
                elif [[ "$stackStatus" == "DELETE_COMPLETE" ]]; then
                break
                fi

        # Sleep for 5 seconds, if stack creation in progress
                sleep 5
        done

else
        echo "No Stack by the name ${hn}"
fi
