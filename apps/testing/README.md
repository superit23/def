# Testing

**Inspired by (and derived from) github.com/sschneider1207/distributed_test (MIT)**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `testing` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:testing, "~> 0.1.0"}]
    end
    ```

  2. Ensure `testing` is started before your application:

    ```elixir
    def application do
      [applications: [:testing]]
    end
    ```
