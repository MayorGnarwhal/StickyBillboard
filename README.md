# StickyBillboard
Converts any BillboardGui into a StickyBillboard, which will stick to the edges of the screen when the Billboard's adornee is off screen. 

StickyBillboard works by copying the contents of a BillboardGui into a Frame in PlayerGui, and rendering its position every frame. When the BillboardGui's adornee position is off screen, the StickyBillboard's frame is clamped to the edges of the screen.

## How to use
```luau
local partWithBillboard = workspace.Part
local billboard = partWithBillboard.BillboardGui
local sticky = StickyBillboard.new(billboard, partWithBillboard)
billboard:Destroy()
```


### Creating a location notification
```luau
local sticky = StickyBillboard.new(billboard, adornee, {
	OffScreenSizeMult = 0.75,
	Padding = UDim2.fromOffset(20, 20),
})

sticky:BindToUpdate(function(onScreen, direction)
	if onScreen then
		sticky.Container.Arrow.Visible = false
	else
		sticky.Container.Arrow.Visible = true
		
		local rotation = math.atan2(direction.Y, direction.X)
		sticky.Container.Arrow.Rotation = math.deg(rotation) + 90
	end
end)
```

https://github.com/user-attachments/assets/f0a7cfb3-d35c-42d1-a866-343f83c96d31



## StickyBillboard Options
When creating a StickyBillboard object, a number of options can be given to define its behavior.
| Property | Type | Description |
| :-- | :-- | :-- |
| **MaxDistance** | *number* | Maximum render range of the StickyBillboard. Defaults to the `MaxDistance` of the given BillboardGui |
| **OffScreenSize** | *UDim2* | The size of the StickyBillboard when it is clamped to the edge of the screen. Defaults to its normal size |
| **OffScreenSizeMult** | *number* | Calculates OffScreenSize based on the billboard's size and the multiplier. Has no effect if `OffScreenSize` is defined |
| **Padding** | *UDim2* | Defines distance from the edge of the screen the StickyBillboard is clamped to |
| **PaddingTop** | *UDim* | Padding for the top of the screen. Stacks with `Padding` |
| **PaddingBottom** | *UDim* | Padding for the bottom of the screen. Stacks with `Padding` |
| **PaddingLeft** | *UDim* | Padding for the left of the screen. Stacks with `Padding` |
| **PaddingRight** | *UDim* | Padding for the right of the screen. Stacks with `Padding` |
| **IgnoreGuiInset** | *boolean* | Adds padding to the top and left of the screen as neccessary based on the device's GuiInset |
| **AnchorPoint** | *Vector2* | Defines the center of the StickyBillboard. Defaults to `(0.5, 0.5)`. |
| **ScreenOffset** | *Vector2* | Defines the offset based of the StickyBillboard's screen position |

## StickyBillboard Properties
There are a few properties that can be used to read and/or change the state of the StickyBillboard
| Property | Type | Description |
| :-- | :-- | :-- |
| **Enabled** | *boolean* | Determines if the StickyBillboard should be rendered or not |
| **OnScreen** | *boolean* | (Readonly) Denotes if the StickyBillboard is on the screen or if it is clamped to the edge of the screen |
| **WithinMaxDistance** | *boolean* | (Readonly) Denotes if the StickyBillboard is within rendering range as defined by `MaxDistance` |
| **ScreenDirection** | *Vector2* | (Readonly) Denotes a direction vector from the center of the screen. Is not a unit vector |


## Limitations
- Since the StickyBillboard is a Frame in PlayerGui, the following BillboardGui properties will have no affect:
  - `Active` (default = `false`)
  - `AlwaysOnTop` (default = `true`)
  - `LightInfluence` (default = `0`)
  - `PlayerToHideFrom` (default = `nil`)
  - `ResetOnSpawn` (default = `false)`
- If given BillboardGui is sized with Scale, `Options.OffScreenSize` must be defined
- Billboards with a non-zero `SizeOffset` will clamp off screen based on the adornee position, not where the StickyBillboard renders on the screen
