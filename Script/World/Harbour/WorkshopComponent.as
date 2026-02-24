event void FOnHarbourDeliveryCompleted(FWorkshopProduct Product, float Value);
event void FOnHarbourReset(FDateTime Time);

class UWorkshopComponent : UActorComponent
{
	UPROPERTY()
	UDataTable MultiplierTable;

	UPROPERTY()
	TArray<FWorkshopProduct> Products;

	TMap<UItem, FWorkshopProduct> HashMap; // for easier lookup

	UPROPERTY(Category = "Events")
	FOnHarbourDeliveryCompleted HarbourDeliveryCompleted;

    UPROPERTY(Category = "Events")
    FOnHarbourReset HarbourReset;

    int ElapsedSeconds;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto& Product : Products)
		{
			HashMap.Add(Product.Item, Product); // makes it easier to find entries
		}

		FDateTime Now = FDateTime::Now();
		ElapsedSeconds = Now.Hour * 3600 + Now.Minute * 60 + Now.Second;

		System::SetTimer(this, n"Delay", 1.0f, false); // testing
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        if (ElapsedSeconds % 3600 == 0)
        {
            Print(f"Whole Hour");
            HarbourReset.Broadcast(FDateTime::Now());
        }
	}

	UFUNCTION()
	void Delay()
	{
		Deliver(Products[0].Item, 1);
	}

	UFUNCTION(Category = "Harbour", DisplayName = "Get Product Multiplier")
	float BP_GetMultiplier(FWorkshopProduct Product)
	{
		return GetMultiplier(Product);
	}

	float GetMultiplier(FWorkshopProduct Product)
	{
		return GetMultiplier(Product.Popularity, Product.Supply);
	}

	float GetMultiplier(EProductPopularity Popularity, EProductSupply Supply)
	{
		if (!IsValid(MultiplierTable))
			return -1.0f;

		FName RowName = FName(f"{Popularity:n}");
		FProductSupplyAndDemandRow Row;
		MultiplierTable.FindRow(RowName, Row);

		switch (Supply)
		{
			case EProductSupply::Nonexistent:
				return Row.Nonexistent;
			case EProductSupply::Insufficient:
				return Row.Insufficient;
			case EProductSupply::Sufficient:
				return Row.Sufficient;
			case EProductSupply::Surplus:
				return Row.Surplus;
			case EProductSupply::Overflowing:
				return Row.Overflowing;
		}
	}

	UFUNCTION()
	void Deliver(UItem Item, int Quantity)
	{
		FWorkshopProduct Product;
		HashMap.Find(Item, Product); // returns copy

		auto FishItem = Item.AsFishItem();
		float Value = FishItem.VendorValue * GetMultiplier(Product);

		for (int i = 0; i < Quantity; i++)
		{
			HarbourDeliveryCompleted.Broadcast(Product, Value);
		}
	}
};

struct FWorkshopProduct
{
	UPROPERTY()
	UItem Item;

	UPROPERTY()
	EProductPopularity Popularity;

	UPROPERTY()
	EProductSupply Supply;
}

struct FProductSupplyAndDemandRow
{
	UPROPERTY(Meta = (Units = "x"))
	float Nonexistent;

	UPROPERTY(Meta = (Units = "x"))
	float Insufficient;

	UPROPERTY(Meta = (Units = "x"))
	float Sufficient;

	UPROPERTY(Meta = (Units = "x"))
	float Surplus;

	UPROPERTY(Meta = (Units = "x"))
	float Overflowing;
}

enum EProductPopularity
{
	/**
	 * +40%
	 */
	VeryHigh,
	/**
	 * +20%
	 */
	High,
	/**
	 * +0%
	 */
	Average,
	/**
	 * -20%
	 */
	Low,
}

enum EProductSupply
{
	/**
	 * +60%
	 */
	Nonexistent,
	/**
	 * +30%
	 */
	Insufficient,
	/**
	 * +0%
	 */
	Sufficient,
	/**
	 * -20%
	 */
	Surplus,
	/**
	 * -40%
	 */
	Overflowing
}