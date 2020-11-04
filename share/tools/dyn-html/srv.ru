require "roda"
require "delegate"
require "pathname"
##TODO: require 'rack-livereload'
## read config file
require 'dyndoc/init/home'
require 'json'
require 'fileutils'

dyndoc_home = Dyndoc.home
cfg_yml = File.join(dyndoc_home,"etc","dyn-html.yml")
cfg={}
cfg.merge! YAML::load_file(cfg_yml) if File.exist? cfg_yml
root = cfg["root"] || File.join(ENV["HOME"],"RCqls","RodaServer")
$public_root = cfg["public_root"] || File.join(root ,"public")
##p [:public_root,$public_root]

##require 'dyndoc-world'
require File.join(File.dirname(__FILE__),'dyndoc-world.rb')
DyndocWorld.root(cfg["dynworld_root"] || File.join(ENV["HOME"],".dyndoc-world"))
DyndocWorld.public_root($public_root)
DyndocWorld.etc(File.join($public_root,"users",".etc"))

class App < Roda
  use Rack::Session::Cookie, :secret => (secret="Thanks life!")
  ##TODO: use Rack::LiveReload
  plugin :static, ["/pages","/private","/tools","/users"], :root => $public_root
  #opts[:root]=File.expand_path("..",__FILE__),
  #plugin :static, ["/pages","/private"]
  plugin :multi_route
  ###Dir[File.expand_path("../routes/*.rb",__FILE__)].each{|f| require f}
  plugin :header_matchers
  plugin :json
  plugin :json_parser
  plugin :render,
    :views => File.join($public_root,"views"),
    :escape=>true,
    :check_paths=>true,
    :allowed_paths=>[File.join($public_root,"views"),$public_root]
  plugin :route_csrf

  
  route do |r|

    @upload_dir_root="/home/ubuntu/.dyndoc-world"

    # GET / request
    r.root do
      r.redirect "/DynStudio"
    end

    r.on "counter" do

      init_mongo("mongo:27017")
      mongo_counter=@mongo.use("counter")
      puts "counter!!!!!!"

      r.post "inc" do
        success=false
        url,key=r["url"].split("/")
        p [:counter,url,key]
        if mongo? #and url==r.ip
          case url
          when "hist-math.fr"
            counter=:hist
          end
          mongo_counter[counter].find(:url => url,:key => key).update_one("$inc" => { :nb =>  1 } )
          success=true
        end
        "{success: " + success.to_s + "}"
      end

      r.get do
        url,key=r["url"].split("/")
        res=""
        if mongo? #and url==r.ip
          case url
          when "hist-math.fr"
            counter=:hist
          end
          res=mongo_counter[counter].find(:url => url,:key => key).first[:nb]
        end
        res
      end

    end

    r.on "dynworld" do

      r.post "identify" do 
        puts "identify"
        user=r['user']

        ## force reading yml
        DyndocWorld.prj_cfg(true)
        DyndocWorld.secret_cfg(true)

        ## DyndocWorld.debug_me(DyndocWorld.prj_user_ok?(user))
        
        prj,user=DyndocWorld.prj_user_ok?(user)
        if prj and user
          session["prj"],session["user"] = prj,user 
          #DyndocWorld.debug_me([prj,user,session["prj"],session["user"],DyndocWorld.secret_cfg,DyndocWorld.prj_cfg])
          FileUtils.mkdir_p DyndocWorld.prj_user_file?(prj,user,"upload")
          FileUtils.mkdir_p DyndocWorld.prj_user_file?(prj,user,"layout")
          FileUtils.mkdir_p DyndocWorld.prj_user_file?(prj,user,"dynlib")
          {prj: prj,user: user}.to_json
        else
          session["prj"],session["user"] = "none","nobody"
          {}.to_json
        end
      end

      r.get "dynfiles" do
        res=[{id: "edit",text: "Edit",children: true,icon: "far fa-folder"},{id: "dynlib",text: "DynLib",children: true,icon: "far fa-folder"},{id: "layout",text: "Layout",children: true,icon: "far fa-folder"}]
        if user?
          prj,user=session["prj"],session["user"]
          node=r['id']
          DyndocWorld.debug_me("node:<"+node.inspect+">"+"user: "+user.inspect,true)
          if node and node != "#"
            DyndocWorld.debug_me("node...",true)
            res=DyndocWorld.node_tree_files?(node,prj,user)
          else
            dynlibpath=File.join(DyndocWorld.prj_webuser?(prj),"dynlib",DyndocWorld.prj_user_root?(prj,user))
            layoutpath=File.join(DyndocWorld.prj_webuser?(prj),"layout",DyndocWorld.prj_user_root?(prj,user))
            res=[{id: "edit",text: "Edit (#{DyndocWorld.prj_webuser?(prj)}/#{DyndocWorld.prj_user_root?(prj,user)})",children: true,icon: "far fa-folder"},{id: "dynlib",text: "DynLib (#{dynlibpath})",children: true,icon: "far fa-folder"},{id: "layout",text: "Layout (#{layoutpath})",children: true,icon: "far fa-folder"}]
          end
        end
        DyndocWorld.debug_me("res: "+res.to_json,true)
        res.to_json
      end

      r.get "dyntree" do
        op=r["operation"]
        res=""
        DyndocWorld.debug_me("op: "+op,true)
        case op
        when "create_node"
          DyndocWorld.debug_me("create: "+r["id"]+","+r["parent"]+","+r["text"],true)
          unless r["parent"] =~ /\.dyn$/ 
            res=File.join(r["parent"],"new_node")
          end
        when "rename_node"
          DyndocWorld.debug_me("rename: "+r["id"]+","+r["text"]+","+r["old"],true)
          parts=r['id'].split("/")
          if parts.length > 1
            old=parts[-1]
            id=File.join(parts[0...-1],r['text'])
            res=id
            DyndocWorld.debug_me("rename res: "+res.inspect,true)
            file=DyndocWorld.prj_user_file?(session["prj"],session["user"],id)
            DyndocWorld.debug_me("rename file: "+file+", old: "+old ,true)
            parts=r['text'].split('.')
            if old=="new_node"
              ## to create (since just created)
              if parts.length==1
                FileUtils.mkdir_p file
              elsif parts.length==2 and parts[1]=="dyn"
                FileUtils.touch file
              end
            else
              ## to rename
              DyndocWorld.debug_me("to rename: "+ r['text']+","+r["old"],true)
              if (r['old'] =~ /\.dyn$/  && r['text'] =~ /\.dyn$/) || (!(r['old'] =~ /\.dyn$/)  && !(r['text'] =~ /\.dyn$/))
                DyndocWorld.debug_me("to rename.....",true)
                old=DyndocWorld.prj_user_file?(session["prj"],session["user"],r["id"])
                DyndocWorld.debug_me("rename old: "+old,true)
                FileUtils.mv old,file
                DyndocWorld.debug_me("rename move",true)
              end
            end
          end
        when "delete_node"
          DyndocWorld.debug_me("delete: "+r["id"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          if r['id'] =~ /\.dyn$/ 
            FileUtils.rm file
          else
            FileUtils.rm_rf file
          end
        when "move_node"
          DyndocWorld.debug_me("move: "+r["id"]+","+r["parent"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          target=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['parent'])
          FileUtils.mv file,target
          res=""
        end
        DyndocWorld.debug_me("dyntree: id "+res,true)
        res
      end

      r.get "pubfiles" do
        res=[{id: "public",text: "Public",children: true,icon: "far fa-folder"},{id: "upload",text: "Upload",children: true,icon: "far fa-folder"}]
        if user?
          prj,user=session["prj"],session["user"]
          node=r['id']
          DyndocWorld.debug_me("node:<"+node.inspect+">"+"user: "+user.inspect,true)
          if node and node != "#"
            DyndocWorld.debug_me("node...",true)
            res=DyndocWorld.node_tree_files?(node,prj,user)
          else
            res=[{id: "public",text: "Public (/users/#{DyndocWorld.prj_webuser?(prj)}/public/#{DyndocWorld.prj_user_root?(prj,user)})",children: true,icon: "far fa-folder"},{id: "upload",text: "Upload",children: true,icon: "far fa-folder"}]
          end
        end
        DyndocWorld.debug_me("res: "+res.to_json,true)
        res.to_json
      end

      r.get "dyntree" do
        op=r["operation"]
        res=""
        DyndocWorld.debug_me("op: "+op,true)
        case op
        when "create_node"
          DyndocWorld.debug_me("create: "+r["id"]+","+r["parent"]+","+r["text"],true)
          unless r["parent"] =~ /\.dyn$/ 
            res=File.join(r["parent"],"new_node")
          end
        when "rename_node"
          DyndocWorld.debug_me("rename: "+r["id"]+","+r["text"]+","+r["old"],true)
          parts=r['id'].split("/")
          if parts.length > 1
            old=parts[-1]
            id=File.join(parts[0...-1],r['text'])
            res=id
            DyndocWorld.debug_me("rename res: "+res.inspect,true)
            file=DyndocWorld.prj_user_file?(session["prj"],session["user"],id)
            DyndocWorld.debug_me("rename file: "+file+", old: "+old ,true)
            parts=r['text'].split('.')
            if old=="new_node"
              ## to create (since just created)
              if parts.length==1
                FileUtils.mkdir_p file
              elsif parts.length==2 and parts[1]=="dyn"
                FileUtils.touch file
              end
            else
              ## to rename
              DyndocWorld.debug_me("to rename: "+ r['text']+","+r["old"],true)
              if (r['old'] =~ /\.dyn$/  && r['text'] =~ /\.dyn$/) || (!(r['old'] =~ /\.dyn$/)  && !(r['text'] =~ /\.dyn$/))
                DyndocWorld.debug_me("to rename.....",true)
                old=DyndocWorld.prj_user_file?(session["prj"],session["user"],r["id"])
                DyndocWorld.debug_me("rename old: "+old,true)
                FileUtils.mv old,file
                DyndocWorld.debug_me("rename move",true)
              end
            end
          end
        when "delete_node"
          DyndocWorld.debug_me("delete: "+r["id"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          if r['id'] =~ /\.dyn$/ 
            FileUtils.rm file
          else
            FileUtils.rm_rf file
          end
        when "move_node"
          DyndocWorld.debug_me("move: "+r["id"]+","+r["parent"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          target=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['parent'])
          FileUtils.mv file,target
          res=""
        end
        DyndocWorld.debug_me("dyntree: id "+res,true)
        res
      end

      r.get "pubtree" do
        op=r["operation"]
        res=""
        DyndocWorld.debug_me("pubtree op: "+op,true)
        case op
        when "create_node"
          DyndocWorld.debug_me("create: "+r["id"]+","+r["parent"]+","+r["text"],true)
          if File.extname(r["parent"]).empty?
            res=File.join(r["parent"],"new_node")
          end
        when "rename_node"
          DyndocWorld.debug_me("rename: "+r["id"]+","+r["text"]+","+r["old"],true)
          parts=r['id'].split("/")
          if parts.length > 1
            old=parts[-1]
            id=File.join(parts[0...-1],r['text'])
            res=id
            DyndocWorld.debug_me("rename res: "+res.inspect,true)
            file=DyndocWorld.prj_user_file?(session["prj"],session["user"],id)
            DyndocWorld.debug_me("rename file: "+file+", old: "+old ,true)
            if old=="new_node"
              ## to create (since just created)
              if File.extname(r["text"]).empty?
                FileUtils.mkdir_p file
              end
            else
              ## to rename
              DyndocWorld.debug_me("to rename: "+ r['text']+","+r["old"],true)
              if (File.extname(r['old']).empty?  && File.extname(r['text']).empty? =~ /\.dyn$/) || (!(File.extname(r['old']).empty?)  && !(File.extname(r['text']).empty? ))
                DyndocWorld.debug_me("to rename.....",true)
                old=DyndocWorld.prj_user_file?(session["prj"],session["user"],r["id"])
                DyndocWorld.debug_me("rename old: "+old,true)
                FileUtils.mv old,file
                DyndocWorld.debug_me("rename move",true)
              end
            end
          end
        when "delete_node"
          DyndocWorld.debug_me("delete: "+r["id"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          if File.extname(r['id']).empty?
            FileUtils.rm_rf file
          else
            FileUtils.rm file
          end
        when "move_node"
          DyndocWorld.debug_me("move: "+r["id"]+","+r["parent"],true)
          file=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['id'])
          target=DyndocWorld.prj_user_file?(session["prj"],session["user"],r['parent'])
          FileUtils.mv file,target
          res=""
        end
        DyndocWorld.debug_me("pubtree: id "+res,true)
        res
      end

      r.post "file-save" do
        puts "file-save"
        file,@content=r['file'].strip,r['content']
        p [file,@content]
        res={status: "Failed"}
        if user? and !file.empty?
          require 'fileutils'
          if (prj_file=DyndocWorld.prj_user_file?(session["prj"],session["user"],file))
            if File.exists? prj_file
              DyndocWorld.prj_save_file(prj_file,@content)
              res[:status]="OK"
            else
              res[:status]="File not saved!"
            end
          else
            res[:status]="Unauthorized"
          end
        end
        res.to_json
      end

      r.post "file-open" do
        puts "file-open"
        file=r['file'].strip
        res={status: "Failed"}
        #DyndocWorld.debug_me([session["prj"],session["user"],file,DyndocWorld.prj_user_file?(session["prj"],session["user"],file)])
        if user? and !file.empty?
          if (prj_file=DyndocWorld.prj_user_file?(session["prj"],session["user"],file))
            res=DyndocWorld.prj_open_file(prj_file)
            res[:status]=res[:success] ? "OK" : "Failed" 
          else
            res[:status]="Unauthorized"
          end
        end
        p [:res, res]
        res.to_json
      end

      r.get "dyn-notify" do
        DyndocWorld.dyn_notify?(session["prj"])
      end

      r.get "dyn-html" do
        DyndocWorld.debug_me("dyn-html file: "+r["file"].inspect,true)
        parts=r["file"].split("/")
        DyndocWorld.debug_me("dyn-html parts: "+parts.inspect,true)
        url=File.join(parts[1...-1],(parts[-1].gsub(".dyn","")))
        DyndocWorld.debug_me("dyn-html url: "+url,true)
        prj,user=session["prj"],session["user"]
        "#{DyndocWorld.prj_webuser?(prj)}/#{DyndocWorld.prj_user_root?(prj,user)}/#{url}"
      end

      r.post "file-dropzone-upload" do
        DyndocWorld.debug_me("file-dropzone-upload:",true)
        #check_csrf!
        uploaded_io = r[:file]
        uploaded_io[:filename].gsub("'","_") if uploaded_io[:filename].include? "'"
        prj_file=DyndocWorld.prj_user_file?(session["prj"],session["user"],File.join("upload",uploaded_io[:filename]))
        DyndocWorld.debug_me("file-dropzone-upload prj_file: "+prj_file,true)
        File.open(prj_file, 'wb') do |file|
          file.write(uploaded_io[:tempfile].read)
        end
        DyndocWorld.debug_me("file-dropzone-upload prj_file: end",true)
        "{success: true}"
      end
  
      r.post "file-dropzone-delete" do
        deleted_file=DyndocWorld.prj_user_file?(session["prj"],session["user"],File.join("upload",r[:file_name]))
        ##p deleted_file
        DyndocWorld.debug_me("file-dropzone-delete prj_file: "+deleted_file,true)
        FileUtils.rm(deleted_file)
        "{success: true}"
      end

      # r.post "file-list" do
      #   where,user,subdir=r["where"],r["user"],r["subdir"]
      #   where=case where 
      #     when "public"
      #       $public_root
      #     when "edit"
      #       $public_root
      #     when "dynworld"
      #       File.join(@upload_dir_root,user)
      #     end 
      #   res=Dir["#{}"]
      # end

      r.post "task-save" do
        puts "task-save"
        p [:data,r["data"]]
        "{success: true}"
      end

      r.post "mongo-save" do
        mongo_save(r["db"],r["collection"],r["doc"])
        "{success: true}"
      end

    end

    #r.multi_route

    # /hello branch
    r.on "hello" do
      # Set variable for all routes in /hello branch
      @greeting = 'Hello'

      # GET /hello/world request
      r.get "world" do
        "#{@greeting} world! ("+r.ip+" "+r.host+")"
      end

      # /hello request
      r.is do
        # GET /hello request
        r.get do
          "#{@greeting}!"
        end

        # POST /hello request
        r.post do
          puts "Someone said #{@greeting}!"
          r.redirect
        end
      end
    end

=begin
    r.on "get" do ## useless because of static above???
      rsrc=r.remaining_path
      #p [:get,rsrc]
      static_root=File.join($public_root,"tools")
      if (rsrc=~/[^\.]*\.(?:css|js|rb|red|r|R|RData|rdata|rds|csv|txt|xls|xlsx|jpeg|jpg|png|gif)/)
        rsrc_files=Dir[File.join(static_root,"**",rsrc)]
        ##p rsrc_files
        unless rsrc_files.empty?
          rsrc_file="/tools/"+Pathname(rsrc_files[0]).relative_path_from(Pathname(static_root)).to_s
          r.redirect rsrc_file
        end
      end
      "No resource #{rsrc} to serve!"
    end
=end

    r.get do
      page=r.remaining_path
      p [:captures,r.remaining_path,r.captures,r.scope,r.params]
      static_root=File.join($public_root,"pages")
  
      ## Added for erb 
      is_erb = (page[0...4] == "/erb")
      if is_erb
        page=page[4..-1] 
        @params=r.params
      end

      ## Added to protect page
      @protect = "no"
      if (page[0...8] == "/protect")
        page=page[8..-1]
        if page =~ /^\/([^\/]*)\/(.*)$/
          @protect, page = $1, '/' + $2
        end
        p [:protect, @protect, page]
      end
      
      ##p [:page,File.join(static_root,"**",page+".html")]
      
      pattern=(page=~/[^\.]*\.(?:R|Rmd|css|js|htm|html|rb|red|r|jpeg|jpg|png|gif|pdf)/) ? page : page+(is_erb ? ".erb" : ".html")
      
      html_files=Dir[File.join(static_root,"**",pattern)]
      html_files=Dir[File.join(static_root,"*","**",pattern)] if html_files.empty?

      ## try index.html in directory
      html_files=Dir[File.join(static_root,"**",page,"index.html")] if html_files.empty?
      html_files=Dir[File.join(static_root,"*","**",page,"index.html")] if html_files.empty?

      ##DEBUG:
      # a=File.join(static_root,"**",page,"index.html")
      # p [a,Dir[a]]
      # a=File.join(static_root,"*","**",page,"index.html")
      # p [a,Dir[a]]

      ##DEBUG: p html_files

      unless html_files.empty?
        html_file="pages/"+Pathname(html_files[0]).relative_path_from(Pathname(static_root)).to_s
        if [".html",".erb"].include? (html_file_ext=File.extname(html_file))
          html_file=File.join(File.dirname(html_file),File.basename(html_file,html_file_ext))
          p html_file
          if is_erb
            erb_yml=File.join($public_root,html_file+"_erb.yml")
            @cfg_erb=(File.exists? erb_yml) ? YAML::load_file(erb_yml) : {}
          end
          render html_file, :engine=> (is_erb ? "erb" : 'html'), :views=>$public_root
        else
          r.redirect html_file
        end
      else
        "no #{page} to serve!"
      end
    end

  end

  def user?
    session["user"] and session["user"]!="nobody"
  end

  def init_mongo(address)
    require 'mongo'
    client = Mongo::Client.new([ address ])
    @mongo = client.with(user: 'MongoUser', password: 'MongoPwd')
    @mongo_srv=@mongo.cluster.servers.first
  end

  def mongo?
    @mongo_srv and @mongo_srv.connected?
  end

  def mongo_save(db,col,doc)
    init_mongo("mongo:27017")
    db_mongo=@mongo.use(db)
    if mongo?
      collection = db_mongo[col.to_sym]
      collection.insert_one(doc)
    end
  end

end

run App.freeze.app
