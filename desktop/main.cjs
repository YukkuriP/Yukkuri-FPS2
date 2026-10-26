const { app, BrowserWindow, shell } = require("electron");
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const webRoot = path.resolve(__dirname, "..", "web");
const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff2": "font/woff2"
};

function startLocalWebServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      let pathname;
      try {
        pathname = decodeURIComponent(new URL(req.url, "http://127.0.0.1").pathname);
      } catch {
        res.writeHead(400).end("Bad request");
        return;
      }

      const relativePath = pathname === "/" ? "index.html" : pathname.replace(/^\/+/, "");
      const filePath = path.resolve(webRoot, relativePath);
      if (filePath !== webRoot && !filePath.startsWith(webRoot + path.sep)) {
        res.writeHead(403).end("Forbidden");
        return;
      }

      fs.stat(filePath, (statError, stat) => {
        if (statError || !stat.isFile()) {
          res.writeHead(404).end("Not found");
          return;
        }
        res.writeHead(200, {
          "Content-Type": mimeTypes[path.extname(filePath).toLowerCase()] || "application/octet-stream",
          "X-Content-Type-Options": "nosniff",
          "Cache-Control": "no-store"
        });
        fs.createReadStream(filePath).pipe(res);
      });
    });

    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      resolve({ server, url: `http://127.0.0.1:${address.port}/` });
    });
  });
}

let localServer;

async function createWindow() {
  const { server, url } = await startLocalWebServer();
  localServer = server;

  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 900,
    minHeight: 600,
    backgroundColor: "#080d13",
    title: "Operation: Iron Veil",
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  win.webContents.setWindowOpenHandler(({ url: targetUrl }) => {
    if (targetUrl.startsWith("https://")) shell.openExternal(targetUrl);
    return { action: "deny" };
  });

  await win.loadURL(url);
}

app.whenReady().then(async () => {
  await createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("before-quit", () => {
  if (localServer) localServer.close();
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
