const { cfDownloadStream } = await import('./src/utils/cloudflareSpeedTest.ts').catch(() => import('./src/utils/cloudflareSpeedTest.ts').catch(e => { console.log("Can't import directly, writing raw fetch"); return null; }));

async function test() {
  const url = `https://speed.cloudflare.com/__down?bytes=10000000`;
  const resp = await fetch(url);
  const reader = resp.body.getReader();
  let bytes = 0;
  while(true) {
    const {done, value} = await reader.read();
    if(done) break;
    bytes += value.length;
    console.log("Chunk length:", value.length);
  }
  console.log("Total bytes:", bytes);
}
test();
