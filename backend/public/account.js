const token=localStorage.getItem('arike_token');if(!token)location.href='/login';
const H={'Content-Type':'application/json',Authorization:'Bearer '+token};let me;
const $=id=>document.getElementById(id);
const msg=(id,t,ok=true)=>$(id).innerHTML=`<div class="notice ${ok?'success':'danger'}" style="margin-top:12px">${t}</div>`;
function kycView(raw){const s=String(raw||'not_submitted').toLowerCase();if(s==='verified')return['Verified','verified'];if(s==='pending'||s==='under_review')return['Under Review','pending'];if(['failed','rejected','needs_attention'].includes(s))return['Needs Attention','attention'];return['Not Verified','unverified']}
async function load(){
 const d=await fetch('/api/auth/me',{headers:H}).then(r=>r.json());
 if(!d.success){localStorage.removeItem('arike_token');location.href='/login';return}
 me=d.user;
 $('name').textContent=[me.first_name,me.last_name].filter(Boolean).join(' ');
 $('username').textContent='@'+me.username;
 $('avatar').textContent=((me.first_name||'A')[0]+(me.last_name||'P')[0]).toUpperCase();
 const values={firstName:me.first_name,lastName:me.last_name,usernameEdit:me.username,email:me.email,phone:me.phone,country:me.country,state:me.state,city:me.city,address:me.address};
 Object.entries(values).forEach(([id,v])=>{$(id).value=v||''});
 $('legalName').value=[me.first_name,me.last_name].filter(Boolean).join(' ');
 const [label,cls]=kycView(me.kyc_status);$('kycBadge').textContent=label;$('kycBadge').className='status kyc-badge '+cls;
 $('pinExisting').style.display=me.pin_set?'block':'none';$('pinCreate').style.display=me.pin_set?'none':'block';
}
async function saveProfileOnly(msgId,closeId){
 const body={firstName:$('firstName').value,lastName:$('lastName').value,username:$('usernameEdit').value,email:$('email').value,phone:$('phone').value,country:$('country').value,state:$('state').value,city:$('city').value,address:$('address').value};
 const r=await fetch('/api/auth/profile',{method:'POST',headers:H,body:JSON.stringify(body)});const d=await r.json();msg(msgId,d.message,d.success);
 if(d.success){await load();setTimeout(()=>{if(closeId)$(closeId).open=false},500)}
}
$('saveProfile').onclick=()=>saveProfileOnly('profileMsg','personalDetails');$('saveAddress').onclick=()=>saveProfileOnly('addressMsg');
$('savePin').onclick=async()=>{const d=await fetch('/api/auth/pin',{method:'POST',headers:H,body:JSON.stringify({pin:$('pin').value,currentPassword:$('pinPassword').value})}).then(r=>r.json());msg('pinMsg',d.message,d.success);if(d.success){$('pin').value='';$('pinPassword').value='';load()}};
$('submitKyc').onclick=async()=>{const d=await fetch('/api/auth/kyc',{method:'POST',headers:H,body:JSON.stringify({legalName:$('legalName').value,documentType:$('docType').value,documentNumber:$('docNumber').value})}).then(r=>r.json());msg('kycMsg',d.message,d.success);if(d.success)load()};
$('kycBadge').onclick=()=>{$('kycDetails').open=true;$('kycDetails').scrollIntoView({behavior:'smooth',block:'center'})};
load();
