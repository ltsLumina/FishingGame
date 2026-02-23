#include "ProjectFunctionLibrary.h"
#include "Misc/ConfigCacheIni.h"

FString UProjectFunctionLibrary::GetGameVersion()
{
	FString Version;

	if (!GConfig)
	{
		return "";
	}

	GConfig->GetString(
		TEXT("/Script/EngineSettings.GeneralProjectSettings"),
		TEXT("ProjectVersion"),
		Version,
		GGameIni
	);

	return Version;
}

void UProjectFunctionLibrary::SetGameVersion(const FString& NewVersion)
{
	if (!GConfig)
	{
		return;
	}

	// Write the new version string into the project settings and flush the config to disk
	GConfig->SetString(
		TEXT("/Script/EngineSettings.GeneralProjectSettings"),
		TEXT("ProjectVersion"),
		*NewVersion,
		GGameIni
	);

	GConfig->Flush(false, GGameIni);
}

void UProjectFunctionLibrary::UpgradeVersion(const EVersionUpgrade VersionUpgrade)
{
	auto Version = GetGameVersion();

	// If version is empty, start with a default
	if (Version.IsEmpty())
	{
		Version = TEXT("0.0.0");
	}

	// Split into numeric parts
	TArray<FString> Parts;
	Version.ParseIntoArray(Parts, TEXT("."), true);

	// Ensure we have at least 3 parts (major.minor.patch)
	while (Parts.Num() < 3)
	{
		Parts.Add(TEXT("0"));
	}

	// Convert to ints (non-numeric entries will become 0)
	TArray<int32> Numbers;
	Numbers.Reserve(Parts.Num());
	for (const FString& P : Parts)
	{
		Numbers.Add(FCString::Atoi(*P));
	}

	switch (VersionUpgrade)
	{
	case Patch:
		// Increment patch
		Numbers[2] += 1;
		break;

	case Minor:
		// Increment minor, reset patch
		Numbers[1] += 1;
		Numbers[2] = 0;
		break;

	case Major:
		// Increment major, reset minor and patch
		Numbers[0] += 1;
		Numbers[1] = 0;
		Numbers[2] = 0;
		break;

	default:
		break;
	}

	// Rebuild version string (keep only major.minor.patch)
	FString NewVersion = FString::Printf(TEXT("%d.%d.%d"), Numbers[0], Numbers[1], Numbers[2]);

	SetGameVersion(NewVersion);
}
