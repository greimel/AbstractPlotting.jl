"""
    barplot(x, y; kwargs...)

Plots a barplot; `y` defines the height.  `x` and `y` should be 1 dimensional.

## Attributes
$(ATTRIBUTES)
"""
@recipe(BarPlot, x, y) do scene
    Attributes(;
        fillto = automatic,
        color = theme(scene, :color),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        dodge = automatic,
        x_gap = 0.1,
        dodge_gap = 0.03,
        marker = Rect,
        stack = automatic,
        strokewidth = 0,
        strokecolor = :white,
        width = automatic,
        direction = :y,
        visible = theme(scene, :visible),
    )
end

conversion_trait(::Type{<: BarPlot}) = PointBased()

function bar_rectangle(x, y, width, fillto)
    # y could be smaller than fillto...
    ymin = min(fillto, y)
    ymax = max(fillto, y)
    w = abs(width)
    return FRect(x - (w / 2f0), ymin, w, ymax - ymin)
end

flip(r::Rect2D) = Rect2D(reverse(origin(r)), reverse(widths(r)))

using DataAPI: refarray, levels
import DataFrames

function AbstractPlotting.plot!(p::BarPlot)

    in_y_direction = lift(p.direction) do dir
        if dir == :y
            true
        elseif dir == :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    bars = lift(p[1], p.fillto, p.width, p.dodge, p.x_gap, p.dodge_gap, p.stack, in_y_direction) do xy, fillto, width, dodge, x_gap, dodge_gap, stack, in_y_direction
      
        #
        if dodge === automatic
            n_dodge = 1
        else
            n_dodge = length(levels(dodge))
            @show n_dodge
        end
        
        x = first.(xy)
        y = last.(xy)
        
        # compute half-width of bars
        if width === automatic
            # times 0.8 for default gap
            width = mean(diff(sort(unique(x)))) # TODO ignore nan?
        end
        
        # --------------------------------
        # ------------ Dodging -----------
        # --------------------------------
        dodge_width = scale_width(x_gap, dodge_gap, n_dodge)

        if dodge === automatic
            i_dodge = 1
        else
            i_dodge = refarray(dodge)
            @assert eltype(i_dodge) <: Integer
            # This is satisfied if dodge isa PooledArray, CategoricalArray or Vector{<:Integer}
        end
        
        shft = shift_dodge.(1:n_dodge, x_gap, dodge_gap, n_dodge)

        # --------------------------------
        # ----------- Stacking -----------
        # --------------------------------

        if stack === automatic
            if fillto === automatic
                fillto = 0.0
            end
        else
            fillto === automatic || @warn "Ignore keyword fillto when keyword stack is provided"
            i_stack = refarray(stack)
            @assert eltype(i_dodge) <: Integer
            # This is satisfied if dodge isa PooledArray, CategoricalArray or Vector{<:Integer}
            
            tmp_df = DataFrames.DataFrame(x = x, y = y, i_stack = i_stack, i_dodge = i_dodge, order = 1:length(x))
            sort!(tmp_df, [:i_stack])
            
            DataFrames.groupby(tmp_df, [:i_dodge, :x]) |>
                df -> DataFrames.transform!(df, :y => from_val => :from,
                                                :y => to_val => :to)
              
            sort!(tmp_df, :order)
            
            y = tmp_df.to
            fillto = tmp_df.from
        end
        
        rects = bar_rectangle.(x .+ width .* shft[i_dodge], y, width .* dodge_width, fillto)
        return in_y_direction ? rects : flip.(rects)
    end

    poly!(
        p, bars, color = p.color, colormap = p.colormap, colorrange = p.colorrange,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor, visible = p.visible
    )
end

scale_width(x_gap, dodge_gap, n_dodge) = ((1 - x_gap) - n_dodge * dodge_gap) / n_dodge

function shift_dodge(i, x_gap, dodge_gap, n_dodge)
    wdt = scale_width(x_gap, dodge_gap, n_dodge)

    - (1/2) + (i-1)*(wdt + dodge_gap) + (0.5 * (wdt + x_gap + dodge_gap))
end

to_val(y) = cumsum(y)

from_val(y) = [zero(eltype(y)); cumsum(y)[begin:end-1]]