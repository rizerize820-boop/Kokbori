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
#define DIALOG_JOB (1002)
#define DIALOG_CHAR_NAME (1003)
#define DIALOG_CHAR_AGE (1004)
#define DIALOG_CHAR_GENDER (1005)
#define DIALOG_BANK (1006)
#define DIALOG_BANK_AMOUNT (1007)
#define DIALOG_BANK_TRANSFER (1008)
#define JOB_NONE (0)
#define VEHICLE_PRICE (15000)
#define VEHICLE_MODEL_PLACEHOLDER (400)
#define VEHICLE_REFUND (7500)
#define INVENTORY_SLOTS (20)
#define HOUSE_PRICE (250000)
#define BUSINESS_PRICE (500000)
#define BUSINESS_PAYOUT (2500)
#define BUSINESS_COOLDOWN (1800)
#define FACTION_NONE (0)
#define FACTION_POLICE (1)
#define FACTION_MEDIC (2)
#define FACTION_GOVERNMENT (3)

new DB:gDatabase;
new PlayerMoney[MAX_PLAYERS];
new PlayerBankMoney[MAX_PLAYERS];
new BankAction[MAX_PLAYERS];
new bool:PlayerLoggedIn[MAX_PLAYERS];
new PlayerAccountName[MAX_PLAYERS][MAX_PLAYER_NAME + 1];
new PlayerJob[MAX_PLAYERS];
new PlayerLastWork[MAX_PLAYERS];
new PlayerFirstName[MAX_PLAYERS][25];
new PlayerLastName[MAX_PLAYERS][25];
new PlayerAge[MAX_PLAYERS];
new PlayerGender[MAX_PLAYERS];
new PlayerSkin[MAX_PLAYERS];
new VehicleOwner[MAX_VEHICLES + 1][MAX_PLAYER_NAME + 1];
new PlayerAdminLevel[MAX_PLAYERS];
new PlayerItemCount[MAX_PLAYERS][6];
new PlayerHouseOwned[MAX_PLAYERS];
new PlayerBusinessOwned[MAX_PLAYERS];
new PlayerBusinessLastCollect[MAX_PLAYERS];
new PlayerFaction[MAX_PLAYERS];
new PlayerFactionRank[MAX_PLAYERS];
new bool:PlayerOnDuty[MAX_PLAYERS];
new bool:PlayerHasSavedPosition[MAX_PLAYERS];
new Float:PlayerSavedX[MAX_PLAYERS];
new Float:PlayerSavedY[MAX_PLAYERS];
new Float:PlayerSavedZ[MAX_PLAYERS];
new Float:PlayerSavedAngle[MAX_PLAYERS];
new PlayerSavedInterior[MAX_PLAYERS];
new PlayerSavedWorld[MAX_PLAYERS];
#define MAX_WORLD_ITEM_PICKUPS (100)
new WorldItemPickup[MAX_WORLD_ITEM_PICKUPS];
new WorldItemType[MAX_WORLD_ITEM_PICKUPS];
new WorldItemAmount[MAX_WORLD_ITEM_PICKUPS];

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
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS player_jobs ("
        "name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "job_id INTEGER NOT NULL DEFAULT 0"
        ");");
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS characters ("
        "account_name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "first_name TEXT NOT NULL,"
        "last_name TEXT NOT NULL,"
        "age INTEGER NOT NULL,"
        "gender INTEGER NOT NULL,"
        "skin INTEGER NOT NULL"
        ");");
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS bank_accounts ("
        "account_name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "balance INTEGER NOT NULL DEFAULT 0"
        ");");
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS bank_transactions ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "account_name TEXT NOT NULL COLLATE NOCASE,"
        "action TEXT NOT NULL,"
        "amount INTEGER NOT NULL,"
        "other_account TEXT NOT NULL DEFAULT '',"
        "created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP"
        ");");
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS owned_vehicles ("
        "account_name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "modelid INTEGER NOT NULL,"
        "color1 INTEGER NOT NULL DEFAULT 1,"
        "color2 INTEGER NOT NULL DEFAULT 1,"
        "x REAL NOT NULL,"
        "y REAL NOT NULL,"
        "z REAL NOT NULL,"
        "angle REAL NOT NULL"
        ");");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS player_inventory (account_name TEXT NOT NULL COLLATE NOCASE, item_id INTEGER NOT NULL, amount INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(account_name,item_id));");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS player_houses (account_name TEXT NOT NULL COLLATE NOCASE UNIQUE, price INTEGER NOT NULL, x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL, angle REAL NOT NULL);");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS player_businesses (account_name TEXT NOT NULL COLLATE NOCASE UNIQUE, price INTEGER NOT NULL, last_collect INTEGER NOT NULL DEFAULT 0);");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS admin_accounts (account_name TEXT NOT NULL COLLATE NOCASE UNIQUE, level INTEGER NOT NULL DEFAULT 0);");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS admin_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, admin_name TEXT NOT NULL, action TEXT NOT NULL, target_name TEXT NOT NULL DEFAULT '', details TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS player_factions (account_name TEXT NOT NULL COLLATE NOCASE UNIQUE, faction_id INTEGER NOT NULL, faction_rank INTEGER NOT NULL DEFAULT 1);");
    db_query(gDatabase, "CREATE TABLE IF NOT EXISTS player_positions (account_name TEXT NOT NULL COLLATE NOCASE UNIQUE, x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL, angle REAL NOT NULL, interior INTEGER NOT NULL DEFAULT 0, world INTEGER NOT NULL DEFAULT 0);");
    LoadOwnedVehicles();
    db_query(gDatabase,
        "CREATE TABLE IF NOT EXISTS player_work ("
        "account_name TEXT NOT NULL COLLATE NOCASE UNIQUE,"
        "last_work INTEGER NOT NULL DEFAULT 0"
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
    PlayerBankMoney[playerid] = 0;
    BankAction[playerid] = 0;
    PlayerJob[playerid] = 0;
    PlayerLastWork[playerid] = 0;
    PlayerAdminLevel[playerid] = 0;
    PlayerHouseOwned[playerid] = 0;
    PlayerBusinessOwned[playerid] = 0;
    PlayerBusinessLastCollect[playerid] = 0;
    PlayerFaction[playerid] = FACTION_NONE;
    PlayerFactionRank[playerid] = 0;
    PlayerOnDuty[playerid] = false;
    PlayerHasSavedPosition[playerid] = false;
    PlayerSavedX[playerid] = KOKBORI_SPAWN_X;
    PlayerSavedY[playerid] = KOKBORI_SPAWN_Y;
    PlayerSavedZ[playerid] = KOKBORI_SPAWN_Z;
    PlayerSavedAngle[playerid] = KOKBORI_SPAWN_A;
    PlayerSavedInterior[playerid] = 0;
    PlayerSavedWorld[playerid] = 0;
    for (new item = 0; item < 6; item++) PlayerItemCount[playerid][item] = 0;
    PlayerFirstName[playerid][0] = '\0';
    PlayerLastName[playerid][0] = '\0';
    PlayerAge[playerid] = 18;
    PlayerGender[playerid] = 0;
    PlayerSkin[playerid] = 0;

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
        SaveBankBalance(playerid);
        SavePlayerPosition(playerid);
        new ownedVehicle = FindPlayerVehicle(playerid);
        if (ownedVehicle != 0) SaveOwnedVehicle(ownedVehicle);
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


public OnPlayerPickUpPickup(playerid, pickupid)
{
    if (!PlayerLoggedIn[playerid]) return 1;
    for (new slot = 0; slot < MAX_WORLD_ITEM_PICKUPS; slot++)
    {
        if (WorldItemPickup[slot] == pickupid && WorldItemType[slot] != 0)
        {
            new itemid = WorldItemType[slot];
            new amount = WorldItemAmount[slot];
            new total = 0;
            for (new i = 1; i <= 5; i++) total += PlayerItemCount[playerid][i];
            if (total + amount > INVENTORY_SLOTS)
            {
                SendClientMessage(playerid, 0xFFCC66FF, "Недостаточно места в инвентаре. Освободи слот и попробуй снова.");
                return 1;
            }
            DestroyPickup(pickupid);
            WorldItemPickup[slot] = 0;
            WorldItemType[slot] = 0;
            WorldItemAmount[slot] = 0;
            PlayerItemCount[playerid][itemid] += amount;
            SaveInventoryItem(playerid, itemid);
            SendClientMessage(playerid, 0x65C9FFFF, "Предмет подобран и сохранён в инвентаре. /inv");
            return 1;
        }
    }
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

    SetPlayerSkin(playerid, PlayerSkin[playerid]);
    if (PlayerHasSavedPosition[playerid])
    {
        SetPlayerInterior(playerid, PlayerSavedInterior[playerid]);
        SetPlayerVirtualWorld(playerid, PlayerSavedWorld[playerid]);
        SetPlayerPos(playerid, PlayerSavedX[playerid], PlayerSavedY[playerid], PlayerSavedZ[playerid]);
        SetPlayerFacingAngle(playerid, PlayerSavedAngle[playerid]);
        PlayerHasSavedPosition[playerid] = false;
    }
    else
    {
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerPos(playerid, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z);
        SetPlayerFacingAngle(playerid, KOKBORI_SPAWN_A);
    }
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_BANK)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            new bankMsg[112];
            format(bankMsg, sizeof bankMsg, "Наличные: %d KZT | На счёте: %d KZT", PlayerMoney[playerid], PlayerBankMoney[playerid]);
            SendClientMessage(playerid, 0x65C9FFFF, bankMsg);
        }
        else if (listitem == 1 || listitem == 2)
        {
            BankAction[playerid] = (listitem == 1) ? 1 : 2;
            ShowPlayerDialog(playerid, DIALOG_BANK_AMOUNT, DIALOG_STYLE_INPUT,
                (listitem == 1) ? "KOKBORI BANK | Пополнение" : "KOKBORI BANK | Снятие",
                "Введи сумму в KZT (от 1 до 100000000):", "Подтвердить", "Назад");
        }
        else if (listitem == 3)
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER, DIALOG_STYLE_INPUT,
                "KOKBORI BANK | Перевод",
                "Введи ID игрока и сумму через пробел. Пример: 4 1500",
                "Перевести", "Назад");
        }
        else if (listitem == 4)
        {
            ShowBankHistory(playerid);
        }
        return 1;
    }

    if (dialogid == DIALOG_BANK_AMOUNT)
    {
        if (!response) { ShowBankDialog(playerid); return 1; }
        if (!IsNumericString(inputtext) || strval(inputtext) < 1 || strval(inputtext) > 100000000)
        {
            SendClientMessage(playerid, 0xFFCC66FF, "Сумма должна быть числом от 1 до 100000000 KZT.");
            ShowPlayerDialog(playerid, DIALOG_BANK_AMOUNT, DIALOG_STYLE_INPUT,
                (BankAction[playerid] == 1) ? "KOKBORI BANK | Пополнение" : "KOKBORI BANK | Снятие",
                "Введи сумму в KZT (от 1 до 100000000):", "Подтвердить", "Назад");
            return 1;
        }
        new amount = strval(inputtext);
        if (BankAction[playerid] == 1)
        {
            if (PlayerMoney[playerid] < amount)
            {
                SendClientMessage(playerid, 0xFF5555FF, "Недостаточно наличных для пополнения.");
                ShowBankDialog(playerid);
                return 1;
            }
            PlayerMoney[playerid] -= amount;
            PlayerBankMoney[playerid] += amount;
            ResetPlayerMoney(playerid);
            GivePlayerMoney(playerid, PlayerMoney[playerid]);
            SaveBankBalance(playerid);
            SavePlayerCash(playerid);
            LogBankTransaction(playerid, "deposit", amount, "");
            SendClientMessage(playerid, 0x65C9FFFF, "Деньги зачислены на банковский счёт.");
        }
        else if (BankAction[playerid] == 2)
        {
            if (PlayerBankMoney[playerid] < amount)
            {
                SendClientMessage(playerid, 0xFF5555FF, "На банковском счёте недостаточно средств.");
                ShowBankDialog(playerid);
                return 1;
            }
            PlayerBankMoney[playerid] -= amount;
            PlayerMoney[playerid] += amount;
            ResetPlayerMoney(playerid);
            GivePlayerMoney(playerid, PlayerMoney[playerid]);
            SaveBankBalance(playerid);
            SavePlayerCash(playerid);
            LogBankTransaction(playerid, "withdraw", amount, "");
            SendClientMessage(playerid, 0x65C9FFFF, "Деньги сняты с банковского счёта.");
        }
        return 1;
    }

    if (dialogid == DIALOG_BANK_TRANSFER)
    {
        if (!response) { ShowBankDialog(playerid); return 1; }
        new split = strfind(inputtext, " ", true);
        if (split < 1 || split >= strlen(inputtext) - 1 || strfind(inputtext[split + 1], " ", true) != -1)
        {
            SendClientMessage(playerid, 0xFFCC66FF, "Формат: ID сумма. Например: 4 1500");
            ShowBankDialog(playerid);
            return 1;
        }
        new targetText[12], amountText[16];
        strmid(targetText, inputtext, 0, split, sizeof targetText);
        strmid(amountText, inputtext, split + 1, strlen(inputtext), sizeof amountText);
        if (!IsNumericString(targetText) || !IsNumericString(amountText))
        {
            SendClientMessage(playerid, 0xFFCC66FF, "ID и сумма должны быть числами.");
            ShowBankDialog(playerid);
            return 1;
        }
        new targetid = strval(targetText);
        new amount = strval(amountText);
        if (targetid < 0 || targetid >= MAX_PLAYERS || !IsPlayerConnected(targetid) || !PlayerLoggedIn[targetid] || targetid == playerid || amount < 1 || amount > 100000000)
        {
            SendClientMessage(playerid, 0xFF5555FF, "Проверь ID игрока и сумму перевода.");
            ShowBankDialog(playerid);
            return 1;
        }
        if (PlayerBankMoney[playerid] < amount)
        {
            SendClientMessage(playerid, 0xFF5555FF, "На счёте недостаточно средств.");
            ShowBankDialog(playerid);
            return 1;
        }
        PlayerBankMoney[playerid] -= amount;
        PlayerBankMoney[targetid] += amount;
        SaveBankBalance(playerid);
        SaveBankBalance(targetid);
        LogBankTransaction(playerid, "transfer_out", amount, PlayerAccountName[targetid]);
        LogBankTransaction(targetid, "transfer_in", amount, PlayerAccountName[playerid]);
        new senderMsg[96], targetMsg[96];
        format(senderMsg, sizeof senderMsg, "Перевод %d KZT игроку ID %d выполнен.", amount, targetid);
        format(targetMsg, sizeof targetMsg, "На твой счёт поступило %d KZT от ID %d.", amount, playerid);
        SendClientMessage(playerid, 0x65C9FFFF, senderMsg);
        SendClientMessage(targetid, 0x65C9FFFF, targetMsg);
        return 1;
    }

    if (dialogid == DIALOG_CHAR_NAME)
    {
        if (!response) { ShowCharacterNameDialog(playerid); return 1; }
        new split = strfind(inputtext, " ", true);
        new spaces = 0;
        for (new i = 0; inputtext[i] != '\0'; i++)
            if (inputtext[i] == ' ') spaces++;
        if (split < 2 || split > 24 || strlen(inputtext) - split - 1 < 2 || strlen(inputtext) - split - 1 > 24 || spaces != 1)
        {
            SendClientMessage(playerid, 0xFFCC66FF, "Введи имя и фамилию через один пробел (2-24 символа каждое).");
            ShowCharacterNameDialog(playerid);
            return 1;
        }
        strmid(PlayerFirstName[playerid], inputtext, 0, split, 25);
        strmid(PlayerLastName[playerid], inputtext, split + 1, strlen(inputtext), 25);
        ShowPlayerDialog(playerid, DIALOG_CHAR_AGE, DIALOG_STYLE_INPUT,
            "KOKBORI RP | Возраст", "Укажи возраст персонажа (18-80):", "Далее", "Назад");
        return 1;
    }

    if (dialogid == DIALOG_CHAR_AGE)
    {
        if (!response) { ShowCharacterNameDialog(playerid); return 1; }
        if (!IsNumericString(inputtext) || strval(inputtext) < 18 || strval(inputtext) > 80)
        {
            SendClientMessage(playerid, 0xFFCC66FF, "Возраст должен быть числом от 18 до 80.");
            ShowPlayerDialog(playerid, DIALOG_CHAR_AGE, DIALOG_STYLE_INPUT,
                "KOKBORI RP | Возраст", "Укажи возраст персонажа (18-80):", "Далее", "Назад");
            return 1;
        }
        PlayerAge[playerid] = strval(inputtext);
        ShowPlayerDialog(playerid, DIALOG_CHAR_GENDER, DIALOG_STYLE_LIST,
            "KOKBORI RP | Пол персонажа", "Мужской\nЖенский", "Выбрать", "Назад");
        return 1;
    }

    if (dialogid == DIALOG_CHAR_GENDER)
    {
        if (!response)
        {
            ShowPlayerDialog(playerid, DIALOG_CHAR_AGE, DIALOG_STYLE_INPUT,
                "KOKBORI RP | Возраст", "Укажи возраст персонажа (18-80):", "Далее", "Назад");
            return 1;
        }
        PlayerGender[playerid] = (listitem == 1) ? 1 : 0;
        PlayerSkin[playerid] = (PlayerGender[playerid] == 1) ? 40 : 0;
        if (!SaveNewCharacter(playerid))
        {
            SendClientMessage(playerid, 0xFF5555FF, "Не удалось сохранить персонажа. Попробуй ещё раз.");
            ShowCharacterNameDialog(playerid);
            return 1;
        }
        CharacterReady(playerid);
        return 1;
    }

    if (dialogid == DIALOG_JOB)
    {
        if (!response) return 1;
        PlayerJob[playerid] = listitem + 1;
        SavePlayerJob(playerid);
        SendClientMessage(playerid, 0x65C9FFFF,
            "Работа выбрана. Используй /work, чтобы выполнить смену.");
        return 1;
    }

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
            "KOKBORI: /help /stats /id /job /work /bank /bankhistory /buyveh /veh /parkveh /sellveh /lockveh /engine /inv /buyitem ID /useitem ID /buyhouse /house /sellhouse /buybiz /biz /bizcollect /adminhelp /faction /joinfaction ID /leavefaction /fchat TEXT /duty /dropitem ID /giveitem ITEM AMOUNT PLAYERID");
        return 1;
    }

    if (!strcmp(cmdtext, "/stats", true))
    {
        new msg[144];
        format(msg, sizeof msg, "%s %s | Возраст: %d | Наличные: %d | Банк: %d KZT", PlayerFirstName[playerid], PlayerLastName[playerid], PlayerAge[playerid], PlayerMoney[playerid], PlayerBankMoney[playerid]);
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

    if (!strcmp(cmdtext, "/bank", true))
    {
        ShowBankDialog(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/bankhistory", true))
    {
        ShowBankHistory(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/job", true))
    {
        ShowPlayerDialog(playerid, DIALOG_JOB, DIALOG_STYLE_LIST,
            "KOKBORI RP | Выбор работы",
            "Курьер\nТаксист\nМеханик", "Выбрать", "Закрыть");
        return 1;
    }

    if (!strcmp(cmdtext, "/work", true))
    {
        if (PlayerJob[playerid] == 0)
        {
            SendClientMessage(playerid, 0xFFCC66FF,
                "Сначала выбери работу командой /job.");
            return 1;
        }
        new now = gettime();
        if (PlayerLastWork[playerid] != 0 && now - PlayerLastWork[playerid] < 60)
        {
            new secondsLeft = 60 - (now - PlayerLastWork[playerid]);
            new waitMsg[80];
            format(waitMsg, sizeof waitMsg, "Следующая смена будет доступна через %d сек.", secondsLeft);
            SendClientMessage(playerid, 0xFFCC66FF, waitMsg);
            return 1;
        }
        PlayerLastWork[playerid] = now;
        SavePlayerWork(playerid);
        new reward;
        switch (PlayerJob[playerid])
        {
            case 1: reward = 350 + random(151);
            case 2: reward = 400 + random(201);
            case 3: reward = 450 + random(201);
            default: reward = 300;
        }
        PlayerMoney[playerid] += reward;
        GivePlayerMoney(playerid, reward);
        SavePlayerCash(playerid);
        new workMsg[96];
        format(workMsg, sizeof workMsg, "Смена завершена. Заработано: %d KZT.", reward);
        SendClientMessage(playerid, 0x65C9FFFF, workMsg);
        return 1;
    }

    if (!strcmp(cmdtext, "/giveitem ", true, 10))
    {
        new firstSpace = strfind(cmdtext[10], " ", true);
        if (firstSpace < 1) { SendClientMessage(playerid, 0xFFCC66FF, "Использование: /giveitem ID_предмета количество ID_игрока."); return 1; }
        new secondStart = 10 + firstSpace + 1;
        new secondSpace = strfind(cmdtext[secondStart], " ", true);
        if (secondSpace < 1) { SendClientMessage(playerid, 0xFFCC66FF, "Использование: /giveitem ID_предмета количество ID_игрока."); return 1; }
        new itemText[8], amountText[8], targetText[8];
        strmid(itemText, cmdtext, 10, 10 + firstSpace, sizeof itemText);
        strmid(amountText, cmdtext, secondStart, secondStart + secondSpace, sizeof amountText);
        strmid(targetText, cmdtext, secondStart + secondSpace + 1, strlen(cmdtext), sizeof targetText);
        if (!IsNumericString(itemText) || !IsNumericString(amountText) || !IsNumericString(targetText))
        {
            SendClientMessage(playerid, 0xFFCC66FF, "ID предмета, количество и ID игрока должны быть числами.");
            return 1;
        }
        GiveInventoryItem(playerid, strval(itemText), strval(amountText), strval(targetText));
        return 1;
    }

    if (!strcmp(cmdtext, "/dropitem ", true, 10))
    {
        if (!IsNumericString(cmdtext[10])) { SendClientMessage(playerid, 0xFFCC66FF, "Использование: /dropitem ID (1-5)."); return 1; }
        DropInventoryItem(playerid, strval(cmdtext[10]));
        return 1;
    }

    if (!strcmp(cmdtext, "/inv", true)) { ShowPlayerInventory(playerid); return 1; }
    if (!strcmp(cmdtext, "/buyitem ", true, 9)) { BuyInventoryItem(playerid, strval(cmdtext[9])); return 1; }
    if (!strcmp(cmdtext, "/useitem ", true, 9)) { UseInventoryItem(playerid, strval(cmdtext[9])); return 1; }
    if (!strcmp(cmdtext, "/buyhouse", true)) { BuyPlayerHouse(playerid); return 1; }
    if (!strcmp(cmdtext, "/house", true)) { EnterPlayerHouse(playerid); return 1; }
    if (!strcmp(cmdtext, "/sellhouse", true)) { SellPlayerHouse(playerid); return 1; }
    if (!strcmp(cmdtext, "/buybiz", true)) { BuyPlayerBusiness(playerid); return 1; }
    if (!strcmp(cmdtext, "/biz", true)) { ShowPlayerBusiness(playerid); return 1; }
    if (!strcmp(cmdtext, "/bizcollect", true)) { CollectBusinessIncome(playerid); return 1; }
    if (!strcmp(cmdtext, "/kickid ", true, 8))
    {
        if (PlayerAdminLevel[playerid] < 1) { SendClientMessage(playerid, 0xFF5555FF, "Нет доступа."); return 1; }
        new targetid = strval(cmdtext[8]);
        if (targetid < 0 || targetid >= MAX_PLAYERS || !IsPlayerConnected(targetid) || !PlayerLoggedIn[targetid]) { SendClientMessage(playerid, 0xFFCC66FF, "Неверный ID игрока."); return 1; }
        LogAdminAction(playerid, "kick", PlayerAccountName[targetid], "Администраторское исключение");
        SendClientMessage(targetid, 0xFF5555FF, "Ты был отключён администрацией.");
        Kick(targetid);
        return 1;
    }
    if (!strcmp(cmdtext, "/setcash ", true, 9))
    {
        if (PlayerAdminLevel[playerid] < 2) { SendClientMessage(playerid, 0xFF5555FF, "Требуется уровень администратора 2."); return 1; }
        new split = strfind(cmdtext[9], " ", true);
        if (split < 1) { SendClientMessage(playerid, 0xFFCC66FF, "Формат: /setcash ID сумма"); return 1; }
        new targetText[12], amountText[16];
        strmid(targetText, cmdtext, 9, 9 + split, sizeof targetText);
        strmid(amountText, cmdtext, 10 + split, strlen(cmdtext), sizeof amountText);
        if (!IsNumericString(targetText) || !IsNumericString(amountText)) { SendClientMessage(playerid, 0xFFCC66FF, "ID и сумма должны быть числами."); return 1; }
        new targetid = strval(targetText), amount = strval(amountText);
        if (targetid < 0 || targetid >= MAX_PLAYERS || !IsPlayerConnected(targetid) || !PlayerLoggedIn[targetid] || amount < 0 || amount > 100000000) { SendClientMessage(playerid, 0xFFCC66FF, "Проверь ID и сумму (0-100000000)."); return 1; }
        PlayerMoney[targetid] = amount; ResetPlayerMoney(targetid); GivePlayerMoney(targetid, amount); SavePlayerCash(targetid);
        LogAdminAction(playerid, "setcash", PlayerAccountName[targetid], amountText);
        SendClientMessage(playerid, 0x65C9FFFF, "Баланс игрока обновлён.");
        SendClientMessage(targetid, 0x65C9FFFF, "Администратор изменил твой баланс.");
        return 1;
    }

    if (!strcmp(cmdtext, "/faction", true)) { ShowPlayerFaction(playerid); return 1; }
    if (!strcmp(cmdtext, "/joinfaction ", true, 13)) { JoinPlayerFaction(playerid, strval(cmdtext[13])); return 1; }
    if (!strcmp(cmdtext, "/leavefaction", true)) { LeavePlayerFaction(playerid); return 1; }
    if (!strcmp(cmdtext, "/fchat ", true, 7)) { SendFactionMessage(playerid, cmdtext[7]); return 1; }
    if (!strcmp(cmdtext, "/duty", true)) { TogglePlayerDuty(playerid); return 1; }

    if (!strcmp(cmdtext, "/adminhelp", true))
    {
        if (PlayerAdminLevel[playerid] < 1) SendClientMessage(playerid, 0xFF5555FF, "Нет доступа.");
        else SendClientMessage(playerid, 0x65C9FFFF, "Админ-система подключена; выдача уровней — через таблицу admin_accounts.");
        return 1;
    }

    if (!strcmp(cmdtext, "/buyveh", true))
    {
        BuyPlayerVehicle(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/veh", true))
    {
        SummonPlayerVehicle(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/parkveh", true))
    {
        ParkPlayerVehicle(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/sellveh", true))
    {
        SellPlayerVehicle(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/lockveh", true))
    {
        ToggleOwnedVehicleLock(playerid);
        return 1;
    }

    if (!strcmp(cmdtext, "/engine", true))
    {
        ToggleOwnedVehicleEngine(playerid);
        return 1;
    }
    return 0;
}




stock GiveInventoryItem(playerid, itemid, amount, targetid)
{
    if (itemid < 1 || itemid > 5 || amount < 1 || amount > INVENTORY_SLOTS ||
        targetid < 0 || targetid >= MAX_PLAYERS || targetid == playerid ||
        !IsPlayerConnected(targetid) || !PlayerLoggedIn[targetid])
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Проверь ID предмета (1-5), количество (1-20) и ID игрока.");
        return 0;
    }
    if (!IsPlayerInRangeOfPoint(playerid, 3.0, GetPlayerX(targetid), GetPlayerY(targetid), GetPlayerZ(targetid)))
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Игрок должен находиться рядом (до 3 метров).");
        return 0;
    }
    if (GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid) ||
        GetPlayerInterior(playerid) != GetPlayerInterior(targetid))
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Вы должны находиться в одном мире и интерьере.");
        return 0;
    }
    if (PlayerItemCount[playerid][itemid] < amount)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "У тебя недостаточно этих предметов.");
        return 0;
    }
    new total = 0;
    for (new i = 1; i <= 5; i++) total += PlayerItemCount[targetid][i];
    if (total + amount > INVENTORY_SLOTS)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "У получателя недостаточно места в инвентаре.");
        return 0;
    }
    PlayerItemCount[playerid][itemid] -= amount;
    PlayerItemCount[targetid][itemid] += amount;
    if (!SaveInventoryItem(playerid, itemid) || !SaveInventoryItem(targetid, itemid))
    {
        PlayerItemCount[playerid][itemid] += amount;
        PlayerItemCount[targetid][itemid] -= amount;
        SaveInventoryItem(playerid, itemid);
        SaveInventoryItem(targetid, itemid);
        SendClientMessage(playerid, 0xFF5555FF, "Не удалось сохранить передачу. Изменения отменены.");
        return 0;
    }
    new senderMessage[96], targetMessage[96];
    format(senderMessage, sizeof senderMessage, "Передано предметов: %d (ID %d) игроку ID %d.", amount, itemid, targetid);
    format(targetMessage, sizeof targetMessage, "Ты получил предметов: %d (ID %d) от игрока ID %d.", amount, itemid, playerid);
    SendClientMessage(playerid, 0x65C9FFFF, senderMessage);
    SendClientMessage(targetid, 0x65C9FFFF, targetMessage);
    return 1;
}

stock DropInventoryItem(playerid, itemid)
{
    if (itemid < 1 || itemid > 5 || PlayerItemCount[playerid][itemid] < 1)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Такого предмета нет в инвентаре. Посмотри /inv.");
        return 0;
    }
    new slot = -1;
    for (new i = 0; i < MAX_WORLD_ITEM_PICKUPS; i++)
    {
        if (WorldItemType[i] == 0) { slot = i; break; }
    }
    if (slot == -1)
    {
        SendClientMessage(playerid, 0xFF5555FF, "На земле сейчас нет свободного места для новых предметов.");
        return 0;
    }
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new pickupid = CreatePickup(1279, 1, x, y, z - 0.5, GetPlayerVirtualWorld(playerid));
    if (pickupid == INVALID_PICKUP)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Не удалось создать предмет на земле.");
        return 0;
    }
    PlayerItemCount[playerid][itemid]--;
    if (!SaveInventoryItem(playerid, itemid))
    {
        PlayerItemCount[playerid][itemid]++;
        DestroyPickup(pickupid);
        SendClientMessage(playerid, 0xFF5555FF, "Ошибка сохранения инвентаря. Предмет остался у тебя.");
        return 0;
    }
    WorldItemPickup[slot] = pickupid;
    WorldItemType[slot] = itemid;
    WorldItemAmount[slot] = 1;
    SendClientMessage(playerid, 0x65C9FFFF, "Предмет выброшен на землю. Его сможет подобрать другой игрок в этом мире.");
    return 1;
}

stock BuyInventoryItem(playerid, itemid)
{
    if (itemid < 1 || itemid > 5) { SendClientMessage(playerid, 0xFFCC66FF, "ID предмета: 1 аптечка, 2 вода, 3 еда, 4 ремкомплект, 5 телефон."); return 0; }
    new total = 0;
    for (new i = 1; i <= 5; i++) total += PlayerItemCount[playerid][i];
    if (total >= INVENTORY_SLOTS) { SendClientMessage(playerid, 0xFFCC66FF, "Инвентарь заполнен."); return 0; }
    new price;
    switch (itemid) { case 1: price = 250; case 2: price = 50; case 3: price = 80; case 4: price = 500; case 5: price = 1000; }
    if (PlayerMoney[playerid] < price) { SendClientMessage(playerid, 0xFF5555FF, "Недостаточно наличных."); return 0; }
    PlayerMoney[playerid] -= price; PlayerItemCount[playerid][itemid]++;
    ResetPlayerMoney(playerid); GivePlayerMoney(playerid, PlayerMoney[playerid]); SavePlayerCash(playerid); SaveInventoryItem(playerid, itemid);
    SendClientMessage(playerid, 0x65C9FFFF, "Предмет куплен и сохранён. Список: /inv.");
    return 1;
}

stock ShowPlayerInventory(playerid)
{
    new msg[96], total = 0;
    SendClientMessage(playerid, 0x65C9FFFF, "Инвентарь: 1 аптечка, 2 вода, 3 еда, 4 ремкомплект, 5 телефон.");
    for (new i = 1; i <= 5; i++) { total += PlayerItemCount[playerid][i]; format(msg, sizeof msg, "Предмет %d: %d шт.", i, PlayerItemCount[playerid][i]); SendClientMessage(playerid, 0xFFFFFFFF, msg); }
    format(msg, sizeof msg, "Слоты: %d/%d. Используй /useitem ID.", total, INVENTORY_SLOTS); SendClientMessage(playerid, 0xFFFFFFFF, msg);
    return 1;
}
stock LoadPlayerInventory(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[192];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "SELECT item_id,amount FROM player_inventory WHERE account_name='%s';", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    for (new i = 1; i <= 5; i++) PlayerItemCount[playerid][i] = 0;
    if (db_num_rows(result) > 0) do { new itemid = db_get_field_assoc_int(result, "item_id"); if (itemid >= 1 && itemid <= 5) PlayerItemCount[playerid][itemid] = db_get_field_assoc_int(result, "amount"); } while (db_next_row(result));
    db_free_result(result); return 1;
}
stock SaveInventoryItem(playerid, itemid)
{
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[224];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "INSERT OR REPLACE INTO player_inventory (account_name,item_id,amount) VALUES ('%s',%d,%d);", safeName, itemid, PlayerItemCount[playerid][itemid]);
    new DBResult:result = db_query(gDatabase, query); if (!result) return 0; db_free_result(result); return 1;
}
stock UseInventoryItem(playerid, itemid)
{
    if (itemid < 1 || itemid > 5 || PlayerItemCount[playerid][itemid] < 1) { SendClientMessage(playerid, 0xFFCC66FF, "Предмет отсутствует."); return 0; }
    if (itemid == 4) { if (!IsPlayerInAnyVehicle(playerid)) { SendClientMessage(playerid, 0xFFCC66FF, "Ремкомплект используется в автомобиле."); return 0; } RepairVehicle(GetPlayerVehicleID(playerid)); }
    else if (itemid == 5) { SendClientMessage(playerid, 0x65C9FFFF, "Телефон пока служит предметом инвентаря."); return 1; }
    else SetPlayerHealth(playerid, 100.0);
    PlayerItemCount[playerid][itemid]--; SaveInventoryItem(playerid, itemid); SendClientMessage(playerid, 0x65C9FFFF, "Предмет использован."); return 1;
}
stock LoadPlayerProperties(playerid)
{
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[192];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "SELECT account_name FROM player_houses WHERE account_name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query); PlayerHouseOwned[playerid] = (result && db_num_rows(result) > 0) ? 1 : 0; if (result) db_free_result(result);
    format(query, sizeof query, "SELECT last_collect FROM player_businesses WHERE account_name='%s' LIMIT 1;", safeName);
    result = db_query(gDatabase, query); PlayerBusinessOwned[playerid] = (result && db_num_rows(result) > 0) ? 1 : 0; PlayerBusinessLastCollect[playerid] = (PlayerBusinessOwned[playerid] && result) ? db_get_field_assoc_int(result, "last_collect") : 0; if (result) db_free_result(result);
    return 1;
}
stock BuyPlayerHouse(playerid)
{
    if (PlayerHouseOwned[playerid] || PlayerMoney[playerid] < HOUSE_PRICE) { SendClientMessage(playerid, 0xFFCC66FF, "Нужны свободный слот недвижимости и 250000 KZT."); return 0; }
    new Float:x, Float:y, Float:z, Float:a; GetPlayerPos(playerid,x,y,z); GetPlayerFacingAngle(playerid,a);
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[320]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"INSERT INTO player_houses (account_name,price,x,y,z,angle) VALUES ('%s',%d,%f,%f,%f,%f);",safeName,HOUSE_PRICE,x,y,z,a);
    new DBResult:result=db_query(gDatabase,query); if (!result) return 0; db_free_result(result);
    PlayerMoney[playerid]-=HOUSE_PRICE; PlayerHouseOwned[playerid]=1; ResetPlayerMoney(playerid); GivePlayerMoney(playerid,PlayerMoney[playerid]); SavePlayerCash(playerid);
    SendClientMessage(playerid,0x65C9FFFF,"Дом куплен. /house — вернуться к точке покупки."); return 1;
}
stock EnterPlayerHouse(playerid)
{
    if (!PlayerHouseOwned[playerid]) { SendClientMessage(playerid,0xFFCC66FF,"Сначала купи дом: /buyhouse."); return 0; }
    new safeName[(MAX_PLAYER_NAME * 2) + 1],query[192]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"SELECT x,y,z,angle FROM player_houses WHERE account_name='%s' LIMIT 1;",safeName);
    new DBResult:result=db_query(gDatabase,query); if (!result || db_num_rows(result)==0) { if(result) db_free_result(result); return 0; }
    new Float:x=db_get_field_assoc_float(result,"x"),Float:y=db_get_field_assoc_float(result,"y"),Float:z=db_get_field_assoc_float(result,"z"),Float:a=db_get_field_assoc_float(result,"angle"); db_free_result(result);
    SetPlayerPos(playerid,x,y,z); SetPlayerFacingAngle(playerid,a); SendClientMessage(playerid,0x65C9FFFF,"Ты у своей недвижимости."); return 1;
}
stock SellPlayerHouse(playerid)
{
    if (!PlayerHouseOwned[playerid]) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1],query[160]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"DELETE FROM player_houses WHERE account_name='%s';",safeName);
    new DBResult:result=db_query(gDatabase,query); if(!result) return 0; db_free_result(result);
    PlayerHouseOwned[playerid]=0; PlayerMoney[playerid]+=HOUSE_PRICE/2; ResetPlayerMoney(playerid); GivePlayerMoney(playerid,PlayerMoney[playerid]); SavePlayerCash(playerid);
    SendClientMessage(playerid,0x65C9FFFF,"Дом продан за 125000 KZT."); return 1;
}
stock BuyPlayerBusiness(playerid)
{
    if (PlayerBusinessOwned[playerid] || PlayerMoney[playerid] < BUSINESS_PRICE) { SendClientMessage(playerid,0xFFCC66FF,"Нужен свободный слот и 500000 KZT."); return 0; }
    new safeName[(MAX_PLAYER_NAME * 2) + 1],query[192]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"INSERT INTO player_businesses (account_name,price,last_collect) VALUES ('%s',%d,0);",safeName,BUSINESS_PRICE);
    new DBResult:result=db_query(gDatabase,query); if(!result) return 0; db_free_result(result);
    PlayerMoney[playerid]-=BUSINESS_PRICE; PlayerBusinessOwned[playerid]=1; PlayerBusinessLastCollect[playerid]=0; ResetPlayerMoney(playerid); GivePlayerMoney(playerid,PlayerMoney[playerid]); SavePlayerCash(playerid);
    SendClientMessage(playerid,0x65C9FFFF,"Бизнес куплен. Доход 2500 KZT раз в 30 минут: /bizcollect."); return 1;
}
stock ShowPlayerBusiness(playerid)
{
    if (!PlayerBusinessOwned[playerid]) { SendClientMessage(playerid,0xFFCC66FF,"Бизнеса нет. /buybiz"); return 0; }
    SendClientMessage(playerid,0x65C9FFFF,"Бизнес приносит 2500 KZT раз в 30 минут."); return 1;
}
stock CollectBusinessIncome(playerid)
{
    if (!PlayerBusinessOwned[playerid]) return 0;
    new now=gettime(); if(PlayerBusinessLastCollect[playerid]!=0 && now-PlayerBusinessLastCollect[playerid]<BUSINESS_COOLDOWN) { new msg[96]; format(msg,sizeof msg,"Доход доступен через %d сек.",BUSINESS_COOLDOWN-(now-PlayerBusinessLastCollect[playerid])); SendClientMessage(playerid,0xFFCC66FF,msg); return 0; }
    new safeName[(MAX_PLAYER_NAME * 2) + 1],query[224]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"UPDATE player_businesses SET last_collect=%d WHERE account_name='%s';",now,safeName);
    new DBResult:result=db_query(gDatabase,query); if(!result) return 0; db_free_result(result);
    PlayerBusinessLastCollect[playerid]=now; PlayerMoney[playerid]+=BUSINESS_PAYOUT; ResetPlayerMoney(playerid); GivePlayerMoney(playerid,BUSINESS_PAYOUT); SavePlayerCash(playerid);
    SendClientMessage(playerid,0x65C9FFFF,"Доход бизнеса: +2500 KZT."); return 1;
}

