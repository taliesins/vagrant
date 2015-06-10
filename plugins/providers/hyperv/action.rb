require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module HyperV
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use action_halt
            b2.use action_start
          end
        end
      end

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b1.use Call, DestroyConfirm do |env2, b2|
              if !env2[:result]
                b2.use MessageWillNotDestroy
                next
              end

              b2.use ConfigValidate
              b2.use StopInstance
              b2.use DeleteVM
              b2.use PrepareNFSValidIds
              b2.use SyncedFolderCleanup
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use Call, GracefulHalt, :off, :running do |env2, b3|
              if !env2[:result]
                b3.use StopInstance
              end
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use Call, IsState, :running do |env1, b3|
              if !env1[:result]
                b3.use Message, I18n.t("vagrant_hyperv.message_not_running")
                next
              end

              b3.use PrepareNFSValidIds
              b3.use SyncedFolderCleanup
              b3.use PrepareNFSSettings

              # Provision will create shared folders if necessary
              b3.use Provision

              b3.use SyncedFolders
            end
          end
        end
      end

      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b1|
            if env[:result]
              b1.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b1.use ResumeVM
            b1.use WaitForIPAddress
            b1.use WaitForCommunicator, [:running]
          end
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :running do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant_hyperv.message_already_running")
              next
            end

            b1.use Call, IsState, :paused do |env2, b2|
              if env2[:result]
                b2.use action_resume
                next
              end

              b2.use Network
              b2.use StartInstance
              b2.use WaitForIPAddress
              b2.use WaitForCommunicator, [:running]
              b2.use SetHostname
              
              b2.use PrepareNFSValidIds
              b2.use SyncedFolderCleanup
              b2.use PrepareNFSSettings

              # Provision will create shared folders if necessary
              b2.use Provision

              b2.use SyncedFolders
            end
          end
        end
      end

      # This is the action that is called to sync folders to a running
      # machine without a reboot.
      def self.action_sync_folders
        Vagrant::Action::Builder.new.tap do |b|
          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup

          b.use PrepareNFSSettings
          b.use SyncedFolders
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckEnabled
          b.use HandleBox
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Import
            end

            b1.use action_start
          end
        end
      end

      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use Call, IsState, :running do |env1, b3|
              if !env1[:result]
                b3.use Message, I18n.t("vagrant_hyperv.message_not_running")
                next
              end

              b3.use SSHExec
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use Call, IsState, :running do |env1, b3|
              if !env1[:result]
                b3.use Message, I18n.t("vagrant_hyperv.message_not_running")
                next
              end

              b3.use SSHRun
            end
          end
        end
      end

      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("vagrant_hyperv.message_not_created")
              next
            end

            b2.use SuspendVM
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :CheckEnabled, action_root.join("check_enabled")
      autoload :DeleteVM, action_root.join("delete_vm")
      autoload :Import, action_root.join("import")
      autoload :Network, action_root.join("network")
      autoload :IsWindows, action_root.join("is_windows")
      autoload :ReadState, action_root.join("read_state")
      autoload :ResumeVM, action_root.join("resume_vm")
      autoload :StartInstance, action_root.join('start_instance')
      autoload :PrepareNFSValidIds, action_root.join("prepare_nfs_valid_ids")
      autoload :PrepareNFSSettings, action_root.join("prepare_nfs_settings")
      autoload :StopInstance, action_root.join('stop_instance')
      autoload :SuspendVM, action_root.join("suspend_vm")
      autoload :WaitForIPAddress, action_root.join("wait_for_ip_address")
      autoload :MessageWillNotDestroy, action_root.join("message_will_not_destroy")
    end
  end
end
