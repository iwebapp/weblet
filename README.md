Weblet
=========

### Weblet 是一個 Web HTTP 服務器軟件．
(Weblet is a Web HTTP Server software.)
它是一個非常簡單的面向命令行的Web服務器軟件．
主要爲Web程式開發者提供一個極爲簡單的Web開發環境．
這個程式是用 SWordFish 語言開發的，也算是這個新的編程語言的一個開發示例．
同時也可以支持　CGI　腳本．也支持 WebSocket 服務。
## 安裝方法　(　Installation　)

```bash
$ sudo npm install swordfish -g
$ sudo npm install weblet -g
```
### 用法示例：( Example )
在當前目錄下開啓一個 Web 服務．
```
$ weblet .
```
在指定的目錄 htmldoc 下開啓一個 Web 服務，並且設定以 cgi 爲後綴名的文件被視爲 CGI 程式．
```
$ weblet -x cgi htmldoc
```
在指定的目錄 htmldoc 下開啓一個 Web 服務，並且設定以 cgi 爲後綴名的文件被視爲 CGI 程式．
同時以 php 爲後綴名的文件被視爲 PHP 程式，指定其由 /usr/bin/php-cgi 程式來運行 PHP 腳本．

```
$ weblet -x cgi -x php=/usr/bin/php-cgi htmldoc
```
加 -p 8080 參數，指此 HTTP 服務綁定在系統 8080 端口上，如果不指定，默認端口爲 9999 .

```
$ weblet -p 8080 htmldoc
```

php-cgi 在 apache 以外時，要設置　php.ini 中的
```
cgi.force_redirect = 0
```

```
weblet -x php=D:\php\php-cgi.exe . 
```
一個　HTTPS 服務設置實例．(HTTPS Server Setup Example)
```
#產生一個key文件
$ openssl genrsa -out key.pem
#生成證書申請文件
$ openssl req -new -key key.pem -out csr.pem
#自簽發申請文件產生證書．
$ openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem
#刪除申請文件
$ rm csr.pem
#最後開啓 HTTPS 服務
$ weblet -c cert.pem -k key.pem . 
```

## 概括的使用說明　(　Overview Usage　)
顯示用法幫助：
```
$ weblet -h
```

```
Usage:
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
 -e, <path>                additional exe file path for CGI sub process.
 -s,                       Use a CGI script file to handle WebSocket connections. The -x option must be on
 -o,                       Open the URL to this service by browser window.
 -m,                      config mime type by extname. such as :-m .md=text/html
 -h,                    display this help and exit
Directory:  Document Root.
```

#一個打印環境變量的 CGI 腳本示例:

linux 系統下啓動 http server
```
$ weblet.sw -x swp .
```
windows　系統下啓動 http server
```
weblet.sw -x swp=swordfish .
```

```
#!/usr/bin/env swordfish
##
##  printenv.swp -- demo CGI program which just prints its environment
##
require:(JSEval "require")
path   :(require "path")
D      :(.path "sep")

nodejs: (JSCallObject [$PATH_SWORDFISH "nodejs"] "join" D)
(load (+ nodejs D "package.sw"))
prime:(JSCallObject [$PATH_SWORDFISH "prime"] "join" D)
((. use "PushINC") prime true)
((. use "PushINC") "." (GetScriptURI))

(use "app.info"
"io.print"
(lambda (AppInfo
print
)
	(print "Content-type: text/plain; charset=iso-8859-1\n\n")
	appInfo:((. AppInfo "Dump"))
	(print appInfo)
))
```


#開啓 WebSocket 服務
```
$ weblet -s -x swp .

```
在 windows 系統下可以這樣：
```
weblet -s -x swp=swordfish .
```
這樣以 .swp 結尾的 CGI 程式文件,會處理　WebSocket 鏈接。

這個 CGI 程式，必須是　swordfish　，或 nodejs  腳本。
因爲 它用 Nodejs 的　IPC Message 通訊機制 [child.send()]
每個 WebSocket 鏈接 會產生一個 CGI 進程。
WebSocket 鏈接關掉會導致 CGI 退出。
同樣 CGI 退出會導致 WebSocket 鏈接關掉。　
同時 常規的 CGI　環境變量也會在　CGI　進程中有效。

以下是個簡單的 message 響應腳本.
```
#!/usr/bin/env swordfish
require:(JSEval "require")
path   :(require "path")
D      :(.path "sep")

nodejs: (JSCallObject [$PATH_SWORDFISH "nodejs"] "join" D)
(load (+ nodejs D "package.sw"))
prime:(JSCallObject [$PATH_SWORDFISH "prime"] "join" D)
((. use "PushINC") prime true)
((. use "PushINC") "." (GetScriptURI))

(use "app.info"
(lambda (AppInfo
)
	process:(JSEval "process")
	((. process "on") "message" (JSCallback (lambda (msg)
			((. process "send") msg)
			)
		))
))

```




[child.send()]: https://nodejs.org/api/child_process.html#child_process_child_send_message_sendhandle_options_callback "child.send()"

#know issue:
-x php=D:\php\php-cgi.exe
如果寫成 -x "php=D:\php \php-cgi.exe"
是不能工作的，因爲中間有空格，這時CGI子進程就命令行就成這樣了：
D:\php "\php-cgi.exe" "current_cgi_script.php"
如果的確需要有空格程式如　：　"C:\Program Files\php5\php-cgi.exe
可以這樣寫選項
```
-e "C:\Program Files\php5" -x php=php-cgi
```
因爲 -e 是加path環境變量,這樣具體exe文件就不用寫全路徑．
這樣寫是爲了繞開nodejs spawn 中給有空格的path會出錯的問題．