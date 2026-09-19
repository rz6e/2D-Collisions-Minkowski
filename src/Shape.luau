
local raylib = require("../raylib/src")

local lib = raylib.lib;
local const = raylib.const;

local Shape = {}
Shape.__index = Shape

type ShapeProps = {
    Vertices: {vector},
    Position: vector,
    Color: raylib.Color?
}

function Shape.new(Vertices, Position) 

    local self = setmetatable({} :: ShapeProps, Shape)

    self.Vertices = Vertices
    self.Position = Position

    return self
end

function Shape.Draw(self: ShapeProps)

    for Index, Vertex in self.Vertices do
        lib.DrawLineEx(self.Position + Vertex, self.Position + self.Vertices[Index % #self.Vertices + 1], 3, self.Color and self.Color or const.RED)
    end

end

function Shape.PointCloud(self: ShapeProps, OtherShape: ShapeProps)
    local PointCloud = {}
    
    for _, Vertex in self.Vertices do
        for _, v in OtherShape.Vertices do
            PointCloud[#PointCloud + 1] = Vertex + v
        end
    end

    return PointCloud
end

function Shape.SetColor(self: ShapeProps, Color: raylib.Color)
    self.Color = Color
end

return Shape