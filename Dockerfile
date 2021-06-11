# Container image that runs your code
FROM python:3.8-slim

RUN apt-get update
RUN apt-get install -y git jq zip
RUN pip install awscli

# Copies your code file from your action repository to the filesystem path `/` of the container
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
