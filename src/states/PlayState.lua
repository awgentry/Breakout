--[[
	GD50
	Breakout Remake

	-- PlayState Class --

	Author: Colton Ogden
	cogden@cs50.harvard.edu

	Represents the state of the game in which we are actively playing;
	player should control the paddle, with the ball actively bouncing between
	the bricks, walls, and the paddle. If the ball goes below the paddle, then
	the player should lose one point of health and be taken either to the Game
	Over screen if at 0 health or the Serve screen otherwise.
	
	
	UPDATE
	Author: Adam Gentry
	6/24/23
	-add powerup - falls from middle, activated by hitting paddle
	-powerup: multiball 
		-when powerup activated, one ball splits into three
		-lose multiball - lose life when all three are gone
	-grow paddle every 1000 points
	-shrink paddle every life lost
	
	7/1/23
	-randomized powerup every X ticks - multiball or key
	-multiball powerup spawns 2 more balls
	
	7/4/23
	-no multiball powerup if already active (2+ balls)
	-no key powerup if already unlocked
	-no powerup shown if both powerups active - check next timer round
	
	7/6/23
	-don't increase score if locked brick hit when key powerup inactive
	
	
	
]]

PlayState = Class{__includes = BaseState}

--[[
	We initialize what's in our PlayState via a state table that we pass between
	states as we go from playing to serving.
]]
function PlayState:enter(params)
	self.paddle = params.paddle
	self.bricks = params.bricks
	self.health = params.health
	self.score = params.score
	self.highScores = params.highScores
	self.powerup = params.powerup
	self.level = params.level
	self.recoverPoints = 5000   -- get new life
	self.ball = Ball()
	self.ball.x = params.ballX
	self.ball.y = params.ballY
	self.ball.skin = params.skin
	
	debug = 0   -- NEW: 1 to display programmer statistics (ball location, etc.)
	
	-- ball(s) parameters
	numBalls = 1
	scoreCheck = 1000  -- NEW: grow paddle every 1000 points
	
	self.balls = {}   -- NEW: option for multiple balls, all in a table
	for b=1, numBalls do
		self.balls[b] = Ball()
		self.balls[b].x = self.ball.x -- params.VIRTUAL_WIDTH / 2 - 2
		self.balls[b].y = self.ball.y -- VIRTUAL_HEIGHT / 2 - 2
		self.balls[b].dx = math.random(-200, 200)
		self.balls[b].dy = math.random(-50, -60)
		self.balls[b].skin = self.ball.skin
	end
	
	-- NEW: powerups static and invisible to start
	self.powerup.dx = 0
	self.powerup.dy = 0
	
	-- NEW: track time elapsed; at max, display powerup
	powerTimer = 0      
	powerTimerMax = 500
	powerOn = 0   -- check if powerup is showing
	
	-- NEW: key powerup - if 1, locked bricks can become unlocked
	if unlocked == nil then unlocked = 2 end   -- NEW - 0 locked, 1 unlocked, 2 no lock bricks on level; if no locked brick created in "LevelMaker", no need for key powerup
	multi = 0
	
	
end

