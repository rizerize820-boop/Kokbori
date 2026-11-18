/*
 * KOKBORI RP - PAWN server-side starter
 * Target: SA-MP/open.mp Pawn gamemode.
 *
 * This file deliberately uses only standard SA-MP natives.
 * It is NOT a Unity gateway and does not magically accept Unity TCP.
 * Compile with the matching server includes and integrate into your
 * existing gamemode after backing it up.
 */

#include <a_samp>

#define KOKBORI_SERVER_NAME "KOKBORI RP | Astana"
#define KOKBORI_DEFAULT_MONEY (5000)
#define KOKBORI_SPAWN_X (1464.0)
#define KOKBORI_SPAWN_Y (-1010.0)
#define KOKBORI_SPAWN_Z (26.8)
#define KOKBORI_SPAWN_A (90.0)

new PlayerMoney[MAX_PLAYERS];
new bool:PlayerLoggedIn[MAX_PLAYERS];

public OnGameModeInit()
{
    SetGameModeText("KOKBORI RP | Astana");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(true);
    SetWorldTime(12);
    SetWeather(10);
    UsePlayerPedAnims();
    AddPlayerClass(0, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z,
        KOKBORI_SPAWN_A, 0, 0, 0, 0, 0, 0);
    print("[KOKBORI] Pawn gamemode starter loaded.");
    print("[KOKBORI] Unity networking requires a separately implemented adapter.");
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerLoggedIn[playerid] = false;
    PlayerMoney[playerid] = KOKBORI_DEFAULT_MONEY;
    SendClientMessage(playerid, 0x65C9FFFF,
        "Добро пожаловать на KOKBORI RP | Astana!");
    SendClientMessage(playerid, 0xFFFFFFFF,
        "Тестовый режим: аккаунт и сохранение пока не подключены.");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    PlayerLoggedIn[playerid] = false;
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z);
    SetPlayerFacingAngle(playerid, KOKBORI_SPAWN_A);
    SetPlayerCameraBehindPlayer(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerPos(playerid, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z);
    SetPlayerFacingAngle(playerid, KOKBORI_SPAWN_A);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, 0x65C9FFFF,
            "KOKBORI: /help /stats /id /veh");
        return 1;
    }
    if (!strcmp(cmdtext, "/stats", true))
    {
        new msg[96];
        format(msg, sizeof msg, "Тестовый баланс: %d KZT", PlayerMoney[playerid]);
        SendClientMessage(playerid, 0xFFFFFFFF, msg);
        return 1;
    }
    if (!strcmp(cmdtext, "/id", true))
    {
        new msg[64];
        format(msg, sizeof msg, "Твой игровой ID: %d", playerid);
        SendClientMessage(playerid, 0xFFFFFFFF, msg);
        return 1;
    }
    if (!strcmp(cmdtext, "/veh", true))
    {
        SendClientMessage(playerid, 0xFFCC66FF,
            "Спавн транспорта добавим после согласования моделей и системы гаража.");
        return 1;
    }
    return 0;
}
