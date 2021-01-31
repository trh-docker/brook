FROM quay.io/spivegin/gitonly:latest AS git

FROM quay.io/spivegin/golang:v1.13 AS builder
WORKDIR /opt/src/src/github.com/txthinking

RUN ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && git config --global user.name "quadtone" && git config --global user.email "quadtone@txtsme.com"
COPY --from=git /root/.ssh /root/.ssh
RUN ssh-keyscan -H github.com > ~/.ssh/known_hosts &&\
    ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts &&\
    ssh-keyscan -H gitea.com >> ~/.ssh/know_hosts

#COPY --from=gover /opt/go /opt/go
ENV deploy=c1f18aefcb3d1074d5166520dbf4ac8d2e85bf41 \
    GO111MODULE=off \
    GOPROXY=direct \
    GOSUMDB=off \
    GOPRIVATE=sc.tpnfc.us \
    version=1.0.1
    # GIT_TRACE_PACKET=1 \
    # GIT_TRACE=1 \
    # GIT_CURL_VERBOSE=1
RUN git config --global url.git@github.com:.insteadOf https://github.com/ &&\
    git config --global url.git@gitlab.com:.insteadOf https://gitlab.com/ &&\
    git config --global url.git@gitea.com:.insteadOf https://gitea.com/ &&\
    git config --global url."https://${deploy}@sc.tpnfc.us/".insteadOf "https://sc.tpnfc.us/"

RUN go get github.com/txthinking/brook &&\
    cd /opt/src/src/github.com/txthinking/brook/cli/brook &&\
    go get -t -v . &&\
    export GOOS=linux &&\
    export GOARCH=amd64 &&\
    go build -o brook . &&\
    export GOOS=windows &&\
    GOARCH=amd64 &&\
    go build -o brook_windows_amd64.exe .
    # sh build.sh 20210101

FROM quay.io/spivegin/tlmbasedebian
RUN mkdir /opt/bin
COPY --from=builder /opt/src/src/github.com/txthinking/brook/cli/brook/brook /opt/bin/brook
COPY --from=builder /opt/src/src/github.com/txthinking/brook/cli/brook/brook_windows_amd64.exe /opt/brook_windows_amd64.exe
RUN chmod +x /opt/bin/brook && ln -s /opt/bin/brook /bin/brook
CMD ["brook", "server"]
