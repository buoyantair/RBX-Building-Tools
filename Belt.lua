-- ROBLOX Object Properties =========
-- [Name] Building Tools by F3X
-- [ClassName] LocalScript
-- [Parent] Building Tools
-- ==================================

------------------------------------------
-- Create references to important objects
------------------------------------------
Services = {
	["Workspace"] = Game:GetService( "Workspace" );
	["Players"] = Game:GetService( "Players" );
	["Lighting"] = Game:GetService( "Lighting" );
	["Teams"] = Game:GetService( "Teams" );
	["Debris"] = Game:GetService( "Debris" );
	["MarketplaceService"] = Game:GetService( "MarketplaceService" );
	["JointsService"] = Game.JointsService;
	["BadgeService"] = Game:GetService( "BadgeService" );
	["RunService"] = Game:GetService( "RunService" );
	["ContentProvider"] = Game:GetService( "ContentProvider" );
	["TeleportService"] = Game:GetService( "TeleportService" );
	["SoundService"] = Game:GetService( "SoundService" );
	["InsertService"] = Game:GetService( "InsertService" );
	["CollectionService"] = Game:GetService( "CollectionService" );
	["UserInputService"] = Game:GetService( "UserInputService" );
	["GamePassService"] = Game:GetService( "GamePassService" );
	["StarterPack"] = Game:GetService( "StarterPack" );
	["StarterGui"] = Game:GetService( "StarterGui" );
	["TestService"] = Game:GetService( "TestService" );
	["ServerScriptService"] = Game:GetService( "ServerScriptService" );
	["ServerStorage"] = Game:GetService( "ServerStorage" );
	["ReplicatedStorage"] = Game:GetService( "ReplicatedStorage" );
};

Tool = script.Parent;
Player = Services.Players.LocalPlayer;
Mouse = nil;
Camera = Services.Workspace.CurrentCamera;

dark_slanted_rectangle = "http://www.roblox.com/asset/?id=127774197";
light_slanted_rectangle = "http://www.roblox.com/asset/?id=127772502";
action_completion_sound = "http://www.roblox.com/asset/?id=99666917";
expand_arrow = "http://www.roblox.com/asset/?id=134367382";
tool_decal = "http://www.roblox.com/asset/?id=129748355";

------------------------------------------
-- Load external dependencies
------------------------------------------
RbxUtility = LoadLibrary( "RbxUtility" );
Services.ContentProvider:Preload( dark_slanted_rectangle );
Services.ContentProvider:Preload( light_slanted_rectangle );
Services.ContentProvider:Preload( action_completion_sound );
Services.ContentProvider:Preload( expand_arrow );
Services.ContentProvider:Preload( tool_decal );

------------------------------------------
-- Define functions that are depended-upon
------------------------------------------
function _findTableOccurrences( haystack, needle )
	-- Returns the positions of instances of `needle` in table `haystack`
	local positions = {};

	-- Add any indexes from `haystack` that have `needle`
	for index, value in pairs( haystack ) do
		if value == needle then
			table.insert( positions, index );
		end;
	end;

	return positions;
end;

