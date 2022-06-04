// Директива, указывающая строго соблюдения синтаксиса сорсмода
#pragma semicolon 1

// Подключаем главный инклуд сорсмода
#include <sourcemod>

// Глобальная переменная, создается методом define
#define PLUGIN_VERSION "1.0"

// Функция которая хранит мета-данные о плагине и его создателе
// 	выводится в консоле сервера по команде: 
//		> sm plugins info <номер вашего плагина в списке>
public Plugin myinfo =
{
	name = "Simple Chat trigger",
	author = "Alex Deroza (KGB1st)",
	description = "simple chat trigger",
	version = PLUGIN_VERSION,
	url = "https://ranks.moonsiber.org"
};

// Событие, когда плагин стартует на сервере (каждый раз, после запуска карты)
public void OnPluginStart()
{
	// AddCommandListener, перехватывает сообщения чата (по сути вешает триггер на события чата)
	AddCommandListener(HookPlayerChat_All, "say");
	//AddCommandListener(HookPlayerChat_Team, "say_team"); // чат союзников
}

// Событие, когда плагин перехватывает любое новое сообщение, поступающее в игровой чат
public Action HookPlayerChat_All(int client, const char[] command, int args)
{
	// Завершаем работу программы если игрок НЕВАЛИДЕН (не в сети, не в игре, или его id неверный)
	if(!client || client >= MAXPLAYERS || !IsClientConnected(client) || !IsClientInGame(client)) 
	{
		return Plugin_Continue;
	}
	
	// 	Создаем переменную, в которой будем хранить текст чата (по сути это временный буфер для этого текста)
	char text[PLATFORM_MAX_PATH]; // длинна PLATFORM_MAX_PATH - 256 символов
	
	// Прочитаем текст поступивший в наш чат и запишем его в переменную text
	GetCmdArg(1, text, sizeof(text));
	
	// Проверяем входящий текст на наличие фразы
	if(StrContains(text, "!hi", false) == -1)
	{
		return Plugin_Continue;
	}
	
	/**
	 * Prints a message to a specific client in the chat area.
	 *
	 * @param client        Client index.
	 * @param format        Formatting rules.
	 * @param ...           Variable number of format parameters.
	 * @error               If the client is not connected an error will be thrown.
	 */
	 
	PrintToChat(client, "Привет, %N", client);
	
	// Форма %N в связке с client позволяет выводить текущее имя пользователя
	// 	это позволяет не вызывать функцию для получения никнейма игрока и записывать его в строку
	
	// Если бы мы хотели получить ник игрока с помощью этой функции, тогда код бы выглядет так..
	
	// Объявим стринг длинною в 63 символа
	char nickName[64];
	
	// Выполним функцию, которая автоматом запишет полученный ник игрока в наш стринг
	GetClientName(client, nickName, 63);
	
	// После чего выполним наш код для ответа на перехваченное сообщение
	// 	однако, в этом случае мы не будем использовать ID клиента, а прямо передадим строку с его ником
	PrintToChat(client, "Привет, %s", nickName);
	
	// Задача №1: написать функцию, которая дополнительно будет выводить для всех остальных игроков фразу:
	// 	> Player_Nick: привет всем!
	
	return Plugin_Handled;
}

//SourceMod Batch Compiler
// by the SourceMod Dev Team


//// pipec.sp
//
// Code size:             3516 bytes
// Data size:             2444 bytes
// Stack/heap size:      16384 bytes
// Total requirements:   22344 bytes
//
// Compilation Time: 0.12 sec
// ----------------------------------------

