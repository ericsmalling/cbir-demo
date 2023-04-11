FROM maven:3 as build

RUN mkdir -p /webapp
WORKDIR /webapp

COPY pom.xml pom.xml
COPY src src
RUN --mount=target=$HOME/.m2,type=cache mvn install

FROM repo.initech.com:5001/amazoncorretto:17.0.1
COPY --from=build /webapp/target/*.jar /webapp.jar
EXPOSE 8080
CMD ["java", "-jar", "/webapp.jar"]