function _getCollectionInfo( part_collection )
	-- Returns the size and position of collection of parts `part_collection`

	-- Get the corners
	local corners = {};

	-- Create shortcuts to certain things that are expensive to call constantly
	-- (note: otherwise it actually becomes an issue if the selection grows
	-- considerably large)
	local table_insert = table.insert;
	local newCFrame = CFrame.new;

	for _, Part in pairs( part_collection ) do

		local PartCFrame = Part.CFrame;
		local partCFrameOffset = PartCFrame.toWorldSpace;
		local PartSize = Part.Size / 2;
		local size_x, size_y, size_z = PartSize.x, PartSize.y, PartSize.z;

		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( size_x, size_y, size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( -size_x, size_y, size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( size_x, -size_y, size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( size_x, size_y, -size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( -size_x, size_y, -size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( -size_x, -size_y, size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( size_x, -size_y, -size_z ) ) );
		table_insert( corners, partCFrameOffset( PartCFrame, newCFrame( -size_x, -size_y, -size_z ) ) );

	end;

	-- Get the extents
	local x, y, z = {}, {}, {};

	for _, Corner in pairs( corners ) do
		table_insert( x, Corner.x );
		table_insert( y, Corner.y );
		table_insert( z, Corner.z );
	end;

	local x_min, y_min, z_min = math.min( unpack( x ) ),
								math.min( unpack( y ) ),
								math.min( unpack( z ) );

	local x_max, y_max, z_max = math.max( unpack( x ) ),
								math.max( unpack( y ) ),
								math.max( unpack( z ) );

	-- Get the size between the extents
	local x_size, y_size, z_size = 	x_max - x_min,
									y_max - y_min,
									z_max - z_min;

	local Size = Vector3.new( x_size, y_size, z_size );

	-- Get the centroid of the collection of points
	local Position = CFrame.new( 	x_min + ( x_max - x_min ) / 2,
									y_min + ( y_max - y_min ) / 2,
									z_min + ( z_max - z_min ) / 2 );

	-- Return the size of the collection of parts
	return Size, Position;
end;

function _round( number, places )
	-- Returns `number` rounded to the number of decimal `places`
	-- (from lua-users)

	local mult = 10 ^ ( places or 0 );

	return math.floor( number * mult + 0.5 ) / mult;

end

function _cloneTable( source )
	-- Returns a deep copy of table `source`

	-- Get a copy of `source`'s metatable, since the hacky method
	-- we're using to copy the table doesn't include its metatable
	local source_mt = getmetatable( source );

	-- Return a copy of `source` including its metatable
	return setmetatable( { unpack( source ) }, source_mt );
end;

function _getAllDescendants( Parent )
	-- Recursively gets all the descendants of  `Parent` and returns them

	local descendants = {};

	for _, Child in pairs( Parent:GetChildren() ) do

		-- Add the direct descendants of `Parent`
		table.insert( descendants, Child );

		-- Add the descendants of each child
		for _, Subchild in pairs( _getAllDescendants( Child ) ) do
			table.insert( descendants, Subchild );
		end;

	end;

	return descendants;

end;

function _pointToScreenSpace( Point )
	-- Returns Vector3 `Point`'s position on the screen when rendered
	-- (kudos to stravant for this)

	local point = Camera.CoordinateFrame:pointToObjectSpace( Point );
	local aspectRatio = Mouse.ViewSizeX / Mouse.ViewSizeY;
	local hfactor = math.tan( math.rad( Camera.FieldOfView ) / 2 )
	local wfactor = aspectRatio * hfactor;

	local x = ( point.x / point.z ) / -wfactor;
	local y = ( point.y / point.z ) /  hfactor;

	return Vector2.new( Mouse.ViewSizeX * ( 0.5 + 0.5 * x ), Mouse.ViewSizeY * ( 0.5 + 0.5 * y ) );

end;

------------------------------------------
-- Create data containers
------------------------------------------
ActiveKeys = {};

Options = setmetatable( {

	["_options"] = {
		["Tool"] = nil,
		["PreviousTool"] = nil
	}

}, {

	__newindex = function ( self, key, value )

		-- Do different special things depending on `key`
		if key == "Tool" then

			-- If it's a different tool than the current one
			if self.Tool ~= value then

				-- Run (if existent) the old tool's `Unequipped` listener
				if Options.Tool and Options.Tool.Listeners.Unequipped then
					Options.Tool.Listeners.Unequipped();
				end;

				rawget( self, "_options" ).PreviousTool = Options.Tool;
				rawget( self, "_options" ).Tool = nil;

				-- Replace the current handle with `value.Handle`
				local Handle = Tool:FindFirstChild( "Handle" );
				if Handle then
					Handle.Parent = nil;
				end;
				value.Handle.Parent = Tool;

				-- Adjust the grip for the new handle
				Tool.Grip = value.Grip;

				-- Run (if existent) the new tool's `Equipped` listener
				if value.Listeners.Equipped then
					value.Listeners.Equipped();
				end;

			end;
		end;

		-- Set the value normally to `self._options`
		rawget( self, "_options" )[key] = value;

	end;

	-- Get any options from `self._options` instead of `self` directly
	__index = function ( self, key )
		return rawget( self, "_options" )[key];
	end;

} );

-- Keep some state data
clicking = false;
selecting = false;
click_x, click_y = 0, 0;
override_selection = false;

SelectionBoxes = {};
SelectionExistenceListeners = {};
SelectionBoxColor = BrickColor.new( "Cyan" );

UI = RbxUtility.Create "ScreenGui" {
	Name = "Building Tools by F3X (UI)",
	Parent = Player.PlayerGui
};
Dragger = nil;

function updateSelectionBoxColor()
	-- Updates the color of the selectionboxes
	for _, SelectionBox in pairs( SelectionBoxes ) do
		SelectionBox.Color = SelectionBoxColor;
	end;
end;

Selection = {

	["Items"] = {};

	-- Provide events to listen to changes in the selection
	["Changed"] = RbxUtility.CreateSignal();
	["ItemAdded"] = RbxUtility.CreateSignal();
	["ItemRemoved"] = RbxUtility.CreateSignal();

	-- Provide a method to get an item's index in the selection
	["find"] = function ( self, Needle )

		-- Look through all the selected items and return the matching item's index
		for item_index, Item in pairs( self.Items ) do
			if Item == Needle then
				return item_index;
			end;
		end;

		-- Otherwise, return `nil`

	end;

	-- Provide a method to add items to the selection
	["add"] = function ( self, NewPart )

		-- Make sure `NewPart` isn't already in the selection
		if #_findTableOccurrences( self.Items, NewPart ) > 0 then
			return false;
		end;

		-- Insert it into the selection
		table.insert( self.Items, NewPart );

		-- Add its SelectionBox
		SelectionBoxes[NewPart] = Instance.new( "SelectionBox", UI );
		SelectionBoxes[NewPart].Name = "BTSelectionBox";
		SelectionBoxes[NewPart].Color = SelectionBoxColor;
		SelectionBoxes[NewPart].Adornee = NewPart;

		-- Remove any target selection box focus
		if NewPart == Options.TargetBox.Adornee then
			Options.TargetBox.Adornee = nil;
		end;

		-- Make sure to remove the item from the selection when it's deleted
		SelectionExistenceListeners[NewPart] = NewPart.AncestryChanged:connect( function ( Object, NewParent )
			if NewParent == nil then
				Selection:remove( NewPart );
			end;
		end );

		-- Provide a reference to the last item added to the selection (i.e. NewPart)
		self:focus( NewPart );

		-- Fire events
		self.ItemAdded:fire( NewPart );
		self.Changed:fire();

	end;

	-- Provide a method to remove items from the selection
	["remove"] = function ( self, Item )

		-- Make sure selection item `Item` exists
		if not self:find( Item ) then
			return false;
		end;

		-- Remove `Item`'s SelectionBox
		local SelectionBox = SelectionBoxes[Item];
		if SelectionBox then
			SelectionBox:Destroy();
		end;
		SelectionBoxes[Item] = nil;

		-- Delete the item from the selection
		table.remove( self.Items, self:find( Item ) );

		-- If it was logged as the last item, change it
		if self.Last == Item then
			self:focus( ( #self.Items > 0 ) and self.Items[#self.Items] or nil );
		end;

		-- Delete the existence listeners of the item
		SelectionExistenceListeners[Item]:disconnect();
		SelectionExistenceListeners[Item] = nil;

		-- Fire events
		self.ItemRemoved:fire( Item );
		self.Changed:fire();

	end;

	-- Provide a method to clear the selection
	["clear"] = function ( self )

		-- Go through all the items in the selection and call `self.remove` on them
		for _, Item in pairs( _cloneTable( self.Items ) ) do
			self:remove( Item );
		end;

	end;

	-- Provide a method to change the focus of the selection
	["focus"] = function ( self, NewFocus )

		-- Change the focus
		self.Last = NewFocus;

		-- Fire events
		self.Changed:fire();

	end;

};

Tools = {};

------------------------------------------
-- Move tool
------------------------------------------

-- Create the main container for this tool
Tools.Move = {};

-- Define the color of the tool
Tools.Move.Color = BrickColor.new( "Deep orange" );

-- Keep a container for the handles and other temporary stuff
Tools.Move.Temporary = {
	["Connections"] = {};
};

-- Keep options in a container too
Tools.Move.Options = {
	["increment"] = 1;
	["axes"] = "global";
};

-- Keep internal state data in its own container
Tools.Move.State = {
	["distance_moved"] = 0;
	["moving"] = false;
	["PreMove"] = {};
};

-- Add listeners
Tools.Move.Listeners = {};

-- Create the handle
Tools.Move.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = BrickColor.new( "Deep orange" );
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};

RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Move.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Move.Grip = CFrame.new( 0, 0, 0.4 );

Tools.Move.Listeners.Equipped = function ()

	-- Make sure the tool is actually being equipped (because this is the default tool)
	if not Mouse then
		return;
	end;

	-- Change the color of selection boxes temporarily
	Tools.Move.Temporary.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = Tools.Move.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	Tools.Move:showGUI();

	-- Create the boundingbox if it doesn't already exist
	if not Tools.Move.Temporary.BoundingBox then
		Tools.Move.Temporary.BoundingBox = RbxUtility.Create "Part" {
			Name = "BTBoundingBox";
			CanCollide = false;
			Transparency = 1;
			Anchored = true;
		};
	end;
	Mouse.TargetFilter = Tools.Move.Temporary.BoundingBox;

	-- Refresh the axis type option
	Tools.Move:changeAxes( Tools.Move.Options.axes );

	-- Listen for any keystrokes that might affect any dragging operation
	Tools.Move.Temporary.Connections.DraggerKeyListener = Mouse.KeyDown:connect( function ( key )

		local key = key:lower();

		-- Make sure a dragger exists
		if not Tools.Move.Temporary.Dragger then
			return;
		end;

		-- Rotate along the Z axis if `r` is pressed
		if key == "r" then
			Tools.Move.Temporary.Dragger:AxisRotate( Enum.Axis.Z );

		-- Rotate along the X axis if `t` is pressed
		elseif key == "t" then
			Tools.Move.Temporary.Dragger:AxisRotate( Enum.Axis.X );

		-- Rotate along the Y axis if `y` is pressed
		elseif key == "y" then
			Tools.Move.Temporary.Dragger:AxisRotate( Enum.Axis.Y );
		end;

		-- Simulate a mouse move so that it applies the changes
		Tools.Move.Temporary.Dragger:MouseMove( Mouse.UnitRay );

	end );

	-- Oh, and update the boundingbox and the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		Tools.Move.Temporary.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == Tools.Move then

				-- Update the GUI if it's visible
				if Tools.Move.Temporary.GUI and Tools.Move.Temporary.GUI.Visible then
					Tools.Move:updateGUI();
				end;

				-- Update the boundingbox if it's visible
				if Tools.Move.Options.axes == "global" then
					Tools.Move:updateBoundingBox();
				end;

			end;

		end;

	end )();

end;

Tools.Move.Listeners.Unequipped = function ()

	-- Stop the update loop
	Tools.Move.Temporary.Updater();
	Tools.Move.Temporary.Updater = nil;

	-- Hide the GUI
	Tools.Move:hideGUI();

	-- Hide the handles
	Tools.Move:hideHandles();

	-- Clear out any temporary connections
	for connection_index, Connection in pairs( Tools.Move.Temporary.Connections ) do
		Connection:disconnect();
		Tools.Move.Temporary.Connections[connection_index] = nil;
	end;

	-- Restore the original color of the selection boxes
	SelectionBoxColor = Tools.Move.Temporary.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Move.updateGUI = function ( self )

	if self.Temporary.GUI then
		local GUI = self.Temporary.GUI;

		if #Selection.Items > 0 then

			-- Look for identical numbers in each axis
			local position_x, position_y, position_z =  nil, nil, nil;
			for item_index, Item in pairs( Selection.Items ) do

				-- Set the first values for the first item
				if item_index == 1 then
					position_x, position_y, position_z = _round( Item.Position.x, 2 ), _round( Item.Position.y, 2 ), _round( Item.Position.z, 2 );

				-- Otherwise, compare them and set them to `nil` if they're not identical
				else
					if position_x ~= _round( Item.Position.x, 2 ) then
						position_x = nil;
					end;
					if position_y ~= _round( Item.Position.y, 2 ) then
						position_y = nil;
					end;
					if position_z ~= _round( Item.Position.z, 2 ) then
						position_z = nil;
					end;
				end;

			end;

			-- If each position along each axis is the same, display that number; otherwise, display "*"
			GUI.Info.Center.X.TextLabel.Text = position_x and tostring( position_x ) or "*";
			GUI.Info.Center.Y.TextLabel.Text = position_y and tostring( position_y ) or "*";
			GUI.Info.Center.Z.TextLabel.Text = position_z and tostring( position_z ) or "*";

			GUI.Info.Visible = true;
		else
			GUI.Info.Visible = false;
		end;

		if self.State.distance_moved then
			GUI.Changes.Text.Text = "moved " .. tostring( self.State.distance_moved ) .. " studs";
			GUI.Changes.Position = GUI.Info.Visible and UDim2.new( 0, 5, 0, 165 ) or UDim2.new( 0, 5, 0, 100 );
			GUI.Changes.Visible = true;
		else
			GUI.Changes.Text.Text = "";
			GUI.Changes.Visible = false;
		end;
	end;

end;

Tools.Move.Listeners.Button1Down = function ()

	if not Mouse.Target or ( Mouse.Target:IsA( "BasePart" ) and Mouse.Target.Locked ) then
		return;
	end;

	if not Selection:find( Mouse.Target ) then
		Selection:clear();
		Selection:add( Mouse.Target );
	end;

	Tools.Move.State.dragging = true;

	override_selection = true;

	Tools.Move.Temporary.Dragger = Instance.new( "Dragger" );

	Tools.Move.Temporary.Dragger:MouseDown( Mouse.Target, Mouse.Target.CFrame:toObjectSpace( CFrame.new( Mouse.Hit.p ) ).p, Selection.Items );

	Tools.Move.Temporary.Connections.DraggerConnection = Mouse.Button1Up:connect( function ()

		override_selection = true;

		if Tools.Move.Temporary.Connections.DraggerConnection then
			Tools.Move.Temporary.Connections.DraggerConnection:disconnect();
			Tools.Move.Temporary.Connections.DraggerConnection = nil;
		end;

		if not Tools.Move.Temporary.Dragger then
			return;
		end;

		Tools.Move.Temporary.Dragger:MouseUp();

		Tools.Move.State.dragging = false;

		Tools.Move.Temporary.Dragger:Destroy();
		Tools.Move.Temporary.Dragger = nil;

	end );

end;

Tools.Move.Listeners.Move = function ()

	if not Tools.Move.Temporary.Dragger then
		return;
	end;

	override_selection = true;

	Tools.Move.Temporary.Dragger:MouseMove( Mouse.UnitRay );

end;

Tools.Move.showGUI = function ( self )

	-- Create the GUI if it doesn't exist
	if not self.Temporary.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTMoveToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 280 );
			Size = UDim2.new( 0, 245, 0, 90 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "AxesOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption;
			Name = "Global";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 45, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption.Global;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.axes == "global" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.AxesOption.Global;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the axis type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changeAxes( "global" );
				Container.AxesOption.Global.SelectedIndicator.BackgroundTransparency = 0;
				Container.AxesOption.Global.Background.Image = dark_slanted_rectangle;
				Container.AxesOption.Local.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Local.Background.Image = light_slanted_rectangle;
				Container.AxesOption.Last.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Last.Background.Image = light_slanted_rectangle;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.AxesOption.Global;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.axes == "global" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.AxesOption.Global;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "GLOBAL";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption;
			Name = "Local";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 110, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption.Local;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.axes == "local" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.AxesOption.Local;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the axis type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changeAxes( "local" );
				Container.AxesOption.Global.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Global.Background.Image = light_slanted_rectangle;
				Container.AxesOption.Local.SelectedIndicator.BackgroundTransparency = 0;
				Container.AxesOption.Local.Background.Image = dark_slanted_rectangle;
				Container.AxesOption.Last.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Last.Background.Image = light_slanted_rectangle;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.AxesOption.Local;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.axes == "local" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.AxesOption.Local;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "LOCAL";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption;
			Name = "Last";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 175, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption.Last;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.axes == "last" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.AxesOption.Last;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the axis type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changeAxes( "last" );
				Container.AxesOption.Global.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Global.Background.Image = light_slanted_rectangle;
				Container.AxesOption.Local.SelectedIndicator.BackgroundTransparency = 1;
				Container.AxesOption.Local.Background.Image = light_slanted_rectangle;
				Container.AxesOption.Last.SelectedIndicator.BackgroundTransparency = 0;
				Container.AxesOption.Last.Background.Image = dark_slanted_rectangle;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.AxesOption.Last;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.axes == "last" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.AxesOption.Last;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "LAST";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.AxesOption;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.AxesOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Axes";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = Color3.new( 255 / 255, 170 / 255, 0 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "MOVE TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "IncrementOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 65 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Increment";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption.Increment;
			Name = "SelectedIndicator";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			Size = UDim2.new( 1, -4, 0, 2 );
			Position = UDim2.new( 0, 5, 0, -2 );
		};

		RbxUtility.Create "TextBox" {
			Parent = Container.IncrementOption.Increment;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = tostring( self.Options.increment );
			TextColor3 = Color3.new( 1, 1, 1 );

			-- Change the increment option when the value of the textbox is updated
			[RbxUtility.Create.E "FocusLost"] = function ( enter_pressed )
				if enter_pressed then
					self.Options.increment = tonumber( Container.IncrementOption.Increment.TextBox.Text ) or self.Options.increment;
					Container.IncrementOption.Increment.TextBox.Text = tostring( self.Options.increment );
				end;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.IncrementOption.Increment;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.IncrementOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Increment";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Info";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 100 );
			Size = UDim2.new( 1, -5, 0, 60 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 170 / 255, 0 );
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "SELECTION INFO";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "Center";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.Center;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Position";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0);
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.Center;
			Name = "X";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.Center.X;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.Center.X;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.Center;
			Name = "Y";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 117, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.Center.Y;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.Center.Y;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.Center;
			Name = "Z";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 164, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.Center.Z;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.Center.Z;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Changes";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 165 );
			Size = UDim2.new( 1, -5, 0, 20 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Changes;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 170 / 255, 0 );
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Changes;
			Name = "Text";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size11;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0.5;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Right;
		};

		self.Temporary.GUI = Container;
	end;

	-- Reveal the GUI
	self.Temporary.GUI.Visible = true;

end;

Tools.Move.hideGUI = function ( self )

	-- Hide the GUI if it exists
	if self.Temporary.GUI then
		self.Temporary.GUI.Visible = false;
	end;

end;

Tools.Move.showHandles = function ( self, Part )

	-- Create the handles if they don't exist yet
	if not self.Temporary.Handles then

		-- Create the object
		self.Temporary.Handles = RbxUtility.Create "Handles" {
			Name = "BTMovementHandles";
			Color = self.Color;
			Parent = Player.PlayerGui;
		};

		-- Add functionality to the handles

		self.Temporary.Handles.MouseButton1Down:connect( function ()

			-- Prevent the platform from thinking we're selecting
			override_selection = true;
			self.State.moving = true;

			-- Clear the change stats
			self.State.distance_moved = 0;

			-- Do a few things to the selection before manipulating it
			for _, Item in pairs( Selection.Items ) do

				-- Keep a copy of the state of each item
				self.State.PreMove[Item] = Item:Clone();

				-- Anchor each item
				Item.Anchored = true;

			end;

			-- Return stuff to normal once the mouse button is released
			self.Temporary.Connections.HandleReleaseListener = Mouse.Button1Up:connect( function ()

				-- Prevent the platform from thinking we're selecting
				override_selection = true;
				self.State.moving = false;

				-- Stop this connection from firing again
				if self.Temporary.Connections.HandleReleaseListener then
					self.Temporary.Connections.HandleReleaseListener:disconnect();
					self.Temporary.Connections.HandleReleaseListener = nil;
				end;

				-- Restore properties that may have been changed temporarily
				-- from the pre-movement state copies
				for Item, PreviousItemState in pairs( self.State.PreMove ) do
					Item.Anchored = PreviousItemState.Anchored;
					self.State.PreMove[Item] = nil;
					Item:MakeJoints();
					Item.Velocity = Vector3.new( 0, 0, 0 );
					Item.RotVelocity = Vector3.new( 0, 0, 0 );
				end;

			end );

		end );

		self.Temporary.Handles.MouseDrag:connect( function ( face, drag_distance )

			-- Calculate which multiple of the increment to use based on the current drag distance's
			-- proximity to their nearest upper and lower multiples

			local difference = drag_distance % self.Options.increment;

			local lower_degree = drag_distance - difference;
			local upper_degree = drag_distance - difference + self.Options.increment;

			local lower_degree_proximity = math.abs( drag_distance - lower_degree );
			local upper_degree_proximity = math.abs( drag_distance - upper_degree );

			if lower_degree_proximity <= upper_degree_proximity then
				drag_distance = lower_degree;
			else
				drag_distance = upper_degree;
			end;

			local increase = drag_distance;

			self.State.distance_moved = drag_distance;

			-- Increment the position of each selected item in the direction of `face`
			for _, Item in pairs( Selection.Items ) do

				-- Remove any joints connected with `Item` so that it can freely move
				Item:BreakJoints();

				-- Update the position of `Item` depending on the type of axes that is currently set
				if face == Enum.NormalId.Top then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( 0, increase, 0 ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( 0, increase, 0 ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, increase, 0 ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				elseif face == Enum.NormalId.Bottom then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( 0, -increase, 0 ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( 0, -increase, 0 ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, -increase, 0 ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				elseif face == Enum.NormalId.Front then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( 0, 0, -increase ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, -increase ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, 0, -increase ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				elseif face == Enum.NormalId.Back then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( 0, 0, increase ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, increase ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, 0, increase ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				elseif face == Enum.NormalId.Right then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( increase, 0, 0 ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( increase, 0, 0 ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( increase, 0, 0 ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				elseif face == Enum.NormalId.Left then
					if self.Options.axes == "global" then
						Item.CFrame = CFrame.new( self.State.PreMove[Item].CFrame.p ):toWorldSpace( CFrame.new( -increase, 0, 0 ) ) * CFrame.Angles( self.State.PreMove[Item].CFrame:toEulerAnglesXYZ() );
					elseif self.Options.axes == "local" then
						Item.CFrame = self.State.PreMove[Item].CFrame:toWorldSpace( CFrame.new( -increase, 0, 0 ) );
					elseif self.Options.axes == "last" then
						Item.CFrame = self.State.PreMove[Selection.Last].CFrame:toWorldSpace( CFrame.new( -increase, 0, 0 ) ):toWorldSpace( self.State.PreMove[Item].CFrame:toObjectSpace( self.State.PreMove[Selection.Last].CFrame ):inverse() );
					end;

				end;

			end;

		end );

	end;

	-- Stop listening for the existence of the previous adornee (if any)
	if self.Temporary.Connections.AdorneeExistenceListener then
		self.Temporary.Connections.AdorneeExistenceListener:disconnect();
		self.Temporary.Connections.AdorneeExistenceListener = nil;
	end;

	-- Attach the handles to `Part`
	self.Temporary.Handles.Adornee = Part;

	-- Make sure to hide the handles if `Part` suddenly stops existing
	self.Temporary.Connections.AdorneeExistenceListener = Part.AncestryChanged:connect( function ( Object, NewParent )

		-- Make sure this change in parent applies directly to `Part`
		if Object ~= Part then
			return;
		end;

		-- Show the handles according to the existence of the part
		if NewParent == nil then
			self:hideHandles();
		else
			self:showHandles( Part );
		end;

	end );

end;

Tools.Move.hideHandles = function ( self )

	-- Hide the handles if they exist
	if self.Temporary.Handles then
		self.Temporary.Handles.Adornee = nil;
	end;

end;

Tools.Move.updateBoundingBox = function ( self )

	if #Selection.Items > 0 and not self.State.dragging then
		local SelectionSize, SelectionPosition = _getCollectionInfo( Selection.Items );
		self.Temporary.BoundingBox.Size = SelectionSize;
		self.Temporary.BoundingBox.CFrame = SelectionPosition;
		self:showHandles( self.Temporary.BoundingBox );

	else
		self:hideHandles();
	end;

end;

Tools.Move.changeAxes = function ( self, new_axes )

	-- Have a quick reference to the GUI (if any)
	local AxesOptionGUI = self.Temporary.GUI and self.Temporary.GUI.AxesOption or nil;

	-- Disconnect any handle-related listeners that are specific to a certain axes option

	if self.Temporary.Connections.HandleFocusChangeListener then
		self.Temporary.Connections.HandleFocusChangeListener:disconnect();
		self.Temporary.Connections.HandleFocusChangeListener = nil;
	end;

	if self.Temporary.Connections.HandleSelectionChangeListener then
		self.Temporary.Connections.HandleSelectionChangeListener:disconnect();
		self.Temporary.Connections.HandleSelectionChangeListener = nil;
	end;

	if new_axes == "global" then

		-- Update the options
		self.Options.axes = "global";

		-- Clear out any previous adornee
		self:hideHandles();

		-- Focus the handles on the boundary box
		self:showHandles( self.Temporary.BoundingBox );

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			AxesOptionGUI.Global.SelectedIndicator.BackgroundTransparency = 0;
			AxesOptionGUI.Global.Background.Image = dark_slanted_rectangle;
			AxesOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Local.Background.Image = light_slanted_rectangle;
			AxesOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Last.Background.Image = light_slanted_rectangle;
		end;

	end;

	if new_axes == "local" then

		-- Update the options
		self.Options.axes = "local";

		-- Always have the handles on the most recent addition to the selection
		self.Temporary.Connections.HandleSelectionChangeListener = Selection.Changed:connect( function ()

			-- Clear out any previous adornee
			self:hideHandles();

			-- If there /is/ a last item in the selection, attach the handles to it
			if Selection.Last then
				self:showHandles( Selection.Last );
			end;

		end );

		-- Switch the adornee of the handles if the second mouse button is pressed
		self.Temporary.Connections.HandleFocusChangeListener = Mouse.Button2Up:connect( function ()

			-- Make sure the platform doesn't think we're selecting
			override_selection = true;

			-- If the target is in the selection, make it the new adornee
			if Selection:find( Mouse.Target ) then
				Selection:focus( Mouse.Target );
				self:showHandles( Mouse.Target );
			end;

		end );

		-- Finally, attach the handles to the last item added to the selection (if any)
		if Selection.Last then
			self:showHandles( Selection.Last );
		end;

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			AxesOptionGUI.Global.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Global.Background.Image = light_slanted_rectangle;
			AxesOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 0;
			AxesOptionGUI.Local.Background.Image = dark_slanted_rectangle;
			AxesOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Last.Background.Image = light_slanted_rectangle;
		end;

	end;

	if new_axes == "last" then

		-- Update the options
		self.Options.axes = "last";

		-- Always have the handles on the most recent addition to the selection
		self.Temporary.Connections.HandleSelectionChangeListener = Selection.Changed:connect( function ()

			-- Clear out any previous adornee
			self:hideHandles();

			-- If there /is/ a last item in the selection, attach the handles to it
			if Selection.Last then
				self:showHandles( Selection.Last );
			end;

		end );

		-- Switch the adornee of the handles if the second mouse button is pressed
		self.Temporary.Connections.HandleFocusChangeListener = Mouse.Button2Up:connect( function ()

			-- Make sure the platform doesn't think we're selecting
			override_selection = true;

			-- If the target is in the selection, make it the new adornee
			if Selection:find( Mouse.Target ) then
				Selection:focus( Mouse.Target );
				self:showHandles( Mouse.Target );
			end;

		end );

		-- Finally, attach the handles to the last item added to the selection (if any)
		if Selection.Last then
			self:showHandles( Selection.Last );
		end;

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			AxesOptionGUI.Global.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Global.Background.Image = light_slanted_rectangle;
			AxesOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 1;
			AxesOptionGUI.Local.Background.Image = light_slanted_rectangle;
			AxesOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 0;
			AxesOptionGUI.Last.Background.Image = dark_slanted_rectangle;
		end;

	end;

end;

------------------------------------------
-- Resize tool
------------------------------------------

-- Create the tool
Tools.Resize = {};

-- Create structures that will be used within the tool
Tools.Resize.Temporary = {
	["Connections"] = {};
};

Tools.Resize.Options = {
	["increment"] = 1;
	["directions"] = "normal";
};

Tools.Resize.State = {
	["PreResize"] = {};
	["previous_distance"] = 0;
	["resizing"] = false;
	["length_resized"] = 0;
};

Tools.Resize.Listeners = {};

-- Define the color of the tool
Tools.Resize.Color = BrickColor.new( "Cyan" );

-- Create the handle
Tools.Resize.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Resize.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Resize.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Resize.Grip = CFrame.new( 0, 0, 0.4 );

Tools.Resize.Listeners.Equipped = function ()

	-- Change the color of selection boxes temporarily
	Tools.Resize.Temporary.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = Tools.Resize.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	Tools.Resize:showGUI();

	-- Always have the handles on the most recent addition to the selection
	table.insert( Tools.Resize.Temporary.Connections, Selection.Changed:connect( function ()

		-- Clear out any previous adornee
		Tools.Resize:hideHandles();

		-- If there /is/ a last item in the selection, attach the handles to it
		if Selection.Last then
			Tools.Resize:showHandles( Selection.Last );
		end;

	end ) );

	-- Switch the adornee of the handles if the second mouse button is pressed
	table.insert( Tools.Resize.Temporary.Connections, Mouse.Button2Up:connect( function ()

		-- Make sure the platform doesn't think we're selecting
		override_selection = true;

		-- If the target is in the selection, make it the new adornee
		if Selection:find( Mouse.Target ) then
			Tools.Resize:showHandles( Mouse.Target );
		end;

	end ) );

	-- Finally, attach the handles to the last item added to the selection (if any)
	if Selection.Last then
		Tools.Resize:showHandles( Selection.Last );
	end;

	-- Update the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		Tools.Resize.Temporary.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == Tools.Resize then

				-- Update the GUI if it's visible
				if Tools.Resize.Temporary.GUI and Tools.Resize.Temporary.GUI.Visible then
					Tools.Resize:updateGUI();
				end;

			end;

		end;

	end )();

end;

Tools.Resize.Listeners.Unequipped = function ()

	-- Stop the update loop
	Tools.Resize.Temporary.Updater();
	Tools.Resize.Temporary.Updater = nil;

	-- Hide the GUI
	Tools.Resize:hideGUI();

	-- Hide the handles
	Tools.Resize:hideHandles();

	-- Clear out any temporary connections
	for connection_index, Connection in pairs( Tools.Resize.Temporary.Connections ) do
		Connection:disconnect();
		Tools.Resize.Temporary.Connections[connection_index] = nil;
	end;

	-- Restore the original color of the selection boxes
	SelectionBoxColor = Tools.Resize.Temporary.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Resize.showGUI = function ( self )

	-- Create the GUI if it doesn't exist
	if not self.Temporary.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTResizeToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 280 );
			Size = UDim2.new( 0, 245, 0, 90 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "DirectionsOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.DirectionsOption;
			Name = "Normal";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.DirectionsOption.Normal;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.directions == "normal" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.DirectionsOption.Normal;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the axis type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self.Options.directions = "normal";
				Container.DirectionsOption.Normal.SelectedIndicator.BackgroundTransparency = 0;
				Container.DirectionsOption.Normal.Background.Image = dark_slanted_rectangle;
				Container.DirectionsOption.Both.SelectedIndicator.BackgroundTransparency = 1;
				Container.DirectionsOption.Both.Background.Image = light_slanted_rectangle;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.DirectionsOption.Normal;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.directions == "normal" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.DirectionsOption.Normal;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "NORMAL";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.DirectionsOption;
			Name = "Both";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 135, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.DirectionsOption.Both;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.directions == "both" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.DirectionsOption.Both;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the axis type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self.Options.directions = "both";
				Container.DirectionsOption.Normal.SelectedIndicator.BackgroundTransparency = 1;
				Container.DirectionsOption.Normal.Background.Image = light_slanted_rectangle;
				Container.DirectionsOption.Both.SelectedIndicator.BackgroundTransparency = 0;
				Container.DirectionsOption.Both.Background.Image = dark_slanted_rectangle;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.DirectionsOption.Both;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.directions == "both" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.DirectionsOption.Both;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "BOTH";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.DirectionsOption;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Size = UDim2.new( 0, 75, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.DirectionsOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Directions";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = self.Color.Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "RESIZE TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "IncrementOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 65 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Increment";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption.Increment;
			Name = "SelectedIndicator";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			Size = UDim2.new( 1, -4, 0, 2 );
			Position = UDim2.new( 0, 5, 0, -2 );
		};

		RbxUtility.Create "TextBox" {
			Parent = Container.IncrementOption.Increment;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = tostring( self.Options.increment );
			TextColor3 = Color3.new( 1, 1, 1 );

			-- Change the increment option when the value of the textbox is updated
			[RbxUtility.Create.E "FocusLost"] = function ( enter_pressed )
				if enter_pressed then
					self.Options.increment = tonumber( Container.IncrementOption.Increment.TextBox.Text ) or self.Options.increment;
					Container.IncrementOption.Increment.TextBox.Text = tostring( self.Options.increment );
				end;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.IncrementOption.Increment;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.IncrementOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Increment";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Info";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 100 );
			Size = UDim2.new( 1, -5, 0, 60 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "SELECTION INFO";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "SizeInfo";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.SizeInfo;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Size";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0);
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.SizeInfo;
			Name = "X";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.SizeInfo.X;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.SizeInfo.X;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.SizeInfo;
			Name = "Y";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 117, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.SizeInfo.Y;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.SizeInfo.Y;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.SizeInfo;
			Name = "Z";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 164, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.SizeInfo.Z;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.SizeInfo.Z;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Changes";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 165 );
			Size = UDim2.new( 1, -5, 0, 20 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Changes;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Changes;
			Name = "Text";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size11;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0.5;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Right;
		};

		self.Temporary.GUI = Container;
	end;

	-- Reveal the GUI
	self.Temporary.GUI.Visible = true;

end;

Tools.Resize.updateGUI = function ( self )

	-- Make sure the GUI exists
	if not self.Temporary.GUI then
		return;
	end;

	local GUI = self.Temporary.GUI;

	if #Selection.Items > 0 then

		-- Look for identical numbers in each axis
		local size_x, size_y, size_z =  nil, nil, nil;
		for item_index, Item in pairs( Selection.Items ) do

			-- Set the first values for the first item
			if item_index == 1 then
				size_x, size_y, size_z = _round( Item.Size.x, 2 ), _round( Item.Size.y, 2 ), _round( Item.Size.z, 2 );

			-- Otherwise, compare them and set them to `nil` if they're not identical
			else
				if size_x ~= _round( Item.Size.x, 2 ) then
					size_x = nil;
				end;
				if size_y ~= _round( Item.Size.y, 2 ) then
					size_y = nil;
				end;
				if size_z ~= _round( Item.Size.z, 2 ) then
					size_z = nil;
				end;
			end;

		end;

		-- Update the size info on the GUI
		GUI.Info.SizeInfo.X.TextLabel.Text = size_x and tostring( size_x ) or "*";
		GUI.Info.SizeInfo.Y.TextLabel.Text = size_y and tostring( size_y ) or "*";
		GUI.Info.SizeInfo.Z.TextLabel.Text = size_z and tostring( size_z ) or "*";

		GUI.Info.Visible = true;
	else
		GUI.Info.Visible = false;
	end;

	if self.State.length_resized then
		GUI.Changes.Text.Text = "resized " .. tostring( self.State.length_resized ) .. " studs";
		GUI.Changes.Position = GUI.Info.Visible and UDim2.new( 0, 5, 0, 165 ) or UDim2.new( 0, 5, 0, 100 );
		GUI.Changes.Visible = true;
	else
		GUI.Changes.Text.Text = "";
		GUI.Changes.Visible = false;
	end;

end;

Tools.Resize.hideGUI = function ( self )

	-- Hide the GUI if it exists
	if self.Temporary.GUI then
		self.Temporary.GUI.Visible = false;
	end;

end;

Tools.Resize.showHandles = function ( self, Part )

	-- Create the handles if they don't exist yet
	if not self.Temporary.Handles then

		-- Create the object
		self.Temporary.Handles = RbxUtility.Create "Handles" {
			Name = "BTResizeHandles";
			Style = Enum.HandlesStyle.Resize;
			Color = self.Color;
			Parent = Player.PlayerGui;
		};

		-- Add functionality to the handles
		self.Temporary.Handles.MouseButton1Down:connect( function ()

			-- Prevent the platform from thinking we're selecting
			override_selection = true;
			self.State.resizing = true;

			-- Clear the change stats
			self.State.length_resized = 0;

			-- Do a few things to the selection before manipulating it
			for _, Item in pairs( Selection.Items ) do

				-- Keep a copy of the state of each item
				self.State.PreResize[Item] = Item:Clone();

				-- Make the item be able to be freely resized
				Item.FormFactor = Enum.FormFactor.Custom;

				-- Anchor each item
				Item.Anchored = true;

			end;

			-- Return stuff to normal once the mouse button is released
			self.Temporary.Connections.HandleReleaseListener = Mouse.Button1Up:connect( function ()

				-- Prevent the platform from thinking we're selecting
				override_selection = true;
				self.State.resizing = false;

				-- Stop this connection from firing again
				if self.Temporary.Connections.HandleReleaseListener then
					self.Temporary.Connections.HandleReleaseListener:disconnect();
					self.Temporary.Connections.HandleReleaseListener = nil;
				end;

				-- Restore properties that may have been changed temporarily
				-- from the pre-resize state copies
				for Item, PreviousItemState in pairs( self.State.PreResize ) do
					Item.Anchored = PreviousItemState.Anchored;
					self.State.PreResize[Item] = nil;
					Item:MakeJoints();
				end;

			end );

		end );

		self.Temporary.Handles.MouseDrag:connect( function ( face, drag_distance )

			-- Calculate which multiple of the increment to use based on the current drag distance's
			-- proximity to their nearest upper and lower multiples

			local difference = drag_distance % self.Options.increment;

			local lower_degree = drag_distance - difference;
			local upper_degree = drag_distance - difference + self.Options.increment;

			local lower_degree_proximity = math.abs( drag_distance - lower_degree );
			local upper_degree_proximity = math.abs( drag_distance - upper_degree );

			if lower_degree_proximity <= upper_degree_proximity then
				drag_distance = lower_degree;
			else
				drag_distance = upper_degree;
			end;

			local increase = drag_distance;

			-- Log the distance that the handle was dragged
			self.State.previous_distance = drag_distance;

			-- Note the length by which the selection will be enlarged
			if self.Options.directions == "both" then
				increase = drag_distance * 2;
			end;
			self.State.length_resized = increase;

			-- Go through the selection and make changes to it
			for _, Item in pairs( Selection.Items ) do

				-- Keep a copy of `Item` in case we need to revert anything
				local PreviousItemState = Item:Clone();

				-- Break any of `Item`'s joints so it can move freely
				Item:BreakJoints();

				-- Position and resize `Item` according to the options and the handle that was used

				if face == Enum.NormalId.Top then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( 0, increase, 0 );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( 0, increase / 2, 0 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;

				elseif face == Enum.NormalId.Bottom then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( 0, increase, 0 );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( 0, -increase / 2, 0 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;

				elseif face == Enum.NormalId.Front then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( 0, 0, increase );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, -increase / 2 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;

				elseif face == Enum.NormalId.Back then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( 0, 0, increase );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, increase / 2 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;

				elseif face == Enum.NormalId.Left then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( increase, 0, 0 );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( -increase / 2, 0, 0 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;

				elseif face == Enum.NormalId.Right then

					-- Calculate the appropriate increment to the size based on the shape of `Item`
					local SizeIncrease;
					if Item.Shape == Enum.PartType.Ball or Item.Shape == Enum.PartType.Cylinder then
						SizeIncrease = Vector3.new( increase, increase, increase );
					elseif Item.Shape == Enum.PartType.Block then
						SizeIncrease = Vector3.new( increase, 0, 0 );
					end;

					Item.Size = self.State.PreResize[Item].Size + SizeIncrease;
					if Item.Size == self.State.PreResize[Item].Size + SizeIncrease then
						Item.CFrame = ( self.Options.directions == "normal" and self.State.PreResize[Item].CFrame:toWorldSpace( CFrame.new( increase / 2, 0, 0 ) ) )
									  or ( self.Options.directions == "both" and self.State.PreResize[Item].CFrame );
					-- If the resizing was not possible, revert `Item`'s state
					else
						Item.Size = PreviousItemState.Size;
						Item.CFrame = PreviousItemState.CFrame;
					end;
				end;

				-- Make joints with surrounding parts again once the resizing is done
				Item:MakeJoints();

			end;

		end );

	end;

	-- Stop listening for the existence of the previous adornee (if any)
	if self.Temporary.Connections.AdorneeExistenceListener then
		self.Temporary.Connections.AdorneeExistenceListener:disconnect();
		self.Temporary.Connections.AdorneeExistenceListener = nil;
	end;

	-- Attach the handles to `Part`
	self.Temporary.Handles.Adornee = Part;

	-- Make sure to hide the handles if `Part` suddenly stops existing
	self.Temporary.Connections.AdorneeExistenceListener = Part.AncestryChanged:connect( function ( Object, NewParent )

		-- Make sure this change in parent applies directly to `Part`
		if Object ~= Part then
			return;
		end;

		-- Show the handles according to the existence of the part
		if NewParent == nil then
			self:hideHandles();
		else
			self:showHandles( Part );
		end;

	end );

end;

Tools.Resize.hideHandles = function ( self )

	-- Hide the handles if they exist
	if self.Temporary.Handles then
		self.Temporary.Handles.Adornee = nil;
	end;

end;

------------------------------------------
-- Rotate tool
------------------------------------------

-- Create the tool
Tools.Rotate = {};

-- Create structures to hold data that the tool needs
Tools.Rotate.Temporary = {
	["Connections"] = {};
};

Tools.Rotate.Options = {
	["increment"] = 15;
	["pivot"] = "center"
};

Tools.Rotate.State = {
	["PreRotation"] = {};
	["rotating"] = false;
	["previous_distance"] = 0;
	["degrees_rotated"] = 0;
	["rotation_size"] = 0;
};

Tools.Rotate.Listeners = {};

-- Define the color of the tool
Tools.Rotate.Color = BrickColor.new( "Bright green" );

-- Create the handle
Tools.Rotate.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Rotate.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Rotate.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Rotate.Grip = CFrame.new( 0, 0, 0.4 );

-- Start adding functionality to the tool
Tools.Rotate.Listeners.Equipped = function ()

	-- Change the color of selection boxes temporarily
	Tools.Rotate.Temporary.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = Tools.Rotate.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	Tools.Rotate:showGUI();

	-- Create the boundingbox if it doesn't already exist
	if not Tools.Rotate.Temporary.BoundingBox then
		Tools.Rotate.Temporary.BoundingBox = RbxUtility.Create "Part" {
			Name = "BTBoundingBox";
			CanCollide = false;
			Transparency = 1;
			Anchored = true;
		};
	end;
	Mouse.TargetFilter = Tools.Rotate.Temporary.BoundingBox;

	-- Update the pivot option
	Tools.Rotate:changePivot( Tools.Rotate.Options.pivot );

	-- Oh, and update the boundingbox and the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		Tools.Rotate.Temporary.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == Tools.Rotate then

				-- Update the GUI if it's visible
				if Tools.Rotate.Temporary.GUI and Tools.Rotate.Temporary.GUI.Visible then
					Tools.Rotate:updateGUI();
				end;

				-- Update the boundingbox if it's visible
				if Tools.Rotate.Options.pivot == "center" then
					Tools.Rotate:updateBoundingBox();
				end;

			end;

		end;

	end )();

	-- Also enable the ability to select an edge as a pivot
	SelectEdge:start( function ( EdgeMarker )
		Tools.Rotate:changePivot( "last" );
		Tools.Rotate.Temporary.SelectedEdge = EdgeMarker;
		table.insert( Tools.Rotate.Temporary.Connections, Selection.Changed:connect( function ()
			if Selection.Last ~= EdgeMarker then
				EdgeMarker:Destroy();
				Tools.Rotate.Temporary.SelectedEdge = nil;
			end;
		end ) );
	end );

end;

Tools.Rotate.Listeners.Unequipped = function ()

	-- Stop the update loop
	Tools.Rotate.Temporary.Updater();
	Tools.Rotate.Temporary.Updater = nil;

	-- Disable the ability to select edges
	SelectEdge:stop();
	if Tools.Rotate.Temporary.SelectedEdge then
		Tools.Rotate.Temporary.SelectedEdge:Destroy();
	end;

	-- Hide the GUI
	Tools.Rotate:hideGUI();

	-- Hide the handles
	Tools.Rotate:hideHandles();

	-- Clear out any temporary connections
	for connection_index, Connection in pairs( Tools.Rotate.Temporary.Connections ) do
		Connection:disconnect();
		Tools.Rotate.Temporary.Connections[connection_index] = nil;
	end;

	-- Restore the original color of the selection boxes
	SelectionBoxColor = Tools.Rotate.Temporary.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Rotate.showGUI = function ( self )

	-- Create the GUI if it doesn't exist
	if not self.Temporary.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTRotateToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 280 );
			Size = UDim2.new( 0, 245, 0, 90 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "PivotOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption;
			Name = "Center";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 50, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption.Center;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.pivot == "center" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.PivotOption.Center;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the pivot type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changePivot( "center" );
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.PivotOption.Center;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.pivot == "center" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.PivotOption.Center;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "CENTER";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption;
			Name = "Local";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 115, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption.Local;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.pivot == "local" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.PivotOption.Local;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the pivot type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changePivot( "local" );
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.PivotOption.Local;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.pivot == "local" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.PivotOption.Local;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "LOCAL";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption;
			Name = "Last";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 180, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption.Last;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 6, 0, -2 );
			Size = UDim2.new( 1, -5, 0, 2 );
			BackgroundTransparency = ( self.Options.pivot == "last" ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.PivotOption.Last;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the pivot type option when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:changePivot( "last" );
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.PivotOption.Last;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.Options.pivot == "last" ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.PivotOption.Last;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "LAST";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.PivotOption;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.PivotOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Pivot";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = self.Color.Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "ROTATE TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "IncrementOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 65 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Increment";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption.Increment;
			Name = "SelectedIndicator";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			Size = UDim2.new( 1, -4, 0, 2 );
			Position = UDim2.new( 0, 5, 0, -2 );
		};

		RbxUtility.Create "TextBox" {
			Parent = Container.IncrementOption.Increment;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = tostring( self.Options.increment );
			TextColor3 = Color3.new( 1, 1, 1 );

			-- Change the increment option when the value of the textbox is updated
			[RbxUtility.Create.E "FocusLost"] = function ( enter_pressed )
				if enter_pressed then
					self.Options.increment = tonumber( Container.IncrementOption.Increment.TextBox.Text ) or self.Options.increment;
					Container.IncrementOption.Increment.TextBox.Text = tostring( self.Options.increment );
				end;
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.IncrementOption.Increment;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.IncrementOption;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.IncrementOption.Label;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Increment";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Info";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 100 );
			Size = UDim2.new( 1, -5, 0, 60 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info;
			Name = "Label";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "SELECTION INFO";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info;
			Name = "RotationInfo";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.RotationInfo;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 0, 75, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Rotation";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0);
			TextStrokeTransparency = 0;
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.RotationInfo;
			Name = "X";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 70, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.RotationInfo.X;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.RotationInfo.X;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.RotationInfo;
			Name = "Y";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 117, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.RotationInfo.Y;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.RotationInfo.Y;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Info.RotationInfo;
			Name = "Z";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 164, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Info.RotationInfo.Z;
			Name = "TextLabel";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextWrapped = true;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Info.RotationInfo.Z;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Image = light_slanted_rectangle;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Changes";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 165 );
			Size = UDim2.new( 1, -5, 0, 20 );
			Visible = false;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Changes;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Changes;
			Name = "Text";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 10, 0, 2 );
			Size = UDim2.new( 1, -10, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size11;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0.5;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Right;
		};

		self.Temporary.GUI = Container;
	end;

	-- Reveal the GUI
	self.Temporary.GUI.Visible = true;

end;

Tools.Rotate.updateGUI = function ( self )

	-- Make sure the GUI exists
	if not self.Temporary.GUI then
		return;
	end;

	local GUI = self.Temporary.GUI;

	if #Selection.Items > 0 then

		-- Look for identical numbers in each axis
		local rot_x, rot_y, rot_z = nil, nil, nil;
		for item_index, Item in pairs( Selection.Items ) do

			local item_rot_x, item_rot_y, item_rot_z = Item.CFrame:toEulerAnglesXYZ();

			-- Set the first values for the first item
			if item_index == 1 then
				rot_x, rot_y, rot_z = _round( math.deg( item_rot_x ), 2 ), _round( math.deg( item_rot_y ), 2 ), _round( math.deg( item_rot_z ), 2 );

			-- Otherwise, compare them and set them to `nil` if they're not identical
			else
				if rot_x ~= _round( math.deg( item_rot_x ), 2 ) then
					rot_x = nil;
				end;
				if rot_y ~= _round( math.deg( item_rot_y ), 2 ) then
					rot_y = nil;
				end;
				if rot_z ~= _round( math.deg( item_rot_z ), 2 ) then
					rot_z = nil;
				end;
			end;

		end;

		-- Update the size info on the GUI
		GUI.Info.RotationInfo.X.TextLabel.Text = rot_x and tostring( rot_x ) or "*";
		GUI.Info.RotationInfo.Y.TextLabel.Text = rot_y and tostring( rot_y ) or "*";
		GUI.Info.RotationInfo.Z.TextLabel.Text = rot_z and tostring( rot_z ) or "*";

		GUI.Info.Visible = true;
	else
		GUI.Info.Visible = false;
	end;

	if self.State.degrees_rotated then
		GUI.Changes.Text.Text = "rotated " .. tostring( self.State.degrees_rotated ) .. " degrees";
		GUI.Changes.Position = GUI.Info.Visible and UDim2.new( 0, 5, 0, 165 ) or UDim2.new( 0, 5, 0, 100 );
		GUI.Changes.Visible = true;
	else
		GUI.Changes.Text.Text = "";
		GUI.Changes.Visible = false;
	end;

end;

Tools.Rotate.hideGUI = function ( self )

	-- Hide the GUI if it exists
	if self.Temporary.GUI then
		self.Temporary.GUI.Visible = false;
	end;

end;

Tools.Rotate.updateBoundingBox = function ( self )

	if #Selection.Items > 0 then
		local SelectionSize, SelectionPosition = _getCollectionInfo( Selection.Items );
		self.Temporary.BoundingBox.Size = SelectionSize;
		self.Temporary.BoundingBox.CFrame = SelectionPosition;
		self:showHandles( self.Temporary.BoundingBox );

	else
		self:hideHandles();
	end;

end;

Tools.Rotate.changePivot = function ( self, new_pivot )

	-- Have a quick reference to the GUI (if any)
	local PivotOptionGUI = self.Temporary.GUI and self.Temporary.GUI.PivotOption or nil;

	-- Disconnect any handle-related listeners that are specific to a certain pivot option
	if self.Temporary.Connections.HandleFocusChangeListener then
		self.Temporary.Connections.HandleFocusChangeListener:disconnect();
		self.Temporary.Connections.HandleFocusChangeListener = nil;
	end;

	if self.Temporary.Connections.HandleSelectionChangeListener then
		self.Temporary.Connections.HandleSelectionChangeListener:disconnect();
		self.Temporary.Connections.HandleSelectionChangeListener = nil;
	end;

	-- Remove any temporary edge selection
	if self.Temporary.SelectedEdge then
		self.Temporary.SelectedEdge:Destroy();
		self.Temporary.SelectedEdge = nil;
	end;

	if new_pivot == "center" then

		-- Update the options
		self.Options.pivot = "center";

		-- Focus the handles on the boundingbox
		self:showHandles( self.Temporary.BoundingBox );

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			PivotOptionGUI.Center.SelectedIndicator.BackgroundTransparency = 0;
			PivotOptionGUI.Center.Background.Image = dark_slanted_rectangle;
			PivotOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Local.Background.Image = light_slanted_rectangle;
			PivotOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Last.Background.Image = light_slanted_rectangle;
		end;

	end;

	if new_pivot == "local" then

		-- Update the options
		self.Options.pivot = "local";

		-- Always have the handles on the most recent addition to the selection
		self.Temporary.Connections.HandleSelectionChangeListener = Selection.Changed:connect( function ()

			-- Clear out any previous adornee
			self:hideHandles();

			-- If there /is/ a last item in the selection, attach the handles to it
			if Selection.Last then
				self:showHandles( Selection.Last );
			end;

		end );

		-- Switch the adornee of the handles if the second mouse button is pressed
		self.Temporary.Connections.HandleFocusChangeListener = Mouse.Button2Up:connect( function ()

			-- Make sure the platform doesn't think we're selecting
			override_selection = true;

			-- If the target is in the selection, make it the new adornee
			if Selection:find( Mouse.Target ) then
				Selection:focus( Mouse.Target );
				self:showHandles( Mouse.Target );
			end;

		end );

		-- Finally, attach the handles to the last item added to the selection (if any)
		if Selection.Last then
			self:showHandles( Selection.Last );
		end;

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			PivotOptionGUI.Center.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Center.Background.Image = light_slanted_rectangle;
			PivotOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 0;
			PivotOptionGUI.Local.Background.Image = dark_slanted_rectangle;
			PivotOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Last.Background.Image = light_slanted_rectangle;
		end;

	end;

	if new_pivot == "last" then

		-- Update the options
		self.Options.pivot = "last";

		-- Always have the handles on the most recent addition to the selection
		self.Temporary.Connections.HandleSelectionChangeListener = Selection.Changed:connect( function ()

			-- Clear out any previous adornee
			self:hideHandles();

			-- If there /is/ a last item in the selection, attach the handles to it
			if Selection.Last then
				self:showHandles( Selection.Last );
			end;

		end );

		-- Switch the adornee of the handles if the second mouse button is pressed
		self.Temporary.Connections.HandleFocusChangeListener = Mouse.Button2Up:connect( function ()

			-- Make sure the platform doesn't think we're selecting
			override_selection = true;

			-- If the target is in the selection, make it the new adornee
			if Selection:find( Mouse.Target ) then
				Selection:focus( Mouse.Target );
				self:showHandles( Mouse.Target );
			end;

		end );

		-- Finally, attach the handles to the last item added to the selection (if any)
		if Selection.Last then
			self:showHandles( Selection.Last );
		end;

		-- Update the GUI's option panel
		if self.Temporary.GUI then
			PivotOptionGUI.Center.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Center.Background.Image = light_slanted_rectangle;
			PivotOptionGUI.Local.SelectedIndicator.BackgroundTransparency = 1;
			PivotOptionGUI.Local.Background.Image = light_slanted_rectangle;
			PivotOptionGUI.Last.SelectedIndicator.BackgroundTransparency = 0;
			PivotOptionGUI.Last.Background.Image = dark_slanted_rectangle;
		end;

	end;

end;


Tools.Rotate.showHandles = function ( self, Part )

	-- Create the handles if they don't exist yet
	if not self.Temporary.Handles then

		-- Create the object
		self.Temporary.Handles = RbxUtility.Create "ArcHandles" {
			Name = "BTRotationHandles";
			Color = self.Color;
			Parent = Player.PlayerGui;
		};

		-- Add functionality to the handles

		self.Temporary.Handles.MouseButton1Down:connect( function ()

			-- Prevent the platform from thinking we're selecting
			override_selection = true;
			self.State.rotating = true;

			-- Clear the change stats
			self.State.degrees_rotated = 0;
			self.State.rotation_size = 0;

			-- Do a few things to the selection before manipulating it
			for _, Item in pairs( Selection.Items ) do

				-- Keep a copy of the state of each item
				self.State.PreRotation[Item] = Item:Clone();

				-- Anchor each item
				Item.Anchored = true;

			end;

			-- Also keep the position of the original selection
			local PreRotationSize, PreRotationPosition = _getCollectionInfo( self.State.PreRotation );
			self.State.PreRotationPosition = PreRotationPosition;

			-- Return stuff to normal once the mouse button is released
			self.Temporary.Connections.HandleReleaseListener = Mouse.Button1Up:connect( function ()

				-- Prevent the platform from thinking we're selecting
				override_selection = true;
				self.State.rotating = false;

				-- Stop this connection from firing again
				if self.Temporary.Connections.HandleReleaseListener then
					self.Temporary.Connections.HandleReleaseListener:disconnect();
					self.Temporary.Connections.HandleReleaseListener = nil;
				end;

				-- Restore properties that may have been changed temporarily
				-- from the pre-rotation state copies
				for Item, PreviousItemState in pairs( self.State.PreRotation ) do
					Item.Anchored = PreviousItemState.Anchored;
					self.State.PreRotation[Item] = nil;
					Item:MakeJoints();
				end;

			end );

		end );

		self.Temporary.Handles.MouseDrag:connect( function ( axis, drag_distance )

			-- Round down and convert the drag distance to degrees to make it easier to work with
			local drag_distance = math.floor( math.deg( drag_distance ) );

			-- Calculate which multiple of the increment to use based on the current angle's
			-- proximity to their nearest upper and lower multiples

			local difference = drag_distance % self.Options.increment;

			local lower_degree = drag_distance - difference;
			local upper_degree = drag_distance - difference + self.Options.increment;

			local lower_degree_proximity = math.abs( drag_distance - lower_degree );
			local upper_degree_proximity = math.abs( drag_distance - upper_degree );

			if lower_degree_proximity <= upper_degree_proximity then
				drag_distance = lower_degree;
			else
				drag_distance = upper_degree;
			end;

			local increase = self.Options.increment * math.floor( drag_distance / self.Options.increment );

			self.State.degrees_rotated = drag_distance;

			-- Go through the selection and make changes to it
			for _, Item in pairs( Selection.Items ) do

				-- Keep a copy of `Item` in case we need to revert anything
				local PreviousItemState = Item:Clone();

				-- Break any of `Item`'s joints so it can move freely
				Item:BreakJoints();

				-- Rotate `Item` according to the options and the handle that was used
				if axis == Enum.Axis.Y then
					if self.Options.pivot == "center" then
						Item.CFrame = self.State.PreRotationPosition:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, math.rad( increase ), 0 ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotationPosition ):inverse() );
					elseif self.Options.pivot == "local" then
						Item.CFrame = self.State.PreRotation[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, math.rad( increase ), 0 ) );
					elseif self.Options.pivot == "last" then
						Item.CFrame = self.State.PreRotation[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, math.rad( increase ), 0 ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotation[Selection.Last].CFrame ):inverse() );
					end;
				elseif axis == Enum.Axis.X then
					if self.Options.pivot == "center" then
						Item.CFrame = self.State.PreRotationPosition:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( math.rad( increase ), 0, 0 ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotationPosition ):inverse() );
					elseif self.Options.pivot == "local" then
						Item.CFrame = self.State.PreRotation[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( math.rad( increase ), 0, 0 ) );
					elseif self.Options.pivot == "last" then
						Item.CFrame = self.State.PreRotation[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( math.rad( increase ), 0, 0 ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotation[Selection.Last].CFrame ):inverse() );
					end;
				elseif axis == Enum.Axis.Z then
					if self.Options.pivot == "center" then
						Item.CFrame = self.State.PreRotationPosition:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, 0, math.rad( increase ) ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotationPosition ):inverse() );
					elseif self.Options.pivot == "local" then
						Item.CFrame = self.State.PreRotation[Item].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, 0, math.rad( increase ) ) );
					elseif self.Options.pivot == "last" then
						Item.CFrame = self.State.PreRotation[Selection.Last].CFrame:toWorldSpace( CFrame.new( 0, 0, 0 ) * CFrame.Angles( 0, 0, math.rad( increase ) ) ):toWorldSpace( self.State.PreRotation[Item].CFrame:toObjectSpace( self.State.PreRotation[Selection.Last].CFrame ):inverse() );
					end;
				end;

				-- Make joints with surrounding parts again once the resizing is done
				Item:MakeJoints();

			end;

		end );

	end;

	-- Stop listening for the existence of the previous adornee (if any)
	if self.Temporary.Connections.AdorneeExistenceListener then
		self.Temporary.Connections.AdorneeExistenceListener:disconnect();
		self.Temporary.Connections.AdorneeExistenceListener = nil;
	end;

	-- Attach the handles to `Part`
	self.Temporary.Handles.Adornee = Part;

	-- Make sure to hide the handles if `Part` suddenly stops existing
	self.Temporary.Connections.AdorneeExistenceListener = Part.AncestryChanged:connect( function ( Object, NewParent )

		-- Make sure this change in parent applies directly to `Part`
		if Object ~= Part then
			return;
		end;

		-- Show the handles according to the existence of the part
		if NewParent == nil then
			self:hideHandles();
		else
			self:showHandles( Part );
		end;

	end );

end;

Tools.Rotate.hideHandles = function ( self )

	-- Hide the handles if they exist
	if self.Temporary.Handles then
		self.Temporary.Handles.Adornee = nil;
	end;

end;


------------------------------------------
-- Paint tool
------------------------------------------

-- Create the main container for this tool
Tools.Paint = {};

-- Define the color of the tool
Tools.Paint.Color = BrickColor.new( "Really red" );

-- Define options
Tools.Paint.Options = {
	["Color"] = nil
};

Tools.Paint.Temporary = {};

-- Add listeners
Tools.Paint.Listeners = {};

-- Create the handle
Tools.Paint.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Paint.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Paint.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Paint.Grip = CFrame.new( 0, 0, 0.4 );

Tools.Paint.Listeners.Equipped = function ()

	-- Change the color of selection boxes temporarily
	Tools.Paint.Temporary.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = Tools.Paint.Color;
	updateSelectionBoxColor();

	-- Show the GUI
	Tools.Paint:showGUI();

	-- Update the selected color
	Tools.Paint:changeColor( Tools.Paint.Options.Color );

end;

Tools.Paint.Listeners.Unequipped = function ()

	-- Clear out the preferred color option
	Tools.Paint:changeColor( nil );

	-- Hide the GUI
	Tools.Paint:hideGUI();

	-- Restore the original color of the selection boxes
	SelectionBoxColor = Tools.Paint.Temporary.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Paint.Listeners.Button1Up = function ()

	-- Make sure that they clicked on one of the items in their selection
	-- (and they weren't multi-selecting)
	if Selection:find( Mouse.Target ) and not selecting and not selecting then

		override_selection = true;

		-- Paint all of the selected items `Tools.Paint.Options.Color`
		if Tools.Paint.Options.Color then
			for _, Item in pairs( Selection.Items ) do
				Item.BrickColor = Tools.Paint.Options.Color;
			end;
		end;

	end;

end;

Tools.Paint.changeColor = function ( self, Color )

	-- Alright so if `Color` is given, set that as the preferred color
	if Color then

		-- First of all, change the color option itself
		self.Options.Color = Color;

		-- Then, we want to update the color of any items in the selection
		for _, Item in pairs( Selection.Items ) do
			Item.BrickColor = Color;
		end;

		-- After that, we want to mark our new color in the palette
		if self.Temporary.GUI then

			-- First clear out any other marks
			for _, ColorSquare in pairs( self.Temporary.GUI.Palette:GetChildren() ) do
				ColorSquare.Text = "";
			end;

			-- Then mark the right square
			self.Temporary.GUI.Palette[Color.Name].Text = "X";

		end;

	-- Otherwise, let's assume no color at all
	else

		-- Set the preferred color to none
		self.Options.Color = nil;

		-- Clear out any color option marks on any of the squares
		if self.Temporary.GUI then
			for _, ColorSquare in pairs( self.Temporary.GUI.Palette:GetChildren() ) do
				ColorSquare.Text = "";
			end;
		end;

	end;

end;

Tools.Paint.showGUI = function ( self )

	-- Create the GUI if it doesn't exist
	if not self.Temporary.GUI then

		-- Create the GUI container
		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTPaintGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 230 );
			Size = UDim2.new( 0, 205, 0, 230 );
			Draggable = true;
		};
		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = BrickColor.new( "Really red" ).Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "PAINT TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		-- Create the frame that will contain the colors
		local PaletteFrame = RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Palette";
			BackgroundColor3 = Color3.new( 0, 0, 0 );
			Transparency = 1;
			Size = UDim2.new( 0, 205, 0, 205 );
			Position = UDim2.new( 0, 5, 0, 20 );
		};

		-- Insert the colors
		for palette_index = 0, 63 do

			-- Get BrickColor `palette_index` from the palette
			local Color = BrickColor.palette( palette_index );

			-- Calculate the row and column in the 8x8 grid
			local row = ( palette_index - ( palette_index % 8 ) ) / 8;
			local column = palette_index % 8;

			-- Create the button
			local ColorButton = RbxUtility.Create "TextButton" {
				Parent = PaletteFrame;
				Name = Color.Name;
				BackgroundColor3 = Color.Color;
				Size = UDim2.new( 0, 20, 0, 20 );
				Text = "";
				TextStrokeTransparency = 0.75;
				Font = Enum.Font.Arial;
				FontSize = Enum.FontSize.Size12;
				TextColor3 = Color3.new( 1, 1, 1 );
				TextStrokeColor3 = Color3.new( 0, 0, 0 );
				Position = UDim2.new( 0, column * 25 + 5, 0, row * 25 + 5 );
				BorderSizePixel = 0;

				-- Make the button change the `Color` option
				[RbxUtility.Create.E "MouseButton1Click"] = function ()
					self:changeColor( Color );
				end;
			};

		end;

		self.Temporary.GUI = Container;
	end;

	-- Reveal the GUI
	self.Temporary.GUI.Visible = true;

end;

Tools.Paint.hideGUI = function ( self )

	-- Hide the GUI if it exists
	if self.Temporary.GUI then
		self.Temporary.GUI.Visible = false;
	end;

end;

------------------------------------------
-- Anchor tool
------------------------------------------

-- Create the tool
Tools.Anchor = {};

-- Create structures to hold data that the tool needs
Tools.Anchor.Temporary = {
	["Connections"] = {};
};

Tools.Anchor.State = {
	["anchored"] = nil;
};

Tools.Anchor.Listeners = {};

-- Define the color of the tool
Tools.Anchor.Color = BrickColor.new( "Really black" );

-- Create the handle
Tools.Anchor.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Anchor.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Anchor.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Anchor.Grip = CFrame.new( 0, 0, 0.4 );

-- Start adding functionality to the tool

Tools.Anchor.Listeners.Equipped = function ()

	-- Change the color of selection boxes temporarily
	Tools.Anchor.Temporary.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = Tools.Anchor.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	Tools.Anchor:showGUI();

	-- Update the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		Tools.Anchor.Temporary.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == Tools.Anchor then

				-- Update the anchor status of every item in the selection
				local anchor_status = nil;
				for item_index, Item in pairs( Selection.Items ) do

					-- Set the first values for the first item
					if item_index == 1 then
						anchor_status = Item.Anchored;

					-- Otherwise, compare them and set them to `nil` if they're not identical
					else
						if anchor_status ~= Item.Anchored then
							anchor_status = nil;
						end;
					end;

				end;

				Tools.Anchor.State.anchored = anchor_status;

				-- Update the GUI if it's visible
				if Tools.Anchor.Temporary.GUI and Tools.Anchor.Temporary.GUI.Visible then
					Tools.Anchor:updateGUI();
				end;

			end;

		end;

	end )();

	-- Listen for the Enter button to be pressed to toggle the anchor
	Tools.Anchor.Temporary.Connections.EnterButtonListener = Mouse.KeyDown:connect( function ( key )

		local key = key:lower();
		local key_code = key:byte();

		-- If the Enter button is pressed
		if key_code == 13 then

			if Tools.Anchor.State.anchored == true then
				Tools.Anchor:unanchor();

			elseif Tools.Anchor.State.anchored == false then
				Tools.Anchor:anchor();

			elseif Tools.Anchor.State.anchored == nil then
				Tools.Anchor:anchor();

			end;

		end;

	end );

