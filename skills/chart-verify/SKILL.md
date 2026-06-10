---
name: chart-verify
description: Verify Chart.js rendering in HTML slides via browser_console — no vision model needed. Detects CDN load failures, missing canvases, and render errors.
---

# Chart Verification (browser_console)

Trigger when: building/fixing HTML slide decks with Chart.js charts, or verifying charts render after deploying slides.

## Quick Check (single expression)

Paste this into browser_console:

```js
(function(){
  var r={};
  r.ChartLoaded = typeof Chart !== 'undefined';
  r.ChartVersion = r.ChartLoaded ? Chart.version : 'N/A';
  
  // Check script tag
  var scripts = document.querySelectorAll('script[src]');
  var chartSrc = '';
  for(var i=0;i<scripts.length;i++){
    if(scripts[i].src.includes('chart')) chartSrc = scripts[i].src;
  }
  r.ChartCDN = chartSrc || 'NOT FOUND';
  
  // Check if it's UMD build
  r.isUMD = chartSrc.includes('umd') || chartSrc.includes('Chart.bundle');
  
  // Check canvases
  var canvases = document.querySelectorAll('canvas');
  r.CanvasCount = canvases.length;
  r.HiddenCanvases = 0;
  canvases.forEach(function(c){ if(c.style.display==='none') r.HiddenCanvases++; });
  
  // Check Chart instances (if our code stores them in window.ci)
  r.ChartInstances = window.ci ? Object.keys(window.ci).length : 'no ci object';
  
  // Check slide rendering
  var activeSlide = document.querySelector('.slide.active');
  r.ActiveSlideIndex = activeSlide ? activeSlide.getAttribute('data-index') : 'N/A';
  
  // CDN accessibility test
  r.CDNAccessible = 'unknown';
  
  return JSON.stringify(r, null, 2);
})()
```

## CDN Accessibility Test

If Chart is undefined despite correct script tag, test if CDN is reachable:

```js
var x=new XMLHttpRequest();
x.open('GET','https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js');
x.timeout=5000;
x.onload=function(){ window.__cdnTest = {status: x.status, size: x.responseText.length}; };
x.onerror=function(){ window.__cdnTest = 'XHR failed'; };
x.ontimeout=function(){ window.__cdnTest = 'timeout'; };
x.send();
'check window.__cdnTest in a moment'
```

## Full Diagnostic (comprehensive)

Run when charts aren't rendering and root cause is unclear:

```js
(function(){
  var diag = {checks: []};
  
  // 1. Script presence
  var scripts = document.querySelectorAll('script[src*="chart"]');
  diag.checks.push({
    check: 'Chart.js script tag',
    pass: scripts.length > 0,
    detail: scripts.length ? scripts[0].src : 'no chart script found'
  });
  
  // 2. Global availability
  diag.checks.push({
    check: 'Chart global',
    pass: typeof Chart !== 'undefined',
    detail: typeof Chart !== 'undefined' ? 'v' + Chart.version : 'undefined'
  });
  
  // 3. Script load status
  if(scripts.length){
    var s = scripts[0];
    diag.checks.push({
      check: 'Script load state',
      pass: s.complete || s.readyState === 'complete',
      detail: 'complete=' + s.complete + ' readyState=' + (s.readyState||'N/A')
    });
  }
  
  // 4. Canvases
  var canvases = document.querySelectorAll('canvas');
  diag.canvasCount = canvases.length;
  var canvasDetails = [];
  canvases.forEach(function(c,i){
    canvasDetails.push({
      id: c.id || '(no id)',
      display: c.style.display,
      width: c.width,
      height: c.height,
      inViewport: c.getBoundingClientRect().top < window.innerHeight
    });
  });
  diag.canvases = canvasDetails;
  
  // 5. Try creating a test chart
  if(typeof Chart !== 'undefined'){
    try {
      var testCanvas = document.createElement('canvas');
      testCanvas.style.display = 'none';
      document.body.appendChild(testCanvas);
      var testChart = new Chart(testCanvas, {
        type: 'bar',
        data: {labels:['A'],datasets:[{data:[1]}]}
      });
      diag.checks.push({
        check: 'Chart instantiation',
        pass: true,
        detail: 'Chart created successfully'
      });
      testChart.destroy();
      document.body.removeChild(testCanvas);
    } catch(e){
      diag.checks.push({
        check: 'Chart instantiation',
        pass: false,
        detail: 'Error: ' + e.message
      });
    }
  }
  
  // 6. Console errors
  diag.checks.push({
    check: 'JS errors',
    pass: true,
    detail: 'Check browser console manually for errors'
  });
  
  return JSON.stringify(diag, null, 2);
})()
```

## Common Problems & Fixes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Chart` undefined, script tag exists | Loaded ESM build (`chart.js` not `chart.umd.min.js`) | Use `chart.umd.min.js` |
| `Chart` undefined, correct URL | CDN blocked by network/firewall | Embed Chart.js inline or use local file |
| Chart defined but canvas blank | Canvas `display:none` when Chart() called | Set `display:block` before creating chart |
| Chart renders then disappears on navigation | Canvas not in DOM when slide becomes active | Use lazy render pattern (create on slide activation only) |
| `canvas is already in use` | Chart re-created on same canvas | Check `ci[key]` before creating; use `destroy()` if needed |

## Fix: Inline Chart.js Fallback

If CDN loading fails, embed Chart.js directly. Download once:
```bash
curl -sL https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js -o chart.min.js
```
Then replace `<script src="...">` with `<script>` containing the file contents.
