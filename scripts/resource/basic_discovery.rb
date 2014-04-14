# portscan.rb
# Author: m-1-k-3 (Web: http://www.s3cur1ty.de / Twitter: @s3cur1ty_de)

# This Metasploit RC-File could be used to portscan the network via nmap or via the internal portscanner module
# it also uses the udp_sweep module and some more metasploit modules for getting more infos ans vulns
# RHOSTS is used from the global datastore
# VERBOSE is used from the global datastore
# you can define your own Nmap options via the global NMAPOPTS variable

<ruby>
maxjobs = 8			#throttling if we get too much jobs
versionscanners = 1		# set to 0 if we should not use the metasploit _version modules

#set ports for Metasploit portscanner (change this for your needs):
ports = "7,21,22,23,25,43,50,53,67,68,79,80,109,110,111,123,135,137,138,139,143,161,264,265,389,443,445,500,631,901,995,1241,1352,1433,1434,1521,1720,1723,3306,3389,3780,4662,5800,5801,5802,5803,5900,5901,5902,5903,6000,6666,8000,8080,8443,10000,10043,27374,27665"

if (framework.datastore['RHOSTS'] == nil)
	print_line("you have to set RHOSTS globally ... exiting")
	return
end

if (framework.datastore['NMAPOPTS'] != nil)
	nmapopts = framework.datastore['NMAPOPTS']
else
	#default-settings
	nmapopts = "-PN -P0 -O -sSV"
end

#we look in the global datastore for a global VERBOSE option and use it
if (framework.datastore['VERBOSE'] == "true")
	verbose = 1
else
	verbose = 0
end

#default to 15 Threads
if (framework.datastore['THREADS'] == nil)
	run_single("setg THREADS 15")
end

#default usage of nmap as portscanner
if (framework.datastore['NMAP'] == nil or framework.datastore['NMAP'] == "true")
	nmap = 1
else
	nmap = 0
end

# Test and see if we have a database connected
begin
	framework.db.hosts
rescue ::ActiveRecord::ConnectionNotEstablished
	print_error("Database connection isn't established")
	return
end

def jobwaiting(maxjobs,verbose)	#thread handling for poor guys
	while(framework.jobs.keys.length >= maxjobs)
		::IO.select(nil, nil, nil, 2.5)
		if(verbose == 1)
			print_error("waiting for finishing some modules... active jobs: #{framework.jobs.keys.length} / threads: #{framework.threads.length}")
		end
	end
end

def infos(serv,host)
	print_line("")
	print_line("====================================")
	print_line("IP: #{host.address}")
	print_line("OS: #{host.os_name}")
	print_line("Servicename: #{serv.name}")
	print_line("Service Port: #{serv.port.to_i}")
	print_line("Service Protocol: #{serv.proto}")
	print_line("====================================")
	print_line("")
end

print_line("")
print_line("============================================")
print_line("starting discovery scanners ... stage 1")
print_line("============================================")
print_line("")

print_line("")
print_line("starting portscanners ...")
print_line("")
print_line("udp_sweep")
run_single("use auxiliary/scanner/discovery/udp_sweep")
run_single("run -j")

if ( nmap == 1 )
	print_line("Module: db_nmap")
	if (verbose == 1)
		print_line("Using Nmap with the following options: -v -n #{nmapopts} #{framework.datastore['RHOSTS']}")
		run_single("db_nmap -v -n #{nmapopts} #{framework.datastore['RHOSTS']}")
	else
		print_line("Using Nmap with the following options: -n #{nmapopts} #{framework.datastore['RHOSTS']}")
		run_single("db_nmap -n #{nmapopts} #{framework.datastore['RHOSTS']}")
	end
else
	print_line("Module: portscan/tcp")
	run_single("use auxiliary/scanner/portscan/tcp")
	run_single("set PORTS #{ports}")
	run_single("run -j")
end

print_line("")
print_line("============================================")
print_line("starting discovery scanners ... stage 2")
print_line("============================================")
print_line("")

run_single("unsetg RHOSTS") # we dont need it anymore 

