require "log4r"

module VagrantPlugins
  module HyperV
    module Action
        class Network
            def initialize(app, env)
                @app = app
                @logger = Log4r::Logger.new("vagrant::hyperv::import")
            end

            def call(env)

                switches = env[:machine].provider.driver.execute("get_switches.ps1", {})
                raise Errors::NoSwitches if switches.empty?

                options = {
                    networks: "",
                    macs: "",
                    vlan: "",
                    VMId: ""
                }

                outswitches = []
                outmacs = []
                outvlan = []

                env[:machine].config.vm.networks.each do |type, opts|
                    next if type != :public_network && type != :private_network
                    
                    switchToFind = opts[:bridge]
                    switch = nil

                    if switchToFind
                        env[:ui].output "Looking for switch with name: #{switchToFind}"
                        switch = switches.find { |s| s["Name"].downcase == switchToFind.downcase }["Name"]
                        env[:ui].output "Found switch: #{switch}"
                    else
                        env[:ui].detail(I18n.t("vagrant_hyperv.choose_switch") + "\n ")
                        switches.each_index do |i|
                            switch = switches[i]
                            env[:ui].detail("#{i+1}) #{switch["Name"]}")
                        end
                        env[:ui].detail(" ")
                        
                        switch = nil
                        while !switch
                            switch = env[:ui].ask("What switch would you like to use? ")
                            next if !switch
                            switch = switch.to_i - 1
                            switch = nil if switch < 0 || switch >= switches.length
                        end
                        switch = switches[switch]["Name"]
                    end  

                    if opts[:mac]
                        outmacs << opts[:mac]
                    else
                        outmacs << "auto"
                    end

                    if opts[:vlan]
                        outvlan << opts[:vlan]
                    else
                        outvlan << "none"
                    end
                    
                    outswitches << switch
                end

                options[:networks] = "#{outswitches.join('|')}"
                options[:mac] = "#{outmacs.join("|")}"
                options[:vlan] = "#{outvlan.join("|")}"
                env[:machine].provider.driver.network(options)
                @app.call(env)
            end
        end

    end
  end
end