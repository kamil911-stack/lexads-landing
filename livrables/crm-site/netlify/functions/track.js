const https = require('https');

const PIXEL = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
const STEP_MAP = { j0: 'J0 ouvert', j3: 'J3 ouvert', j7: 'J7 ouvert', j14: 'J14 ouvert' };

function patchNotion(pageId, propName) {
  const token = process.env.NOTION_API_KEY;
  const data = JSON.stringify({ properties: { [propName]: { checkbox: true } } });
  return new Promise((resolve) => {
    const req = https.request({
      hostname: 'api.notion.com',
      path: `/v1/pages/${pageId}`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => { res.on('data', () => {}); res.on('end', resolve); });
    req.on('error', resolve);
    req.write(data);
    req.end();
  });
}

exports.handler = async (event) => {
  const { page, step = 'j0' } = event.queryStringParameters || {};
  const propName = STEP_MAP[(step || 'j0').toLowerCase()] || 'J0 ouvert';

  if (page && process.env.NOTION_API_KEY) {
    await patchNotion(page, propName).catch(() => {});
  }

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'image/gif',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache'
    },
    body: PIXEL.toString('base64'),
    isBase64Encoded: true
  };
};
