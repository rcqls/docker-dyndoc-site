export-rubylib-guest-user() {
	echo "export JULIA_RUBYLIB_PATH=$(/usr/bin/env ruby -e 'puts Dir[RbConfig::CONFIG["libdir"]+"/**/libruby*"].select{|e| e =~ /\.so$/}[0]')"
}

bashrc-guest-user() {
	cd /home/ubuntu
	ln -s ../tools/etc/bashrc .bashrc
}

install-julia-guest-user() {
	jl=$1
	extra=$2
	if [ "$extra" = "" ];then 
		extra="0"
	fi
	juliabin=julia-${jl}.${extra}
	juliatgz=${juliabin}-linux-x86_64.tar.gz

	mkdir -p /home/ubuntu/tools/install/src
	cd /home/ubuntu/tools/install/src

	if ! [ -f  "${juliatgz}" ]; then
 		wget https://julialang-s3.julialang.org/bin/linux/x64/$jl/${juliatgz}
		cd ..
		tar xzvf src/${juliatgz}
	fi

	cd /home/ubuntu/tools/bin 
	ln -sf ../install/${juliabin}/bin/julia julia
}
