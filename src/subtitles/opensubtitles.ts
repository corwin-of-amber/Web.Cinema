import fs from 'fs';
import MemoryStream from 'memory-stream';


function readFirstAndLast(fn: string) {
  const BLOCK_SIZE = 65536
  let result = {}

  return new Promise((fulfill, reject) => {
    let check = () => { console.log(result); }; //if (result.block0 && result.blockn? then fulfill result
    let rsblock0 = fs.createReadStream(fn, {start: 0, end: BLOCK_SIZE - 1});
    let block0 = new MemoryStream
    rsblock0.pipe(block0);
    /*
      block0 = new MemoryStream
      ..pipe block0
      ..on 'end' -> result.block0 = block0.toBuffer! ; console.log result.block0.length ; check!
      */
    /*  
    fs.stat fn, (err, stat) ->
      console.log err, stat
      if err then werr err ; reject err
      else
        result.size = stat.size
        rs-blockn = fs.createReadStream(fn, start: stat.size - BLOCK_SIZE, end: stat.size - 1)
          blockn = new MemoryStream
          ..pipe blockn
          ..on 'end' -> result.blockn = blockn.toBuffer! ; console.log result.blockn.length ; check!
*/
  });
}


export { readFirstAndLast }