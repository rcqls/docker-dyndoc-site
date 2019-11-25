export-rubylib-user() {
	mkdir -p /home/ubuntu/tools/etc
	script=/home/ubuntu/tools/etc/bashrc
	echo "export JULIA_RUBYLIB_PATH=$(/usr/bin/env ruby -e 'puts Dir[RbConfig::CONFIG["libdir"]+"/**/libruby*"].select{|e| e =~ /\.so$/}[0]')" >> $script
}

links-user() {
	mkdir -p /home/ubuntu/tools/etc
	cd /home/ubuntu
	ln -sf tools/etc/bashrc .bashrc
	ln -sf tools/etc/dyndoc.yml .dyndoc.yml
}

install-dyndoc-user() {
	if ! [[ -L /home/ubuntu/dyndoc && -d /home/ubuntu/dyndoc ]]; then
		cd /home/ubuntu
		if [ -d tools/dyndoc ]; then
			if [ -d dyndoc ]; then
				rm -fr dyndoc
			fi
		else
			mv dyndoc tools/
		fi
		ln -sf tools/dyndoc dyndoc
	fi
}

# install-julia-guest-user() {
# 	jl=$1
# 	extra=$2
# 	if [ "$extra" = "" ];then 
# 		extra="0"
# 	fi
# 	juliabin=julia-${jl}.${extra}
# 	juliatgz=${juliabin}-linux-x86_64.tar.gz

# 	mkdir -p /home/ubuntu/tools/install/src
# 	cd /home/ubuntu/tools/install/src

# 	if ! [ -f  "${juliatgz}" ]; then
#  		wget https://julialang-s3.julialang.org/bin/linux/x64/$jl/${juliatgz}
# 		cd ..
# 		tar xzvf src/${juliatgz}
# 	fi

# 	cd /home/ubuntu/tools/bin 
# 	ln -sf ../install/${juliabin}/bin/julia julia
# }
