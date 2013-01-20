# defmodule Mix.Tasks.Compile.Erlang do
#   use Mix.Task

#   @hidden true
#   @shortdoc "Compile Erlang source files"

#   def run(_) do
#     project      = Mix.project
#     compile_exts = [:erl]
#     to_compile = Mix.Utils.extract_files(["imap_parser"], compile_exts)

#     compile_files(to_compile, project[:compile_path])
#   end

#   defp compile_files(to_compile, compile_path) do
#     compile_one = function do
#                     f ->
#                       IO.puts "Compiling #{f}"
#                       {:ok, _} = :compile.file(Kernel.binary_to_list(f))
#                   end
#     Enum.each to_compile, compile_one
#   end
# end

# defmodule Mix.Tasks.Compile.Imapparse do
#   @shortdoc "Compiles the imap parser and lexer"

#   def run(_) do
#     IO.puts "Compiling Lexer imap.peg"
#     :ok = :neotoma.file('imap_parser/imap.peg')
#   end
# end

defmodule GmailSynchronize.Mixfile do
  use Mix.Project

  def project do
    [ app: :gmail_synchronize,
      version: "0.0.1",
      deps: deps,
      compilers: [:elixir, :app],
      source_paths: ["lib"]
    ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
     #{:neotoma, "1.5.1", git: "https://github.com/seancribbs/neotoma.git"}
    ]
  end
end
