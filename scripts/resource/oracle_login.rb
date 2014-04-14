# oracle_login.rb
# Author: nebulus

<ruby>

hosts = {}
host_id_to_ip = {}

# map hosts ip to host_id

begin
	framework.db.hosts.each do |host|
		# don't really like having to do that but only way I could tie them together as notes were missing ip
		host_id_to_ip[host.id] = host.address
	end
	rescue ActiveRecord::ConnectionNotEstablished
		puts "DB not connected..."
# Uncomment if you want auto-reconnect and retry (on really large scans the db connector can time out)
#		self.run_single('db_connect <creds>')
#		puts "trying again..."
#		retry

end

begin
	framework.db.notes.each do |note|
		if ( note.ntype == 'oracle_sid' )
			data = note.data
			if(data =~ /PORT=(\d+), SID=(\S*)$/)
				ip = host_id_to_ip[note.host_id]
				port = "#{$1}"
				sid = "#{$2}"
				if(sid != '')
					hosts["#{ip}"] = {'RPORT' => port, 'SID' => sid}
				end
			else
				puts "Bad regexp (#{note.inspect})"
			end
		end
	end
	rescue ActiveRecord::ConnectionNotEstablished
		puts "DB not connected..."
# Uncomment if you want auto-reconnect and retry (on really large scans the db connector can time out)
#		self.run_single('db_connect <creds>')
#		puts "trying again..."
#		retry
end

self.run_single("use auxiliary/admin/oracle/oracle_login")

hosts.each do |rhost|
	begin
		self.run_single("set RHOST #{rhost[0]}")
		self.run_single("set RPORT #{rhost[1]['RPORT']}")
		self.run_single("set SID #{rhost[1]['SID']}")
		self.run_single('exploit')
		puts "DB not connected..."
# Uncomment if you want auto-reconnect and retry (on really large scans the db connector can time out)
#		self.run_single('db_connect <creds>')
#		puts "trying again..."
#		retry
	end

end
</ruby>

