module VagrantPlugins
  module GuestWindows
    module Cap
      class NFSClient
        def self.nfs_client_installed(machine)
          machine.communicate.test("if (Get-Command | ?{$_.Name -eq 'Get-NfsShare'}){ Write-Host 0 } else { Write-Host 1}")
        end
      end
    end
  end
end
