#!/bin/bash
rm -rf .vvp .vcd

iverilog -g2012 -o sim.vvp -f $1.f
vvp sim.vvp
