-- ********************
-- Settings
local display_y_position = 0.9 -- Y screen position of the display
local display_x_position = 0.45 -- X screen position of the display
local display_distance = 2 -- Distance from the player before the display shows up. Maximum 10.
local update_interval = 0.15 -- How often to update the display, lower numbers are more responsive.
-- ********************

local player_to_id_text = {} -- Storage of players so the mod knows what huds to update
local player_to_cnode = {} -- Get the current looked at node
local player_to_enabled = {} -- Enable/disable item display
local update_time = 0 -- Used for the update interval
local modname = minetest.get_current_modname() -- Used for importing functions via dofile

dofile(minetest.get_modpath(modname).."/functions.lua")


minetest.register_globalstep(function(dtime) -- This will run every tick, so around 20 times/second
	update_time = update_time + dtime
	if update_time < update_interval then
		return
	else
		update_time = 0
	end
    
	-- Do everything below for each player in-game
    for _, player in ipairs(minetest:get_connected_players()) do 
        if not is_id_enabled(player) then return end
        
        local lookat = get_looking_node(player, display_distance)
        if lookat then 
            -- Only do anything if the player is looking at a different type of block than before
            if player_to_cnode[player] ~= lookat.name then
                -- Get the details of the block in a nice looking way
                local nodename = get_node_name(lookat)
                -- If player is looking at something, display the name
                player:hud_change(player_to_id_text[player], "text", nodename)
                -- Get the node
                local node_object = minetest.registered_nodes[lookat.name]
            end
            player_to_cnode[player] = lookat.name -- Update the current node
        else
            -- If player is not looking at anything, do not display the text
            blank_player_hud(player)
            -- Update the current node
            player_to_cnode[player] = nil
        end

    end
end)


-- Add the hud to all players
minetest.register_on_joinplayer(function(player)
    -- Add the block name text 
    player_to_id_text[player] = player:hud_add({
        hud_elem_type = "text",
        text = "",
        number = 0xffffff,
        alignment = {x = 1, y = 0},
        position = {x = display_x_position, y = display_y_position},
    })
end)


-- Command to toggle item display on or off
minetest.register_chatcommand("id", { 
	params = "",
	description = "Toggle Item Display on or off",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)

		if not player then return false end
        item_disp = is_id_enabled(player)
        
        if is_id_enabled(player) == false then
            player_to_enabled[player] = true
            player_meta:set_int("item_display", 0)
            set_id_enabled(player, true)
            minetest.chat_send_player(name, core.colorize("#66ff00","Item display enabled."))
        else
            player_to_enabled[player] = false
            blank_player_hud(player)
            player_to_cnode[player] = nil
            set_id_enabled(player, false)
            minetest.chat_send_player(name, core.colorize("#66ff00", "Item display disabled."))        
        end
        
        return true
	end
})


-- Change position of hud elements
function update_player_hud_pos(player, to_x, to_y) 
    to_y = to_y or display_y_position
    player:hud_change(player_to_id_text[player], "position", {x = to_x, y = to_y})
end


-- Clear the display hud
function blank_player_hud(player) 
    player:hud_change(player_to_id_text[player], "text", "")
end
