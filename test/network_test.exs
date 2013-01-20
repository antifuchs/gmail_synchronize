Code.require_file "../test_helper.exs", __FILE__

defmodule GmailSynchronize.Network.Test do
  use ExUnit.Case

  alias GmailSynchronize.Network, as: Net

  defrecord TestInput, buffers: [], current_buffer: ""

  defimpl Net.BufferManagement, for: TestInput do
    def buffer(TestInput[current_buffer: buffer]), do: buffer

    def update_buffer(TestInput[] = input, buffer) do
      input.current_buffer(buffer)
    end

    def fill_buffer(TestInput[buffers: [next|rest]] = input) do
      # This is sensible only for small amounts of data.
      input = input.current_buffer(<<input.current_buffer :: binary, next :: binary>>)
      input.buffers(rest)
    end

    def has_bytes_buffered?(TestInput[current_buffer: buffer], bytes) when size(buffer) >= bytes, do: true
    def has_bytes_buffered?(_, _), do: false
  end

  test "returns a line when so buffered" do
    reader = Net.NetworkReader.new(input: TestInput.new(buffers: ["abcdefg\r\nfoo"]))
    {line, reader} = Net.read_line(reader)
    assert line == "abcdefg"
    assert Net.BufferManagement.buffer(reader.input) == "foo"
  end

  test "returns a line after rebuffering" do
    reader = Net.NetworkReader.new(input: TestInput.new(buffers: ["abcde", "fg\r\nfoo"]))
    {line, reader} = Net.read_line(reader)
    assert line == "abcdefg"
    assert Net.BufferManagement.buffer(reader.input) == "foo"
  end

  test "returns N bytes in a buffer of M>=N bytes" do
    reader = Net.NetworkReader.new(input: TestInput.new(buffers: ["foobar"]))
    {n_bytes, reader} = Net.read_n_bytes(reader, 5)
    assert n_bytes == "fooba"
    assert Net.BufferManagement.buffer(reader.input) == "r"
  end

  test "returns N bytes even when it has to re-fill the buffer" do
    reader = Net.NetworkReader.new(input: TestInput.new(buffers: ["f", "o", "o", "bar"]))
    {n_bytes, reader} = Net.read_n_bytes(reader, 5)
    assert n_bytes == "fooba"
    assert Net.BufferManagement.buffer(reader.input) == "r"
  end
end