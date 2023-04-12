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

**-daemon** - completely detaches from the current process terminal
**./crb** - pipe directory
**./log** - log directory
**iex -S mix** - command to run##

## Build Release

MIX_ENV=prod mix release

## Run in Backrgound

elixir --no-halt --detached -S mix > fileoutput.txt &

## Websockets

Poloniex API:  `wss://api2.poloniex.com`

Connect to Poloniex through WebSockets

    {:ok, pid} = Shotgun.start_link("wss://api2.poloniex.com", 443)