stock LoadPlayerFaction(playerid)
{
    PlayerFaction[playerid] = FACTION_NONE; PlayerFactionRank[playerid] = 0; PlayerOnDuty[playerid] = false;
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[192]; EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "SELECT faction_id,faction_rank FROM player_factions WHERE account_name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query); if (!result) return 0;
    if (db_num_rows(result) > 0) { PlayerFaction[playerid] = db_get_field_assoc_int(result, "faction_id"); PlayerFactionRank[playerid] = db_get_field_assoc_int(result, "faction_rank"); }
    db_free_result(result); return 1;
}
stock ShowPlayerFaction(playerid)
{
    new msg[128];
    if (PlayerFaction[playerid] == FACTION_NONE) format(msg, sizeof msg, "Ты не состоишь во фракции. /joinfaction 1-3");
    else format(msg, sizeof msg, "Фракция: %s | Ранг: %d | Служба: %s", PlayerFaction[playerid] == 1 ? ("Полиция") : (PlayerFaction[playerid] == 2 ? ("Медики") : ("Правительство")), PlayerFactionRank[playerid], PlayerOnDuty[playerid] ? ("Да") : ("Нет"));
    SendClientMessage(playerid, 0x65C9FFFF, msg); return 1;
}
stock JoinPlayerFaction(playerid, factionid)
{
    if (factionid < 1 || factionid > 3) { SendClientMessage(playerid, 0xFFCC66FF, "Доступные фракции: 1 полиция, 2 медики, 3 правительство."); return 0; }
    if (PlayerFaction[playerid] != FACTION_NONE) { SendClientMessage(playerid, 0xFFCC66FF, "Сначала выйди из текущей фракции."); return 0; }
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[224]; EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "INSERT INTO player_factions (account_name,faction_id,faction_rank) VALUES ('%s',%d,1);", safeName, factionid);
    new DBResult:result = db_query(gDatabase, query); if (!result) return 0; db_free_result(result);
    PlayerFaction[playerid] = factionid; PlayerFactionRank[playerid] = 1;
    SendClientMessage(playerid, 0x65C9FFFF, "Ты вступил во фракцию. Используй /duty для начала службы."); return 1;
}
stock LeavePlayerFaction(playerid)
{
    if (PlayerFaction[playerid] == FACTION_NONE) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1], query[160]; EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    format(query, sizeof query, "DELETE FROM player_factions WHERE account_name='%s';", safeName);
    new DBResult:result = db_query(gDatabase, query); if (!result) return 0; db_free_result(result);
    PlayerFaction[playerid] = FACTION_NONE; PlayerFactionRank[playerid] = 0; PlayerOnDuty[playerid] = false;
    SendClientMessage(playerid, 0x65C9FFFF, "Ты покинул фракцию."); return 1;
}
stock SendFactionMessage(playerid, const message[])
{
    if (PlayerFaction[playerid] == FACTION_NONE) { SendClientMessage(playerid, 0xFF5555FF, "Ты не состоишь во фракции."); return 0; }
    if (message[0] == '\0') return 0;
    new output[160], name[MAX_PLAYER_NAME + 1]; GetPlayerName(playerid, name, sizeof name);
    format(output, sizeof output, "[ФРАКЦИЯ] %s [%d]: %s", name, PlayerFactionRank[playerid], message);
    for (new i = 0; i < MAX_PLAYERS; i++)
        if (IsPlayerConnected(i) && PlayerLoggedIn[i] && PlayerFaction[i] == PlayerFaction[playerid])
            SendClientMessage(i, 0x8CCBFFFF, output);
    return 1;
}
stock TogglePlayerDuty(playerid)
{
    if (PlayerFaction[playerid] == FACTION_NONE) { SendClientMessage(playerid, 0xFFCC66FF, "Для службы нужна фракция."); return 0; }
    PlayerOnDuty[playerid] = !PlayerOnDuty[playerid];
    SendClientMessage(playerid, 0x65C9FFFF, PlayerOnDuty[playerid] ? ("Ты заступил на службу.") : ("Ты закончил службу."));
    return 1;
}

