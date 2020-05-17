local player_to_id_text = {} -- Storage of players so the mod knows what huds to update
local player_to_cnode = {} -- Get the current looked at node
local player_to_enabled = {} -- Enable/disable item display

local ypos = 0.9
local xpos = 0.45

minetest.register_globalstep(function(dtime) -- This will run every tick, so around 20 times/second
    for _, player in ipairs(minetest:get_connected_players()) do -- Do everything below for each player in-game
        if player_to_enabled[player] == nil then player_to_enabled[player] = true end -- Enable by default
        if not player_to_enabled[player] then return end -- Don't do anything if they have it disabled
        local lookat = get_looking_node(player) -- Get the node they're looking at


        if lookat then 
            if player_to_cnode[player] ~= lookat.name then -- Only do anything if they are looking at a different type of block than before
                local nodename = describe_node(lookat) -- Get the details of the block in a nice looking way
                player:hud_change(player_to_id_text[player], "text", nodename) -- If they are looking at something, display that
                local node_object = minetest.registered_nodes[lookat.name] -- Get information about the block
            end
            player_to_cnode[player] = lookat.name -- Update the current node
        else
            blank_player_hud(player) -- If they are not looking at anything, do not display the text
            player_to_cnode[player] = nil -- Update the current node
        end

    end
end)

minetest.register_on_joinplayer(function(player) -- Add the hud to all players
    player_to_id_text[player] = player:hud_add({ -- Add the block name text
        hud_elem_type = "text",
        text = "test",
        number = 0xffffff,
        alignment = {x = 1, y = 0},
        position = {x = xpos, y = ypos},
    })
end)


minetest.register_chatcommand("item-display", { -- Command to turn item display on or off
	params = "<on/off>",
	description = "Turn Item Display on or off",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
        player_to_enabled[player] = param == "on"
        blank_player_hud(player)
        player_to_cnode[player] = nil
        return true
	end
})

function get_looking_node(player) -- Return the node the given player is looking at or nil
    local lookat
    for i = 0, 2 do -- 10 is the maximum distance you can point to things in creative mode by default, using 2 to only display nearby items
        local lookvector = -- This variable will store what node we might be looking at
            vector.add( -- This add function corrects for the players approximate height
                vector.add( -- This add function applies the camera's position to the look vector
                    vector.multiply( -- This multiply function adjusts the distance from the camera by the iteration of the loop we're in
                        player:get_look_dir(), 
                        i -- Goes from 0 to 10
                    ), 
                    player:get_pos()
                ),
                vector.new(0, 1.5, 0)
            )
        lookat = minetest.get_node_or_nil( -- This actually gets the node we might be looking at
            lookvector
        ) or lookat
        if lookat ~= nil and lookat.name ~= "air" and lookat.name ~= "walking_light:light" then break else lookat = nil end -- If we *are* looking at something, stop the loop and continue
    end
    return lookat
end


function describe_node(node) 
    local nodename = minetest.registered_nodes[node.name].description 
    if nodename == "" then -- If it doesn't have a proper name, just use the technical one
        nodename = node.name
    end
    nodename = capitalize(nodename):gsub("[_-]", " ") 
    return nodename
end


function capitalize(str) -- Capitalize every word in a string, looks good for node names
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end


function update_player_hud_pos(player, to_x, to_y) -- Change position of hud elements
    to_y = to_y or ypos
    player:hud_change(player_to_id_text[player], "position", {x = to_x, y = to_y})
end

function blank_player_hud(player) -- Make hud appear blank
    player:hud_change(player_to_id_text[player], "text", "")
end
