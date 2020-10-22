user-dyn-init-etc() {
	dyn-init install etc
}

user-export-rubylib() {
	mkdir -p /home/ubuntu/tools/etc
	script=/home/ubuntu/tools/etc/bashrc
	echo "export JULIA_RUBYLIB_PATH=$(/usr/bin/env ruby -e 'puts Dir[RbConfig::CONFIG["libdir"]+"/**/libruby*"].select{|e| e =~ /\.so$/}[0]')" >> $script
}

user-links() {
	mkdir -p /home/ubuntu/tools/etc
	cd /home/ubuntu
	ln -sf tools/etc/bashrc .bashrc
	ln -sf tools/etc/dyndoc.yml .dyndoc.yml
}

user-install-dyndoc() {
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

## A appeler en début d'install
root-install-begin() {
	apt-get update -qq
}

## A appeler en fin d'install
root-install-end() {
	rm -rf /var/lib/apt/lists/*
}

## OLD to install R, ruby and dyndoc: curl -fs https://cqls.dyndoc.fr/users/RCqls/Dyndoc/install/install-ubuntu16.sh
root-install-r() {
	R_VERSION=4.0.2
	OS_IDENTIFIER=ubuntu-2004
	if [ "$1" != "" ]; then
		R_VERSION=$1
	fi
	if [ "$2" != "" ]; then
		OS_IDENTIFIER=$2
	fi

	echo "Installing R since not detected in your system"
	## OLD
	# if [ "$(which add-apt-repository)" = "" ]; then
	# 	sudo apt-get install -y software-properties-common
	# fi
	# sudo add-apt-repository -y ppa:marutter/rrutter
	# sudo apt-get update -y
	# sudo apt-get install -y r-base r-base-dev
	## NEW (from github rstudio/r-docker)
	wget https://cdn.rstudio.com/r/${OS_IDENTIFIER}/pkgs/r-${R_VERSION}_1_amd64.deb && \
	DEBIAN_FRONTEND=noninteractive apt-get install -f -y ./r-${R_VERSION}_1_amd64.deb && \
	ln -sf /opt/R/${R_VERSION}/bin/R /usr/bin/R && \
	ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/bin/Rscript && \
	ln -sf /opt/R/${R_VERSION}/lib/R /usr/lib/R && \
	rm r-${R_VERSION}_1_amd64.deb
}

root-install-ruby() {
	echo "Installing ruby"
	apt-get install -y ruby ruby-dev libruby
}

## From r-docker/base
root-install-tinytex() {
	echo "Installing tinytex...."
	wget -qO- "https://yihui.name/gh/tinytex/tools/install-unx.sh" | sh -s - --admin --no-path && \
    mv ~/.TinyTeX /opt/TinyTeX && \
    /opt/TinyTeX/bin/*/tlmgr path add
}

## From r-docker/base
root-install-pandoc() {
	echo "Installing pandoc..."
	mkdir -p /opt/pandoc && \
    wget -O /opt/pandoc/pandoc.gz https://files.r-hub.io/pandoc/linux-64/pandoc.gz && \
    gzip -d /opt/pandoc/pandoc.gz && \
    chmod +x /opt/pandoc/pandoc && \
    ln -s /opt/pandoc/pandoc /usr/bin/pandoc && \
    wget -O /opt/pandoc/pandoc-citeproc.gz https://files.r-hub.io/pandoc/linux-64/pandoc-citeproc.gz && \
    gzip -d /opt/pandoc/pandoc-citeproc.gz && \
    chmod +x /opt/pandoc/pandoc-citeproc && \
    ln -s /opt/pandoc/pandoc-citeproc /usr/bin/pandoc-citeproc
}

root-install-ttm() {
	echo "Installing ttm..."
	mkdir ~/.ttm-tmp
	cd ~/.ttm-tmp
	curl -fsO http://hutchinson.belmont.ma.us/tth/mml/ttmC.tar.gz
	tar xzf ttmC.tar.gz
	cd ttmC
	make
	chmod u+x ttm
	sudo cp ttm /usr/local/bin
	rm -fr ~/.ttm-tmp
}

root-install-dyndoc() {
	echo "Installing gems dependencies ..."
	sudo gem install daemons thin roda tilt erubis erubi  --no-ri --no-rdoc


	echo "Installing dyndoc ruby gems ..."

	# ruby gems: dyndoc
	sudo gem install dyndoc-ruby --no-ri --no-rdoc

	# R package devtools
	sudo R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'

	echo "Installing dyndoc R packages ..."

	# R package rb4R
	sudo R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch",build=FALSE)'
	# if something goes wrong in the previous instruction redo after: sudo apt-get install libgmp-dev

	# R package base64
	sudo R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'

	echo "Installing optional ruby gems ..."

	# optional but nice-to-have:
	sudo gem install asciidoctor --no-ri --no-rdoc
	sudo gem install redcarpet --no-ri --no-rdoc
	sudo gem install filewatcher --no-ri --no-rdoc
}

user-install-dynlib() {
	echo "Installing dyndoc package DyndocWebTools.dyn ..."
	dpm install rcqls/DyndocWebTools.dyn
	dpm link rcqls/DyndocWebTools.dyn
}

