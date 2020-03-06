defmodule TelegramApi do
  require Logger

  def accounts do
    []
  end

  def send_message(text), do: spawn_link(__MODULE__, :send_message_process, [text])
  def send_message_process(text) do
    for account <- accounts do
      with {:error, error} <- Nadia.send_message(account, text) do
        Logger.warn "Cannot send message to Telegram."
        error |> inspect |> Logger.warn()
      end
    end
  end


  def test_connection do
    case Nadia.get_me do
      {:ok, _} -> Logger.info "Sucessfully connected to Telegram"
      _ -> Logger.error "Cannot connect to Telegram"
    end
  end

  def start_polling do
    spawn_link(TelegramApi, :polling, [self()])
  end

  def polling(parent_pid) do
    case Nadia.get_updates do
      {:ok, updates} ->
        for update <- updates do
          if (update.message != nil) do
            send parent_pid, {:user_message, update.message.text }
          end
        end
        case Enum.take(updates, -1) do
          [] -> nil
          [last] -> Nadia.get_updates([{:offset, last.update_id + 1}])
        end
      _ ->
    end
    polling(parent_pid)
  end

end