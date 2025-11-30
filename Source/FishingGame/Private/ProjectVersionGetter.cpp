#include "ProjectVersionGetter.h"
#include "Misc/ConfigCacheIni.h"

FString UProjectVersionGetter::GetGameVersion()
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
