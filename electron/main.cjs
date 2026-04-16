'use strict';

const { app, BrowserWindow, shell, Menu } = require('electron');
const path = require('path');
const http = require('http');
const fs = require('fs');
const url = require('url');

// ── Static file server for the built React app ──
const PORT = 54821; // fixed high port, unlikely to clash

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.ico':  'image/x-icon',
  '.json': 'application/json',
  '.webmanifest': 'application/manifest+json',
  '.woff2':'font/woff2',
  '.woff': 'font/woff',
};

function createStaticServer(distDir) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      let reqPath = url.parse(req.url).pathname;

      // Strip leading slash, default to index.html
      let filePath = path.join(distDir, reqPath === '/' ? 'index.html' : reqPath);

      // If file doesn't exist → serve index.html (React Router catch-all)
      if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(distDir, 'index.html');
      }

      const ext  = path.extname(filePath);
      const mime = MIME[ext] ?? 'application/octet-stream';

      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(404);
          res.end('Not found');
          return;
        }
        res.writeHead(200, { 'Content-Type': mime });
        res.end(data);
      });
    });

    server.listen(PORT, '127.0.0.1', () => resolve(server));
    server.on('error', reject);
  });
}

let mainWindow = null;
let server     = null;

// Resolve dist directory — works both in dev (from project root) and packaged
function getDistDir() {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, 'dist');
  }
  return path.join(__dirname, '..', 'dist');
}

async function createWindow() {
  const distDir = getDistDir();

  // Start static server
  server = await createStaticServer(distDir);

  mainWindow = new BrowserWindow({
    width:  1280,
    height: 800,
    minWidth:  380,
    minHeight: 500,
    title: 'FantaTech',
    backgroundColor: '#060c18',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    },
    // Icon (optional — skipped if file is missing)
    ...(() => {
      const ico = path.join(__dirname, 'icon.ico');
      return (process.platform !== 'darwin' && fs.existsSync(ico))
        ? { icon: ico }
        : {};
    })(),
  });

  // Remove default menu bar
  Menu.setApplicationMenu(null);

  mainWindow.loadURL(`http://127.0.0.1:${PORT}`);

  // Open external links in the real browser, not Electron
  mainWindow.webContents.setWindowOpenHandler(({ url: href }) => {
    if (!href.startsWith(`http://127.0.0.1:${PORT}`)) {
      shell.openExternal(href);
    }
    return { action: 'deny' };
  });

  mainWindow.on('closed', () => { mainWindow = null; });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (server) server.close();
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (mainWindow === null) createWindow();
});
