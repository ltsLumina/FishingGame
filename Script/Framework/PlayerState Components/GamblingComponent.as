/**
 * Gamble Gil on whether you manage to catch a specific fish within a set number of attempts.
 */
class UGamblingComponent : UFishComponentBase
{
    UPROPERTY(Category = "Gambling")
    int AmountBet;

    /**
     * The amount of fishing attempts before resolving the bet.
     */
    UPROPERTY(Category = "Gambling", BlueprintGetter = "GetFishingAttempts")
    int FishingAttempts;

    UFUNCTION(BlueprintPure)
    int GetFishingAttempts()
    {
        return FishingAttempts + 10;
    }

    UPROPERTY(Category = "Gambling")
    UFishItem RequiredFish;

    UPROPERTY(Category = "Gambling")
    int TotalWinnings;

    UPROPERTY(Category = "Gambling")
    APlayerState BettingPlayer; // The player who placed the bet. They must be the one to catch the fish.

    UPROPERTY()
    TArray<APlayerState> BettingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
    
	void LatePlay() override
	{
		Super::LatePlay();

        BettingPlayer = State;
        Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnFishCaught(AFish Fish)
    {
        if (FishingAttempts > 0)
        {
            ResolveBet(Fish);
        }
    }

    UFUNCTION(Category = "Gambling")
    void PlaceBet(int InAmountBet, int InFishingAttempts)
    {
        AmountBet = InAmountBet;
        FishingAttempts = InFishingAttempts;
    }

    UFUNCTION(Category = "Gambling")
    void ResolveBet(AFish CaughtFish)
    {
        FishingAttempts--;

        if (CaughtFish.Item == RequiredFish)
        {
            // Player wins
            int Winnings = AmountBet * 2;
            TotalWinnings += Winnings;
            BettingPlayers.Add(State);
            Notifications::AddNotification(f"You earned {Winnings} Gil from your bet!", 5.0f);
            FishingAttempts = 0; // End betting
        }
        else if (FishingAttempts <= 0)
        {
            // Player loses
            Notifications::AddNotification(f"You lost your bet! (-{AmountBet} Gil)", 5.0f);
            AmountBet = 0;
            TotalWinnings = 0;
        }
        else
        {
            Notifications::AddNotification(f"You have {FishingAttempts} attempts remaining to catch the {RequiredFish.GetItemName()}.", 5.0f);
        }
    }
};