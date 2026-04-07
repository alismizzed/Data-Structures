#lang dssl2

# HW4: Graph

import cons
import 'dictionaries.rkt'
import sbox_hash

###
### REPRESENTATION
###

# A Vertex is a natural number.
let Vertex? = nat?

# A VertexList is either
#  - None, or
#  - cons(v, vs), where v is a Vertex and vs is a VertexList
let VertexList? = Cons.ListC[Vertex?]

# A Weight is a real number. (It’s a number, but it’s neither infinite
# nor not-a-number.)
let Weight? = AndC(num?, NotC(OrC(inf, -inf, nan)))

# An OptWeight is either
# - a Weight, or
# - None
let OptWeight? = OrC(Weight?, NoneC)

# A WEdge is WEdge(Vertex, Vertex, Weight)
struct WEdge:
    let u: Vertex?
    let v: Vertex?
    let w: Weight?

# A WEdgeList is either
#  - None, or
#  - cons(w, ws), where w is a WEdge and ws is a WEdgeList
let WEdgeList? = Cons.ListC[WEdge?]

# A weighted, undirected graph ADT.
interface WUGRAPH:
    # Returns the number of vertices in the graph. (The vertices are
    # numbered 0, 1, ..., k - 1.)
    def n_vertices(self) -> nat?
    # Returns the number of edges in the graph.
    def n_edges(self) -> nat?
    # Sets the weight of the edge between u and v to be w.
    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?) -> NoneC
    # Gets the weight of the edge between u and v, or None if there
    # is no such edge.
    def get_edge(self, u: Vertex?, v: Vertex?) -> OptWeight?
    # Gets a list of all vertices adjacent to v.
    def get_adjacent(self, v: Vertex?) -> VertexList?
    # Gets a list of all edges in the graph.
    def get_all_edges(self) -> WEdgeList?

class WUGraph (WUGRAPH):
    let nvert
    let nedge
    let mat

    def __init__(self, n_vert: nat?):
        self.nvert = n_vert
        self.nedge = 0
        self.mat = [None; n_vert]
        for i in range(n_vert):
            self.mat[i] = [None; n_vert]

    def _check_vertex(self, v: Vertex?) -> NoneC:
        if v >= self.nvert:
            error("vertex out of bounds")

    def n_vertices(self) -> nat?:
        return self.nvert

    def n_edges(self) -> nat?:
        return self.nedge

    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?) -> NoneC:
        self._check_vertex(u)
        self._check_vertex(v)

        let had_edge = self.mat[u][v] != None

        if w == None:
            if had_edge:
                self.mat[u][v] = None
                self.mat[v][u] = None
                self.nedge = self.nedge - 1
        else:
            self.mat[u][v] = w
            self.mat[v][u] = w
            if not had_edge:
                self.nedge = self.nedge + 1

    def get_edge(self, u: Vertex?, v: Vertex?) -> OptWeight?:
        self._check_vertex(u)
        self._check_vertex(v)
        return self.mat[u][v]

    def get_adjacent(self, v: Vertex?) -> VertexList?:
        self._check_vertex(v)
        let result = None
        for u in range(self.nvert):
            if self.mat[v][u] != None:
                result = cons(u, result)
        return result

    def get_all_edges(self) -> WEdgeList?:
        let result = None
        for u in range(self.nvert):
            for v in range(u, self.nvert):
                if self.mat[u][v] != None:
                    result = cons(WEdge(u, v, self.mat[u][v]), result)
        return result

test "basic get_edge test":
    let g = WUGraph(2)
    g.set_edge(0, 1, 1)
    assert g.get_edge(0, 1) == 1

###
### List helpers
###

# normalize_vertices : ListOf[Vertex] -> ListOf[Vertex]
# Sorts a list of numbers.
def normalize_vertices(lst: Cons.list?) -> Cons.list?:
    def vertex_lt?(u, v): return u < v
    return Cons.sort[Vertex?](vertex_lt?, lst)

# normalize_edges : ListOf[WEdge] -> ListOf[WEdge]
# Sorts a list of weighted edges, lexicographically.
def normalize_edges(lst: Cons.list?) -> Cons.list?:
    def normalize_edge(e: WEdge?) -> WEdge?:
        if e.u > e.v: return WEdge(e.v, e.u, e.w)
        else: return e
    def edge_lt?(e1, e2):
        return e1.u < e2.u or (e1.u == e2.u and e1.v < e2.v)
    lst = Cons.map(normalize_edge, lst)
    return Cons.sort[WEdge?](edge_lt?, lst)

###
### BUILDING GRAPHS
###

def example_graph() -> WUGraph?:
    let result = WUGraph(6)

    result.set_edge(0, 1, 12)
    result.set_edge(1, 2, 31)
    result.set_edge(1, 3, 56)
    result.set_edge(2, 3, -2)
    result.set_edge(3, 4, 9)
    result.set_edge(3, 5, 7)
    result.set_edge(4, 5, 1)

    return result

struct CityMap:
    let graph
    let city_name_to_node_id
    let node_id_to_city_name

