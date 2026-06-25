(() => {
      'use strict';

      /* ═══ i18n ════════════════════════════════════════════ */
      const T = {
        vi: {
          heroBadge: '🔍 Phân tích mã độc tĩnh',
          heroTitle: 'Phân Tích Mã Độc<br>Toàn Diện &amp; Tức Thì',
          heroDesc: 'Tải file lên để nhận báo cáo phân tích đầy đủ — cấu trúc PE, YARA, entropy, IoC, MITRE ATT&amp;CK và điểm rủi ro.',
          uploadTitle: 'Kéo thả file vào đây',
          uploadDesc: 'hoặc <span class="browse-link" id="browseLink">chọn file</span> từ máy tính — tối đa 32 MB',
          analyzeBtn: 'Phân tích →',
          progressTitle: 'Đang phân tích file...',
          progressSub: 'Có thể mất vài giây tuỳ kích thước file.',
          errorTitle: '⚠ Phân tích thất bại',
          statusOnline: 'Trực tuyến',
          statusOffline: 'Ngoại tuyến',
          statusCheck: 'Đang kiểm tra...',
          footer: '🛡 Malware Analyzer · Phân tích thực hiện phía máy chủ · File bị xóa ngay sau khi phân tích',
          /* result sections */
          riskTitle: 'Đánh giá Rủi ro',
          fileInfo: 'Thông tin File',
          entropyTitle: 'Phân tích Entropy',
          peTitle: 'Phân tích PE',
          deepTitle: 'Phân tích tĩnh chuyên sâu',
          stringsTitle: 'Chuỗi &amp; IoC',
          yaraTitle: 'YARA',
          vtTitle: 'VirusTotal',
          mitreTitle: 'MITRE ATT&amp;CK',
          riskFactors: 'Yếu tố Rủi ro',
          analysisWarn: 'Cảnh báo phân tích',
          rawJson: 'Báo cáo JSON thô',
          dlHtml: '📄 Tải báo cáo HTML',
          dlJson: '📁 Tải báo cáo JSON',
          dlStix: '🔒 Xuất STIX 2.1 Bundle',
          newAnalysis: '↺ Phân tích file mới',
          copyBtn: 'Sao chép',
          copied: 'Đã sao chép!',
          copyJson: 'Sao chép JSON',
          copiedJson: 'Đã sao chép!',
          networkErr: 'Lỗi kết nối mạng — không thể liên hệ máy chủ.',
          sections: 'Sections',
          susImports: 'Suspicious Imports',
          filename: 'Tên file',
          filetype: 'Loại file',
          filesize: 'Kích thước',
          overall: 'Tổng thể',
          stats: 'Thống kê',
          arch: 'Kiến trúc',
          compileTime: 'Thời gian biên dịch',
          entryPoint: 'Entry Point',
          impHash: 'Import Hash',
          detections: 'Phát hiện',
          scanDate: 'Ngày quét',
          report: 'Báo cáo',
          vtLink: 'Xem trên VirusTotal ↗',
          riskSummary: 'Điểm',
          entVerdict: ['Bình thường', 'Entropy cao vừa', 'Có thể bị packer/mã hóa'],
          more: 'nữa',
          iocLabels: { urls: 'URLs', ipv4: 'Địa chỉ IPv4', emails: 'Email', domains: 'Tên miền', registry_keys: 'Registry Keys', file_paths: 'Đường dẫn File' },
          pageTitle: 'Malware Analyzer — Nền tảng phân tích mã độc tĩnh',
        },
        en: {
          heroBadge: '🔍 Static Malware Analysis',
          heroTitle: 'Comprehensive Malware<br>Analysis &amp; Threat Intel',
          heroDesc: 'Upload a suspicious file for a full analysis report — PE structure, YARA, entropy, IoC, MITRE ATT&amp;CK mapping and risk scoring.',
          uploadTitle: 'Drop your file here',
          uploadDesc: 'or <span class="browse-link" id="browseLink">browse</span> to select — max 32 MB',
          analyzeBtn: 'Analyze →',
          progressTitle: 'Analyzing file...',
          progressSub: 'This may take a few seconds depending on file size.',
          errorTitle: '⚠ Analysis Failed',
          statusOnline: 'Online',
          statusOffline: 'Offline',
          statusCheck: 'Checking...',
          footer: '🛡 Malware Analyzer · All analysis is server-side · Files are deleted after analysis',
          riskTitle: 'Risk Assessment',
          fileInfo: 'File Information',
          entropyTitle: 'Entropy Analysis',
          peTitle: 'PE Analysis',
          deepTitle: 'Deep Static Analysis',
          stringsTitle: 'Strings &amp; IoCs',
          yaraTitle: 'YARA',
          vtTitle: 'VirusTotal',
          mitreTitle: 'MITRE ATT&amp;CK',
          riskFactors: 'Risk Factors',
          analysisWarn: 'Analysis Warnings',
          rawJson: 'Raw JSON Report',
          dlHtml: '📄 Download HTML Report',
          dlJson: '📁 Download JSON Report',
          dlStix: '🔒 Export STIX 2.1 Bundle',
          newAnalysis: '↺ New Analysis',
          copyBtn: 'Copy',
          copied: 'Copied!',
          copyJson: 'Copy JSON',
          copiedJson: 'Copied!',
          networkErr: 'Network error — could not reach the server.',
          sections: 'Sections',
          susImports: 'Suspicious Imports',
          filename: 'Filename',
          filetype: 'File Type',
          filesize: 'Size',
          overall: 'Overall',
          stats: 'Stats',
          arch: 'Architecture',
          compileTime: 'Compile Time',
          entryPoint: 'Entry Point',
          impHash: 'Import Hash',
          detections: 'Detections',
          scanDate: 'Scan Date',
          report: 'Report',
          vtLink: 'View on VirusTotal ↗',
          riskSummary: 'Score',
          entVerdict: ['Normal', 'Moderately high', 'Likely packed/encrypted'],
          more: 'more',
          iocLabels: { urls: 'URLs', ipv4: 'IPv4 Addresses', emails: 'Emails', domains: 'Domains', registry_keys: 'Registry Keys', file_paths: 'File Paths' },
          pageTitle: 'Malware Analyzer — Static Analysis Platform',
        },
        zh: {
          heroBadge: '🔍 静态恶意软件分析',
          heroTitle: '全面的恶意软件<br>分析与威胁情报',
          heroDesc: '上传可疑文件获取完整分析报告 — PE 结构, YARA, 熵, IoC, MITRE ATT&amp;CK 映射和风险评分。',
          uploadTitle: '将文件拖放到此处',
          uploadDesc: '或 <span class="browse-link" id="browseLink">浏览文件</span> — 最大 32 MB',
          analyzeBtn: '分析 →',
          progressTitle: '正在分析文件...',
          progressSub: '根据文件大小可能需要几秒钟。',
          errorTitle: '⚠ 分析失败',
          statusOnline: '在线',
          statusOffline: '离线',
          statusCheck: '检查中...',
          footer: '🛡 恶意软件分析器 · 所有分析在服务器端进行 · 文件分析后即被删除',
          riskTitle: '风险评估',
          fileInfo: '文件信息',
          entropyTitle: '熵分析',
          peTitle: 'PE 分析',
          deepTitle: '深度静态分析',
          stringsTitle: '字符串 &amp; IoCs',
          yaraTitle: 'YARA',
          vtTitle: 'VirusTotal',
          mitreTitle: 'MITRE ATT&amp;CK',
          riskFactors: '风险因素',
          analysisWarn: '分析警告',
          rawJson: '原始 JSON 报告',
          dlHtml: '📄 下载 HTML 报告',
          dlJson: '📁 下载 JSON 报告',
          dlStix: '🔒 导出 STIX 2.1 包',
          newAnalysis: '↺ 重新分析',
          copyBtn: '复制',
          copied: '已复制！',
          copyJson: '复制 JSON',
          copiedJson: '已复制！',
          networkErr: '网络错误 — 无法连接到服务器。',
          sections: '节区 (Sections)',
          susImports: '可疑导入 (Suspicious)',
          filename: '文件名',
          filetype: '文件类型',
          filesize: '大小',
          overall: '总体',
          stats: '统计',
          arch: '架构',
          compileTime: '编译时间',
          entryPoint: '入口点',
          impHash: 'Import Hash',
          detections: '检测结果',
          scanDate: '扫描日期',
          report: '报告',
          vtLink: '在 VirusTotal 上查看 ↗',
          riskSummary: '评分',
          entVerdict: ['正常', '中等偏高', '可能是加壳/加密文件'],
          more: '更多',
          iocLabels: { urls: 'URLs', ipv4: 'IPv4 地址', emails: '电子邮件', domains: '域名', registry_keys: '注册表键', file_paths: '文件路径' },
          pageTitle: '恶意软件分析器 — 静态分析平台',
        }
      };

      /* ═══ State ═══════════════════════════════════════════ */
      let lang = localStorage.getItem('ma-lang') || 'vi';
      let theme = localStorage.getItem('ma-theme') || 'light';
      let selectedFile = null;
      let lastData = null;

      /* ═══ DOM refs ════════════════════════════════════════ */
      const $ = id => document.getElementById(id);
      const uploadZone = $('uploadZone');
      const fileInput = $('fileInput');
      const progressEl = $('progressSection');
      const errorCard = $('errorCard');
      const errorMsg = $('errorMessage');
      const resultsEl = $('resultsSection');
      const filePreview = $('filePreview');
      const fileNameEl = $('fileName');
      const fileSizeEl = $('fileSize');
      const analyzeBtn = $('analyzeBtn');

      /* ═══ Helpers ═════════════════════════════════════════ */
      function t(key) { return T[lang][key] ?? T.vi[key] ?? key; }
      function fmtBytes(b) {
        if (!b) return '0 B';
        const u = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(b) / Math.log(1024));
        return (b / Math.pow(1024, i)).toFixed(i ? 1 : 0) + ' ' + u[i];
      }
      function esc(s) {
        const d = document.createElement('div');
        d.textContent = String(s ?? '');
        return d.innerHTML;
      }

      /* ═══ Theme ═══════════════════════════════════════════ */
      function applyTheme(th) {
        theme = th;
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('ma-theme', theme);
      }
      window.toggleTheme = () => applyTheme(theme === 'light' ? 'dark' : 'light');

      /* ═══ Language ════════════════════════════════════════ */
      function applyLang(l) {
        lang = l;
        document.documentElement.setAttribute('data-lang', lang);
        document.documentElement.lang = lang;
        localStorage.setItem('ma-lang', lang);

        const langSel = $('langSelect');
        if (langSel && langSel.value !== lang) langSel.value = lang;

        document.title = t('pageTitle');
        $('heroBadge').textContent = t('heroBadge').replace(/&amp;/g, '&');
        $('heroTitle').innerHTML = t('heroTitle');
        $('heroDesc').innerHTML = t('heroDesc');
        $('uploadTitle').textContent = t('uploadTitle');
        $('uploadDesc').innerHTML = t('uploadDesc');
        $('analyzeBtnLabel').textContent = t('analyzeBtn');
        $('progressTitle').textContent = t('progressTitle');
        $('progressSub').textContent = t('progressSub');
        $('errorTitle').textContent = t('errorTitle');
        $('footerText').textContent = t('footer');

        /* re-bind browse click after innerHTML swap */
        const bl = $('browseLink');
        if (bl) bl.addEventListener('click', () => fileInput.click());

        /* status label */
        const statusEl = $('statusLabel');
        if (statusEl) {
          const cur = statusEl.dataset.state;
          if (cur === 'online') statusEl.textContent = t('statusOnline');
          else if (cur === 'offline') statusEl.textContent = t('statusOffline');
          else statusEl.textContent = t('statusCheck');
        }

        /* pipeline labels */
        document.querySelectorAll('.pipe-item-label[data-vi]').forEach(el => {
          el.textContent = el.dataset[lang];
        });
        document.querySelectorAll('.pipe-item-status').forEach(el => {
          const state = el.dataset.currentState || 'idle';
          el.textContent = el.dataset[`${lang}-${state}`] || el.textContent;
        });

        /* if results already rendered, re-render */
        if (lastData) renderResults(lastData);
      }
      window.applyLang = applyLang;

      /* ═══ Drag & Drop ═════════════════════════════════════ */
      ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(ev => {
        uploadZone.addEventListener(ev, e => { e.preventDefault(); e.stopPropagation(); });
      });
      ['dragenter', 'dragover'].forEach(ev =>
        uploadZone.addEventListener(ev, () => uploadZone.classList.add('is-dragover'))
      );
      ['dragleave', 'drop'].forEach(ev =>
        uploadZone.addEventListener(ev, () => uploadZone.classList.remove('is-dragover'))
      );
      uploadZone.addEventListener('drop', e => {
        if (e.dataTransfer.files.length) handleFile(e.dataTransfer.files[0]);
      });
      uploadZone.addEventListener('click', () => fileInput.click());
      uploadZone.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') fileInput.click();
      });
      fileInput.addEventListener('change', e => {
        if (e.target.files.length) handleFile(e.target.files[0]);
      });
      const bl0 = $('browseLink');
      if (bl0) bl0.addEventListener('click', e => { e.stopPropagation(); fileInput.click(); });

      /* ═══ Handle file ══════════════════════════════════════ */
      function handleFile(file) {
        selectedFile = file;
        fileNameEl.textContent = file.name;
        fileSizeEl.textContent = fmtBytes(file.size);
        filePreview.classList.add('is-visible');
      }

      /* ═══ Analyze ══════════════════════════════════════════ */
      const analyzeBtnEl = $('analyzeBtn');
      if (analyzeBtnEl) {
        analyzeBtnEl.addEventListener('click', () => {
          if (!selectedFile) return;
          uploadFile(selectedFile);
        });
      }

      const themeBtnEl = $('themeBtn');
      if (themeBtnEl) {
        themeBtnEl.addEventListener('click', () => applyTheme(theme === 'light' ? 'dark' : 'light'));
      }
      
      const langSelectEl = $('langSelect');
      if (langSelectEl) {
        langSelectEl.addEventListener('change', (e) => applyLang(e.target.value));
      }

      if (resultsEl) {
        resultsEl.addEventListener('click', (e) => {
          const toggleBtn = e.target.closest('[data-toggle="card"]');
          if (toggleBtn) {
            toggleBtn.parentElement.classList.toggle('is-open');
            return;
          }
          
          const copyBtn = e.target.closest('[data-copy]');
          if (copyBtn) {
            if (window.doCopy) window.doCopy(copyBtn, copyBtn.dataset.copy);
            return;
          }

          const copyJsonBtn = e.target.closest('[data-copy-json]');
          if (copyJsonBtn) {
            if (window.copyRawJson) window.copyRawJson(copyJsonBtn);
            return;
          }

          const actionBtn = e.target.closest('[data-action="reset"]');
          if (actionBtn) {
            if (window.resetUI) window.resetUI();
            return;
          }
        });
      }

      async function uploadFile(file) {
        showProgress();
        hideError();
        resultsEl.classList.remove('is-visible');
        resultsEl.innerHTML = '';
        lastData = null;
        if (analyzeBtn) analyzeBtn.disabled = true;

        const form = new FormData();
        form.append('file', file);

        try {
          const res = await fetch('/analyze', { method: 'POST', body: form });
          const data = await res.json();
          if (!res.ok) { showError(data.error || `HTTP ${res.status}`); return; }
          
          const analysisId = data.analysis_id;
          
          // Connect to SSE stream
          const eventSource = new EventSource(`/stream/${analysisId}`);
          
          eventSource.onmessage = function(e) {
            try {
              const msg = JSON.parse(e.data);
              
              if (msg.status === 'running' || msg.status === 'progress') {
                // You can update a text label here if you have one, e.g. msg.message
                // We map step_id to our UI steps if possible, or just animate
                // For simplicity, we just keep the animation running
                if (msg.step_id) {
                    markStep(msg.step_id, 'run');
                }
              } 
              else if (msg.status === 'done') {
                eventSource.close();
                fetchFinalResults(analysisId);
              }
              else if (msg.status === 'error') {
                eventSource.close();
                showError(msg.message || "Lỗi phân tích từ server");
                hideProgress();
                if (analyzeBtn) analyzeBtn.disabled = false;
              }
            } catch(err) {
              console.error("SSE parse error", err);
            }
          };

          eventSource.onerror = function(e) {
            console.error("SSE connection error", e);
            eventSource.close();
            // Fallback to poll if SSE fails
            setTimeout(() => fetchFinalResults(analysisId), 2000);
          };

        } catch (err) {
          showError(t('networkErr'));
          hideProgress();
          if (analyzeBtn) analyzeBtn.disabled = false;
        }
      }

      async function fetchFinalResults(analysisId) {
        try {
            const res = await fetch(`/status/${analysisId}`);
            const data = await res.json();
            if (data.status === 'done') {
                document.querySelectorAll('.pipe-item').forEach(el => el.classList.add('is-done'));
                lastData = data.result;
                setTimeout(() => { hideProgress(); renderResults(data.result); }, 500);
            } else if (data.status === 'error') {
                showError(data.error || "Phân tích thất bại");
                hideProgress();
            } else {
                // still running, poll again
                setTimeout(() => fetchFinalResults(analysisId), 2000);
            }
        } catch(err) {
            showError("Không thể lấy kết quả phân tích");
            hideProgress();
        } finally {
            if (analyzeBtn) analyzeBtn.disabled = false;
        }
      }

      /* ═══ Progress ═════════════════════════════════════════ */
      function showProgress() { progressEl.classList.add('is-visible'); resetSteps(); }
      function hideProgress() { progressEl.classList.remove('is-visible'); }
      function resetSteps() {
        document.querySelectorAll('.pipe-item').forEach(el => {
          el.classList.remove('is-active', 'is-done');
          const s = el.querySelector('.pipe-item-status');
          s.dataset.currentState = 'idle';
          s.textContent = s.dataset[`${lang}-idle`] || 'Chờ...';
        });
      }
      function markStep(name, state) {
        const el = document.querySelector(`.pipe-item[data-step="${name}"]`);
        if (!el) return;
        const s = el.querySelector('.pipe-item-status');
        if (state === 'run') {
          el.classList.add('is-active'); el.classList.remove('is-done');
          s.dataset.currentState = 'run';
          s.textContent = s.dataset[`${lang}-run`] || 'Processing...';
        } else if (state === 'done') {
          el.classList.remove('is-active'); el.classList.add('is-done');
          s.dataset.currentState = 'done';
          s.textContent = s.dataset[`${lang}-done`] || '✓ Done';
        }
      }

      /* ═══ Error ════════════════════════════════════════════ */
      function showError(msg) {
        errorMsg.textContent = msg;
        errorCard.classList.add('is-visible');
        hideProgress();
      }
      function hideError() { errorCard.classList.remove('is-visible'); }

      /* ═══ Risk helpers ═════════════════════════════════════ */
      function riskColor(lvl) {
        const m = { CLEAN: '#059669', LOW: '#059669', MEDIUM: '#d97706', HIGH: '#ea580c', CRITICAL: '#dc2626', MALICIOUS: '#991b1b' };
        return m[lvl?.toUpperCase()] || '#6b7280';
      }
      function riskRgb(lvl) {
        const m = { CLEAN: '5,150,105', LOW: '5,150,105', MEDIUM: '217,119,6', HIGH: '234,88,12', CRITICAL: '220,38,38', MALICIOUS: '153,27,27' };
        return m[lvl?.toUpperCase()] || '107,114,128';
      }

      /* ═══ Copy ══════════════════════════════════════════════ */
      function mkCopyBtn(val) {
        const safe = esc(val).replace(/'/g, "\\'");
        return `<button class="copy-btn" data-copy="${safe}">${t('copyBtn')}</button>`;
      }
      window.doCopy = (btn, val) => {
        navigator.clipboard.writeText(val).then(() => {
          btn.textContent = t('copied'); btn.classList.add('is-copied');
          setTimeout(() => { btn.textContent = t('copyBtn'); btn.classList.remove('is-copied'); }, 1500);
        });
      };

      /* ═══ Card helper ═══════════════════════════════════════ */
      function card(icon, title, body, open = false) {
        return `
    <div class="result-card ${open ? 'is-open' : ''} fade-up">
      <div class="card-head" data-toggle="card">
        <div class="card-head-left">
          <div class="card-head-icon">${icon}</div>
          <h3>${title}</h3>
        </div>
        <span class="card-chevron">▼</span>
      </div>
      <div class="card-body">${body}</div>
    </div>`;
      }

      /* ═══ Render Results ════════════════════════════════════ */
      function renderResults(data) {
        resultsEl.innerHTML = '';
        const risk = data.risk_assessment || data.risk || {};
        const score = risk.score ?? 0;
        const level = risk.level || 'UNKNOWN';
        const rc = riskColor(level);
        const rr = riskRgb(level);

        /* Risk Banner */
        resultsEl.innerHTML += `
    <div class="risk-banner fade-up" style="--risk-color:${rc};--risk-pct:${score};--risk-rgb:${rr}">
      <div class="risk-gauge" style="--risk-color:${rc};--risk-pct:${score}">
        <span class="risk-gauge-val">${score}</span>
      </div>
      <div class="risk-info">
        <h3>${t('riskTitle')}</h3>
        <p>${esc(risk.summary || `${t('riskSummary')}: ${score}/100`)}</p>
        <span class="risk-badge">${esc(level)}</span>
      </div>
    </div>`;

        /* Executive Summary */
        if (data.executive_summary) {
          const sum = data.executive_summary;
          resultsEl.innerHTML += card('📝', 'Tổng quan Phân tích', `
      <table class="info-table" style="margin-bottom:0;">
        <tr><td class="label" style="width:130px;">📌 <strong>Đây là gì?</strong></td><td class="value" style="color:var(--text-bright);">${esc(sum.what_it_is)}</td></tr>
        <tr><td class="label"> <strong>Mục đích</strong></td><td class="value" style="color:var(--text-bright);">${esc(sum.purpose)}</td></tr>
        <tr><td class="label"> <strong>Tác hại</strong></td><td class="value" style="color:var(--danger);">${esc(sum.harm)}</td></tr>
        <tr><td class="label"> <strong>Lời khuyên</strong></td><td class="value" style="color:var(--accent);">${esc(sum.advice)}</td></tr>
      </table>`, true);
        }

        /* File Info */
        const h = data.hashes || {};
        resultsEl.innerHTML += card('📄', t('fileInfo'), `
    <table class="info-table">
      <tr><td class="label">${t('filename')}</td><td class="value">${esc(data.filename)}</td></tr>
      <tr><td class="label">${t('filetype')}</td><td class="value">${esc(data.file_type)}</td></tr>
      ${h.file_size != null ? `<tr><td class="label">${t('filesize')}</td><td class="value">${fmtBytes(h.file_size)}</td></tr>` : ''}
      ${(data.pe_analysis || data.pe || {}).imphash ? `<tr><td class="label">Imphash</td><td class="value" style="color:#00ffff">${esc((data.pe_analysis || data.pe || {}).imphash)}${mkCopyBtn((data.pe_analysis || data.pe || {}).imphash)}</td></tr>` : ''}
      ${h.md5 ? `<tr><td class="label">MD5</td><td class="value">${esc(h.md5)}${mkCopyBtn(h.md5)}</td></tr>` : ''}
      ${h.sha1 ? `<tr><td class="label">SHA-1</td><td class="value">${esc(h.sha1)}${mkCopyBtn(h.sha1)}</td></tr>` : ''}
      ${h.sha256 ? `<tr><td class="label">SHA-256</td><td class="value">${esc(h.sha256)}${mkCopyBtn(h.sha256)}</td></tr>` : ''}
      ${h.sha512 ? `<tr><td class="label">SHA-512</td><td class="value">${esc(h.sha512)}${mkCopyBtn(h.sha512)}</td></tr>` : ''}
    </table>`, true);

        /* Entropy */
        const entropy = data.entropy || {};
        if (entropy.overall_entropy != null) {
          const ent = entropy.overall_entropy;
          const vIdx = ent > 7.2 ? 2 : ent > 6.0 ? 1 : 0;
          const vCls = ['tag--ok', 'tag--warn', 'tag--danger'][vIdx];
          const verdict = t('entVerdict')[vIdx];
          resultsEl.innerHTML += card('📊', t('entropyTitle'), `
      <table class="info-table">
        <tr><td class="label">${t('overall')}</td><td class="value">${ent.toFixed(4)} <span class="tag ${vCls}">${verdict}</span></td></tr>
        ${entropy.chunk_stats ? `<tr><td class="label">${t('stats')}</td><td class="value">Min: ${entropy.chunk_stats.min?.toFixed(3) ?? '—'} · Max: ${entropy.chunk_stats.max?.toFixed(3) ?? '—'} · Avg: ${entropy.chunk_stats.mean?.toFixed(3) ?? '—'}</td></tr>` : ''}
      </table>`);
        }

        /* PE */
        const pe = data.pe_analysis || data.pe || {};
        if (pe.machine || pe.compile_time || pe.sections) {
          let rows = '';
          if (pe.machine) rows += `<tr><td class="label">${t('arch')}</td><td class="value">${esc(pe.machine)}</td></tr>`;
          if (pe.compile_time) rows += `<tr><td class="label">${t('compileTime')}</td><td class="value">${esc(pe.compile_time)}</td></tr>`;
          if (pe.entry_point) rows += `<tr><td class="label">${t('entryPoint')}</td><td class="value">${esc(pe.entry_point)}</td></tr>`;
          if (pe.imphash) rows += `<tr><td class="label">${t('impHash')}</td><td class="value">${esc(pe.imphash)}${mkCopyBtn(pe.imphash)}</td></tr>`;
          if (pe.is_signed) rows += `<tr><td class="label">Authenticode</td><td class="value"><span class="tag tag--info" style="background:rgba(16,185,129,0.2);color:#10b981;border:1px solid #10b981">Signed ✅</span></td></tr>`;
          if (pe.rich_header && pe.rich_header.hash) rows += `<tr><td class="label">Rich Hash</td><td class="value">${esc(pe.rich_header.hash)}</td></tr>`;

          let alertHtml = '';
          if (pe.anomalies && pe.anomalies.length > 0) {
            alertHtml += `<div style="background:rgba(239,68,68,0.1); border-left:4px solid #ef4444; padding:10px 15px; margin: 15px 0; border-radius:4px;">
              <strong style="color:#ef4444; display:block; margin-bottom:6px;">⚠️ Heuristics Anomalies:</strong>
              <ul style="margin:0; padding-left:20px; color:#f87171; font-size:13px;">`;
            pe.anomalies.forEach(a => { alertHtml += `<li>${esc(a)}</li>`; });
            alertHtml += `</ul></div>`;
          }

          if (pe.overlay) {
             alertHtml += `<div style="background:rgba(245,158,11,0.1); border-left:4px solid #f59e0b; padding:10px 15px; margin: 15px 0; border-radius:4px;">
              <strong style="color:#f59e0b; display:block; margin-bottom:4px;">📦 Overlay Data Found! (Suspicious Tail)</strong>
              <span style="color:#fbbf24; font-size:13px;">Size: ${fmtBytes(pe.overlay.size)} | Entropy: ${pe.overlay.entropy} | MD5: ${pe.overlay.md5}</span>
            </div>`;
          }

          let secHtml = '';
          if (pe.sections?.length) {
            secHtml = `<p class="card-section-title">${t('sections')}</p><div class="tag-list">`;
            pe.sections.forEach(s => {
              const name = s.name || s.Name || '??';
              const ent = s.entropy ?? s.Entropy ?? 0;
              const cls = ent > 7.2 ? 'tag--danger' : ent > 6.5 ? 'tag--warn' : '';
              secHtml += `<span class="tag ${cls}">${esc(name)} · ${ent.toFixed(2)}</span>`;
            });
            secHtml += '</div>';
          }
          let impHtml = '';
          if (pe.suspicious_imports?.length) {
            impHtml = `<p class="card-section-title">${t('susImports')}</p><div class="tag-list">`;
            pe.suspicious_imports.forEach(imp => { impHtml += `<span class="tag tag--warn">${esc(imp)}</span>`; });
            impHtml += '</div>';
          }
          resultsEl.innerHTML += card('⚙️', t('peTitle'), `<table class="info-table">${rows}</table>${alertHtml}${secHtml}${impHtml}`);
        }

        /* Deep Static */
        const deep = data.deep_static || {};
        if (deep.available) {
          let deepHtml = '';
          if (deep.packer_detected) {
            deepHtml += `<tr><td class="label">Packer</td><td class="value"><span class="tag tag--danger">${esc(deep.packer_detected)}</span></td></tr>`;
          }
          const obf = deep.obfuscation || {};
          if (obf.verdict && obf.verdict !== 'CLEAN') {
            const cls = obf.verdict === 'LIKELY_OBFUSCATED' ? 'tag--danger' : 'tag--warn';
            deepHtml += `<tr><td class="label">Obfuscation</td><td class="value"><span class="tag ${cls}">${esc(obf.verdict)}</span> (XOR: ${(obf.xor_density * 100).toFixed(1)}%, JMP: ${(obf.jmp_density * 100).toFixed(1)}%)</td></tr>`;
          }
          if (deep.crypto_constants?.length) {
            let tags = '';
            deep.crypto_constants.slice(0, 10).forEach(c => tags += `<span class="tag tag--warn">${esc(c.label)}</span>`);
            deepHtml += `<tr><td class="label">Crypto Constants</td><td class="value"><div class="tag-list">${tags}</div></td></tr>`;
          }
          if (deep.anti_analysis?.apis?.length) {
            let tags = '';
            deep.anti_analysis.apis.forEach(a => tags += `<span class="tag tag--danger">${esc(a)}</span>`);
            deepHtml += `<tr><td class="label">Anti-Analysis APIs</td><td class="value"><div class="tag-list">${tags}</div></td></tr>`;
          }
          if (deep.disasm_summary?.total_instructions > 0) {
            deepHtml += `<tr><td class="label">Disassembly</td><td class="value">${deep.disasm_summary.total_instructions} insts, ${deep.cfg_summary?.estimated_functions} funcs</td></tr>`;
          }

          if (deepHtml) {
            resultsEl.innerHTML += card('🧠', t('deepTitle'), `<table class="info-table">${deepHtml}</table>`);
          }
        }

        /* Strings / IoCs */
        const iocs = (data.strings || {}).iocs || {};
        const hasIoc = Object.values(iocs).some(v => Array.isArray(v) && v.length);
        if (hasIoc) {
          const labels = t('iocLabels');
          let iocHtml = '';
          Object.entries(labels).forEach(([key, label]) => {
            const items = iocs[key];
            if (items?.length) {
              iocHtml += `<p class="card-section-title">${label}</p><div class="tag-list">`;
              items.slice(0, 20).forEach(item => { iocHtml += `<span class="tag tag--warn">${esc(item)}</span>`; });
              if (items.length > 20) iocHtml += `<span class="tag">+${items.length - 20} ${t('more')}</span>`;
              iocHtml += '</div>';
            }
          });
          resultsEl.innerHTML += card('🔍', t('stringsTitle'), iocHtml);
        }

        /* YARA */
        const yaraMatches = (data.yara_matches || data.yara || {}).matches || [];
        if (yaraMatches.length) {
          let yaraHtml = '<div class="tag-list">';
          yaraMatches.forEach(m => {
            const name = typeof m === 'string' ? m : (m.rule || m.name || JSON.stringify(m));
            yaraHtml += `<span class="tag tag--danger">🎯 ${esc(name)}</span>`;
          });
          yaraHtml += '</div>';
          resultsEl.innerHTML += card('🎯', `${t('yaraTitle')} (${yaraMatches.length})`, yaraHtml, true);
        }


        /* MITRE */
        const techniques = (data.mitre || {}).techniques || [];
        if (techniques.length) {
          let mitreHtml = '<div class="tag-list">';
          techniques.forEach(tc => {
            const id = tc.technique_id || tc.id || '';
            const name = tc.technique_name || tc.name || '';
            mitreHtml += `<span class="tag tag--warn">🗺 ${esc(id)} — ${esc(name)}</span>`;
          });
          mitreHtml += '</div>';
          resultsEl.innerHTML += card('🗺️', `${t('mitreTitle')} (${techniques.length})`, mitreHtml);
        }

        /* Risk Factors */
        const factors = risk.breakdown || risk.factors || [];
        if (factors.length) {
          let factHtml = '<div style="display:flex;flex-direction:column;gap:6px">';
          factors.forEach(f => {
            const label = typeof f === 'string' ? f : (f.feature || f.description || f.label || f.name || '');
            const pts = typeof f === 'object' ? (f.score || f.points || '') : '';
            factHtml += `<div style="display:flex;justify-content:space-between;align-items:center;gap:10px;padding:7px 0;border-bottom:1px solid var(--border)">
        <span style="font-size:13px">${esc(label)}</span>
        ${pts ? `<span class="tag tag--warn">+${pts}</span>` : ''}
      </div>`;
          });
          factHtml += '</div>';
          resultsEl.innerHTML += card('⚠️', `${t('riskFactors')} (${factors.length})`, factHtml);
        }

        /* Analysis warnings */
        const errors = data.analysis_errors || [];
        if (errors.length) {
          let errHtml = '<div style="display:flex;flex-direction:column;gap:5px">';
          errors.forEach(e => { errHtml += `<span style="color:var(--orange);font-size:13px">⚠ ${esc(e)}</span>`; });
          errHtml += '</div>';
          resultsEl.innerHTML += card('⚠️', `${t('analysisWarn')} (${errors.length})`, errHtml);
        }

        /* Raw JSON */
        const fmtJson = syntaxHighlight(data);
        resultsEl.innerHTML += card('💻', t('rawJson'), `
    <div style="display:flex;justify-content:flex-end;margin-bottom:6px">
      <button class="copy-btn" data-copy-json="true">${t('copyJson')}</button>
    </div>
    <pre class="json-pre"><code id="rawJsonCode">${fmtJson}</code></pre>`);

        /* Downloads */
        const urls = data.report_urls || {};
        if (urls.html) {
          let dl = '<div class="download-bar">';
          dl += `<a class="dl-btn dl-btn--primary" href="${esc(urls.html)}" target="_blank">${t('dlHtml')}</a>`;
          dl += '</div>';
          resultsEl.innerHTML += dl;
        }
        if (data.analysis_id) {
          resultsEl.innerHTML += `
      <div class="download-bar" style="margin-top:6px">
        <a class="dl-btn" href="/export/stix/${esc(data.analysis_id)}" target="_blank">${t('dlStix')}</a>
      </div>`;
        }

        /* New Analysis */
        resultsEl.innerHTML += `
    <div class="new-analysis">
      <button class="new-btn" data-action="reset">${t('newAnalysis')}</button>
    </div>`;

        resultsEl.classList.add('is-visible');

        /* Stagger animation - render nhanh */
        resultsEl.querySelectorAll('.result-card,.risk-banner').forEach((el, i) => {
          el.style.animationDelay = `${i * 0.065}s`;
        });
      }

      /* ═══ JSON syntax highlight ════════════════════════════ */
      function syntaxHighlight(json) {
        if (typeof json !== 'string') json = JSON.stringify(json, null, 2);
        json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        return json.replace(/(\"(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*\"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g, m => {
          let cls = 'json-number';
          if (/^"/.test(m)) cls = /:$/.test(m) ? 'json-key' : 'json-string';
          else if (/true|false/.test(m)) cls = 'json-boolean';
          else if (/null/.test(m)) cls = 'json-null';
          return `<span class="${cls}">${m}</span>`;
        });
      }
      window.copyRawJson = btn => {
        const el = document.getElementById('rawJsonCode');
        if (!el) return;
        navigator.clipboard.writeText(el.textContent).then(() => {
          btn.textContent = t('copiedJson'); btn.classList.add('is-copied');
          setTimeout(() => { btn.textContent = t('copyJson'); btn.classList.remove('is-copied'); }, 1500);
        });
      };

      /* ═══ Reset ═════════════════════════════════════════════ */
      window.resetUI = () => {
        resultsEl.classList.remove('is-visible');
        resultsEl.innerHTML = '';
        filePreview.classList.remove('is-visible');
        hideError(); hideProgress();
        fileInput.value = '';
        selectedFile = null;
        lastData = null;
        window.scrollTo({ top: 0, behavior: 'smooth' });
      };

      /* ═══ Health check ══════════════════════════════════════ */
      fetch('/health').then(r => r.json()).then(d => {
        const dot = document.querySelector('.status-dot');
        const label = $('statusLabel');
        if (d.status === 'ok') {
          dot.style.background = 'var(--green)';
          dot.style.boxShadow = '0 0 6px var(--green)';
          label.dataset.state = 'online';
          label.textContent = t('statusOnline');
        } else {
          dot.style.background = 'var(--red)';
          dot.style.boxShadow = 'none';
          label.dataset.state = 'offline';
          label.textContent = t('statusOffline');
        }
      }).catch(() => {
        const dot = document.querySelector('.status-dot');
        const label = $('statusLabel');
        dot.style.background = 'var(--red)';
        dot.style.boxShadow = 'none';
        label.dataset.state = 'offline';
        label.textContent = t('statusOffline');
      });

      /* ═══ Init ══════════════════════════════════════════════ */
      applyTheme(theme);
      applyLang(lang);

    })();