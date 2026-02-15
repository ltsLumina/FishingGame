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
