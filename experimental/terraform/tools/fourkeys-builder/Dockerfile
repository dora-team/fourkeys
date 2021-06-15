FROM gcr.io/google.com/cloudsdktool/cloud-sdk:slim

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-get install software-properties-common -y && \
    apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && \
    apt install terraform=0.15.5