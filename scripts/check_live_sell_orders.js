const https = require('https');

const orders = [
  { id: 'INJ TP2', symbol: 'INJUSDT', target: 8.3200, coins: 25.14, tpType: 'TP2' },
  { id: 'INJ TP1', symbol: 'INJUSDT', target: 8.1920, coins: 25.14, tpType: 'TP1' },
  { id: 'ALGO Sell', symbol: 'ALGOUSDT', target: 0.1165, coins: 840.0, tpType: 'Rotación' },
  { id: 'XLM Sell', symbol: 'XLMUSDT', target: 0.1840, coins: 446.0, tpType: 'Rotación' },
  { id: 'ADA TP1', symbol: 'ADAUSDT', target: 0.2224, coins: 415.8, tpType: 'TP1' },
  { id: 'ADA TP2', symbol: 'ADAUSDT', target: 0.2278, coins: 508.4, tpType: 'TP2' },
  { id: 'AAVE TP1', symbol: 'AAVEUSDT', target: 152.44, coins: 0.622, tpType: 'TP1' },
  { id: 'AAVE TP2', symbol: 'AAVEUSDT', target: 156.14, coins: 0.731, tpType: 'TP2' },
  { id: 'JUP TP1', symbol: 'JUPUSDT', target: 0.3252, coins: 450.0, tpType: 'TP1' },
  { id: 'JUP TP2', symbol: 'JUPUSDT', target: 0.3331, coins: 505.0, tpType: 'TP2' },
  { id: 'TIA TP1', symbol: 'TIAUSDT', target: 0.6200, coins: 169.0, tpType: 'TP1' },
  { id: 'TIA TP2', symbol: 'TIAUSDT', target: 0.6450, coins: 169.0, tpType: 'TP2' },
  { id: 'OP TP2', symbol: 'OPUSDT', target: 0.1352, coins: 727.08, tpType: 'TP2' },
  { id: 'SUI TP2', symbol: 'SUIUSDT', target: 1.0650, coins: 149.7, tpType: 'TP2' },
];

function fetchTickers() {
  return new Promise((resolve, reject) => {
    https.get('https://api.binance.com/api/v3/ticker/24hr', { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
      let d = '';
      res.on('data', chunk => d += chunk);
      res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });
}

async function run() {
  const data = await fetchTickers();
  const map = {};
  data.forEach(t => map[t.symbol] = t);

  console.log("ORDEN       | SYM      | TARGET    | LIVE PRICE  | DISTANCIA % | VALOR USDT ESPERADO");
  console.log("---------------------------------------------------------------------------------");
  orders.forEach(o => {
    const t = map[o.symbol];
    const live = t ? parseFloat(t.lastPrice) : 0;
    const distPct = ((o.target - live) / live) * 100;
    const expReturn = o.coins * o.target;
    console.log(
      `${o.id.padEnd(11)} | ${o.symbol.padEnd(8)} | $${o.target.toFixed(4).padEnd(9)} | $${live.toFixed(4).padEnd(10)} | ${distPct >= 0 ? '+' : ''}${distPct.toFixed(2).padStart(6)}%   | $${expReturn.toFixed(2)}`
    );
  });
}
run();
