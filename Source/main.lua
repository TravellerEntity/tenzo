

import 'CoreLibs/graphics.lua'
import 'CoreLibs/timer.lua'

local gfx = playdate.graphics
local screenWidth, screenHeight = playdate.display.getSize()

local highScore = playdate.datastore.read("highScore") or 0
local score = 0
local gameIsOver = false
local showTitleScreen = true
local scoreBarHeight = 20
local cursorRow, cursorCol = 1, 1
-- Import the Block and Matrix classes
local blocks = import("blocks")
local gridready = false
local newLineTimerDelay = 20000
local bongoFont = gfx.font.new( "fonts/Bongo" )
local diamondFont = gfx.font.new( "fonts/diamond_12" )
local nontendoFont = gfx.font.new( "fonts/Nontendo-Bold-2x" )
local nontendoLightFont = gfx.font.new( "fonts/Nontendo-Light" )
local nontendoLight2xFont = gfx.font.new( "fonts/Nontendo-Light-2x" )
local isRotating = false
local rotationImage = nil
local rotationDirectionRight = false


local grid = blocks.Grid:new(10, 10, 21, 21,170,15) -- Initialize grid with 10 rows and 10 columns, blocks are 32x32 pixels

-- Add some initial blocks to the grid
for row = 1, 10 do  -- Start from the second last row to the first
    if true then
        for col = 1, 10 do
            grid:addBlock(row, col, math.random(0,9))    
        end
    end
end

gridready = true

function processRotationAnimation(isRightRotation)
    isRotating = true
    rotationDirectionRight = isRightRotation
    --Make the image context of the grid
    rotationImage = gfx.image.new(212, 212, gfx.kColorWhite)
    gfx.pushContext(rotationImage)
        
        grid:draw(true)
    gfx.popContext()
    
    if rotationDirectionRight then
        --set to animate the context image to rotate right
    else
        --set to animate the context image rotate left
    end
    playdate.timer.performAfterDelay(500, function()
        isRotating = false
        if rotationDirectionRight then
            grid:rotateRight()
        else
            grid:rotateLeft()
        end
    end)
end

function insertRowAtBottom()
    for row = 2, 10 do
        for col = 1, 10 do
            grid:moveBlockForce(row, col, row - 1, col)
        end
    end
    for col = 1, 10 do
        grid:addBlock(10, col, math.random(0,9))
    end
end

function processSequences()
    for row = 1, 10 do
        local sequence = getLongestStraightSequenceOfNumbersInRow(row)
        if #sequence >= 3 then
            --add this sequence to the score
            score = score + factorial(#sequence)
            for _, block in ipairs(sequence) do
                grid:highlight(block.row, block.col)
            end
            playdate.timer.performAfterDelay(300, function()
                for _, block in ipairs(sequence) do
                    block:remove()
                end
            end)
            
        end
    end
end

function getLongestStraightSequenceOfNumbersInRow(row)
    local sequence = {} -- to store the block objects in the sequence
    local longestSequence = {} -- to store the longest sequence found so far
    local currentNumber = nil -- to keep track of the current number in the sequence
    local currentSequenceLength = 0 -- to keep track of the length of the current sequence
    for col = 1, grid.cols do
        local block = grid:getBlockAt(row, col)
        
        if block.blank then
            -- If the block is blank, reset the current sequence
            currentNumber = nil
            currentSequenceLength = 0
        elseif currentNumber == nil or block.number == (currentNumber+1) then
            -- If the block has the incrment number as the current sequence or it's the first block in the sequence
            currentNumber = block.number
            currentSequenceLength = currentSequenceLength + 1
            table.insert(sequence, block)
            
            if currentSequenceLength >= 3 and currentSequenceLength > #longestSequence then
                -- If the current sequence is longer than the longest sequence found so far, update the longest sequence
                longestSequence = sequence
            end
        else
            -- If the block has a different number than the current sequence, reset the current sequence
            currentNumber = block.number
            currentSequenceLength = 1
            sequence = {block}
        end
    end
    
    return longestSequence
end

function factorial(n)
  if n <= 0 then
    return 1
  else
    return n * factorial(n-1)
  end
end



function playdate.update()
    gfx.clear() -- Clears the screen, necessary to redraw the sprites
    
    --Draw the title and the score board
    gfx.setFont(bongoFont)
    gfx.fillRect(0, 0, screenWidth, scoreBarHeight, 0)
    gfx.fillRect(0, screenHeight-150, screenWidth, 150, 0)
    --reverse the text to white
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("TENZO", 10, 7)
    gfx.setColor(gfx.kColorWhite)
    if not isRotating then
        gfx.fillRect(170,15,212,212)
    end
    gfx.setColor(gfx.kColorBlack)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.setFont(nontendoLightFont)
    gfx.drawText("High Score: " .. highScore, 10, 40)
    gfx.drawText("Score: " .. score, 10, 60)

    
    
    
    gfx.setFont(diamondFont)
    grid:moveBlocksDown() -- Move blocks downward if space is available
    if gridready then
        grid:unhighlight(cursorRow,cursorCol)
        grid:unhighlight(cursorRow,cursorCol+1)
        if playdate.buttonJustPressed(playdate.kButtonDown) then
            if cursorRow < grid.rows then
                cursorRow = cursorRow + 1
            end
        elseif playdate.buttonJustPressed(playdate.kButtonUp) then
            if cursorRow > 1 then
                cursorRow = cursorRow - 1
            end
        elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
            if cursorCol > 1 then
                cursorCol = cursorCol - 1
            end
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            if (cursorCol-1) < grid.cols then
                cursorCol = cursorCol + 1
            end
        elseif playdate.buttonJustPressed(playdate.kButtonA) then
            grid:swap(cursorRow,cursorCol,cursorRow,cursorCol+1)
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            processRotationAnimation(true)
        end
        grid:highlight(cursorRow,cursorCol)
        grid:highlight(cursorRow,cursorCol+1)
    end
    processSequences()
    playdate.timer.updateTimers()
    if isRotating then
        --rotate the image of the grid
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        rotationImage:drawRotated(290, 110, 45)
    else
        grid:draw() -- Draw the entire grid
    end
end
