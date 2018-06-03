
**medv 0.1 Mai 2018**
**Mind Engineering Docker VPS**
*by Mind.Engineering*
*https://mind.engineering/*
 
 

 

## 1. USAGE


Usage: medv option1 -arguments --subarguments"

    --v, --version                            show version
    --h, --help                               show help
    docker -i                                 install docker system with composer, portainer and nginx-proxy
	docker -yml --list                        list of yml files
	docker -yml --update                      update yml files
	docker -c domainename.tld yml             create dockers based on docker-compose from yml with specific domaine
	docker -b -s domainename.tld              create backup from specific domainename.tld with a crontab
	docker -b -s --list domainename.tld       list a crontab file from specific domainename.tld
	docker -b -s --add domainename.tld        add a crontab from specific domainename.tld
	docker -b -s --delete domainename.tld     delete a crontab from specific domainename.tld
	docker -r domainename.tld --list          list of backups loaded for specific domainename.tld
	docker -r domainename.tld backupfile      restore website volumes for specific domaiename.tld from specific backupfile
	docker -rm domainename.tld                remove dockers, volumes, backup and configuration for specific domainename.tld
	docker -start domainename.tld             start specific domainename.tld
	docker -stop domainename.tld              stop specific domainename.tld
	docker -log --view                        read docker log file
	docker -log --trancate                    trancate docker log file
	docker -config --view                     read medv docker config file
	docker -config --edit                     edit medv docker config file
	docker -u --all                           remove all


## 2. BUILDING .DEB PACKAGE

    sudo apt-get install dh-make devscripts
    cd medv-0.1/
    chmod u+x medv
    dh_make --indep --createorig
    grep -v makefile debian/rules > debian/rules.new
    mv debian/rules.new debian/rules
    echo medv usr/bin > debian/install
    echo "1.0" > debian/source/format
    rm debian/*.ex
    debuild -us -uc
    cd ..
    sudo dpkg -i medv_0.1-1_all.deb #for installing program
    sudo dpkg -r medv #for removing program
