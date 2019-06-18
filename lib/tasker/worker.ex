defmodule Tasker.Worker do
  @moduledoc """
  This module will contact the weather API and do return the temparature.
  As long as it is provided the correct
  """

  @doc """
    get a single city temparature.
  """
  def temperature_of(city) do
    create_url(city)
    |> HTTPoison.get()
    |> parse_response
  end

  defp create_url(city) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{city}&appid=#{api_key()}"
  end

  defp api_key do
    "c5bcd52c435ecaf5f659ccac8d3c1311"
  end

  def parse_response({:error, _}) do
    {:error, "[:ERROR:] check your internet connection and retry"}
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!()
    |> compute_temperature
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: _}}) do
    body
    |> JSON.decode!()
    |> decode_error
  end

  defp compute_temperature(json) do
    try do
      temp =
        (json["main"]["temp"] - 273.15)
        |> Float.round(1)

      {:ok, temp}
    rescue
      _ ->
        {:error, "[:ERROR:] temparature cant be decoded"}
    end
  end

  defp decode_error(reason) do
    {:error, "[:ERROR:] #{reason["message"]}"}
  end
end
