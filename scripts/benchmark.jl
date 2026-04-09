using FastCellularAutomata
using Random
using BenchmarkTools

function simulate_ca(y, x, rule, nsteps)
    for _ in 1:nsteps
        apply!(y, rule, x)
        x, y = y, x # swap pointers
    end
    nothing
end

x = Lattice1D(2^20)
Random.rand!(x.cells)
y = similar(x)
nsteps = 10000
rule = ECARule(110, x.N)
@benchmark simulate_ca($y, $x, $rule, $nsteps)