def my_home_region():
    let g = WUGraph(5)

    let city_to_id = HashTable(10, make_sbox_hash())
    let id_to_city = HashTable(10, make_sbox_hash())

    city_to_id.put("Clifton", 0)
    city_to_id.put("Montclair", 1)
    city_to_id.put("Passaic", 2)
    city_to_id.put("Paterson", 3)
    city_to_id.put("Newark", 4)

    id_to_city.put(0, "Clifton")
    id_to_city.put(1, "Montclair")
    id_to_city.put(2, "Passaic")
    id_to_city.put(3, "Paterson")
    id_to_city.put(4, "Newark")

    g.set_edge(city_to_id.get("Clifton"), city_to_id.get("Montclair"), 5)
    g.set_edge(city_to_id.get("Clifton"), city_to_id.get("Passaic"), 4)
    g.set_edge(city_to_id.get("Clifton"), city_to_id.get("Paterson"), 6)
    g.set_edge(city_to_id.get("Clifton"), city_to_id.get("Newark"), 11)
    g.set_edge(city_to_id.get("Montclair"), city_to_id.get("Newark"), 10)
    g.set_edge(city_to_id.get("Passaic"), city_to_id.get("Paterson"), 3)
    g.set_edge(city_to_id.get("Paterson"), city_to_id.get("Newark"), 12)

    return CityMap(g, city_to_id, id_to_city)

###
### DFS
###

# dfs : WUGRAPH Vertex [Vertex -> any] -> None
# Performs a depth-first search starting at `start`, applying `visit`
# to each vertex once as it is discovered by the search.
def dfs(graph: WUGRAPH!, start: Vertex?, visit: FunC[Vertex?, AnyC]) -> NoneC:
    let seen = [False; graph.n_vertices()]

    def search(v):
        if seen[v]:
            return
        seen[v] = True
        visit(v)

        let nbrs = graph.get_adjacent(v)
        while nbrs != None:
            search(nbrs.data)
            nbrs = nbrs.next

    search(start)

###
### DFS helpers
###

# dfs_to_list : WUGRAPH Vertex -> ListOf[Vertex]
# Performs a depth-first search starting at `start` and returns a
# list of all reachable vertices.
# This function uses your `dfs` function to build a list in the
# order of the search.
def dfs_to_list(graph: WUGRAPH!, start: Vertex?) -> VertexList?:
    let list = None
    dfs(graph, start, lambda new: list = cons(new, list))
    return Cons.rev(list)

# one_of : AnyC? VecC[AnyC] -> bool?
# Returns true is `x` is one of the elements of `vec`.
def one_of(x, vec):
    for y in vec:
        if x == y: return True
    return False

###
### Tests
###

test "n_vertices and n_edges":
    let g = WUGraph(4)
    assert g.n_vertices() == 4
    assert g.n_edges() == 0

test "set_edge add update delete":
    let g = WUGraph(3)

    g.set_edge(0, 1, 5)
    assert g.get_edge(0, 1) == 5
    assert g.get_edge(1, 0) == 5
    assert g.n_edges() == 1

    g.set_edge(1, 0, 9)
    assert g.get_edge(0, 1) == 9
    assert g.n_edges() == 1

    g.set_edge(0, 1, None)
    assert g.get_edge(0, 1) == None
    assert g.get_edge(1, 0) == None
    assert g.n_edges() == 0

test "self edge works":
    let g = WUGraph(3)
    g.set_edge(1, 1, 8)
    assert g.get_edge(1, 1) == 8
    assert g.n_edges() == 1
    g.set_edge(1, 1, None)
    assert g.get_edge(1, 1) == None
    assert g.n_edges() == 0

test "get_adjacent normalized":
    let g = WUGraph(5)
    g.set_edge(2, 0, 1)
    g.set_edge(2, 4, 1)
    g.set_edge(2, 1, 1)
    assert normalize_vertices(g.get_adjacent(2)) == Cons.from_vec([0, 1, 4])

test "get_all_edges normalized":
    let g = WUGraph(4)
    g.set_edge(0, 1, 7)
    g.set_edge(3, 2, 9)
    g.set_edge(1, 1, 5)
    assert normalize_edges(g.get_all_edges()) == \
        Cons.from_vec([WEdge(0, 1, 7),
                       WEdge(1, 1, 5),
                       WEdge(2, 3, 9)])

test "example_graph edges":
    let g = example_graph()
    assert g.n_vertices() == 6
    assert g.n_edges() == 7
    assert g.get_edge(0, 1) == 12
    assert g.get_edge(1, 2) == 31
    assert g.get_edge(1, 3) == 56
    assert g.get_edge(2, 3) == -2
    assert g.get_edge(3, 4) == 9
    assert g.get_edge(3, 5) == 7
    assert g.get_edge(4, 5) == 1

test "get_edge out of bounds":
    let g = WUGraph(3)
    assert_error g.get_edge(0, 3)

test "set_edge out of bounds":
    let g = WUGraph(3)
    assert_error g.set_edge(0, 3, 10)

test "my first DFS test":
    let g = WUGraph(4)
    g.set_edge(0, 1, 1)
    g.set_edge(0, 2, 10)
    g.set_edge(1, 3, 12)
    g.set_edge(2, 3, -4)

    assert one_of(dfs_to_list(g, 0),
                  [Cons.from_vec([0, 1, 3, 2]),
                   Cons.from_vec([0, 2, 3, 1])])

test "dfs on disconnected graph":
    let g = WUGraph(6)
    g.set_edge(0, 1, 1)
    g.set_edge(1, 2, 1)
    g.set_edge(3, 4, 1)

    assert dfs_to_list(g, 0) == Cons.from_vec([0, 1, 2])

test "dfs self edge":
    let g = WUGraph(3)
    g.set_edge(0, 0, 5)
    g.set_edge(0, 1, 7)

    assert dfs_to_list(g, 0) == Cons.from_vec([0, 1])

test "my_home_region uses both dictionaries and graph":
    let cm = my_home_region()

    let clifton = cm.city_name_to_node_id.get("Clifton")
    let paterson = cm.city_name_to_node_id.get("Paterson")
    let newark = cm.city_name_to_node_id.get("Newark")

    assert cm.graph.get_edge(clifton, paterson) == 6
    assert cm.node_id_to_city_name.get(newark) == "Newark"
    assert cm.node_id_to_city_name.get(clifton) == "Clifton"