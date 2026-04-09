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
    @testset "ECA rules" begin
        n = 8
        for rule in 0:255
            eca = ECARule(rule, n)
            @testset "Rule $rule" begin
                for x_int in 0:(1 << n) - 1
                    x = UInt16(x_int)
                    result = apply(eca, x)
                    for i in 0:(n - 1)
                        l_bit = Int((x >> ((i - 1 + n) % n)) & 1)
                        c_bit = Int((x >> i) & 1)
                        r_bit = Int((x >> ((i + 1) % n)) & 1)
                        index = l_bit * 4 + c_bit * 2 + r_bit
                        expected = (rule >> index) & 1
                        actual = Int((result >> i) & 1)
                        @test actual == expected
                    end
                end
            end
        end
    end
end
