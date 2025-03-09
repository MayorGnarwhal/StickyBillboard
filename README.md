# StickyBillboard
Converts any BillboardGui into a StickyBillboard, which will stick to the edges of the screen when the Billboard's adornee is off screen. 

StickyBillboard works by copying the contents of a BillboardGui into a Frame in PlayerGui, and rendering its position every frame. When the BillboardGui's adornee position is off screen, the StickyBillboard's frame is clamped to the edges of the screen. 

All properties of the BillboardGui are passed to the StickyBillboard unless overwritten by the given [options](#stickybillboard-options), with the exception of the properties listed in the [limitations](#limitations).

## How to use
```luau
local billboardGui = workspace.Part.BillboardGui
local sticky = StickyBillboard.new(billboardGui, billboardGui.Parent)
billboardGui:Destroy()
```


### Creating a location marker
Sample code utilizing all features of StickyBillboard. Creates a billboard that has an arrow pointing towards the world position when off screen.
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

https://github.com/user-attachments/assets/1e11f2fa-e595-46a4-a20f-5b0884221a38

<br>

## Constructors
### `new`
Creates a new StickyBillboard object
### Parameters
|     |     |     |
| :-- | :-- | :-- |
| **billboard** | *BillboardGui* | Template BillboardGui to be converted. The original billboard will not be modified |
| **adornee** | *BasePart \| Model \| Vector3?* | Defaults to the adornee of the given billboard |
| **options** | *[Options](#stickybillboard-options)?* | Dictonary of parameters than can be used to modify the StickyBillboard's behavior |

<br>

## Methods
### `BindToUpdate`
Binds a function that will be called every frame as the StickyBillboard updates. Passes two arguments `onScreen` and `screenDirection` indicating basic state of the billboard, which can also be read directly through the [StickyBillboard properties](#stickybillboard-properties)
### Parameters
|     |     |
| :-- | :-- |
| **closure** | *(onScreen: boolean, screenDirection: Vector2) -> nil* |

```luau
local sticky = StickyBillboard.new(billboardGui, adornee)

sticky:BindToUpdate(function(onScreen, screenDirection)
	print("StickyBillboard is on screen:", onScreen)
end)
```

### `WorldPosition`
Calculates and returns a `Vector3` of the world position of the StickyBillboard based on its adornee's position and offset properties

### `Destroy`
Destroys the StickyBillboard and all created instances and connections. If the StickyBillboard's adornee is an instance, `Destroy` is automatically called when the adornee is destroyed.

<br>

## StickyBillboard Options
When creating a StickyBillboard object, a number of options can be given to define its behavior.
| Property | Type | Description |
| :-- | :-- | :-- |
| **MaxDistance** | *number* | Maximum render range of the StickyBillboard. Defaults to the BillboardGui `MaxDistance` property |
| **ZIndex** | *number* | Determines the order the StickyBillboards renders relative to other StickyBillboard objects |
| **OffScreenSize** | *UDim2* | The size of the StickyBillboard when it is clamped to the edge of the screen. Defaults to the BillboardGui's `Size` property. **Must be defined if the size uses scale** |
| **OffScreenSizeMult** | *number* | Calculates OffScreenSize based on the billboard's size and the multiplier. Has no effect if `OffScreenSize` is defined |
| **Padding** | *UDim2* | Defines the distance from the edge of the screen the StickyBillboard is bound to |
| **PaddingTop** | *UDim* | Padding for the top of the screen. Stacks with `Padding` |
| **PaddingBottom** | *UDim* | Padding for the bottom of the screen. Stacks with `Padding` |
| **PaddingLeft** | *UDim* | Padding for the left of the screen. Stacks with `Padding` |
| **PaddingRight** | *UDim* | Padding for the right of the screen. Stacks with `Padding` |
| **IgnoreGuiInset** | *boolean* | Adds padding to the top and left of the screen as neccessary based on the device's GuiInset |
| **AnchorPoint** | *Vector2* | Defines the center of the StickyBillboard. Defaults to `(0.5, 0.5)`. |
| **ScreenOffset** | *Vector2* | Defines the screen offset in pixels of the rendered billboard |

<br>

## StickyBillboard Properties
There are a few properties that can be used to read and/or change the state of the StickyBillboard
| Property | Type | Description |
| :-- | :-- | :-- |
| **Container** | *Frame* | (Readonly) The Frame Instance in which the billboard is rendered. Has the same hierarchy as the given BillboardGui |
| **Enabled** | *boolean* | Determines if the StickyBillboard should be rendered or not |
| **OnScreen** | *boolean* | (Readonly) Denotes if the StickyBillboard is on the screen or if it is clamped to the edge of the screen |
| **ScreenDirection** | *Vector2* | (Readonly) Denotes a direction vector from the center of the screen. Is not a unit vector |

<br>

## Limitations
- Since the StickyBillboard is a Frame in PlayerGui, the following BillboardGui properties will have no effect:
  - `Active` (default = `false`)
  - `AlwaysOnTop` (default = `true`)
  - `LightInfluence` (default = `0`)
  - `PlayerToHideFrom` (default = `nil`)
  - `ResetOnSpawn` (default = `false)`
  - `ZIndexBehavior` (default = `Sibling`)
- If given BillboardGui is sized with Scale, `Options.OffScreenSize` must be defined
- Billboards with a non-zero `SizeOffset` will clamp off screen based on the adornee position, not where the StickyBillboard renders on the screen