stock LogAdminAction(playerid, const action[], const targetName[], const details[])
{
    if (gDatabase == DB:0) return 0;
    new safeAdmin[(MAX_PLAYER_NAME * 2) + 1], safeTarget[(MAX_PLAYER_NAME * 2) + 1], safeDetails[128], query[384];
    EscapeSQL(PlayerAccountName[playerid], safeAdmin, sizeof safeAdmin);
    EscapeSQL(targetName, safeTarget, sizeof safeTarget);
    EscapeSQL(details, safeDetails, sizeof safeDetails);
    format(query, sizeof query, "INSERT INTO admin_logs (admin_name,action,target_name,details) VALUES ('%s','%s','%s','%s');", safeAdmin, action, safeTarget, safeDetails);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock LoadPlayerAdmin(playerid)
{
    PlayerAdminLevel[playerid]=0; new safeName[(MAX_PLAYER_NAME * 2) + 1],query[192]; EscapeSQL(PlayerAccountName[playerid],safeName,sizeof safeName);
    format(query,sizeof query,"SELECT level FROM admin_accounts WHERE account_name='%s' LIMIT 1;",safeName);
    new DBResult:result=db_query(gDatabase,query); if(!result) return 0;
    if(db_num_rows(result)>0) PlayerAdminLevel[playerid]=db_get_field_assoc_int(result,"level"); db_free_result(result); return 1;
}

stock ToggleOwnedVehicleLock(playerid)
{
    if (!IsPlayerInAnyVehicle(playerid) || GetPlayerVehicleSeat(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Сядь за руль своего автомобиля.");
        return 0;
    }
    new vehicleid = GetPlayerVehicleID(playerid);
    if (strcmp(VehicleOwner[vehicleid], PlayerAccountName[playerid], true) != 0)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Ты не владелец этого автомобиля.");
        return 0;
    }
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
    if (doors == 1)
    {
        SetVehicleParamsEx(vehicleid, -1, -1, -1, 0, -1, -1, -1);
        SendClientMessage(playerid, 0x65C9FFFF, "Автомобиль открыт.");
    }
    else
    {
        SetVehicleParamsEx(vehicleid, -1, -1, -1, 1, -1, -1, -1);
        SendClientMessage(playerid, 0x65C9FFFF, "Автомобиль закрыт.");
    }
    return 1;
}

stock ToggleOwnedVehicleEngine(playerid)
{
    if (!IsPlayerInAnyVehicle(playerid) || GetPlayerVehicleSeat(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Сядь за руль своего автомобиля.");
        return 0;
    }
    new vehicleid = GetPlayerVehicleID(playerid);
    if (strcmp(VehicleOwner[vehicleid], PlayerAccountName[playerid], true) != 0)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Ты не владелец этого автомобиля.");
        return 0;
    }
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
    if (engine == 1)
    {
        SetVehicleParamsEx(vehicleid, 0, lights, alarm, doors, bonnet, boot, objective);
        SendClientMessage(playerid, 0x65C9FFFF, "Двигатель выключен.");
    }
    else
    {
        SetVehicleParamsEx(vehicleid, 1, lights, alarm, doors, bonnet, boot, objective);
        SendClientMessage(playerid, 0x65C9FFFF, "Двигатель запущен.");
    }
    return 1;
}

stock FindPlayerVehicle(playerid)
{
    for (new vehicleid = 1; vehicleid <= MAX_VEHICLES; vehicleid++)
    {
        if (VehicleOwner[vehicleid][0] != '\0' &&
            !strcmp(VehicleOwner[vehicleid], PlayerAccountName[playerid], true))
            return vehicleid;
    }
    return 0;
}

stock LoadOwnedVehicles()
{
    if (gDatabase == DB:0) return 0;
    new DBResult:result = db_query(gDatabase,
        "SELECT account_name, modelid, color1, color2, x, y, z, angle FROM owned_vehicles;");
    if (!result) return 0;
    if (db_num_rows(result) > 0)
    {
        do
        {
            new owner[MAX_PLAYER_NAME + 1];
            db_get_field_assoc(result, "account_name", owner, sizeof owner);
            new modelid = db_get_field_assoc_int(result, "modelid");
            new color1 = db_get_field_assoc_int(result, "color1");
            new color2 = db_get_field_assoc_int(result, "color2");
            new Float:x = db_get_field_assoc_float(result, "x");
            new Float:y = db_get_field_assoc_float(result, "y");
            new Float:z = db_get_field_assoc_float(result, "z");
            new Float:angle = db_get_field_assoc_float(result, "angle");
            new vehicleid = CreateVehicle(modelid, x, y, z, angle, color1, color2, -1);
            if (vehicleid > 0 && vehicleid <= MAX_VEHICLES)
                format(VehicleOwner[vehicleid], MAX_PLAYER_NAME + 1, "%s", owner);
        }
        while (db_next_row(result));
    }
    db_free_result(result);
    return 1;
}

stock SaveOwnedVehicle(vehicleid)
{
    if (vehicleid <= 0 || vehicleid > MAX_VEHICLES || VehicleOwner[vehicleid][0] == '\0' || gDatabase == DB:0)
        return 0;
    new Float:x, Float:y, Float:z, Float:angle;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    new modelid = GetVehicleModel(vehicleid);
    new color1 = 1, color2 = 1;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(VehicleOwner[vehicleid], safeName, sizeof safeName);
    new query[320];
    format(query, sizeof query,
        "UPDATE owned_vehicles SET modelid=%d, color1=%d, color2=%d, x=%f, y=%f, z=%f, angle=%f WHERE account_name='%s';",
        modelid, color1, color2, x, y, z, angle, safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock BuyPlayerVehicle(playerid)
{
    if (FindPlayerVehicle(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "У тебя уже есть личный автомобиль. Используй /veh.");
        return 0;
    }
    if (PlayerMoney[playerid] < VEHICLE_PRICE)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Недостаточно наличных. Автомобиль стоит 15000 KZT.");
        return 0;
    }
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    x += 4.0;
    new vehicleid = CreateVehicle(VEHICLE_MODEL_PLACEHOLDER, x, y, z, angle, 1, 1, -1);
    if (vehicleid == 0 || vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Не удалось создать автомобиль. Попробуй позже.");
        return 0;
    }
    PlayerMoney[playerid] -= VEHICLE_PRICE;
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    format(VehicleOwner[vehicleid], MAX_PLAYER_NAME + 1, "%s", PlayerAccountName[playerid]);
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[320];
    format(query, sizeof query,
        "INSERT INTO owned_vehicles (account_name, modelid, color1, color2, x, y, z, angle) VALUES ('%s', %d, 1, 1, %f, %f, %f, %f);",
        safeName, VEHICLE_MODEL_PLACEHOLDER, x, y, z, angle);
    new DBResult:result = db_query(gDatabase, query);
    if (!result)
    {
        DestroyVehicle(vehicleid);
        VehicleOwner[vehicleid][0] = '\0';
        PlayerMoney[playerid] += VEHICLE_PRICE;
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, PlayerMoney[playerid]);
        SendClientMessage(playerid, 0xFF5555FF, "Ошибка сохранения автомобиля. Деньги возвращены.");
        return 0;
    }
    db_free_result(result);
    SavePlayerCash(playerid);
    SendClientMessage(playerid, 0x65C9FFFF, "Автомобиль куплен и сохранён. Вызови его командой /veh.");
    return 1;
}

stock SummonPlayerVehicle(playerid)
{
    new vehicleid = FindPlayerVehicle(playerid);
    if (vehicleid == 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "У тебя пока нет личного автомобиля. Покупка: /buyveh.");
        return 0;
    }
    if (IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    x += 5.0;
    SetVehiclePos(vehicleid, x, y, z);
    SetVehicleZAngle(vehicleid, angle);
    PutPlayerInVehicle(playerid, vehicleid, 0);
    SendClientMessage(playerid, 0x65C9FFFF, "Твой автомобиль доставлен к тебе.");
    return 1;
}

stock ParkPlayerVehicle(playerid)
{
    if (!IsPlayerInAnyVehicle(playerid) || GetPlayerVehicleSeat(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "Сядь за руль своего автомобиля, чтобы сохранить парковку.");
        return 0;
    }
    new vehicleid = GetPlayerVehicleID(playerid);
    if (strcmp(VehicleOwner[vehicleid], PlayerAccountName[playerid], true) != 0)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Это не твой автомобиль.");
        return 0;
    }
    SaveOwnedVehicle(vehicleid);
    SendClientMessage(playerid, 0x65C9FFFF, "Положение и цвет автомобиля сохранены.");
    return 1;
}