end;

Tools.Anchor.anchor = function ( self )

	-- Anchor all the items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item.Anchored = true;
	end;

end;

Tools.Anchor.unanchor = function ( self )

	-- Unanchor all the items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item.Anchored = false;
	end;

end;

Tools.Anchor.showGUI = function ( self )

	-- Create the GUI if it doesn't exist
	if not self.Temporary.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTAnchorToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 280 );
			Size = UDim2.new( 0, 245, 0, 90 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = self.Color.Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "ANCHOR TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Status";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 30 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Status;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 14, 0, 0 );
			Size = UDim2.new( 0, 40, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Status";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Status;
			Name = "Anchored";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 55, 0, 0 );
			Size = UDim2.new( 0, 90, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Status.Anchored;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 9, 0, -2 );
			Size = UDim2.new( 1, -9, 0, 2 );
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BackgroundTransparency = ( self.State.anchored == true ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.Status.Anchored;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the anchor status when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:anchor();
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Status.Anchored;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.State.anchored == true ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Status.Anchored;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "ANCHORED";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Status;
			Name = "Unanchored";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 140, 0, 0 );
			Size = UDim2.new( 0, 90, 0, 25 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Status.Unanchored;
			Name = "SelectedIndicator";
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 9, 0, -2 );
			Size = UDim2.new( 1, -9, 0, 2 );
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			BackgroundTransparency = ( self.State.anchored == false ) and 0 or 1;
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.Status.Unanchored;
			Name = "Button";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 2;
			Text = "";
			TextTransparency = 1;

			-- Change the anchor status when the button is clicked
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self:unanchor();
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.Status.Unanchored;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = ( self.State.anchored == false ) and dark_slanted_rectangle or light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Status.Unanchored;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "UNANCHORED";
			TextColor3 = Color3.new( 1, 1, 1 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Tip";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 70 );
			Size = UDim2.new( 1, -5, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Tip;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Tip;
			Name = "Text";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 0, 0, 2 );
			Size = UDim2.new( 1, 0, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size11;
			Text = "TIP: Press Enter to quickly toggle the anchor.";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0.5;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Center;
		};
		self.Temporary.GUI = Container;
	end;

	-- Reveal the GUI
	self.Temporary.GUI.Visible = true;

end;

Tools.Anchor.updateGUI = function ( self )

	-- Make sure the GUI exists
	if not self.Temporary.GUI then
		return;
	end;

	local GUI = self.Temporary.GUI;

	if self.State.anchored == nil then
		GUI.Status.Anchored.Background.Image = light_slanted_rectangle;
		GUI.Status.Anchored.SelectedIndicator.BackgroundTransparency = 1;
		GUI.Status.Unanchored.Background.Image = light_slanted_rectangle;
		GUI.Status.Unanchored.SelectedIndicator.BackgroundTransparency = 1;

	elseif self.State.anchored == true then
		GUI.Status.Anchored.Background.Image = dark_slanted_rectangle;
		GUI.Status.Anchored.SelectedIndicator.BackgroundTransparency = 0;
		GUI.Status.Unanchored.Background.Image = light_slanted_rectangle;
		GUI.Status.Unanchored.SelectedIndicator.BackgroundTransparency = 1;

	elseif self.State.anchored == false then
		GUI.Status.Anchored.Background.Image = light_slanted_rectangle;
		GUI.Status.Anchored.SelectedIndicator.BackgroundTransparency = 1;
		GUI.Status.Unanchored.Background.Image = dark_slanted_rectangle;
		GUI.Status.Unanchored.SelectedIndicator.BackgroundTransparency = 0;

	end;

end;

Tools.Anchor.hideGUI = function ( self )

	-- Hide the GUI if it exists
	if self.Temporary.GUI then
		self.Temporary.GUI.Visible = false;
	end;

end;

Tools.Anchor.Listeners.Unequipped = function ()

	-- Stop the update loop
	Tools.Anchor.Temporary.Updater();
	Tools.Anchor.Temporary.Updater = nil;

	-- Hide the GUI
	Tools.Anchor:hideGUI();

	-- Clear out any temporary connections
	for connection_index, Connection in pairs( Tools.Anchor.Temporary.Connections ) do
		Connection:disconnect();
		Tools.Anchor.Temporary.Connections[connection_index] = nil;
	end;

	-- Restore the original color of the selection boxes
	SelectionBoxColor = Tools.Anchor.Temporary.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

------------------------------------------
-- Surface tool
------------------------------------------

-- Create the tool
Tools.Surface = {};

-- Define the tool's color
Tools.Surface.Color = BrickColor.new( "Bright violet" );

-- Keep a container for temporary connections
Tools.Surface.Connections = {};

-- Keep a container for state data
Tools.Surface.State = {
	["type"] = nil;
};

-- Maintain a container for options
Tools.Surface.Options = {
	["side"] = Enum.NormalId.Top;
};

-- Keep a container for platform event connections
Tools.Surface.Listeners = {};

-- Create the handle
Tools.Surface.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Surface.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Surface.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Surface.Grip = CFrame.new( 0, 0, 0.4 );

-- Start adding functionality to the tool
Tools.Surface.Listeners.Equipped = function ()

	local self = Tools.Surface;

	-- Change the color of selection boxes temporarily
	self.State.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = self.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	self:showGUI();

	-- Restore the side option
	self:changeSurface( self.Options.side );

	-- Update the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		self.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == self then

				-- Update the surface type of every item in the selection
				local surface_type = nil;
				for item_index, Item in pairs( Selection.Items ) do

					-- Set the first values for the first item
					if item_index == 1 then
						surface_type = Item[self.Options.side.Name .. "Surface"];

					-- Otherwise, compare them and set them to `nil` if they're not identical
					else
						if surface_type ~= Item[self.Options.side.Name .. "Surface"] then
							surface_type = nil;
						end;
					end;

				end;

				self.State.type = surface_type;

				-- Update the GUI if it's visible
				if self.GUI and self.GUI.Visible then
					self:updateGUI();
				end;

			end;

		end;

	end )();

