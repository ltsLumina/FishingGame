event void FOnTokenAdded(FTokenEntry TokenEntry);
event void FOnTokenRemoved(FTokenEntry TokenEntry);
event void FOnTokenExpired(FTokenEntry TokenEntry);
event void FOnTokenCooldownAdded(FGameplayTag Token, float Duration, FText EffectName);
event void FOnTokenCooldownExpired(FGameplayTag Token);

class UTokenComponent : UFishComponentBase
{
	/**
	 * Tokens are granted by certain abilities or traits to modify fishing behavior (e.g., ignoring conditions).
	 * For instance, an ability may grant a "Thaliak's Favor" token, which can be used by other abilities.
	 * **Key:** FGameplayTag representing the token type.
	 * **Value:** Float representing the amount of tokens (stacks) the player has.
	 * @see FTokenEntry
	 */
	UPROPERTY(Category = "Tokens", VisibleInstanceOnly, BlueprintReadOnly)
	TMap<FGameplayTag, int> Tokens;

	UPROPERTY(Category = "Tokens", VisibleInstanceOnly, BlueprintReadOnly)
	TArray<FTokenEntry> ActiveTokens;

	/**
	 * Tokens that are currently on cooldown and cannot be granted again until the cooldown expires.
	 */
	UPROPERTY(Category = "Tokens", VisibleInstanceOnly, BlueprintReadOnly)
	TMap<FGameplayTag, float> CooldownTokens;

	UPROPERTY(Category = "Events")
	FOnTokenAdded OnTokenAdded;

	UPROPERTY(Category = "Events")
	FOnTokenRemoved OnTokenRemoved;

	UPROPERTY(Category = "Events")
	FOnTokenExpired OnTokenExpired;

	UPROPERTY(Category = "Events")
	FOnTokenCooldownAdded OnTokenCooldownAdded;

	UPROPERTY(Category = "Events")
	FOnTokenCooldownExpired OnTokenCooldownExpired;

