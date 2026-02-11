UCLASS(Abstract, NotPlaceable, ClassGroup = "Managers", Meta = (ShortTooltip = "Manages weather and seasons"))
class AWeatherManager : AActor
{
	UPROPERTY(Category = "Weather", VisibleInstanceOnly, BlueprintReadOnly, Replicated)
	EWeather CurrentWeather = EWeather::ClearSkies;

	UPROPERTY(Category = "Weather", VisibleInstanceOnly, BlueprintReadOnly, Replicated)
	EWeather PreviousWeather = EWeather::ClearSkies;

	UPROPERTY(Category = "Weather", VisibleInstanceOnly, BlueprintReadOnly, Replicated)
	EWeather NextWeather;

	UPROPERTY(Category = "Season", VisibleInstanceOnly, BlueprintReadOnly, Replicated)
	ESeason CurrentSeason = ESeason::Spring;

    UPROPERTY(Category = "Season", VisibleInstanceOnly, Replicated)
    bool Spring;
	UPROPERTY(Category = "Season", VisibleInstanceOnly, Replicated)
	float Autumn;
	UPROPERTY(Category = "Season", VisibleInstanceOnly, Replicated)
	float Winter;

    UPROPERTY(Category = "Season", Meta=(InlineEditConditionToggle))
    bool FixedSpringDuration = false;
    UPROPERTY(Category = "Season", Meta=(InlineEditConditionToggle))
    bool FixedAutumnDuration = false;
    UPROPERTY(Category = "Season", Meta=(InlineEditConditionToggle))
    bool FixedWinterDuration = false;

    UPROPERTY(Category = "Season", Meta=(EditCondition="!FixedSpringDuration"))
    float SpringDuration = 10.0f;
    UPROPERTY(Category = "Season", Meta=(EditCondition="!FixedAutumnDuration"))
    float AutumnDuration = 10.0f;
    UPROPERTY(Category = "Season", Meta=(EditCondition="!FixedWinterDuration"))
    float WinterDuration = 10.0f;

	UPROPERTY(Category = "Weather", VisibleInstanceOnly, Replicated)
	bool Leaves;
	UPROPERTY(Category = "Weather", VisibleInstanceOnly, Replicated)
	bool Snowing;
	UPROPERTY(Category = "Weather", VisibleInstanceOnly, Replicated)
	bool Raining;

    float TimeSinceSeasonChange = 0.0f;

    default bReplicates = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TransitionWeather(DetermineWeather());

        RandomizeSeasonDurations(60, 300); // Randomize season durations between 1 and 5 minutes
        
        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        TimeSinceSeasonChange += DeltaSeconds;

        BP_Tick();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Tick")
    void BP_Tick() { }

	UFUNCTION(Category = "Weather")
	EWeather DetermineWeather()
	{
        switch (CurrentSeason)
        {
            case ESeason::Spring:
            case ESeason::Autumn:
            {
                Snowing = false; // No snow in spring or autumn
                
                if (PreviousWeather == EWeather::Snow)
                {
                    Raining = true;
                }

                float p = Math::RandRange(0.0f, 1.0f);

                // Simple persistence to avoid jittery changes
                if (PreviousWeather == EWeather::Rain && p < 0.6f && Raining)
                {
                    return EWeather::Rain;
                }

                if (Leaves)
                {
                    if (Raining)
                    {
                        // Leaves + rain -> mostly rain, small chance of thunder or wind
                        if (p < 0.80f) return EWeather::Rain;
                        //if (p < 0.90f) return EWeather::Thunder;
                        return EWeather::Wind;
                    }
                    else
                    {
                        // Leaves without rain -> wind or cloudy, sometimes clear
                        if (p < 0.50f) return EWeather::Wind;
                        if (p < 0.75f) return EWeather::Cloudy;
                        return RandomSky();
                    }
                }
                else
                {
                    // No leaves -> more chance of fog/cloudy or clear
                    if (p < 0.20f) return EWeather::Fog;
                    if (p < 0.50f) return EWeather::Cloudy;
                    return RandomSky();
                }
            }
            
            case ESeason::Winter:
            {
                Raining = false; // No rain in winter
                Leaves = false; // No leaves in winter (Snow is just recoloured leaves)

                if (PreviousWeather == EWeather::Rain)
                {
                    Snowing = true;
                }

                // Winter prefers snow, but allow cloudy/fog variations
                if (Snowing)
                {
                    return EWeather::Snow;
                }

                float p = Math::RandRange(0.0f, 1.0f);
                if (p < 0.50f) return EWeather::Cloudy;
                return EWeather::FairSkies;
            }
        }
	}

	EWeather RandomSky() // 50/50 chance between ClearSkies and FairSkies
	{
		if (Math::RandBool())
		{
			return EWeather::FairSkies;
		}
		else
		{
			return EWeather::ClearSkies;
		}
	}

	UFUNCTION(Category = "Weather")
	void TransitionWeather(EWeather NewWeather)
	{
		PreviousWeather = CurrentWeather;
		CurrentWeather = NewWeather;
	}

    UFUNCTION(Category = "Season", BlueprintPure)
    TArray<float> RandomizeSeasonDurations(float MinDuration = 5.0f, float MaxDuration = 10.0f)
    {
        TArray<float> Durations;
        
        SpringDuration = Math::RandRange(MinDuration, MaxDuration);
        AutumnDuration = Math::RandRange(MinDuration, MaxDuration);
        WinterDuration = Math::RandRange(MinDuration, MaxDuration);

        Durations.Add(SpringDuration);
        Durations.Add(AutumnDuration);
        Durations.Add(WinterDuration);

        return Durations;
    }

	UFUNCTION(Category = "Season", NetMulticast)
	void TransitionSeason(ESeason NewSeason)
	{
		CurrentSeason = NewSeason;
		switch (CurrentSeason)
		{
			case ESeason::Spring:
                Spring = true;
				Winter = 0.0f;
				Autumn = 0.0f;
				break;
			case ESeason::Autumn:
                Spring = false;
				Winter = 0.0f;
				Autumn = 1.0f;
				break;
			case ESeason::Winter:
                Spring = false;
				Winter = 1.0f;
				Autumn = 0.0f;
				break;
		}

        TimeSinceSeasonChange = 0.0f;
        TransitionWeather(DetermineWeather());
	}
};

enum EWeather
{
	// Clear / pleasant
	ClearSkies,
	FairSkies,

	// Cloudiness / low visibility
	Cloudy,
	Fog,

	// Precipitation (light to heavy)
	Rain,
	Snow,
	Thunder,
	Thunderstorms,

	// Wind-related
	Wind,
}

enum ESeason
{
	Spring,
	// No summer because the asset pack didn't cover it lol
	Autumn,
	Winter,
}