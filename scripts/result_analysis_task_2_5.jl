using JSON
using JSON3
using CbaOPF
using Plots
using Makie
using LaTeXStrings

include("create_grid_and_opf_functions.jl")
include("processing_results_function.jl")

#########################################################################################################################
# One can choose the Pmax of the conv_power among 2.0, 4.0 and 8.0 GW
conv_power = 6.0
########################################################################
# Uploading test case
########################################################################
test_case_file = "DC_overlay_grid_$(conv_power)_GW_convdc.json"
test_case = _PM.parse_file("./test_cases/$test_case_file")

########################################################################
# Uploading results
########################################################################
results_file_ac = "/Users/giacomobastianel/.julia/dev/DCGridOverlay/results/result_one_year_AC_grid.json"
results_file_ac_dc = "/Users/giacomobastianel/.julia/dev/DCGridOverlay/results/result_one_year_AC_DC_grid.json"

results_AC = Dict()
open(results_file_ac, "r") do f
    global results_AC
    dicttxt = read(f,String)  # file information to string
    results_AC=JSON.parse(dicttxt)  # parse and transform data
end

results_AC_DC = Dict()
open(results_file_ac_dc, "r") do f
    global results_AC_DC
    dicttxt_ = read(f,String)  # file information to string
    results_AC_DC=JSON.parse(dicttxt_)  # parse and transform data
end

########################################################################
# Computing the total generation costs
########################################################################
obj_ac = sum(r["objective"]*100 for (r_id,r) in results_AC)
obj_ac_dc = sum(r["objective"]*100 for (r_id,r) in results_AC_DC)

benefit = (obj_ac - obj_ac_dc)/10^9

print("The total generation costs for the selected year for the AC/DC grid are $(obj_ac_dc/10^9) billions")
print("The total generation costs for the selected year for the AC grid are $(obj_ac/10^9) billions")
print("The total benefits for the selected year are $(benefit) billions")

########################################################################
# Computing VOLL for each hour
########################################################################
hourly_voll_ac = []
hourly_voll_ac_dc = []

compute_VOLL(test_case,8760,results_AC,hourly_voll_ac)
compute_VOLL(test_case,8760,results_AC_DC,hourly_voll_ac_dc)


print("The total load curtailment for the selected year for the AC/DC grid is $(sum(hourly_voll_ac_dc)) MWh")
print("The total load curtailment for the selected year for the AC grid is $(sum(hourly_voll_ac)) MWh")


########################################################################
# Computing CO2 emissions for each hour
########################################################################
# Adding and assigning generator values
gen_costs,inertia_constants,emission_factor_CO2,start_up_cost,emission_factor_NOx,emission_factor_SOx = gen_values()
assigning_gen_values(test_case)

hourly_CO2_ac = []
hourly_CO2_ac_dc = []

compute_CO2_emissions(test_case,8760,results_AC,hourly_CO2_ac)
compute_CO2_emissions(test_case,8760,results_AC_DC,hourly_CO2_ac_dc)

CO2_reduction = (sum(hourly_CO2_ac)-sum(hourly_CO2_ac_dc))/10^6 # Mton

print("The total CO2 emissions for the selected year for the AC/DC grid are $(sum(hourly_CO2_ac_dc)/10^6) Mton")
print("The total CO2 emissions for the selected year for the AC grid are $(sum(hourly_CO2_ac)/10^6) Mton")
print("The reduction of the CO2 emissions for the selected year are $(CO2_reduction) Mton")
########################################################################
# Computing RES generation for each hour
########################################################################
hourly_RES_ac = []
hourly_RES_ac_dc = []

compute_RES_generation(test_case,8760,results_AC,hourly_RES_ac)
compute_RES_generation(test_case,8760,results_AC_DC,hourly_RES_ac_dc)

RES_curtailment = (sum(hourly_RES_ac_dc)-sum(hourly_RES_ac)) # Wh

print("The total RES generation for the selected year for the AC/DC grid are $(sum(hourly_RES_ac_dc)/10^9) TWh")
print("The total RES generation for the selected year for the AC grid are $(sum(hourly_RES_ac)/10^9) TWh")
print("The curtailment of the RES generation for the selected year are $(RES_curtailment/10^6) MWh")

########################################################################
# Computing NOx emissions for each hour
########################################################################
hourly_NOx_ac = []
hourly_NOx_ac_dc = []

compute_NOx_emissions(test_case,8760,results_AC,hourly_NOx_ac)
compute_NOx_emissions(test_case,8760,results_AC_DC,hourly_NOx_ac_dc)

NOx_reduction = (sum(hourly_NOx_ac)-sum(hourly_NOx_ac_dc))/10^6 # Mton

print("The total NOx emissions for the selected year for the AC/DC grid are $(sum(hourly_NOx_ac_dc)/10^6) Mton")
print("The total NOx emissions for the selected year for the AC grid are $(sum(hourly_NOx_ac)/10^6) Mton")
print("The reduction of the NOx emissions for the selected year are $(NOx_reduction) Mton")

########################################################################
# Computing SOx emissions for each hour
########################################################################
hourly_SOx_ac = []
hourly_SOx_ac_dc = []

compute_SOx_emissions(test_case,8760,results_AC,hourly_SOx_ac)
compute_SOx_emissions(test_case,8760,results_AC_DC,hourly_SOx_ac_dc)

SOx_reduction = (sum(hourly_SOx_ac)-sum(hourly_SOx_ac_dc)) # Mton

