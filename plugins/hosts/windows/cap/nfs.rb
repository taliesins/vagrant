module VagrantPlugins
  module HostWindows
    module Cap
      class NFS
		ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
		OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      	def self.execute_powershell(path, options, &block)
	        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
	        path = lib_path.join(path).to_s.gsub("/", "\\")
	        options = options || {}
	        ps_options = []
	        options.each do |key, value|
	          ps_options << "-#{key}"
	          ps_options << "#{value}"
	        end

	        # Always have a stop error action for failures
	        ps_options << "-ErrorAction" << "Stop"

	        opts = { notify: [:stdout, :stderr, :stdin] }
	        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
	    end

      	def self.execute(path, options)
	        r = execute_powershell(path, options)
	        if r.exit_code != 0
	          raise Errors::PowerShellError,
	            script: path,
	            stderr: r.stderr
		    end

		    # We only want unix-style line endings within Vagrant
		    r.stdout.gsub!("\r\n", "\n")
		    r.stderr.gsub!("\r\n", "\n")

		    error_match  = ERROR_REGEXP.match(r.stdout)
		    output_match = OUTPUT_REGEXP.match(r.stdout)

		    if error_match
		      data = JSON.parse(error_match[1])

		      # We have some error data.
		      raise Errors::PowerShellError,
		        script: path,
		        stderr: data["error"]
		    end

		    # Nothing
		    return nil if !output_match
		    return JSON.parse(output_match[1])
		end
		
      	def self.nfs_export(environment, ui, id, ips, folders)
      		parameters = {}
	        parameters[:environment] = environment
	        parameters[:id] = id
	        parameters[:ips] = ips.to_json.gsub('"', '\"')
	        parameters[:folders] = folders.to_json.gsub('"', '\"')

	        results = execute("nfs_export.ps1", parameters)
	        folders.each { |id, opts| set_sharename(results['shares'], opts) }
        end

        def self.set_sharename(shares, opts)
        	share = shares.find{ |share| share['name'] == opts[:uuid]}
        	opts[:hostpath] = share['guestpath']
        end

        def self.nfs_installed(env)
        	parameters = {}
	        results = execute("nfs_installed.ps1", parameters)
	        supported = results["supported"]
	        supported
        end

		def self.nfs_prune(environment, ui, valid_ids)
			parameters = {}
	        parameters[:environment] = environment
	        parameters[:valid_ids] = valid_ids.to_json.gsub('"', '\"')

	        execute("nfs_prune.ps1", parameters)
		end

		def self.nfs_cleanup(id)
			parameters = {}
	        parameters[:id] = id

	        execute("nfs_cleanup.ps1", parameters)
		end
      end
    end
  end
end
