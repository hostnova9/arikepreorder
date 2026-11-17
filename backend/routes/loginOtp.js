const pool = require('../db');
const web = globalThis.crypto || require('node:crypto').webcrypto;
function config() { return pool.requestEnv(); }
function failure(stage, err, status=503) {
  console.error('AUTH_OTP_FAILURE', stage, String(err?.code || err?.name || 'Error').slice(0,40));
  const e = new Error(status===429 ? 'Wait 60 seconds before requesting another code.' : 'Verification service temporarily unavailable. Please retry.');
  e.status=status; return e;
}
function generateCode() {
  const a=new Uint32Array(1), limit=Math.floor(2**32/900000)*900000;
  do { web.getRandomValues(a); } while(a[0]>=limit);
  return String(100000+a[0]%900000);
}
async function digest(id,code) {
  const enc=new TextEncoder();
  const key=await web.subtle.importKey('raw',enc.encode(config().JWT_SECRET),{name:'HMAC',hash:'SHA-256'},false,['sign']);
  return Array.from(new Uint8Array(await web.subtle.sign('HMAC',key,enc.encode(id+':'+code))),b=>b.toString(16).padStart(2,'0')).join('');
}
async function issue(kind,user) {
  const env=config();
  const missing=['JWT_SECRET','RESEND_API_KEY','ARIKE_FROM_EMAIL'].filter(k=>!String(env[k]||'').trim());
  if(missing.length||!user.email) throw failure('configuration:'+missing.join(',')+(!user.email?':recipient':''));
  let id,code,hash;
  try { id=web.randomUUID(); code=generateCode(); hash=await digest(id,code); } catch(e){throw failure('crypto',e);}
  let q;
  try { q=await pool.query(`INSERT INTO login_challenges(id,kind,subject,email,code_hash) VALUES($1,$2,$3,$4,$5) ON CONFLICT(kind,subject) DO UPDATE SET id=EXCLUDED.id,email=EXCLUDED.email,code_hash=EXCLUDED.code_hash,created_at=NOW(),attempts=0,used=false WHERE login_challenges.created_at < NOW()-INTERVAL '60 seconds' RETURNING id`,[id,kind,String(user.id),user.email,hash]); } catch(e){throw failure('database_insert',e);}
  if(!q.rows.length) throw failure('cooldown',null,429);
  try {
    const response=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:'Bearer '+env.RESEND_API_KEY.trim(),'Content-Type':'application/json'},body:JSON.stringify({from:env.ARIKE_FROM_EMAIL.trim(),to:[user.email],subject:'ArikePreorder security code',text:'Your verification code is '+code+'. Expires in 10 minutes. Never share this code.'})});
    if(!response.ok){console.error('AUTH_OTP_RESEND_STATUS',response.status);throw Error('Provider rejected request');}
  } catch(e){try{await pool.query('DELETE FROM login_challenges WHERE id=$1',[id]);}catch(cleanup){failure('database_cleanup',cleanup);}throw failure('email_send',e);}
  return {success:true,otpRequired:true,challengeId:id,message:'Check your email for a six-digit code.'};
}
async function consume(kind,id,code) {
  if(!/^[0-9a-f-]{36}$/i.test(String(id))||!/^\d{6}$/.test(String(code)))return null;
  try {const q=await pool.query(`UPDATE login_challenges SET attempts=attempts+1,used=(code_hash=$3) WHERE id=$1 AND kind=$2 AND used=false AND attempts<5 AND created_at>NOW()-INTERVAL '10 minutes' RETURNING subject,email,used`,[id,kind,await digest(id,code)]);return q.rows[0]?.used?q.rows[0]:null;}catch(e){throw failure('verify',e);}
}
module.exports={issue,consume};
