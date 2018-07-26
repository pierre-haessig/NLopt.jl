__precompile__()

module NLopt

export Opt, NLOPT_VERSION, algorithm, algorithm_name, ForcedStop,
       lower_bounds!, lower_bounds, upper_bounds!, upper_bounds, stopval!, stopval, ftol_rel!, ftol_rel, ftol_abs!, ftol_abs, xtol_rel!, xtol_rel, xtol_abs!, xtol_abs, maxeval!, maxeval, maxtime!, maxtime, force_stop!, force_stop, force_stop!, population!, population, vector_storage!, vector_storage, initial_step!, initial_step, default_initial_step!, local_optimizer!,
       min_objective!, max_objective!, equality_constraint!, inequality_constraint!, remove_constraints!,
       optimize!, optimize

import Base.ndims, Base.copy, Base.convert, Base.show

import MathProgBase.SolverInterface
import MathProgBase.SolverInterface.optimize!

import Libdl
const depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")
if isfile(depfile)
    include(depfile)
else
    error("NLopt not properly installed. Please run Pkg.build(\"NLopt\")")
end

############################################################################
# separate initializations that must occur at runtime, for precompilation

function __init__()
    # get the version of NLopt at runtime, not compile time
    global NLOPT_VERSION = version()
end

############################################################################
# Mirrors of NLopt's C enum constants:

# enum nlopt_algorithm
const GN_DIRECT = Cint(0)
const GN_DIRECT_L = Cint(1)
const GN_DIRECT_L_RAND = Cint(2)
const GN_DIRECT_NOSCAL = Cint(3)
const GN_DIRECT_L_NOSCAL = Cint(4)
const GN_DIRECT_L_RAND_NOSCAL = Cint(5)
const GN_ORIG_DIRECT = Cint(6)
const GN_ORIG_DIRECT_L = Cint(7)
const GD_STOGO = Cint(8)
const GD_STOGO_RAND = Cint(9)
const LD_LBFGS_NOCEDAL = Cint(10)
const LD_LBFGS = Cint(11)
const LN_PRAXIS = Cint(12)
const LD_VAR1 = Cint(13)
const LD_VAR2 = Cint(14)
const LD_TNEWTON = Cint(15)
const LD_TNEWTON_RESTART = Cint(16)
const LD_TNEWTON_PRECOND = Cint(17)
const LD_TNEWTON_PRECOND_RESTART = Cint(18)
const GN_CRS2_LM = Cint(19)
const GN_MLSL = Cint(20)
const GD_MLSL = Cint(21)
const GN_MLSL_LDS = Cint(22)
const GD_MLSL_LDS = Cint(23)
const LD_MMA = Cint(24)
const LN_COBYLA = Cint(25)
const LN_NEWUOA = Cint(26)
const LN_NEWUOA_BOUND = Cint(27)
const LN_NELDERMEAD = Cint(28)
const LN_SBPLX = Cint(29)
const LN_AUGLAG = Cint(30)
const LD_AUGLAG = Cint(31)
const LN_AUGLAG_EQ = Cint(32)
const LD_AUGLAG_EQ = Cint(33)
const LN_BOBYQA = Cint(34)
const GN_ISRES = Cint(35)
const AUGLAG = Cint(36)
const AUGLAG_EQ = Cint(37)
const G_MLSL = Cint(38)
const G_MLSL_LDS = Cint(39)
const LD_SLSQP = Cint(40)
const LD_CCSAQ = Cint(41)
const GN_ESCH = Cint(42)
const NUM_ALGORITHMS = 43