function PlayState:update(dt)
	if self.paused then
		if love.keyboard.wasPressed('space') then
			self.paused = false
			gSounds['pause']:play()
		else
			return
		end
	elseif love.keyboard.wasPressed('space') then
		self.paused = true
		gSounds['pause']:play()
		return
	end

	-- update positions based on velocity
	self.paddle:update(dt)
	
	for b=1, numBalls do	
		self.balls[b]:update(dt)
	end
	
	self.powerup:update(dt)
	
	for b=1, numBalls do	
		if self.balls[b]:collides(self.paddle) then
			-- raise ball above paddle in case it goes below it, then reverse dy
			self.balls[b].y = self.paddle.y - 8
			self.balls[b].dy = -self.balls[b].dy

			--
			-- tweak angle of bounce based on where it hits the paddle
			--

			-- if we hit the paddle on its left side while moving left...
			if self.balls[b].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
				self.balls[b].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.balls[b].x))
		
			-- else if we hit the paddle on its right side while moving right...
			elseif self.balls[b].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
				self.balls[b].dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.balls[b].x))
			end

			gSounds['paddle-hit']:play()
		end
	end

	-- powerup hits paddle
	if self.powerup:collides(self.paddle) then
		
		if self.powerup.type == 9 and multi == 0 then		
			-- multiball - initialize 2 more balls (same as beginning), same stats as first, different trajectories			
			numBalls = 3
			for b=2, numBalls do
				self.balls[b] = Ball()
				self.balls[b].x = self.balls[1].x -- params.VIRTUAL_WIDTH / 2 - 2
				self.balls[b].y = self.balls[1].y -- VIRTUAL_HEIGHT / 2 - 2
				self.balls[b].dx = math.random(-200, 200)
				self.balls[b].dy = -(math.abs(self.balls[1].y) * math.random(.97, 1.03))  -- similar speed to first ball, but always up
				self.balls[b].skin = self.balls[1].skin
			end
			multi = 1   -- multiball in effect
		elseif self.powerup.type == 10 then
			if unlocked == 0 then unlocked = 1 end   -- locked black bricks can be unlocked
		end
		
		self.powerup.active = true
		self.powerup.inPlay = false  -- powerup caught, disappears
	
		gSounds['paddle-hit']:play()
	end


	
	-- detect collision across all bricks with the ball
	for k, brick in pairs(self.bricks) do

		for b=1, numBalls do	

			-- only check collision if we're in play
			if brick.inPlay and self.balls[b]:collides(brick) then

				-- add to score
				if brick.color ~= 6 or unlocked == 1 then   -- NEW: not locked brick, or key powerup active
					self.score = self.score + (brick.tier * 200 + brick.color * 25)
				end

				-- check to make paddle larger every 2000 points
				if self.score >= scoreCheck then
					if self.paddle.size < 4 then   -- > 1
						self.paddle.size = self.paddle.size + 1   --  -1
						self.paddle.width = 32 * self.paddle.size
					end
					scoreCheck = scoreCheck + 1000    -- every 1000 points
				end

				-- trigger the brick's hit function, which removes it from play
				brick:hit()

				-- if we have enough points, recover a point of health
				if self.score > self.recoverPoints then
					-- can't go above 3 health
					self.health = math.min(3, self.health + 1)

					-- multiply recover points by 2
					self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

					-- play recover sound effect
					gSounds['recover']:play()
				end

				-- go to our victory screen if there are no more bricks left
				if self:checkVictory() then
					gSounds['victory']:play()

					gStateMachine:change('victory', {
						level = self.level,
						paddle = self.paddle,
						health = self.health,
						score = self.score,
						highScores = self.highScores,
						ball = self.ball,
						powerup = self.powerup,	    
						recoverPoints = self.recoverPoints
					})
				end

				--
				-- collision code for bricks
				--
				-- we check to see if the opposite side of our velocity is outside of the brick;
				-- if it is, we trigger a collision on that side. else we're within the X + width of
				-- the brick and should check to see if the top or bottom edge is outside of the brick,
				-- colliding on the top or bottom accordingly 
				--

				-- left edge; only check if we're moving right, and offset the check by a couple of pixels
				-- so that flush corner hits register as Y flips, not X flips
				if self.balls[b].x + 2 < brick.x and self.balls[b].dx > 0 then
				
					-- flip x velocity and reset position outside of brick
					self.balls[b].dx = -self.balls[b].dx
					self.balls[b].x = brick.x - 8
			
				-- right edge; only check if we're moving left, , and offset the check by a couple of pixels
				-- so that flush corner hits register as Y flips, not X flips
				elseif self.balls[b].x + 6 > brick.x + brick.width and self.balls[b].dx < 0 then
				
					-- flip x velocity and reset position outside of brick
					self.balls[b].dx = -self.balls[b].dx
					self.balls[b].x = brick.x + 32
			
				-- top edge if no X collisions, always check
				elseif self.balls[b].y < brick.y then
				
					-- flip y velocity and reset position outside of brick
					self.balls[b].dy = -self.balls[b].dy
					self.balls[b].y = brick.y - 8
			
				-- bottom edge if no X collisions or top collision, last possibility
				else
				
					-- flip y velocity and reset position outside of brick
					self.balls[b].dy = -self.balls[b].dy
					self.balls[b].y = brick.y + 16
				end

				-- slightly scale the y velocity to speed up the game, capping at +- 150
				if math.abs(self.balls[b].dy) < 150 then
					self.balls[b].dy = self.balls[b].dy * 1.02
				end

				-- only allow colliding with one brick, for corners
				break
			end
		end
	end

	-- if ball goes below bounds, revert to serve state and decrease health
	for b=1, numBalls do	

		if self.balls[b].y >= VIRTUAL_HEIGHT then
			table.remove(self.balls, b)   -- lose extra ball and remove from table, or...
			numBalls = numBalls - 1
			if numBalls == 1 then multi = 0 end -- end multiball
			gSounds['hurt']:play()

			-- all gone, lose a life	
			if numBalls == 0 then
				self.health = self.health - 1

				-- game over
				if self.health == 0 then
					gStateMachine:change('game-over', {
						score = self.score,
						highScores = self.highScores
					})
				else

					-- make smaller when ball lost
					if self.paddle.size > 1 then
						self.paddle.size = self.paddle.size - 1 
						self.paddle.width = 32 * self.paddle.size
					end
								
					gStateMachine:change('serve', {
						paddle = self.paddle,
						bricks = self.bricks,
						health = self.health,
						score = self.score,
						highScores = self.highScores,
						level = self.level,
						recoverPoints = self.recoverPoints
					})
				end
			end
			break	
		end
	end
	
	-- for rendering particle systems
	for k, brick in pairs(self.bricks) do
		brick:update(dt)
	end

	
	-- display powerup when powerTimer reaches max
	if powerTimer < powerTimerMax then
		powerTimer = powerTimer + 1
	elseif multi == 1 and unlocked == 1 then   -- unlocked: 1 key has unlocked, 2 no locked bricks at start
		powerTimer = 0  -- only reset timer
	else 	
		if multi == 0 and unlocked == 0 then
			local rnd = math.random(9, 10) -- 9 is multiball, 10 is key
			self.type = rnd
			self.powerup.inPlay = true
		elseif multi == 1 and unlocked == 0 then
			self.powerup.type = 10   -- key
			self.powerup.inPlay = true			
		elseif multi == 0 then
			self.powerup.type = 9  -- multiball
			self.powerup.inPlay = true
		else
			self.powerup.inPlay = false
		end		
		
		-- display powerup if inPlay == true
		self.powerup.y = VIRTUAL_HEIGHT / 4 - 2   -- NEW: reset vertical
		self.powerup.dy = 30  -- fall slowly from center
		powerTimer = 0		
	end
	
	if love.keyboard.wasPressed('escape') then
		love.event.quit()
	end
	
	
	
	
end






function PlayState:render()
	-- render bricks
	for k, brick in pairs(self.bricks) do
		brick:render()
	end

	-- render all particle systems
	for k, brick in pairs(self.bricks) do
		brick:renderParticles()
	end

	self.paddle:render()
	
	for b=1, numBalls do	
		self.balls[b]:render()
	end
	
	self.powerup:render()

	renderScore(self.score)
	renderHealth(self.health)

	-- pause text, if paused
	if self.paused then
		love.graphics.setFont(gFonts['large'])
		love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
	end
end

function PlayState:checkVictory()
	for k, brick in pairs(self.bricks) do
		if brick.inPlay then
			return false
		end 
	end

	return true
end