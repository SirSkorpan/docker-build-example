FROM openjdk:8-jre

ARG JAR_FILE
ENV JAR_FILE ${JAR_FILE}

RUN mkdir /app
RUN mkdir /app/resources

COPY ./resources/greetings.text /app/resources/
COPY ./${JAR_FILE} /app

WORKDIR /app

CMD java -jar ${JAR_FILE}