const alg2int = Dict{Symbol,Cint}(:GN_DIRECT=>GN_DIRECT, :GN_DIRECT_L=>GN_DIRECT_L, :GN_DIRECT_L_RAND=>GN_DIRECT_L_RAND, :GN_DIRECT_NOSCAL=>GN_DIRECT_NOSCAL, :GN_DIRECT_L_NOSCAL=>GN_DIRECT_L_NOSCAL, :GN_DIRECT_L_RAND_NOSCAL=>GN_DIRECT_L_RAND_NOSCAL, :GN_ORIG_DIRECT=>GN_ORIG_DIRECT, :GN_ORIG_DIRECT_L=>GN_ORIG_DIRECT_L, :GD_STOGO=>GD_STOGO, :GD_STOGO_RAND=>GD_STOGO_RAND, :LD_LBFGS_NOCEDAL=>LD_LBFGS_NOCEDAL, :LD_LBFGS=>LD_LBFGS, :LN_PRAXIS=>LN_PRAXIS, :LD_VAR1=>LD_VAR1, :LD_VAR2=>LD_VAR2, :LD_TNEWTON=>LD_TNEWTON, :LD_TNEWTON_RESTART=>LD_TNEWTON_RESTART, :LD_TNEWTON_PRECOND=>LD_TNEWTON_PRECOND, :LD_TNEWTON_PRECOND_RESTART=>LD_TNEWTON_PRECOND_RESTART, :GN_CRS2_LM=>GN_CRS2_LM, :GN_MLSL=>GN_MLSL, :GD_MLSL=>GD_MLSL, :GN_MLSL_LDS=>GN_MLSL_LDS, :GD_MLSL_LDS=>GD_MLSL_LDS, :LD_MMA=>LD_MMA, :LN_COBYLA=>LN_COBYLA, :LN_NEWUOA=>LN_NEWUOA, :LN_NEWUOA_BOUND=>LN_NEWUOA_BOUND, :LN_NELDERMEAD=>LN_NELDERMEAD, :LN_SBPLX=>LN_SBPLX, :LN_AUGLAG=>LN_AUGLAG, :LD_AUGLAG=>LD_AUGLAG, :LN_AUGLAG_EQ=>LN_AUGLAG_EQ, :LD_AUGLAG_EQ=>LD_AUGLAG_EQ, :LN_BOBYQA=>LN_BOBYQA, :GN_ISRES=>GN_ISRES, :AUGLAG=>AUGLAG, :AUGLAG_EQ=>AUGLAG_EQ, :G_MLSL=>G_MLSL, :G_MLSL_LDS=>G_MLSL_LDS, :LD_SLSQP=>LD_SLSQP, :LD_CCSAQ=>LD_CCSAQ, :GN_ESCH=>GN_ESCH)
const int2alg = Dict{Cint,Symbol}(alg2int[k]=>k for k in keys(alg2int))

# enum nlopt_result
const FAILURE = Cint(-1)
const INVALID_ARGS = Cint(-2)
const OUT_OF_MEMORY = Cint(-3)
const ROUNDOFF_LIMITED = Cint(-4)
const FORCED_STOP = Cint(-5)
const SUCCESS = Cint(1)
const STOPVAL_REACHED = Cint(2)
const FTOL_REACHED = Cint(3)
const XTOL_REACHED = Cint(4)
const MAXEVAL_REACHED = Cint(5)
const MAXTIME_REACHED = Cint(6)

const res2sym = Dict{Cint,Symbol}(FAILURE=>:FAILURE, INVALID_ARGS=>:INVALID_ARGS, OUT_OF_MEMORY=>:OUT_OF_MEMORY, ROUNDOFF_LIMITED=>:ROUNDOFF_LIMITED, FORCED_STOP=>:FORCED_STOP, SUCCESS=>:SUCCESS, STOPVAL_REACHED=>:STOPVAL_REACHED, FTOL_REACHED=>:FTOL_REACHED, XTOL_REACHED=>:XTOL_REACHED, MAXEVAL_REACHED=>:MAXEVAL_REACHED, MAXTIME_REACHED=>:MAXTIME_REACHED)

############################################################################
# wrapper around nlopt_opt type

const _Opt = Ptr{Cvoid} # nlopt_opt

