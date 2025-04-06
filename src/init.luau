local StickyBillboard = {}
StickyBillboard.__index = StickyBillboard
StickyBillboard.ClassName = "StickyBillboard"

debug.setmemorycategory(StickyBillboard.ClassName)

--// Dependencies
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StickyBillboardGui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local HiddenFolder = Instance.new("Configuration")
HiddenFolder.Name = "_hidden"
HiddenFolder.Parent = ScreenGui

--// Types
export type UpdateClosure = (dt: number, onScreen: boolean, screenDirection: Vector2) -> nil
export type Adornee = Vector3 | BasePart | Model
export type Options = {
	MaxDistance: number?,
	ZIndex: number?,

	OffScreenSize: UDim2?,
	OffScreenSizeMult: number?,
	MinimumAbsoluteSize: Vector2?,

	Padding: UDim2?,
	PaddingTop: UDim?,
	PaddingBottom: UDim2?,
	PaddingLeft: UDim2?,
	PaddingRight: UDim2?,
	IgnoreGuiInset: boolean?,

	AnchorPoint: Vector2?,
	ScreenOffset: Vector2?,
}

export type ClassType = typeof(setmetatable({} :: {
	Adornee: Adornee,
	Container: Frame,

	OnScreen: boolean,
	ScreenDirection: Vector2,
	Enabled: boolean,

	_options: Options,
	_sizedWithScale: boolean?,
	_extentsOffset: Vector3?,
	_extentsOffsetWorldSpace: Vector3?,
	_studsOffset: Vector3?,
	_studsOffsetWorldSpace: Vector3?,
	_sizeOffset: Vector2?,
	_size: UDim2,
	_offScreenSize: UDim2,

	_onUpdate: {UpdateClosure},
	_connections: {RBXScriptConnection},
}, StickyBillboard))


--// Helper functions
local function AssertOptionsType(options: Options, optionKey: string, typeName: string)
	local value = options[optionKey]
	assert(value == nil or typeof(value) == typeName, 
		`Invalid option '{optionKey}' given (expected {typeName}, got {typeof(value)})`)
end

local function SafeNumberRange(min: number, max: number): NumberRange
	return NumberRange.new(min, math.max(min, max))
end


