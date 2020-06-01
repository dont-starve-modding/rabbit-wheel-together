name = "Rabbit Wheel"
version = "1.0.0"
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
    {
        name = "rabbit_lifetime",
        label = "Rabbit life expectancy",
        options = {
            { description = "Low", data = "low" },
            { description = "Default", data = "default" },
            { description = "High", data = "high" },
        },
        default = "default"
    },
    {
        name = "rabbit_perseverance",
        label = "Rabbit perseverance",
        options = {
            { description = "Low", data = "low" },
            { description = "Default", data = "default" },
            { description = "High", data = "high" },
        },
        default = "default"
    },
    {
        name = "rabbit_power",
        label = "Rabbit power",
        options = {
            { description = "Low", data = "low" },
            { description = "Default", data = "default" },
            { description = "High", data = "high" },
        },
        default = "default"
    },
    {
        name = "rabbit_wheel_costs",
        label = "Rabbit wheel costs",
        options = {
            { description = "Low", data = "low" },
            { description = "Default", data = "default" },
            { description = "High", data = "high" },
        },
        default = "default"
    },    
}
