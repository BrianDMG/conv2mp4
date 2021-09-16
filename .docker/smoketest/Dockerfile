ARG COMMIT=latest

FROM registry.gitlab.com/briandmg/conv2mp4:${COMMIT} AS base

FROM base AS test

ENV ENV MEDIA_PATH=/test
RUN mkdir /smoke-test-results
ADD smoke_test_suite.tar.gz /test

CMD [ "pwsh", "/c", "sleep 720" ]