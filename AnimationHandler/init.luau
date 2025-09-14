--!strict

--// Used to handle loading, playing, removing and other methods of animations //--

--// Services //--

local HttpService = game:GetService("HttpService")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ContentProvider = game:GetService("ContentProvider")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--

local GarbageCollector = require(ReplicatedStorage.Modules.Shared.Garbage.GarbageCollector)

--// Types //--

local Types = require(script.Types)

--// Variables //--

local LoadedAnimations: { [Instance]: { [string]: Types.LoadedAnimation } } = {}

local AnimationModule: Types.AnimationModule = {} :: any
AnimationModule.__index = AnimationModule

local LoadedAnimation: Types.LoadedAnimation = {} :: any
LoadedAnimation.__index = LoadedAnimation

local Cashe: Folder = nil

if script:FindFirstChild("Cashe") then
	Cashe = script:FindFirstChild("Cashe") :: any
else
	Cashe = Instance.new("Folder", script)
	Cashe.Name = "Cashe"
end

--// Functions //--

function AnimationModule:Preload(AnimID: string, LoadKeyframes: boolean)
	ContentProvider:PreloadAsync({ AnimID })

	local Animation = Instance.new("Animation")
	Animation.AnimationId = AnimID
	Animation.Name = AnimID
	Animation.Parent = Cashe

	if LoadKeyframes == true then
		if not Animation:FindFirstChild("KeyframeSequence") then
			local Keyframes = KeyframeSequenceProvider:GetKeyframeSequenceAsync(AnimID)

			Keyframes["Parent"] = Animation
		end
	end
end

function AnimationModule.LoadAnimation(AnimationObject, AnimID, AnimName, AnimGroups, LoadKeyFrames)
	local self: Types.LoadedAnimation = setmetatable({}, LoadedAnimation) :: any

	local TargetedAnimator: Animator

	if AnimationObject:IsA("Model") or AnimationObject:IsA("Humanoid") then
		TargetedAnimator = AnimationObject:FindFirstChild("Animator", true) :: any
	elseif AnimationObject:IsA("Animator") then
		TargetedAnimator = AnimationObject
	end

	local Animation: Animation

	if Cashe:FindFirstChild(AnimID) then
		Animation = Cashe:FindFirstChild(AnimID) :: Animation
	else
		Animation = Instance.new("Animation")
		Animation.AnimationId = AnimID
		Animation["Name"] = AnimID
		Animation.Parent = Cashe
	end

	self.AnimationID = AnimID
	self.AnimationName = AnimName
	self.AnimationGroups = AnimGroups

	self.GarbageCollector = GarbageCollector.new(HttpService:GenerateGUID(false))
	self.GarbageCollector:AttachToInstance(AnimationObject)

	self.AnimationTrack = TargetedAnimator:LoadAnimation(Animation)

	self.AnimationPaused = false
	self.AnimationSpeed = 1
	self.AnimationLoaded = false

	self.AnimationLoaded = true

	if not LoadedAnimations[AnimationObject] then
		LoadedAnimations[AnimationObject] = {}
	end

	LoadedAnimations[AnimationObject][self.AnimationName] = self

	return self
end

function LoadedAnimation.Play(self, Fade, Weight, Speed)
	Fade = Fade or 0
	Weight = Weight or 1
	Speed = Speed or 1

	self.AnimationTrack:Play(Fade, Weight)
	self.AnimationTrack:AdjustSpeed(Speed)
	self.AnimationSpeed = Speed
end

function LoadedAnimation.Stop(self, Fade)
	Fade = Fade or 0

	self.AnimationTrack:Stop(Fade)
end

function LoadedAnimation.Pause(self)
	self.AnimationTrack:AdjustSpeed(0)
	self.AnimationPaused = true
end

function LoadedAnimation.Unpause(self)
	self.AnimationTrack:AdjustSpeed(self.AnimationSpeed)
	self.AnimationPaused = false
end

function LoadedAnimation.Loop(self, Loop)
	self.AnimationTrack.Looped = Loop
end

function LoadedAnimation.AdjustSpeed(self, Speed)
	self.AnimationTrack:AdjustSpeed(Speed)
	self.AnimationSpeed = Speed
