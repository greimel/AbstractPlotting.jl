### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# ╔═╡ b914f3b4-4890-11eb-34c6-09003e4a51ef
using CairoMakie, DataFrames

# ╔═╡ 51852efc-4850-11eb-029c-bdbf99b70e6b
using CategoricalArrays, DataAPI

# ╔═╡ 31bbfa64-4851-11eb-37b7-b924d9cdd664
using Underscores

# ╔═╡ 1809b3a6-4845-11eb-356a-97bd0f6e5fc8
md"""
## Grouped bar plots
"""

# ╔═╡ f4cceca4-484a-11eb-240a-7551df7e4892
begin
	x_gap = 0.1
	dodge_gap = 0.03
end

# ╔═╡ e4dfa75c-484d-11eb-18b0-fdef31f65d0a
gross_width(x_gap) = (1 - x_gap)

# ╔═╡ 6f900122-484d-11eb-1698-4580c9bd3842
width(x_gap, dodge_gap, n_dodge) = (gross_width(x_gap) - n_dodge * dodge_gap) / n_dodge

# ╔═╡ 96c259ca-484d-11eb-3d9b-8df2346c9ff7
function shift_dodge(i, x_gap, dodge_gap, n_dodge)
	wdt = width(x_gap, dodge_gap, n_dodge)
	
	- (1/2) + (i-1)*(wdt + dodge_gap) + (0.5 * (wdt + x_gap + dodge_gap))
end

# ╔═╡ f5ad80e4-484e-11eb-27e7-fda141b65216
bar_df = let
	n_dodge = 2
	n_x = 2
	n_stack = 2
	n = n_dodge * n_x * n_stack
	
	grp_dodge = ["dodge $i" for i in 1:n_dodge]
	grp_x     = ["x $i"     for i in 1: n_x]
	grp_stack = ["stack $i" for i in 1:n_stack]
	
	df = Iterators.product(grp_dodge, grp_x, grp_stack) |> DataFrame
	cols = [:grp_dodge, :grp_x, :grp_stack]
	rename!(df, cols)
	transform!(df, cols .=> categorical .=> cols)
	
	df[:,:y] = rand(n)
	df
end

# ╔═╡ ab00201a-4850-11eb-3573-f9fa7be32c22
bar_df0 = begin
	dodge_i = bar_df.grp_dodge.refs .|> Int
	stack_i = bar_df.grp_stack.refs .|> Int
	x_i     = bar_df.grp_x.refs .|> Int
	y       = bar_df.y
	
	DataFrame(dodge_i = dodge_i,
		      stack_i = stack_i,
		      x_i = x_i,
		      y = y
		)
end

# ╔═╡ 81034f3c-4851-11eb-28f7-35b2e9484491
from_val(y) = [zero(eltype(y)); cumsum(y)[begin:end-1]]

# ╔═╡ a9849af6-4851-11eb-24dc-01723cc1eb35
to_val(y) = cumsum(y)

# ╔═╡ 2c820b7e-4851-11eb-2f56-3d727883f55a
# add from and to
bar_df1 = @_ bar_df0 |> 
    sort(__, :stack_i) |>
	groupby(__, [:dodge_i, :x_i]) |>
    transform(__, :y => from_val => :from,
				  :y => to_val => :to)
 

# ╔═╡ 85df4d3e-4898-11eb-28cf-03e6c7273dee
begin
	n_x = length(levels(bar_df.grp_x))
	n_dodge = length(unique(bar_df.grp_dodge))
	x_labels = levels(bar_df.grp_x)
	wdt = width(x_gap, dodge_gap, n_dodge)
end

# ╔═╡ 0ba88794-4850-11eb-20fd-cdf0a1cad316
df1 = let
	shft = shift_dodge.(1:n_dodge, x_gap, dodge_gap, n_dodge)
	
	bar_df2 = @_ bar_df1 |>
	    transform(__, [:x_i, :dodge_i] => ByRow((x,d) -> x + shft[d]) => :x_pos)
	
	bar_df2
end;

# ╔═╡ 92972f92-487a-11eb-255b-b7e8d3529ce6
let
	scene, layout = layoutscene()
	ax1 = layout[1,1] = LAxis(scene)
	
	barplot!(ax1, df1.x_pos, df1.to, fillto=df1.from, width = wdt, color = df1.stack_i)
	
	ax1.xticks = (1:n_x, x_labels)
	scene
end

# ╔═╡ 2557bba8-4899-11eb-0777-4d43c33d1f6c


# ╔═╡ Cell order:
# ╠═b914f3b4-4890-11eb-34c6-09003e4a51ef
# ╟─1809b3a6-4845-11eb-356a-97bd0f6e5fc8
# ╠═92972f92-487a-11eb-255b-b7e8d3529ce6
# ╠═f4cceca4-484a-11eb-240a-7551df7e4892
# ╠═e4dfa75c-484d-11eb-18b0-fdef31f65d0a
# ╠═6f900122-484d-11eb-1698-4580c9bd3842
# ╠═96c259ca-484d-11eb-3d9b-8df2346c9ff7
# ╠═f5ad80e4-484e-11eb-27e7-fda141b65216
# ╠═51852efc-4850-11eb-029c-bdbf99b70e6b
# ╠═ab00201a-4850-11eb-3573-f9fa7be32c22
# ╠═31bbfa64-4851-11eb-37b7-b924d9cdd664
# ╠═81034f3c-4851-11eb-28f7-35b2e9484491
# ╠═a9849af6-4851-11eb-24dc-01723cc1eb35
# ╠═2c820b7e-4851-11eb-2f56-3d727883f55a
# ╠═0ba88794-4850-11eb-20fd-cdf0a1cad316
# ╠═85df4d3e-4898-11eb-28cf-03e6c7273dee
# ╠═2557bba8-4899-11eb-0777-4d43c33d1f6c
