require 'shellwords'
require_relative '../classes/pull_widget'

class NetworkConnectivity < PullWidget

  def initialize(*args)
    super

    @update_interval = 5
  end

  def update

    host = @config['host']
    timeout = @config['timeout'] || 1000
    remote = @config['remote'] || nil

    ipv4_host = @config['ipv4_host'] || '8.8.8.8'
    ipv6_host = @config['ipv6_host'] || '2001:4860:4860::8888'

    ipv4 = %W{ping -c1 #{ipv4_host}}
    ipv6 = %W{ping6 -c1 #{ipv6_host}}

    keyfile = Tempfile.new('NetworkConnectivity')
    begin

      if (r = @config['remote']) and r['key_base64'] and r['user'] and r['host']
        keyfile << Base64.decode64(r['key_base64'])
        keyfile.close
        remote = [ 'ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'ConnectTimeout=3', '-i' << keyfile.path,
          '%s@%s' % [ r['user'], r['host'] ] ]
      end

      cmd_v4 = Shellwords.join(remote ? remote.clone.concat(ipv4) : ipv4 )
      cmd_v6 = Shellwords.join(remote ? remote.clone.concat(ipv6) : ipv6 )

      result_v4 = self.exec_with_timeout(cmd_v4, timeout / 1000)
      result_v6 = self.exec_with_timeout(cmd_v6, timeout / 1000)
    ensure
      keyfile.close
      keyfile.unlink
    end

    latency_v4 = !result_v4[:hit_timeout] ? self.extract_latency(result_v4[:data]) : 0
    latency_v6 = !result_v6[:hit_timeout] ? self.extract_latency(result_v6[:data]) : 0

    timeout_error_v4 = result_v4[:hit_timeout]
    timeout_error_v6 = result_v6[:hit_timeout]

    test_error_v4 = !timeout_error_v4 && result_v4[:data].length == 0
    test_error_v6 = !timeout_error_v6 && result_v6[:data].length == 0

    connectivity_error_v4 = !timeout_error_v4 && !test_error_v4 && latency_v4 == 0
    connectivity_error_v6 = !timeout_error_v6 && !test_error_v6 && latency_v6 == 0

    {
      ipv4: {
        host: ipv4_host,
        error: test_error_v4 || connectivity_error_v4 || timeout_error_v4,
        timeout_error_v4: timeout_error_v4,
        test_error: test_error_v4,
        connectivity_error: connectivity_error_v4,
        latency: latency_v4
      },
      ipv6: {
        host: ipv6_host,
        error: test_error_v4 || connectivity_error_v4 || timeout_error_v4,
        timeout_error_v4: timeout_error_v4,
        test_error: test_error_v4,
        connectivity_error: connectivity_error_v4,
        latency: latency_v6
      }
    }
  end

  def extract_latency(ping_output)
    res = ping_output.match(/time=([0-9\.]+)/)
    res ? res[1].to_f : 0
  end

  def exec_with_timeout(cmd, timeout)
    # http://stackoverflow.com/a/31465248/1387396

    hit_timeout = false

    begin
      # stdout, stderr pipes
      rout, wout = IO.pipe
      rerr, werr = IO.pipe
      stdout, stderr = nil

      pid = Process.spawn(cmd, pgroup: true, :out => wout, :err => werr)

      Timeout.timeout(timeout) do
        Process.waitpid(pid)

        # close write ends so we can read from them
        wout.close
        werr.close

        stdout = rout.readlines.join
        stderr = rerr.readlines.join
      end

    rescue Timeout::Error
      Process.kill(-9, pid)
      Process.detach(pid)
      hit_timeout = true
    ensure
      wout.close unless wout.closed?
      werr.close unless werr.closed?
      # dispose the read ends of the pipes
      rout.close
      rerr.close
    end

    {
      hit_timeout: hit_timeout,
      data: stdout
    }
   end

end