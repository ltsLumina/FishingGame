class UStatsComponent : UFishComponent
{
    UPROPERTY(Category = "Stats")
    FStats Stats;

    UPROPERTY(Category = "Stats")
	int Gil;

    UFUNCTION(Category = "Gil")
	void GainGil(int Amount)
	{
		Gil += Math::Max(0, Amount);
	}

    UFUNCTION(Category = "Gil")
    bool SpendGil(int Amount)
    {
        if (Gil >= Amount)
        {
            Gil -= Amount;
            return true;
        }
        return false;
    }
};

struct FStats
{
	UPROPERTY(Category = "Stats", Replicated, DisplayName = "Gathering Points")
	int Gathering = 100;
}