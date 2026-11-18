/*
 * KOKBORI RP - Pawn gamemode with SQLite registration/login.
 * Target: SA-MP 0.3.7 / open.mp compatibility layer.
 *
 * Accounts are stored in scriptfiles/kokbori_accounts.db.
 * Passwords are SHA-256 hashed with the account name as salt.
 * This is a starter authentication system, not a production security audit.
 * Unity networking still requires a separately implemented gateway/adapter.
 */

#include <a_samp>

#define KOKBORI_SERVER_NAME "KOKBORI RP | Astana"
#define KOKBORI_DEFAULT_MONEY (5000)
#define KOKBORI_SPAWN_X (1464.0)
#define KOKBORI_SPAWN_Y (-1010.0)
#define KOKBORI_SPAWN_Z (26.8)
#define KOKBORI_SPAWN_A (90.0)

#define DIALOG_REGISTER (1000)
#define DIALOG_LOGIN (1001)

new DB:gDatabase;
new PlayerMoney[MAX_PLAYERS];
new bool:PlayerLoggedIn[MAX_PLAYERS];
new PlayerAccountName[MAX_PLAYERS][MAX_PLAYER_NAME + 1];

forward KickPlayerLater(playerid);

public OnGameModeInit()
{
    SetGameModeText(KOKBORI_SERVER_NAME);
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(true);
    SetWorldTime(12);
    SetWeather(10);
    UsePlayerPedAnims();

    AddPlayerClass(0, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z,
        KOKBORI_SPAWN_A, 0, 0, 0, 0, 0, 0);

    gDatabase = db_open("kokbori_accounts.db");
    if (gDatabase == DB:0)
    {
        print("[KOKBORI] ERROR: Could not open SQLite database.");
        return 0;
    }

    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS accounts ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "password_hash TEXT NOT NULL,"
        "money INTEGER NOT NULL DEFAULT 5000"
        ");");

    print("[KOKBORI] Gamemode and SQLite account database loaded.");
    print("[KOKBORI] Unity networking requires a separate gateway adapter.");
    return 1;
}