# pass both f and o to the callback so that we can handle exceptions
struct Callback_Data
    f::Function
    o::Any # should be Opt, but see Julia issue #269
end

mutable struct Opt
    opt::_Opt

    # need to store callback data for objective and constraints in
    # Opt so that they aren't garbage-collected.  cb[1] is the objective.
    cb::Vector{Callback_Data}

    function Opt(p::_Opt)
        opt = new(p, Array{Callback_Data}(undef,1))
        finalizer(destroy,opt)
        opt
    end
    function Opt(algorithm::Integer, n::Integer)
        if algorithm < 0 || algorithm > NUM_ALGORITHMS
            throw(ArgumentError("invalid algorithm $algorithm"))
        elseif n < 0
            throw(ArgumentError("invalid dimension $n < 0"))
        end
        p = ccall((:nlopt_create,libnlopt), _Opt, (Cint, Cuint),
                  algorithm, n)
        if p == C_NULL
            error("Error in nlopt_create")
        end
        Opt(p)
    end
    Opt(algorithm::Symbol, n::Integer) = Opt(try alg2int[algorithm]
                                             catch
                         throw(ArgumentError("unknown algorithm $algorithm"))
                                             end, n)
end

Base.unsafe_convert(::Type{_Opt}, o::Opt) = o.opt # for passing to ccall

destroy(o::Opt) = ccall((:nlopt_destroy,libnlopt), Cvoid, (_Opt,), o)

ndims(o::Opt) = Int(ccall((:nlopt_get_dimension,libnlopt), Cuint, (_Opt,), o))
algorithm(o::Opt) = int2alg[ccall((:nlopt_get_algorithm,libnlopt),
                                  Cint, (_Opt,), o)]

show(io::IO, o::Opt) = print(io, "Opt(:$(algorithm(o)), $(ndims(o)))")

############################################################################
# copying is a little tricky because we have to tell NLopt to use
# new Callback_Data.

# callback wrapper for nlopt_munge_data in NLopt 2.4
function munge_callback(p::Ptr{Cvoid}, f_::Ptr{Cvoid})
    f = unsafe_pointer_to_objref(f_)::Function
    f(p)::Ptr{Cvoid}
end

function copy(o::Opt)
    p = ccall((:nlopt_copy,libnlopt), _Opt, (_Opt,), o)
    if p == C_NULL
        error("Error in nlopt_copy")
    end
    n = Opt(p)

    n.cb = similar(o.cb)
    for i = 1:length(o.cb)
        try
            n.cb[i] = Callback_Data(o.cb[i].f, n)
        catch e
            # if objective has not been set, o.cb[1] will throw
            # an UndefRefError, which is okay.
            if i != 1 || !isa(e, UndefRefError)
                rethrow(e) # some not-okay exception
            end
        end
    end

    try
        # n.o, for each callback, stores a pointer to an element of o.cb,
        # and we need to convert this into a pointer to the corresponding
        # element of n.cb.  nlopt_munge_data allows us to call a function
        # to transform each stored pointer in n.o, and we use the cbi
        # dictionary to convert pointers to indices into o.cb, whence
        # we obtain the corresponding element of n.cb.
        cbi = Dict{Ptr{Cvoid},Int}()
        for i in 1:length(o.cb)
            try
                cbi[pointer_from_objref(o.cb[i])] = i
            catch
            end
        end
        munge_callback_ptr = @cfunction(munge_callback, Ptr{Cvoid},
                                        (Ptr{Cvoid}, Ptr{Cvoid}))
        ccall((:nlopt_munge_data,libnlopt), Cvoid, (_Opt, Ptr{Cvoid}, Any),
              n, munge_callback_ptr,
              p::Ptr{Cvoid} -> p==C_NULL ? C_NULL :
                              pointer_from_objref(n.cb[cbi[p]]))
    catch e0
        # nlopt_munge_data not available, punt unless there is
        # no callback data
        try
            o.cb[1]
        catch e
            if length(o.cb) == 1 && isa(e, UndefRefError)
                return n
            end
        end
        error("copy(o::Opt) not supported for NLopt version < 2.4")
    end

    return n
