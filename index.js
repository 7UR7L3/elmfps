const WebSocketServer = require('ws').Server;

const wss = new WebSocketServer({ port: 3000 });
var arr = [];

wss.on('connection', function(ws) {
	ws.on('message', function incoming(message) {
		// gets player number
		var num = message.substring(0,message.indexOf(";"));
		// splits string into each attribute sent
		var tempar = message.split(";");
		// updates the score by 1 of the player
		tempar[tempar.length-1] = arr.length//parseInt(tempar[tempar.length-1]) + 1
		// updates the player attributes stored by the server
		arr[num] = tempar.join(";");
		// each player, joined by quest(";");ion marks
		var send = arr.join("?");
		// logging all the players
		// console.log(send);
		// sending all the player info
		ws.send(send);
		if (num > 0) console.log(message)
		// console.log(num)
	});
	console.log('connected')
	// adds a new space in the array for the player
	arr.push("")
	// console.log(arr)
	// sends the player their number/ the place in the array
	ws.send("+" + (arr.length-1)); //ws.send(arr.length-1)
});

// var ws = require("node.jas-websocket")

// var server = ws.createServer(function (conn){
// 	console.log("New connection")
// 	conn.on("text", function (str) {
// 		console.log("Received " + str)
// 		conn.sendText(str.toUpperCase() + "!!!")
// 	})
// 	conn.on("close", function (code, respon){
// 		console.log("Connection closed")
// 	})
// }).listen(8001)

//This
// var cool = require('cool-ascii-faces');
// var express = require('express');
// var app = express();

// app.set('port', (process.env.PORT || 5000));

// app.use(express.static(__dirname + '/public'));

// // views is directory for all template files
// app.set('views', __dirname + '/views');
// app.set('view engine', 'ejs');

// app.get('/', function(request, response) {
//   response.render('pages/index');
// });

// app.get('/cool', function(request, response) {
//   response.send(cool());
// });

// app.get('/user/:id', function(request, response){
// 	response.send(request.params.id);
// });

// app.listen(app.get('port'), function() {
//   console.log('Node app is running on port', app.get('port'));
// });
//This

// var cool = require('cool-ascii-faces');
// const express = require('express')
// const path = require('path')
// const PORT = process.env.PORT || 5000

// express()
//   .use(express.static(path.join(__dirname, 'public')))
//   .set('views', path.join(__dirname, 'views'))
//   .set('view engine', 'ejs')
//   .get('/', (req, res) => res.render('pages/index'))
//   .listen(PORT, () => console.log(`Listening on ${ PORT }`))