--// Constructor
function StickyBillboard.new(billboard: BillboardGui, adornee: Adornee, options: Options?): ClassType
	adornee = adornee or billboard.Adornee
	options = options and table.clone(options) or {}

	local sizedWithScale = (billboard.Size.X.Scale ~= 0 or billboard.Size.Y.Scale ~= 0) 
	if sizedWithScale then
		assert(options.OffScreenSize ~= nil, 
			"OffScreenSize must be specified for BillboardGuis that are sized with Scale")
	end

	AssertOptionsType(options, "MaxDistance", "number")
	AssertOptionsType(options, "OffScreenSize", "UDim2")
	AssertOptionsType(options, "OffScreenSizeMult", "number")
	AssertOptionsType(options, "IgnoreGuiInset", "boolean")
	AssertOptionsType(options, "Padding", "UDim2")
	AssertOptionsType(options, "PaddingTop", "UDim")
	AssertOptionsType(options, "PaddingBottom", "UDim2")
	AssertOptionsType(options, "PaddingLeft", "UDim2")
	AssertOptionsType(options, "PaddingRight", "UDim2")
	AssertOptionsType(options, "AnchorPoint", "Vector2")
	AssertOptionsType(options, "ScreenOffset", "Vector2")
	AssertOptionsType(options, "MinimumAbsoluteSize", "Vector2")

	local self = setmetatable({}, StickyBillboard) :: ClassType

	self.Adornee = adornee
	self._size = billboard.Size
	self._sizedWithScale = sizedWithScale
	self._extentsOffset = billboard.ExtentsOffset
	self._extentsOffsetWorldSpace = billboard.ExtentsOffsetWorldSpace
	self._studsOffset = billboard.StudsOffset
	self._studsOffsetWorldSpace = billboard.StudsOffsetWorldSpace
	self._sizeOffset = billboard.SizeOffset

	self.Container = Instance.new("Frame")
	self.Container.Name = billboard.Name
	self.Container.Size = self._size
	self.Container.BackgroundTransparency = 1
	for i, child in pairs(billboard:GetChildren()) do
		child:Clone().Parent = self.Container
	end
	self.Container.ClipsDescendants = billboard.ClipsDescendants
	self.Container.AutoLocalize = billboard.AutoLocalize
	self.Container.RootLocalizationTable = billboard.RootLocalizationTable
	self.Container.Interactable = false
	self.Container.Active = false
	self.Container.Parent = ScreenGui

	self._options = options
	self._options.MaxDistance = self._options.MaxDistance or billboard.MaxDistance
	self._options.OffScreenSizeMult = self._options.OffScreenSizeMult or 1
	self._options.IgnoreGuiInset = self._options.IgnoreGuiInset and true or false
	self._options.Padding = self._options.Padding or UDim2.new()
	self._options.PaddingTop = self._options.PaddingTop or UDim.new()
	self._options.PaddingBottom = self._options.PaddingBottom or UDim.new()
	self._options.PaddingLeft = self._options.PaddingLeft or UDim.new()
	self._options.PaddingRight = self._options.PaddingRight or UDim.new()
	self._options.AnchorPoint = self._options.AnchorPoint or Vector2.new(0.5, 0.5)
	self._options.ScreenOffset = self._options.ScreenOffset or Vector2.zero

	self._offScreenSize = self._options.OffScreenSize
	if not self._options.OffScreenSize then
		local sizeMult = self._options.OffScreenSizeMult or 1
		self._offScreenSize = UDim2.new(
			self._size.X.Scale * sizeMult,
			self._size.X.Offset * sizeMult,
			self._size.Y.Scale * sizeMult,
			self._size.Y.Offset * sizeMult
		)
	end

	local xPadding = UDim.new(self._options.Padding.X.Scale, self._options.Padding.X.Offset)
	local yPadding = UDim.new(self._options.Padding.Y.Scale, self._options.Padding.Y.Offset)

	self._options.PaddingTop += yPadding + UDim.new(0, self._offScreenSize.Y.Offset * self._options.AnchorPoint.Y)
	self._options.PaddingBottom += yPadding + UDim.new(0, self._offScreenSize.Y.Offset * (1 - self._options.AnchorPoint.Y))
	self._options.PaddingLeft += xPadding + UDim.new(0, self._offScreenSize.X.Offset * self._options.AnchorPoint.X)
	self._options.PaddingRight += xPadding + UDim.new(0, self._offScreenSize.X.Offset * (1 - self._options.AnchorPoint.X))

	self.OnScreen = false
	self.ScreenDirection = Vector2.zero
	self.Enabled = billboard.Enabled

	self.Container.AnchorPoint = self._options.AnchorPoint
	self.Container.ZIndex = self._options.ZIndex or 1

	self._onUpdate = {}

	self._connections = {}
	table.insert(self._connections, RunService.PostSimulation:Connect(function(dt)
		debug.profilebegin(StickyBillboard.ClassName)
		self:_update(dt)
		debug.profileend()
	end))

	if typeof(adornee) == "Instance" then
		table.insert(self._connections, adornee.AncestryChanged:Connect(function()
			if adornee.Parent == nil then
				self:Destroy()
			end
		end))
	end

	return self
end


