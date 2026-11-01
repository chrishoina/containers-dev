import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { SharedArray } from 'k6/data';

// --- Load model: ramp up to 50 concurrent VUs ---
export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '1m', target: 25 },
    { duration: '1m', target: 50 },
    { duration: '3m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  // Optional thresholds:
  // thresholds: {
  //   http_req_failed: ['rate<0.01'],
  //   http_req_duration: ['p(95)<2000'],
  // },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const APP_ID = __ENV.APP_ID || '101';

// Keep users in a SharedArray so they’re loaded once (memory-efficient)
const users = new SharedArray('users', function () {
  return [
    { username: 'user01@mail.com', password: 'Password12345!' },
    { username: 'user02@mail.com', password: 'Password12345!' },
    { username: 'user03@mail.com', password: 'Password12345!' },
    { username: 'user04@mail.com', password: 'Password12345!' },
    { username: 'user05@mail.com', password: 'Password12345!' },
    { username: 'user06@mail.com', password: 'Password12345!' },
    { username: 'user07@mail.com', password: 'Password12345!' },
    { username: 'user08@mail.com', password: 'Password12345!' },
    { username: 'user09@mail.com', password: 'Password12345!' },
    { username: 'user10@mail.com', password: 'Password12345!' },
    { username: 'user11@mail.com', password: 'Password12345!' },
    { username: 'user12@mail.com', password: 'Password12345!' },
    { username: 'user13@mail.com', password: 'Password12345!' },
    { username: 'user14@mail.com', password: 'Password12345!' },
    { username: 'user15@mail.com', password: 'Password12345!' },
    { username: 'user16@mail.com', password: 'Password12345!' },
    { username: 'user17@mail.com', password: 'Password12345!' },
    { username: 'user18@mail.com', password: 'Password12345!' },
    { username: 'user19@mail.com', password: 'Password12345!' },
    { username: 'user20@mail.com', password: 'Password12345!' },
    { username: 'user21@mail.com', password: 'Password12345!' },
    { username: 'user22@mail.com', password: 'Password12345!' },
    { username: 'user23@mail.com', password: 'Password12345!' },
    { username: 'user24@mail.com', password: 'Password12345!' },
    { username: 'user25@mail.com', password: 'Password12345!' },
    { username: 'user26@mail.com', password: 'Password12345!' },
    { username: 'user27@mail.com', password: 'Password12345!' },
    { username: 'user28@mail.com', password: 'Password12345!' },
    { username: 'user29@mail.com', password: 'Password12345!' },
    { username: 'user30@mail.com', password: 'Password12345!' },
    { username: 'user31@mail.com', password: 'Password12345!' },
    { username: 'user32@mail.com', password: 'Password12345!' },
    { username: 'user33@mail.com', password: 'Password12345!' },
    { username: 'user34@mail.com', password: 'Password12345!' },
    { username: 'user35@mail.com', password: 'Password12345!' },
    { username: 'user36@mail.com', password: 'Password12345!' },
    { username: 'user37@mail.com', password: 'Password12345!' },
    { username: 'user38@mail.com', password: 'Password12345!' },
    { username: 'user39@mail.com', password: 'Password12345!' },
    { username: 'user40@mail.com', password: 'Password12345!' },
    { username: 'user41@mail.com', password: 'Password12345!' },
    { username: 'user42@mail.com', password: 'Password12345!' },
    { username: 'user43@mail.com', password: 'Password12345!' },
    { username: 'user44@mail.com', password: 'Password12345!' },
    { username: 'user45@mail.com', password: 'Password12345!' },
    { username: 'user46@mail.com', password: 'Password12345!' },
    { username: 'user47@mail.com', password: 'Password12345!' },
    { username: 'user48@mail.com', password: 'Password12345!' },
    { username: 'user49@mail.com', password: 'Password12345!' },
    { username: 'user50@mail.com', password: 'Password12345!' },
  ];
});

function userForThisVU() {
  // k6 VU ids start at 1
  return users[(__VU - 1) % users.length];
}

// Basic HTML value extraction for correlation (adjust if your markup differs)
function extractInputValue(html, name) {
  const re = new RegExp(`name="${name}"[^>]*value="([^"]*)"`, 'i');
  const m = html.match(re);
  return m ? m[1] : null;
}

function loginApex({ username, password }) {
  // 1) GET login page (cookies/session established per VU automatically)
  const loginPageUrl = `${BASE_URL}/ords/r/k6_testing/brookstrut/login`;
  let res = http.get(loginPageUrl);

  check(res, { 'GET login page is 200': (r) => r.status === 200 });

  // 2) Correlate required hidden values from the HTML (common APEX fields)
  const pInstance = extractInputValue(res.body, 'p_instance');
  const pFlowId = extractInputValue(res.body, 'p_flow_id') || APP_ID;
  const pFlowStepId =
    extractInputValue(res.body, 'p_flow_step_id') ||
    extractInputValue(res.body, 'p_flow_step_id'); // left as-is; see TODO below
  const pPageSubmissionId = extractInputValue(res.body, 'p_page_submission_id');

  // Optional fields sometimes present:
  const pRequest = extractInputValue(res.body, 'p_request') || 'LOGIN';

  // 3) POST credentials to APEX accept endpoint
  // NOTE: This is where you MUST align to your app:
  // - login page number (e.g. 9999 or 101)
  // - item names for username/password (e.g. P9999_USERNAME / P9999_PASSWORD)
  //
  // TODO: Inspect your login page HTML and set:
  //   LOGIN_PAGE_ID, USER_ITEM, PASS_ITEM
  const LOGIN_PAGE_ID = __ENV.LOGIN_PAGE_ID || '101';       // <-- TODO likely not 101
  const USER_ITEM = __ENV.USER_ITEM || 'P101_USERNAME';      // <-- TODO likely different
  const PASS_ITEM = __ENV.PASS_ITEM || 'P101_PASSWORD';      // <-- TODO likely different

  const postUrl = `${BASE_URL}/ords/wwv_flow.accept`;

  const form = {
    p_flow_id: pFlowId,
    p_flow_step_id: LOGIN_PAGE_ID,         // important: login page id
    p_instance: pInstance,
    p_request: pRequest,
    p_page_submission_id: pPageSubmissionId,

    [USER_ITEM]: username,
    [PASS_ITEM]: password,
  };

  res = http.post(postUrl, form, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    redirects: 0, // helps detect success via redirect
  });

  // Successful APEX login often responds with 302/303
  check(res, {
    'POST login returns redirect (likely success)': (r) =>
      r.status === 302 || r.status === 303,
  });

  return res;
}

export default function () {
  const u = userForThisVU();

  group('APEX login + home', () => {
    // Start clean-ish each iteration (optional): hit logout endpoint first
    // (Avoid hard-coded p_session_id; just call logout without it.)
    http.get(`${BASE_URL}/ords/apex_authentication.logout`);

    // Login per VU
    loginApex(u);

    // Hit an authenticated page (your original script calls /home)
    const home = http.get(`${BASE_URL}/ords/r/k6_testing/brookstrut/home`);
    check(home, { 'GET home is 200': (r) => r.status === 200 });

    sleep(1);
  });
}