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
    UPROPERTY(Category = "Gambling")
    int FishingAttempts;

    UPROPERTY(Category = "Gambling")
    FName RequiredFish;

    UPROPERTY(Category = "Gambling")
    int TotalWinnings;

    UPROPERTY(Category = "Gambling")
    APlayerState BettingPlayer; // Player who initiated the bet

    UPROPERTY(Category = "Gambling")
    APlayerState OpponentPlayer; // The other player in the bet

    UPROPERTY(Category = "Gambling")
    TArray<APlayerState> BettingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
    
	void LatePlay() override
	{
		Super::LatePlay();

        Character.FishingComponent.OnFishCaught.AddUFunction(this, n"OnFishCaught");
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnFishCaught(AFish Fish)
    {
        if (BettingPlayers.Num() == 0)
            return;
        
        if (FishingAttempts > 0)
        {
            TryResolveBet(Fish);
        }
    }

    UFUNCTION(Category = "Gambling")
    void PlaceBet(APlayerState Against, int InAmountBet, FName InRequiredFish, int InFishingAttempts)
    {
        AmountBet = InAmountBet;
        RequiredFish = InRequiredFish;
        FishingAttempts = InFishingAttempts;
        TotalWinnings = 0;
        BettingPlayer = State;
        OpponentPlayer = Against;
        
        Notifications::AddNotification(f"Betting {AmountBet}$ against {Against.GetPlayerName()} to catch a {RequiredFish} within {FishingAttempts} attempts!", 5.0f);   
    }

    UFUNCTION(Category = "Gambling")
    void ReceiveBet(APlayerState From, int InAmountBet, FName InRequiredFish, int InFishingAttempts)
    {
        AmountBet = InAmountBet;
        RequiredFish = InRequiredFish;
        FishingAttempts = InFishingAttempts;
        TotalWinnings = 0;
        BettingPlayer = From;
        BettingPlayers.Add(From);
        BettingPlayers.Add(State);

        Notifications::AddNotification(f"{From.GetPlayerName()} has challenged you to a bet of {AmountBet}$ to catch a {RequiredFish} within {FishingAttempts} attempts!", 5.0f);
    }

    UFUNCTION(Category = "Gambling")
    void TryResolveBet(AFish CaughtFish)
    {
        FishingAttempts--;

        if (CaughtFish.Item.GetID() == RequiredFish)
        {
            // Bettor wins
            int Winnings = AmountBet * 2;
            TotalWinnings += Winnings;
            UStatsComponent::Get(BettingPlayer).GainGil(Winnings);
            UStatsComponent::Get(OpponentPlayer).GainGil(-AmountBet);
            
            Notifications::AddNotification(f"You earned {Winnings} Gil from your bet!", 5.0f);
            FishingAttempts = 0;
        }
        else if (FishingAttempts <= 0)
        {
            // Bettor loses, opponent wins
            UStatsComponent::Get(BettingPlayer).GainGil(-AmountBet);
            UStatsComponent::Get(OpponentPlayer).GainGil(AmountBet);
            
            Notifications::AddNotification(f"You lost your bet! (-{AmountBet} Gil)", 5.0f);
            AmountBet = 0;
            TotalWinnings = 0;
        }
        else
        {
            Notifications::AddNotification(f"You have {FishingAttempts} attempts remaining to catch the {RequiredFish}.", 5.0f);
        }
    }
};