--// Methods
function StickyBillboard._update(self: ClassType, dt: number)
	if not self.Enabled then
		self.Container.Parent = HiddenFolder
		return
	end

	local worldPosition = self:WorldPosition()
	local screenPoint, isVisible = Camera:WorldToViewportPoint(worldPosition)
	local depth = screenPoint.Z

	local absoluteSize = self:_calculateAbsoluteSize(worldPosition)
	local screenPosition = Vector2.new(
		screenPoint.X + (absoluteSize.X * self._sizeOffset.X), 
		screenPoint.Y + (absoluteSize.Y * -self._sizeOffset.Y)
	)

	local distance = (Camera.CFrame.Position - worldPosition).Magnitude
	local withinMaxDistance = (distance <= self._options.MaxDistance)

	local screenSize = Camera.ViewportSize
	local screenCenter = screenSize / 2

	local paddingTop = self._options.PaddingTop
	local paddingBottom = self._options.PaddingBottom
	local paddingLeft = self._options.PaddingLeft
	local paddingRight = self._options.PaddingRight

	if self._options.IgnoreGuiInset then
		local guiInset = GuiService:GetGuiInset()
		paddingTop += UDim.new(0, guiInset.Y)
		paddingLeft += UDim.new(0, guiInset.X)
	end

	local xBounds = SafeNumberRange(
		paddingLeft.Offset + (paddingLeft.Scale * screenSize.X),
		screenSize.X - (paddingRight.Offset + (paddingRight.Scale * screenSize.X))
	)
	local yBounds = SafeNumberRange(
		paddingTop.Offset + (paddingTop.Scale * screenSize.Y),
		screenSize.Y - (paddingBottom.Offset + (paddingBottom.Scale * screenSize.Y))
	)

	self.OnScreen = isVisible and (xBounds.Min <= screenPosition.X and screenPosition.X <= xBounds.Max)
		and (yBounds.Min <= screenPosition.Y and screenPosition.Y <= yBounds.Max)

	if self.OnScreen then
		self.Container.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y) 
		self.Container.Position = UDim2.fromOffset(screenPosition.X, screenPosition.Y)

		self.ScreenDirection = screenPosition - screenCenter
	else
		self.Container.Size = self._offScreenSize

		local worldDirection = (worldPosition - Camera.CFrame.Position)
		local relativeDirection = Camera.CFrame:VectorToObjectSpace(worldDirection)
		self.ScreenDirection = Vector2.new(relativeDirection.X, -relativeDirection.Y)

		local xRatio = math.abs(self.ScreenDirection.X / screenCenter.X)
		local yRatio = math.abs(self.ScreenDirection.Y / screenCenter.Y)

		local clampedX = screenCenter.X + (self.ScreenDirection.X / yRatio)
		local clampedY = screenCenter.Y + (self.ScreenDirection.Y / xRatio)

		if 0 <= clampedX and clampedX <= screenSize.X then
			local yAxisIntersect = (self.ScreenDirection.Y < 0 and yBounds.Min or yBounds.Max)
			self.Container.Position = UDim2.fromOffset(
				math.clamp(clampedX, xBounds.Min, xBounds.Max), 
				yAxisIntersect
			)
		else
			local xAxisIntersect = (self.ScreenDirection.X < 0 and xBounds.Min or xBounds.Max)
			self.Container.Position = UDim2.fromOffset(
				xAxisIntersect, 
				math.clamp(clampedY, yBounds.Min, yBounds.Max)
			)
		end
	end

	self.Container.Parent = withinMaxDistance and ScreenGui or HiddenFolder

	for i, closure in ipairs(self._onUpdate) do
		closure(dt, self.OnScreen, self.ScreenDirection)
	end
end

-- bind a function to be called every frame as the billboard updates
function StickyBillboard.BindToUpdate(self: ClassType, closure: UpdateClosure)
	table.insert(self._onUpdate, closure)
end

-- calculates the world position of the billboard based on its adornee position and offset properties
function StickyBillboard.WorldPosition(self: ClassType): Vector3
	local position = self:_adorneePosition() + self._studsOffsetWorldSpace

	if self._studsOffset ~= Vector3.zero then
		position += Camera.CFrame:Inverse():VectorToObjectSpace(self._studsOffset)
	end

	if self._extentsOffsetWorldSpace ~= Vector3.zero then
		local boundingBoxCFrame, boundingBoxSize = self:_adorneeBoundingBox()
		position += boundingBoxCFrame:Inverse():VectorToObjectSpace(self._extentsOffsetWorldSpace * boundingBoxSize / 2)
	end

	if self._extentsOffset ~= Vector3.zero then
		local boundingBoxCFrame, boundingBoxSize = self:_adorneeBoundingBox(Camera.CFrame)
		position += Camera.CFrame:Inverse():VectorToObjectSpace(self._extentsOffset * boundingBoxSize / 2)
	end

	return position
end

