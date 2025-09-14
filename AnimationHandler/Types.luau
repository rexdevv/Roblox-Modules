export type LoadedAnimation = {
	__index: LoadedAnimation,

	AnimationID: string,
	AnimationName: string,
	AnimationGroups: { string },
	GarbageCollector: GarbageCollector.GarbageCollectorObject,

	AnimationTrack: AnimationTrack,

	AnimationPaused: boolean,
	AnimationSpeed: number,

	AnimationLoaded: boolean,

	Play: (self: LoadedAnimation, Fade: number, Weight: number, Speed: number) -> (),
	Stop: (self: LoadedAnimation, Fade: number) -> (),

	Pause: (self: LoadedAnimation) -> (),
	Unpause: (self: LoadedAnimation) -> (),

	AdjustSpeed: (self: LoadedAnimation, Speed: number) -> (),
	Loop: (self: LoadedAnimation, LoopAnimation: boolean) -> (),

	ScheduleEvent: (self: LoadedAnimation, EventName: string, Callback: (...any) -> ()) -> (),
	ScheduleEventOnce: (self: LoadedAnimation, EventName: string, Callback: (...any) -> ()) -> (),
	Unload: (self: LoadedAnimation) -> (),
	DelayAnimationEvent: (self: LoadedAnimation, EventName: string, callback: (...any) -> ()) -> (),
}

export type AnimationModule = {
	__index: AnimationModule,

	Preload: (self: AnimationModule, AnimID: string, LoadKeyFrames: boolean) -> (),
	LoadAnimation: (
		AnimationObject: Model | Humanoid | Animator,
		AnimID: string,
		AnimName: string,
		AnimGroups: {},
		LoadKeyFrames: boolean
	) -> LoadedAnimation,

	FindAnimation: (self: AnimationModule, AnimationInstance: Instance, AnimName: string) -> LoadedAnimation | nil,

	GetLoadedAnimations: (self: AnimationModule, AnimationInstance: Instance) -> { [string]: LoadedAnimation },

	StopAllLoadedAnimations: (self: AnimationModule, AnimationInstance: Instance, Fade: number) -> (),

	StopAllLoadedAnimationsExcept: (
		self: AnimationModule,
		AnimationInstance: Instance,
		Except: { string },
		Fade: number
	) -> (),

	StopAllLoadedAnimationsExceptGroups: (
		self: AnimationModule,
		AnimationInstance: Instance,
		ExceptGroups: { string },
		Fade: number
	) -> (),

	StopAllLoadedAnimationsInGroups: (
		self: AnimationModule,
		AnimationInstance: Instance,
		Groups: { string },
		Fade: number
	) -> (),

	FindAnimationEvents: (self: AnimationModule, AnimationID: string) -> { [string]: number },

	ClearLoadedAnimationsInGroups: (self: AnimationModule, AnimationInstance: Instance, Groups: { string }) -> (),

	IsAnimLoaded: (self: AnimationModule, AnimationInstance: Instance, AnimName: string) -> boolean,
}

return nil
