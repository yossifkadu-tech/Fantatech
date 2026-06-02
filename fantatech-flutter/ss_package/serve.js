const http = require('http');
const fs   = require('fs');
const path = require('path');

const root = String.raw$webDir;
const port = 8095;

http.createServer((req, res) => {
  let file = path.join(root, req.url === '/' ? '/index.html' : req.url);
  if (!fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  const ext = path.extname(file);
  const mime = {'.html':'text/html','.js':'application/javascript',
    '.css':'text/css','.png':'image/png','.json':'application/json',
    '.wasm':'application/wasm'}[ext] || 'application/octet-stream';
  res.writeHead(200, {'Content-Type': mime});
  fs.createReadStream(file).pipe(res);
}).listen(port, '127.0.0.1', () => console.log('Server on ' + port));
