# Base image: ubuntu:22.04
FROM ubuntu:22.04

# ARGs
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

# neo4j 5.5.0 installation and some cleanup
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y nano unzip neo4j=1:5.5.0 python3-pip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# TODO: Complete the Dockerfile

RUN echo "server.default_listen_address=0.0.0.0" >> /etc/neo4j/neo4j.conf

RUN echo "server.http.listen_address=:7474" >> /etc/neo4j/neo4j.conf
RUN echo "server.bolt.listen_address=:7687" >> /etc/neo4j/neo4j.conf
RUN echo "dbms.security.procedures.unrestricted=gds.*,my.extensions.example,my.procedures.*" >> /etc/neo4j/neo4j.conf
RUN echo "dbms.security.procedures.allowlist=apoc.coll.*,apoc.load.*,gds.*" >> /etc/neo4j/neo4j.conf

RUN neo4j-admin dbms set-initial-password project2phase1
	
RUN wget -O /var/lib/neo4j/plugins/neo4j-graph-data-science-2.3.1.zip https://graphdatascience.ninja/neo4j-graph-data-science-2.3.1.zip \
    && unzip /var/lib/neo4j/plugins/neo4j-graph-data-science-2.3.1.zip -d /var/lib/neo4j/plugins/ \
    && rm /var/lib/neo4j/plugins/neo4j-graph-data-science-2.3.1.zip

# Install git
RUN apt-get update && \
    apt-get install -y git && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install additional Python packages
RUN pip install neo4j pandas pyarrow

# Create the directory
RUN mkdir -p /cse511/

# Download the taxicab dataset
RUN wget -O /cse511/yellow_tripdata_2022-03.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet


# Clone the GitHub repository to get data_loader.py
RUN git clone https://Varun-Kesana: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@github.com/CSE511-SPRING-2023/vkesana-project-2.git /cse511/vkesana-project-2 && \
    mv /cse511/vkesana-project-2/data_loader.py /cse511/data_loader.py && \
    rm -rf /cse511/vkesana-project-2


# Run the data loader script
RUN chmod +x /cse511/data_loader.py && \
    cd /cse511 && \
    neo4j start && \
    python3 data_loader.py && \
    neo4j stop

# Expose neo4j ports
EXPOSE 7474 7687

# Start neo4j service and show the logs on container run
CMD ["/bin/bash", "-c", "neo4j start && tail -f /dev/null"]