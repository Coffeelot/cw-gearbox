Config = {}

Config.Debug = false
Config.OxLib = true -- set to true if you use Oxlib, will otherwise default to QBcore

Config.CwTuning = true -- Set to true if you use CW tuning and want to use that scripts gearbox swaps
Config.UseOtherCheck = false -- set to true and add your code to client.lua. Search for "ADD YOUR CHECK HERE" in the file

Config.ClutchTime = 300 -- value / clutchChangeRate As standard, GTA uses 900 for this value but I found that lower values works better. Higher means slower gearing.

Config.Keys = {
    gearUp = 'R',
    gearDown = 'Q'
}