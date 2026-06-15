const https = require('https');

const REPO  = 'kamil911-stack/lexads-landing';
const PATH  = 'livrables/crm-site/prospects.json';
const CORS  = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

function githubReq(path, method, body) {
  const token = process.env.GITHUB_TOKEN;
  const data = body ? JSON.stringify(body) : null;
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.github.com',
      path,
      method,
      headers: {
        'Authorization': `token ${token}`,
        'User-Agent': 'perflux-crm',
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    }, (res) => {
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); }
        catch (e) { reject(new Error('Invalid JSON: ' + raw.slice(0, 200))); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function emptyStep() {
  return { sent: false, sentAt: null, objet: '', corps: '', validated: false, opened: false, openedAt: null, replied: false, repliedAt: null, replyContent: '' };
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return { statusCode: 200, headers: CORS };
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers: CORS };

  let id, step, action;
  try {
    ({ id, step = 'j0', action = 'validate' } = JSON.parse(event.body || '{}'));
  } catch {
    return { statusCode: 400, headers: CORS, body: 'Invalid JSON' };
  }

  if (!id || !process.env.GITHUB_TOKEN) {
    return { statusCode: 400, headers: CORS, body: 'Missing id or GITHUB_TOKEN' };
  }

  try {
    const fileData = await githubReq(`/repos/${REPO}/contents/${PATH}`, 'GET');
    const content  = Buffer.from(fileData.content.replace(/\n/g, ''), 'base64').toString('utf8');
    const prospects = JSON.parse(content);

    const p = prospects.find(x => x.id === id);
    if (!p) return { statusCode: 404, headers: CORS, body: 'Prospect not found' };

    if (!p.seq)       p.seq       = {};
    if (!p.seq[step]) p.seq[step] = emptyStep();

    p.seq[step].validated = (action !== 'unvalidate');

    const newContent = Buffer.from(JSON.stringify(prospects, null, 2), 'utf8').toString('base64');
    await githubReq(`/repos/${REPO}/contents/${PATH}`, 'PUT', {
      message: `CRM: ${action} ${step} — ${id}`,
      content: newContent,
      sha: fileData.sha
    });

    return { statusCode: 200, headers: CORS, body: JSON.stringify({ ok: true }) };
  } catch (err) {
    return { statusCode: 500, headers: CORS, body: err.message };
  }
};
