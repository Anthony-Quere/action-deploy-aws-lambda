#!/bin/bash

setup_requirement_file() {
	echo "> Authentication with github token"

	TOKEN=${INPUT_AUTH_SSH_KEY}

	sed -i "s/https:\/\/github\.com/https:\/\/$TOKEN:github\.com/1" app/requirements.txt
	sed -i "s/ssh:\/\/github\.com/https:\/\/$TOKEN:github\.com/1" 
}

add_requirements() {
	if [ -f "app/requirements.txt" ]
	then
		echo "> Setup requirement file..."
		setup_requirement_file
		echo "> Installing requirements..."

		mkdir -p libs
		pip install -vvv --target libs -r app/requirements.txt
		if [ $? -ne 0 ]
		then
			echo "> Fail to add requirements"
			exit 1
		fi
    fi
}

deploy_function() {
	echo "> Deploying function ..."
	RETCODE=0
	cd "${INPUT_WORKING_DIRECTORY}"
	add_requirements
	zip -r code.zip . -x \*.git\*
	aws lambda create-function --function-name "${INPUT_FUNCTION_NAME}" --runtime "${INPUT_RUNTIME}" \
		--timeout "${INPUT_TIMEOUT}" --memory-size "${INPUT_MEMORY}" --role "${INPUT_ROLE}" \
		--handler "${INPUT_HANDLER}" ${OPT_ENV_VARIABLES} ${OPT_VPC_CONFIG} --zip-file fileb://code.zip
    RETCODE=$((RETCODE+$?))
	[ $RETCODE -ne 0 ] && echo "> ERROR : failed to create the function."
	exit $RETCODE
}

update_function() {
	echo "> Updating function ..."
	RETCODE=0
	cd "${INPUT_WORKING_DIRECTORY}"
	# add_requirements
	zip -r code.zip . -x \*.git\*
	aws lambda update-function-configuration --function-name "${INPUT_FUNCTION_NAME}" --runtime "${INPUT_RUNTIME}" \
		--timeout "${INPUT_TIMEOUT}" --memory-size "${INPUT_MEMORY}" --role "${INPUT_ROLE}" \
		--handler "${INPUT_HANDLER}" ${OPT_ENV_VARIABLES} ${OPT_VPC_CONFIG}
    RETCODE=$((RETCODE+$?))
	aws lambda update-function-code --function-name "${INPUT_FUNCTION_NAME}" --zip-file fileb://code.zip
    RETCODE=$((RETCODE+$?))
	[ $RETCODE -ne 0 ] && echo "> ERROR : failed to update the function."
	exit $RETCODE
}

deploy_or_update_function() {
	cd app
	if [ -n "${INPUT_ENV_VARIABLES}" ]
    then 
            OPT_ENV_VARIABLES="--environment Variables=${INPUT_ENV_VARIABLES}"
    fi
	if [ -n "${INPUT_VPC_CONFIG}" ]
    then 
            OPT_VPC_CONFIG="--vpc-config ${INPUT_VPC_CONFIG}"
    fi
    echo "> Checking function existence..."
	aws lambda get-function --function-name "${INPUT_FUNCTION_NAME}" &> /dev/null
	if [ $? != 0 ]
	then
		echo "> Function ${INPUT_FUNCTION_NAME} not found, running initial deployment..."
		deploy_function
	else
		echo "> Function found, updating..."
		update_function
    fi
    echo "> Done."
}

show_environment() {
	echo "> Function name: ${INPUT_FUNCTION_NAME}"
	echo "> Runtime: ${INPUT_RUNTIME}"
	echo "> Memory size: ${INPUT_MEMORY}"
	echo "> Timeout: ${INPUT_TIMEOUT}"
	echo "> IAM role: ${INPUT_ROLE}"
	echo "> Lambda handler: ${INPUT_HANDLER}"
	echo "> Working directory: ${INPUT_WORKING_DIRECTORY}"
	echo "> Environment variables: ${INPUT_ENV_VARIABLES}"
	echo "> VPC Config: ${INPUT_VPC_CONFIG}"
}

echo "Anthony-Quere/action-deploy-aws-lambda@v1.6"
aws --version
show_environment
add_requirements

echo "> ls"
ls

echo "> ls libs"
ls libs

deploy_or_update_function