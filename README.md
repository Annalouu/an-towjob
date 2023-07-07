# an-towjob
- Original is qb-towjob
- Towing Job For QB-Core

# Video
- https://youtu.be/XChrYQYJiuo

# Installaion
- If You Use Qb-Phone ( Renewed Phone ) then make Config.reqTow = true other wise false

Add This If You Enabled Config.reqTow
```lua
	["requestTow"] = {
        bones = {
            "seat_dside_f",
        },
        options = {
            {
                type = "client",
                event = "tow:requestTow",
                icon = "fas fa-truck",
                label = "Request Tow",
            },
        },
        distance = 4.0
    },
```

Like This : 
![code-snapshot](https://github.com/FzzyYT69/an-towjob/assets/99145322/2b4f4ff2-3d89-4c4b-b6e9-5e674f6f76ed)

# Feats

- All interactions has been moved to be integrated inside the script.
- Utilize of qb-target/ox_target (you don't have to change nothing)
- Much simplier and everything is in the Config.
- Added a slamtruck to the existing flatbed
- Added support for qb/gks/qs phones (notifications/emails)
- Tow Request System (Requirements : https://github.com/Renewed-Scripts/qb-phone ) Credit Goes To PineappleOnMyPizza For Providing Tow Request System

# Installation 

- Drag and drop to your resource folder
- ensure an-towjob
- Setjob ID tow 0
- Enjoy

# dependency 
- qb-core
- qb-target
- qb/qs/gks phone
- cdn-fuel/ps-fuel/cdn-fuel (in the config)

# Questions:
- Q: The Npc cars aren't spawning after i restarted the script
- A: You need to setjob yourself after each script restart, since it will need to update your job within itself and it needs to be able to read your job.
