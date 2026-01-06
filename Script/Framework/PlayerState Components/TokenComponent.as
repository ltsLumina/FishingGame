event void FOnTokenAdded(FGameplayTag Token, int NewAmount);
event void FOnTokenRemoved(FGameplayTag Token, int NewAmount);
event void FOnTokenExpired(FGameplayTag Token, int NewAmount);

class UTokenComponent : UFishComponentBase
{
	/**
	 * Tokens are granted by certain abilities or traits to modify fishing behavior (e.g., ignoring conditions).
	 * For instance, an ability may grant a "Thaliak's Favor" token, which can be used by other abilities.
	 * **Key:** FGameplayTag representing the token type.
	 * **Value:** Float representing the amount of tokens (stacks) the player has.
	 * @see FTokenEntry
	 */
	UPROPERTY(Category = "Tokens", VisibleInstanceOnly)
	TMap<FGameplayTag, int> Tokens;

	UPROPERTY(Category = "Tokens", VisibleInstanceOnly)
	TArray<FTokenEntry> ActiveTokens;

	UPROPERTY(Category = "Events")
	FOnTokenAdded OnTokenAdded;

	UPROPERTY(Category = "Events")
	FOnTokenRemoved OnTokenRemoved;

	UPROPERTY(Category = "Events")
	FOnTokenExpired OnTokenExpired;

