name = "Rabbit Wheel"
version = "0.1.0"
description = "Version " .. version .. "\n\n Adds the rabbit wheel to your game! Only Winona may use it."
author = "s1m13"

api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

icon_atlas = "rabbitwheel.xml"
icon = "rabbitwheel.tex"

-- forumthread = "/topic/xxx-abc/"

all_clients_require_mod = true
client_only_mod = false
server_filter_tags = { "winona" }


configuration_options =
{
    -- {
    --     name = "poop_amount",
    --     label = "Poop amount",
    --     options = {
    --         { description = "Low", data = "low" },
    --         { description = "Default", data = "default" },
    --         { description = "High", data = "high" },
    --     },
    --     default = "default",
    -- },

    -- {
    --     name = "compost_duration",
    --     label = "Compost duration",
    --     options = {
    --         { description = "Realistic", data = "realistic" },
    --         { description = "Default", data = "default" },
    --         { description = "Efficient", data = "efficient" },
    --     },
    --     default = "default",
    -- },

    -- {
    --     name = "cost",
    --     label = "Cost",
    --     options = {
    --         { description = "Low", data = "low" },
    --         { description = "Default", data = "default" },
    --         { description = "High", data = "high" },
    --     },
    --     default = "default",
    -- },

    -- {
    --     name = "fertile_soil_advantage",
    --     label = "Fertile soil advantage",
    --     options = {
    --         { description = "Low", data = "low" },
    --         { description = "Default", data = "default" },
    --         { description = "High", data = "high" },
    --     },
    --     default = "default",
    -- },

    -- {
    --     name = "spawn_fireflies",
    --     label = "Attract Fireflies",
    --     options = {
    --         { description = "Always", data = "always" },
    --         { description = "On", data = "on" },
    --         { description = "Off", data = "off" },
    --     },
    --     default = "on",
    -- },
}
