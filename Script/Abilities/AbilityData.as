namespace Ability
{
	const float GLOBAL_COOLDOWN_DURATION = 1.0f;
}

class UAbilityData : UPrimaryDataAsset
{
	UPROPERTY(Category = "Details")
	FAbilityDetails Details;

	/**
	 * The class that implements the ability's functionality.
	 */
	UPROPERTY(Category = "Logic")
	TSubclassOf<UAbility> AbilityClass;

	/**
	 * Conditions that must be satisfied to use this ability.
	 * Each condition is represented by a subclass of UAbilityCondition.
	 * Examples include being near water or being in a fishing state.
	 */
	UPROPERTY(Category = "Logic", EditInline, Instanced)
	TArray<UAbilityCondition> Conditions;

	UFUNCTION(BlueprintPure)
	bool CanUse(AFishCharacter User)
	{
		for (UAbilityCondition Condition : Conditions) 
		{
			if (Condition == nullptr) 
			{
				throw(f"Ability {AbilityClass.DefaultObject.GetName()} has a null AbilityCondition!");
				continue;
			}
			if (!Condition.IsSatisfied(User, User.FishingState)) 
			{
				return false;
			}
		}

		return true;
	}
};

USTRUCT()
struct FAbilityDetails
{
	UPROPERTY()
	FText Name;

	UPROPERTY(Meta = (MultiLine))
	FText Description;

	/**
	 * The effect that the ability has when used, e.g., "Restores 500 MP over 10 seconds."
	 */
	UPROPERTY(Meta = (MultiLine))
	FText Effect;

	UPROPERTY(Meta = (UIMin = "1", UIMax = "50"))
	int UnlockLevel = 1;

	UPROPERTY()
	UTexture2D Icon;

	UPROPERTY()
	FCooldownType Cooldown;

	UPROPERTY()
	FCostType Cost;
};

struct FCooldownType
{
	UPROPERTY()
	ECooldownType Type;

	UPROPERTY(Meta = (EditCondition = "Type == ECooldownType::oGCD", EditConditionHides, ClampMin = "0", ClampMax = "120", Delta = "10"))
	float Duration = Ability::GLOBAL_COOLDOWN_DURATION;
}

enum ECooldownType
{
	GCD UMETA(DisplayName = "Global Cooldown"),
	oGCD UMETA(DisplayName = "Off-Global Cooldown"),
}

struct FCostType
{
	UPROPERTY()
	ECostType Type;

	UPROPERTY(Meta = (EditCondition = "Type != ECostType::None", EditConditionHides, ClampMin = "0", ClampMax = "20000", Delta = "100"))
	int Amount;
}

enum ECostType
{
	None,
	MP,
	Other,
}