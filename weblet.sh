#!/usr/bin/env node

var fs=require("fs");
var path=require("path");
var D=path.sep;
var exeFilePath=process.argv[1];
try{
	var linkFilePath=fs.readlinkSync(exeFilePath);
	if(path.isAbsolute(linkFilePath)){
		exeFilePath=linkFilePath;
	}else{
		exeFilePath=path.normalize(path.dirname(exeFilePath)+D+linkFilePath);
	}
}catch(e){}

if(!path.isAbsolute(exeFilePath)){
	exeFilePath=path.normalize((process.cwd()+exeFilePath));
}

var webletPath=path.normalize(path.dirname(exeFilePath));
var dependencies_node_modules_D=webletPath+D+"node_modules"+D;
var binSWPath;
var Start;
try{
	Start=require(dependencies_node_modules_D+"swordfish");
	binSWPath=dependencies_node_modules_D+"swordfish"+D+"swordfish.js";
}catch(e){
	Start=require("swordfish");
	binSWPath=null;
}
var arguments=[(webletPath+D+"weblet.sw")].concat(process.argv.slice(2));
Start(binSWPath,arguments);
