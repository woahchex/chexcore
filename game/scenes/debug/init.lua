local scene = GameScene.new{
    FrameLimit = 60,
    DeathHeight = 3000,
    Update = function (self, dt)
        GameScene.Update(self, dt)
        self.Player = self:GetDescendant("Player")
        -- self.Camera.Position = self.Camera.Position:Lerp((self.Player:GetPoint(0.5,0.5)), 1000*dt)
        -- self.Camera.Zoom = 1 --+ (math.sin(Chexcore._clock)+1)/2
    end
}
Chexcore:AddType("game.objects.wheel")
Chexcore:AddType("game.objects.cameraZone")

local bgLayer = Prop.new{Size = V{64, 36}, Color = HSV{0,0.5,0.5,01}, Texture = Texture.new("chexcore/assets/images/square.png"),Update = function(s,dt) s.Color.H = (s.Color.H + dt/5)%1 end}:Into(scene:AddLayer(Layer.new("BG", 64, 36, true):Properties{TranslationInfluence = 0}))
local mainLayer = scene:GetLayer("Gameplay")

scene:SwapChildOrder(bgLayer, mainLayer)

local tilemap = Tilemap.import("game.scenes.debug.tilemap", "game/scenes/debug/tilemap.png", {Scale = 1 }):Nest(mainLayer):Properties{
    LockPlayerVelocity = true,
    Update = function (self,dt)
        
        -- self.Position = self.Position + V{1,0}
        -- self.LayerColors[3].H = (self.LayerColors[2].H + dt/2)%1 
        -- self.LayerColors[1].S = math.sin(Chexcore._clock)/2 + 0.5 
    end
}


