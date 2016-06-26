FROM neo4j
RUN mkdir -p /db/data
WORKDIR /db
COPY . /db/
EXPOSE 7474:7474
ENV NEO4J_AUTH neo4j/admin
RUN bash -c "/var/lib/neo4j/bin/neo4j start; while ! curl -s localhost:7474 > /dev/null; do echo neo4j service not available, sleeping...; sleep 3; done; ls . && python ./process_courses.py;"