	default ComponentTickInterval = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = ActiveTokens.Num() - 1; i >= 0; i--)
		{
			FTokenEntry Entry = ActiveTokens[i];

			if (Entry.RemainingTime > 0.0f)
			{
				Entry.RemainingTime -= DeltaSeconds;
				if (Entry.RemainingTime < 0.0f)
				{
					Entry.RemainingTime = 0.0f;
				}
			}

			float TotalTime = Entry.Duration;
			Entry.RemainingTimeString = Entry.RemainingTime > 0.0f ? f"{Entry.RemainingTime:.1f}s/{TotalTime:.1f}s" : "Expired";
			ActiveTokens[i] = Entry;

			if (Entry.RemainingTime <= 0.0f)
			{
				if (Entry.RefreshDuration)
				{
					if (RemoveToken(Entry.Tag, 1) > 0) // There are still tokens left, restart the countdown for the next stack
					{
						Entry.Amount = Math::Max(Entry.Amount - 1, 0);
						Entry.RemainingTime = Entry.Duration;
						Entry.RemainingTimeString = f"{Entry.RemainingTime:.1f}s/{Entry.Duration:.1f}s";
						ActiveTokens[i] = Entry;
						Print(f"Token {Entry.Tag} expired, but more remain. \nNew amount: {Tokens[Entry.Tag]}", 3.0f, FLinearColor::LucBlue);
						OnTokenExpired.Broadcast(Entry);
					}
					else // last token expired
					{
						FTokenEntry ExpiredEntry = FTokenEntry(Entry.Tag, 0, Entry.MaxAmount, -1.0f, Entry.ID);
						ExpiredEntry.RemainingTime = 0.0f;
						ExpiredEntry.RemainingTimeString = "Expired";
						ActiveTokens.RemoveAt(i);
						OnTokenExpired.Broadcast(ExpiredEntry);
					}
				}
				else // not refreshing duration, just remove the token entry
				{
					FTokenEntry ExpiredEntry = FTokenEntry(Entry.Tag, 0, Entry.MaxAmount, -1.0f, Entry.ID);
					RemoveToken(Entry.Tag, Entry.Amount);
					ActiveTokens.RemoveAt(i);
					OnTokenExpired.Broadcast(ExpiredEntry);
				}
			}
		}

		for (int i = CooldownTokens.Num() - 1; i >= 0; i--)
		{
			TArray<FGameplayTag> Keys;
			CooldownTokens.GetKeys(Keys);
			FGameplayTag Token = Keys[i];
			float& Duration = CooldownTokens[Token];

			Duration -= DeltaSeconds;
			if (Duration <= 0.0f)
			{
				CooldownTokens.Remove(Token);
				OnTokenCooldownExpired.Broadcast(Token);
			}
		}
	}

	/**
	 * Adds a specific token to the player's fishing component.
	 * @param Token The token to add.
	 * @param Amount The amount to add.
	 * @return The new total amount of the token after addition.
	 * @note This function does not invoke the OnTokenAdded event! Use AddTokenForDuration to add tokens with duration and trigger the event.
	 */
	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "New Amount", Categories = "Token"))
	int AddToken(FGameplayTag Token, int Amount = 1)
	{
		if (Tokens.Contains(Token))
		{
			Tokens[Token] += Amount;
			return Tokens[Token];
		}
		else
		{
			Tokens.Add(Token, Amount);
			return Amount;
		}
	}

	/**
	 * Removes a specific token from the player's fishing component.
	 * @param Token The token to remove.
	 * @param Amount The amount to remove.
	 * @return The new total amount of the token after removal, or -1 if the token did not exist.
	 * @note This function does not invoke the OnTokenRemoved event! Use AddTokenForDuration to manage tokens with duration and trigger the event.
	 */
	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "New Amount", Categories = "Token"))
	int RemoveToken(FGameplayTag Token, int Amount = 1)
	{
		if (Tokens.Contains(Token))
		{
			Tokens[Token] = Math::Max(Tokens[Token] - Amount, 0); // prevent negative values
			if (Tokens[Token] <= 0)
			{
				Tokens.Remove(Token);
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

	/**
	 * Adds a token for a specified duration. If the token already exists and RefreshDuration is true, the timer is reset.
	 * @param Token The token to add.
	 * @param Amount The amount to add.
	 * @param MaxTokens The maximum number of tokens allowed (0 for unlimited).
	 * @param Duration The duration in seconds for which the token is valid.
	 * @param RefreshDuration Whether to refresh the duration if the token already exists. If this is false, multiple tokens can still be added, but the duration of existing tokens won't be refreshed.
	 * @param Identifier An optional identifier to distinguish between multiple instances of the same token. (For targeted removal)
	 * @param CurrentTokens Output parameter to receive the current amount of the token after addition. (Shorthand for GetToken)
	 * @param TokenEntry Output parameter to receive the details of the added token entry.
	 * @return True if the token was added successfully, false if the maximum token limit was reached.
	 */
	UFUNCTION(Category = "Fishing | Tokens", Meta = (ReturnDisplayName = "Success", Categories = "Token", AdvancedDisplay = "Identifier"))
	bool AddTokenForDuration(FGameplayTag Token, int Amount, int MaxTokens = 1, float Duration = 5.0f, bool RefreshDuration = true, FName Identifier = NAME_None, int&out CurrentTokens = 0.0f, FTokenEntry&out TokenEntry = FTokenEntry())
	{
		if (IsTokenOnCooldown(Token)) // optional cooldown token check
		{
			PrintWarning(f"Cannot add token {Token}. Cooldown is still active.", 3.0f);
			TokenEntry = FTokenEntry(Token, 0, MaxTokens, -1.0f, Identifier);
			return false;
		}

		GetToken(Token, CurrentTokens);

		// If MaxTokens is set and we've reached the limit, do not add more
		if (MaxTokens > 0 && CurrentTokens >= MaxTokens)
		{
			PrintWarning(f"Cannot add more of token {Token}. Max tokens reached: {MaxTokens}", 3.0f);
			TokenEntry = FTokenEntry(Token, CurrentTokens, MaxTokens, -1.0f, Identifier);
			return false;
		}
		else
		{
			CurrentTokens = AddToken(Token, Amount);
		}

		FTokenEntry NewEntry = FTokenEntry(Token, Amount, MaxTokens, Duration, Identifier);
		NewEntry.RemainingTime = Duration;
		NewEntry.RemainingTimeString = Duration > 0.0f ? f"{Duration:.1f}s/{Duration:.1f}s" : "Expired";

		if (RefreshDuration)
		{
			// Check if a token with the same tag and identifier already exists
			for (int i = 0; i < ActiveTokens.Num(); i++)
			{
				FTokenEntry ExistingEntry = ActiveTokens[i];
				if (ExistingEntry.Tag == Token && ExistingEntry.ID == Identifier)
				{
					// Refresh the countdown
					ExistingEntry.Duration = Duration;
					ExistingEntry.RemainingTime = Duration;
					ExistingEntry.Amount += Amount; // Increase the amount to the new total
					ExistingEntry.RemainingTimeString = Duration > 0.0f ? f"{Duration:.1f}s/{Duration:.1f}s" : "Expired";
					ExistingEntry.RefreshDuration = RefreshDuration;
					ActiveTokens[i] = ExistingEntry;
					TokenEntry = ExistingEntry;
					OnTokenAdded.Broadcast(ExistingEntry);
					return true;
				}
			}
		}
		else // not refreshing the duration, but add another token to the existing entry
		{
			for (int i = 0; i < ActiveTokens.Num(); i++)
			{
				FTokenEntry ExistingEntry = ActiveTokens[i];
				if (ExistingEntry.Tag == Token && ExistingEntry.ID == Identifier)
				{
					// Just increase the amount
					ExistingEntry.Amount += Amount;
					ActiveTokens[i] = ExistingEntry;
					TokenEntry = ExistingEntry;
					OnTokenAdded.Broadcast(ExistingEntry);
					return true;
				}
			}
		}

		ActiveTokens.Add(NewEntry);

		TokenEntry = NewEntry;
		OnTokenAdded.Broadcast(NewEntry);
		return true;
	}

	UFUNCTION(Category = "Fishing | Tokens", BlueprintPure, Meta = (Categories = "Token", ReturnDisplayName = "On Cooldown"))
	bool IsTokenOnCooldown(FGameplayTag Token)
	{
		return CooldownTokens.Contains(Token);
	}

	UFUNCTION(Category = "Fishing | Tokens", DisplayName = "Is Token on Cooldown", Meta = (Categories = "Token", ReturnDisplayName = "On Cooldown", ExpandBoolAsExecs = "ReturnValue"))
	bool IsTokenOnCooldown_Branch(FGameplayTag Token)
	{
		return CooldownTokens.Contains(Token);
	}

	UFUNCTION(Category = "Fishing | Tokens", Meta = (Categories = "Token"))
	void AddCooldownToken(FGameplayTag Token, float Duration = 5, FText EffectName = FText::FromString("Unknown Cooldown"))
	{
		if (!IsTokenOnCooldown(Token))
		{
			CooldownTokens.Add(Token, Duration);
			OnTokenCooldownAdded.Broadcast(Token, Duration, EffectName);
		}
	}

	/**
	 * Add a one-shot token for traits that want to fire once and immediately go on cooldown.
	 * Does not support stacking. If the token is already on cooldown, it will not be added, and the function will return false.
	 * @param Token The token to add.
	 * @param Duration The duration in seconds for which the token is valid.
	 * @param EffectName The name of the effect associated with the token.
	 * @return True if the token is not already on cooldown, false otherwise.
	 */
	UFUNCTION(Category = "Fishing | Tokens", Meta = (Categories = "Token", ExpandBoolAsExecs = "ReturnValue"))
	bool AddTokenOneShot(FGameplayTag Token, float Duration = 5, FText EffectName = FText::FromString("Unknown Cooldown"))
	{
		if (!IsTokenOnCooldown(Token))
		{
			CooldownTokens.Add(Token, Duration);
			OnTokenCooldownAdded.Broadcast(Token, Duration, EffectName);
			return true;
		}

		return false;
	}
}

struct FTokenEntry
{
	UPROPERTY(Meta = (Categories = "Token"), BlueprintReadOnly)
	FGameplayTag Tag;

	UPROPERTY(BlueprintReadOnly)
	int Amount;

	UPROPERTY(BlueprintReadOnly)
	int MaxAmount;

	UPROPERTY(BlueprintHidden)
	FString RemainingTimeString;

	UPROPERTY(NotVisible)
	float Duration;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float RemainingTime;

	UPROPERTY(BlueprintReadOnly)
	bool RefreshDuration;

	UPROPERTY()
	FName ID = NAME_None;

	FTokenEntry(FGameplayTag InTag, int InAmount, int InMaxAmount, float InDuration, FName InID)
	{
		Tag = InTag;
		Amount = InAmount;
		MaxAmount = InMaxAmount;
		Duration = InDuration;
		RemainingTime = InDuration;
		RemainingTimeString = InDuration > 0.0f ? f"{InDuration:.1f}s/{InDuration:.1f}s" : "Expired";
		ID = InID;
	}
}

struct FTokenDefinition
{
	UPROPERTY(Category = "Details", BlueprintReadOnly)
	bool DisplayMaxStackCount = true;

	UPROPERTY(Category = "Details")
	FText TokenName;

	UPROPERTY(Category = "Details", Meta = (MultiLine))
	FText Description;

	UPROPERTY(Category = "Visuals")
	UTexture2D Icon;

	/**
	 * Only used to quickly view gameplay tags in editor. Do not use or set this anywhere!s
	 */
	UPROPERTY(Category = "Debug", BlueprintHidden, NotVisible)
	private FGameplayTag Helper;
};

namespace Token
{
	UFUNCTION(BlueprintPure, Category = "Token")
	mixin FGameplayTag GetTag(FTokenEntry Entry)
	{
		return Entry.Tag;
	}

	UFUNCTION(BlueprintPure, Category = "Token")
	mixin FText GetCooldownName(FText EffectName)
	{
		FString ToString = EffectName.ToString();
		if (!ToString.Contains("Cooldown"))
		{
			return FText::FromString(f"{ToString} Cooldown");
		}

		return EffectName;
	}
}