function StickyBillboard.IsA(self: ClassType, className): boolean
	return className == StickyBillboard.ClassName
end

-- returns the world position of the billboard's adornee
function StickyBillboard._adorneePosition(self: ClassType): Vector3
	if typeof(self.Adornee) == "Vector3" then
		return self.Adornee
	elseif self.Adornee:IsA("BasePart") then
		return self.Adornee.Position
	elseif self.Adornee:IsA("Model") then
		local cframe, size = self.Adornee:GetBoundingBox()
		return cframe.Position
	end

	return Vector3.zero
end

-- calculates the bounding box of the adornee relative to the given orientation
-- if no orientation is given, defaults to adornee's CFrame
-- https://devforum.roblox.com/t/216581/12
function StickyBillboard._adorneeBoundingBox(self: ClassType, orientation: CFrame?): (CFrame, Vector3)
	if typeof(self.Adornee) == "Vector3" then
		return CFrame.identity, Vector3.zero
	end

	local isPart = self.Adornee:IsA("BasePart")
	local descendants = self.Adornee:GetDescendants()
	if isPart then 
		table.insert(descendants, self.Adornee) 
	end

	if orientation then
		orientation = orientation.Rotation
	elseif isPart then
		orientation = self.Adornee.CFrame.Rotation
	else
		orientation = self.Adornee:GetPivot().Rotation
	end

	local minx, miny, minz = math.huge, math.huge, math.huge
	local maxx, maxy, maxz = -math.huge, -math.huge, -math.huge

	for i, part in pairs(descendants) do
		if part:IsA("BasePart") then 
			local size = part.Size
			local sx, sy, sz = size.X, size.Y, size.Z

			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = orientation:ToObjectSpace(part.CFrame):GetComponents()
			local wsx = 0.5 * (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz)
			local wsy = 0.5 * (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz)
			local wsz = 0.5 * (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz)

			minx = if minx > (x - wsx) then x - wsx else minx
			miny = if miny > (y - wsy) then y - wsy else miny
			minz = if minz > (z - wsz) then z - wsz else minz

			maxx = if maxx < (x + wsx) then x + wsx else maxx
			maxy = if maxy < (y + wsy) then y + wsy else maxy
			maxz = if maxz < (z + wsz) then z + wsz else maxz
		end
	end

	local omin = Vector3.new(minx, miny, minz)
	local omax = Vector3.new(maxx, maxy, maxz)

	local size = omax - omin
	local cframe = orientation + orientation:PointToWorldSpace(size * 0.5)

	return cframe, size
end

-- calculates the screen render size of the billboard in pixels if the billboard is sized with scale
function StickyBillboard._calculateAbsoluteSize(self: ClassType, worldPosition: Vector3): Vector2
	local sizeX, sizeY

	if self._sizedWithScale then
		worldPosition = worldPosition or self:WorldPosition()
		local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPosition)
		local depth = screenPoint.Z

		local screenSize = Camera.ViewportSize
		local maxAxisWidth = math.max(screenSize.X, screenSize.Y)

		local fov = math.rad(Camera.MaxAxisFieldOfView)
		local focalLength = (maxAxisWidth / 2) / math.tan(fov / 2)

		sizeX = self._size.X.Offset + (self._size.X.Scale * focalLength / depth)
		sizeY = self._size.Y.Offset + (self._size.Y.Scale * focalLength / depth)
	else
		sizeX = self._size.X.Offset
		sizeY = self._size.Y.Offset
	end

	local absoluteSize = Vector2.new(sizeX, sizeY)
	local minSize = self._options.MinimumAbsoluteSize

	if minSize then -- clamp while maintaining aspect ratio
		if absoluteSize.X < minSize.X then
			absoluteSize *= (minSize.X / absoluteSize.X)
		end
		if absoluteSize.Y < minSize.Y then
			absoluteSize *= (minSize.Y / absoluteSize.Y)
		end
	end

	return absoluteSize
end

function StickyBillboard.Destroy(self: ClassType)
	if self.Container then
		self.Container:Destroy()
		self.Container = nil
	end

	for i, connection in pairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

--//
return StickyBillboard
