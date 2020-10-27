require 'yaml'

module DyndocWorld

	@@root=nil
	@@etc=nil
	@@public=nil

	def DyndocWorld.root(root=nil)
		@@root=root if root
		return @@root
	end

	def DyndocWorld.etc(etc=nil)
		@@etc=etc if etc
		return @@etc
	end

	def DyndocWorld.public_root(public_root=nil)
		@@public=public_root if public_root
		return @@public
	end

	def DyndocWorld.cfg(mode=:secret) #:prj, :secret
		cfg={}
		etc = File.join(DyndocWorld.etc,mode.to_s+".yml")
		cfg = YAML::load_file(etc) if DyndocWorld.etc and File.exists? etc
		return cfg
	end

	@@secret_cfg=nil
	@@prj_cfg=nil

	## RMK: To reverse a hash: <hash>.to_a.map{|e1,e2| [e2,e1]}.to_h
	def DyndocWorld.secret_cfg(force=false)
		@@secret_cfg=DyndocWorld.cfg(:secret) if force || !@@secret_cfg
		@@secret_cfg
	end

	def DyndocWorld.prj_cfg(force=false)
		@@prj_cfg=DyndocWorld.cfg(:prj) if force || !@@prj_cfg
		@@prj_cfg
	end

	## return noms projet,utilisateur et répertoire
	def DyndocWorld.prj_user_ok?(secret)
		sp,su=secret.split("-")
		res=[]
		prj,user=DyndocWorld.secret_cfg["prjs"][sp],DyndocWorld.secret_cfg["users"][su]
		if DyndocWorld.prj_cfg[prj] && DyndocWorld.prj_cfg[prj]["users"]
			res=[prj,user] if DyndocWorld.prj_cfg[prj]["users"][user] || (DyndocWorld.prj_cfg[prj]["users"]["list"] && (DyndocWorld.prj_cfg[prj]["users"]["list"].include? user))
		end
	end

	def DyndocWorld.prj_webuser?(prj)
		DyndocWorld.prj_cfg[prj]["webuser"] || "RCqls"
	end

	def DyndocWorld.prj_user_root?(prj,user)
		if DyndocWorld.prj_cfg[prj]["users"]["list"] && (DyndocWorld.prj_cfg[prj]["users"]["list"].include? user)
			user.downcase
		else	
			DyndocWorld.prj_cfg[prj]["users"][user]["root"]
		end
	end

	def DyndocWorld.dyn_notify?(prj)
		DyndocWorld.debug_me("notify?",true)
		webuser=DyndocWorld.prj_webuser?(prj)
		DyndocWorld.debug_me("notify?: webuser "+webuser,true)
		notify_out=File.join(DyndocWorld.public_root,"users",webuser,".edit","notify.out")
		DyndocWorld.debug_me("notify?: out "+notify_out,true)
		min,sec=(Time.now-File.ctime(notify_out)).divmod(60)
		text=File.read(notify_out)
		text=text.gsub(".edit/","").split("/")[6..-1].join("/") if text.include? "/"
		res=(File.exists? notify_out) ? ("("+min.to_s+"m "+sec.round(1).to_s+"s) "+text) : "No notify file!"
		DyndocWorld.debug_me("notify?: res "+res,true)
		res
	end

	## 
	def DyndocWorld.prj_user_file?(prj,user,file)
		root=DyndocWorld.prj_user_root?(prj,user)
		webuser=DyndocWorld.prj_webuser?(prj)
		parts=file.split("/")
		p [:parts,parts]
		mode=parts.shift
		p [:mode,mode]

		prj_file=nil
		if ["public","edit","dynworld","dynlib","layout","upload"].include? mode
			case mode
			when "public","dynlib","layout","upload"
				prj_file=File.join(DyndocWorld.public_root,"users",webuser)
				prj_file=(Dir.exists? prj_file) ? File.join(prj_file,mode,root,parts) : ""
			when "edit"
				prj_file=File.join(DyndocWorld.public_root,"users",webuser,".edit")
				prj_file=(Dir.exists? prj_file) ? File.join(prj_file,root,parts) : ""
			when "dynworld"
				prj_file=File.join(DyndocWorld.root,webuser,root,parts)
			end
		end
	 
		DyndocWorld.debug_me("prj_file: "+prj_file,true)
		return prj_file
		
	end

	def DyndocWorld.node_tree_files?(node,prj,user)
		prj_dir=DyndocWorld.prj_user_file?(prj,user,node)
		return [] if prj_dir.empty?
		DyndocWorld.debug_me(prj_dir,true)
		nodes=Dir[File.join(prj_dir,"*")].map{|e|
			fbn=File.basename(e)
			id=File.join(node,fbn)
			res={id: id, text: fbn}
			if File.directory? e
				res[:children]=true
				res[:icon]="far fa-folder"
			else
				res[:icon]=case File.extname(id)
						when ".dyn"
							"far fa-file-alt"
						when ".png",".jpeg",".jpg",".gif"
							"far fa-file-image"
						when ".pdf"
							"far fa-file-pdf"
						when ".ogg",".wav"
							"far fa-file-audio"
						when ".avi",".mp4",".mpeg",".mpg",".vob",".mov"
							"far fa-file-video"
						else
							"far fa-file"
						end
			end
			res
		}
		DyndocWorld.debug_me(nodes.inspect,true)
		nodes
	end

	## file ##
	## ex: public/<user>/<pathname>
	##     edit/<user>/<pathname>
	##     dynworld/<user>/<pathname>
	def DyndocWorld.prj_save_file(prj_file,content)
		FileUtils.mkdir_p File.dirname prj_file
		File.open(prj_file,"w") {|f|
			f << content.strip
		}
	end

	def DyndocWorld.prj_open_file(prj_file)
		res={success: false}
		if File.exists? prj_file
			res[:content]=File.read(prj_file)
			res[:success]=true
		end
		return res
	end

	def DyndocWorld.user_ok?(prj,user)
		cfg=DyndocWorld.secret_cfg["prj"]
		if cfg["users"]
			if cfg["users"].is_a? Array
			elsif cfg["users"].is_a? Hash
			end
		end
	end

	def DyndocWorld.debug_me(str,append=false)
		upload_dir_root="/home/ubuntu/.dyndoc-world"
		File.open(File.join(upload_dir_root,".debug"),(append ? "a" : "w")) do |f| 
			f << "\n" if append 
			f << str
		end
	end
end