print("The total SOx emissions for the selected year for the AC/DC grid are $(sum(hourly_SOx_ac_dc)/10^6) Mton")
print("The total SOx emissions for the selected year for the AC grid are $(sum(hourly_SOx_ac)/10^6) Mton")
print("The reduction of the SOx emissions for the selected year are $(SOx_reduction/10^6) Mton")

########################################################################
# Computing congestions for each hour
########################################################################
congested_lines_ac = []
congested_lines_ac_dc = []
branches_ac = Dict{String,Any}()
branches_ac_dc = Dict{String,Any}()

compute_congestions(test_case,8760,results_AC,congested_lines_ac,branches_ac)
compute_congestions(test_case,8760,results_AC_DC,congested_lines_ac_dc,branches_ac_dc)

congested_line_ac = Dict{String,Any}()
congested_line_ac_dc = Dict{String,Any}()

for i in 1:8760
    congested_line_ac["$i"] = Dict{String,Any}()
    congested_line_ac_dc["$i"] = Dict{String,Any}()
    congested_line_ac["$i"]["line"] = deepcopy(congested_lines_ac[i][1][1])
    congested_line_ac_dc["$i"]["line"] = deepcopy(congested_lines_ac_dc[i][1][1])
    congested_line_ac["$i"]["congestion"] = deepcopy(congested_lines_ac[i][1][2])
    congested_line_ac_dc["$i"]["congestion"] = deepcopy(congested_lines_ac_dc[i][1][2])
end

lines = []
for i in 1:8760
    push!(lines,parse(Int64,congested_line_ac["$i"]["line"]))
end

line_7_ac = Dict{String,Any}()
line_7_ac_dc = Dict{String,Any}()

compute_congestions_line_AC(test_case,8760,results_AC,line_7_ac,7)
compute_congestions_line_AC(test_case,8760,results_AC_DC,line_7_ac_dc,7)


for i in 1:8760
    push!(congestion_ac_7,line_7_ac["$i"])
    push!(congestion_ac_dc_7,line_7_ac_dc["$i"])
end

hourly_RES_ac_TWh = hourly_RES_ac/10^3 # TWh
hourly_RES_ac_dc_TWh =  hourly_RES_ac_dc/10^3 # TWh


# Line 6 is the most congested in this case
p1 = Plots.scatter(hourly_RES_ac_TWh, congestion_ac_7, legend=:none, mc=:blue, ms=2, ma=0.5,marker = :diamond,xlabel = "\$RES~generation~[TWh]\$",xguidefontsize=10,xtickfont = "Computer Modern",ylabel = "\$Branch~utilization\$",yguidefontsize=10,ytickfont = font(8,"Computer Modern"),ylims=[-1.1,1.1],xlims=[340,660])#,title = "Power flow through AC branch 3 for different RES levels, only AC grid",titlefont = font(10,"Computer Modern"))
p2 = Plots.scatter(hourly_RES_ac_dc_TWh, congestion_ac_dc_7, legend=:none, mc=:blue, ms=2, ma=0.5,marker = :diamond,xlabel = "\$RES~generation~[TWh]\$",xguidefontsize=10,xtickfont = "Computer Modern",ylabel = "\$Branch~utilization\$",yguidefontsize=10,ytickfont = font(8,"Computer Modern"),ylims=[-1.1,1.1],xlims=[340,660])#,title = "Power flow through AC branch 3 for different RES levels, AC/DC grid",titlefont = font(10,"Computer Modern"))

# AC/DC grid
congested_lines_hvdc = []
branches_hvdc = Dict{String,Any}()
compute_congestions_HVDC(test_case,8760,results_AC_DC,congested_lines_hvdc,branches_hvdc)

line_6_hvdc = Dict{String,Any}()
compute_congestions_line_HVDC(test_case,8760,results_AC_DC,line_6_hvdc,6)

congestion_6_hvdc = []
for i in 1:8760
    push!(congestion_6_hvdc,line_6_hvdc["$i"])
end

p3 = Plots.scatter(hourly_RES_ac_dc_TWh, congestion_6_hvdc, label="data", legend=:none, mc=:red, ms=2, ma=0.5,marker = :diamond,xlabel = "\$RES~generation~[TWh]\$",xguidefontsize=10,xtickfont = "Computer Modern",ytickfont = font(8,"Computer Modern"),ylabel = "\$Branch~utilization\$",ylims=[-1.1,1.1],xlims=[340,660])#,title = "Power flow through DC branch 6 for different RES levels, AC/DC grid",titlefont = font(10,"Computer Modern"))

p4 = Plots.plot(p2,p3,layout = (2,1))

#=
type = "AC_DC_AC_DC"
number = "3_6"
plot_filename = "$(dirname(@__DIR__))/results/figures/$(type)_branch_$(number).pdf"
Plots.savefig(p4, plot_filename)
=#

for (g_id,g) in test_case["gen"]
    if length(g["cost"]) > 0
        print(g["type"],"  ",g_id,"  ",g["cost"][1],"\n")
    else
        print(g["type"],"  ",g_id,"  0.0","\n")
    end
end

tot_ac = compute_energy_through_a_line(8760,results_AC,6,0)

TWh_ac = tot_ac*100/10^(3) # GWh

tot_ac_ac_dc = compute_energy_through_a_line(8760,results_AC_DC,6,0)
tot_dc_ac_dc = compute_energy_through_a_dc_line(8760,results_AC_DC,6,0)

TWh_ac_ac_dc = tot_ac_ac_dc*100/10^(3) # GWh
TWh_dc_ac_dc = tot_dc_ac_dc*100/10^(3) # GWh

