# Script to analyse the results for the simulated timesteps in the DC grid overlay project
using JSON

##########################################################################
# Read time series file
res_filename = "./test_cases/DC_overlay_grid_RES_1_8760.json"
res = JSON.parsefile(res_filename)

load_filename = "./test_cases/DC_overlay_grid_Demand_1_8760.json"
load = JSON.parsefile(load_filename)

# Read test case file
grid_filename = "./test_cases/DC_overlay_grid.json"
grid = JSON.parsefile(grid_filename)

# Adding name to the branches
for (br_id,br) in grid["branch"]
    br["name"] = "AC_L_$(br["f_bus"])$(br["t_bus"])"
end
for (br_id,br) in grid["branchdc"]
    br["name"] = "DC_L_$(br["fbusdc"])$(br["tbusdc"])"
end

# Read results file
output_filename = "./results/OPF_results_selected_timesteps_DCPPowerModel.json"
results = JSON.parsefile(output_filename)
##########################################################################

#2723 -> MIN onshore wind
#6311 -> MIN RES
#6541 -> MIN Load/RES
#476  -> MAX Load/RES
#2511 -> MIN offshore wind
#1125 -> MAX demand

obj = [results[i]["objective"] for i in eachindex(results)]


# Max load/RES
ac_branch_flow = [[results["476"]["solution"]["branch"][i]["pt"],grid["branch"][i]["name"]] for i in eachindex(results["476"]["solution"]["branch"])]
dc_branch_flow = [[results["476"]["solution"]["branchdc"][i]["pt"],grid["branchdc"][i]["name"]] for i in eachindex(results["476"]["solution"]["branchdc"])]
gen = [[results["476"]["solution"]["gen"][i]["pg"],grid["gen"][i]["name"]] for i in eachindex(results["476"]["solution"]["gen"]) if results["476"]["solution"]["gen"][i]["pg"] != 0.0]
load_timestep = [[load[i][476],i] for i in eachindex(load)]
total_load_timestep = sum(load_timestep[i][1] for i in 1:length(load_timestep))

# Min Load/RES
ac_branch_flow = [[results["6541"]["solution"]["branch"][i]["pt"],grid["branch"][i]["name"]] for i in eachindex(results["6541"]["solution"]["branch"])]
dc_branch_flow = [[results["6541"]["solution"]["branchdc"][i]["pt"],grid["branchdc"][i]["name"]] for i in eachindex(results["6541"]["solution"]["branchdc"])]
gen = [[results["6541"]["solution"]["gen"][i]["pg"],grid["gen"][i]["name"]] for i in eachindex(results["6541"]["solution"]["gen"]) if results["6541"]["solution"]["gen"][i]["pg"] != 0.0]
load_timestep = [[load[i][6541],i] for i in eachindex(load)]
total_load_timestep = sum(load_timestep[i][1] for i in 1:length(load_timestep))