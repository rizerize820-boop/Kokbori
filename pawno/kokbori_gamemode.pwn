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
#define WORK_COOLDOWN_MS (60000)

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

    SetPlayerSkin(playerid, PlayerSkin[playerid]);
    SetPlayerPos(playerid, KOKBORI_SPAWN_X, KOKBORI_SPAWN_Y, KOKBORI_SPAWN_Z);
    SetPlayerFacingAngle(playerid, KOKBORI_SPAWN_A);
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
            "KOKBORI: /help /stats /id /job /work /bank /veh");
        return 1;
    }

    if (!strcmp(cmdtext, "/stats", true))
    {
        new msg[144];
        format(msg, sizeof msg, "%s %s | Возраст: %d | Баланс: %d KZT", PlayerFirstName[playerid], PlayerLastName[playerid], PlayerAge[playerid], PlayerMoney[playerid]);
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
        new now = GetTickCount();
        if (PlayerLastWork[playerid] != 0 && now - PlayerLastWork[playerid] < WORK_COOLDOWN_MS)
        {
            new secondsLeft = (WORK_COOLDOWN_MS - (now - PlayerLastWork[playerid])) / 1000;
            new waitMsg[80];
            format(waitMsg, sizeof waitMsg, "Следующая смена будет доступна через %d сек.", secondsLeft);
            SendClientMessage(playerid, 0xFFCC66FF, waitMsg);
            return 1;
        }
        PlayerLastWork[playerid] = now;
        new reward = 300 + random(201);
        PlayerMoney[playerid] += reward;
        GivePlayerMoney(playerid, reward);
        new workMsg[96];
        format(workMsg, sizeof workMsg, "Смена завершена. Заработано: %d KZT.", reward);
        SendClientMessage(playerid, 0x65C9FFFF, workMsg);
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

stock ShowBankDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_BANK, DIALOG_STYLE_LIST,
        "KOKBORI BANK | Astana",
        "Проверить баланс\nПоложить наличные\nСнять деньги\nПеревести игроку",
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
    if (value[0] == '\\0') return 0;
    for (new i = 0; value[i] != '\\0'; i++)
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
