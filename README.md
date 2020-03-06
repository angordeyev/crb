# Crb

## Run project

To run on server run command:
```
./run.sh
```
The file content:
```
run_erl -daemon ./crb ./log "iex -S mix"
```
-daemon - completely detaches from the current process terminal
./crb - pipe directorj
./log - log directory
"iex -S mix" - command to run

[run_erl documentation](http://erlang.org/doc/man/run_erl.html)

## Deploy

[Phoenix Deployment](https://hexdocs.pm/phoenix/deployment.html)

## Команды

### Запуск приложения
iex -S mix

### Установка зависимостей
mix deps.get

### Сборка релиза
MIX_ENV=prod mix release

## Запус в фоновом режиме без привязки к консоли
echo "" | iex -S mix > file.txt &
elixir --no-halt --detached -S mix > fileoutput.txt &

# Механизм создания цепочек ордеров

1. Передается массив ордеров
2. Создается первый ордер
3. Получем номер первого ордера
4. Записываем оставшеюся цепочку с ключем ордера
5. Получем уведомление о срабатывании ордера
6. Получаем по ключу оставшуюся цепочку ордера
7. Создаем следующий ордер
8. Удаляем записи по ключу
9. Добавляем оставшеюся цепочку с новым ключем , далее повтор с пункта 5, пока не останется пустой список ордеров

# Процесс балланса и аггрегированных сделок

Баланс в таком виде
%{"ETC" => #Decimal<1000>, "USDT" => #Decimal<1000>}

## Документация по GenStage
https://hexdocs.pm/gen_stage/GenStage.html

## Releases

https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html

Как GenStage
## Работа с Websocket

Клиент Chrome Smart Websocket Client

Проверка работы (Echo server)
wss://echo.websocket.org/

API Poliniex
wss://api2.poloniex.com

Соединени с Poloniex через WebSocket
{:ok, pid} = Shotgun.start_link("wss://api2.poloniex.com", 443)

# Руководство по IEx

https://hexdocs.pm/iex/IEx.html

# Elixir tasks
http://joeyates.info/2015/07/25/create-a-mix-task-for-an-elixir-project/

# Deploy with Distillery and edeliver
https://devato.com/automate-elixir-phoenix-1-4-deployment-with-distillery-and-edeliver-on-ubuntu/

# Возможность вставки многострочного кода

# Elixir Killer Tips

## Редирект коммандной строки в файл

iex -S mix > file.txt &
echo "" | mix some_task some_arg > file.txt &
echo "" | iex -S mix > file.txt &

# Debug в Elixir
https://crypt.codemancers.com/tags/elixir/

# Дополнительно

## Перезагрузка машины WSL
sudo killall -r '.*'

# Debugging Elixir
http://blog.plataformatec.com.br/2016/04/debugging-techniques-in-elixir-lang/

# Elixir tracing and observing
http://blog.plataformatec.com.br/2016/05/tracing-and-observing-your-remote-node/

# Для того, чтобы скомпилировать модуль в HiPe к модулю добавляется аттрибут
@compile [:native, {:hipe, [:verbose, :o3]}]

# GenServer Cheat Sheet

```
defmodule Counter do
  use GenStage

  def start_link(callback) do
    GenServer.start_link(__MODULE__, {0, callback })
  end

  def init(state) do
    {:ok, state}
  end

  def increment(pid) do
    GenServer.call(pid, :increment)
  end

  def handle_call(:increment, from, {counter, callback}) do
    {:reply, "current: #{counter+1}", {counter + 1, callback} }
  end

  def count(pid) do
    GenServer.cast(pid, :count)
  end

  def handle_cast(:count, state) do
    spawn(Counter, :count_cycle, [state])
    {:noreply, state}
  end

  def count_cycle({counter, callback}) do
    callback.(counter)
    :timer.sleep(1000)
    count_cycle({counter + 1, callback})
  end

  def printing(pid) do
    GenServer.cast(pid, :printing)
  end

  def handle_cast(:printing, c) do
    putter(1)
    {:noreply}
  end

  def putter(i) do
    IO.puts i
    :timer.sleep(2000)
    putter(i)
  end

  def cb(callback) do
    callback.()
  end

end
```

# Настройка IEx
http://samuelmullen.com/articles/customizing_elixirs_iex/

# ELIXIR: how to Filter a list for a specific struct
https://stackoverflow.com/questions/36936763/elixir-how-to-filter-a-list-for-a-specific-struct
for %A{} = a <- list, do: a

# Elixir Erlang and NIX
https://stackoverflow.com/questions/51371028/what-is-the-canonical-way-of-installing-elixir-on-erlang-19-with-nix-on-a-no/51384383#51384383
https://www.reddit.com/r/NixOS/comments/73ceks/elixir_151_with_erlang_200_on_nixos_1803/

# Profile erlang over ssh
https://mfeckie.github.io/Remote-Profiling-Elixir-Over-SSH/

# Elixir nix package
https://medium.com/@ejpcmac/using-nix-in-elixir-projects-ff5300214e7

IEx.configure(
  colors:
      [eval_error: [IO.ANSI.color(5,1,1)],
       stack_info: [IO.ANSI.color(1,2,1)] ]
)



# TODO

- [ ] Добавить автоматическое обновление сертификатов Certbot
- [ ] Cбой при апгрейде коннекшна Poloniex
- [ ] Unexpected {:gun_ws, #PID<0.359.0>, #Reference<0.2388937103.2826436610.103433>, :close}

- [ ] Арбитражные алгоритмы
  - [ ] Для проверки на эмуляторе биржи сделать задерку создания ордеров
  - [ ] Для проверки на эмуляторе создавать ордера, только тогда, когда ситуация арбитража держится какое-то время
- [ ] Copy release on remote machine
- [x] Phoenix application deployment
- [ ] Look into [CCTX](https://github.com/ccxt/ccxt)
- [ ] Графики продолжительности отдельно для каждой сделки, если проходит время и цена меняетмя - это уже другая сделка.
      Выбираем лучшие сделки и показываем на графике
- [ ] График арбитражей:
      Одна линия - разница одной пары между двумя биржами, к примеру USDT/BTC-Poliniex-BitPhoenix
      Разница между покупкой и продажей?
- [ ] Графики двойных и тройных сделок
      Показывает прибыль при двойной сделке и сколько она держится
      К примеру:
         Poloniex buy BTC/USDT, BitPhoenix sell USDT/BTC
         Тройные сделки, в том числе две на одной бирже, а третья на другой
- [ ] Графики провоцируемой сделки, то есть первая сделка провоцируется, по цене близкой к рынку 
- [ ] Separation and deployment infrastructure
- [ ] Add database project
- [ ] Elixir Deploy
- [ ] Публикация (One Click Deploy)
- [ ] Добавить автоматическое обновление сертификатов Certbot
- [ ] Cбой при апгрейде коннекшна Poloniex
- [ ] Unexpected {:gun_ws, #PID<0.359.0>, #Reference<0.2388937103.2826436610.103433>, :close}
- [ ] Отследить и измерить задержки при передаче сообщений
- [ ] Скачать минутные свечи
  - [ ] Poloniex
  - [ ] OKEX
  - [ ] Binance
- [ ] Доразобраться с логированием
- [ ] Доразобраться с диагностикой
- [ ] Доразобраться с запуском приложений
- [ ] Доделать броадкастер на OKEX
- [ ] Переприсоединение без вызова исключения, множественные
- [ ] Не запускать приложение при запуске тестов
- [ ] Сохранять все ошибки в логах
- [ ] Сохранить сессию с сервером
- [ ] Updated profit дубликаты из-за количества знаков
- [ ] Посмотреть какие шняги можно брать в долг
- [ ] Цепочка, которое начинается с продажи шняги
- [ ] Состояние счета каждый час
- [ ] Когда удаляется арбитраж показывать новые курсы валют
- [ ] Структура для арбитражей
- [ ] Webhooks
- [ ] Работа с валютой 1СR
- [ ] Telegram бот для логирования https://hexdocs.pm/logger_telegram_backend/readme.html
- [ ] Монитор получения данных, если данные не приходят, то перезагружаем ботов и соеденение с биржой
- [ ] Простой боевой робот
- [ ] Бэкапы сервера Borg
- [ ] Деплой
- [ ] Логирование ошибок
- [ ] Статистика для обработки в Excel
- [ ] Оптимизация быстродействия
- [ ] Алгоритм арбитража на парах
- [ ] Conditional log (Logger.debug только в случае, если стоят определенные настройки, например, логирование всех приходящих с вебсокетов сообщений, поскольку если логировать всегда, так поток будет мешать)
- [ ] Мониторинг сервера
- [ ] Надежный сбор статистики
- [ ] Быстрое развертывание приложения на любой ОС
- [ ] Быстрый прогон бота на данных
- [ ] Разработаь процесс разработки
  - [ ] Развертывание из системы контроля версий
- [ ] Настроить обновление приложения
- [ ] Запуск приложение на сервере как сервис
- [ ] Запись в конец файла медленная?
- [ ] Управление сервисом на сервере
- [ ] Разбивка лога по файлам (дням или часам)
- [ ] Процесс баланса и аггрегированных сделок
- [ ] Настроить цвета IEx, в том числе и для IO.inspect
- [ ] Обертка над над GUN
- [ ] Завершение работы приложения (напрмиер при невозможности подключения к Telegram)
- [ ] Удаление повторяющихся подряд курсов
- [ ] Plugin Mnesia для работы с LMDB
- [ ] Пакет elixir LMDB
- [ ] Пакет elixir GUN
- [ ] Написать полноценный pattern matching строк отдельной функцией (должно быть просто)
- [ ] Выполнение ордеров на основе цепочки функций или в виде отдельного процесса, который ожидает определенных событий
- [-] Distilllery
- [x] Виртуальные машины в Linux
- [x] Редактировать кода прямо на сервере(подключив файловую систему) и запускать там же
- [x] Перейти на Linux
  - [x] Настроить Sublime
- [x] Редирект :stdout в файл
- [x] Обновление валют при первом запуске и реконнекте
- [x] Настроить vpn
- [x] Snake case
- [x] Сохранить данные биржи
- [x] Приложение, которое рассылает события
- [-] Streamref для распределения событий GUN https://ninenines.eu/docs/en/gun/1.0/manual/gun.ws_upgrade/
- [x] Создать просто генератор событий
- [x] Сделать обработку событий
- [x] Получить данные Websocket с Poloniex
- [x] Установка соединения с Poloniex
- [x] Иcключения в Sublime
- [x] Научиться свободно использовать GenServer и понять его, написать пример самостоятельно
- [x] Набросать краткую шпаркалку по GenServer