	default ComponentTickInterval = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = ActiveTokens.Num() - 1; i >= 0; i--)
		{
			FTokenEntry Entry = ActiveTokens[i];
			float ElapsedTime = System::GetTimerElapsedTimeHandle(Entry.TimerHandle);
			float RemainingTime = System::GetTimerRemainingTimeHandle(Entry.TimerHandle);
			float TotalTime = RemainingTime + ElapsedTime;
			
			Entry.RemainingTime = RemainingTime;
			Entry.RemainingTimeString = RemainingTime > 0 ? f"{RemainingTime:.1f}s/{TotalTime:.1f}s" : "Expired";

			ActiveTokens[i] = Entry;

			if (System::IsValidTimerHandle(Entry.TimerHandle) && !System::IsTimerActiveHandle(Entry.TimerHandle))
			{
				if (RemoveToken(Entry.Tag, 1) > 0) // always remove 1 stack when the timer expires
				{
					// There are still tokens left, run the timer again
					Entry.TimerHandle = System::SetTimer(this, n"TokenExpired", Entry.Duration, false);
					Entry.Amount--;
					ActiveTokens[i] = Entry;
					Print(f"Token {Entry.Tag} expired, but more remain. \nNew amount: {Tokens[Entry.Tag]}", 3.0f, FLinearColor::LucBlue);
					OnTokenExpired.Broadcast(Entry.Tag, Tokens[Entry.Tag]);
				}
				else
				{
					ActiveTokens.RemoveAt(i);
				}
			}
		}
	}

	/**
	 * Adds a specific token to the player's fishing component.
	 * @param Token The token to add.
	 * @param Amount The amount to add.
	 * @return The new total amount of the token after addition.
	 */
	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "New Amount", Categories = "Token"))
	int AddToken(FGameplayTag Token, int Amount = 1)
	{
		if (Tokens.Contains(Token))
		{
			Tokens[Token] += Amount;
			OnTokenAdded.Broadcast(Token, Tokens[Token]);
			return Tokens[Token];
		}
		else
		{
			Tokens.Add(Token, Amount);
			OnTokenAdded.Broadcast(Token, Amount);
			return Amount;
		}
	}

	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "New Amount", Categories = "Token"))
	int RemoveToken(FGameplayTag Token, int Amount = 1)
	{
		if (Tokens.Contains(Token))
		{
			Tokens[Token] -= Amount;
			if (Tokens[Token] <= 0)
			{
				Tokens.Remove(Token);
				OnTokenRemoved.Broadcast(Token, 0);
				return 0.0f;
			}
			return Tokens[Token];
		}
		else
		{
			return -1;
		}
	}

	UFUNCTION()
	bool GetToken(FGameplayTag Token, int&out CurrentAmount = 0)
	{
		if (Tokens.Contains(Token))
		{
			CurrentAmount = Tokens[Token];
			return true;
		}
		else
		{
			CurrentAmount = 0.0f;
			return false;
		}
	}

	/**
	 * Checks if the player has a specific token with at least the specified amount.
	 * @param Token The token to check for.
	 * @param MinimumAmount The minimum amount required (default is 1.0f).
	 * @param CurrentAmount Output parameter to receive the current amount of the token.
	 * @return True if the player has at least the minimum amount of the token, false otherwise.
	 */
	UFUNCTION(Category = "Fishing | Tokens", BlueprintPure, Meta = (ReturnDisplayName = "Has Tokens", Categories = "Token"))
	bool HasToken(FGameplayTag Token, int MinimumAmount = 1, int&out CurrentAmount = 0)
	{
		if (Tokens.Contains(Token))
		{
			CurrentAmount = Tokens[Token];
			return CurrentAmount >= MinimumAmount;
		}
		else
		{
			CurrentAmount = 0.0f;
			return false;
		}
	}

	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "Success", Categories = "Token", AdvancedDisplay = "Identifier"))
	bool AddTokenForDuration(FGameplayTag Token, int Amount, int MaxTokens = 0, float Duration = 5.0f, bool RefreshDuration = true, FName Identifier = NAME_None, int&out CurrentTokens = 0.0f, FTokenEntry&out TokenEntry = FTokenEntry())
	{
		GetToken(Token, CurrentTokens);

		// If MaxTokens is set and we've reached the limit, do not add more
		if (MaxTokens > 0 && CurrentTokens >= MaxTokens)
		{
			Print(f"Cannot add more of token {Token}. Max tokens reached: {MaxTokens}", 3.0f, FLinearColor::LucBlue);
			TokenEntry = FTokenEntry(Token, CurrentTokens, -1.0f, FTimerHandle(), Identifier);
			return false;
		}
		else
		{
			CurrentTokens = AddToken(Token, Amount);
		}

		FTokenEntry NewEntry = FTokenEntry(Token, Amount, Duration, FTimerHandle(), Identifier);

		if (RefreshDuration)
		{
			// Check if a token with the same tag and identifier already exists
			for (int i = 0; i < ActiveTokens.Num(); i++)
			{
				FTokenEntry ExistingEntry = ActiveTokens[i];
				if (ExistingEntry.Tag == Token && ExistingEntry.ID == Identifier)
				{
					// Refresh the timer
					ExistingEntry.TimerHandle= System::SetTimer(this, n"TokenExpired", Duration, false);
					ExistingEntry.Amount += Amount;	 // Increase the amount to the new total
					ActiveTokens[i] = ExistingEntry;
					TokenEntry = ExistingEntry;
					OnTokenAdded.Broadcast(Token, CurrentTokens);
					return true;
				}
			}
		}

		NewEntry.TimerHandle = System::SetTimer(this, n"TokenExpired", Duration, false);
		ActiveTokens.Add(NewEntry);

		TokenEntry = NewEntry;
		OnTokenAdded.Broadcast(Token, CurrentTokens);
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void TokenExpired()
	{
		// This function is intentionally left blank.
		// The actual removal logic is handled in the Tick function.
		// This function serves as a callback for the timer.
	}
}

struct FTokenEntry
{
	UPROPERTY(Meta = (Categories = "Token"))
	FGameplayTag Tag;

	UPROPERTY()
	int Amount;

	UPROPERTY(BlueprintHidden)
	FString RemainingTimeString;

	UPROPERTY(NotVisible)
	float Duration;

	UPROPERTY()
	float RemainingTime;

	UPROPERTY(NotVisible)
	FTimerHandle TimerHandle;

	UPROPERTY()
	FName ID = NAME_None;


	FTokenEntry(FGameplayTag InTag, int InAmount, float InDuration, FTimerHandle InTimerHandle, FName InID)
	{
		Tag = InTag;
		Amount = InAmount;
		TimerHandle = InTimerHandle;
		ID = InID;
		Duration = InDuration;
	}
}