stock SellPlayerVehicle(playerid)
{
    new vehicleid = FindPlayerVehicle(playerid);
    if (vehicleid == 0)
    {
        SendClientMessage(playerid, 0xFFCC66FF, "У тебя нет личного автомобиля.");
        return 0;
    }
    if (IsPlayerInVehicle(playerid, vehicleid)) RemovePlayerFromVehicle(playerid);
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[160];
    format(query, sizeof query, "DELETE FROM owned_vehicles WHERE account_name='%s';", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Не удалось оформить продажу автомобиля.");
        return 0;
    }
    db_free_result(result);
    DestroyVehicle(vehicleid);
    VehicleOwner[vehicleid][0] = '\0';
    PlayerMoney[playerid] += VEHICLE_REFUND;
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    SavePlayerCash(playerid);
    SendClientMessage(playerid, 0x65C9FFFF, "Автомобиль продан за 7500 KZT.");
    return 1;
}


stock SavePlayerPosition(playerid)
{
    if (gDatabase == DB:0 || !PlayerLoggedIn[playerid]) return 0;
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    new interior = GetPlayerInterior(playerid);
    new world = GetPlayerVirtualWorld(playerid);
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[320];
    format(query, sizeof query,
        "INSERT OR REPLACE INTO player_positions (account_name, x, y, z, angle, interior, world) VALUES ('%s', %f, %f, %f, %f, %d, %d);",
        safeName, x, y, z, angle, interior, world);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock LoadPlayerPosition(playerid)
{
    PlayerHasSavedPosition[playerid] = false;
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[224];
    format(query, sizeof query,
        "SELECT x, y, z, angle, interior, world FROM player_positions WHERE account_name='%s' LIMIT 1;",
        safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    if (db_num_rows(result) > 0)
    {
        PlayerSavedX[playerid] = db_get_field_assoc_float(result, "x");
        PlayerSavedY[playerid] = db_get_field_assoc_float(result, "y");
        PlayerSavedZ[playerid] = db_get_field_assoc_float(result, "z");
        PlayerSavedAngle[playerid] = db_get_field_assoc_float(result, "angle");
        PlayerSavedInterior[playerid] = db_get_field_assoc_int(result, "interior");
        PlayerSavedWorld[playerid] = db_get_field_assoc_int(result, "world");
        PlayerHasSavedPosition[playerid] = true;
    }
    db_free_result(result);
    return 1;
}

stock SavePlayerCash(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query, "UPDATE accounts SET money=%d WHERE name='%s';", PlayerMoney[playerid], safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock ShowBankHistory(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[224];
    format(query, sizeof query,
        "SELECT action, amount, other_account, created_at FROM bank_transactions WHERE account_name='%s' ORDER BY id DESC LIMIT 5;", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result)
    {
        SendClientMessage(playerid, 0xFF5555FF, "Не удалось загрузить историю операций.");
        return 0;
    }
    if (db_num_rows(result) == 0)
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "Банковских операций пока нет.");
        db_free_result(result);
        return 1;
    }
    SendClientMessage(playerid, 0x65C9FFFF, "Последние 5 банковских операций:");
    do
    {
        new action[24], other[25], created[24], row[144];
        db_get_field_assoc(result, "action", action, sizeof action);
        db_get_field_assoc(result, "other_account", other, sizeof other);
        db_get_field_assoc(result, "created_at", created, sizeof created);
        new amount = db_get_field_assoc_int(result, "amount");
        if (other[0] != '\0')
            format(row, sizeof row, "%s: %d KZT | %s | %s", action, amount, other, created);
        else
            format(row, sizeof row, "%s: %d KZT | %s", action, amount, created);
        SendClientMessage(playerid, 0xFFFFFFFF, row);
    }
    while (db_next_row(result));
    db_free_result(result);
    return 1;
}

stock ShowBankDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_BANK, DIALOG_STYLE_LIST,
        "KOKBORI BANK | Astana",
        "Проверить баланс\nПоложить наличные\nСнять деньги\nПеревести игроку\nИстория операций",
        "Выбрать", "Закрыть");
    return 1;
}

