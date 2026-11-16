const crypto=require('crypto'),pool=require('../db');
const digest=(id,code)=>crypto.createHmac('sha256',process.env.JWT_SECRET).update(id+':'+code).digest('hex');
async function issue(kind,user){
 const id=crypto.randomUUID(),code=String(crypto.randomInt(100000,1000000));
 if(!process.env.RESEND_API_KEY||!process.env.ARIKE_FROM_EMAIL||!user.email||!process.env.JWT_SECRET) throw Error('Email configuration missing');
 const q=await pool.query(`INSERT INTO login_challenges(id,kind,subject,email,code_hash) VALUES($1,$2,$3,$4,$5) ON CONFLICT(kind,subject) DO UPDATE SET id=EXCLUDED.id,email=EXCLUDED.email,code_hash=EXCLUDED.code_hash,created_at=NOW(),attempts=0,used=false WHERE login_challenges.created_at < NOW()-INTERVAL '60 seconds' RETURNING id`,[id,kind,String(user.id),user.email,digest(id,code)]);
 if(!q.rows.length){const e=Error('Wait 60 seconds before requesting another code.');e.status=429;throw e;}
 try{const response=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:'Bearer '+process.env.RESEND_API_KEY,'Content-Type':'application/json'},body:JSON.stringify({from:process.env.ARIKE_FROM_EMAIL,to:[user.email],subject:'ArikePreorder security code',text:'Your verification code is '+code+'. Expires in 10 minutes. Never share this code.'})});if(!response.ok)throw Error('Email delivery request rejected');}catch(e){await pool.query('DELETE FROM login_challenges WHERE id=$1',[id]);throw e;}
 return {success:true,otpRequired:true,challengeId:id,message:'Check your email for a six-digit code.'};
}
async function consume(kind,id,code){if(!/^[0-9a-f-]{36}$/i.test(String(id))||!/^\d{6}$/.test(String(code)))return null;
 const q=await pool.query(`UPDATE login_challenges SET attempts=attempts+1,used=(code_hash=$3) WHERE id=$1 AND kind=$2 AND used=false AND attempts<5 AND created_at>NOW()-INTERVAL '10 minutes' RETURNING subject,email,used`,[id,kind,digest(id,code)]);return q.rows[0]?.used?q.rows[0]:null;}
module.exports={issue,consume};
