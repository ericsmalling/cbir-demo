FROM maven:3 as build

RUN mkdir -p /webapp
WORKDIR /webapp

COPY pom.xml pom.xml
COPY src src
RUN --mount=target=$HOME/.m2,type=cache mvn install

FROM repo.mycorp.com:5001/my-java:17.0.6
COPY --from=build /webapp/target/*.jar /webapp.jar
EXPOSE 8080
CMD ["java", "-jar", "/webapp.jar"]

