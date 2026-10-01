// Puts a manager's company on a paid plan with a test card (dev only). From
// the repo root:
//   node docs/completed/bulk-upload-s3-manual-qa/upgrade.mjs <manager email>
import { signIn, makePaid, status } from './lib.mjs';

const token = await signIn(process.argv[2]);
await makePaid(token);
console.log(await status(token));