framework.db.workspace.hosts.each do |host|
	host.services.each do |serv|
		next if not serv.host
		next if (serv.state != ServiceState::Open)
		#next if (serv.name =~ /smb/ or serv.name =~ /microsoft-ds/ or serv.name =~ /netbios/ or serv.port == 445 or serv.port == 139 or serv.port == 137 or serv.name =~ /smtp/ or serv.port == 25 or serv.name =~ /snmp/ or serv.port == 161 or serv.name =~ /ssh/ or serv.port == 22 or serv.name =~ /telnet/ or serv.port == 23)
		if (serv.name =~ /smb/ or serv.name =~ /microsoft-ds/ or serv.name =~ /netbios/ or serv.port == 445 or serv.port == 139 or serv.port == 137)
			if(serv.port == 445)
				if(versionscanners == 1 or serv.name == nil)
					print_line("Module: smb-version")
					run_single("use auxiliary/scanner/smb/smb_version")
					if(verbose == 1)
						infos(serv,host)
					end
					run_single("set RHOSTS #{host.address}")
					if(verbose == 1)
						run_single("set VERBOSE true")
						run_single("run -j")
					else
						run_single("run -j -q")
					end
					jobwaiting(maxjobs,verbose)
				end
			end

			print_line("Module: smb2")
			run_single("use auxiliary/scanner/smb/smb2")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: nbname")
			run_single("use auxiliary/scanner/netbios/nbname")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: smb_enumshares")
			run_single("use auxiliary/scanner/smb/smb_enumshares")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: smb_enumusers")
			run_single("use auxiliary/scanner/smb/smb_enumusers")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: smb_enumusers_domain")
			run_single("use auxiliary/scanner/smb/smb_enumusers_domain")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: smb_lookupsid")
			run_single("use auxiliary/scanner/smb/smb_lookupsid")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /smtp/ or serv.port == 25)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: smtp_version")
				run_single("use auxiliary/scanner/smtp/smtp_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end

			print_line("Module: smtp_enum")
			run_single("use auxiliary/scanner/smtp/smtp_enum")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /snmp/ or serv.port == 161)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: aix_version")
				run_single("use auxiliary/scanner/snmp/aix_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end

			print_line("Module: snmp_enumshares")
			run_single("use auxiliary/scanner/snmp/snmp_enumshares")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: snmp_enumusers")
			run_single("use auxiliary/scanner/snmp/snmp_enumusers")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: snmp_enum")
			run_single("use auxiliary/scanner/snmp/snmp_enum")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /ssh/ or serv.port == 22)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: ssh_version")
				run_single("use auxiliary/scanner/ssh/ssh_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end

		if (serv.name =~ /telnet/ or serv.port == 23)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: telnet_version")
				run_single("use auxiliary/scanner/telnet/telnet_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end

			print_line("Module: telnet_encrypt_overflow")
			run_single("use auxiliary/scanner/telnet/telnet_encrypt_overflow")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /imap/ or serv.port == 143)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: imap_version")
				run_single("use auxiliary/scanner/imap/imap_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end

		if (serv.name =~ /pop3/ or serv.port == 110)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: pop3_version")
				run_single("use auxiliary/scanner/pop3/pop3_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end

		if (serv.name =~ /http/ or serv.port == 80 or serv.port == 443)
			
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: http_version")
				run_single("use auxiliary/scanner/http/http_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if (serv.name =~ /https/ or serv.port == 443)
					run_single("set SSL true")
				else
					run_single("set SSL false")
				end
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end

			print_line("Module: open_proxy")
			run_single("use auxiliary/scanner/http/open_proxy")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: svn_scanner")
			run_single("use auxiliary/scanner/http/svn_scanner")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: webdav_scanner")
			run_single("use auxiliary/scanner/http/webdav_scanner")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: http_put")
			run_single("use auxiliary/scanner/http/http_put")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: cisco_device_manager")
			run_single("use auxiliary/scanner/http/cisco_device_manager")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
			print_line("Module: cisco_ios_auth_bypass")
			run_single("use auxiliary/scanner/http/cisco_ios_auth_bypass")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: vmware_server_dir_trav")
			run_single("use auxiliary/scanner/http/vmware_server_dir_trav")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if (serv.name =~ /https/)
				run_single("set SSL true")
			else
				run_single("set SSL false")
			end
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /ftp/ or serv.port == 21)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: ftp_version")
				run_single("use auxiliary/scanner/ftp/ftp_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end

			print_line("Module: ftp-anonymous")
			run_single("use auxiliary/scanner/ftp/anonymous")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)

			print_line("Module: titanftp_x.rb_traversal")
			run_single("use auxiliary/admin/ftp/titanftp_x.rb_traversal")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOST #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /mssql/ or serv.name =~ /ms-sql/ or serv.port == 1434 or serv.port == 1433)
			print_line("Module: mssql_ping")
			run_single("use auxiliary/scanner/mssql/mssql_ping")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /postgre/ or serv.port == 5432)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: postgres_version")
				run_single("use auxiliary/scanner/postgres/postgres_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end

		if (serv.name =~ /mysql/ or serv.port == 3306)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: mysql_version")
				run_single("use auxiliary/scanner/mysql/mysql_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end
		if (serv.name =~ /oracle/ or serv.port == 1521)
			if(versionscanners == 1 or serv.name == nil)
				print_line("Module: tnslsnr_version")
				run_single("use auxiliary/scanner/oracle/tnslsnr_version")
				if(verbose == 1)
					infos(serv,host)
				end
				run_single("set RPORT #{serv.port}")
				run_single("set RHOSTS #{host.address}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(maxjobs,verbose)
			end
		end
			
		if (serv.port == 7777)
			print_line("Module: energizer_duo_detect")
			run_single("use auxiliary/scanner/backdoor/energizer_duo_detect")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end

		if (serv.name =~ /vnc/ or serv.port == 5900)
			print_line("Module: vnc_none_auth")
			run_single("use auxiliary/scanner/vnc/vnc_none_auth")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end
		if (serv.port == 6000)
			print_line("Module: open_x11")
			run_single("use auxiliary/scanner/x11/open_x11")
			if(verbose == 1)
				infos(serv,host)
			end
			run_single("set RPORT #{serv.port}")
			run_single("set RHOSTS #{host.address}")
			if(verbose == 1)
				run_single("set VERBOSE true")
				run_single("run -j")
			else
				run_single("run -j -q")
			end
			jobwaiting(maxjobs,verbose)
		end
	end
	run_single("back")
end
</ruby>
