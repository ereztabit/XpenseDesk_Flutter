// Uses N of a user's free receipts "from another device" (files N typed-in
// expenses). From the repo root:
//   node docs/in-progress/bulk-upload-s3-manual-qa/use.mjs <email> <n>
import { signIn, fileExpenses, status } from './lib.mjs';

const token = await signIn(process.argv[2]);
await fileExpenses(token, Number(process.argv[3] ?? 1));
console.log(await status(token));
