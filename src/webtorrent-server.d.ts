// import type { TorrentFile } from 'webtorrent';

declare module "webtorrent/lib/server" {
    class NodeServer {
        constructor(...a: any[])
        listen(port: number): void
        close(): void
        onRequest(req, cb): void
        static serveFile(file: any, req: any, opts?: any): any
    }
}