local layer = scene:AddLayer(Layer.new("Test", 640, 360)):Properties{
    TranslationInfluence = V{0,0}
}
layer:Adopt(Prop.new{
    Size = V{640,360},
    AnchorPoint = V{0.5,0.5},
    -- Visible = false,
    Shader = Shader.new([[
extern float time;       // Pass from Lua
extern Image channel0;   // Pass texture
extern vec2 offset;      // Pass offset from Lua
extern float zoom;       // Pass zoom from Lua

const int iters = 150;
const float brightnessThreshold = 0.08;  // Threshold for brightness to switch to a saturated color

int fractal(vec2 p, vec2 point) {
    vec2 so = (-1.0 + 2.0 * point) * 0.4;
    vec2 seed = vec2(0.098386255 + so.x, 0.6387662 + so.y);

    for (int i = 0; i < iters; i++) {
        if (length(p) > 2.0) {
            return i;
        }
        vec2 r = p;
        p = vec2(p.x * p.x - p.y * p.y, 2.0 * p.x * p.y);
        p = vec2(p.x * r.x - p.y * r.y + seed.x, r.x * p.y + p.x * r.y + seed.y);
    }
    return 0;    
}

vec3 getColor(int i) { 
    float f = float(i) / float(iters) * 2.0;
    f = f * f * 2.0;
    return vec3(sin(f * 2.0), sin(f * 3.0), abs(sin(f * 7.0)));
}

float sampleMusicA(vec2 uv) {
    return 0.5 * (
        Texel(channel0, vec2(0.15, 0.25)).x + 
        Texel(channel0, vec2(0.30, 0.25)).x);
}

float calculateBrightness(vec3 color) {
    // Simple brightness calculation using the luminance formula
    return dot(color, vec3(0.299, 0.587, 0.114));  // Luminance (weighted average of RGB)
}

// Function to convert hue to RGB
vec3 hsvToRgb(float h) {
    float r, g, b;
    h = mod(h, 1.0);  // Ensure hue is within [0, 1] range
    float p = 0.0;
    float q = 1.0 - p;
    float t = (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    
    // For each section of the hue circle (RGB)
    if (h < 1.0 / 6.0) {
        r = 1.0;
        g = t;
        b = p;
    } else if (h < 2.0 / 6.0) {
        r = q;
        g = 1.0;
        b = p;
    } else if (h < 3.0 / 6.0) {
        r = p;
        g = 1.0;
        b = t;
    } else if (h < 4.0 / 6.0) {
        r = p;
        g = q;
        b = 1.0;
    } else if (h < 5.0 / 6.0) {
        r = t;
        g = p;
        b = 1.0;
    } else {
        r = 1.0;
        g = p;
        b = q;
    }

    return vec3(r, g, b);  // Return the RGB color
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 iResolution = vec2(love_ScreenSize);
    vec2 fragCoord = screen_coords;

    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 position = (fragCoord.xy / iResolution.xy - 0.5) * 2.0 * zoom + offset;  // Apply dynamic zoom and offset
    position.x *= iResolution.x / iResolution.y;

    vec2 iFC = vec2(iResolution.x - fragCoord.x, iResolution.y - fragCoord.y);
    vec2 pos2 = (iFC.xy / iResolution.xy - 0.5) * 2.0 * zoom + offset;
    pos2.x *= iResolution.x / iResolution.y;

    vec4 t3 = Texel(channel0, vec2(length(position) / 2.0, 0.1));
    float pulse = 0.5 + sampleMusicA(uv) * 1.8;

    // Dynamically generate the "mouse" effect using time
    vec2 dynamic_point = vec2(
        0.5 + sin(time / 3.0) / 2.0,
        0.9 + 0.4 * cos(time / 4.0)
    );

    vec3 invFract = getColor(fractal(pos2, vec2(0.55 + sin(time / 3.0 + 0.5) / 2.0, pulse * 0.9)));
    vec3 fract4 = getColor(fractal(position / 1.6, vec2(0.6 + cos(time / 2.0 + 0.5) / 2.0, pulse * 0.8)));
    vec3 c = getColor(fractal(position, dynamic_point));

    t3 = abs(vec4(0.5, 0.1, 0.5, 1.0) - t3) * 2.0;

    vec4 fract01 = vec4(c, 1.0);
    vec4 salida = fract01 / t3 + fract01 * t3 + vec4(invFract, 0.6) + vec4(fract4, 0.3);

    // Calculate brightness
    float brightness = calculateBrightness(salida.rgb);

    // Set the color based on brightness
    if (brightness > brightnessThreshold) {
        // Choose a random hue (based on time or another variable)
        float hue = mod(time / 10.0, 1.0);  // Time-based hue (adjust timing for variation)
        salida.rgb = hsvToRgb(hue);  // Convert the hue to RGB and use it as the color
    } else {
        // Black
        salida.rgb = vec3(0.0, 0.0, 0.0);
    }

    // Multiply the final color by the passed color from love.graphics.setColor
    salida.rgb *= color.rgb;  // Multiply by the color passed from Love2D
    return salida;
}
    ]]),

    Update = function (self)
        self.Shader:Send("time", (math.sin(Chexcore._clock/4))*(1)+11 )
        self.Shader:Send("offset", {(scene.Camera.Position/7000)()})
        self.Shader:Send("zoom", 1)
        self.Color = HSV{(math.sin(Chexcore._clock)+1)/8,1,1}:AddAxis(0.25)
    end,
    
})

local rotatingDecoration = layer:Adopt(Prop.new{
    Size = V{640,640},
    Texture = Texture.new("game/scenes/debug/bg_circle.png"),
    Position = V{200,100},
    AnchorPoint = V{0.5,0.5},
    Update = function(self)
        -- self.Position = scene:GetLayer("Gameplay"):GetChild("Player").Position
        self.Rotation = Chexcore._clock/50
        self.Color = HSV{Chexcore._clock/50%1,1,1}
    end,

})

rotatingDecoration:Clone(true):Properties{
    Position = V{-200,200},
    Update = function(self)
        -- self.Position = scene:GetLayer("Gameplay"):GetChild("Player").Position
        self.Rotation = Chexcore._clock/80
        self.Color = HSV{(Chexcore._clock/50+ 0.2)%1,1,1}
    end,    
}

layer:Adopt(Prop.new{
    -- Texture = Texture.new("game/scenes/debug/angular white bg.png"),
    Size = V{640,200},
    Color = V{1,1,1},
    AnchorPoint = V{0.5,0},
    Update = function (self, dt)
        self.Position.Y = -scene.Camera.Position.Y/10 + 250
        -- self.Rotation = math.sin(Chexcore._clock/4)/20
    end
})


scene:SwapChildOrder(#scene:GetChildren()-1,#scene:GetChildren())


return scene