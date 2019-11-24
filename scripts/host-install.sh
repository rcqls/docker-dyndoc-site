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
		git pull
	fi
	cd ..
	cp install/dyndoc-syntax/ultraviolet/syntax/julia.syntax dyndoc/etc/uv/syntax/
}