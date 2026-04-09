include("eca.jl")

export ECARule, Lattice1D, apply, apply!, shift_left, shift_right


struct Lattice1D{T<:Integer,VA<:AbstractArray{T}}
    cells::VA
    N::Int
end

Base.similar(x::Lattice1D{T, VA}) where {T, VA} = Lattice1D{T, VA}(similar(x.cells), x.N)

function shift_left(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    n = length(x.cells)
    prev = i > 1 ? i - 1 : n
    shift = prev == n ? x.N - (n - 1) * bpw - 1 : bpw - 1
    return x.cells[i] << 1 | x.cells[prev] >> shift
end

function shift_right(x::Lattice1D{T}, i::Int) where T
    bpw = 8 * sizeof(T)
    n = length(x.cells)
    next = i < n ? i + 1 : 1
    shift = i == n ? x.N - (n - 1) * bpw - 1 : bpw - 1
    return x.cells[i] >> 1 | (x.cells[next] & one(T)) << shift
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
    
    @inbounds for i in eachindex(x.cells)
        l = needs_left(rule) ? shift_left(x, i) : zero(T)
        c = needs_center(rule) ? x.cells[i] : zero(T)
        r = needs_right(rule) ? shift_right(x, i) : zero(T)

        target.cells[i] = _apply_rule(rule, l, c, r)
    end
    return target
end

