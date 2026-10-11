# BaseWars
BaseWars is a gamemode all about printing and raiding. Build your own base to print tons of money while fighting off enemies trying to raid you!

This project is a refactor of the original BaseWars gamemode. Its goal is to provide cleaner, better optimized code that uses modern Garry's Mod and GLua APIs and takes advantage of their newer features, while staying compatible with current addons and preserving the original gameplay.

## Features

* Easy to setup!
* Easy to configure!
* Crashes recover lost player money!
* Progression via a configurable leveling system!
* Automated anti-spawnkill!
* Automated raiding, no more 'random raids'!
* Built-in textscreens!
* Custom language support!
* Easy to use entity bases!

## What's changed

* Replaced the old player data (tmysql/SQLite) in favor of [goobie-sql](https://github.com/Srlion/goobie-sql)
* Switched to [Srlion's Hook Library](https://github.com/Srlion/Hook-Library) and its hook priorities
* Removed EasyLua
* Removed the old qchat
* A lot of optimizations

This refactor is intended for a fresh database. Please do not try to import data from your old BaseWars gamemode unless you know what you're doing.

## Installation

### Prerequisites
* A CPPI compliant prop-protection addon.
* A fading door addon.
* A MySQL database.
* A [goobie-sql release](https://github.com/Srlion/goobie-sql/releases) compatible with your Garry's Mod branch.
* [Srlion's Hook Library](https://steamcommunity.com/sharedfiles/filedetails/?id=1907060869), installed through your server's Workshop collection.

### Installing the gamemode
* Drag the folder into ```garrysmod/gamemodes```.
* Edit ```garrysmod/gamemodes/basewars/gamemode/config.lua``` to your own liking.
* Download `goobie-sql.lua` into `gamemode/server/thirdparty/goobie-sql.lua`. Install its matching `gmsv_goobie_mysql` binary in `garrysmod/lua/bin`.
* Add [Srlion's Hook Library](https://steamcommunity.com/sharedfiles/filedetails/?id=1907060869) to your server's Workshop collection.
* Set the host, port, user, password, and database in `gamemode/server/mysql.lua`. The database must already exist; BaseWars creates its own tables. Use an account with table creation and read/write permissions.

The default weapon configuration uses Customizable Weaponry 2.0. You can change `gamemode/config.lua` if your server uses different weapons.

## Screenshots

### Help Menu
![ScreenShot](http://puu.sh/mALs7/ad13259bff.jpg)
### Main Menu
![ScreenShot](http://puu.sh/mALv7/eefc81fe95.jpg)
### Entities
![ScreenShot](http://puu.sh/mALDK/b199a75830.jpg)
### Textscreens
![ScreenShot](http://puu.sh/mAOmT/370b971f4f.jpg)

## Authors
**Main Developer:** [Callum J. Slaney](mailto:q2f2@hexahedron.pw)
**Developer:** [Andrew Austin](mailto:ghosty.hexahedronic@gmail.com)
**Developer:** [Stepan Fedotov](mailto:admin@futuretechs.eu)
**Developer:** [Ling](mailto:ling@hexahedron.pw)
