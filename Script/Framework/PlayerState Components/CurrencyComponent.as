UCLASS(Abstract)
class UCurrencyComponent : UFishComponentBase
{
	UPROPERTY(Category = "Currency", SaveGame)
	TMap<ECurrency, int> Currencies;
	default Currencies.Add(ECurrency::Money, 0);

	UFUNCTION(BlueprintPure)
	int GetMoney() property
	{
		int Value;
		if (Currencies.Find(ECurrency::Money, Value))
		{
			return Value;
		}
		else throw("Could not find entry by that currency type!");
		return -1;
	}

    UFUNCTION(BlueprintPure)
	int GetCurrency(ECurrency Currency)
	{
		int Value;
		if (Currencies.Find(Currency, Value))
		{
			return Value;
		}
		else throw("Could not find entry by that currency type!");
		return -1;
	}

	UFUNCTION(Category = "Currency", DisplayName = "Gain Currency")
	void BP_GainCurrency(ECurrency Currency, int Amount, int&out NewValue)
	{
		if (Currencies.Find(Currency, NewValue))
		{
			NewValue = Math::Max(0, NewValue + Amount);
            Currencies.Add(Currency, NewValue);
		}
		else throw("Could not find entry by that currency type!");
	}

    void GainCurrency(ECurrency Currency, int Amount)
	{
        int Value;
		if (Currencies.Find(Currency, Value))
		{
			Value = Math::Max(0, Value + Amount);
            Currencies.Add(Currency, Value);
		}
		else throw("Could not find entry by that currency type!");
	}

	UFUNCTION(Category = "Currency", DisplayName = "Spend Currency", Meta=(ReturnDisplayName="Can Afford"))
	bool BP_SpendCurrency(ECurrency Currency, int Cost, int&out NewValue)
	{
		if (CanAfford(Currency, Cost))
		{
			if (Currencies.Find(Currency, NewValue))
			{
				NewValue = Math::Max(0, NewValue - Cost);
                Currencies.Add(Currency, NewValue);
				return true;
			}
			else throw("Could not find entry by that currency type!");
		}
		return false;
	}

	bool SpendCurrency(ECurrency Currency, int Cost)
	{
        int Value;
		if (CanAfford(Currency, Cost))
		{
			if (Currencies.Find(Currency, Value))
			{
				Value = Math::Max(0, Value - Cost);
                Currencies.Add(Currency, Value);
				return true;
			}
			else throw("Could not find entry by that currency type!");
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool CanAfford(ECurrency Currency, int Cost)
	{
		int Value;
		if (Currencies.Find(Currency, Value) && Value >= Cost)
		{
			return true;
		}
		else throw("Could not find entry by that currency type!");
		return false;
	}

	void PostInitialize(AFishCharacter InCharacter, AFishPlayerState InPlayerState, AFishController InController) override
	{
		Super::PostInitialize(InCharacter, InPlayerState, InController);
	}

	bool SaveCurrencies()
	{
		auto SaveGame = Gameplay::CreateSaveGameObject(UCurrencySaveGame);

		SaveGame.Currencies = Currencies;

		return Gameplay::SaveGameToSlot(SaveGame, "PlayerCurrencies", 0);
	}

	ELoadResult LoadCurrencies()
	{
		auto SaveGame = Gameplay::LoadGameFromSlot("PlayerCurrencies", 0);
		if (SaveGame == nullptr)
			return ELoadResult::NoData;

		auto LoadedSave = Cast<UCurrencySaveGame>(SaveGame);
		if (LoadedSave == nullptr)
			return ELoadResult::Failure;

		Currencies = LoadedSave.Currencies;

		return ELoadResult::Success;
	}
};

enum ECurrency
{
	Money
}