end

function LoadedAnimation.ScheduleEvent(self, EventName: string, Callback: (...any) -> ())
	self.GarbageCollector:AddConnection(self.AnimationTrack:GetMarkerReachedSignal(EventName), Callback)
end

function LoadedAnimation.ScheduleEventOnce(self, EventName: string, Callback: (...any) -> ())
	self.AnimationTrack:GetMarkerReachedSignal(EventName):Once(Callback)
end

function LoadedAnimation.Unload(self)
	self.AnimationLoaded = false
	self.GarbageCollector:Clean()
end

function AnimationModule.FindAnimation(self, AnimationInstance, AnimName: string)
	if LoadedAnimations[AnimationInstance] then
		return LoadedAnimations[AnimationInstance][AnimName]
	else
		return nil
	end
end

function AnimationModule.GetLoadedAnimations(self, AnimationInstance)
	return LoadedAnimations[AnimationInstance]
end

function AnimationModule.StopAllLoadedAnimations(self, AnimationInstance, Fade: number)
	if LoadedAnimations[AnimationInstance] then
		for _, Anim in LoadedAnimations[AnimationInstance] do
			Anim:Stop(Fade or 0)
		end
	end
end

function AnimationModule.StopAllLoadedAnimationsExcept(self, AnimationInstance, Except: { string }, Fade: number)
	if LoadedAnimations[AnimationInstance] then
		for _, Anim in LoadedAnimations[AnimationInstance] do
			if not table.find(Except, Anim.AnimationName) then
				Anim:Stop(Fade or 0)
			end
		end
	end
end

function AnimationModule.StopAllLoadedAnimationsExceptGroups(
	self,
	AnimationInstance,
	ExceptGroups: { string },
	Fade: number
)
	if LoadedAnimations[AnimationInstance] then
		for _, Anim in LoadedAnimations[AnimationInstance] do
			local StopAnim = true
			for _, ExceptGroup in ExceptGroups do
				if table.find(Anim.AnimationGroups, ExceptGroup) then
					StopAnim = false
					break
				end
			end
			if StopAnim then
				Anim:Stop(Fade or 0)
			end
		end
	end
end

function AnimationModule.StopAllLoadedAnimationsInGroups(self, AnimationInstance, Groups: { string }, Fade: number)
	if LoadedAnimations[AnimationInstance] then
		for _, Anim in LoadedAnimations[AnimationInstance] do
			for _, Group in Groups do
				if table.find(Anim.AnimationGroups, Group) then
					Anim:Stop(Fade or 0)
					break
				end
			end
		end
	end
end

function AnimationModule.FindAnimationEvents(self, AnimationID: string)
	local Events = {}

	local Animation: Animation = Cashe:FindFirstChild(AnimationID) :: Animation

	if not Animation then
		Animation = Instance.new("Animation")
		Animation.AnimationId = AnimationID
		Animation.Name = AnimationID
		Animation.Parent = Cashe
	end

	if not Animation:FindFirstChild("KeyframeSequence") then
		local Keyframes = KeyframeSequenceProvider:GetKeyframeSequenceAsync(AnimationID)
		Keyframes.Name = "KeyframeSequence"
		Keyframes.Parent = Animation
	end

	local KeyframeSequence = Animation:FindFirstChild("KeyframeSequence")
	if KeyframeSequence then
		for _, Marker in (KeyframeSequence:GetDescendants()) do
			if Marker:IsA("KeyframeMarker") then
				Events[Marker.Name] = Marker.Parent.Time
			end
		end
	end

	return Events
end

function AnimationModule.ClearLoadedAnimationsInGroups(self, AnimationInstance, Groups: { string })
	if LoadedAnimations[AnimationInstance] then
		for _, anim in (LoadedAnimations[AnimationInstance]) do
			for _, group in (Groups) do
				if table.find(anim.AnimationGroups, group) then
					anim:Unload()
					break
				end
			end
		end
	end
end

function AnimationModule.IsAnimLoaded(self, AnimationInstance, AnimName: string)
	return LoadedAnimations[AnimationInstance] and LoadedAnimations[AnimationInstance][AnimName] ~= nil
end

--// Return //--

return AnimationModule