end;

Tools.Surface.Listeners.Unequipped = function ()

	local self = Tools.Surface;

	-- Stop the GUI updating loop
	self.Updater();
	self.Updater = nil;

	-- Hide the GUI
	self:hideGUI();

	-- Disconnect temporary connections
	for connection_index, Connection in pairs( self.Connections ) do
		Connection:disconnect();
		self.Connections[connection_index] = nil;
	end;

	-- Restore the original color of selection boxes
	SelectionBoxColor = self.State.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Surface.Listeners.Button2Down = function ()

	local self = Tools.Surface;

	-- Capture the camera rotation (for later use
	-- in determining whether a surface was being
	-- selected or the camera was being rotated
	-- with the right mouse button)
	local cr_x, cr_y, cr_z = Camera.CoordinateFrame:toEulerAnglesXYZ();
	self.State.PreB2DownCameraRotation = Vector3.new( cr_x, cr_y, cr_z );

end;

Tools.Surface.Listeners.Button2Up = function ()

	local self = Tools.Surface;

	local cr_x, cr_y, cr_z = Camera.CoordinateFrame:toEulerAnglesXYZ();
	local CameraRotation = Vector3.new( cr_x, cr_y, cr_z );

	-- If a surface is selected
	if Selection:find( Mouse.Target ) and self.State.PreB2DownCameraRotation == CameraRotation then
		self:changeSurface( Mouse.TargetSurface );
	end;