end

############################################################################
# converting error results into exceptions

struct ForcedStop <: Exception end

# cache current exception for forced stop
nlopt_exception = nothing

# check result and throw an exception if necessary
function chk(result::Integer)
    if result < 0 && result != ROUNDOFF_LIMITED
        if result == INVALID_ARGS
            throw(ArgumentError("invalid NLopt arguments"))
        elseif result == OUT_OF_MEMORY
            throw(OutOfMemoryError())
        elseif result == FORCED_STOP
            global nlopt_exception
            e = nlopt_exception
            if e != nothing && !isa(e, ForcedStop)
                nlopt_exception = nothing
                rethrow(e)
            end
        else
            error("nlopt failure: $result")
        end
    end
    result
end

chks(result::Integer) = res2sym[chk(result)]
chkn(result::Integer) = begin chk(result); nothing; end

############################################################################
# getting and setting scalar and vector parameters

# make a quoted symbol expression out of the arguments
qsym(args...) = Expr(:quote, Symbol(string(args...)))

# scalar parameters p of type T
macro GETSET(T, p)
    Tg = T == :Cdouble ? :Real : (T == :Cint || T == :Cuint ? :Integer : :Any)
    ps = Symbol(string(p, "!"))
    quote
        $(esc(p))(o::Opt) = ccall(($(qsym("nlopt_get_", p)),libnlopt),
                                  $T, (_Opt,), o)
        $(esc(ps))(o::Opt, val::$Tg) =
          chkn(ccall(($(qsym("nlopt_set_", p)),libnlopt),
                     Cint, (_Opt, $T), o, val))
    end
end

# Vector{Cdouble} parameters p
macro GETSET_VEC(p)
    ps = Symbol(string(p, "!"))
    quote
        function $(esc(p))(o::Opt, v::Vector{Cdouble})
            if length(v) != ndims(o)
                throw(BoundsError())
            end
            chk(ccall(($(qsym("nlopt_get_", p)),libnlopt),
                      Cint, (_Opt, Ptr{Cdouble}), o, v))
            v
        end
        $(esc(p))(o::Opt) = $(esc(p))(o, Array{Cdouble}(undef, ndims(o)))
        function $(esc(ps))(o::Opt, v::Vector{Cdouble})
            if length(v) != ndims(o)
                throw(BoundsError())
            end
            chkn(ccall(($(qsym("nlopt_set_", p)),libnlopt),
                      Cint, (_Opt, Ptr{Cdouble}), o, v))
        end
        $(esc(ps))(o::Opt, v::AbstractVector{<:Real}) =
          $(esc(ps))(o, Array{Cdouble}(v))
        $(esc(ps))(o::Opt, val::Real) =
          chkn(ccall(($(qsym("nlopt_set_", p, "1")),libnlopt),
                     Cint, (_Opt, Cdouble), o, val))
    end
end

############################################################################
# Optimizer parameters

@GETSET_VEC lower_bounds
@GETSET_VEC upper_bounds
@GETSET Cdouble stopval
@GETSET Cdouble ftol_rel
@GETSET Cdouble ftol_abs
@GETSET Cdouble xtol_rel
@GETSET_VEC xtol_abs
@GETSET Cint maxeval
@GETSET Cdouble maxtime
@GETSET Cint force_stop
@GETSET Cuint population
@GETSET Cuint vector_storage

force_stop!(o::Opt) = force_stop!(o, 1)

local_optimizer!(o::Opt, lo::Opt) =
  chkn(ccall((:nlopt_set_local_optimizer,libnlopt),
             Cint, (_Opt, _Opt), o, lo))

# the initial-stepsize stuff is a bit different than GETSET_VEC,
# since the heuristics depend on the position x.

