class UEmotePlayerComponent : UFishComponentBase
{
	UPROPERTY(Category = "Emotes", EditDefaultsOnly)
	TMap<EDirection, FEmoteData> EmoteMap;

	UPROPERTY(Category = "Emotes", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter = "GetPlayingEmote")
	private UAnimMontage PlayingMontage;

	UPROPERTY(Category = "Emotes", NotVisible, BlueprintReadOnly)
	UAnimInstance AnimInstance;

	UPROPERTY(Category = "Emotes", NotVisible, BlueprintReadOnly, BlueprintGetter = "GetIsEmotePlaying")
	bool IsEmotePlaying;

	default bReplicates = false;
    
	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, AFishController InController) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InController);
		AnimInstance = InCharacter.Mesh.GetAnimInstance();
	}

	UFUNCTION(Category = "Emotes")
	void PlayEmote(UAnimMontage Emote)
	{
		if (EmoteMap.IsEmpty())
			return;

		if (Emote == nullptr)
			return;

		TArray<EFishingState> InvalidStates;
		InvalidStates.Add(EFishingState::Fishing);
		InvalidStates.Add(EFishingState::ReelingIn);
		if (Character.FishingComponent.IsAnyState(InvalidStates))
			return;

		PlayEmoteEvent(Emote);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Play Emote")
	private void PlayEmoteEvent(UAnimMontage Emote)
	{}

	UFUNCTION()
	void StopEmote(UAnimMontage Emote)
	{
		StopEmoteEvent(AnimInstance.IsAnyMontagePlaying() ? GetPlayingEmote() : Emote);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Emote")
	private void StopEmoteEvent(UAnimMontage Emote)
	{}

	UFUNCTION(NotBlueprintCallable, BlueprintPure, Meta = (ReturnDisplayName = "Playing Emote"), Keywords = "current")
	UAnimMontage GetPlayingEmote()
	{
		return AnimInstance.GetCurrentActiveMontage();
	}

	UFUNCTION(NotBlueprintCallable, BlueprintPure, Meta = (DisplayName = "Is Emote Playing"))
	bool GetIsEmotePlaying()
	{
		// check if any EMOTE is playing
		for (auto& Pair : EmoteMap)
		{
			if (AnimInstance.CurrentActiveMontage == Pair.Value.Montage)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	FEmoteData GetEmote(EDirection Direction)
	{
		return EmoteMap.Contains(Direction) ? EmoteMap[Direction] : FEmoteData();
	}
}

struct FEmoteData
{
	UPROPERTY(BlueprintReadOnly)
	UAnimMontage Montage;

	UPROPERTY(BlueprintReadOnly)
	UTexture2D Icon;
}

enum EDirection
{
	// Cardinals
	North = 0,
	East = 1,
	South = 2,
	West = 3,

	// Ordinals
	NorthEast,
	SouthEast,
	SouthWest,
	NorthWest,

	// shouldn't be used
	None,
}