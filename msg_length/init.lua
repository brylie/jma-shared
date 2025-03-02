-- Message Length Module
-- Handles limiting chat message length

local mod_storage = minetest.get_mod_storage()

msg_length = {
    max_length = 1024 -- Default max message length
}

-- Initialize max length from mod storage if available
if mod_storage:contains("message_max_length") then
    msg_length.max_length = tonumber(mod_storage:get_string("message_max_length")) or msg_length.max_length
end

-- Function to set the maximum message length
function msg_length.set_max_length(length)
    msg_length.max_length = tonumber(length) or msg_length.max_length
    mod_storage:set_string("message_max_length", tostring(msg_length.max_length))
    return msg_length.max_length
end

-- Function to get the current maximum message length
function msg_length.get_max_length()
    return msg_length.max_length
end

-- Check if a message is too long
-- Returns true if the message is valid (not too long)
function msg_length.check_message(message)
        if type(message) ~= "string" then
        return false
    end
    
    return #message <= msg_length.max_length
    end

-- Function to mute a player for sending a message that's too long
function msg_length.mute_player(name, message)
    local duration = 1 -- 1 minute mute duration
    
    minetest.chat_send_all(name .. " has been temporarily muted for sending a message that is too long.")
    minetest.chat_send_player(name, "Your message was too long. Maximum allowed length is " .. 
        msg_length.max_length .. " characters.")
    
    xban.mute_player(name, "msg_length", os.time() + (duration*60), 
        "Message too long: " .. #message .. " characters (maximum: " .. msg_length.max_length .. ")")
        
    minetest.log("action", "[msg_length] Player " .. name .. " muted for message length violation. " ..
        "Message length: " .. #message .. ", Max allowed: " .. msg_length.max_length)
end

-- Define the chat message handler function separately for better readability
local function on_player_chat_message(name, message)
    -- Ignore commands (messages starting with '/')
    if message:sub(1, 1) == "/" then
        return
    end
    
    -- Check if the message is valid (not too long)
    local is_message_valid = msg_length.check_message(message)
    
    -- If message is too long, mute the player and cancel the message
    if not is_message_valid then
        msg_length.mute_player(name, message)
        return true -- Cancel the message
    end
    
    -- Message is valid, allow it to be processed by other handlers
    return false
end

-- Insert this check after xban checks whether the player is muted (position 2 in the handlers list)
table.insert(minetest.registered_on_chat_messages, 2, on_player_chat_message)

-- Register a command to manage max message length
minetest.register_chatcommand("message_max_length", {
    description = "Get or set the maximum message length",
    params = "[length]",
    privs = {server = true}, -- Requires server privilege to change
    func = function(name, param)
        if param and param ~= "" then
            local length = tonumber(param)
            if not length or length < 1 then
                return false, "Invalid length. Please provide a positive number."
            end
            
            local old_length = msg_length.max_length
            msg_length.set_max_length(length)
            
            minetest.log("action", name .. " changed max message length from " .. old_length .. " to " .. msg_length.max_length)
            return true, "Maximum message length changed from " .. old_length .. " to " .. msg_length.max_length
        else
            return true, "Current maximum message length: " .. msg_length.get_max_length()
        end
    end
})
