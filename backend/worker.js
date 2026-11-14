// Experimental Cloudflare Worker adapter for existing Express API.
// Node HTTP server is never bound to a TCP port on Cloudflare.
const { createServer } = require('node:http');
const { httpServerHandler } = require('cloudflare:node');
const app = require('./server');
const server = createServer(app);
const apiHandler = httpServerHandler({ port: 8787, server });
const pages = new Set(['register','login','forgot','reset','dashboard','account','seller','cart','orders','help-pay','welcome','wallet','deposit','admin','admin-login','vip','ask-arike','partnership']);
module.exports = {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname.startsWith('/api/')) {
      // API requests are forwarded to Express. Database credentials are Worker secrets.
      return apiHandler.fetch(request, env, ctx);
    }
    if (url.pathname === '/admin/login') url.pathname = '/admin-login.html';
    else if (url.pathname === '/') url.pathname = '/index.html';
    else if (pages.has(url.pathname.slice(1))) url.pathname += '.html';
    // Static frontend assets are served by Cloudflare Assets, not Express.sendFile.
    return env.ASSETS.fetch(new Request(url, request));
  }
};
