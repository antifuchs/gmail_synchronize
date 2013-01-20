Code.require_file "../test_helper.exs", __FILE__


defmodule GmailSynchronizeTest.IMAP.StringSlice.Test do
  use ExUnit.Case

  test "slices a string into CR NL-separated lines" do
    assert GmailSynchronize.IMAP.StringSlice.next_line("foo\r\nbar\r\nbaz") == {"foo", "bar\r\nbaz"}
  end

  test "slices a buffer's string into CR NL-separated lines" do
    state = GmailSynchronize.IMAP.State.new(buffer: "foo\r\nbar\r\nbaz", literal_bytes: 0)
    {line, new_state} = GmailSynchronize.IMAP.StringSlice.next_line(state)
    assert line == "foo"
    assert new_state.buffer == "bar\r\nbaz"
    assert new_state.literal_bytes == 0
  end

  test "returns an M-byte buffer of a binary that's N bytes long when N>=M" do
    state = GmailSynchronize.IMAP.State.new(buffer: "oin\r\nk", literal_bytes: 3)
    {literal, new_state} = GmailSynchronize.IMAP.StringSlice.read_literal(state)
    assert literal == "oin"
    assert new_state.buffer == "\r\nk"
    assert new_state.literal_bytes == 0
  end

  # test "will read more bytes if N<M" do
  #   state = GmailSynchronize.IMAP.State.new(buffer: "oin", literal_bytes: 15)
  #   {literal, new_state} = GmailSynchronize.IMAP.StringSlice.read_literal(state)
  # end
end

defmodule GmailSynchronize.Network.Test do
  use ExUnit.Case

  defrecord TestInput, buffers: [], current_buffer: ""

  defimpl GmailSynchronize.Network.BufferManagement, for: TestInput do
    def buffer(TestInput[current_buffer: buffer]), do: buffer

    def update_buffer(TestInput[] = input, buffer) do
      input.current_buffer(buffer)
    end

    def fill_buffer(TestInput[buffers: [next|rest]] = input) do
      # This is sensible only for small amounts of data, apparently.
      input = input.current_buffer(<<input.current_buffer :: binary, next :: binary>>)
      input.buffers(rest)
    end

    def has_bytes_buffered?(TestInput[current_buffer: buffer], bytes) when size(buffer) >= bytes do
      true
    end

    def has_bytes_buffered?(_, _), do: false
  end

  test "returns a line when so buffered" do
    reader = GmailSynchronize.Network.NetworkReader.new(input: TestInput.new(buffers: ["abcdefg\r\nfoo"]))
    {line, reader} = GmailSynchronize.Network.read_line(reader)
    assert line == "abcdefg"
    assert GmailSynchronize.Network.BufferManagement.buffer(reader.input) == "foo"
  end

  test "returns a line after rebuffering" do
    reader = GmailSynchronize.Network.NetworkReader.new(input: TestInput.new(buffers: ["abcde", "fg\r\nfoo"]))
    {line, reader} = GmailSynchronize.Network.read_line(reader)
    assert line == "abcdefg"
    assert GmailSynchronize.Network.BufferManagement.buffer(reader.input) == "foo"
  end

  test "returns N bytes in a buffer of M>=N bytes" do
    reader = GmailSynchronize.Network.NetworkReader.new(input: TestInput.new(buffers: ["foobar"]))
    {n_bytes, reader} = GmailSynchronize.Network.read_n_bytes(reader, 5)
    assert n_bytes == "fooba"
    assert GmailSynchronize.Network.BufferManagement.buffer(reader.input) == "r"
  end

  test "returns N bytes even when it has to re-fill the buffer" do
    reader = GmailSynchronize.Network.NetworkReader.new(input: TestInput.new(buffers: ["f", "o", "o", "bar"]))
    {n_bytes, reader} = GmailSynchronize.Network.read_n_bytes(reader, 5)
    assert n_bytes == "fooba"
    assert GmailSynchronize.Network.BufferManagement.buffer(reader.input) == "r"
  end
end