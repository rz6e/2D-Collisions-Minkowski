local raylib = require("../raylib/src")
local Shape = require("./Shape")

local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs

lib.SetConfigFlags(const.ConfigFlags.FLAG_WINDOW_RESIZABLE)
lib.InitWindow(500, 500, "ZUNE + Raylib")

lib.SetTargetFPS(30)
local bgColor = structs.Color:new({ r = 16, g = 16, b = 16, a = 255 })

local function CreateRect(Size)
  local Vertices = {
    vector.create(-Size.X / 2, Size.Y / 2, 0),
    vector.create(Size.X / 2, Size.Y / 2, 0),
    vector.create(Size.X / 2, -Size.Y / 2, 0),
    vector.create(-Size.X / 2, -Size.Y / 2, 0),
  }
  return Vertices
end

local function CreateCircle(Radius: number, VertexCount: number)
  local Vertices = {}

  for i = 1, VertexCount do
    local Angle = 2 * math.pi / VertexCount * i
    Vertices[i] = vector.create(math.cos(Angle), math.sin(Angle)) * Radius
  end

  return Vertices
end

local function CreateTriangle(Base, Height)
  return {
    vector.create(0, Height / 2, 0),
    vector.create(-Base / 2, -Height / 2, 0),
    vector.create(Base / 2, -Height / 2, 0),
  }
end

local BASE_RECT_SIZE = vector.create(200, 200, 0)
local BASE_RADIUS = 50
local CIRCLE_VERTICES = 100

-- local Triangle = Shape.new(CreateTriangle(BASE_RECT_SIZE.X, BASE_RECT_SIZE.Y), vector.create(500, 300, 0))
local Rect = Shape.new(CreateRect(BASE_RECT_SIZE), vector.create(500, 700, 0))
local Circle = Shape.new(CreateCircle(BASE_RADIUS, CIRCLE_VERTICES), vector.create(500, 100, 0))
-- local AddedRect = Shape.new(CreateRect(BASE_RECT_SIZE + vector.create(BASE_RADIUS*2, BASE_RADIUS*2, 0)), vector.create(200, 200, 0))

local function SortByAngle(PointCloud)
  table.sort(PointCloud, function(a0, a1)
    return math.atan2(a0.Y, a0.X) < math.atan2(a1.Y, a1.X)
  end)

  return PointCloud
end

local function GenerateHull(SortedPointCloud)
  local Hull = table.clone(SortedPointCloud)

  local Index = 1

  while Index <= #Hull do
    local First = Hull[Index]
    local Second = Hull[Index % #Hull + 1]
    local Third = Hull[(Index + 1) % #Hull + 1]

    local VectorOne = First - Third
    local VectorTwo = First - Second

    local CrossVector = vector.cross(VectorOne, VectorTwo)

    if CrossVector.Z >= 0 then
      table.remove(Hull, Index % #Hull + 1)

      if Index ~= 1 then
        Index = (Index - 2) % #Hull + 1
      end
    else
      Index += 1
    end
  end

  return Hull
end

local PointCloud, HullBounds = Rect:PointCloud(Circle)
local Hull = GenerateHull(SortByAngle(PointCloud))

local ConvexHull = Shape.new(Hull, Rect.Position)

local function DrawCloud(Vertices, Color, Position)
  for i, v in Vertices do
    lib.DrawRectangle(v.X + Position.X - 1, v.Y + Position.Y - 1, 5, 5, Color)
  end
end

local function GetRayBounds(OriginPos, TargetPos)

  return {
    Min = vector.create(math.min(OriginPos.X, TargetPos.X), math.min(OriginPos.Y, TargetPos.Y)),
    Max = vector.create(math.max(OriginPos.X, TargetPos.X), math.max(OriginPos.Y, TargetPos.Y))
  }

end

local function AABB(a, b)
    return a.Min.X <= b.Max.X and a.Max.X >= b.Min.X and a.Min.Y <= b.Max.Y and a.Max.Y >= b.Min.Y
end

local function Orient(a, b, c)
    return vector.cross(b-a, c-a)
end

local LastTime = os.clock()
local Speed = vector.create(0, 50, 0)

while lib.WindowShouldClose() == 0 do
  lib.BeginDrawing()
  lib.ClearBackground(bgColor)

  Circle:SetColor(const.ORANGE)
  Circle:Draw()

  local CurrentTime = os.clock()
  local DeltaTime = CurrentTime - LastTime
  local Displacement = Speed * DeltaTime
  local RayOrigin = Circle.Position - Rect.Position
  local NextPosition = RayOrigin + Displacement

  -- print(RayOrigin)

  DrawCloud(HullBounds, const.BLUE, Rect.Position)
  
  local RayBounds = GetRayBounds(RayOrigin, NextPosition)
  DrawCloud(RayBounds, const.BLUE, Rect.Position)

  if AABB(RayBounds, HullBounds) then
      local a = RayOrigin
      local b = NextPosition

      for Index, Vertex in ConvexHull.Vertices do
          local c = Vertex
          local d = ConvexHull.Vertices[Index % #ConvexHull.Vertices + 1]

          local oa = Orient(c, d, a).Z
          local ob = Orient(c,d,b).Z
          local oc = Orient(a,b,c).Z
          local od = Orient(a,b,d).Z

          if oa*ob < 0 and oc*od < 0 then
              print("COLLIDED")
          end
      end
  end


  -- lib.DrawRectangle(Circle.Position.X, Circle.Position.Y, 3, 3, const.GREEN)
  -- lib.DrawRectangle(NextPosition.X, NextPosition.Y, 3, 3, const.WHITE)
  -- lib.DrawLineEx(Circle.Position, NextPosition, 2, const.BLUE)

  Circle.Position += Displacement

  Rect:Draw()
  ConvexHull:Draw()

  -- DrawCloud(Hull, const.GREEN, Rect.Position)
  -- PendingRemovalShape:Draw()

  lib.DrawFPS(10, 10)

  LastTime = CurrentTime

  lib.EndDrawing()
end

lib.CloseWindow()
zune.process.exit(0)
