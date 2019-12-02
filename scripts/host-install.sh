install-julia-host() {
	guestdir=$(pwd)/../guest-tools
	jl=$1
	extra=$2
	if [ "$extra" = "" ];then 
		extra="0"
	fi
	juliabin=julia-${jl}.${extra}
	juliatgz=${juliabin}-linux-x86_64.tar.gz

	mkdir -p ${guestdir}/install/src
	cd ${guestdir}/install

	if ! [ -f  "src/${juliatgz}" ]; then
		cd src
 		wget https://julialang-s3.julialang.org/bin/linux/x64/$jl/${juliatgz}
		cd ..
	fi

	if [ -d "${juliabin}" ]; then 
		rm -fr  ${juliabin}
	fi

	tar xzvf src/${juliatgz}

	cd ${guestdir}/bin 
	ln -sf ../install/${juliabin}/bin/julia julia

	cd ${guestdir}/install
	if ! [ -d dyndoc-syntax ]; then
		git clone https://github.com/rcqls/dyndoc-syntax
	else
		cd dyndoc-syntax
		git pull
		cd ..
	fi
	cd ..
	cp install/dyndoc-syntax/ultraviolet/syntax/julia.syntax dyndoc/etc/uv/syntax/
}

etc-dyn-html-host() {
	guestdir=$(pwd)/../guest-tools
	script=${guestdir}/dyndoc/etc/dyn-html.yml
	echo "---" > $script
	echo "root: /home/ubuntu/RodaSrv" >> $script
}

dyndoc-yml-julia-host() {
	guestdir=$(pwd)/../guest-tools
	script=${guestdir}/etc/dyndoc.yml
	echo "---" > $script
	echo "cfg_dyn:" >> $script
  	echo "  langs: R,jl" >> $script
}

dyndoc-notify-host() {
	RODAUSER=$1
	if [ "$RODAUSER" != "" ]; then
		userdir=$(pwd)/../RodaPublic/users/${RODAUSER}
		mkdir -p ${userdir}/dyndoc-notify
		script=${userdir}/dyndoc-notify/run
		echo "#!/bin/bash" > $script
		echo "cd \$(dirname \$0)" >> $script
		echo "watchexec --exts out -w ../.edit -r  ./read" >> $script
		chmod u+x $script
		script=${userdir}/dyndoc-notify/read
		echo "#!/bin/bash" > $script
		echo "noti -t 'dyndoc server' -m \$(cat ../.edit/notify.out)" >> $script
		chmod u+x $script
	fi
}