class UEmotePlayerComponent : UFishComponentBase
{
    UPROPERTY(Category = "Emotes", EditDefaultsOnly)
    TArray<UAnimMontage> Emotes;

    UPROPERTY(Category = "Emotes", VisibleInstanceOnly, BlueprintReadOnly, BlueprintGetter="GetPlayingEmote")
    private UAnimMontage PlayingMontage;

    UPROPERTY(Category = "Emotes", NotVisible, BlueprintReadOnly)
    UAnimInstance AnimInstance;

    default bReplicates = false;

    void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState,
                        float InInitializationTime) override
    {
        Super::PostInitialize(InCharacter, InPlayerState, InInitializationTime);
        AnimInstance = InCharacter.Mesh.GetAnimInstance();
    }

    UFUNCTION()
    void PlayEmote()
    {
        if (Emotes.Num() == 0)
            return;
        
        PlayEmoteEvent(Emotes[0]);
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Play Emote")
    private void PlayEmoteEvent(UAnimMontage Emote) { }

    UFUNCTION()
    void StopEmote()
    {
        StopEmoteEvent(GetPlayingEmote());
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Stop Emote")
    private void StopEmoteEvent(UAnimMontage Emote) { }

    UFUNCTION(BlueprintPure, Meta=(ReturnDisplayName="Playing Emote"), Keywords="current")
    UAnimMontage GetPlayingEmote()
    {
        return AnimInstance.GetCurrentActiveMontage();
    }
}