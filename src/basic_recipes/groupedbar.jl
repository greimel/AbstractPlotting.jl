using Pkg: @pkg_str
pkg"activate @groupedbar"
#pkg"add Revise"
pkg"dev ."
 
using Revise
using CairoMakie
using DataFrames
using Random: shuffle
using DataAPI: refarray

bar_df = let
	n_dodge = 2
	n_x = 3
	n_stack = 5
	n = n_dodge * n_x * n_stack
	
	grp_dodge = ["dodge $i" for i in 1:n_dodge]
	grp_x     = ["x $i"     for i in 1: n_x]
	grp_stack = ["stack $i" for i in 1:n_stack]
	
	df = Iterators.product(grp_dodge, grp_x, grp_stack) |> DataFrame
	cols = [:grp_dodge, :grp_x, :grp_stack]
	rename!(df, cols)
	transform!(df, cols .=> categorical .=> cols)
	
	cols_i = cols .|> string .|> x -> x[5:end]  .|> x -> x * "_i"
	transform!(df, cols .=> (x -> Int.(x.refs)) .=> cols_i)
	
	df[:,:y] = rand(n)
	#shuffle
	df = DataFrame(shuffle(eachrow(df)))
	df
end

bar1 = filter(:dodge_i => ==(1), bar_df)
bar2 = filter(:dodge_i => ==(2), bar_df)

scn = barplot(bar1.grp_x, bar1.y, dodge = bar1.grp_dodge, stack = bar1.grp_stack, color = refarray(bar1.grp_stack))

barplot!(scn, bar2.grp_x, bar2.y, dodge = bar2.grp_dodge, stack = bar2.grp_stack, color = refarray(bar2.grp_stack))

scn.plots[2].dodge
scn.plots

