require "vagrant"

module VagrantPlugins
  module HostWindows
    class Plugin < Vagrant.plugin("2")
      name "Windows host"
      description "Windows host support."

      host("windows") do
        require_relative "host"
        Host
      end

      host_capability("windows", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("windows", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end

      host_capability("windows", "nfs_export") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("windows", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("windows", "nfs_prune") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