end;

Tools.Surface.SpecialTypeNames = {
	SmoothNoOutlines = "NO OUTLINE",
	Inlet = "INLETS"
};

Tools.Surface.changeType = function ( self, surface_type )
	-- Apply `surface_type` to all items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item[self.Options.side.Name .. "Surface"] = surface_type;
	end;
	self.TypeDropdown:selectOption( self.SpecialTypeNames[surface_type.Name] or surface_type.Name:upper() );
	if self.TypeDropdown.open then
		self.TypeDropdown:toggle();
	end;
end;

Tools.Surface.changeSurface = function ( self, surface )
	self.Options.side = surface;
	self.SideDropdown:selectOption( surface.Name:upper() );
	if self.SideDropdown.open then
		self.SideDropdown:toggle();
	end;
end;

Tools.Surface.updateGUI = function ( self )

	-- Make sure the GUI exists
	if not self.GUI then
		return;
	end;

	if #Selection.Items > 0 then
		self.TypeDropdown:selectOption( self.State.type and ( self.SpecialTypeNames[self.State.type.Name] or self.State.type.Name:upper() ) or "*" );
	else
		self.TypeDropdown:selectOption( "" );
	end;

end;

function createDropdown()

	local Frame = RbxUtility.Create "Frame" {
		Name = "Dropdown";
		Size = UDim2.new( 0, 20, 0, 20 );
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ClipsDescendants = true;
	};

	RbxUtility.Create "ImageLabel" {
		Parent = Frame;
		Name = "Arrow";
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Image = expand_arrow;
		Position = UDim2.new( 1, -21, 0, 3 );
		Size = UDim2.new( 0, 20, 0, 20 );
		ZIndex = 3;
	};

	local DropdownObject = {
		-- Provide access to the actual frame
		Frame = Frame;

		-- Keep a list of all the options in the dropdown
		_options = {};

		-- Provide a function to add options to the dropdown
		addOption = function ( self, option )

			-- Add the option to the list
			table.insert( self._options, option );

			-- Create the GUI for the option
			local Button = RbxUtility.Create "TextButton" {
				Parent = self.Frame;
				BackgroundColor3 = Color3.new( 0, 0, 0 );
				BackgroundTransparency = 0.3;
				BorderColor3 = Color3.new( 27 / 255, 42 / 255, 53 / 255 );
				BorderSizePixel = 1;
				Name = option;
				Position = UDim2.new( math.ceil( #self._options / 9 ) - 1, 0, 0, 25 * ( ( #self._options % 9 == 0 ) and 9 or ( #self._options % 9 ) ) );
				Size = UDim2.new( 1, 0, 0, 25 );
				ZIndex = 3;
				Text = "";
			};
			local Label = RbxUtility.Create "TextLabel" {
				Parent = Button;
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Position = UDim2.new( 0, 6, 0, 0 );
				Size = UDim2.new( 1, -30, 1, 0 );
				ZIndex = 3;
				Font = Enum.Font.ArialBold;
				FontSize = Enum.FontSize.Size12;
				Text = option;
				TextColor3 = Color3.new( 1, 1, 1 );
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
			};

			-- Return the button object
			return Button;

		end;

		selectOption = function ( self, option )
			self.Frame.MainButton.CurrentOption.Text = option;
		end;

		open = false;

		toggle = function ( self )

			-- If it's open, close it
			if self.open then
				self.Frame.MainButton.BackgroundTransparency = 0.3;
				self.Frame.ClipsDescendants = true;
				self.open = false;

			-- If it's not open, open it
			else
				self.Frame.MainButton.BackgroundTransparency = 0;
				self.Frame.ClipsDescendants = false;
				self.open = true;
			end;

		end;

	};

	-- Create the GUI for the option
	local MainButton = RbxUtility.Create "TextButton" {
		Parent = Frame;
		Name = "MainButton";
		BackgroundColor3 = Color3.new( 0, 0, 0 );
		BackgroundTransparency = 0.3;
		BorderColor3 = Color3.new( 27 / 255, 42 / 255, 53 / 255 );
		BorderSizePixel = 1;
		Position = UDim2.new( 0, 0, 0, 0 );
		Size = UDim2.new( 1, 0, 0, 25 );
		ZIndex = 2;
		Text = "";

		-- Toggle the dropdown when pressed
		[RbxUtility.Create.E "MouseButton1Up"] = function ()
			DropdownObject:toggle();
		end;
	};
	RbxUtility.Create "TextLabel" {
		Parent = MainButton;
		Name = "CurrentOption";
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new( 0, 6, 0, 0 );
		Size = UDim2.new( 1, -30, 1, 0 );
		ZIndex = 3;
		Font = Enum.Font.ArialBold;
		FontSize = Enum.FontSize.Size12;
		Text = "";
		TextColor3 = Color3.new( 1, 1, 1 );
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
	};

	return DropdownObject;

end;

Tools.Surface.showGUI = function ( self )

	-- Create the GUI if it doesn't already exist
	if not self.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTSurfaceToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 172 );
			Size = UDim2.new( 0, 245, 0, 90 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = self.Color.Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "SURFACE TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "SideOption";
			Position = UDim2.new( 0, 14, 0, 30 );
			Size = UDim2.new( 0, 120, 0, 25 );
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.SideOption;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Name = "Label";
			Size = UDim2.new( 0, 40, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Side";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		local SideDropdown = createDropdown();
		self.SideDropdown = SideDropdown;
		SideDropdown.Frame.Parent = Container.SideOption;
		SideDropdown.Frame.Position = UDim2.new( 0, 30, 0, 0 );
		SideDropdown.Frame.Size = UDim2.new( 0, 72, 0, 25 );

		SideDropdown:addOption( "TOP" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Top );
		end );
		SideDropdown:addOption( "BOTTOM" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Bottom );
		end );
		SideDropdown:addOption( "FRONT" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Front );
		end );
		SideDropdown:addOption( "BACK" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Back );
		end );
		SideDropdown:addOption( "LEFT" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Left );
		end );
		SideDropdown:addOption( "RIGHT" ).MouseButton1Up:connect( function ()
			self:changeSurface( Enum.NormalId.Right );
		end );

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "TypeOption";
			Position = UDim2.new( 0, 124, 0, 30 );
			Size = UDim2.new( 0, 120, 0, 25 );
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.TypeOption;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Name = "Label";
			Size = UDim2.new( 0, 40, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Type";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		local TypeDropdown = createDropdown();
		self.TypeDropdown = TypeDropdown;
		TypeDropdown.Frame.Parent = Container.TypeOption;
		TypeDropdown.Frame.Position = UDim2.new( 0, 30, 0, 0 );
		TypeDropdown.Frame.Size = UDim2.new( 0, 87, 0, 25 );

		TypeDropdown:addOption( "STUDS" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Studs );
		end );
		TypeDropdown:addOption( "INLETS" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Inlet );
		end );
		TypeDropdown:addOption( "SMOOTH" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Smooth );
		end );
		TypeDropdown:addOption( "WELD" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Weld );
		end );
		TypeDropdown:addOption( "GLUE" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Glue );
		end );
		TypeDropdown:addOption( "UNIVERSAL" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Universal );
		end );
		TypeDropdown:addOption( "HINGE" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Hinge );
		end );
		TypeDropdown:addOption( "MOTOR" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.Motor );
		end );
		TypeDropdown:addOption( "NO OUTLINE" ).MouseButton1Up:connect( function ()
			self:changeType( Enum.SurfaceType.SmoothNoOutlines );
		end );

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Tip";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 70 );
			Size = UDim2.new( 1, -5, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Tip;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Tip;
			Name = "Text";
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 6, 0, 2 );
			Size = UDim2.new( 1, -6, 0, 20 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size11;
			Text = "TIP: Select a part and right click on a surface";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextStrokeTransparency = 0.5;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
		};

		self.GUI = Container;

	end;

	-- Reveal the GUI
	self.GUI.Visible = true;

