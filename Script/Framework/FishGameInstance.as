enum EFindSessionResult
{
    Success,
    NotFound,
    UnknownError
};

event void FOnFindSessionsStart();
event void FOnFindSessionsComplete(EFindSessionResult Result);

class UFishGameInstance : UAdvancedFriendsGameInstance
{   
    UPROPERTY()
    FOnFindSessionsStart OnFindSessionsStart;

    UPROPERTY()
    FOnFindSessionsComplete OnFindSessionsComplete;
};