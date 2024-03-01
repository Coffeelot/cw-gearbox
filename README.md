# cw-gearbox
Add manual gearing to you vehicles. 

Default buttons are R and Q, so you might need to rebind some stuff or change these.

### Key Features:

- Manual Gear Controls: Take full control of your vehicle's gears, enhancing realism and immersion.
- Gear skipping
- Efficient Resource Management: Minimize resource consumption for optimal client performance. Running at a 0.0ms resmon on idle and a 0.02ms when driving a manual
- Clutch Simulation: Experience authentic clutch engagement, adding depth to your driving interactions.
- Synchronized Gear Changes
- Support for oxlib and QBcore (for notifications and keybind)

> ❗ Hot tip:  Read the damn readme and config before reporting issues

> "b-b-b but Coffee, I use ESX on my server will this work?". No. But I'm pretty sure it will if you change those like two lines using QBCore in client.lua. 

## Comes ready for [CW-Tuning](https://cw-scripts.tebex.io/package/5987879) transmissions
Check the Config for `UseOtherCheck` if you want to implement another script for swappable transmissions
> As of the release of this. CW-Tuning also recieved an update (see our Discord for patch notes)

# Showcase

[Youtube Link](https://www.youtube.com/watch?v=UTnGFwetMfo) 🎬

# Links
### ⭐ Check out our [Tebex store](https://cw-scripts.tebex.io/category/2523396) for some cheap scripts ⭐
### 🥳 Get more [Free scripts](https://github.com/stars/Coffeelot/lists/cw-scripts) 🥳

### **Support, updates and script previews**:

[![Join The discord!](https://cdn.discordapp.com/attachments/977876510620909579/1013102122985857064/discordJoin.png)](https://discord.gg/FJY4mtjaKr )

# Limitations
- Limited to the vehicles original amount of gears (no extra from upgrade for example)
- Doesn't work well with gears over 5
- Doesn't handle gear ratios, only uses default ones
- Tested on game build 3095, not sure what older ones it works on
- This script in itself doesn't add any transmission swapping. You need to enable it in the vehicle handling files if you do not use something like [CW-Tuning](https://cw-scripts.tebex.io/package/5987879)
- **Can _not_ be** applied to vehicles that do not already have the `strAdvancedFlags` in it's handling.meta file
- Only tested with OxLib for keybind, but has code for basic keybinds also
- Supports oxlib or qbcore for notify (legit one line to change if you want something else tho)

# Adding the flag manually
**This does take some handling.meta know-how.** You need to add the CF_GEARBOX_MANUAL flag (or in bit: 400)

> One example of a working Advanced Flag is 4000400 

[This tool](https://adam10603.github.io/GTA5VehicleFlagTool/) is great for modifying existing flags, you want this flag enabled:

![this](https://media.discordapp.net/attachments/1206659469258264576/1211080190231453868/image.png?ex=65ece552&is=65da7052&hm=793e951de62930c6a1d28fb8ce945fc94b2c4b33714baeac349b15b8e31ab71a&=&format=webp&quality=lossless&width=792&height=291)

One example of the SubHandlingData for a vehicle with the flag enabled:
```xml
			<SubHandlingData>
			  <Item type="CCarHandlingData">
				<strAdvancedFlags>400</strAdvancedFlags>
			  </Item>
			  <Item type="NULL" />
			  <Item type="NULL" />
			</SubHandlingData>
```