module Counters

export Counter, counter, clean!, incr!, mean, csv_print

import Base: show, length, getindex, sum, keys, (+), (==), hash
import Base: showall, setindex!, nnz, mean, collect, start, done, next

"""
A `Counter` is a device for keeping a count of how often we observe
various objects. It is created by giving a type such as
`c=Counter{String}()`.

Counts are retrieved with square brackets like a dictionary: `c["hello"]`.
It is safe to retrieve the count of an object never encountered, e.g.,
`c["goodbye"]`; in this case `0` is returned.

Counts may be assigned with `c[key]=amount`, but the more likely use
case is using `c[key]+=1` to count each time `key` is encountered.
"""
type Counter{T<:Any} <: Associative{T,Int}
  data::Dict{T,Int}
  function Counter()
    d = Dict{T,Int}()
    C = new(d)
  end
end

Counter() = Counter{Any}()

# These items enable this to satisfy the Associative properties

start(c::Counter) = start(c.data)
done(c::Counter,s) = done(c.data,s)
next(c::Counter,s) = next(c.data,s)

"""
`length(c::Counter)` gives the number of entries monitored
by the Counter. Conceivably, some may have value `0`.
"""
length(c::Counter) = length(c.data)

function show{T}(io::IO, c::Counter{T})
  n = length(c.data)
  word = ifelse(n==1, "entry", "entries")
  msg = "with $n $word"
  print(io,"Counter{$T} $msg")
end

"""
`showall(c::Counter)` displays all the objects
held in the Counter and their counts.
"""
function showall{T}(io::IO, c::Counter{T})
  println(io,"Counter{$T} with these nonzero values:")
  klist = collect(keys(c))
  try
    sort!(klist)
  end

  for k in klist
    if c[k] != 0
      println(io,"$k ==> $(c.data[k])")
    end
  end
end

function getindex{T}(c::Counter{T}, x::T)
  return get(c.data,x,0)
end

"""
`keys(c::Counter)` returns an interator for the things counted by `c`.
"""
keys(c::Counter) = keys(c.data)


"""
`sum(c::Counter)` gives the total of the counts for all things
in `c`.
"""
sum(c::Counter) = sum(values(c.data))

"""
`nnz(c::Counter)` gives the number of keys in
the `Counter` with nonzero value.
"""
function nnz(c::Counter)
  amt::Int = 0
  for k in keys(c)
    if c.data[k] != 0
      amt += 1
    end
  end
  return amt
end

setindex!{T}(c::Counter{T}, val::Int, k::T) = c.data[k] = val>0 ? val : 0

function =={T}(c::Counter{T}, d::Counter{T})
  for k in keys(c)
    if c[k] != d[k]
      return false
    end
  end

  for k in keys(d)
    if c[k] != d[k]
      return false
    end
  end

  return true
end

isequal{T}(c::Counter{T},d::Counter{T}) = c==d

"""
`clean!(c)` removes all keys from `c` whose value is `0`.
Generally, it's not necessary to invoke this unless one
suspects that `c` contains *a lot* of keys associated with
a zero value.
"""
function clean!{T}(c::Counter{T})
  for k in keys(c)
    if c[k] == 0
      delete!(c.data,k)
    end
  end
  nothing
end

"""
`incr!(c,x)` increments the count for `x` by 1. This is equivalent to
`c[x]+=1`.

`incr!(c,items)` is more useful. Here `items` is an iterable collection
of keys and we increment the count for each element in `items`.

`incr!(c,d)` where `c` and `d` are counters will increment `c` by
the amounts held in `d`.
"""
incr!{T}(c::Counter{T}, x::T) = c[x] += 1

function incr!(c::Counter, items)
  for x in items
    c[x] += 1
  end
end

function incr!{T}(c::Counter{T},d::Counter{T})
  for k in keys(d)
    c[k] += d[k]
  end
end


"""
If `c` and `d` are `Counter`s, then `c+d` creates a new `Counter`
in which the count associated with an object `x` is `c[x]+d[x]`.
"""
function (+){T}(c::Counter{T}, d::Counter{T})
  result = deepcopy(c)
  incr!(result,d)
  return result
end

"""
`collect(C)` for a `Counter` returns an array containing the elements of `C`
each repeated according to its multiplicty.
"""
function collect{T}(c::Counter{T})
  result = Vector{T}(sum(c))
  idx = 0
  for k in keys(c)
    m = c[k]
    for j=1:m
      idx += 1
      result[idx] = k
    end
  end
  return result
end



"""
`mean(C::Counter)` computes the weighted average of the objects in `C`.
Of course, the counted objects must be a `Number`; their multiplicity
(weight) in the average is determined by their `C`-value.
"""
function mean{T<:Number}(C::Counter{T})
  total = zero(T)
  for k in keys(C)
    total += k * C[k]
  end
  return total / sum(C)
end

"""
`csv_print(C::Counter)` prints out `C` in a manner suitable for import into
a spreadsheet.
"""
function csv_print(C::Counter)
  klist = collect(keys(C))
  try
    sort!(klist)
  end
  for k in klist
    println("$k, $(C[k])")
  end
  nothing
end

"""
`counter(list)` creates a `Counter` whose elements are the
members of `list` with the appropriate multiplicities.
This may also be used if `list` is a `Set` or an `IntSet`
(in which case multiplicities will all be 1).
"""
function counter(list::AbstractArray)
  T = eltype(list)
  C = Counter{T}()
  for x in list
    incr!(C,x)
  end
  return C
end

counter(S::Base.AbstractSet) = counter(collect(S))


"""
Performing `hash` on a `Counter` will first apply `clean!` to the
`Counter` in order that equal `Counter` objects hash the same.
"""
function hash(C::Counter, h::UInt64 = UInt64(0))
    clean!(C)
    return hash(C.data,h)
end

end # module