stock SaveBankBalance(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query,
        "INSERT OR REPLACE INTO bank_accounts (account_name, balance) VALUES ('%s', %d);",
        safeName, PlayerBankMoney[playerid]);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock LoadBankBalance(playerid)
{
    PlayerBankMoney[playerid] = 0;
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query,
        "INSERT OR IGNORE INTO bank_accounts (account_name, balance) VALUES ('%s', 0);", safeName);
    new DBResult:createResult = db_query(gDatabase, query);
    if (createResult) db_free_result(createResult);
    format(query, sizeof query,
        "SELECT balance FROM bank_accounts WHERE account_name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    if (db_num_rows(result) > 0)
        PlayerBankMoney[playerid] = db_get_field_assoc_int(result, "balance");
    db_free_result(result);
    return 1;
}

stock LogBankTransaction(playerid, const action[], amount, const otherAccount[])
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    new safeOther[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    EscapeSQL(otherAccount, safeOther, sizeof safeOther);
    new query[320];
    format(query, sizeof query,
        "INSERT INTO bank_transactions (account_name, action, amount, other_account) VALUES ('%s', '%s', %d, '%s');",
        safeName, action, amount, safeOther);
    new DBResult:result = db_query(gDatabase, query);
    if (result) db_free_result(result);
    return 1;
}

