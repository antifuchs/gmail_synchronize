defmodule GmailSynchronize.IMAP do
  defrecord State, buffer: nil, literal_bytes: 0, reader: nil

  defmodule StringSlice do
    def next_line(<< binary:: binary >>) do
      [line, rest] = String.split(binary, "\r\n", global: false)
      {line, rest}
    end

    def next_line(State[] = state) do
      {line, rest} = next_line(state.buffer)
      {line, state.buffer(rest)}
    end

    def read_literal(bytes, binary) when size(binary) >= bytes do
      << literal :: [size(bytes), binary], rest :: binary>> = binary
      {literal, rest}
    end

    def read_literal(State[buffer: buffer, literal_bytes: literal_bytes] = state) when size(buffer) >= literal_bytes do
      {literal, rest} = read_literal(literal_bytes, buffer)
      {literal, state.buffer(rest).literal_bytes(0)}
    end

  end


end