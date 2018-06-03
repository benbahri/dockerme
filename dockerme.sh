#!/bin/bash
function DOCKERME_GLOBAL_VARS(){
	DOCKER_LOG="/var/log/dockerme";
	DOCKER_LOG_TMP="/var/log/.dockerme";
	d=`date +"%Y-%m-%d %T"`
	D=`date "+%Y%m%d%H%M%S"`
}
function DOCKERME_PROGRESS(){

	function ceiling_divide {
	  ((result=($1 + ($2 - 1))/$2))
	  echo $result
	}

	function string_of_length {
	  # Space-separate a sequene of N numbers and
	  # replace each number with the wanted character
	  seq $1 | tr '\n' ' ' | perl -pe "s/[0-9]+ /$2/g"
	}

	function move_up {
	  # The escape sequence \033[<number>A moves the cursor <number> lines up
	  # The carriage return '\r' moves the cursor to the start of the line
	  echo -en "\033[${1}A\r"
	}

	function move_down {
	  # The escape sequence \033[<number>B moves the cursor <number> lines down
	  # and the carriage return '\r' moves the cursor to the far left again (communism)
	  echo -en "\033[${1}B\r"
	}

	function print_progress {
	  if [ $1 -gt $2 ]; then
	    return 1
	  fi

	  # The indicator (current_steps/total_steps) width is two times the total
	  # number, since ultimately we'll want to print "(total/total)", plus 3 for
	  # the parantheses and forward slash
	  indicator_width=$(echo $2 | awk '{ print length($1) * 2 + 3}')

	  # printf allows us to right justify the text according to the maximum width
	  indicator=$(printf "%${indicator_width}s" "($1/$2)")
	  indicator="\033[${progress_indicator_format}m${indicator}\033[0m"

	  percent=$(echo "(100.0 * $1) / $2" | bc)
	  percent="\033[${progress_percent_format}m[${percent}%]\033[0m"

	  # PROGRESS in bold (usually displayed as bright formats)
	  echo -en "\033[1mPROGRESS\033[0m: $indicator $3 $percent"
	}
	if [ -z $PROGRESS_NUMBER_OF_STEPS ]; then
	  echo -e "\033[31m[ERROR]\033[0m \$PROGRESS_NUMBER_OF_STEPS was not set!"
	  exit -1
	fi
	progress_number_of_steps=$PROGRESS_NUMBER_OF_STEPS
	progress_width=${PROGRESS_WIDTH:-$PROGRESS_NUMBER_OF_STEPS}
	progress_indicator_format=${PROGRESS_INDICATOR_FORMAT:-31}
	progress_percent_format=${PROGRESS_PERCENT_FORMAT:-35}
	progress_symbol=${PROGRESS_SYMBOL:-'\xE2\x96\xAC'}
	progress_symbol=$(echo -en "$progress_symbol")
	progress_format=${PROGRESS_FORMAT:-32}
	progress_fill_symbol=${PROGRESS_FILL_SYMBOL:-"$progress_symbol"}
	progress_fill_format=${PROGRESS_FILL_FORMAT:-0}
	progress_divisor=$(ceiling_divide $progress_number_of_steps $progress_width)
	progress_step_size=$(ceiling_divide $progress_width $progress_number_of_steps)
	progress_unit=$(string_of_length $progress_step_size "$progress_symbol")
	progress_unit=$(echo -en "\033[${progress_format}m$progress_unit\033[${progress_fill_format}m")
	progress_fill_unit=$(string_of_length $progress_step_size "$progress_fill_symbol")
	progress_line=$(string_of_length $progress_width "$progress_fill_symbol")
	progress_line="\033[${progress_fill_format}m${progress_line}\033[0m"
	progress_step=0
	progress_line_number=1
	progress_max_lines=$(tput lines)
	((progress_max_lines = progress_max_lines - 2))
	function progress_step {

	  # Don't overflow ...
	  if [ -z $PROGRESS_STICKY ] && [ $progress_line_number -ge $progress_max_lines ]; then
	    return 0
	  elif [ $progress_step -gt $progress_number_of_steps ]; then
	    return 0
	  fi

	  ((progress_step += 1))
	  ((remainder=progress_step % progress_divisor))

	  if [ $remainder -eq 0 ]; then
	    # Replace one unit of the filler with one unit of progress
	    progress_gsed_command="s/$progress_fill_unit/$progress_unit/"

	    # If the fill symbol equals the progress symbol, we need to specify after
	    # which match to start replacing, else we'll just match the first replacement
	    # we made (since we'd be replacing e.g. xxxx with \033[31mx\033[0mxxx which
	    # still contains x as the first text character, so next time we'd get
	    # \033[31m\033[31mx\033[0m\033[0m instead of replacing the next fill character)
	    if [ "$progress_fill_symbol" = "$progress_symbol" ]; then
	        ((progress_index = progress_step / progress_divisor))
	        progress_gsed_command="${progress_gsed_command}${progress_index}"
	    fi
	    progress_line="$(echo -e "$progress_line" | sed "$progress_gsed_command")"
	  fi

	  # We must always increment on the last step
	  if [ $progress_step -eq $progress_number_of_steps ]; then
	      ((progress_line_number += ${1:-1}))
	  # Dont' increment when we've reached the end of the terminal
	  elif [ $progress_line_number -lt $progress_max_lines ]; then
	    # If nothing is passed, we increment by one (default), else if it is
	    # -1, we do nothing (don't increment), else (if it's nonzero) we increment
	    # by the given amount.
	    if [ -z $1 ]; then
	      ((progress_line_number += 1))
	    elif [ $1 -ne -1 ]; then
	      ((progress_line_number += $1))
	    fi
	  fi

	  # Go back to the beginning of the line
	  move_up $progress_line_number
	  print_progress $progress_step $progress_number_of_steps "$progress_line"
	  move_down $progress_line_number
	}
	function progress_end {
	  if [ -z $PROGRESS_STICKY ] && [ $progress_line_number -ge $progress_max_lines ]; then
	    return 0
	  fi

	  progress_line="$(echo -en "$progress_line" | perl -pe 's/$(echo $progress_fill_symbol)/'$progress_symbol'/g')"
	  if [ $1 ]; then
	    ((progress_line_number += $1))
	  fi
	  move_up $progress_line_number
	  print_progress $progress_number_of_steps $progress_number_of_steps "$progress_line"
	  move_down $progress_line_number
	}
	function progress_start {
	  print_progress $progress_step $progress_number_of_steps "$progress_line"
	  echo ""
	}
	if [ -z $PROGRESS_DEFER ]; then
	  progress_start
	fi
}
function DOCKERME_INSTALL(){
	PROGRESS_STICKY=yes
	PROGRESS_WIDTH=100
	progress_max_lines=1
	PROGRESS_NUMBER_OF_STEPS=${1:-18}
	DOCKERME_PROGRESS
	for i in $(seq $PROGRESS_NUMBER_OF_STEPS); do
		if [[ $i -eq 1 ]]; then
			echo " * DOCKERME SETUP......................................................................................................[INITIALIZING]"
		elif [[ $i -eq 2 ]]; then
			apt-get update -y >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * SYSTEM UPDATE.......................................................................................................[OK]"
			else
				echo " * SYSTEM UPDATING.....................................................................................................[FAIL] CODE I2 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 3 ]]; then
			apt-get upgrade -y >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * SYSTEM UPGRADE......................................................................................................[OK]"
			else
				echo " * SYSTEM UPGRADING....................................................................................................[FAIL] CODE I3 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 4 ]]; then
			apt-get install git zip unzip >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * INSTALL git, zip & unzip............................................................................................[OK]"
				#exit
			else
				echo " * INSTALLING git, zip & unzip.........................................................................................[FAIL] CODE I4 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 5 ]]; then
			apt-get install -y apt-transport-https ca-certificates curl software-properties-common >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * INSTALL PACKAGE apt-transport-https, ca-certificates, curl, software-properties-common..............................[OK]"
			else
				echo " * INSTALLING PACKAGE apt-transport-https, ca-certificates, curl, software-properties-common...........................[FAIL] CODE I5, PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 6 ]]; then
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * DOWNLOAD DOCKER GNU PRIVACY GUARD (GPG).............................................................................[OK]"
			else
				echo " * DOWNLOADING DOCKER GNU PRIVACY GUARD (GPG)..........................................................................[FAIL] CODE I6, PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 7 ]]; then
			add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * ADD DOCKER REPOSITORY...............................................................................................[OK]"
			else
				echo " * ADDING DOCKER REPOSITORY............................................................................................[FAIL] CODE I7, PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi		
		elif [[ $i -eq 8 ]]; then
			apt-get update -y >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * SYSTEM UPDATE.......................................................................................................[OK]"
			else
				echo " * SYSTEM UPDATING.....................................................................................................[FAIL] CODE I8 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 9 ]]; then
			apt-get install -y docker-ce -y >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * INSTALL DOCKER-CE...................................................................................................[OK]"
			else
				echo " * INSTALLING DOCKER-CE................................................................................................[FAIL] CODE I9 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 10 ]]; then
			#apt-cache madison docker-ce
			#usermod -aG docker ${USER} >> DOCKER_LOG_TMP.log
			curl -L https://github.com/docker/compose/releases/download/1.21.0-rc1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * DOWNLOAD DOCKER-COMPOSE.............................................................................................[OK]"
			else
				echo " * DOWNLOAD DOCKER-COMPOSE.............................................................................................[FAIL] CODE I10 : PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 11 ]]; then
			chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * ADD EXECUTE PERMESSION TO DOCKER-COMPOSE............................................................................[OK]"
			else
				echo " * ADDING EXECUTE PERMESSION TO DOCKER-COMPOSE.........................................................................[FAIL] CODE I11: PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 12 ]]; then
			if [[ ! -d /var/dockerme ]]; then
				mkdir /var/dockerme >/dev/null 2>&1
				if [[ $? -eq 0 ]]; then
					echo " * CREATE MEDV DIRECTORY UNDER /var/dockerme...............................................................................[OK]"
				else
					echo " * CREATING MEDV DIRECTORY UNDER /var/dockerme.............................................................................[FAIL] CODE I12: PLEASE CHECK tmp logfile /var/log/dockerme.log"
	                #exit
	            fi
	        else
	        	echo " * TRYING TO CREATE /var/dockerme, BUT DIRECTORY ALRADY EXIST!.............................................................[WARNING]"
	        fi
	    elif [[ $i -eq 13 ]]; then
	    	cd /var/dockerme >/dev/null 2>&1
	    	rm -r yml >/dev/null 2>&1
	    	git clone http://cd4862abd5.mind.engineering/ayoubsakly/yml >/dev/null 2>&1
	    	if [ $? -eq 0 ]; then
	    		echo " * CLONE YML REPOSITORY FROM GIT SERVER................................................................................[OK]"
	    	else
	    		echo " * CLONING YML REPOSITORY FROM GIT SERVER..............................................................................[FAIL] CODE I13: PLEASE CHECK tmp logfile /var/log/dockerme.log"
	    		#exit
	    	fi
	    elif [[ $i -eq 14 ]]; then
			touch dockerme.conf  >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * CREATE CONFIGURATION FILE UNDER /var/dockerme/dockerme.conf..........................................................[OK]"
			else
				echo " * CREATING CONFIGURATION FILE UNDER /var/dockerme/dockerme.conf........................................................[FAIL] CODE I14: PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 15 ]]; then
			mkdir -p /home/dockerme_docker >/dev/null 2>&1
			echo "HOME_PATH_DIRECTORY=/home/dockerme-docker" >> dockerme.conf
			if [[ $? -eq 0 ]]; then
				echo " * SETUP HOME HOME_PATH_DIRECTORY UNDER /home/dockerme_docker..............................................................[OK]"
			else
				echo " * SETING UP HOME HOME_PATH_DIRECTORY UNDER /home/dockerme_docker..........................................................[FAIL] CODE I15: PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 16 ]]; then
			docker run --name nginx-proxy -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro -v nginx_data:/data -d jwilder/nginx-proxy >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * CREATE NGINX-PROXY CONTAINER........................................................................................[OK]"
			else
				echo " * CREATING NGINX-PROXY CONTAINER......................................................................................[FAIL] CODE I16: PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 17 ]]; then
			docker run --name portainer -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -d portainer/portainer >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				echo " * CREATE PORTAINER CONTAINER..........................................................................................[OK]"
			else
				echo " * CREATING PORTAINER CONTAINER........................................................................................[FAIL] CODE I17: PLEASE CHECK tmp logfile /var/log/dockerme.log"
				#exit
			fi
		elif [[ $i -eq 18 ]]; then
			echo " * DOCKERME SETUP...................................................................................................[COMPLETED]"     
		fi
	  progress_step
	done
}
