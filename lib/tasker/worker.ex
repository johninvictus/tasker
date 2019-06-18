defmodule Tasker.Worker do

  require Logger
  @moduledoc """
  This module will contact the weather API and do return the temparature.
  As long as it is provided the correct
  """

  @doc """
  This function to receive messages send and fetch the citys temparature
  """
  def loop do
    receive do
      {coordinator_pid, city} ->
        data = temperature_of(city)

        case data do
          {:ok, _city, temp} ->
            send(coordinator_pid, {:ok, "#{city} #{temp}"})

          {:error, _city, _reason} ->
            send(coordinator_pid, {:ok, "#{city} temparature"})
        end
    end
  end

  @doc """
    get a single city temparature.
  """
  def temperature_of(city) do
    create_url(city)
    |> HTTPoison.get()
    |> parse_response(city)
  end

  defp create_url(city) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{city}&appid=#{api_key()}"
  end

  defp api_key do
    "c5bcd52c435ecaf5f659ccac8d3c1311"
  end

  def parse_response({:error, _}, city) do
    {:error, city, "[:ERROR:] check your internet connection and retry"}
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}, city) do
    body
    |> JSON.decode!()
    |> compute_temperature(city)
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: _}}, city) do
    body
    |> JSON.decode!()
    |> decode_error(city)
  end

  defp compute_temperature(json, city) do
    try do
      temp =
        (json["main"]["temp"] - 273.15)
        |> Float.round(1)

      {:ok,city, temp}
    rescue
      _ ->
        {:error, city, "[:ERROR:] temparature cant be decoded"}
    end
  end

  defp decode_error(reason, city) do
    {:error, city, "[:ERROR:] #{reason["message"]}"}
  end
end
