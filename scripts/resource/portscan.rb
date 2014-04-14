# portscan.rb
# Author: m-1-k-3 (Web: http://www.s3cur1ty.de / Twitter: @s3cur1ty_de)

# This Metasploit RC-File could be used to portscan the network via nmap or via the internal portscanner module 
# it also uses the udp_sweep module
# RHOSTS is used from the global datastore
# VERBOSE is used from the global datastore
# you can define your own Nmap options via the global NMAPOPTS variable

<ruby>
#set ports for Metasploit tcp-portscanner (change this for your needs):
ports = "7,21,22,23,25,43,50,53,67,68,79,80,109,110,111,123,135,137,138,139,143,161,264,265,389,443,445,500,631,901,995,1241,1352,1433,1434,1521,1720,1723,3306,3389,3780,4662,5800,5801,5802,5803,5900,5901,5902,5903,6000,6666,8000,8080,8443,10000,10043,27374,27665"

if (framework.datastore['RHOSTS'] == nil)
	print_status("you have to set RHOSTS globally ... exiting")
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
	verbose = 1 #true
else
	verbose = 0
end

if (framework.datastore['THREADS'] == nil)	#default to 100 Threads
	run_single("setg THREADS 100")
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

print_line("")
print_line("starting portscanners ...")
print_line("")
print_line("Module: udp_sweep")
run_single("use auxiliary/scanner/discovery/udp_sweep")
run_single("run -j")
run_single("back")

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
	run_single("back")
end
</ruby>