function default_initial_step!(o::Opt, x::Vector{Cdouble})
    if length(x) != ndims(o)
        throw(BoundsError())
    end
    chkn(ccall((:nlopt_set_default_initial_step,libnlopt),
               Cint, (_Opt, Ptr{Cdouble}), o, x))
end
default_initial_step!(o::Opt, x::AbstractVector{<:Real}) =
  default_initial_step!(o, Array{Cdouble}(x))

function initial_step!(o::Opt, dx::Vector{Cdouble})
    if length(dx) != ndims(o)
        throw(BoundsError())
    end
    chkn(ccall((:nlopt_set_initial_step,libnlopt),
               Cint, (_Opt, Ptr{Cdouble}), o, dx))
end
initial_step!(o::Opt, dx::AbstractVector{<:Real}) =
  initial_step!(o, Array{Cdouble}(dx))
initial_step!(o::Opt, dx::Real) =
  chkn(ccall((:nlopt_set_initial_step1,libnlopt),
             Cint, (_Opt, Cdouble), o, dx))

function initial_step(o::Opt, x::Vector{Cdouble}, dx::Vector{Cdouble})
    if length(x) != ndims(o) || length(dx) != ndims(o)
        throw(BoundsError())
    end
    chkn(ccall((:nlopt_get_initial_step,libnlopt),
               Cint, (_Opt, Ptr{Cdouble}, Ptr{Cdouble}), o, x, dx))
    dx
end
initial_step(o::Opt, x::AbstractVector{<:Real}) =
    initial_step(o, Array{Cdouble}(x),
                 Array{Cdouble}(undef, ndims(o)))

############################################################################

function algorithm_name(a::Integer)
    s = ccall((:nlopt_algorithm_name,libnlopt), Ptr{UInt8}, (Cint,), a)
    if s == C_NULL
        throw(ArgumentError("invalid algorithm $a"))
    end
    return String(s)
end

algorithm_name(a::Symbol) = algorithm_name(try alg2int[a]
                                           catch
                             throw(ArgumentError("unknown algorithm $a"))
                                           end)
algorithm_name(o::Opt) = algorithm_name(algorithm(o))

############################################################################

function version()
    v = Array{Cint}(undef,3)
    pv = pointer(v)
    ccall((:nlopt_version,libnlopt), Cvoid, (Ptr{Cint},Ptr{Cint},Ptr{Cint}),
          pv, pv + sizeof(Cint), pv + 2*sizeof(Cint))
    VersionNumber(convert(Int, v[1]),convert(Int, v[2]),convert(Int, v[3]))
end

############################################################################

srand(seed::Integer) = ccall((:nlopt_srand,libnlopt),
                             Cvoid, (Culong,), seed)
srand_time() = ccall((:nlopt_srand_time,libnlopt), Cvoid, ())

############################################################################
# Objective function:

const empty_grad = Cdouble[] # for passing when grad == C_NULL

function nlopt_callback_wrapper(n::Cuint, x::Ptr{Cdouble},
                                grad::Ptr{Cdouble}, d_::Ptr{Cvoid})
    d = unsafe_pointer_to_objref(d_)::Callback_Data
    try
        res = convert(Cdouble,
                      d.f(unsafe_wrap(Array, x, (convert(Int, n),)),
                          grad == C_NULL ? empty_grad
                          : unsafe_wrap(Array, grad, (convert(Int, n),))))
        return res::Cdouble
    catch e
        global nlopt_exception
        nlopt_exception = e
        println("in callback catch")
        force_stop!(d.o::Opt)
        return 0.0 # ignored by nlopt
    end
end