end;

Tools.Surface.hideGUI = function ( self )

	-- Hide the GUI if it exists already
	if self.GUI then
		self.GUI.Visible = false;
	end;

end;

------------------------------------------
-- Material tool
------------------------------------------

-- Create the tool
Tools.Material = {};
Tools.Material.Color = BrickColor.new( "Bright violet" );
Tools.Material.Connections = {};
Tools.Material.State = {
	["material"] = nil;
	["reflectance_focused"] = false;
	["transparency_focused"] = false;
};
Tools.Material.Listeners = {};
Tools.Material.SpecialMaterialNames = {
	CorrodedMetal = "CORRODED METAL",
	DiamondPlate = "DIAMOND PLATE",
	SmoothPlastic = "SMOOTH PLASTIC"
};

-- Create the handle
Tools.Material.Handle = RbxUtility.Create "Part" {
	Name = "Handle";
	Locked = true;
	BrickColor = Tools.Material.Color;
	FormFactor = Enum.FormFactor.Custom;
	Size = Vector3.new( 0.8, 0.8, 0.8 );
	TopSurface = Enum.SurfaceType.Smooth;
	BottomSurface = Enum.SurfaceType.Smooth;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Front;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Back;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Left;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Right;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Top;
	Texture = tool_decal;
};
RbxUtility.Create "Decal" {
	Parent = Tools.Material.Handle;
	Face = Enum.NormalId.Bottom;
	Texture = tool_decal;
};

