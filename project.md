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

## TODO

## Документация по GenStage
https://hexdocs.pm/gen_stage/GenStage.html

## Запус в фоновом режиме без привязки к консоли
echo "" | iex -S mix > file.txt &
elixir --no-halt --detached -S mix > fileoutput.txt &

## Как реализовать WebSocket

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

# Дешевый vpn за 1 бакс
https://virmach.com/

# Быстрая настройка VPN
https://github.com/Nyr/openvpn-install
https://habr.com/post/87197/

# Сборка Erlang


# Elixir tracing and observing
http://blog.plataformatec.com.br/2016/05/tracing-and-observing-your-remote-node/

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

# Для того, чтобы скомпилировать модуль в HiPe к модулю добавляется аттрибут
@compile [:native, {:hipe, [:verbose, :o3]}]

# GenServer Cheat Sheet


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

# Настройка IEx
http://samuelmullen.com/articles/customizing_elixirs_iex/

# Процесс балланса и аггрегированных сделок

Баланс в таком виде
%{"ETC" => #Decimal<1000>, "USDT" => #Decimal<1000>}

# ELIXIR: how to Filter a list for a specific struct
https://stackoverflow.com/questions/36936763/elixir-how-to-filter-a-list-for-a-specific-struct
for %A{} = a <- list, do: a

# Присоединиться к vpn
sudo openvpn --config ~/client.ovpn

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

#ZFS snapshot

## Recursively
sudo zfs snapshot -r rpool@name

## Init git server repository
git --bare init

## run nix repl
nix repl
exit - :q
























**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `crbmix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crbmix, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/crybomix](https://hexdocs.pm/crybomix).


Create VPN

Location: https://raw.github.com/Nyr/openvpn-install/master/openvpn-install.sh [following]
--2018-12-24 23:49:05--  https://raw.github.com/Nyr/openvpn-install/master/openvpn-install.sh
Resolving raw.github.com (raw.github.com)... 151.101.12.133
Connecting to raw.github.com (raw.github.com)|151.101.12.133|:443... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh [following]
--2018-12-24 23:49:05--  https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 151.101.12.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|151.101.12.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 14806 (14K) [text/plain]
Saving to: ‘openvpn-install.sh’

openvpn-install.sh  100%[===================>]  14.46K  --.-KB/s    in 0s

2018-12-24 23:49:05 (133 MB/s) - ‘openvpn-install.sh’ saved [14806/14806]


Welcome to this OpenVPN "road warrior" installer!

I need to ask you a few questions before starting the setup.
You can leave the default options and just press enter if you are ok with them.

First, provide the IPv4 address of the network interface you want OpenVPN
listening to.
IP address: 104.248.16.20

Which protocol do you want for OpenVPN connections?
   1) UDP (recommended)
   2) TCP
Protocol [1-2]: 1

What port do you want OpenVPN listening to?
Port: 1194

Which DNS do you want to use with the VPN?
   1) Current system resolvers
   2) 1.1.1.1
   3) Google
   4) OpenDNS
   5) Verisign
DNS [1-5]: 1

Finally, tell me your name for the client certificate.
Please, use one word only, no special characters.
Client name: client

Okay, that was all I needed. We are ready to set up your OpenVPN server now.
Press any key to continue...
Get:1 http://security.ubuntu.com/ubuntu xenial-security InRelease [107 kB]
Hit:2 http://mirrors.digitalocean.com/ubuntu xenial InRelease
Hit:3 http://mirrors.digitalocean.com/ubuntu xenial-updates InRelease
Hit:4 http://mirrors.digitalocean.com/ubuntu xenial-backports InRelease
Fetched 107 kB in 0s (152 kB/s)
Reading package lists... Done
Reading package lists... Done
Building dependency tree
Reading state information... Done
iptables is already the newest version (1.6.0-2ubuntu3).
ca-certificates is already the newest version (20170717~16.04.1).
openssl is already the newest version (1.0.2g-1ubuntu4.14).
The following package was automatically installed and is no longer required:
  grub-pc-bin
Use 'apt autoremove' to remove it.
The following additional packages will be installed:
  libpkcs11-helper1
Suggested packages:
  easy-rsa
The following NEW packages will be installed:
  libpkcs11-helper1 openvpn
0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
Need to get 465 kB of archives.
After this operation, 1,168 kB of additional disk space will be used.
Get:1 http://ams2.mirrors.digitalocean.com/ubuntu xenial/main amd64 libpkcs11-helper1 amd64 1.11-5 [44.0 kB]
Get:2 http://ams2.mirrors.digitalocean.com/ubuntu xenial-updates/main amd64 openvpn amd64 2.3.10-1ubuntu2.1 [421 kB]
Fetched 465 kB in 0s (1,001 kB/s)
Preconfiguring packages ...
Selecting previously unselected package libpkcs11-helper1:amd64.
(Reading database ... 54500 files and directories currently installed.)
Preparing to unpack .../libpkcs11-helper1_1.11-5_amd64.deb ...
Unpacking libpkcs11-helper1:amd64 (1.11-5) ...
Selecting previously unselected package openvpn.
Preparing to unpack .../openvpn_2.3.10-1ubuntu2.1_amd64.deb ...
Unpacking openvpn (2.3.10-1ubuntu2.1) ...
Processing triggers for libc-bin (2.23-0ubuntu10) ...
Processing triggers for man-db (2.7.5-1) ...
Processing triggers for systemd (229-4ubuntu21.10) ...
Processing triggers for ureadahead (0.100.0-19) ...
Setting up libpkcs11-helper1:amd64 (1.11-5) ...
Setting up openvpn (2.3.10-1ubuntu2.1) ...
 * Restarting virtual private network daemon(s)...                               *   No VPN is running.
Processing triggers for libc-bin (2.23-0ubuntu10) ...
Processing triggers for systemd (229-4ubuntu21.10) ...
Processing triggers for ureadahead (0.100.0-19) ...

Using SSL: openssl OpenSSL 1.0.2g  1 Mar 2016

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/easy-rsa/pki

Generating RSA private key, 2048 bit long modulus
...............+++
............................................................+++
e is 65537 (0x10001)

Using SSL: openssl OpenSSL 1.0.2g  1 Mar 2016
Generating a 2048 bit RSA private key
.....................+++
...............................................+++
writing new private key to '/etc/openvpn/easy-rsa/pki/private/server.key.NLIXO2TucB'
-----
Using configuration from ./safessl-easyrsa.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'server'
Certificate is to be certified until Dec 21 23:50:24 2028 GMT (3650 days)

Write out database with 1 new entries
Data Base Updated

Using SSL: openssl OpenSSL 1.0.2g  1 Mar 2016
Generating a 2048 bit RSA private key
......................+++
.............................................+++
writing new private key to '/etc/openvpn/easy-rsa/pki/private/client.key.ON79Y2kogh'
-----
Using configuration from ./safessl-easyrsa.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'client'
Certificate is to be certified until Dec 21 23:50:24 2028 GMT (3650 days)

Write out database with 1 new entries
Data Base Updated

Using SSL: openssl OpenSSL 1.0.2g  1 Mar 2016
Using configuration from ./safessl-easyrsa.cnf

An updated CRL has been created.
CRL file: /etc/openvpn/easy-rsa/pki/crl.pem

623

Finished!

Your client configuration is available at: /root/client.ovpn
If you want to add more clients, you simply need to run this script again!

---------------------------
11:59:18.432 [info]  order buy NXT/USDT, rate:0.028868093010000002, amount: 51.90852057601847

11:59:23.743 [error] GenServer ArbitrageBot terminating
** (MatchError) no match of right hand side value: {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
    (crb) lib/Poloniex/poloniex_api.ex:82: PoloniexApi.post_command/2
    (crb) lib/Poloniex/poloniex_api.ex:26: PoloniexApi.buy/4
    (crb) lib/Poloniex/arbitrage_bot.ex:93: anonymous fn/3 in ArbitrageBot.create_orders/2
    (elixir) lib/enum.ex:1940: Enum."-reduce/3-lists^foldl/2-0-"/3
    (crb) lib/Poloniex/arbitrage_bot.ex:88: ArbitrageBot.create_orders/2
    (crb) lib/Poloniex/arbitrage_bot.ex:48: ArbitrageBot.handle_events/3
    lib/gen_stage.ex:2329: GenStage.consumer_dispatch/6
    (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
Last message: {:"$gen_consumer", {#PID<0.218.0>, #Reference<0.2227272806.1127481345.211916>}, [{:rate_changed, :poloniex, :message, :NXT, :USDT, 0.02889699, 0.02889699, 0.0289084, false, 1547035153561}]}






