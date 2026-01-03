namespace TimeManager
{
    UFUNCTION()
    FGameTime GetGameTime() { return Gameplay::GetActorOfClass(ATimeManager).GameTime; }
}

UCLASS(NotPlaceable, ClassGroup = "Managers", Abstract, Meta = (ShortTooltip = "Manages in-game time progression and day-night cycle"))
class ATimeManager : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector::UpVector * 100;

	UPROPERTY(Category = "Time", ReplicatedUsing = OnRep_GameTime)
    FGameTime GameTime;
    default GameTime.Hour = 7;
    default GameTime.Minute = 0;

	/**
	 * runs on clients when GameTime changes on the server
	 */
	UFUNCTION(NotBlueprintCallable)
    void OnRep_GameTime() { UpdateSunRotation(); }

	UPROPERTY(Category = "Time")
	ETimeOfDay TimeOfDay;

	UPROPERTY(Category = "Time")
	TMap<ETimeOfDay, FVector2D> TimeOfDayLimits;
	default TimeOfDayLimits.Add(ETimeOfDay::Morning, FVector2D(6, 12));
	default TimeOfDayLimits.Add(ETimeOfDay::Afternoon, FVector2D(12, 18));
	default TimeOfDayLimits.Add(ETimeOfDay::Evening, FVector2D(18, 21));
	default TimeOfDayLimits.Add(ETimeOfDay::Night, FVector2D(21, 6));

	/**
	 * Time scale factor:
	 * 30 = 1 real second = 30 in-game seconds
	 * 60 = 1 real second = 1 in-game minute
	 * 120 = 1 real second = 2 in-game minutes
	 */
	UPROPERTY(Category = "Time", Meta = (UIMin = "1.0", UIMax = "120.0", Delta = "10.0"))
	float TimeScale = 60.0f;

	/**
	 * Global time dilation factor affecting the speed of time progression.
	 * 1.0 = normal speed, <1.0 = slower, >1.0 = faster.
	 */
	UPROPERTY(Category = "Time", Meta = (UIMin = "0.1", UIMax = "100.0", Delta = "1"))
	float TimeDilation = 1.0f;

	/**
	 * The ratio of real-world seconds to in-game seconds.
	 * E.g., if TimeScale is 60, then 1 real second = 60 in-game seconds.
	 */
	UPROPERTY(Category = "Time", VisibleInstanceOnly, Meta = (Units = "s"))
	float RealSecondToGameSecond;

	/**
	 * Current in-game time represented as a FTimespan for easier calculations.
	 */
    UPROPERTY(NotVisible, Replicated)
	FTimespan CurrentTime;

	ADirectionalLight SunActor;
	AStaticMeshActor SkySphereActor;

	default bReplicates = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SunActor = Gameplay::GetActorOfClass(ADirectionalLight);

        TArray<AActor> Actors;
		Gameplay::GetAllActorsWithTag(n"SkySphere", Actors);
		SkySphereActor = Cast<AStaticMeshActor>(Actors[0]);

		Actors.Empty();

        CurrentTime = FTimespan::FromHours(GameTime.Hour) + FTimespan::FromMinutes(GameTime.Minute);

		BP_BeginPlay();
    }

	UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
	void BP_BeginPlay() { }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        // Only server authoritatively advances time
        if (HasAuthority())
        {
            SetTime(DeltaSeconds);
        }

		BP_Tick();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Tick")
	void BP_Tick() { }

    UFUNCTION(Server)
    void SetTime(float DeltaSeconds)
    {
        if (!HasAuthority()) return; // double-safety: only run on server

        CurrentTime += FTimespan::FromSeconds(DeltaSeconds * TimeScale);

        GameTime.Hour = CurrentTime.GetHours() % 24; // 24-hour format
        GameTime.Minute = CurrentTime.GetMinutes() % 60;
        GameTime.Second = CurrentTime.GetSeconds() % 60;
        GameTime.TimeOfDay = GetTimeOfDay(GameTime.Hour);

		RealSecondToGameSecond = TimeScale * TimeDilation;

        UpdateSunRotation();
    }

	ETimeOfDay GetTimeOfDay(int32 Hour)
	{
		if (Hour < 0 || Hour >= 24)
			throw("Hour must be between 0 and 23");

		for (auto& kvp : TimeOfDayLimits)
		{
			FVector2D Limits = kvp.Value;
			if (Limits.X < Limits.Y)
			{
				if (Hour >= Limits.X && Hour < Limits.Y)
					return kvp.Key;
			}
			else // Overnight range (e.g., 21 to 6)
			{
				if (Hour >= Limits.X || Hour < Limits.Y)
					return kvp.Key;
			}
		}
		return ETimeOfDay::Morning; // Default fallback
	}

    void UpdateSunRotation()
    {
        if (SunActor == nullptr) return;

        // Map 6:00 (360 minutes) to 0° so "0 minutes" in rotation = break of dawn (6 AM).
        float totalMinutes = GameTime.Hour * 60 + GameTime.Minute + GameTime.Second / 60.0f;
        float shiftedMinutes = totalMinutes - 360.0f; // shift so 6:00 -> 0
        // Wrap into [0, 1440)
        while (shiftedMinutes < 0.0f) shiftedMinutes += 1440.0f;
        while (shiftedMinutes >= 1440.0f) shiftedMinutes -= 1440.0f;

        float fractionOfDay = shiftedMinutes / 1440.0f;
        float pitchDegrees = fractionOfDay * 360.0f;

        // Apply rotation. Keep the same roll/yaw setup as before.
        FRotator newRot = FRotator(-pitchDegrees, 0.0f, 180.0f);
        SunActor.SetActorRotation(newRot);

		auto Component = SkySphereActor.StaticMeshComponent;
		Component.SetScalarParameterValueOnMaterials(n"Glow Crank", fractionOfDay);
		Component.SetScalarParameterValueOnMaterials(n"Opacity", 1.0f - Math::Abs(1 - fractionOfDay) * 2.0f);
    }

	UFUNCTION(CallInEditor, DisplayName = "Next Time of Day")
	void NextTimeofDay()
	{
		switch (GameTime.TimeOfDay)
		{
			case ETimeOfDay::Morning:
				CurrentTime = FTimespan::FromHours(12); // Noon
				break;
			case ETimeOfDay::Afternoon:
				CurrentTime = FTimespan::FromHours(18); // 6 PM
				break;
			case ETimeOfDay::Evening:
				CurrentTime = FTimespan::FromHours(21); // 9 PM
				break;
			case ETimeOfDay::Night:
				CurrentTime = FTimespan::FromHours(6);	// 6 AM
				break;
		}

		GameTime.Hour = CurrentTime.GetHours() % 24;
		GameTime.Minute = CurrentTime.GetMinutes() % 60;
		GameTime.Second = CurrentTime.GetSeconds() % 60;
		GameTime.TimeOfDay = GetTimeOfDay(GameTime.Hour);

		UpdateSunRotation();
	}

	UFUNCTION(CallInEditor)
	void ResetTime()
	{
		CurrentTime = FTimespan::FromHours(12); // Reset to noon
		GameTime.Hour = 12;
		GameTime.Minute = 0;
		GameTime.Second = 0;
		GameTime.TimeOfDay = ETimeOfDay::Afternoon;

		UpdateSunRotation();
	}
};

struct FGameTime
{
	UPROPERTY(Replicated)
	int32 Hour;
	UPROPERTY(Replicated)
	int32 Minute;
	UPROPERTY(Replicated)
	int32 Second;
	UPROPERTY(Replicated)
	ETimeOfDay TimeOfDay;
}

struct FShortGameTime
{
	UPROPERTY(Meta=(UIMin="0", UIMax="23", Delta="1"))
	int32 Hour;
	UPROPERTY(Meta=(UIMin="0", UIMax="59", Delta="5", ClampMax="59"))
	int32 Minute;
}

struct FGameTimeSpan
{
	UPROPERTY()
	FShortGameTime StartTime;

	UPROPERTY()
	FShortGameTime EndTime;
}

enum ETimeOfDay
{
	Morning,
	Afternoon,
	Evening,
	Night
}