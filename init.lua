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
        
        local lookat = get_looking_node(player)
        if lookat then 
            if player_to_cnode[player] ~= lookat.name then -- Only do anything if they are looking at a different type of block than before
                local nodename = get_node_name(lookat) -- Get the details of the block in a nice looking way
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


function is_id_enabled(player)
    player_meta = player:get_meta()
    if player_meta:get_int("item_display") == 0 then
        return true
    end
    
    return false  
end


function set_id_enabled(player, enabled)
    player_meta = player:get_meta()
    if enabled == true then
        player_meta:set_int("item_display", 0)
    else
        player_meta:set_int("item_display", -1)
    end
end


function get_looking_node(player) -- Return the node the given player is looking at or nil
    local lookat
    for distance = 0, display_distance do
        -- lookvector stores what node we might be looking at    
        local lookvector = 
            -- Add function corrects for the players approximate height
            vector.add( 
                -- Add function applies the camera's position to the look vector            
                vector.add( 
					-- Multiply function adjusts the distance from the camera by the iteration of the loop we're in				
                    vector.multiply(player:get_look_dir(), distance), 
					player:get_pos()
                ),
                vector.new(0, 1.5, 0)
            )
        -- Get the node the player is looking at
        lookat = minetest.get_node_or_nil(lookvector) or lookat
        
        if lookat ~= nil and lookat.name ~= "air" and lookat.name ~= "walking_light:light" then break else lookat = nil end -- If we *are* looking at something, stop the loop and continue
    end
    return lookat
end


-- Returns the name of a node, or "" if name cannot be determined
function get_node_name(node) 
    -- Check this in case node is unknown and does not have a description
	if minetest.registered_nodes[node.name] == nil then
	    return ""
	end
	
    local nodename = minetest.registered_nodes[node.name].description 
	
    -- If it doesn't have a proper name, just use the technical one
    if nodename == "" then 
        nodename = node.name
    end
    
	-- Capitalize the node name
	nodename = string.gsub(" "..nodename, "%W%l", string.upper):sub(2)
	-- Replace - and _ in the node name with spaces
    nodename = nodename:gsub("[_-]", " ") 
    -- Replace newlines with commas so that the text doesn't overlap with the hud below it
    nodename = nodename:gsub("\n", ", ") 
    return nodename
end


-- Change position of hud elements
function update_player_hud_pos(player, to_x, to_y) 
    to_y = to_y or display_y_position
    player:hud_change(player_to_id_text[player], "position", {x = to_x, y = to_y})
end


-- Clear the display hud
function blank_player_hud(player) 
    player:hud_change(player_to_id_text[player], "text", "")
end
