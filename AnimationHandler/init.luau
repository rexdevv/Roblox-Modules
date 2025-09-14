--!strict

--// Used to handle loading, playing, removing and other methods of animations //--

--// Services //--

local HttpService = game:GetService("HttpService")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ContentProvider = game:GetService("ContentProvider")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--

local GarbageCollector = require(ReplicatedStorage.Packages.GarbageCollector)

--// Types //--

local Types = require(script.Types)

--// Variables //--

local LoadedAnimations: { [Instance]: { [string]: LoadedAnimation } } = {}

local AnimationModule: AnimationModule = {} :: any
AnimationModule.__index = AnimationModule

local LoadedAnimation: LoadedAnimation = {} :: any
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
	local self: LoadedAnimation = setmetatable({}, LoadedAnimation) :: any

	local TargetedAnimator: Animator

	if AnimationObject:IsA("Model") or AnimationObject:IsA("Humanoid") then
		TargetedAnimator = AnimationObject:FindFirstChild("Animator", true) :: any
	elseif AnimationObject:IsA("Animator") then
		TargetedAnimator = AnimationObject
	end

	local Animation: Animation

	if Cashe:FindFirstChild(AnimID) then
		Animation = Cashe[AnimID]
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
		for _, anim in pairs(LoadedAnimations[AnimationInstance]) do
			anim:Stop(Fade or 0)
		end
	end
end

function AnimationModule.StopAllLoadedAnimationsExcept(self, AnimationInstance, Except: { string }, Fade: number)
	if LoadedAnimations[AnimationInstance] then
		for _, anim in pairs(LoadedAnimations[AnimationInstance]) do
			if not table.find(Except, anim.AnimationName) then
				anim:Stop(Fade or 0)
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
		for _, anim in pairs(LoadedAnimations[AnimationInstance]) do
			local stopAnim = true
			for _, exceptGroup in pairs(ExceptGroups) do
				if table.find(anim.AnimationGroups, exceptGroup) then
					stopAnim = false
					break
				end
			end
			if stopAnim then
				anim:Stop(Fade or 0)
			end
		end
	end
end

function AnimationModule.StopAllLoadedAnimationsInGroups(self, AnimationInstance, Groups: { string }, Fade: number)
	if LoadedAnimations[AnimationInstance] then
		for _, anim in pairs(LoadedAnimations[AnimationInstance]) do
			for _, group in pairs(Groups) do
				if table.find(anim.AnimationGroups, group) then
					anim:Stop(Fade or 0)
					break
				end
			end
		end
	end
end

function AnimationModule.FindAnimationEvents(self, AnimationID: string)
	local events = {}

	local animation = Cashe:FindFirstChild(AnimationID)
	if not animation then
		animation = Instance.new("Animation")
		animation.AnimationId = AnimationID
		animation.Name = AnimationID
		animation.Parent = Cashe
	end

	if not animation:FindFirstChild("KeyframeSequence") then
		local keyframes = KeyframeSequenceProvider:GetKeyframeSequenceAsync(AnimationID)
		keyframes.Name = "KeyframeSequence"
		keyframes.Parent = animation
	end

	local keyframeSequence = animation:FindFirstChild("KeyframeSequence")
	if keyframeSequence then
		for _, marker in pairs(keyframeSequence:GetDescendants()) do
			if marker:IsA("KeyframeMarker") then
				events[marker.Name] = marker.Parent.Time
			end
		end
	end

	return events
end

function AnimationModule.ClearLoadedAnimationsInGroups(self, AnimationInstance, Groups: { string })
	if LoadedAnimations[AnimationInstance] then
		for _, anim in pairs(LoadedAnimations[AnimationInstance]) do
			for _, group in pairs(Groups) do
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
