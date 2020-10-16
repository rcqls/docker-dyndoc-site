
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

########### ONLY COPY OF old install-ubuntu16.sh

install-ubuntu16() {
	# R install
if [ "$(which R)" = "" ]; then
  echo "Installing R since not detected in your system"
  if [ "$(which add-apt-repository)" = "" ]; then
    sudo apt-get install -y software-properties-common
  fi
  sudo add-apt-repository -y ppa:marutter/rrutter
  sudo apt-get update -y
  sudo apt-get install -y r-base r-base-dev
fi

# ruby install
if [ "$(which ruby)" = "" ] || [ "$(ruby -e 'puts RUBY_VERSION[0]')" = "1" ]; then
  echo "Installing ruby version 2 since not detected in your system"
  sudo apt-get install -y ruby ruby-dev libruby
fi

# git install
if [ "$(which git)" = "" ]; then
  echo "Installing git since not detected in your system"
  sudo apt-get install -y git
fi

# git install
if [ "$(which pandoc)" = "" ]; then
  echo "Installing pandoc since not detected in your system"
  sudo apt-get install -y pandoc
fi

echo "Installing gems dependencies ..."
sudo gem install daemons thin roda tilt erubis erubi  --no-ri --no-rdoc


echo "Installing dyndoc ruby gems ..."

# ruby gems: dyndoc
sudo gem install dyndoc-ruby --no-ri --no-rdoc

# R package devtools
sudo apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev
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

echo "Configuring dyn-init ..."
dyn-init

echo "Installing dyndoc package DyndocWebTools.dyn, dyndoc-share/libray/RCqls ..."
dpm install rcqls/DyndocWebTools.dyn
dpm link rcqls/DyndocWebTools.dyn
dpm install rcqls/dyndoc-share
dpm link rcqls/dyndoc-share/library/RCqls


echo "installing ttm"
mkdir ~/.ttm-tmp
cd ~/.ttm-tmp
curl -fsO http://hutchinson.belmont.ma.us/tth/mml/ttmC.tar.gz
tar xzf ttmC.tar.gz
cd ttmC
make
chmod u+x ttm
sudo cp ttm /usr/local/bin
rm -fr ~/.ttm-tmp

echo "IMPORTANT:
* In order to use dyndoc inside latex, do not forget to install pdflatex:
sudo apt-get install -y texlive-full
"
}