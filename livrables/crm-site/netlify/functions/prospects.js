const https = require('https');

const DATABASE_ID = '9f569df3-84d8-4b0a-a4e2-0e192aa9da2a';

function notionRequest(path, body) {
  const token = process.env.NOTION_API_KEY;
  const data = JSON.stringify(body || {});
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.notion.com',
      path,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); }
        catch (e) { reject(new Error('Invalid JSON from Notion')); }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function prop(page, name, type) {
  const p = page.properties[name];
  if (!p) return '';
  if (type === 'title')      return p.title?.map(t => t.plain_text).join('') || '';
  if (type === 'text')       return p.rich_text?.map(t => t.plain_text).join('') || '';
  if (type === 'select')     return p.select?.name || '';
  if (type === 'email')      return p.email || '';
  if (type === 'phone')      return p.phone_number || '';
  if (type === 'url')        return p.url || '';
  if (type === 'number')     return p.number != null ? String(p.number) : '';
  if (type === 'checkbox')   return p.checkbox === true;
  return '';
}

function emptyStep() {
  return { sent: false, sentAt: null, objet: '', opened: false, openedAt: null, replied: false, repliedAt: null, replyContent: '' };
}

function mapToCRM(page) {
  const email = prop(page, 'Email', 'email');
  const score = parseFloat(prop(page, 'Score', 'number')) || 0;
  const slug = email ? 'p_' + email.toLowerCase().replace(/[@.]/g, '_').replace(/[^a-z0-9_]/g, '') : 'p_' + page.id.replace(/-/g, '').slice(0, 12);
  return {
    id: slug,
    nom: prop(page, 'Nom', 'title'),
    cabinet: prop(page, 'Cabinet', 'text'),
    spec: prop(page, 'Spécialité', 'select'),
    dept: prop(page, 'Département', 'select'),
    ville: prop(page, 'Ville', 'text'),
    email,
    tel: prop(page, 'Téléphone', 'phone'),
    site: prop(page, 'Site web', 'url'),
    linkedin: prop(page, 'LinkedIn', 'url'),
    scoreHunter: String(score),
    tier: score >= 8 ? '1' : score >= 6 ? '2' : '3',
    gads: prop(page, 'Google Ads détectés', 'select') || 'Inconnu',
    groupe: (prop(page, 'Groupe', 'select') || '').toLowerCase(),
    ctx: prop(page, 'Matière à personnalisation', 'text'),
    stage: 'nouveaux',
    dateRdv: '',
    notes: '',
    seq: {
      j0:  { ...emptyStep(), opened: prop(page, 'J0 ouvert',  'checkbox') },
      j3:  { ...emptyStep(), opened: prop(page, 'J3 ouvert',  'checkbox') },
      j7:  { ...emptyStep(), opened: prop(page, 'J7 ouvert',  'checkbox') },
      j14: { ...emptyStep(), opened: prop(page, 'J14 ouvert', 'checkbox') },
    },
    activityLog: [],
    createdAt: page.created_time
  };
}

exports.handler = async () => {
  if (!process.env.NOTION_API_KEY) {
    return { statusCode: 500, body: JSON.stringify({ error: 'NOTION_API_KEY not configured' }) };
  }
  try {
    const prospects = [];
    let cursor;
    do {
      const body = { page_size: 100 };
      if (cursor) body.start_cursor = cursor;
      const result = await notionRequest(`/v1/databases/${DATABASE_ID}/query`, body);
      if (result.object === 'error') throw new Error(result.message);
      (result.results || []).forEach(p => prospects.push(mapToCRM(p)));
      cursor = result.has_more ? result.next_cursor : null;
    } while (cursor);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store'
      },
      body: JSON.stringify(prospects)
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
