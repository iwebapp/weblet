#!/usr/bin/env swordfish

require:(JSEval "require")
path:(require "path")
D:(. path "sep")

nodejs:(JSCallObject [$PATH_SWORDFISH "nodejs"] "join" D)
prime:(JSCallObject [$PATH_SWORDFISH "prime"] "join" D)
(load (+ nodejs D "package.sw"))
((. use "PushINC") prime true)


(use
"app.info" "weblet.server" "simply.error"
"cgi.env"
"protocol.uri"
"protocol.http.uri"
"protocol.http.uri.decode"
"script.object.keys"
(lambda (AppInfo WebletServer L CGIEnv
URI
HttpURI
UriDecode
Keys
)
	
	BuildEnv:(. CGIEnv "BuildEnv")

	
	process:(JSEval "process")

	(. global "L" L)
	RegExp:(JSEval "RegExp")
	parseInt:(JSEval "parseInt")

	os:(require "os")
	fs:(require "fs")
	isWindows:(== ((. ((. os "platform")) "indexOf") "win") 0)
	linkFilePath:
	exeFilePath:((. AppInfo "GetExeFilePath"))
	
	(try
		linkFilePath=(( . fs "readlinkSync") exeFilePath)
		(cond { ((. path "isAbsolute") linkFilePath)
			exeFilePath:linkFilePath
		}{default
			exeFilePath: ((. path "normalize") (+ ((. path "dirname") exeFilePath) D linkFilePath))
			})
		(lambda ()
			())
		)


	dependencies_node_modules_D:(+ ((. path "normalize") ((. path "dirname") exeFilePath)) D "node_modules" D)

	appArguments:((. AppInfo "GetArguments"))
	document_path:
	port:
	localAddress:"0.0.0.0"
	httpsCertificatePath:
	httpsPrivatekeyPath:
	additionalPath:
	enableWebSocketCGI:
	argkey:undefined
	cgiSetting:{}
	mimeConfig:null
	//cgiXSize:0
	noOpen:true

	printHelp:(lambda (@arguments)
		(L 
"Usage:
weblet [options] <directory>
Options:
 -x, <cgi>                 Identify CGI script by file suffix name. can set multiple times.
                           For example:
                             -x cgi
                             -x php=/usr/bin/php-cgi
 -p, <port>                listen port number. default 9999
 -a, <address>             Local interface to bind to for network connections. default 0.0.0.0
 -c, <CertificatePath>     HTTPS certificate file path.
 -k, <PrivatekeyPath>      HTTPS private key file path.
 -s,                       Use a CGI script file to handle WebSocket connections. The -x option must be on
 -e, <path>                additional exe file path for CGI sub process.
 -o,                       Open the URL to this service by browser window.
 -m,                      config mime type by extname. such as :-m .md=text/html
 -h,                    display this help and exit

Directory:  Document Root.
"
			)
		)
	(while (!= argkey=((. appArguments "shift")) null)
		(cond {(match argkey `/^-([apxckshoem])$/)
			op:(. RegExp "$1")
			(cond {(== "x" op)
					cgi:((. appArguments "shift"))
					cgis:((. cgi "split") "=")

					(. cgiSetting (. cgis 0) (. cgis 1))
					; (L "======== x" cgis cgiSetting)
					//cgiXSize=(+ cgiXSize 1)
				}{(== "p" op)
					port=(parseInt ((. appArguments "shift")))
				}{(== "a" op)
					localAddress=((. appArguments "shift"))
				}{(== "c" op)
					httpsCertificatePath=((. appArguments "shift"))
				}{(== "k" op)
					httpsPrivatekeyPath=((. appArguments "shift"))
				}{(== "e" op)
					additionalPath=((. appArguments "shift"))
				}{(== "s" op)
					//WebSoketHandlerPath=((. appArguments "shift"))
					enableWebSocketCGI=true
				}{(== "o" op)
					noOpen=(! noOpen)
				}{(== "h" op)
					(printHelp)
					(return)
				}{(== "m" op)
					extname__:((. appArguments "shift"))
					extname__s:((. extname__ "split") "=")
					(if (== mimeConfig null)
						mimeConfig={}
					)

					(. mimeConfig (. extname__s 0) (. extname__s 1))
					
				}{default
					(printHelp)
					(return)
				})
			}{default
				(if (== document_path null)
					document_path=argkey
					(break)
					)
				
			})
		)
	(cond {(== document_path null)
		
			(printHelp)
			(return)
			
		})
	(cond {enableWebSocketCGI
			(if (== (. ((. Keys "Get") cgiSetting) "length") 0)
				(do
					(printHelp)
					(return)
					)
				)})

	lastCharIdx:(- (. document_path "length") 1)
	(if (== ((. document_path "lastIndexOf") D) lastCharIdx)
		document_path=((. document_path "substring") 0 lastCharIdx))
	
	
	(if (! ((. URI "IsAbsolutePath") document_path null isWindows))
		(do
			document_path=(+ ((. process "cwd")) D document_path)
			)

		)
	
	document_path=((. path "normalize") document_path)

	
	port:(|| port 9999)
	server:((. WebletServer "Create") port document_path cgiSetting true true 
		httpsCertificatePath httpsPrivatekeyPath localAddress
		additionalPath mimeConfig)

	protocol:(? (== httpsCertificatePath null) "http" "https")
	serviceURL:(+ protocol "://" (? (!= localAddress "0.0.0.0") localAddress "localhost") ":" port "/")

	(L (+ serviceURL " Service Started."))
	(L (+ "Document at: " document_path))

	(cond {enableWebSocketCGI
		
		WebSocketServer:(. (require (+ dependencies_node_modules_D "ws")) "Server")
		wss:(JSNew WebSocketServer {"server":server})

		cp:(require "child_process")
		spawn:(. cp "spawn")
		
		wsHandler:(lambda (ws request)
			request=(|| request (. ws "upgradeReq"))
			uri:(. request "url")
			uriObj:((. HttpURI "Translate") uri)
			extend:(. uriObj "extend")
			bin:
			parames:[]
			isCGIFile:(in extend cgiSetting)

			
			(cond {(! isCGIFile)
				((. ws "close"))
				(return)
				})


			_local_file_name:
			decodedPath=(UriDecode (. uriObj "path") )
			_local_path:(+ document_path ( (. decodedPath "replace") `/\//g D) )
			_file_name:(UriDecode (. uriObj "fileName"))
			_local_file_name=(+ _local_path D _file_name)
			
			(if (! ((. fs "existsSync") _local_file_name))
				(do 
					((. ws "close"))
					(return)
					)
				)

			
			(cond {(!= (. cgiSetting extend) null)
				bin=(. cgiSetting extend)
				(cond {(! ((. path "isAbsolute") bin))
					((. parames "push") _local_file_name)
					(cond {isWindows
						//(cp.execSync("where swordfish")).toString().split(/[\r\n]+/)
							binPaths:((. ((. ((. cp "execSync") (+ "where " bin)) "toString")) "split") `/[\r\n]+/)
							bin:(each binPaths (lambda (binPath)
								(if (match binPath `/\.(?:exe|cmd)$/)
									(break binPath)
								)
								))
							(if (!bin)
								(do 
									((. ws "close"))
									(return)
									)
								)
						}{default
						})
					})
			}{default
				bin=_local_file_name
			})

			sp:
			startUp:
			spIsExit:false
			wsIsClose:false
			spOnMessage:(JSCallback (lambda (m)
				//(L (+ "PARENT got message:" m))
				//(if (!= m "OK")
				//	((. sp "send") "world")
				//	)
				((. ws "send") m)
				))

			spOnExit:(JSCallback (lambda ()
				//(L "sp On Exit")
				//(startUp)
				spIsExit=true
				(if (! wsIsClose)
					((. ws "close"))
					)
				))

			wsOnMessage:(JSCallback (lambda (m)
				((. sp "send") m)
			))
			wsOnClose:(JSCallback (lambda (m)
				//(L "ws On Close")
				wsIsClose=true
				(cond {(! spIsExit)
					((. sp "disconnect"))
					((. sp "kill") "SIGKILL")
					})
			))

			startUp=(lambda ()


				env:(BuildEnv request null document_path _local_file_name null additionalPath)
				cwd:_local_path
				options:{"cwd":cwd
				"env":env
				"stdio":["ipc" null]
				}
				(try
					sp=(spawn bin parames options)
					(lambda (e)
						//(L e)
						((. ws "close"))
						(return)
					)
				)
				
				((. sp "on") "error" spOnExit)
				((. sp "on") "exit" spOnExit)
				((. sp "on") "message" spOnMessage)
				((. (. sp "stdout") "pipe") (. process "stdout"))
				((. (. sp "stderr") "pipe") (. process "stderr"))
				((. ws "on") "message" wsOnMessage)
				((. ws "on") "close" wsOnClose)
			)
			(startUp)
			)


		((. wss "on") "connection" (JSCallback wsHandler))
		(L "with WebSocketServer" )

		//((. process "on") "exit" (JSCallback (lambda (code)
		//	(L (+ " main Exit " code))
		//	)))
		})

	(cond {(!noOpen)
		open:(require "open")
		setTimeout:(JSEval "setTimeout");
		(setTimeout (JSCallback (lambda ()
			(open serviceURL)
			)) 100)
		})
	))

