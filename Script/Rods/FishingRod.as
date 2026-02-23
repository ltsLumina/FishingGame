/**
 * Fishing rod item instance, like a Destiny weapon instance.
 * @see URodData for base data.
 */
class UFishingRod : UObject
{
	/**
	 * The base data for this rod.
	 */
	UPROPERTY(SaveGame)
	URodItem RodItem;

	/**
	 * The traits this rod has been generated with.
	 */
	UPROPERTY(SaveGame)
	TArray<TSubclassOf<UTrait>> Traits;

	UFUNCTION(BlueprintPure)
	FString GetTraitsString()
	{
		FString String;
		for (int i = 0; i < Traits.Num(); i++)
		{
			auto TraitClass = Traits[i];
			auto TraitCDO = TraitClass.GetDefaultObject();
			String = String::Concat_StrStr(String, TraitCDO.TraitName.ToString() + "\n");
		}
		return String;
	}
}