stock SavePlayerWork(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query,
        "INSERT OR REPLACE INTO player_work (account_name, last_work) VALUES ('%s', %d);",
        safeName, PlayerLastWork[playerid]);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock LoadPlayerWork(playerid)
{
    PlayerLastWork[playerid] = 0;
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query,
        "SELECT last_work FROM player_work WHERE account_name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    if (db_num_rows(result) > 0)
        PlayerLastWork[playerid] = db_get_field_assoc_int(result, "last_work");
    db_free_result(result);
    return 1;
}

stock SavePlayerJob(playerid)
{
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[160];
    format(query, sizeof query,
        "INSERT OR REPLACE INTO player_jobs (name, job_id) VALUES ('%s', %d);",
        safeName, PlayerJob[playerid]);
    new DBResult:result = db_query(gDatabase, query);
    if (result) db_free_result(result);
    return 1;
}

stock LoadPlayerJob(playerid)
{
    PlayerJob[playerid] = 0;
    if (gDatabase == DB:0) return 0;
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[160];
    format(query, sizeof query,
        "SELECT job_id FROM player_jobs WHERE name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (result)
    {
        if (db_num_rows(result) > 0)
            PlayerJob[playerid] = db_get_field_assoc_int(result, "job_id");
        db_free_result(result);
    }
    return 1;
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
    LoadPlayerJob(playerid);
    LoadBankBalance(playerid);
    LoadPlayerWork(playerid);
    LoadPlayerInventory(playerid);
    LoadPlayerProperties(playerid);
    LoadPlayerAdmin(playerid);
    LoadPlayerFaction(playerid);
    LoadPlayerPosition(playerid);
    new safeName[(MAX_PLAYER_NAME * 2) + 1];
    EscapeSQL(PlayerAccountName[playerid], safeName, sizeof safeName);
    new query[192];
    format(query, sizeof query, "SELECT first_name, last_name, age, gender, skin FROM characters WHERE account_name='%s' LIMIT 1;", safeName);
    new DBResult:result = db_query(gDatabase, query);
    if (result && db_num_rows(result) > 0)
    {
        db_get_field_assoc(result, "first_name", PlayerFirstName[playerid], 25);
        db_get_field_assoc(result, "last_name", PlayerLastName[playerid], 25);
        PlayerAge[playerid] = db_get_field_assoc_int(result, "age");
        PlayerGender[playerid] = db_get_field_assoc_int(result, "gender");
        PlayerSkin[playerid] = db_get_field_assoc_int(result, "skin");
        db_free_result(result);
        CharacterReady(playerid);
    }
    else
    {
        if (result) db_free_result(result);
        ShowCharacterNameDialog(playerid);
    }
    return 1;
}

stock ShowCharacterNameDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_CHAR_NAME, DIALOG_STYLE_INPUT,
        "KOKBORI RP | Создание персонажа",
        "Введи имя и фамилию персонажа через пробел (2-24 символа каждое):",
        "Далее", "Повторить");
    return 1;
}

