defmodule GmailSynchronize.Network do
  defprotocol BufferManagement do
    def buffer(data)
    def update_buffer(data, new_buffer)
    def fill_buffer(data)
    def has_bytes_buffered?(data, n)
  end

  defrecord NetworkReader, input: nil

  def has_full_line([]), do: false

  def has_full_line?([buf|rest]) do
    has_full_line?(buf) || has_full_line?(rest)
  end

  def has_full_line?(<<>>), do: false

  def has_full_line?(<<"\r", rest::binary>>) do
    case rest do
      <<"\n", _::binary>> ->
        true
      _ ->
        has_full_line?(rest)
    end
  end

  def has_full_line?(<<_, rest::binary>>), do: has_full_line?(rest)

  defp read_line_buffers(NetworkReader[input: input] = reader) do
    if has_full_line?(BufferManagement.buffer(input)) do
      [line, rest] = String.split(BufferManagement.buffer(input), "\r\n", global: false)
      {[line], reader.input(BufferManagement.update_buffer(input, rest))}
    else
      with_refilled_buffer reader,
        fn (reader) ->
             {buffers, reader} = read_line_buffers(reader)
             {[BufferManagement.buffer(input) | buffers], reader}
        end
    end
  end

  def read_line(reader) do
    {line_buffers, reader} = read_line_buffers(reader)
    {Enum.map_join(line_buffers, '', binary_to_list(&1)), reader}
  end

  def read_n_bytes(NetworkReader[input: input] = reader, n) do
    if BufferManagement.has_bytes_buffered?(input, n) do
      <<n_bytes :: [size(n), binary], rest :: binary>> = BufferManagement.buffer(input)
      {[n_bytes], reader.input(BufferManagement.update_buffer(input, rest))}
    else
      current_buffer_length = size(BufferManagement.buffer(input))
      {n_bytes, reader} = with_refilled_buffer(reader, fn (reader) -> read_n_bytes(reader, n - current_buffer_length) end)
      {[BufferManagement.buffer(input) | n_bytes], reader}
    end
  end

  defp with_refilled_buffer(NetworkReader[input: input] = reader, fun) do
    fun.(reader.input(BufferManagement.fill_buffer(input)))
  end
end