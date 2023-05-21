global function webhookevents_Init

string whe_chat_prefix = "\x1b[38;5;81m[WEBHOOKEVENTS]\x1b[0m "
int matchId 

void function webhookevents_Init() {
    print("[WEBHOOKEVENTS][INFO] Webhooks initialization started...")
    matchId = RandomInt(2000000000)

    AddCallback_OnPlayerKilled(webhookevents_onplayerkilled)
    AddCallback_OnClientConnecting(webhookevents_onplayerconnecting)
    AddCallback_OnClientConnected(webhookevents_onplayerconnected)
    AddCallback_OnClientDisconnected(webhookevents_onplayerdisconnected)
    AddCallback_GameStateEnter(eGameState.Playing, webhookevents_gamestate_playing)
    AddCallback_GameStateEnter(eGameState.Postmatch, webhookevents_gamestate_postmatch)

    webhookevents_modinitcomplete()
    print("[WEBHOOKEVENTS][INFO] Webhooks initialization complete!")
}

void function webhookevents_onplayerkilled(entity victim, entity attacker, var damageInfo){
    if ( !victim.IsPlayer())
        return

    if(attacker.IsPlayer()) {
        if(attacker.GetPlayerName() == victim.GetPlayerName()) {	// suicide check
            webhookevents_sendwebhook("Player Commited Suicide", "Player: **" + victim.GetPlayerName() + "**", 16721930);
        }
        else {	// if not suicide and killed by another player
            webhookevents_sendwebhook("Player Killed by another Player", "Player: **" + victim.GetPlayerName() + "** \n" + "Attacker: **" + attacker.GetPlayerName() + "** \n" , 16721930)
        }
    }
    else {	// killed by not player
        webhookevents_sendwebhook("Player Killed by entity", "Player: **" + victim.GetPlayerName() + "** \n", 16721930);
    }
}

void function webhookevents_onplayerconnecting(entity player) {
    webhookevents_sendjoinmessage(player)
    webhookevents_sendwebhook("Player connection start", "Player: **" + player.GetPlayerName() + "** \n", 7143270);
}

void function webhookevents_onplayerconnected(entity player) {
    webhookevents_sendjoinmessage(player)
    webhookevents_sendwebhook("Player connected", "Player: **" + player.GetPlayerName() + "** \n", 65351);
}

void function webhookevents_onplayerdisconnected(entity player) {
    webhookevents_sendwebhook("Player disconnected", "Player: **" + player.GetPlayerName() + "** \n", 286976);
}

void function webhookevents_gamestate_playing() {
    webhookevents_sendwebhook("Match started", "Total Players: **" + format("%d", GetPlayerArray().len()) + "** \n" + "Map: **" + webhookevents_getmapname() + "** \n", 6723583);
}

void function webhookevents_gamestate_postmatch() {
    webhookevents_sendwebhook("Match ended", "Total Players: **" + format("%d", GetPlayerArray().len()) + "** \n" + "Map: **" + webhookevents_getmapname() + "** \n", 1992055);
}

void function webhookevents_modinitcomplete() {
    webhookevents_sendwebhook("Server started", "MatchID: **" + matchId + "** \n", 65525) 
}


void function webhookevents_sendwebhook(string title, string description, var color){
    table payload = {}
    table embedFirst = {}
    table footer = {}

    footer["text"] <- "MatchID: " + matchId + " | " + "Players: " + format("%d", GetPlayerArray().len()) + ""

    embedFirst["title"] <- title
    embedFirst["description"] <- description
    embedFirst["color"] <- color
    embedFirst["footer"] <- footer

    payload["content"] <- null
    payload["embeds"] <- [embedFirst]
    payload["attachments"] <- []

    HttpRequest request
    request.method = HttpRequestMethod.POST
    request.url = GetConVarString("webhook_url")
    request.body = EncodeJSON(payload)

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        if(response.statusCode == 200 || response.statusCode == 201){
            print("[Tone API] Webhook sent!")
        }else{
            print("[WEBHOOKEVENTS][WARN] Couldn't send kill data")
            print("[WEBHOOKEVENTS][WARN] " + response.body )
        }
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("[WEBHOOKEVENTS][WARN]  Couldn't send Webhook")
        print("[WEBHOOKEVENTS][WARN] " + failure.errorMessage )
    }

    NSHttpRequest(request, onSuccess, onFailure)
}

void function webhookevents_sendjoinmessage(entity player) {
    Chat_ServerPrivateMessage(player, whe_chat_prefix + "This server collects data using the WEBHOOKEVENTS and sending it directly to discord server. Events are publicly available in discord server: \x1b[38;5;81m" + GetConVarString("webhook_discord_server_url") + "\x1b[0m . MatchId: " + matchId, false, false)
}

string function webhookevents_getmapname() {
    return GetMapName()
}
