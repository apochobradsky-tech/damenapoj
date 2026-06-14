const http = require('http');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const port = Number(process.argv[3]);
const types = {'.html':'text/html; charset=utf-8','.json':'application/json; charset=utf-8','.xml':'application/xml; charset=utf-8','.txt':'text/plain; charset=utf-8','.css':'text/css; charset=utf-8','.js':'application/javascript; charset=utf-8'};
http.createServer((req,res)=>{
  const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
  const safe = path.normalize(urlPath).replace(/^([\\/])+/, '');
  const file = path.join(root, safe || 'index.html');
  let target = fs.existsSync(file) && fs.statSync(file).isDirectory() ? path.join(file, 'index.html') : file;
  if (!fs.existsSync(target) && (safe.startsWith('napoj') || safe.startsWith('napoje') || safe.startsWith('kategorie'))) target = path.join(root, 'index.html');
  if (!target.startsWith(root)) { res.writeHead(403); return res.end('Forbidden'); }
  fs.readFile(target, (err,data)=>{
    if (err) { res.writeHead(404); return res.end('Not found'); }
    res.writeHead(200, {'Content-Type': types[path.extname(target).toLowerCase()] || 'application/octet-stream'});
    res.end(data);
  });
}).listen(port, '127.0.0.1');
