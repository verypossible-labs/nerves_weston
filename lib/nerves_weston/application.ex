defmodule NervesWeston.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @tty 1
  @xdg_runtime_dir "/tmp/xdg"

  def start(_type, _args) do
    opts = Application.get_all_env(:nerves_weston)

    config = opts[:config] || Application.app_dir(:nerves_weston, "priv/weston.ini")
    tty = opts[:tty] || @tty
    extra_args = opts[:extra_args] || []
    xdg_runtime_dir = opts[:xdg_runtime_dir] || @xdg_runtime_dir
    env = [{"XDG_RUNTIME_DIR", xdg_runtime_dir}]

    init(xdg_runtime_dir)

    children = [
      # Starts a worker by calling: NervesWeston.Worker.start_link(arg)
      {MuonTrap.Daemon,
       ["weston", ["--tty=#{tty}", "--config=#{config}"] ++ extra_args, [env: env]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesWeston.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init(xdg_runtime_dir) do
    :os.cmd('udevd -d')
    :os.cmd('udevadm trigger --type=subsystems --action=add')
    :os.cmd('udevadm trigger --type=devices --action=add')
    :os.cmd('udevadm settle --timeout=30')

    File.mkdir(xdg_runtime_dir)
    stat = File.stat!(xdg_runtime_dir)
    File.write_stat(xdg_runtime_dir, %{stat | mode: 33216})
  end
end
