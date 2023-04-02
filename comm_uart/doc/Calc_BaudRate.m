clc;clear all;close all;

clk=100e6;
baud_rate=5e6;
baud_freq=16*baud_rate/gcd(clk,16*baud_rate)
baud_limit=clk/gcd(clk,16*baud_rate)-baud_freq
hex_baud_freq=dec2hex(baud_freq)
hex_baud_limit=dec2hex(baud_limit)