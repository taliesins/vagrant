require "vagrant/util/retryable"

module VagrantPlugins
  module GuestWindows
    module Cap
      class MountNFS
        extend Vagrant::Util::Retryable

        def self.mount_nfs_folder(machine, ip, folders)

          mount_command = "Import-Module Servermanager;Add-WindowsFeature NFS-Client;Exit 0;"
          retryable(on: Vagrant::Errors::LinuxNFSMountFailed, tries: 8, sleep: 3) do
            machine.communicate.sudo(mount_command, error_class: Vagrant::Errors::LinuxNFSMountFailed)
          end

          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(:shell_expand_guest_path, opts[:guestpath])

            # Mount
            hostpath = opts[:hostpath].dup
            hostpath.gsub!("'", "'\\\\''")

            mount_shared_folder(machine, hostpath, expanded_guest_path, "\\\\#{ip}\\")
          end
        end

        protected

        def self.mount_shared_folder(machine, name, guestpath, vm_provider_unc_base)
          name = name.gsub(/[\/\/]/,'_').sub(/^_/, '')

          path = File.expand_path("../../scripts/mount_volume.ps1", __FILE__)
          script = Vagrant::Util::TemplateRenderer.render(path, options: {
            mount_point: guestpath,
            share_name: name,
            vm_provider_unc_path: vm_provider_unc_base + name,
          })

          machine.communicate.execute(script, shell: :powershell)
        end
      end
    end
  end
end
