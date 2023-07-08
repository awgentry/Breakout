--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Adapted from Ball Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu
   
    UPDATE:
    Handles creation and movement of a powerup that falls from the
    middle of the screen to be caught by the paddle.    
    
    Author: Adam Gentry
    6/22/23
    -add Powerup object, copied from Ball
    -powerups defined by "type": (9) multiball, (10) key
    -add powerup icon to top right when active
    
    7/2/23
    -choose random powerup
     
]]




Powerup = Class{}

function Powerup:init(type)
    -- simple positional and dimensional variables
    self.width = 8
    self.height = 8

    -- set starting position
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 4 - 2
    
    -- set velocity - static to start
    self.dy = 0
    self.dx = 0
    
    
	-- first instance is random - future instances change in "playState.lua"
	local rnd = math.random(9, 10) -- 9 is multiball, 10 is key
	self.type = rnd
  

    self.inPlay = false       -- draw powerup if true
    self.active = false	    -- NEW: starts when caught by paddle
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball 1/4 down the middle of the screen.
]]
function Powerup:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 4 - 2
    self.dx = 0
    self.dy = 0
end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    
end


function Powerup:render()
	if self.inPlay == true then						-- type: 9 is multiball, 10 is key
		love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type], self.x, self.y)
	end
	if self.active == true then
		-- NEW: draw powerup at 50% size near top right
		love.graphics.push()  -- new temp canvas
		love.graphics.scale(0.5, 0.5)  
		
		if unlocked == 1 then
			love.graphics.draw(gTextures['main'], gFrames['powerups'][10], (VIRTUAL_WIDTH-120)*2, 10)  -- shows key icon - *2 because temp canvas is half size
		end
		if numBalls > 1 then
			love.graphics.draw(gTextures['main'], gFrames['powerups'][9], (VIRTUAL_WIDTH-130)*2, 10)  -- shows multiball icon
		end
		
		love.graphics.pop()   -- back to normal size   				
		
	end
	
	-- NEW: show powerup stats
	local yNum = math.floor(self.y+0.5)
	love.graphics.print('Powerup: x:' .. tostring(self.x) .. ', y: ' .. tostring(yNum) .. ', dx:' .. tostring(self.dx) .. ', dy: ' .. tostring(self.dy), 5, 225)
	
end




