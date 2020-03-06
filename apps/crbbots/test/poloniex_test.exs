defmodule PoloniexTest do
  use ExUnit.Case
  doctest PoloniexApi

  test "number_to_order_type" do
    assert PoloniexApi.number_to_order_type(1) == :buy
    assert PoloniexApi.number_to_order_type(0) == :sell
  end

  def account_update_message do
    PoloniexBroadcaster.account_update_messages(["n", 0, 1, 0, "1.2", "20", "", "20"]) |> IO.puts
  end



end