for m in (:min, :max)
    mf = Symbol(string(m,"_objective!"))
    @eval function $mf(o::Opt, f::Function)
        o.cb[1] = Callback_Data(f, o)
        nlopt_callback_wrapper_ptr = @cfunction(nlopt_callback_wrapper,
            Cdouble, (Cuint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
        chkn(ccall(($(qsym("nlopt_set_", m, "_objective")),libnlopt),
                   Cint, (_Opt, Ptr{Cvoid}, Any),
                   o, nlopt_callback_wrapper_ptr,
                   o.cb[1]))
    end
end

############################################################################
# Nonlinear constraints:

for c in (:inequality, :equality)
    cf = Symbol(string(c, "_constraint!"))
    @eval function $cf(o::Opt, f::Function, tol::Real)
        push!(o.cb, Callback_Data(f, o))
        nlopt_callback_wrapper_ptr = @cfunction(nlopt_callback_wrapper,
            Cdouble, (Cuint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
        chkn(ccall(($(qsym("nlopt_add_", c, "_constraint")),libnlopt),
                   Cint, (_Opt, Ptr{Cvoid}, Any, Cdouble),
                   o, nlopt_callback_wrapper_ptr,
                   o.cb[end], tol))
    end
    @eval $cf(o::Opt, f::Function) = $cf(o, f, 0.0)
end

function remove_constraints!(o::Opt)
    resize!(o.cb, 1)
    chkn(ccall((:nlopt_remove_inequality_constraints,libnlopt),
               Cint, (_Opt,), o))
    chkn(ccall((:nlopt_remove_equality_constraints,libnlopt),
               Cint, (_Opt,), o))
end

############################################################################
# Vector-valued constraints


const empty_jac = Array{Cdouble}(undef,0,0) # for passing when grad == C_NULL

function nlopt_vcallback_wrapper(m::Cuint, res::Ptr{Cdouble},
                                 n::Cuint, x::Ptr{Cdouble},
                                 grad::Ptr{Cdouble}, d_::Ptr{Cvoid})
    d = unsafe_pointer_to_objref(d_)::Callback_Data
    try
        d.f(unsafe_wrap(Array, res, (convert(Int, m),)),
            unsafe_wrap(Array, x, (convert(Int, n),)),
            grad == C_NULL ? empty_jac
            : unsafe_wrap(Array, grad, (convert(Int, n),convert(Int, m))))
    catch e
        global nlopt_exception
        nlopt_exception = e
        force_stop!(d.o::Opt)
    end
    nothing
end

for c in (:inequality, :equality)
    cf = Symbol(string(c, "_constraint!"))
    @eval begin
        function $cf(o::Opt, f::Function, tol::Vector{Cdouble})
            push!(o.cb, Callback_Data(f, o))
            nlopt_vcallback_wrapper_ptr = @cfunction(nlopt_vcallback_wrapper, Cvoid,
                  (Cuint, Ptr{Cdouble}, Cuint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
            chkn(ccall(($(qsym("nlopt_add_", c, "_mconstraint")),
                        libnlopt),
                       Cint, (_Opt, Cuint, Ptr{Cvoid}, Any, Ptr{Cdouble}),
                       o, length(tol), nlopt_vcallback_wrapper_ptr,
                       o.cb[end], tol))
        end
        $cf(o::Opt, f::Function, tol::AbstractVector{<:Real}) =
           $cf(o, f, Array{Float64}(tol))
        $cf(o::Opt, m::Integer, f::Function, tol::Real) =
           $cf(o, f, fill!(Cdouble(tol), m))
        $cf(o::Opt, m::Integer, f::Function)=
           $cf(o, m, f, 0.0)
    end
end

############################################################################
# Perform the optimization:

function optimize!(o::Opt, x::Vector{Cdouble})
    if length(x) != ndims(o)
        throw(BoundsError())
    end
    opt_f = Array{Cdouble}(undef,1)
    ret = ccall((:nlopt_optimize,libnlopt), Cint, (_Opt, Ptr{Cdouble},
                                                     Ptr{Cdouble}),
                o, x, opt_f)
    return (opt_f[1], x, chks(ret))
end

optimize(o::Opt, x::AbstractVector{<:Real}) =
  optimize!(o, copyto!(Array{Cdouble}(undef,length(x)), x))

############################################################################

include("NLoptSolverInterface.jl")


end # module
