using FastCellularAutomata
using Test
using Aqua
using JET

@testset "FastCellularAutomata.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(FastCellularAutomata)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(FastCellularAutomata; target_defined_modules = true)
    end
    # Write your tests here.
end
