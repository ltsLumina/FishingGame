class UChatComponent : UActorComponent
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        System::SetTimer(this, n"SendChat", 5, false);
    }

    UFUNCTION()
    void SendChat()
    {
        
    }

    UFUNCTION(Server)
    void Server_SendChat()
    {
        
    }

    UFUNCTION(NetMulticast)
    void Multicast_SendChat()
    {
        
    }

    UFUNCTION(Client)
    void Client_SendChat()
    {

    }
};