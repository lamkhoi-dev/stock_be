/**
 * KIS (Korea Investment & Securities) Open API — Test Script
 * 한국투자증권 Open API 테스트
 * 
 * Tests:
 *  1. OAuth2 Token 발급 (접근토큰)
 *  2. 주식현재가 시세 (Stock Current Price)
 *  3. 주식현재가 체결 (Stock Execution/Trade)
 *  4. 국내주식기간별시세 (Period Price - Daily OHLCV)
 *  5. 주식당일분봉조회 (Intraday Minute Candle)
 *  6. 거래량순위 (Volume Ranking)
 *  7. 국내업종 현재지수 (Market Index - KOSPI/KOSDAQ)
 *  8. 국내주식 등락률 순위 (Top Gainers/Losers)
 */

import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

// ============================================================
//  CONFIG
// ============================================================
const BASE_URL = 'https://openapi.koreainvestment.com:9443';
const APP_KEY  = 'PSsw5JXblDis6LZJ1tSqMbLwUQFOqQLlopQR';
const APP_SECRET = '0xg6RH037SyXviB49SxYRjSihI6rnWnOfPdDmPGO83blrJddgPVtyYFM3r5JFo50qobhCX0hG1EUIGDUOvcUUDcIrYakX5L3Y+HAQWEDFhv02/SeIQvcTznbhCjhgKnpJFoHaHSiqiN4vDSgwgXV5yGhuZCmHabSf/d9YNK/VSppa+EtS6E=';

let ACCESS_TOKEN = '';

const commonHeaders = () => ({
  'Content-Type': 'application/json; charset=utf-8',
  'Accept': 'text/plain',
  'charset': 'UTF-8',
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  'authorization': `Bearer ${ACCESS_TOKEN}`,
  'appkey': APP_KEY,
  'appsecret': APP_SECRET,
  'custtype': 'P',
});

// ============================================================
// HELPER – pretty print
// ============================================================
function printSection(title) {
  console.log('\n' + '='.repeat(60));
  console.log(`  ${title}`);
  console.log('='.repeat(60));
}

function printResult(label, data) {
  if (typeof data === 'object') {
    console.log(`\n[${label}]`);
    const json = JSON.stringify(data, null, 2);
    // Limit output length to keep terminal readable
    if (json.length > 2000) {
      console.log(json.substring(0, 2000) + '\n... (truncated)');
    } else {
      console.log(json);
    }
  } else {
    console.log(`[${label}] ${data}`);
  }
}

// ============================================================
// 1) OAuth2 Token 발급
// ============================================================
async function getAccessToken() {
  printSection('1. OAuth2 접근토큰 발급 (Access Token)');

  try {
    const url = `${BASE_URL}/oauth2/tokenP`;
    const body = {
      grant_type: 'client_credentials',
      appkey: APP_KEY,
      appsecret: APP_SECRET,
    };

    console.log(`POST ${url}`);
    const res = await axios.post(url, body, {
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    });

    if (res.status === 200 && res.data.access_token) {
      ACCESS_TOKEN = res.data.access_token;
      console.log('✅ 토큰 발급 성공!');
      console.log(`   Token (first 40 chars): ${ACCESS_TOKEN.substring(0, 40)}...`);
      console.log(`   만료일시: ${res.data.access_token_token_expired}`);
      console.log(`   Token type: ${res.data.token_type}`);
      console.log(`   유효기간: ${res.data.expires_in}초`);
      return true;
    } else {
      console.log('❌ 토큰 발급 실패:', res.data);
      return false;
    }
  } catch (err) {
    console.log('❌ 토큰 발급 에러:');
    if (err.response) {
      console.log(`   Status: ${err.response.status}`);
      console.log(`   Data:`, err.response.data);
    } else {
      console.log(`   ${err.message}`);
    }
    return false;
  }
}

