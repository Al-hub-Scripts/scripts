-- Rayfield-ish GUI Mini-Lib (single ModuleScript)
-- Place in ReplicatedStorage and require from a LocalScript
-- API:
--   local RayMini = require(path)
--   local win = RayMini:CreateWindow("My GUI")
--   local sec = win:CreateSection("Main")
--   sec:AddButton("Do thing", function() ... end)
--   sec:AddToggle("Option", false, function(val) end)
--   sec:AddSlider("Speed", 0, 100, 50, function(val) end)
--   sec:AddLabel("Notes here")

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local RayMini = {}
RayMini.__index = RayMini

-- Utility
local function new(class, props)
	local obj = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			obj[k] = v
		end
	end
	return obj
end

local function tween(instance, props, info)
	info = info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(instance, info, props):Play()
end

-- Basic style defaults
local COLORS = {
	Background = Color3.fromRGB(20, 20, 20),
	Panel = Color3.fromRGB(30, 30, 30),
	Accent = Color3.fromRGB(0, 170, 255),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
}

-- Create main window
function RayMini:CreateWindow(title)
	local selfWindow = {}
	selfWindow.__index = selfWindow

	-- ScreenGui
	local screenGui = new("ScreenGui", {
		Name = "RayMiniGui_" .. tostring(math.random(1000,9999)),
		DisplayOrder = 50,
		ResetOnSpawn = false,
	})
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	-- Outer container
	local outer = new("Frame", {
		Name = "Outer",
		Size = UDim2.new(0, 420, 0, 40),
		Position = UDim2.new(0.5, -210, 0.2, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = COLORS.Panel,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	local uicorner = new("UICorner", {CornerRadius = UDim.new(0, 12), Parent = outer})

	-- Title bar
	local titleBar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = outer,
	})
	local titleLabel = new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = title or "RayMini",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextColor3 = COLORS.Text,
		Parent = titleBar,
	})

	-- Expand/collapse arrow + container for content
	local btnToggle = new("TextButton", {
		Name = "Toggle",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -36, 0, 6),
		AnchorPoint = Vector2.new(1, 0),
		Text = "˅",
		Font = Enum.Font.SourceSansBold,
		TextSize = 18,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Parent = titleBar,
	})
	btnToggle.AutoButtonColor = false

	local contentContainer = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = outer,
	})
	local contentLayout = new("UIListLayout", {Parent = contentContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local inner = new("Frame", {
		Name = "Inner",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Parent = contentContainer,
	})

	-- Main panel to hold sections
	local mainPanel = new("Frame", {
		Name = "MainPanel",
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundTransparency = 1,
		Parent = inner,
	})
	local mainLayout = new("UIListLayout", {Parent = mainPanel, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- drag support for outer
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local function beginDrag(input)
		dragging = true
		dragStart = input.Position
		startPos = outer.Position
	end
	local function updateDrag(input)
		if not dragging then return end
		local delta = input.Position - dragStart
		outer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	local function endDrag()
		dragging = false
	end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginDrag(input)
		end
	end)
	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDrag(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDrag(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			endDrag()
		end
	end)

	-- expand/collapse
	local expanded = true
	btnToggle.MouseButton1Click:Connect(function()
		expanded = not expanded
		local txt = expanded and "˅" or "˄"
		btnToggle.Text = txt
		if expanded then
			tween(contentContainer, {Size = UDim2.new(1, 0, 0, mainPanel.AbsoluteSize.Y + 16)})
		else
			tween(contentContainer, {Size = UDim2.new(1, 0, 0, 0)})
		end
	end)

	-- Public API object for the window
	local windowObj = setmetatable({
		_screenGui = screenGui,
		_outer = outer,
		_mainPanel = mainPanel,
		_content = contentContainer,
		_title = titleLabel,
		_sections = {},
	}, selfWindow)

	-- Make sure container resizes when children change
	mainPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local newY = mainPanel.AbsoluteSize.Y + 16
		tween(contentContainer, {Size = UDim2.new(1, 0, 0, newY)}, TweenInfo.new(0.12))
	end)

	-- Methods for windowObj
	function selfWindow:CreateSection(name)
		local section = new("Frame", {
			Name = tostring(name or "Section"),
			Size = UDim2.new(1, -8, 0, 8),
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			Parent = mainPanel,
		})
		local sCorner = new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = section})
		local sPadding = new("UIPadding", {Parent = section, PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})
		local sLayout = new("UIListLayout", {Parent = section, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
		sLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local header = new("TextLabel", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = tostring(name or ""),
			TextColor3 = COLORS.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = section,
		})

		-- adjust section height as children added
		section:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			section.Size = UDim2.new(1, -8, 0, section.AbsoluteSize.Y)
		end)

		local sectionObj = {}
		sectionObj._frame = section

		function sectionObj:AddButton(label, callback)
			local btn = new("TextButton", {
				Name = "Button_" .. label,
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Color3.fromRGB(40,40,40),
				BorderSizePixel = 0,
				Text = label,
				TextColor3 = COLORS.Text,
				Font = Enum.Font.GothamSemibold,
				TextSize = 13,
				Parent = section,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
			btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(50,50,50)}, TweenInfo.new(0.12)) end)
			btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(40,40,40)}, TweenInfo.new(0.12)) end)
			btn.MouseButton1Click:Connect(function()
				pcall(function() callback() end)
			end)
			return btn
		end

		function sectionObj:AddLabel(text)
			local lbl = new("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = COLORS.SubText,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = section,
			})
			return lbl
		end

		function sectionObj:AddToggle(label, default, callback)
			default = default or false
			local container = new("Frame", {
				Name = "Toggle_" .. label,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Parent = section,
			})
			local txt = new("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, -54, 1, 0),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = COLORS.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = container,
			})
			local toggleBtn = new("TextButton", {
				Name = "ToggleBtn",
				Size = UDim2.new(0, 46, 0, 22),
				Position = UDim2.new(1, -46, 0.5, -11),
				BackgroundColor3 = Color3.fromRGB(60,60,60),
				BorderSizePixel = 0,
				Parent = container,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 14), Parent = toggleBtn})
			local knob = new("Frame", {
				Name = "Knob",
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(default and 1 or 0, (default and -2) or 2, 0.5, -9),
				BackgroundColor3 = COLORS.Panel,
				Parent = toggleBtn,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 14), Parent = knob})

			local state = default
			local function setState(s, noCallback)
				state = s
				local pos = s and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
				local bg = s and COLORS.Accent or Color3.fromRGB(60,60,60)
				tween(knob, {Position = pos}, TweenInfo.new(0.14))
				tween(toggleBtn, {BackgroundColor3 = bg}, TweenInfo.new(0.14))
				if not noCallback and callback then
					pcall(function() callback(state) end)
				end
			end

			toggleBtn.MouseButton1Click:Connect(function()
				setState(not state)
			end)

			-- initial state
			setState(default, true)

			return {
				Set = setState,
				Get = function() return state end,
				Instance = container,
			}
		end

		function sectionObj:AddSlider(label, min, max, default, callback)
			min = min or 0
			max = max or 100
			default = math.clamp(default or min, min, max)
			local container = new("Frame", {
				Name = "Slider_" .. label,
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundTransparency = 1,
				Parent = section,
			})
			local txt = new("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundTransparency = 1,
				Text = label .. " — " .. tostring(default),
				TextColor3 = COLORS.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = container,
			})
			local track = new("Frame", {
				Name = "Track",
				Size = UDim2.new(1, 0, 0, 12),
				Position = UDim2.new(0, 0, 0, 24),
				BackgroundColor3 = Color3.fromRGB(60,60,60),
				BorderSizePixel = 0,
				Parent = container,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = track})
			local fill = new("Frame", {
				Name = "Fill",
				Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
				BackgroundColor3 = COLORS.Accent,
				BorderSizePixel = 0,
				Parent = track,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = fill})
			local knob = new("Frame", {
				Name = "Knob",
				Size = UDim2.new(0, 14, 0, 14),
				Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
				BackgroundColor3 = COLORS.Panel,
				Parent = track,
			})
			new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = knob})

			local dragging = false
			local function updateFromPos(x)
				local abs = track.AbsoluteSize.X
				local relative = math.clamp((x - track.AbsolutePosition.X) / abs, 0, 1)
				fill.Size = UDim2.new(relative, 0, 1, 0)
				knob.Position = UDim2.new(relative, -7, 0.5, -7)
				local value = min + (max - min) * relative
				local rounded = math.floor((value) + 0.5)
				txt.Text = label .. " — " .. tostring(rounded)
				if callback then
					pcall(function() callback(rounded) end)
				end
			end

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					updateFromPos(input.Position.X)
				end
			end)
			track.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					updateFromPos(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)

			-- init
			updateFromPos(track.AbsolutePosition.X + track.AbsoluteSize.X * ((default - min) / (max - min)))

			return {
				Set = function(v)
					local r = math.clamp((v - min) / (max - min), 0, 1)
					fill.Size = UDim2.new(r, 0, 1, 0)
					knob.Position = UDim2.new(r, -7, 0.5, -7)
					txt.Text = label .. " — " .. tostring(math.floor(v + 0.5))
					if callback then pcall(function() callback(v) end) end
				end,
				Get = function()
					local relative = fill.Size.X.Scale
					return min + (max - min) * relative
				end,
				Instance = container,
			}
		end

		-- return section object
		return setmetatable(sectionObj, {__index = sectionObj})
	end

	function selfWindow:Destroy()
		if selfWindow._screenGui then
			selfWindow._screenGui:Destroy()
			selfWindow._screenGui = nil
		end
	end

	-- expose for user
	return setmetatable(windowObj, {__index = selfWindow})
end

return RayMini
