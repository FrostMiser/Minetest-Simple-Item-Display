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


function get_looking_node(player, max_distance) -- Return the node the given player is looking at or nil
    local lookat
    for distance = 0, max_distance do
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