-- Set the grip for the handle
Tools.Material.Grip = CFrame.new( 0, 0, 0.4 );

-- Start adding functionality to the tool
Tools.Material.Listeners.Equipped = function ()

	local self = Tools.Material;

	-- Change the color of selection boxes temporarily
	self.State.PreviousSelectionBoxColor = SelectionBoxColor;
	SelectionBoxColor = self.Color;
	updateSelectionBoxColor();

	-- Reveal the GUI
	self:showGUI();

	-- Update the GUI regularly
	coroutine.wrap( function ()
		local updater_on = true;

		-- Provide a function to stop the loop
		self.Updater = function ()
			updater_on = false;
		end;

		while wait( 0.1 ) and updater_on do

			-- Make sure the tool's equipped
			if Options.Tool == self then

				-- Update the material type of every item in the selection
				local material_type, transparency, reflectance = nil, nil, nil;
				for item_index, Item in pairs( Selection.Items ) do

					-- Set the first values for the first item
					if item_index == 1 then
						material_type = Item.Material;
						transparency = Item.Transparency;
						reflectance = Item.Reflectance;

					-- Otherwise, compare them and set them to `nil` if they're not identical
					else
						if material_type ~= Item.Material then
							material_type = nil;
						end;
						if reflectance ~= Item.Reflectance then
							reflectance = nil;
						end;
						if transparency ~= Item.Transparency then
							transparency = nil;
						end;
					end;

				end;

				self.State.material = material_type;
				self.State.transparency = transparency;
				self.State.reflectance = reflectance;

				-- Update the GUI if it's visible
				if self.GUI and self.GUI.Visible then
					self:updateGUI();
				end;

			end;

		end;

	end )();

end;

Tools.Material.Listeners.Unequipped = function ()

	local self = Tools.Material;

	-- Stop the GUI updating loop
	self.Updater();
	self.Updater = nil;

	-- Hide the GUI
	self:hideGUI();

	-- Disconnect temporary connections
	for connection_index, Connection in pairs( self.Connections ) do
		Connection:disconnect();
		self.Connections[connection_index] = nil;
	end;

	-- Restore the original color of selection boxes
	SelectionBoxColor = self.State.PreviousSelectionBoxColor;
	updateSelectionBoxColor();

end;

Tools.Material.changeMaterial = function ( self, material_type )
	-- Apply `material_type` to all items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item.Material = material_type;
	end;
	if self.MaterialDropdown.open then
		self.MaterialDropdown:toggle();
	end;
end;

Tools.Material.changeTransparency = function ( self, transparency )
	-- Apply `transparency` to all items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item.Transparency = transparency;
	end;
end;

Tools.Material.changeReflectance = function ( self, reflectance )
	-- Apply `reflectance` to all items in the selection
	for _, Item in pairs( Selection.Items ) do
		Item.Reflectance = reflectance;
	end;
end;

Tools.Material.updateGUI = function ( self )

	-- Make sure the GUI exists
	if not self.GUI then
		return;
	end;

	if #Selection.Items > 0 then
		self.MaterialDropdown:selectOption( self.State.material and ( self.SpecialMaterialNames[self.State.material.Name] or self.State.material.Name:upper() ) or "*" );

		-- Update the text inputs without interrupting the user
		if not self.State.transparency_focused then
			self.GUI.TransparencyOption.TransparencyInput.TextBox.Text = self.State.transparency and tostring( _round( self.State.transparency, 2 ) ) or "*";
		end;
		if not self.State.reflectance_focused then
			self.GUI.ReflectanceOption.ReflectanceInput.TextBox.Text = self.State.reflectance and tostring( _round( self.State.reflectance, 2 ) ) or "*";
		end;

	else
		self.MaterialDropdown:selectOption( "" );
		self.GUI.TransparencyOption.TransparencyInput.TextBox.Text = "";
		self.GUI.ReflectanceOption.ReflectanceInput.TextBox.Text = "";
	end;

end;


Tools.Material.showGUI = function ( self )

	-- Create the GUI if it doesn't already exist
	if not self.GUI then

		local Container = RbxUtility.Create "Frame" {
			Parent = UI;
			Name = "BTMaterialToolGUI";
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 172 );
			Size = UDim2.new( 0, 200, 0, 135 );
			Draggable = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Title";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Title;
			Name = "ColorBar";
			BackgroundColor3 = self.Color.Color;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, -3 );
			Size = UDim2.new( 1, -5, 0, 2 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "Label";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "MATERIAL TOOL";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.Title;
			Name = "F3XSignature";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 10, 0, 1 );
			Size = UDim2.new( 1, -10, 1, 0 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = "F3X";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Right;
			TextStrokeTransparency = 0.9;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "MaterialOption";
			Position = UDim2.new( 0, 14, 0, 30 );
			Size = UDim2.new( 1, -14, 0, 25 );
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.MaterialOption;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Name = "Label";
			Size = UDim2.new( 0, 40, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Material";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		local MaterialDropdown = createDropdown();
		self.MaterialDropdown = MaterialDropdown;
		MaterialDropdown.Frame.Parent = Container.MaterialOption;
		MaterialDropdown.Frame.Position = UDim2.new( 0, 50, 0, 0 );
		MaterialDropdown.Frame.Size = UDim2.new( 0, 130, 0, 25 );

		MaterialDropdown:addOption( "SMOOTH PLASTIC" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.SmoothPlastic );
		end );
		MaterialDropdown:addOption( "PLASTIC" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Plastic );
		end );
		MaterialDropdown:addOption( "CONCRETE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Concrete );
		end );
		MaterialDropdown:addOption( "DIAMOND PLATE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.DiamondPlate );
		end );
		MaterialDropdown:addOption( "CORRODED METAL" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.CorrodedMetal );
		end );
		MaterialDropdown:addOption( "BRICK" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Brick );
		end );
		MaterialDropdown:addOption( "FABRIC" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Fabric );
		end );
		MaterialDropdown:addOption( "FOIL" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Foil );
		end );
		MaterialDropdown:addOption( "GRANITE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Granite );
		end );
		MaterialDropdown:addOption( "GRASS" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Grass );
		end );
		MaterialDropdown:addOption( "ICE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Ice );
		end );
		MaterialDropdown:addOption( "MARBLE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Marble );
		end );
		MaterialDropdown:addOption( "PEBBLE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Pebble );
		end );
		MaterialDropdown:addOption( "SAND" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Sand );
		end );
		MaterialDropdown:addOption( "SLATE" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Slate );
		end );
		MaterialDropdown:addOption( "WOOD" ).MouseButton1Up:connect( function ()
			self:changeMaterial( Enum.Material.Wood );
		end );

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "TransparencyOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 65 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.TransparencyOption;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Name = "Label";
			Position = UDim2.new( 0, 14, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Transparency";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.TransparencyOption;
			Name = "TransparencyInput";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 90, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.TransparencyOption.TransparencyInput;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Text = "";
			ZIndex = 2;
			AutoButtonColor = false;

			-- Capture focus of the input when clicked
			-- (so we can detect when it is focused-on)
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self.State.transparency_focused = true;
				Container.TransparencyOption.TransparencyInput.TextBox:CaptureFocus();
			end;
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.TransparencyOption.TransparencyInput;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.TransparencyOption.TransparencyInput;
			Name = "SelectedIndicator";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			Size = UDim2.new( 1, -4, 0, 2 );
			Position = UDim2.new( 0, 5, 0, -2 );
		};

		RbxUtility.Create "TextBox" {
			Parent = Container.TransparencyOption.TransparencyInput;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 1;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );

			-- Change the transparency when the value of the textbox is updated
			[RbxUtility.Create.E "FocusLost"] = function ( enter_pressed )
				if enter_pressed then
					local potential_new = tonumber( Container.TransparencyOption.TransparencyInput.TextBox.Text );
					if potential_new then
						self:changeTransparency( potential_new );
					end;
				end;
				self.State.transparency_focused = false;
			end;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "ReflectanceOption";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 0, 0, 100 );
		};

		RbxUtility.Create "TextLabel" {
			Parent = Container.ReflectanceOption;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Name = "Label";
			Position = UDim2.new( 0, 14, 0, 0 );
			Size = UDim2.new( 0, 70, 0, 25 );
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "Reflectance";
			TextColor3 = Color3.new( 1, 1, 1 );
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 0;
			TextStrokeColor3 = Color3.new( 0, 0, 0 );
			TextWrapped = true;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.ReflectanceOption;
			Name = "ReflectanceInput";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 85, 0, 0 );
			Size = UDim2.new( 0, 50, 0, 25 );
		};

		RbxUtility.Create "TextButton" {
			Parent = Container.ReflectanceOption.ReflectanceInput;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new( 1, 0, 1, 0 );
			Text = "";
			ZIndex = 2;
			AutoButtonColor = false;

			-- Capture focus of the input when clicked
			-- (so we can detect when it is focused-on)
			[RbxUtility.Create.E "MouseButton1Down"] = function ()
				self.State.reflectance_focused = true;
				Container.ReflectanceOption.ReflectanceInput.TextBox:CaptureFocus();
			end;
		};

		RbxUtility.Create "Frame" {
			Parent = Container.ReflectanceOption.ReflectanceInput;
			Name = "SelectedIndicator";
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new( 1, 1, 1 );
			Size = UDim2.new( 1, -4, 0, 2 );
			Position = UDim2.new( 0, 5, 0, -2 );
		};

		RbxUtility.Create "ImageLabel" {
			Parent = Container.ReflectanceOption.ReflectanceInput;
			Name = "Background";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Image = light_slanted_rectangle;
			Size = UDim2.new( 1, 0, 1, 0 );
		};

		RbxUtility.Create "TextBox" {
			Parent = Container.ReflectanceOption.ReflectanceInput;
			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			Position = UDim2.new( 0, 5, 0, 0 );
			Size = UDim2.new( 1, -10, 1, 0 );
			ZIndex = 1;
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size12;
			Text = "";
			TextColor3 = Color3.new( 1, 1, 1 );

			-- Change the transparency when the value of the textbox is updated
			[RbxUtility.Create.E "FocusLost"] = function ( enter_pressed )
				if enter_pressed then
					local potential_new = tonumber( Container.ReflectanceOption.ReflectanceInput.TextBox.Text );
					if potential_new then
						self:changeReflectance( potential_new );
					end;
				end;
				self.State.reflectance_focused = false;
			end;
		};

		RbxUtility.Create "Frame" {
			Parent = Container;
			Name = "Bottom";
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, 5, 0, 135 );
			Size = UDim2.new( 1, -5, 0, 20 );
		};

		RbxUtility.Create "Frame" {
			Parent = Container.Bottom;
			Name = "ColorBar";
			BorderSizePixel = 0;
			BackgroundColor3 = self.Color.Color;
			Size = UDim2.new( 1, 0, 0, 2 );
		};

		self.GUI = Container;

	end;

	-- Reveal the GUI
	self.GUI.Visible = true;

end;

Tools.Material.hideGUI = function ( self )

	-- Hide the GUI if it exists already
	if self.GUI then
		self.GUI.Visible = false;
	end;

end;

------------------------------------------
-- Provide an interface to the 2D
-- selection system
------------------------------------------

