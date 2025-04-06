# StickyBillboard
Converts any BillboardGui into a StickyBillboard, which will stick to the edges of the screen when the Billboard's adornee is off screen. 

StickyBillboard works by copying the contents of a BillboardGui into a Frame in PlayerGui, and rendering its position every frame. When the BillboardGui's adornee position is off screen, the StickyBillboard's frame is clamped to the edges of the screen, allowing for an always visible location indicator.

## Table of Contents
- [How to use](#how-to-use)
	- [Creating a location marker](#creating-a-location-marker)
 	- [Seemless Integration](#seemless-integration)
- [Constructors](#constructors)
- [Methods](#methods)
- [Constructor Options](#constructor-options)
- [Properties](#properties)
- [Limitations](#limitations)
- [Installation](#installation)

## How to use
```luau
local billboardGui = workspace.Part.BillboardGui :: BillboardGui
local sticky = StickyBillboard.new(billboardGui, billboardGui.Parent)
billboardGui:Destroy()
```

See [Constructors](#constructors) for more information on how StickyBillboard is created.


### Creating a location marker
Sample code utilizing all features of StickyBillboard. Creates a billboard that has an arrow pointing towards the world position when off screen.
```luau
local billboardTemplate = ReplicatedStorage.Assets.BillboardGui
local adornee = workspace.Baseplate

local sticky = StickyBillboard.new(billboardTemplate, adornee, {
	OffScreenSizeMult = 0.75,
	Padding = UDim2.fromOffset(20, 20),
})

sticky:BindToUpdate(function(dt, onScreen, direction)
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

### Seemless Integration
To make the transition from native BillboardGuis to StickyBillboards as seemless as possible, the rendering of StickyBillboards behave exactly like BillboardGuis. This includes the persistence of all offset properties (`StudsOffset`, `StudsOffsetWorldSpace`, `ExtentsOffset`, and `ExtentsOffsetWorldSpace`).

Below is a demonstration of each of the offset properties. The red circles are StickyBillboards, and the blue oulines are the BillboardGui templates.

https://github.com/user-attachments/assets/f46ec3ec-0ff2-4978-a5da-cfb7f8a9293c


<br>

## Constructors
### `new`
Creates a new StickyBillboard object. All properties of the BillboardGui are passed to the StickyBillboard unless overwritten by the given [options](#constructor-options), with the exception of the properties listed in the [limitations](#limitations).

### Parameters
|     |     |     |
| :-- | :-- | :-- |
| **billboard** | *BillboardGui* | Template BillboardGui to be converted. The original billboard will not be modified |
| **adornee** | *BasePart \| Model \| Vector3?* | Defaults to the adornee of the given billboard |
| **options** | *[Options](#constructor-options)?* | Dictonary of parameters than can be used to modify the StickyBillboard's behavior |

Note that the original BillboardGui is not affected when creating a new StickyBillboard object. If you want to replace a BillboardGui that is already parented in the workspace, you should delete the BillboardGui template after creating the StickyBillboard, and BillboardGuis **do not** need to be cloned when passed into the constructor.

When a StickyBillboard is created, the contents of the template BillboardGui are cloned into a Frame in PlayerGui, which you can access and modify through the `Containter` [property](#properties).

<br>

## Methods
### `BindToUpdate`
Binds a function that will be called every frame as the StickyBillboard updates. 

Passes three arguments, `dt`, `onScreen`, and `screenDirection`. `dt` is the time in seconds since the previous update. `onScreen` and `screenDirections` indicate basic state of the billboard, which can also be read directly through the [StickyBillboard properties](#properties). These arguments can be used to update the contents of the StickyBillboard, such as an arrow pointing towards the world location as seen in the [example location marker code](#creating-a-location-marker).
### Parameters
|     |     |
| :-- | :-- |
| **closure** | *(dt: number, onScreen: boolean, screenDirection: Vector2) -> nil* |
```luau
local sticky = StickyBillboard.new(billboardGui, adornee)

sticky:BindToUpdate(function(dt, onScreen, screenDirection)
	print("StickyBillboard is on screen:", onScreen)
end)
```

### `WorldPosition`
Calculates and returns a `Vector3` of the world position of the StickyBillboard based on its adornee's position and offset properties

```luau
local billboardTemplate = ReplicatedStorage.Assets.BillboardGui
local adornee = workspace.Baseplate

adornee.Position = Vector3.new(0, 5, 0)
billboardTemplate.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)

local sticky = StickyBillboard.new(billboardTemplate, adornee)
print(sticky:WorldPosition()) -- Vector3.new(0, 10, 0)
```

### `Destroy`
Destroys the StickyBillboard and all created instances and connections. If the StickyBillboard's adornee is an instance, `Destroy` is automatically called when the adornee is destroyed or parented to `nil`.

<br>

## Constructor Options
When creating a StickyBillboard object, a number of options can be given to define its behavior.
| Property | Type | Description |
| :-- | :-- | :-- |
| **MaxDistance** | *number* | Maximum render range of the StickyBillboard. Defaults to the BillboardGui `MaxDistance` property |
| **ZIndex** | *number* | Determines the order the StickyBillboards renders relative to other StickyBillboard objects |
| **OffScreenSize** | *UDim2* | The size of the StickyBillboard when it is clamped to the edge of the screen. Defaults to the BillboardGui's `Size` property. **Must be defined if the size uses scale** |
| **OffScreenSizeMult** | *number* | Calculates OffScreenSize based on the billboard's size and the multiplier. Has no effect if `OffScreenSize` is defined |
| **MinimumAbsoluteSize** | *Vector2* | Sets minimum bounds for the AbsoluteSize. Only has effect if sized with scale. Maintains aspect ratio when resized, so minimum size may not be reached on all axes |
| **Padding** | *UDim2* | Defines the distance from the edge of the screen the StickyBillboard is bound to |
| **PaddingTop** | *UDim* | Padding for the top of the screen. Stacks with `Padding` |
| **PaddingBottom** | *UDim* | Padding for the bottom of the screen. Stacks with `Padding` |
| **PaddingLeft** | *UDim* | Padding for the left of the screen. Stacks with `Padding` |
| **PaddingRight** | *UDim* | Padding for the right of the screen. Stacks with `Padding` |
| **IgnoreGuiInset** | *boolean* | Adds padding to the top and left of the screen as neccessary based on the device's GuiInset |
| **AnchorPoint** | *Vector2* | Defines the center of the StickyBillboard. Defaults to `(0.5, 0.5)` |
| **ScreenOffset** | *Vector2* | Defines the screen offset in pixels of the rendered billboard |

<br>

## Properties
There are a few properties that can be used to read and/or change the state of the StickyBillboard
| Property | Type | Description |
| :-- | :-- | :-- |
| **Container** | *Frame* | (Readonly) The Frame Instance in which the billboard is rendered. Has the same hierarchy as the given BillboardGui |
| **Enabled** | *boolean* | Determines if the StickyBillboard should be rendered or not. Functions given to [BindToUpdate](#bindtoupdate) **will not** be called while disabled. You can also set `Container.Visible` if you want to hide the billboard but still render in the background |
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
- The size of the StickyBillboard Container cannot be changed
- If template BillboardGui is sized with Scale, `Options.OffScreenSize` must be defined
- Billboards with a non-zero `SizeOffset` will clamp off screen based on the adornee position, not where the StickyBillboard renders on the screen. For most use cases, it is recommended to use the `AnchorPoint` option instead

## Installation
Get StickyBillboard [on Roblox](https://create.roblox.com/store/asset/118203280367884) or from the [latest GitHub release](https://github.com/MayorGnarwhal/StickyBillboard/releases)
