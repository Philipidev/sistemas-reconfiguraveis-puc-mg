# Load the Quartus environment
package require ::quartus::project

# Set the current project and design
project_open RegBank

# Compile the project
execute_flow -compile

# Start ModelSim for simulation
project_start_simulation -tool=modelsim

# Now, commands for ModelSim to setup and run the simulation
# These commands are sent to the ModelSim console

# Compile all files
vlib work
vcom -93 +acc -work work $quartus(qip_path)/RegBank.vhd
vcom -93 +acc -work work $quartus(qip_path)/RegBank_tb.vhd

# Load the simulation
vsim work.RegBank_tb

# Add signals to the waveform
add wave -position end /*
add wave -position end /RegBank_tb/*

# Run the simulation for a specified time
run 100us

# Save the waveform in a desired format, e.g., WLF (Waveform Save File)
wave save RegBank.wlf

# If you want the GUI to stay open
# View the waveform in ModelSim
view wave
