include("eca.jl")

export ECARule, Lattice1D, apply, apply!, shift_left, shift_right


struct Lattice1D{T<:Integer,VA<:AbstractArray{T}}
    cells::VA
    N::Int
end

function Lattice1D(N::Integer)
    ncells = cld(N, 64)
    cells = Vector{UInt64}(undef, ncells)
    return Lattice1D(cells, N)
end

Base.similar(x::Lattice1D{T, VA}) where {T, VA} = Lattice1D{T, VA}(similar(x.cells), x.N)

@inline function shift_left(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    n = length(x.cells)
    prev = i > 1 ? i - 1 : n
    shift = prev == n ? x.N - (n - 1) * bpw - 1 : bpw - 1
    return x.cells[i] << 1 | x.cells[prev] >> shift
end

@inline function shift_left_interior(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    return x.cells[i] << 1 | x.cells[i-1] >> (bpw - 1)
end

@inline function shift_right(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    n = length(x.cells)
    next = i < n ? i + 1 : 1
    shift = i == n ? x.N - (n - 1) * bpw - 1 : bpw - 1
    return x.cells[i] >> 1 | (x.cells[next] & one(T)) << shift
end

@inline function shift_right_interior(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    return x.cells[i] >> 1 | (x.cells[i+1] & one(T)) << (bpw - 1)
end

function apply(rule::ECARule, x::Lattice1D{T}) where {T}
    y = similar(x)
    for i in eachindex(x.cells)
        l = needs_left(rule) ? shift_left(x, i) : zero(T)
        c = needs_center(rule) ? x.cells[i] : zero(T)
        r = needs_right(rule) ? shift_right(x, i) : zero(T)

        y.cells[i] = _apply_rule(rule, l, c, r)
    end
    return y
end
function apply!(target::Lattice1D{T}, rule::ECARule{R, N}, x::Lattice1D{T}) where {R, N, T}
    @assert length(target.cells) == length(x.cells)
    @assert target.N == x.N
    n = length(x.cells)

    # Boundary elements: shift_left/shift_right handle wrap-around
    for i in (1, n)
        l = needs_left(rule) ? shift_left(x, i) : zero(T)
        c = needs_center(rule) ? x.cells[i] : zero(T)
        r = needs_right(rule) ? shift_right(x, i) : zero(T)
        @inbounds target.cells[i] = _apply_rule(rule, l, c, r)
    end

    # Interior: uniform operations with no boundary branches — SIMD vectorizable
    @inbounds @simd for i in 2:n-1
        l = needs_left(rule) ? shift_left_interior(x, i) : zero(T)
        c = needs_center(rule) ? x.cells[i] : zero(T)
        r = needs_right(rule) ? shift_right_interior(x, i) : zero(T)
        target.cells[i] = _apply_rule(rule, l, c, r)
    end
    return target
end