public OnGameModeExit()
{
    if (gDatabase != DB:0)
    {
        db_close(gDatabase);
        gDatabase = DB:0;
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerLoggedIn[playerid] = false;
    PlayerMoney[playerid] = KOKBORI_DEFAULT_MONEY;

    GetPlayerName(playerid, PlayerAccountName[playerid],
        MAX_PLAYER_NAME + 1);

    TogglePlayerSpectating(playerid, true);

    if (gDatabase == DB:0)
    {
        SendClientMessage(playerid, 0xFF5555FF,
            "Ошибка базы данных. Попробуй зайти позже.");
        SetTimerEx("KickPlayerLater", 500, false, "i", playerid);
        return 1;
    }

    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);

    new query[160];
    format(query, sizeof query,
        "SELECT id FROM accounts WHERE name='%s' LIMIT 1;", safeName);

    new DBResult:result = db_query(gDatabase, query);
    if (result == DBResult:0)
    {
        SendClientMessage(playerid, 0xFF5555FF,
            "Не удалось проверить аккаунт. Обратись к администрации.");
        SetTimerEx("KickPlayerLater", 500, false, "i", playerid);
        return 1;
    }

    if (db_num_rows(result) > 0)
    {
        db_free_result(result);
        ShowLoginDialog(playerid);
    }
    else
    {
        db_free_result(result);
        ShowRegisterDialog(playerid);
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (PlayerLoggedIn[playerid] && gDatabase != DB:0)
    {
        new safeName[(MAX_PLAYER_NAME * 2) + 1];
        EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);

        new query[192];
        format(query, sizeof query,
            "UPDATE accounts SET money=%d WHERE name='%s';",
            PlayerMoney[playerid], safeName);

        new DBResult:result = db_query(gDatabase, query);
        if (result != DBResult:0) db_free_result(result);
    }

    PlayerLoggedIn[playerid] = false;
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if (!PlayerLoggedIn[playerid])
    {
        TogglePlayerSpectating(playerid, true);
        return 1;
    }

    SetPlayerPos(playerid, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z);
    SetPlayerFacingAngle(playerid, KOKBORI_SPAWN_A);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_REGISTER)
    {
        if (!response)
        {
            ShowRegisterDialog(playerid);
            return 1;
        }

        if (strlen(inputtext) < 6 || strlen(inputtext) > 32)
        {
            SendClientMessage(playerid, 0xFFCC66FF,
                "Пароль должен содержать от 6 до 32 символов.");
            ShowRegisterDialog(playerid);
            return 1;
        }

        new hash[65];
        SHA256_PassHash(inputtext, PlayerAccountName[playerid], hash, sizeof hash);

        new safeName[(MAX_PLAYER_NAME * 2) + 1];
        EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);

        new query[256];
        format(query, sizeof query,
            "INSERT INTO accounts (name, password_hash, money) "
            "VALUES ('%s', '%s', %d);",
            safeName, hash, KOKBORI_DEFAULT_MONEY);

        new DBResult:result = db_query(gDatabase, query);
        if (result == DBResult:0)
        {
            SendClientMessage(playerid, 0xFF5555FF,
                "Не удалось создать аккаунт. Попробуй ещё раз.");
            ShowRegisterDialog(playerid);
            return 1;
        }
        db_free_result(result);

        PlayerMoney[playerid] = KOKBORI_DEFAULT_MONEY;
        CompleteLogin(playerid);
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (!response)
        {
            ShowLoginDialog(playerid);
            return 1;
        }

        if (strlen(inputtext) < 1 || strlen(inputtext) > 32)
        {
            SendClientMessage(playerid, 0xFFCC66FF,
                "Введи пароль от своего аккаунта.");
            ShowLoginDialog(playerid);
            return 1;
        }

        new hash[65];
        SHA256_PassHash(inputtext, PlayerAccountName[playerid], hash, sizeof hash);

        new safeName[(MAX_PLAYER_NAME * 2) + 1];
        EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);

        new query[192];
        format(query, sizeof query,
            "SELECT password_hash, money FROM accounts "
            "WHERE name='%s' LIMIT 1;", safeName);

        new DBResult:result = db_query(gDatabase, query);
        if (result == DBResult:0 || db_num_rows(result) == 0)
        {
            if (result != DBResult:0) db_free_result(result);
            SendClientMessage(playerid, 0xFF5555FF,
                "Аккаунт не найден. Переподключись и зарегистрируйся.");
            SetTimerEx("KickPlayerLater", 500, false, "i", playerid);
            return 1;
        }

        new storedHash[65];
        db_get_field_assoc(result, "password_hash", storedHash, sizeof storedHash);
        PlayerMoney[playerid] = db_get_field_assoc_int(result, "money");
        db_free_result(result);

        if (strcmp(hash, storedHash, true) != 0)
        {
            SendClientMessage(playerid, 0xFF5555FF,
                "Неверный пароль. Попробуй ещё раз.");
            ShowLoginDialog(playerid);
            return 1;
        }

        CompleteLogin(playerid);
        return 1;
    }
    return 0;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!PlayerLoggedIn[playerid])
    {
        SendClientMessage(playerid, 0xFF5555FF,
            "Сначала войди в аккаунт.");
        return 1;
    }

    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, 0x65C9FFFF,
            "KOKBORI: /help /stats /id /veh");
        return 1;
    }

    if (!strcmp(cmdtext, "/stats", true))
    {
        new msg[96];
        format(msg, sizeof msg, "Твой баланс: %d KZT", PlayerMoney[playerid]);
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
            "Систему транспорта добавим следующим этапом.");
        return 1;
    }
    return 0;
}

stock ShowRegisterDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
        "KOKBORI RP | Регистрация",
        "Аккаунт с таким ником не найден.\nПридумай пароль (6-32 символа):",
        "Создать", "Повторить");
    return 1;
}

stock ShowLoginDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
        "KOKBORI RP | Авторизация",
        "Аккаунт найден.\nВведи пароль:",
        "Войти", "Повторить");
    return 1;
}

stock CompleteLogin(playerid)
{
    PlayerLoggedIn[playerid] = true;
    SendClientMessage(playerid, 0x65C9FFFF,
        "Ты успешно вошёл на KOKBORI RP | Astana.");
    SendClientMessage(playerid, 0xFFFFFFFF,
        "Используй /help, чтобы посмотреть доступные команды.");

    TogglePlayerSpectating(playerid, false);
    SetSpawnInfo(playerid, 0, 0, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y,
        KOKBORI_SPAWN_Z, KOKBORI_SPAWN_A, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    return 1;
}

stock EscapeSQL(const source[], destination[], destinationSize)
{
    new sourceIndex, destIndex;
    while (source[sourceIndex] != '\0' && destIndex < destinationSize - 2)
    {
        if (source[sourceIndex] == '\'')
        {
            destination[destIndex++] = '\'';
            destination[destIndex++] = '\'';
        }
        else
        {
            destination[destIndex++] = source[sourceIndex];
        }
        sourceIndex++;
    }
    destination[destIndex] = '\0';
    return 1;
}

public KickPlayerLater(playerid)
{
    if (IsPlayerConnected(playerid)) Kick(playerid);
    return 1;
}