Select2D = {

	-- Keep state data
	["enabled"] = false;

	-- Keep objects
	["GUI"] = nil;

	-- Keep temporary, disposable connections
	["Connections"] = {};

	-- Provide an interface to the functions
	["start"] = function ( self )

		if enabled then
			return;
		end;

		self.enabled = true;

		-- Create the GUI
		self.GUI = RbxUtility.Create "ScreenGui" {
			Name = "BTSelectionRectangle";
			Parent = UI;
		};

		local Rectangle = RbxUtility.Create "Frame" {
			Name = "Rectangle";
			Active = false;
			Parent = self.GUI;
			BackgroundColor3 = Color3.new( 0, 0, 0 );
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0;
			Position = UDim2.new( 0, math.min( click_x, Mouse.X ), 0, math.min( click_y, Mouse.Y ) );
			Size = UDim2.new( 0, math.max( click_x, Mouse.X ) - math.min( click_x, Mouse.X ), 0, math.max( click_y, Mouse.Y ) - math.min( click_y, Mouse.Y ) );
		};

		-- Listen for when to resize the selection
		self.Connections.SelectionResize = Mouse.Move:connect( function ()
			Rectangle.Position = UDim2.new( 0, math.min( click_x, Mouse.X ), 0, math.min( click_y, Mouse.Y ) );
			Rectangle.Size = UDim2.new( 0, math.max( click_x, Mouse.X ) - math.min( click_x, Mouse.X ), 0, math.max( click_y, Mouse.Y ) - math.min( click_y, Mouse.Y ) );
		end );

		-- Listen for when the selection ends
		self.Connections.SelectionEnd = Mouse.Button1Up:connect( function ()
			self:select();
			self:finish();
		end );

	end;

	["select"] = function ( self )

		if not self.enabled then
			return;
		end;

		for _, Object in pairs( _getAllDescendants( Services.Workspace ) ) do

			-- Make sure we can select this part
			if Object:IsA( "BasePart" ) and not Object.Locked then

				-- Check if the part is rendered within the range of the selection area
				local PartPosition = _pointToScreenSpace( Object.Position );
				local left_check = PartPosition.x >= self.GUI.Rectangle.AbsolutePosition.x;
				local right_check = PartPosition.x <= ( self.GUI.Rectangle.AbsolutePosition.x + self.GUI.Rectangle.AbsoluteSize.x );
				local top_check = PartPosition.y >= self.GUI.Rectangle.AbsolutePosition.y;
				local bottom_check = PartPosition.y <= ( self.GUI.Rectangle.AbsolutePosition.y + self.GUI.Rectangle.AbsoluteSize.y );

				-- If the part is within the selection area, select it
				if left_check and right_check and top_check and bottom_check then
					Selection:add( Object );
				end;

			end;

		end;

	end;

	["finish"] = function ( self )

		if not self.enabled then
			return;
		end;

		-- Disconnect temporary connections
		for connection_index, Connection in pairs( self.Connections ) do
			Connection:disconnect();
			self.Connections[connection_index] = nil;
		end;

		-- Remove temporary objects
		self.GUI:Destroy();
		self.GUI = nil;

		self.enabled = false;

	end;

};

------------------------------------------
-- Provide an interface to the edge
-- selection system
------------------------------------------
SelectEdge = {

	-- Keep state data
	["enabled"] = false;
	["started"] = false;

	-- Keep objects
	["Marker"] = nil;
	["MarkerOutline"] = RbxUtility.Create "SelectionBox" {
		Color = BrickColor.new( "Institutional white" );
		Parent = UI;
		Name = "BTEdgeSelectionMarkerOutline";
	};

	-- Keep temporary, disposable connections
	["Connections"] = {};

	-- Provide an interface to the functions
	["start"] = function ( self, edgeSelectionCallback )

		if self.started then
			return;
		end;

		-- Listen for when to engage in selection
		self.Connections.KeyListener = Mouse.KeyDown:connect( function ( key )

			local key = key:lower();
			local key_code = key:byte();

			if key == "e" then
				self:enable( edgeSelectionCallback );
			end;

		end );

		self.started = true;

	end;

	["enable"] = function ( self, edgeSelectionCallback )

		if self.enabled then
			return;
		end;

		self.Connections.MoveListener = Mouse.Move:connect( function ()

			-- Make sure the target can be selected
			if not Selection:find( Mouse.Target ) then
				return;
			end;

			-- Calculate the proximity to each edge
			local Proximity = {};
			local edges = {};

			-- Create shortcuts to certain things that are expensive to call constantly
			local table_insert = table.insert;
			local newCFrame = CFrame.new;
			local PartCFrame = Mouse.Target.CFrame;
			local partCFrameOffset = PartCFrame.toWorldSpace;
			local PartSize = Mouse.Target.Size / 2;
			local size_x, size_y, size_z = PartSize.x, PartSize.y, PartSize.z;

			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, -size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, size_y, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, size_y, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, -size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, -size_y, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, -size_y, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, 0, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, 0, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, 0, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, 0, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, -size_y, size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, 0, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, -size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, 0, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, -size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( size_x, 0, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, size_y, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, -size_y, 0 ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( -size_x, 0, -size_z ) ) );
			table_insert( edges, partCFrameOffset( PartCFrame, newCFrame( 0, -size_y, -size_z ) ) );

			-- Calculate the proximity of every edge to the mouse
			for edge_index, Edge in pairs( edges ) do
				Proximity[edge_index] = ( Mouse.Hit.p - Edge.p ).magnitude;
			end;

			-- Get the closest edge to the mouse
			local highest_proximity = 1;
			for proximity_index, proximity in pairs( Proximity ) do
				if proximity < Proximity[highest_proximity] then
					highest_proximity = proximity_index;
				end;
			end;

			-- Replace the current target edge (if any)
			local ClosestEdge = edges[highest_proximity];

			if self.Marker then
				self.Marker:Destroy();
			end;
			self.Marker = RbxUtility.Create "Part" {
				Name = "BTEdgeSelectionMarker";
				Anchored = true;
				Locked = true;
				CanCollide = false;
				Transparency = 1;
				FormFactor = Enum.FormFactor.Custom;
				Size = Vector3.new( 0.2, 0.2, 0.2 );
				CFrame = ClosestEdge;
			};

			self.MarkerOutline.Adornee = self.Marker;

		end );

		self.Connections.ClickListener = Mouse.Button1Up:connect( function ()
			override_selection = true;
			self:select( edgeSelectionCallback );
		end );

		self.enabled = true;

	end;

	["select"] = function ( self, callback )

		if not self.enabled or not self.Marker then
			return;
		end;

		-- Turn the marker into an actual part of the selection
		self.Marker.Parent = Services.Workspace.CurrentCamera;
		Selection:add( self.Marker );

		callback( self.Marker );

		-- Stop treating it like a marker
		self.Marker = nil;
		self.MarkerOutline.Adornee = nil;

		self:disable();

	end;

	["disable"] = function ( self )

		if not self.enabled then
			return;
		end;

		-- Disconnect unnecessary temporary connections
		if self.Connections.ClickListener then
			self.Connections.ClickListener:disconnect();
			self.Connections.ClickListener = nil;
		end;
		if self.Connections.MoveListener then
			self.Connections.MoveListener:disconnect();
			self.Connections.MoveListener = nil;
		end;

		-- Remove temporary objects
		if self.Marker then
			self.Marker:Destroy();
		end;
		self.Marker = nil;

		self.MarkerOutline.Adornee = nil;
		self.enabled = false;

	end;

	["stop"] = function ( self )

		if not self.started then
			return;
		end;

		-- Disconnect & remove all temporary connections
		for connection_index, Connection in pairs( self.Connections ) do
			Connection:disconnect();
			self.Connections[connection_index] = nil;
		end;

		-- Remove temporary objects
		if self.Marker then
			self.Marker:Destroy();
		end;

		self.started = false;

	end;

};

------------------------------------------
-- Attach listeners
------------------------------------------

Tool.Equipped:connect( function ( CurrentMouse )

	Mouse = CurrentMouse;

	Options.TargetBox = Instance.new( "SelectionBox", UI );
	Options.TargetBox.Name = "BTTargetBox";
	Options.TargetBox.Color = BrickColor.new( "Institutional white" );

	-- Enable any temporarily-disabled selection boxes
	for _, SelectionBox in pairs( SelectionBoxes ) do
		SelectionBox.Parent = UI;
	end;

	-- Call the `Equipped` listener of the current tool
	if Options.Tool and Options.Tool.Listeners.Equipped then
		Options.Tool.Listeners.Equipped();
	end;

	Mouse.KeyDown:connect( function ( key )

		local key = key:lower();
		local key_code = key:byte();

		-- Provide the abiltiy to delete via the shift + X key combination
		if ActiveKeys[47] or ActiveKeys[48] and key == "x" then
			local SelectionItems = _cloneTable( Selection.Items );
			for _, Item in pairs( SelectionItems ) do
				Item:Destroy();
			end;
			return;
		end;

		-- Provide the ability to clone via the shift + C key combination
		if ActiveKeys[47] or ActiveKeys[48] and key == "c" then

			-- Make sure that there are items in the selection
			if #Selection.Items > 0 then

				local item_copies = {};

				-- Make a copy of every item in the selection and add it to table `item_copies`
				for _, Item in pairs( Selection.Items ) do

					-- Make sure not to include things like markers
					if Item.Name ~= "BTEdgeSelectionMarker" then
						local ItemCopy = Item:Clone();
						ItemCopy.Parent = Services.Workspace;
						table.insert( item_copies, ItemCopy );
					end;

				end;

				-- Replace the selection with the copied items
				Selection:clear();
				for _, Item in pairs( item_copies ) do
					Selection:add( Item );
				end;

				-- Play a confirmation sound
				local Sound = RbxUtility.Create "Sound" {
					Name = "BTActionCompletionSound";
					Pitch = 1.5;
					SoundId = action_completion_sound;
					Volume = 1;
					Parent = Player;
				};
				Sound:Play();
				Sound:Destroy();

				-- Highlight the outlines of the new parts
				coroutine.wrap( function ()
					for transparency = 1, 0, -0.1 do
						for Item, SelectionBox in pairs( SelectionBoxes ) do
							SelectionBox.Transparency = transparency;
						end;
						wait( 0.1 );
					end;
				end )();

			end;

			return;

		end;

		if key == "z" then
			Options.Tool = Tools.Move;

		elseif key == "x" then
			Options.Tool = Tools.Resize;

		elseif key == "c" then
			Options.Tool = Tools.Rotate;

		elseif key == "v" then
			Options.Tool = Tools.Paint;

		elseif key == "b" then
			Options.Tool = Tools.Surface;

		elseif key == "n" then
			Options.Tool = Tools.Material;

		elseif key == "m" then
			Options.Tool = Tools.Anchor;

		elseif key == "q" then
			Selection:clear();

		end;

		ActiveKeys[key_code] = key_code;
		ActiveKeys[key] = key;

		-- If it's now in multiselection mode, update `selecting`
		-- (these are the left/right ctrl & shift keys)
		if ActiveKeys[47] or ActiveKeys[48] or ActiveKeys[49] or ActiveKeys[50] then
			selecting = ActiveKeys[47] or ActiveKeys[48] or ActiveKeys[49] or ActiveKeys[50];
		end;

	end );

	Mouse.KeyUp:connect( function ( key )

		local key = key:lower();
		local key_code = key:byte();

		ActiveKeys[key_code] = nil;
		ActiveKeys[key] = nil;

		-- If it's no longer in multiselection mode, update `selecting` & related values
		if selecting and not ActiveKeys[selecting] then
			selecting = false;
			if Select2D.enabled then
				Select2D:select();
				Select2D:finish();
			end;
		end;

	end );

	Mouse.Button1Down:connect( function ()

		clicking = true;
		click_x, click_y = Mouse.X, Mouse.Y;

		-- If multiselection is, just add to the selection
		if selecting then
			return;
		end;

		-- Fire tool listeners
		if Options.Tool and Options.Tool.Listeners.Button1Down then
			Options.Tool.Listeners.Button1Down();
		end;

	end );

	Mouse.Move:connect( function ()

		-- If the mouse has moved since it was clicked, start 2D selection mode
		if not override_selection and not Select2D.enabled and clicking and selecting and ( click_x ~= Mouse.X or click_y ~= Mouse.Y ) then
			Select2D:start();
		end;

		-- If the target has changed, update the selectionbox appropriately
		if not override_selection and Mouse.Target then
			if Mouse.Target:IsA( "BasePart" ) and not Mouse.Target.Locked and Options.TargetBox.Adornee ~= Mouse.Target and not Selection:find( Mouse.Target ) then
				Options.TargetBox.Adornee = Mouse.Target;
			end;
		end;

		-- When aiming at something invalid, don't highlight any targets
		if not override_selection and not Mouse.Target or ( Mouse.Target and Mouse.Target:IsA( "BasePart" ) and Mouse.Target.Locked ) or Selection:find( Mouse.Target ) then
			Options.TargetBox.Adornee = nil;
		end;

		-- Fire tool listeners
		if Options.Tool and Options.Tool.Listeners.Move then
			Options.Tool.Listeners.Move();
		end;

		if override_selection then
			override_selection = false;
		end;

	end );

	Mouse.Button1Up:connect( function ()

		clicking = false;

		-- Make sure the person didn't accidentally miss a handle or something
		if not Select2D.enabled and ( Mouse.X ~= click_x or Mouse.Y ~= click_y ) then
			override_selection = true;
		end;

		-- If the target when clicking was invalid then clear the selection (unless we're multi-selecting)
		if not override_selection and not selecting and ( not Mouse.Target or ( Mouse.Target and Mouse.Target:IsA( "BasePart" ) and Mouse.Target.Locked ) ) then
			Selection:clear();
		end;

		-- If multi-selecting, add to/remove from the selection
		if not override_selection and selecting then

			-- If the item isn't already selected, add it to the selection
			if not Selection:find( Mouse.Target ) then
				if Mouse.Target and Mouse.Target:IsA( "BasePart" ) and not Mouse.Target.Locked then
					Selection:add( Mouse.Target );
				end;

			-- If the item _is_ already selected, remove it from the selection
			else
				if ( Mouse.X == click_x and Mouse.Y == click_y ) and Mouse.Target and Mouse.Target:IsA( "BasePart" ) and not Mouse.Target.Locked then
					Selection:remove( Mouse.Target );
				end;
			end;

		-- If not multi-selecting, replace the selection
		else
			if not override_selection and Mouse.Target and Mouse.Target:IsA( "BasePart" ) and not Mouse.Target.Locked then
				Selection:clear();
				Selection:add( Mouse.Target );
			end;
		end;

		-- Fire tool listeners
		if Options.Tool and Options.Tool.Listeners.Button1Up then
			Options.Tool.Listeners.Button1Up();
		end;

		if override_selection then
			override_selection = false;
		end;

	end );

	Mouse.Button2Down:connect( function ()
		-- Fire tool listeners
		if Options.Tool and Options.Tool.Listeners.Button2Down then
			Options.Tool.Listeners.Button2Down();
		end;
	end );

	Mouse.Button2Up:connect( function ()
		-- Fire tool listeners
		if Options.Tool and Options.Tool.Listeners.Button2Up then
			Options.Tool.Listeners.Button2Up();
		end;
	end );

end );

Tool.Unequipped:connect( function ()

	Mouse = nil;

	-- Remove the mouse target SelectionBox from `Player`
	local TargetBox = UI:FindFirstChild( "BTTargetBox" );
	if TargetBox then
		TargetBox:Destroy();
	end;

	-- Disable all the selection boxes temporarily
	for _, SelectionBox in pairs( SelectionBoxes ) do
		SelectionBox.Parent = nil;
	end;

	-- Call the `Unequipped` listener of the current tool
	if Options.Tool and Options.Tool.Listeners.Unequipped then
		Options.Tool.Listeners.Unequipped();
	end;

end );

-- Enable `Tools.Move` as the first tool
Options.Tool = Tools.Move;