// ============================================================
// 2) 주식현재가 시세 — Samsung Electronics (005930)
// ============================================================
async function testStockPrice() {
  printSection('2. 주식현재가 시세 (삼성전자 005930)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-price`;
    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHKST01010100',  // 주식현재가 시세
    };
    const params = {
      FID_COND_MRKT_DIV_CODE: 'J',  // J=주식
      FID_INPUT_ISCD: '005930',      // 삼성전자
    };

    console.log(`GET ${url}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output } = res.data;

    if (rt_cd === '0') {
      console.log('✅ 조회 성공!');
      console.log(`   종목명: ${output.hts_kor_isnm || 'N/A'}`);
      console.log(`   현재가: ₩${Number(output.stck_prpr).toLocaleString()}`);
      console.log(`   전일 대비: ${output.prdy_vrss} (${output.prdy_ctrt}%)`);
      console.log(`   시가: ₩${Number(output.stck_oprc).toLocaleString()}`);
      console.log(`   고가: ₩${Number(output.stck_hgpr).toLocaleString()}`);
      console.log(`   저가: ₩${Number(output.stck_lwpr).toLocaleString()}`);
      console.log(`   거래량: ${Number(output.acml_vol).toLocaleString()}`);
      console.log(`   거래대금: ₩${Number(output.acml_tr_pbmn).toLocaleString()}`);
      console.log(`   52주 최고: ₩${Number(output.stck_mxpr).toLocaleString()}`);
      console.log(`   52주 최저: ₩${Number(output.stck_llam).toLocaleString()}`);
      console.log(`   PER: ${output.per}`);
      console.log(`   PBR: ${output.pbr}`);
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// 3) 주식현재가 체결 (Recent Trades)
// ============================================================
async function testStockExecution() {
  printSection('3. 주식현재가 체결 (삼성전자 체결 내역)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-ccnl`;
    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHKST01010300',  // 주식현재가 체결
    };
    const params = {
      FID_COND_MRKT_DIV_CODE: 'J',
      FID_INPUT_ISCD: '005930',
    };

    console.log(`GET ${url}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output } = res.data;

    if (rt_cd === '0' && output) {
      console.log('✅ 체결 조회 성공!');
      const trades = Array.isArray(output) ? output.slice(0, 5) : [output];
      trades.forEach((t, i) => {
        console.log(`   [${i + 1}] 시간: ${t.stck_cntg_hour} | 체결가: ₩${Number(t.stck_prpr).toLocaleString()} | 체결량: ${t.cntg_vol} | 누적: ${Number(t.acml_vol).toLocaleString()}`);
      });
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// 4) 국내주식기간별시세 — Daily OHLCV (일봉)
// ============================================================
async function testDailyOHLCV() {
  printSection('4. 국내주식기간별시세 — 일봉 (삼성전자 최근 10일)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice`;
    const today = new Date();
    const endDate = today.toISOString().slice(0, 10).replace(/-/g, '');
    const startDate = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)
      .toISOString().slice(0, 10).replace(/-/g, '');

    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHKST03010100',  // 국내주식기간별시세(일/주/월/년)
    };
    const params = {
      FID_COND_MRKT_DIV_CODE: 'J',
      FID_INPUT_ISCD: '005930',
      FID_INPUT_DATE_1: startDate,
      FID_INPUT_DATE_2: endDate,
      FID_PERIOD_DIV_CODE: 'D',  // D=일, W=주, M=월, Y=년
      FID_ORG_ADJ_PRC: '0',     // 0=수정주가, 1=원주가
    };

    console.log(`GET ${url}`);
    console.log(`   기간: ${startDate} ~ ${endDate}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output1, output2 } = res.data;

    if (rt_cd === '0') {
      console.log('✅ 일봉 조회 성공!');
      if (output1) {
        console.log(`   종목명: ${output1.hts_kor_isnm || 'N/A'}`);
        console.log(`   현재가: ₩${Number(output1.stck_prpr).toLocaleString()}`);
      }
      if (output2 && output2.length > 0) {
        console.log(`   일봉 데이터 ${output2.length}개:`);
        output2.slice(0, 10).forEach(d => {
          console.log(`   ${d.stck_bsop_date} | O:${Number(d.stck_oprc).toLocaleString()} H:${Number(d.stck_hgpr).toLocaleString()} L:${Number(d.stck_lwpr).toLocaleString()} C:${Number(d.stck_clpr).toLocaleString()} | Vol:${Number(d.acml_vol).toLocaleString()}`);
        });
      }
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// 5) 주식당일분봉조회 (Intraday Minute Candles)
// ============================================================
async function testMinuteCandles() {
  printSection('5. 주식당일분봉조회 — 분봉 (삼성전자)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice`;
    const now = new Date();
    // Use previous market close time if market is not open
    const timeStr = '153000'; // 15:30:00 KST

    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHKST03010200',  // 주식당일분봉조회
    };
    const params = {
      FID_ETC_CLS_CODE: '',
      FID_COND_MRKT_DIV_CODE: 'J',
      FID_INPUT_ISCD: '005930',
      FID_INPUT_HOUR_1: timeStr,
      FID_PW_DATA_INCU_YN: 'N',
    };

    console.log(`GET ${url}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output1, output2 } = res.data;

    if (rt_cd === '0') {
      console.log('✅ 분봉 조회 성공!');
      if (output2 && output2.length > 0) {
        console.log(`   분봉 데이터 ${output2.length}개 (최근 10개):`);
        output2.slice(0, 10).forEach(d => {
          const t = d.stck_cntg_hour;
          const time = `${t.slice(0, 2)}:${t.slice(2, 4)}:${t.slice(4, 6)}`;
          console.log(`   ${time} | O:${Number(d.stck_oprc).toLocaleString()} H:${Number(d.stck_hgpr).toLocaleString()} L:${Number(d.stck_lwpr).toLocaleString()} C:${Number(d.stck_prpr).toLocaleString()} | Vol:${Number(d.cntg_vol).toLocaleString()}`);
        });
      } else {
        console.log('   ⚠️ 분봉 데이터 없음 (시장 마감 후일 수 있음)');
      }
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// 6) 거래량순위 (Volume Ranking)
// ============================================================
async function testVolumeRanking() {
  printSection('6. 거래량순위 (Volume Ranking)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/volume-rank`;
    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHPST01710000',  // 거래량순위
    };
    const params = {
      FID_COND_MRKT_DIV_CODE: 'J',   // J=전체, 0=KOSPI, 1=KOSDAQ
      FID_COND_SCR_DIV_CODE: '20101',
      FID_INPUT_ISCD: '0000',         // 전체
      FID_DIV_CLS_CODE: '0',         // 0=전체
      FID_BLNG_CLS_CODE: '0',        // 0=전체
      FID_TRGT_CLS_CODE: '111111111', 
      FID_TRGT_EXLS_CLS_CODE: '0000000000',
      FID_INPUT_PRICE_1: '',
      FID_INPUT_PRICE_2: '',
      FID_VOL_CNT: '',
      FID_INPUT_DATE_1: '',
    };

    console.log(`GET ${url}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output } = res.data;

    if (rt_cd === '0' && output) {
      console.log('✅ 거래량순위 조회 성공!');
      const list = Array.isArray(output) ? output.slice(0, 15) : [output];
      list.forEach((s, i) => {
        const change = Number(s.prdy_ctrt) >= 0 ? `▲${s.prdy_ctrt}%` : `▼${s.prdy_ctrt}%`;
        console.log(`   ${String(i + 1).padStart(2)}. ${s.hts_kor_isnm?.padEnd(12) || 'N/A'} | ₩${Number(s.stck_prpr).toLocaleString().padStart(10)} | ${change.padStart(8)} | Vol: ${Number(s.acml_vol).toLocaleString()}`);
      });
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// 7) 국내업종 현재지수 (KOSPI / KOSDAQ Index)
// ============================================================
async function testMarketIndex() {
  printSection('7. 국내업종 현재지수 (KOSPI & KOSDAQ)');

  const indices = [
    { code: '0001', name: 'KOSPI' },
    { code: '1001', name: 'KOSDAQ' },
  ];
  
  for (const idx of indices) {
    try {
      const url = `${BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-index-price`;
      const headers = {
        ...commonHeaders(),
        'tr_id': 'FHPUP02100000',  // 국내업종 현재지수
      };
      const params = {
        FID_COND_MRKT_DIV_CODE: 'U',  // U=업종
        FID_INPUT_ISCD: idx.code,
      };

      const res = await axios.get(url, { headers, params });
      const { rt_cd, msg_cd, msg1, output } = res.data;

      if (rt_cd === '0' && output) {
        const change = Number(output.prdy_vrss) >= 0 ? `▲${output.prdy_vrss}` : `▼${output.prdy_vrss}`;
        console.log(`   ${idx.name}: ${output.bstp_nmix_prpr} (${change}, ${output.prdy_vrss_sign === '1' || output.prdy_vrss_sign === '2' ? '+' : '-'}${output.bstp_nmix_prdy_ctrt}%)`);
      } else {
        console.log(`   ${idx.name}: ❌ [${msg_cd}] ${msg1}`);
      }
    } catch (err) {
      console.log(`   ${idx.name}: ❌ ${err.response?.data?.msg1 || err.message}`);
    }
  }
}

// ============================================================
// 8) 국내주식 등락률 순위 (Top Gainers / Losers)
// ============================================================
async function testTopMovers() {
  printSection('8. 국내주식 등락률 순위 (Top Gainers)');

  try {
    const url = `${BASE_URL}/uapi/domestic-stock/v1/ranking/fluctuation`;
    const headers = {
      ...commonHeaders(),
      'tr_id': 'FHPST01700000',  // 국내주식 등락률 순위
    };
    const params = {
      fid_cond_mrkt_div_code: 'J',
      fid_cond_scr_div_code: '20170',
      fid_input_iscd: '0000',
      fid_rank_sort_cls_code: '0',  // 0=상승률, 1=하락률
      fid_input_cnt_1: '0',
      fid_prc_cls_code: '0',
      fid_input_price_1: '',
      fid_input_price_2: '',
      fid_vol_cnt: '',
      fid_trgt_cls_code: '0',
      fid_trgt_exls_cls_code: '0',
      fid_div_cls_code: '0',
      fid_rsfl_rate1: '',
      fid_rsfl_rate2: '',
    };

    console.log(`GET ${url}`);
    const res = await axios.get(url, { headers, params });
    const { rt_cd, msg_cd, msg1, output } = res.data;

    if (rt_cd === '0' && output) {
      console.log('✅ 등락률순위 조회 성공!');
      const list = Array.isArray(output) ? output.slice(0, 10) : [output];
      list.forEach((s, i) => {
        console.log(`   ${String(i + 1).padStart(2)}. ${(s.hts_kor_isnm || '').padEnd(12)} | ₩${Number(s.stck_prpr).toLocaleString().padStart(10)} | ▲${s.prdy_ctrt}% | Vol: ${Number(s.acml_vol).toLocaleString()}`);
      });
    } else {
      console.log(`❌ 조회 실패: [${msg_cd}] ${msg1}`);
      if (res.data) printResult('Response', res.data);
    }
  } catch (err) {
    handleError(err);
  }
}

// ============================================================
// Error handler
// ============================================================
function handleError(err) {
  if (err.response) {
    console.log(`❌ HTTP ${err.response.status}`);
    const data = err.response.data;
    if (data) {
      console.log(`   rt_cd: ${data.rt_cd}, msg_cd: ${data.msg_cd}, msg1: ${data.msg1}`);
    }
  } else {
    console.log(`❌ Error: ${err.message}`);
  }
}

// ============================================================
// MAIN
// ============================================================
async function main() {
  console.log('\n🇰🇷 ========================================');
  console.log('   KIS Open API Test — 한국투자증권 API 테스트');
  console.log('   ========================================\n');
  console.log(`   Base URL: ${BASE_URL}`);
  console.log(`   App Key:  ${APP_KEY.substring(0, 10)}...`);
  console.log(`   Time:     ${new Date().toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' })} KST`);

  // Step 1: Get token
  const tokenOk = await getAccessToken();
  if (!tokenOk) {
    console.log('\n🛑 토큰 발급 실패 — 테스트 중단');
    console.log('   원인: APP Key / APP Secret이 올바르지 않거나 계정이 비활성 상태');
    return;
  }

  // Step 2: Test endpoints (with small delay between calls to avoid rate limit)
  const delay = (ms) => new Promise(r => setTimeout(r, ms));

  await testStockPrice();
  await delay(200);
  
  await testStockExecution();
  await delay(200);

  await testDailyOHLCV();
  await delay(200);

  await testMinuteCandles();
  await delay(200);

  await testVolumeRanking();
  await delay(200);

  await testMarketIndex();
  await delay(200);

  await testTopMovers();

  // Summary
  printSection('📊 테스트 완료 — Summary');
  console.log('  위 결과를 확인하세요.');
  console.log('  ✅ = 성공, ❌ = 실패, ⚠️ = 주의');
  console.log('  Token은 24시간 유효합니다 (6시간 이내 재발급 시 동일 토큰)');
  console.log('');
}

main().catch(err => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
