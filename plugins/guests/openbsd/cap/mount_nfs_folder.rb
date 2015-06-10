module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            if machine.communicate.test("if mount | grep #{opts[:guestpath]} > /dev/null; then exit 1; else exit 0; fi")
              machine.communicate.sudo("mkdir -p #{opts[:guestpath]}")
              machine.communicate.sudo("mount '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'")
            end
          end
        end
      end
    end
  end
end