stock SaveNewCharacter(playerid)
{
    new safeAccount[(MAX_PLAYER_NAME * 2) + 1];
    new safeFirst[50], safeLast[50];
    EscapeSQL(PlayerAccountName[playerid], safeAccount, sizeof safeAccount);
    EscapeSQL(PlayerFirstName[playerid], safeFirst, sizeof safeFirst);
    EscapeSQL(PlayerLastName[playerid], safeLast, sizeof safeLast);
    new query[320];
    format(query, sizeof query,
        "INSERT INTO characters (account_name, first_name, last_name, age, gender, skin) VALUES ('%s', '%s', '%s', %d, %d, %d);",
        safeAccount, safeFirst, safeLast, PlayerAge[playerid], PlayerGender[playerid], PlayerSkin[playerid]);
    new DBResult:result = db_query(gDatabase, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock CharacterReady(playerid)
{
    SendClientMessage(playerid, 0x65C9FFFF, "Ты вошёл на KOKBORI RP | Astana.");
    SendClientMessage(playerid, 0xFFFFFFFF, "Используй /help, чтобы посмотреть доступные команды.");
    TogglePlayerSpectating(playerid, false);
    SetSpawnInfo(playerid, 0, PlayerSkin[playerid], KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y,
        KOKBORI_SPAWN_Z, KOKBORI_SPAWN_A, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    return 1;
}

stock IsNumericString(const value[])
{
    if (value[0] == '\0') return 0;
    for (new i = 0; value[i] != '\0'; i++)
        if (value[i] < '0' || value[i] > '9') return 0;
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
