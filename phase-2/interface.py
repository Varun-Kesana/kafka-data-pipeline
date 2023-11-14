from neo4j import GraphDatabase

class Interface:
    def __init__(self, uri, user, password):
        self._driver = GraphDatabase.driver(uri, auth=(user, password), encrypted=False)
        self._driver.verify_connectivity()

    def close(self):
        self._driver.close()

    def bfs(self, start_node, last_node):
        with self._driver.session() as session:

            result_exist=session.run("CALL gds.graph.exists('nyc_taxi_data_bfs')")
            rem=result_exist.data()

            if rem[0]["exists"] is True:
                session.run("CALL gds.graph.drop('nyc_taxi_data_bfs')")

            query_inmemory_graph="CALL gds.graph.project('nyc_taxi_data_bfs','Location','TRIP')"
            session.run(query_inmemory_graph)

            query_bfs="""MATCH (a:Location {name:$snode}), (d:Location {name:$lnode})
            WITH id(a) AS source, id(d) AS target
            CALL gds.bfs.stream('nyc_taxi_data_bfs', {
                sourceNode: source,
                targetNodes: target
                })
                YIELD path
                RETURN path"""

            result = session.run(query_bfs, {"snode": start_node,"lnode":last_node})
            k=result.data()
            return k

    def pagerank(self, max_iterations, weight_property):
        with self._driver.session() as session:

            result_exist=session.run("CALL gds.graph.exists('nyc_taxi_data')")
            rem=result_exist.data()

            if rem[0]["exists"] is True:
                session.run("CALL gds.graph.drop('nyc_taxi_data')")

            query_inmemory_graph="CALL gds.graph.project('nyc_taxi_data','Location','TRIP',{relationshipProperties: $weight_prop})"
            session.run(query_inmemory_graph,{"weight_prop":weight_property})
            
            query_pagerank="""CALL gds.pageRank.stream('nyc_taxi_data', {maxIterations: $max_iter, relationshipWeightProperty: $weight_prop}) YIELD nodeId, score
            WITH gds.util.asNode(nodeId).name as name, score
            ORDER BY score DESC
            LIMIT 1
            RETURN name, score
            UNION
            CALL gds.pageRank.stream('nyc_taxi_data', {maxIterations: $max_iter, relationshipWeightProperty: $weight_prop}) YIELD nodeId, score
            WITH gds.util.asNode(nodeId).name as name, score
            ORDER BY score ASC
            LIMIT 1
            RETURN name, score"""

            #print(query_pagerank)
            
            result = session.run(query_pagerank, {"max_iter": max_iterations,"weight_prop":weight_property})
            k=result.data()
            return k

