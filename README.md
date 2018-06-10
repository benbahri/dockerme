	 ____                    __
	/\  _`\                 /\ \                     /'\_/`\
	\ \ \/\ \    ___     ___\ \ \/'\      __   _ __ /\      \     __
	 \ \ \ \ \  / __`\  /'___\ \ , <    /'__`\/\`'__\ \ \__\ \  /'__`\
	  \ \ \_\ \/\ \L\ \/\ \__/\ \ \\`\ /\  __/\ \ \/ \ \ \_/\ \/\  __/
	   \ \____/\ \____/\ \____\\ \_\ \_\ \____\\ \_\  \ \_\\ \_\ \____\
	    \/___/  \/___/  \/____/ \/_/\/_/\/____/ \/_/   \/_/ \/_/\/____/

	
	DockerME V0.4 Mai 2018
	Docker Hosting Tools
	by Mind.Engineering
	https://mind.engineering/
	Works only on Ubuntu 16.04.4 LTS




## 1. USAGE
	Usage: dockerme -argument option1 option2 --subarguments          
           
    dockerme -i                                 install docker system with composer, portainer and nginx-proxy          
    dockerme -yml --list                        list of yml files          
    dockerme -yml --update                      update yml files          
    dockerme -c domainename.tld yml             create dockers based on docker-compose from yml with specific domaine          
    dockerme -c domainename.tld yml --local     create dockers based on docker-compose from yml with specific domaine with local entry in /etc/host          
    dockerme -b domainename.tld                 create backup from specific domainename.tld          
    dockerme -b domainename.tld ndays --older   create backup from specific domainename.tld and delete backups older than ndays          
    dockerme -b domainename.tld --list          list backup files for specific domainename.tld
    dockerme -b -s domainename.tld              create backup from specific domainename.tld with a crontab
    dockerme -b -s domainename.tld --list       list a crontab file from specific domainename.tld
    dockerme -b -s domainename.tld --add        add a crontab from specific domainename.tld
    dockerme -b -s domainename.tld --delete    delete a crontab from specific domainename.tld          
    dockerme -r domainename.tld backupfile      restore website volumes for specific domaiename.tld from specific backupfile          
    dockerme -rm domainename.tld                remove dockers, volumes, backup and configuration for specific domainename.tld          
    dockerme -start domainename.tld             start specific domainename.tld          
    dockerme -stop domainename.tld              stop specific domainename.tld          
    dockerme -log --view                        read docker log file          
    dockerme -log --trancate                    trancate docker log file          
    dockerme -auditor --dbfs                    Lunch Docker Brech For Security auditing tools          
    dockerme -auditor --lynis                   Lunch Lynis auditing tools          
    dockerme -u --all                           remove all


## 2. BUILDING .DEB PACKAGE

    sudo apt-get install dh-make devscripts
    cd dockerme-0.1/
    chmod u+x dockerme
    dh_make --indep --createorig
    grep -v makefile debian/rules > debian/rules.new
    mv debian/rules.new debian/rules
    echo dockerme usr/bin > debian/install
    echo "1.0" > debian/source/format
    rm debian/*.ex
    debuild -us -uc
    cd ..
    sudo dpkg -i dockerme_0.1-1_all.deb #for installing program
    sudo dpkg -r dockerme #for removing program
