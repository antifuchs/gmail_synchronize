defmodule GmailSynchronize.Network do
  defprotocol BufferManagement do
    def buffer(data)
    def update_buffer(data, new_buffer)
    def fill_buffer(data)
    def has_bytes_buffered?(data, n)
  end

  defrecord NetworkReader, input: nil

  def has_full_line?(buffer) do
      # This seems silly, but apparently is the best way to test for
      # whether a binary contains two bytes in succession. This may be
      # faster to test for in a recursive function walking the
      # never-copied binary.
      length(String.split(buffer, "\r\n")) > 1
  end

  def read_line(NetworkReader[input: input] = reader) do
    if has_full_line?(BufferManagement.buffer(input)) do
      [line, rest] = String.split(BufferManagement.buffer(input), "\r\n", global: false)
      {line, reader.input(BufferManagement.update_buffer(input, rest))}
    else
      input = BufferManagement.fill_buffer(input)
      read_line(reader.input(input))
    end
  end

  def read_n_bytes(NetworkReader[input: input] = reader, n) do
    if BufferManagement.has_bytes_buffered?(input, n) do
      <<n_bytes :: [size(n), binary], rest :: binary>> = BufferManagement.buffer(input)
      {n_bytes, reader.input(BufferManagement.update_buffer(input, rest))}
    else
      input = BufferManagement.fill_buffer(input)
      read_n_bytes(reader.input(input), n)
    end
  end
end