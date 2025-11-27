enum EHostSessionResult
{
    Success,
    Failed,
};

enum EFindSessionResult
{
    Success,
    NotFound,
    Failed,
};

event void FOnHostSession(EHostSessionResult Result);
event void FOnFindSessionsStart();
event void FOnFindSessionsComplete(EFindSessionResult Result);

class UFishGameInstance : UAdvancedFriendsGameInstance
{   
    UPROPERTY(Category = "Events | Sessions")
    FOnHostSession OnHostSession;

    UPROPERTY(Category = "Events | Sessions")
    FOnFindSessionsStart OnFindSessionsStart;

    UPROPERTY(Category = "Events | Sessions")
    FOnFindSessionsComplete OnFindSessionsComplete;
};