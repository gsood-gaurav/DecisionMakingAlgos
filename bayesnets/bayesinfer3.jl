using Graphs

Base.Dict{Symbol,V}(a::NamedTuple) where V = Dict{Symbol,V}(n=>v for (n,v) in zip(keys(a), values(a))) 
Base.convert(::Type{Dict{Symbol,V}}, a::NamedTuple) where V =
    Dict{Symbol,V}(a)
    
Base.isequal(a::Dict{Symbol,<:Any}, nt::NamedTuple) = length(a) == length(nt) &&
all(a[n] == v for (n,v) in zip(keys(nt), values(nt)))

struct Variable
    name::Symbol
    r::Int
end
const Assignment = Dict{Symbol, Int}
const FactorTable = Dict{Assignment, Float64}

struct Factor
    vars::Vector{Variable}
    table::FactorTable
end

variablenames(ϕ::Factor)  = [var.name for var in ϕ.vars]
select(a::Assignment, varnames::Vector{Symbol}) = Assignment(n=>a[n] for n in varnames)

function assignments(vars::AbstractVector{Variable})
    names = [var.name for var in vars]
    return vec([Assignment(n=>v for (n,v) in zip(names, values))
        for values in Iterators.product((1:v.r for v in vars)...)
    ])
end

X = Variable(:x, 2)
Y = Variable(:y, 2)
Z = Variable(:z, 2)
as = assignments([X, Y, Z])

ft = Dict(k=>0.0 for k in as)
ϕ = Factor([X,Y,Z], FactorTable(ft))

struct BayesianNetwork
    vars::Vector{Variable}  # Number of variables in a Bayesian Network
    factors::Vector{Factor}  # conditional probability tables
    graph::SimpleDiGraph{Int64}  # Structure of the Bayesian Network
end    

function probability(bn::BayesianNetwork, assignment)
    subassignment(ϕ) = select(assignment, variablenames(ϕ))
    probability(ϕ) = get(ϕ.table, subassignment(ϕ), 0.0)
    return prod(probability(ϕ) for ϕ in bn.factors)
end

B = Variable(:b, 2); S = Variable(:s, 2)
E = Variable(:e, 2)
D = Variable(:v, 2); C = Variable(:c, 2)

vars = [B, S, E, D, C]

factors = [
    Factor([B,], FactorTable((b=1,)=>0.99, (b=2,)=>0.01)),
    Factor([S,], FactorTable((s=1,)=>0.98, (s=2,)=>0.02)),
    Factor([E,B,S], FactorTable(
        (e=1,b=1,s=1) => 0.90, (e=1,b=1,s=2) => 0.04, 
        (e=1,b=2,s=1) => 0.05, (e=1,b=2,s=2) => 0.01, 
        (e=2,b=1,s=1) => 0.10, (e=2,b=1,s=2) => 0.96,
        (e=2,b=2,s=1) => 0.95, (e=2,b=2,s=2) => 0.99)),
    Factor([D, E], FactorTable(
        (d=1,e=1) => 0.96, (d=1,e=2) => 0.03, 
        (d=2,e=1) => 0.04, (d=2,e=2) => 0.97)),
    Factor([C, E], FactorTable(
        (c=1,e=1) => 0.98, (c=1,e=2) => 0.01,
        (c=2,e=1) => 0.02, (c=2,e=2) => 0.99))
]

graph = SimpleDiGraph(5)
add_edge!(graph, 1, 3); add_edge!(graph, 2, 3) 
add_edge!(graph, 3, 4); add_edge!(graph, 3, 5) 
bn = BayesianNetwork(vars, factors, graph)


println(probability(bn, Assignment((b=1, s=1, e=1, d=2, c=1))))