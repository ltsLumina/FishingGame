event void FOnChatModeChanged(EChatMode ChatMode);

class UChatComponent : UActorComponent
{
	UPROPERTY(Category = "Chat", VisibleAnywhere, BlueprintReadOnly)
	EChatMode ChatMode;

	UPROPERTY(Category = "Chat", EditDefaultsOnly, EditInline)
	TArray<UChatCommand> ChatCommands;

	UPROPERTY(Category = "Events")
	FOnChatModeChanged ChatModeChanged;

	/**
	 * @param Formatted The formatted string including the player's name, using RichText.
	 * @param PlayerName .
	 * @param Message The raw message provided by the editable text field.
	 */
	UFUNCTION(Server)
	void Server_SendChat(FText Formatted, FText PlayerName, FText Message, EChatMode InChatMode)
	{
		// try invoke chat commands
		if (Message.ToString().StartsWith("/"))
		{
			FName CommandName = FName(Message.ToString());

			for (auto CMD : ChatCommands)
			{
				if (CMD.Command.IsEqual(CommandName) || CMD.Aliases.Contains(CMD.Command))
				{
					InvokeChatCommand(CMD, CommandName);
					return;
				}
			}

			throw("Failed to parse command!");
		}

		bool IsAFriend = false;
		FBPUniqueNetId NetID;

        auto SenderPC = Cast<APlayerController>(GetOwner());
        auto SenderPawn = IsValid(SenderPC) ? SenderPC.ControlledPawn : nullptr;
        auto SenderPS = IsValid(SenderPC) ? SenderPC.PlayerState : nullptr;

        auto GameState = Gameplay::GetGameState();
        for (auto PS : GameState.PlayerArray)
        {
            auto ChatComp = PS.Get().GetPlayerController().GetComponentByClass(UChatComponent);
            switch (InChatMode)
            {
                case EChatMode::Say:
                {
                    if (SenderPawn != nullptr && PS.Get() != SenderPS)
                    {
                        if (PS.Get().Pawn.GetDistanceTo(SenderPawn) >= 500.0f)
                        {
                            Print(f"too far for say chat");
                            continue;
                        }
                    }
                    ChatComp.Client_SendChat(Formatted);
                    break;
                }

                case EChatMode::Shout:
                    ChatComp.Client_SendChat(Formatted);
                    break;

                case EChatMode::FriendsOnly:
                    if (!AdvancedSessions::HasOnlineSubsystem(n"STEAM") && !IsEditor())
                    {
                        continue;
                    }

                    AdvancedSessions::GetUniqueNetIDFromPlayerState(PS.Get(), NetID);
                    AdvancedFriends::IsAFriend(PS.Get().PlayerController, NetID, IsAFriend);
                    if (!IsAFriend)
                    {
						ChatComp.Client_SendChat(Formatted);
                        Print(f"User is not a friend!");
                        continue;
                    }
                    break;
            }
        }
	}

	/**
	 * Called on the owning client by the server.
	 */
	UFUNCTION(Client, BlueprintEvent)
	void Client_SendChat(FText Message)
	{
		throw("Override this event in Blueprints!");
	}

	UFUNCTION()
	void SetChatMode(EChatMode NewChatMode)
	{
		ChatMode = NewChatMode;
		ChatModeChanged.Broadcast(ChatMode);
	}

	void InvokeChatCommand(UChatCommand Command, FName CommandName)
	{
		Command.ExecuteCommand(this, CommandName);
	}
};

UCLASS(Abstract, EditInlineNew, DefaultToInstanced)
class UChatCommand : UObject
{
	UPROPERTY(Category = "Command")
	FName Command;

	UPROPERTY(Category = "Command")
	TArray<FName> Aliases;

	UFUNCTION(BlueprintEvent)
	bool ExecuteCommand(UChatComponent ChatComponent, FName CommandName)
	{
		if (!Command.ToString().StartsWith("/"))
		{
			throw(f"Command (\"{GetFullName()}\") does not start with a forward slash!");
		}

		return false;
	}
}

enum EChatMode
{
	Say,
	Shout,
	FriendsOnly
}