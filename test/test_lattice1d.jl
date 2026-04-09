@testset "Lattice1D" begin
    @testset "construction" begin
        lat = Lattice1D(UInt8[0xAB], 8)
        @test lat.cells == UInt8[0xAB]
        @test lat.N == 8

        lat2 = Lattice1D(UInt8[0x12, 0x34], 16)
        @test lat2.cells == UInt8[0x12, 0x34]
        @test lat2.N == 16
    end

    @testset "similar" begin
        lat = Lattice1D(UInt8[0xAB, 0xCD], 16)
        lat2 = similar(lat)
        @test lat2.N == lat.N
        @test length(lat2.cells) == length(lat.cells)
        @test eltype(lat2.cells) == UInt8
    end

    @testset "shift_left - single cell circular" begin
        # shift_left on a single-cell lattice should be a circular left shift within N bits
        for v in UInt8[0x00, 0x01, 0x7F, 0x80, 0xFF, 0xA5, 0x5A]
            lat = Lattice1D(UInt8[v], 8)
            @test shift_left(lat, 1) == (v << 1) | (v >> 7)
        end
    end

    @testset "shift_right - single cell circular" begin
        for v in UInt8[0x00, 0x01, 0x7F, 0x80, 0xFF, 0xA5, 0x5A]
            lat = Lattice1D(UInt8[v], 8)
            @test shift_right(lat, 1) == (v >> 1) | ((v & 0x01) << 7)
        end
    end

    @testset "shift_left - two cells cross-boundary carry" begin
        # MSB of cells[2] (bit 15) wraps around to LSB of cells[1]
        lat = Lattice1D(UInt8[0x00, 0x80], 16)
        @test shift_left(lat, 1) == 0x01
        @test shift_left(lat, 2) == 0x00

        # MSB of cells[1] (bit 7) carries into LSB of cells[2]
        lat = Lattice1D(UInt8[0x80, 0x00], 16)
        @test shift_left(lat, 1) == 0x00
        @test shift_left(lat, 2) == 0x01
    end

    @testset "shift_right - two cells cross-boundary carry" begin
        # LSB of cells[1] (bit 0) wraps around to MSB of cells[2] (bit 15)
        lat = Lattice1D(UInt8[0x01, 0x00], 16)
        @test shift_right(lat, 1) == 0x00
        @test shift_right(lat, 2) == 0x80

        # LSB of cells[2] (bit 8) carries into MSB of cells[1] (bit 7)
        lat = Lattice1D(UInt8[0x00, 0x01], 16)
        @test shift_right(lat, 1) == 0x80
        @test shift_right(lat, 2) == 0x00
    end

    @testset "shift_left two cells matches scalar" begin
        for x in UInt16[0x0000, 0x0001, 0x00FF, 0xFF00, 0xFFFF, 0x1234, 0xABCD, 0x5555, 0xAAAA, 0x8000, 0x0080]
            lat = Lattice1D(UInt8[x & 0xFF, x >> 8], 16)
            shifted = UInt16((x << 1) | (x >> 15))
            @test shift_left(lat, 1) == UInt8(shifted & 0xFF)
            @test shift_left(lat, 2) == UInt8(shifted >> 8)
        end
    end

    @testset "shift_right two cells matches scalar" begin
        for x in UInt16[0x0000, 0x0001, 0x00FF, 0xFF00, 0xFFFF, 0x1234, 0xABCD, 0x5555, 0xAAAA, 0x8000, 0x0001]
            lat = Lattice1D(UInt8[x & 0xFF, x >> 8], 16)
            shifted = UInt16((x >> 1) | ((x & UInt16(1)) << 15))
            @test shift_right(lat, 1) == UInt8(shifted & 0xFF)
            @test shift_right(lat, 2) == UInt8(shifted >> 8)
        end
    end

    @testset "apply - single cell matches scalar (all 256 rules, all 256 values)" begin
        for rule_num in 0:255
            rule = ECARule(rule_num, 8)
            for v in 0x00:0xFF
                lat = Lattice1D(UInt8[v], 8)
                @test apply(rule, lat).cells[1] == apply(rule, v)
            end
        end
    end

    @testset "apply! matches apply (all 256 rules)" begin
        for rule_num in 0:255
            rule = ECARule(rule_num, 8)
            for v in UInt8[0x00, 0x01, 0x55, 0xAA, 0x80, 0xFF]
                lat = Lattice1D(UInt8[v], 8)
                expected = apply(rule, lat)
                target = similar(lat)
                apply!(target, rule, lat)
                @test target.cells == expected.cells
                @test target.N == expected.N
            end
        end
    end

    @testset "apply - two cells matches scalar" begin
        # Spot-check well-known rules against the scalar path
        for rule_num in [0, 1, 30, 90, 110, 150, 255]
            rule = ECARule(rule_num, 16)
            for x in UInt16[0x0000, 0x0001, 0x00FF, 0xFF00, 0xFFFF, 0x1234, 0xABCD, 0x5555, 0xAAAA]
                lat = Lattice1D(UInt8[x & 0xFF, x >> 8], 16)
                scalar = apply(rule, x)
                result = apply(rule, lat)
                @test result.cells[1] == UInt8(scalar & 0xFF)
                @test result.cells[2] == UInt8(scalar >> 8)
            end
        end
    end
end
