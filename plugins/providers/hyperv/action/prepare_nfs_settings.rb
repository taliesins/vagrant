require "vagrant/action/builtin/mixin_synced_folders"

module VagrantPlugins
  module HyperV
    module Action
      class PrepareNFSSettings
        include Vagrant::Action::Builtin::MixinSyncedFolders
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          @machine = env[:machine]

          opts = {
            cached: !!env[:synced_folders_cached],
            config: env[:synced_folders_config],
            disable_usable_check: !!env[:test],
          }
          folders = synced_folders(env[:machine], **opts)

          if folders.key?(:nfs)
            @logger.info("Using NFS, preparing NFS settings by reading host IP and machine IP")
            add_ips_to_env!(env)
          end

          @app.call(env)
        end

        # Extracts the proper host and guest IPs for NFS mounts and stores them
        # in the environment for the SyncedFolder action to use them in
        # mounting.
        #
        # The ! indicates that this method modifies its argument.
        def add_ips_to_env!(env)
          candidate_ips = env[:machine].provider.driver.load_host_ips()
          @logger.debug("Potential host IPs: #{candidate_ips.inspect}")
          host_ip = env[:machine].guest.capability(:choose_addressable_ip_addr, candidate_ips)
          if !host_ip
            raise Errors::NoHostIPAddr
          end

          env[:nfs_host_ip] = host_ip
          env[:nfs_machine_ip] = read_host_ip(env)[:host]
        end

        def read_host_ip(env)
          return nil if env[:machine].id.nil?

          # Get Network details from WMI Provider
          # Wait for 120 sec By then the machine should be ready
          host_ip = nil
          begin
            Timeout.timeout(120) do
            begin
              host_ip = env[:machine].provider.driver.read_guest_ip[0]
              sleep 10 if host_ip.empty?
              end while host_ip.empty?
            end
          rescue Timeout::Error
            @logger.info("Cannot find the IP address of the virtual machine")
          end
          return { host: host_ip } unless host_ip.nil?
        end
      end
    end
  end
end
