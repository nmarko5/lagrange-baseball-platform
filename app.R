library(shiny)
library(googlesheets4)

# ==================================================
# GOOGLE SHEET CONNECTION
# ==================================================

SHEET_URL <- "https://docs.google.com/spreadsheets/d/1FBwANX0oBZO6bYX5iblICFsf-HWeDC7Hj_RmTvANBZw/edit?usp=sharing"

gs4_service_account_json <- Sys.getenv("GS4_SERVICE_ACCOUNT_JSON", unset = "")

if (nzchar(gs4_service_account_json)) {
  # Posit Connect Cloud stores secrets as environment-variable values.
  # Write the service-account JSON to a temporary file at runtime,
  # authenticate with it, then remove the temporary file.
  gs4_service_account_file <- tempfile(fileext = ".json")
  writeLines(gs4_service_account_json, gs4_service_account_file, useBytes = TRUE)
  
  gs4_auth(path = gs4_service_account_file)
  
  unlink(gs4_service_account_file)
} else {
  # Local development fallback
  gs4_auth(email = "natemarko5@gmail.com")
}

# ==================================================
# MODULES
# ==================================================

source("R/strike_zone.R")
source("R/google_sheets.R", local = TRUE)
source("R/scoring_engine.R")

# ==================================================
# UI
# ==================================================

ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("

      body {
        background-color: #ffffff;
      }

      /* ==================================================
         FULL APP SIDEBAR
         Team logo path:
         www/lagrange_logo.png
         ================================================== */

      .app-sidebar {
        position: fixed;
        left: 0;
        top: 0;
        bottom: 0;
        width: 148px;
        background: linear-gradient(180deg, #8e0000 0%, #a80000 58%, #7a0000 100%);
        color: #ffffff;
        z-index: 1100;
        box-shadow: 2px 0 8px rgba(0,0,0,.16);
        display: flex;
        flex-direction: column;
      }

      .app-sidebar-logo-wrap {
        height: 132px;
        padding: 10px 10px 6px 10px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        border-bottom: 1px solid rgba(255,255,255,.22);
      }

      .app-sidebar-logo {
        max-width: 108px;
        max-height: 90px;
        object-fit: contain;
      }

      .app-sidebar-brand {
        font-size: 11px;
        font-weight: 900;
        letter-spacing: .5px;
        margin-top: 4px;
        text-align: center;
      }

      .app-nav-item {
        width: 100%;
        display: block;
        color: #ffffff !important;
        text-decoration: none !important;
        padding: 12px 11px;
        border-bottom: 1px solid rgba(255,255,255,.10);
        font-size: 11px;
        font-weight: 800;
        cursor: pointer;
      }

      .app-nav-item:hover {
        background: rgba(255,255,255,.12);
      }

      .app-nav-item.active {
        background: #d20b0b;
        box-shadow: inset 4px 0 0 #ffffff;
      }

      .app-nav-icon {
        display: inline-block;
        width: 24px;
        font-size: 16px;
        text-align: center;
        margin-right: 4px;
      }

      .app-nav-muted {
        opacity: .62;
        cursor: default;
      }

      .app-sidebar-spacer {
        flex: 1 1 auto;
      }

      .app-sidebar-footer {
        border-top: 1px solid rgba(255,255,255,.20);
        padding: 11px;
        font-size: 10px;
        opacity: .85;
      }

      /* Sidebar replaces Shiny's native horizontal navigation. */
      .container-fluid > h2 {
        display: none;
      }

      .tabbable > .nav-tabs {
        display: none;
      }

      .tabbable > .tab-content {
        margin-left: 148px;
        padding-left: 10px;
        padding-right: 8px;
      }

      @media (max-width: 900px) {
        .app-sidebar {
          width: 112px;
        }

        .app-sidebar-logo {
          max-width: 82px;
        }

        .app-nav-item {
          padding: 10px 7px;
          font-size: 9px;
        }

        .app-nav-icon {
          width: 18px;
          font-size: 13px;
        }

        .tabbable > .tab-content {
          margin-left: 112px;
          padding-left: 6px;
        }
      }

      .zone-container {
        width: 520px;
        max-width: 100%;
        margin-top: 15px;
        margin-bottom: 15px;
      }

      .selected-zone-text {
        font-size: 24px;
        font-weight: 700;
        margin-top: 10px;
      }

      .result-button {
        margin-right: 8px;
        margin-bottom: 8px;
        min-width: 120px;
      }

      .contact-button {
        margin-right: 8px;
        margin-bottom: 8px;
        min-width: 120px;
      }

      .pa-result-button {
        margin-right: 8px;
        margin-bottom: 8px;
        min-width: 150px;
      }

      .pa-complete-box {
        margin-top: 20px;
        padding: 15px;
        border: 2px solid #A7191F;
        border-radius: 8px;
        background-color: #fff5f5;
        max-width: 500px;
      }

      .pa-complete-title {
        font-size: 22px;
        font-weight: 700;
        color: #A7191F;
      }

      .warning-text {
        color: #A7191F;
        font-weight: 700;
        margin-top: 10px;
      }

      .success-text {
        color: #18753c;
        font-weight: 700;
        margin-top: 10px;
      }

      .selection-box {
        margin-top: 15px;
        padding: 15px;
        border: 1px solid #dddddd;
        border-radius: 8px;
        background-color: #fafafa;
        max-width: 750px;
      }

      .session-box {
        margin-top: 10px;
        margin-bottom: 20px;
        padding: 15px;
        border: 2px solid #A7191F;
        border-radius: 8px;
        background-color: #fffafa;
        max-width: 850px;
      }

      .selected-value {
        font-size: 20px;
        font-weight: 700;
        margin-bottom: 10px;
      }

      .report-box {
        margin-top: 15px;
        margin-bottom: 20px;
        padding: 20px;
        border: 1px solid #dddddd;
        border-radius: 8px;
        background-color: #fafafa;
      }

      .grade-card {
        padding: 20px;
        border: 2px solid #A7191F;
        border-radius: 8px;
        background-color: #ffffff;
        text-align: center;
        margin-bottom: 15px;
        min-height: 150px;
      }

      .grade-title { font-size: 18px; font-weight: 700; margin-bottom: 8px; }
      .grade-number { font-size: 42px; font-weight: 800; line-height: 1.1; color: #A7191F; }
      .grade-sample { font-size: 14px; margin-top: 8px; color: #555555; }

    
      .report-section {
        margin-top: 18px;
        margin-bottom: 18px;
        padding: 18px;
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background-color: #ffffff;
      }

      .report-section-title {
        font-size: 20px;
        font-weight: 800;
        color: #A7191F;
        margin-bottom: 14px;
      }

      .metric-card {
        padding: 14px 12px;
        border: 1px solid #dddddd;
        border-radius: 8px;
        background-color: #fafafa;
        text-align: center;
        margin-bottom: 12px;
        min-height: 105px;
      }

      .metric-title {
        font-size: 14px;
        font-weight: 700;
        color: #333333;
        margin-bottom: 5px;
      }

      .metric-value {
        font-size: 28px;
        font-weight: 800;
        color: #A7191F;
      }

      .split-header {
        font-weight: 800;
        color: #A7191F;
        text-align: center;
        margin-bottom: 8px;
      }

      .heatmap-card {
        margin-top: 18px;
        margin-bottom: 18px;
        padding: 18px;
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background-color: #ffffff;
      }

      .heatmap-title {
        font-size: 20px;
        font-weight: 800;
        color: #A7191F;
        text-align: center;
        margin-bottom: 2px;
      }

      .heatmap-subtitle {
        font-size: 18px;
        font-weight: 700;
        text-align: center;
        margin-bottom: 10px;
      }

      .heatmap-sample {
        font-size: 13px;
        color: #555555;
        text-align: center;
        margin-top: 8px;
      }

      .heatmap-legend {
        font-size: 12px;
        color: #555555;
        text-align: center;
        margin-top: 5px;
      }


      .heatmap-row {
        display: flex;
        flex-wrap: nowrap;
        gap: 8px;
        align-items: stretch;
        margin-top: 14px;
        width: 100%;
      }

      .heatmap-panel {
        flex: 1 1 0;
        min-width: 0;
        padding: 10px 7px 9px 7px;
        border: 1px solid #e1e1e1;
        border-radius: 7px;
        background-color: #ffffff;
        overflow: hidden;
      }

      .heatmap-panel .heatmap-title {
        font-size: 14px;
        line-height: 1.05;
        margin-bottom: 3px;
        white-space: nowrap;
      }

      .heatmap-panel .heatmap-subtitle {
        font-size: 13px;
        line-height: 1.05;
        margin-bottom: 4px;
      }

      .heatmap-panel .heatmap-sample {
        font-size: 10px;
        line-height: 1.15;
        margin-top: 3px;
      }

      .heatmap-panel .heatmap-legend {
        display: none;
      }

      .heatmap-visual-wrap {
        position: relative;

        /* LOCKED VISUAL STAGE
           Batter + heat map now share one fixed coordinate system.
           This prevents the silhouette from drifting when the browser
           is resized or switched between windowed and full screen. */
        width: 250px;
        max-width: 100%;
        height: 205px;
        margin: 0 auto;

        display: block;
        overflow: visible;
      }

      .heatmap-plot-wrap {
        position: absolute;
        top: 50%;
        left: 50%;
        width: 168px;
        min-width: 168px;
        transform: translate(-50%, -50%);
        z-index: 1;

        display: flex;
        justify-content: center;
        align-items: center;
      }

      .heatmap-plot-wrap > div {
        width: 168px;
        max-width: 168px;
      }

      .batter-silhouette {
        position: absolute;
        width: 96px;
        height: 200px;
        z-index: 5;
        pointer-events: none;
        overflow: visible;

        /* Keep chest/knees alignment locked */
        top: 50%;
        transform: translateY(-54%);
      }

      .batter-silhouette img {
        width: 100%;
        height: 100%;
        object-fit: contain;
        object-position: center center;
        display: block;
        transform-origin: center center;
      }

      /* ==================================================
         HANDEDNESS LAYOUT — CATCHER VIEW
         These positions are now relative to the fixed
         250px visual stage above, NOT the report card width.
         Therefore spacing stays constant at every screen size.
         ================================================== */

      .batter-silhouette.rhh {
        left: 22px;
        right: auto;
      }

      .batter-silhouette.lhh {
        left: auto;
        right: 22px;
      }

      .batter-silhouette.switch {
        left: 22px;
        right: auto;
      }

      .batter-silhouette.rhh img {
        transform: scaleX(-1);
      }

      .batter-silhouette.lhh img {
        transform: scaleX(1);
      }

      .batter-silhouette.switch img {
        transform: scaleX(-1);
      }

      .heatmap-shared-note {
        margin-top: 7px;
        padding: 5px 8px;
        font-size: 10px;
        color: #555555;
        text-align: center;
      }

      .catchers-view-note {
        margin-top: 4px;
        text-align: center;
        font-size: 11px;
        color: #666666;
        font-style: italic;
      }


      /* ==================================================
         PLAYER REPORT BOTTOM BREAKDOWN TABLES
         ================================================== */

      .report-breakdown-grid {
        display: grid;
        grid-template-columns: 1fr 1.08fr .95fr 1.08fr;
        gap: 8px;
        margin-top: 10px;
        margin-bottom: 14px;
      }

      .report-breakdown-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 10px 10px 8px 10px;
        min-width: 0;
      }

      .report-breakdown-title {
        color: #A7191F;
        font-size: 12px;
        font-weight: 900;
        text-transform: uppercase;
        margin-bottom: 7px;
      }

      .report-breakdown-card table {
        width: 100%;
        margin-bottom: 0;
        font-size: 10px;
      }

      .report-breakdown-card table th {
        color: #A7191F;
        font-size: 9px;
        font-weight: 800;
        border-top: none !important;
        padding: 4px 5px !important;
        white-space: nowrap;
      }

      .report-breakdown-card table td {
        padding: 4px 5px !important;
        vertical-align: middle !important;
        white-space: nowrap;
      }


      .table-benchmark-good {
        background-color: #e6f4e8 !important;
        color: #147a32 !important;
        font-weight: 800;
      }

      .table-benchmark-average {
        background-color: #fff4cf !important;
        color: #a87500 !important;
        font-weight: 800;
      }

      .table-benchmark-poor {
        background-color: #fde2e2 !important;
        color: #a51d22 !important;
        font-weight: 800;
      }

      .table-benchmark-neutral {
        color: #333333 !important;
      }


      .breakdown-group-row td {
        font-weight: 800 !important;
        background: #fafafa !important;
        border-top: 1px solid #d8d8d8 !important;
      }

      .breakdown-total-row td {
        font-weight: 900 !important;
        color: #A7191F !important;
        background: #ffffff !important;
        border-top: 2px solid #A7191F !important;
      }

      .pitch-group-hard {
        color: #A7191F;
      }

      .pitch-group-breaking {
        color: #7b1fa2;
      }

      .pitch-group-soft {
        color: #1769aa;
      }

      .report-breakdown-note {
        margin-top: 5px;
        font-size: 9px;
        color: #777777;
      }


      .player-stat-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 6px;
      }

      .player-stat-cell {
        border: 1px solid #eeeeee;
        border-radius: 5px;
        padding: 6px 4px;
        text-align: center;
        background: #fafafa;
        min-width: 0;
      }

      .player-stat-label {
        color: #666666;
        font-size: 8px;
        font-weight: 800;
        text-transform: uppercase;
        line-height: 1.05;
      }

      .player-stat-value {
        margin-top: 3px;
        color: #222222;
        font-size: 14px;
        font-weight: 900;
        line-height: 1;
      }

      .player-stat-value.rate-good {
        color: #18833b;
      }

      .player-stat-value.rate-average {
        color: #d89b00;
      }

      .player-stat-value.rate-poor {
        color: #b51f24;
      }

      @media (max-width: 1150px) {
        .report-breakdown-grid {
          grid-template-columns: 1fr;
        }
      }


      /* ==================================================
         COMPACT PLAYER REPORT HEADER
         ================================================== */

      .player-report-shell {
        margin-top: 8px;
      }


      /* ==================================================
         V24 REPORT HEADER / PLAYER BIO / FILTERS
         NOTE: silhouette CSS below is intentionally untouched.
         ================================================== */

      .report-topbar {
        display: grid;
        grid-template-columns: 360px 1fr;
        gap: 12px;
        margin-bottom: 10px;
      }

      .report-player-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 10px;
        display: grid;
        grid-template-columns: 92px 1fr;
        gap: 10px;
        min-height: 150px;
      }

      .report-player-photo {
        width: 92px;
        height: 126px;
        border-radius: 6px;
        object-fit: cover;
        background: #f2f2f2;
        border: 1px solid #dddddd;
      }

      .report-player-name {
        font-size: 20px;
        font-weight: 900;
        color: #222222;
        line-height: 1.05;
      }

      .report-player-meta {
        margin-top: 6px;
        font-size: 10px;
        line-height: 1.55;
        color: #444444;
      }

      .report-filters-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 10px 12px;
      }

      .report-filter-grid {
        display: grid;
        grid-template-columns: 1.1fr 1fr 1.1fr auto;
        gap: 8px;
        align-items: end;
      }

      .report-filter-grid .form-group {
        margin-bottom: 0;
      }

      .report-grade-comparison {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 8px;
        margin-bottom: 8px;
      }

      .grade-block {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 7px 10px 8px 10px;
        min-height: 0;
      }

      .grade-block-title {
        color: #A7191F;
        text-transform: uppercase;
        font-weight: 900;
        font-size: 11px;
        text-align: center;
        margin-bottom: 6px;
      }

      .grade-block-subtitle {
        text-align: center;
        font-size: 9px;
        color: #555555;
        margin-top: -4px;
        margin-bottom: 5px;
      }

      .grade-block-grid {
        width: 100%;
      }

      /* uiOutput creates a wrapper. Make that wrapper the real
         three-column grid so the grades fill the full card width. */
      .grade-block-grid > .shiny-html-output {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        width: 100%;
        gap: 0;
      }

      .grade-block-cell {
        text-align: center;
        border-right: 1px solid #eeeeee;
        padding: 3px 6px;
        min-width: 0;
      }

      .grade-block-cell:last-child {
        border-right: none;
      }

      .grade-letter {
        font-size: 27px;
        line-height: 1;
        font-weight: 900;
      }

      .grade-number-small {
        font-size: 10px;
        color: #444444;
        margin-top: 3px;
      }

      .grade-pitch-count {
        font-size: 8px;
        color: #777777;
        margin-top: 2px;
      }

      .decision-quality-explainer {
        border: 1px solid #d6dce5;
        border-radius: 7px;
        padding: 8px 10px;
        margin-top: 7px;
        background: #fbfcfe;
        font-size: 9px;
        line-height: 1.35;
        color: #333333;
      }

      .decision-quality-explainer strong {
        color: #A7191F;
      }

      @media (max-width: 1050px) {
        .report-topbar {
          grid-template-columns: 1fr;
        }
        .report-filter-grid {
          grid-template-columns: 1fr 1fr;
        }
      }

      .player-report-header {
        display: grid;
        grid-template-columns: 280px 1fr;
        gap: 12px;
        align-items: stretch;
        margin-bottom: 10px;
      }

      .player-report-control-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 12px 14px;
        min-height: 128px;
      }

      .player-report-kicker {
        color: #A7191F;
        font-size: 12px;
        font-weight: 800;
        letter-spacing: .5px;
        text-transform: uppercase;
        margin-bottom: 4px;
      }

      .player-report-main-title {
        font-size: 24px;
        font-weight: 800;
        line-height: 1.05;
        color: #2f2f2f;
        margin-bottom: 10px;
      }

      .player-report-controls {
        display: grid;
        grid-template-columns: 1fr auto;
        gap: 8px;
        align-items: end;
      }

      .player-report-controls .form-group {
        margin-bottom: 0;
      }

      .player-report-controls .btn {
        height: 34px;
        margin-bottom: 0;
      }

      .player-report-status {
        margin-top: 8px;
        font-size: 11px;
      }

      .compact-grade-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 8px;
      }

      .compact-grade-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 10px 8px;
        min-height: 128px;
        text-align: center;
        display: flex;
        flex-direction: column;
        justify-content: center;
      }

      .compact-grade-title {
        color: #A7191F;
        font-size: 11px;
        font-weight: 800;
        text-transform: uppercase;
        line-height: 1.1;
        margin-bottom: 5px;
      }

      .compact-grade-number {
        font-size: 30px;
        line-height: 1;
        font-weight: 900;
      }

      .benchmark-good { color: #18833b !important; }
      .benchmark-average { color: #d89b00 !important; }
      .benchmark-poor { color: #b51f24 !important; }
      .benchmark-neutral { color: #333333 !important; }
      .benchmark-value { font-weight: 900; }

      .benchmark-legend {
        display: flex;
        justify-content: flex-end;
        gap: 10px;
        margin: -2px 2px 7px 2px;
        font-size: 9px;
        color: #666666;
      }

      .benchmark-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        display: inline-block;
        margin-right: 3px;
      }

      .benchmark-dot.good { background: #18833b; }
      .benchmark-dot.average { background: #d89b00; }
      .benchmark-dot.poor { background: #b51f24; }

      .compact-grade-sample {
        margin-top: 5px;
        font-size: 10px;
        color: #555555;
      }

      .compact-metric-strip {
        display: grid;
        grid-template-columns: repeat(8, 1fr);
        gap: 6px;
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        padding: 8px;
        margin-bottom: 8px;
      }

      .compact-metric-cell {
        text-align: center;
        padding: 7px 4px;
        border-right: 1px solid #ededed;
      }

      .compact-metric-cell:last-child {
        border-right: none;
      }

      .compact-metric-label {
        font-size: 9px;
        color: #555555;
        font-weight: 700;
        line-height: 1.1;
        min-height: 20px;
      }

      .compact-metric-number {
        margin-top: 3px;
        font-size: 17px;
        font-weight: 900;
        line-height: 1;
      }

      .compact-count-strip {
        display: grid;
        grid-template-columns: 160px 1fr 1fr;
        gap: 0;
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
        overflow: hidden;
        margin-bottom: 10px;
      }

      .compact-count-cell {
        padding: 7px 10px;
        text-align: center;
        border-right: 1px solid #ededed;
      }

      .compact-count-cell:last-child {
        border-right: none;
      }

      .compact-count-head {
        font-size: 9px;
        text-transform: uppercase;
        font-weight: 800;
        color: #A7191F;
        margin-bottom: 3px;
      }

      .compact-count-value {
        font-size: 15px;
        font-weight: 900;
        color: #333333;
      }

      .compact-count-label {
        font-size: 10px;
        font-weight: 700;
        color: #444444;
        display: flex;
        flex-direction: column;
        justify-content: center;
      }

      @media (max-width: 1200px) {
        .player-report-header {
          grid-template-columns: 1fr;
        }

        .compact-metric-strip {
          grid-template-columns: repeat(4, 1fr);
        }

        .compact-metric-cell:nth-child(4) {
          border-right: none;
        }
      }


      /* ==================================================
         PITCHER REPORT — manual charting only
         ================================================== */
      .pitcher-report-shell { margin-top: 8px; }
      .pitcher-topbar { display:grid; grid-template-columns:310px 1fr; gap:10px; margin-bottom:8px; }
      .pitcher-bio-card,.pitcher-filter-card,.pitcher-section-card { border:1px solid #e1e1e1; border-radius:8px; background:#fff; }
      .pitcher-bio-card { padding:10px; display:grid; grid-template-columns:84px 1fr; gap:10px; }
      .pitcher-headshot { width:84px; height:112px; border-radius:6px; object-fit:cover; border:1px solid #ddd; background:#f4f4f4; }
      .pitcher-name { font-size:19px; font-weight:900; line-height:1.05; color:#222; }
      .pitcher-meta { margin-top:5px; font-size:10px; line-height:1.5; color:#444; }
      .pitcher-filter-card { padding:10px 12px; }
      .pitcher-filter-grid { display:grid; grid-template-columns:1fr 1fr 1.1fr auto; gap:8px; align-items:end; }
      .pitcher-filter-grid .form-group { margin-bottom:0; }
      .pitcher-kpi-grid { width:100%; margin-bottom:8px; }
      .pitcher-kpi-grid > .shiny-html-output {
        display:grid;
        grid-template-columns:repeat(9,1fr);
        gap:6px;
        width:100%;
      }
      .pitcher-kpi-card { border:1px solid #e2e2e2; border-radius:7px; padding:7px 5px; text-align:center; background:#fff; }
      .pitcher-kpi-label { font-size:8px; line-height:1.1; font-weight:800; color:#555; text-transform:uppercase; min-height:18px; }
      .pitcher-kpi-value { margin-top:3px; font-size:20px; line-height:1; font-weight:900; color:#222; }
      .pitcher-kpi-sub { margin-top:3px; font-size:8px; color:#777; }
      .pitch-eff-good { color:#18833b !important; } .pitch-eff-average { color:#d89b00 !important; } .pitch-eff-poor { color:#b51f24 !important; }
      .pitcher-section-grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-bottom:8px; }
      .pitcher-section-grid-3 { display:grid; grid-template-columns:1.05fr 1.15fr .9fr; gap:8px; margin-bottom:8px; }
      .pitcher-section-card { padding:9px 10px; min-width:0; }
      .pitcher-section-title { color:#A7191F; font-size:18px; font-weight:900; text-transform:uppercase; margin-bottom:8px; }
      .pitcher-section-note { font-size:8px; color:#777; margin-top:4px; line-height:1.25; }
      .pitcher-report-shell table { width:100%; font-size:11px; margin-bottom:0; }
      .pitcher-report-shell table th { color:#A7191F; font-size:10px; font-weight:900; white-space:nowrap; padding:4px 5px !important; }
      .pitcher-report-shell table td { padding:4px 5px !important; white-space:nowrap; vertical-align:middle !important; }
      .inning-efficient td { background:#e9f5eb !important; } .inning-over td { background:#fde7e7 !important; }
      .pitcher-location-control { display:grid; grid-template-columns:190px 1fr; gap:8px; align-items:end; margin-bottom:4px; }
      .pitcher-location-control .form-group { margin-bottom:0; }
      .pitcher-location-svg { width:100%; max-width:480px; margin:0 auto; }
      .count-leverage-strip { display:grid; grid-template-columns:repeat(3,1fr); border:1px solid #e4e4e4; border-radius:6px; overflow:hidden; margin-bottom:8px; }
      .count-leverage-cell { text-align:center; padding:7px 5px; border-right:1px solid #e4e4e4; } .count-leverage-cell:last-child { border-right:none; }
      .count-leverage-label { font-size:8px; color:#666; font-weight:800; text-transform:uppercase; }
      .count-leverage-value { font-size:18px; font-weight:900; margin-top:2px; }


      .pitcher-grade-grid { width:100%; margin-bottom:8px; }
      .pitcher-grade-grid > .shiny-html-output {
        display:grid;
        grid-template-columns:repeat(4,1fr);
        gap:7px;
        width:100%;
      }
      .pitcher-grade-card {
        border:1px solid #e1e1e1;
        border-radius:7px;
        background:#ffffff;
        padding:7px 8px;
        text-align:center;
      }
      .pitcher-grade-label { color:#A7191F; font-size:9px; font-weight:900; text-transform:uppercase; }
      .pitcher-grade-letter { font-size:25px; font-weight:900; line-height:1; margin-top:3px; }
      .pitcher-grade-number { font-size:9px; color:#555; margin-top:2px; }

      .pitcher-stats-grid { display:grid; grid-template-columns:repeat(6,1fr); gap:5px; }
      .pitcher-stat-cell { border:1px solid #eeeeee; border-radius:5px; padding:5px 3px; text-align:center; background:#fafafa; }
      .pitcher-stat-label { color:#666; font-size:10px; font-weight:900; text-transform:uppercase; line-height:1.05; }
      .pitcher-stat-value { color:#222; font-size:13px; font-weight:900; margin-top:2px; line-height:1; }

      .game-state-box {
        border:1px solid #d8d8d8;
        border-radius:7px;
        background:#fff;
        padding:8px 10px;
        margin-bottom:8px;
      }
      .game-state-title { color:#A7191F; font-size:12px; font-weight:900; text-transform:uppercase; margin-bottom:5px; }
      .game-state-grid { display:grid; grid-template-columns:160px 230px 1fr; gap:10px; align-items:end; }
      .game-state-grid .form-group { margin-bottom:0; }
      .outs-controls { display:flex; align-items:center; gap:7px; padding-bottom:1px; }
      .outs-display { font-size:18px; font-weight:900; min-width:72px; text-align:center; }

      .pitcher-location-stage {
        position:relative;
        width:480px;
        max-width:100%;
        height:355px;
        margin:0 auto;
      }
      .pitcher-location-stage .pitcher-location-svg {
        position:absolute;
        inset:0;
        width:100%;
        max-width:none;
      }

      /* ==================================================
         PITCHER REPORT BATTER SILHOUETTES
         LOCKED CLOSER-TO-ZONE POSITIONING

         Goal:
         - match the hitter-report visual relationship
         - larger batter
         - knees/chest aligned with the zone
         - much smaller gap between hitter and strike zone
         - catcher-view handedness remains correct
         ================================================== */

      .pitcher-batter-silhouette {
        position:absolute;
        top:38px;
        width:auto;
        height:340px;
        z-index:5;
        pointer-events:none;
      }

      /* RHH appears on catcher's LEFT */
      .pitcher-batter-silhouette.rhh {
        left:25px;
        transform:scaleX(-1);
      }

      /* LHH appears on catcher's RIGHT */
      .pitcher-batter-silhouette.lhh {
        right:25px;
        transform:scaleX(1);
      }

      /* When ALL is selected, ghost both sides in the same
         close-to-zone positions used by the handedness filters. */
      .pitcher-batter-silhouette.all-left {
        left:25px;
        transform:scaleX(-1);
        opacity:.28;
      }

      .pitcher-batter-silhouette.all-right {
        right:25px;
        transform:scaleX(1);
        opacity:.28;
      }

      .pitcher-team-legend { text-align:right; font-size:8px; color:#666; margin:-3px 0 5px 0; }
      .pitcher-team-legend .g { color:#18833b; font-weight:800; }
      .pitcher-team-legend .y { color:#d89b00; font-weight:800; }
      .pitcher-team-legend .r { color:#b51f24; font-weight:800; }

      /* ==================================================
         LEADERBOARD + QUAB TRACKING
         ================================================== */
      .quab-charting-box{border:1px solid #d8d8d8;border-radius:7px;background:#fbfbfb;padding:9px 11px;margin:7px 0 10px 0;}
      .quab-charting-title{color:#A7191F;font-size:13px;font-weight:900;text-transform:uppercase;margin-bottom:6px;}
      .quab-charting-grid{display:grid;grid-template-columns:125px 1fr 1.3fr 1.5fr;gap:10px;align-items:center;}
      .quab-charting-grid .form-group{margin-bottom:0;}
      .quab-charting-note{margin-top:6px;font-size:10px;line-height:1.3;color:#666;}
      .leaderboard-shell{margin-top:8px;}
      .leaderboard-header-card,.leaderboard-table-card,.leaderboard-podium-card,.leaderboard-quab-card{border:1px solid #e1e1e1;border-radius:8px;background:#fff;}
      .leaderboard-header-card{padding:12px;margin-bottom:8px;}
      .leaderboard-title{color:#A7191F;font-size:24px;font-weight:900;text-transform:uppercase;line-height:1;margin-bottom:8px;}
      .leaderboard-filter-grid{display:grid;grid-template-columns:170px 210px 230px 1.25fr auto;gap:9px;align-items:end;}
      .leaderboard-filter-grid .form-group{margin-bottom:0;}
      .leaderboard-podium-card{padding:10px;margin-bottom:8px;}
      .leaderboard-podium-title{color:#A7191F;font-size:14px;font-weight:900;text-transform:uppercase;margin-bottom:8px;}
      .leaderboard-podium-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;}
      .leaderboard-podium-place{border:1px solid #e6e6e6;border-radius:7px;padding:10px 8px;text-align:center;background:#fafafa;}
      .leaderboard-podium-rank{font-size:11px;font-weight:900;color:#A7191F;}
      .leaderboard-podium-name{font-size:16px;font-weight:900;color:#222;margin-top:2px;}
      .leaderboard-podium-value{font-size:22px;font-weight:900;margin-top:3px;}
      .leaderboard-table-card{padding:10px;margin-bottom:8px;overflow-x:auto;}
      .leaderboard-section-title{color:#A7191F;font-size:18px;font-weight:900;text-transform:uppercase;margin-bottom:8px;}
      .leaderboard-table{width:100%;margin-bottom:0;font-size:12px;}
      .leaderboard-table th{color:#A7191F;font-size:11px;font-weight:900;white-space:nowrap;padding:6px 7px!important;border-bottom:2px solid #A7191F!important;}
      .leaderboard-table td{padding:6px 7px!important;white-space:nowrap;vertical-align:middle!important;}
      .leaderboard-rank{width:45px;text-align:center;font-weight:900;color:#A7191F;}
      .leaderboard-player-link{color:#222!important;font-weight:900;text-decoration:none!important;}
      .leaderboard-player-link:hover{color:#A7191F!important;text-decoration:underline!important;}
      .leaderboard-good{color:#18833b!important;font-weight:900;}.leaderboard-average{color:#d89b00!important;font-weight:900;}.leaderboard-poor{color:#b51f24!important;font-weight:900;}.leaderboard-neutral{color:#333!important;}
      .leaderboard-quab-card{padding:10px 12px;margin-bottom:8px;background:#fbfcfe;}.leaderboard-quab-card strong{color:#A7191F;}
      .leaderboard-note{margin-top:5px;font-size:10px;line-height:1.35;color:#666;}
      @media(max-width:1100px){.leaderboard-filter-grid{grid-template-columns:1fr 1fr;}.leaderboard-podium-grid{grid-template-columns:1fr;}.quab-charting-grid{grid-template-columns:1fr 1fr;}}


      /* ==================================================
         TEAM REPORT
         ================================================== */

      .team-report-shell {
        margin-top: 8px;
      }

      .team-report-header,
      .team-report-card,
      .team-report-kpi-card,
      .team-report-trend-card {
        border: 1px solid #e1e1e1;
        border-radius: 8px;
        background: #ffffff;
      }

      .team-report-header {
        padding: 11px 12px;
        margin-bottom: 8px;
      }

      .team-report-title {
        color: #A7191F;
        font-size: 24px;
        font-weight: 900;
        line-height: 1;
        text-transform: uppercase;
        margin-bottom: 8px;
      }

      .team-report-filter-grid {
        display: grid;
        grid-template-columns: 170px 250px 1fr auto;
        gap: 9px;
        align-items: end;
      }

      .team-report-filter-grid .form-group {
        margin-bottom: 0;
      }

      .team-report-kpi-grid {
        display: block;
        margin-bottom: 8px;
      }

      .team-report-kpi-grid > .shiny-html-output {
        display: grid;
        grid-template-columns: repeat(8, minmax(0, 1fr));
        gap: 6px;
        width: 100%;
      }

      .team-report-kpi-card {
        padding: 8px 5px;
        text-align: center;
      }

      .team-report-kpi-label {
        min-height: 20px;
        font-size: 9px;
        line-height: 1.05;
        font-weight: 900;
        color: #555555;
        text-transform: uppercase;
      }

      .team-report-kpi-value {
        margin-top: 4px;
        font-size: 20px;
        line-height: 1;
        font-weight: 900;
        color: #222222;
      }

      .team-report-grid-2 {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 8px;
        margin-bottom: 8px;
      }

      .team-report-grid-3 {
        display: grid;
        grid-template-columns: 1fr 1fr 1fr;
        gap: 8px;
        margin-bottom: 8px;
      }

      .team-report-card,
      .team-report-trend-card {
        padding: 10px;
        min-width: 0;
        overflow-x: auto;
      }

      .team-report-section-title {
        color: #A7191F;
        font-size: 18px;
        font-weight: 900;
        text-transform: uppercase;
        line-height: 1.1;
        margin-bottom: 8px;
      }

      .team-report-note {
        margin-top: 5px;
        font-size: 10px;
        line-height: 1.3;
        color: #666666;
      }

      .team-report-shell table {
        width: 100%;
        margin-bottom: 0;
        font-size: 11px;
      }

      .team-report-shell table th {
        color: #A7191F;
        font-size: 10px;
        font-weight: 900;
        white-space: nowrap;
        padding: 5px 6px !important;
      }

      .team-report-shell table td {
        white-space: nowrap;
        padding: 5px 6px !important;
        vertical-align: middle !important;
      }

      .team-status-above {
        color: #18833b !important;
        font-weight: 900;
      }

      .team-status-near {
        color: #d89b00 !important;
        font-weight: 900;
      }

      .team-status-below {
        color: #b51f24 !important;
        font-weight: 900;
      }

      .team-trend-up {
        color: #18833b;
        font-weight: 900;
      }

      .team-trend-down {
        color: #b51f24;
        font-weight: 900;
      }

      @media (max-width: 1200px) {
        .team-report-kpi-grid > .shiny-html-output {
          grid-template-columns: repeat(4, minmax(0, 1fr));
        }

        .team-report-grid-3 {
          grid-template-columns: 1fr;
        }
      }

      @media (max-width: 950px) {
        .team-report-filter-grid {
          grid-template-columns: 1fr 1fr;
        }

        .team-report-grid-2 {
          grid-template-columns: 1fr;
        }
      }


      /* BULLPEN MODE */
      .bullpen-mode-card{border:1px solid #dcdcdc;border-radius:8px;background:#fbfbfb;padding:10px 12px;margin-bottom:10px;}
      .bullpen-mode-title{color:#A7191F;font-size:16px;font-weight:900;text-transform:uppercase;margin-bottom:7px;}
      .bullpen-mode-grid{display:grid;grid-template-columns:180px 1fr 1fr;gap:10px;align-items:end;}
      .bullpen-mode-grid .form-group{margin-bottom:0;}
      .bullpen-target-card{border:1px solid #e1e1e1;border-radius:8px;background:#fff;padding:10px 12px;margin:8px 0 10px 0;}
      .bullpen-target-title{color:#A7191F;font-size:14px;font-weight:900;text-transform:uppercase;margin-bottom:6px;}
      .bullpen-target-note{font-size:10px;color:#666;line-height:1.3;margin-top:5px;}
      .bullpen-click-instructions{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-top:7px;font-size:11px;font-weight:800;color:#444;}
      .bullpen-click-step{padding:5px 8px;border:1px solid #dedede;border-radius:999px;background:#fff;}
      .bullpen-click-step.active{border-color:#A7191F;color:#A7191F;background:#fff7f7;}
      .bullpen-reset-target{margin-top:7px;}
      .zone-container{position:relative;}
      .bullpen-target-mitt{
        position:absolute;
        z-index:20;
        width:38px;
        height:38px;
        transform:translate(-50%,-50%);
        pointer-events:none;
        filter:drop-shadow(0 1px 2px rgba(0,0,0,.28));
      }
      .bullpen-target-mitt svg{width:100%;height:100%;display:block;overflow:visible;}
      .bullpen-target-label{
        position:absolute;
        z-index:21;
        transform:translate(-50%,6px);
        pointer-events:none;
        font-size:9px;
        line-height:1;
        font-weight:900;
        color:#6c3b14;
        background:rgba(255,255,255,.92);
        padding:2px 4px;
        border-radius:3px;
        white-space:nowrap;
      }

      .bullpen-result-row{display:flex;gap:10px;margin-bottom:10px;}
      .bullpen-result-row .result-button{min-width:150px;}
      .bullpen-progress-grid{display:block;margin-bottom:8px;}
      .bullpen-progress-grid>.shiny-html-output{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:7px;width:100%;}
      .bullpen-progress-card{border:1px solid #e1e1e1;border-radius:7px;background:#fff;padding:8px 6px;text-align:center;min-width:0;}
      .bullpen-progress-label{min-height:20px;font-size:9px;line-height:1.05;font-weight:900;color:#555;text-transform:uppercase;}
      .bullpen-progress-value{margin-top:4px;font-size:19px;line-height:1;font-weight:900;}
      .bullpen-session-banner{border-left:4px solid #A7191F;padding:7px 10px;background:#f8f8f8;margin-bottom:8px;font-size:11px;line-height:1.3;}

      /* BULLPEN REPORT VISUALS */
      .bullpen-report-control-row{
        display:grid;
        grid-template-columns:minmax(180px,280px) minmax(180px,280px);
        gap:10px;
        align-items:end;
        margin-bottom:8px;
      }
      .bullpen-report-control-row .form-group{margin-bottom:0;}
      .bullpen-visual-grid{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:10px;
        margin-top:10px;
        margin-bottom:10px;
      }
      .bullpen-visual-card{
        border:1px solid #e1e1e1;
        border-radius:8px;
        background:#fff;
        padding:10px 12px;
        min-width:0;
      }
      .bullpen-visual-title{
        color:#A7191F;
        font-size:13px;
        font-weight:900;
        text-transform:uppercase;
        margin-bottom:4px;
      }
      .bullpen-visual-note{
        color:#666;
        font-size:10px;
        line-height:1.3;
        margin-bottom:6px;
      }
      .bullpen-plot-wrap .shiny-plot-output{
        width:100% !important;
      }
      .bullpen-trend-grid{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:9px;
        margin-top:8px;
      }
      .bullpen-trend-card{
        border:1px solid #e6e6e6;
        border-radius:7px;
        padding:7px 8px 4px 8px;
        background:#fff;
      }
      .bullpen-trend-label{
        font-size:10px;
        font-weight:900;
        color:#555;
        text-transform:uppercase;
        margin-bottom:2px;
      }
      .bullpen-comparison-controls{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:10px;
        margin-bottom:8px;
      }
      .bullpen-comparison-controls .form-group{margin-bottom:0;}
      .bullpen-comparison-summary{
        display:grid;
        grid-template-columns:repeat(4,minmax(0,1fr));
        gap:7px;
        margin:8px 0;
      }
      .bullpen-compare-card{
        border:1px solid #e1e1e1;
        border-radius:7px;
        text-align:center;
        padding:8px 6px;
        background:#fff;
      }
      .bullpen-compare-label{
        font-size:9px;
        font-weight:900;
        color:#555;
        text-transform:uppercase;
        min-height:20px;
      }
      .bullpen-compare-value{
        font-size:18px;
        line-height:1;
        font-weight:900;
        margin-top:4px;
      }
      .bullpen-compare-delta{
        font-size:10px;
        font-weight:900;
        margin-top:4px;
      }
      .bullpen-delta-good{color:#18833b;}
      .bullpen-delta-bad{color:#b51f24;}
      .bullpen-delta-neutral{color:#666;}
      .bullpen-direction-grid{
        display:grid;
        grid-template-columns:minmax(0,1fr) minmax(0,1fr);
        gap:8px;
        align-items:start;
      }

      @media(max-width:1100px){
        .bullpen-mode-grid{grid-template-columns:1fr;}
        .bullpen-progress-grid>.shiny-html-output{grid-template-columns:repeat(3,minmax(0,1fr));}
        .bullpen-visual-grid,.bullpen-trend-grid{grid-template-columns:1fr;}
        .bullpen-comparison-summary{grid-template-columns:repeat(2,minmax(0,1fr));}
      }
      @media(max-width:800px){
        .bullpen-report-control-row,.bullpen-comparison-controls,.bullpen-direction-grid{grid-template-columns:1fr;}
      }
      .admin-page{max-width:1380px;margin:0 auto;}
      .admin-toolbar{display:flex;flex-wrap:wrap;gap:8px;align-items:end;margin-bottom:10px;}
      .admin-toolbar .form-group{margin-bottom:0;}
      .admin-grid-4{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px;margin-bottom:10px;}
      .admin-grid-3{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin-bottom:10px;}
      .admin-grid-2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;margin-bottom:10px;}
      .admin-card{border:1px solid #e3e3e3;border-radius:9px;background:#fff;padding:11px 12px;box-shadow:0 1px 2px rgba(0,0,0,.04);}
      .admin-title{font-size:13px;font-weight:900;color:#A7191F;text-transform:uppercase;letter-spacing:.25px;margin-bottom:8px;}
      .admin-kpi{border:1px solid #e5e5e5;border-radius:8px;padding:10px;text-align:center;background:#fff;}
      .admin-kpi-label{font-size:9px;font-weight:900;color:#666;text-transform:uppercase;}
      .admin-kpi-value{font-size:25px;font-weight:900;line-height:1.05;margin-top:4px;}
      .admin-status-pill{display:inline-block;border-radius:999px;padding:4px 9px;font-size:10px;font-weight:900;text-transform:uppercase;background:#eee;color:#333;}
      .admin-status-active{background:#e2f4e7;color:#157638;}
      .admin-status-complete{background:#ececec;color:#555;}
      .admin-note{font-size:10px;color:#666;line-height:1.35;margin-top:6px;}
      .settings-weight-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px;}
      .multi-user-ready{border-left:4px solid #19833b;background:#f4fbf6;padding:9px 10px;font-size:11px;line-height:1.35;margin-bottom:8px;}
      .connection-card{border-left:4px solid #A7191F;background:#faf7f7;padding:9px 10px;font-size:11px;line-height:1.35;}
      @media(max-width:1100px){.admin-grid-4,.settings-weight-grid{grid-template-columns:repeat(2,minmax(0,1fr));}.admin-grid-3{grid-template-columns:1fr;}}
      @media(max-width:800px){.admin-grid-4,.admin-grid-2,.settings-weight-grid{grid-template-columns:1fr;}}


      @media (max-width:1200px) {
        .pitcher-kpi-grid > .shiny-html-output { grid-template-columns:repeat(5,1fr); }
        .pitcher-section-grid-3{grid-template-columns:1fr;}
      }
      @media (max-width:950px) { .pitcher-topbar{grid-template-columns:1fr;} .pitcher-filter-grid{grid-template-columns:1fr 1fr;} .pitcher-section-grid-2{grid-template-columns:1fr;} }

      @media (max-width: 1050px) {
        .heatmap-row {
          overflow-x: auto;
          padding-bottom: 5px;
        }

        .heatmap-panel {
          flex: 0 0 210px;
        }

        .heatmap-visual-wrap {
          width: 200px;
          height: 205px;
        }

        .heatmap-plot-wrap {
          width: 150px;
          min-width: 150px;
        }

        .heatmap-plot-wrap > div {
          width: 150px;
          max-width: 150px;
        }

        .batter-silhouette {
          width: 88px;
          height: 184px;
        }

        .batter-silhouette.rhh,
        .batter-silhouette.switch {
          left: 15px;
        }

        .batter-silhouette.lhh {
          right: 15px;
        }
      }
"))
  ),
  
  tags$script(HTML("
    function switchMainTab(tabName, el) {
      $('.nav-tabs a[data-value=\"' + tabName + '\"]').tab('show');
      $('.app-nav-item').removeClass('active');
      if (el) $(el).addClass('active');
      return false;
    }
    Shiny.addCustomMessageHandler('leaderboardNavigate', function(message) {
      $('.nav-tabs a[data-value=\"' + message.tab + '\"]').tab('show');
      $('.app-nav-item').removeClass('active');
      $('.app-nav-item').each(function() {
        var txt = ($(this).text() || '').replace(/\\s+/g, ' ').trim();
        if (txt.indexOf(message.sidebar) !== -1) $(this).addClass('active');
      });
    });
    Shiny.addCustomMessageHandler('switch-tab-from-r', function(tabName) {
      $('.nav-tabs a[data-value=\"' + tabName + '\"]').tab('show');
      $('.app-nav-item').removeClass('active');
      $('.app-nav-item').each(function() {
        var txt = ($(this).text() || '').replace(/\\s+/g, ' ').trim().toUpperCase();
        if (txt.indexOf(tabName.toUpperCase()) !== -1) $(this).addClass('active');
      });
    });
  ")),
  
  div(
    class = "app-sidebar",
    
    div(
      class = "app-sidebar-logo-wrap",
      tags$img(
        class = "app-sidebar-logo",
        src = "lagrange_logo.png",
        onerror = "this.style.display='none';"
      ),
      div(
        class = "app-sidebar-brand",
        "LAGRANGE BASEBALL"
      )
    ),
    
    tags$a(
      class = "app-nav-item active",
      href = "#",
      onclick = "return switchMainTab('Live Charting', this);",
      tags$span(class = "app-nav-icon", "◉"),
      "LIVE CHARTING"
    ),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Hitter Report', this);",
      tags$span(class = "app-nav-icon", "●"),
      "HITTER'S REPORTS"
    ),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Pitcher Report', this);",
      tags$span(class = "app-nav-icon", "◆"),
      "PITCHER REPORTS"
    ),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Leaderboard', this);",
      tags$span(class = "app-nav-icon", "★"),
      "LEADERBOARDS"
    ),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Team Report', this);",
      tags$span(class = "app-nav-icon", "▥"),
      "TEAM REPORTS"
    ),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Sessions', this);",
      tags$span(class = "app-nav-icon", "☰"),
      "SESSIONS"
    ),
    
    div(class = "app-sidebar-spacer"),
    
    tags$a(
      class = "app-nav-item",
      href = "#",
      onclick = "return switchMainTab('Settings', this);",
      tags$span(class = "app-nav-icon", "⚙"),
      "SETTINGS"
    ),
    
    div(
      class = "app-sidebar-footer",
      "Swing Decision Platform"
    )
  ),
  
  titlePanel("LaGrange Swing Decision Platform"),
  
  tabsetPanel(
    
    tabPanel(
      "Live Charting",
      
      h2("Live Charting"),
      
      # ==================================================
      # SESSION
      # ==================================================
      
      div(
        class = "session-box",
        
        h3("Session"),
        
        fluidRow(
          
          column(
            width = 6,
            
            selectInput(
              "session_select",
              "Current Session",
              choices = NULL
            )
            
          ),
          
          column(
            width = 3,
            textInput("charting_user","Charting By",value = "")
          ),
          
          column(
            width = 3,
            
            br(),
            
            actionButton(
              "refresh_sessions",
              "REFRESH SESSIONS"
            )
            
          )
          
        ),
        
        h4("Selected Session:"),
        
        div(
          class = "selected-value",
          textOutput("selected_session_text")
        ),
        
        checkboxInput(
          "show_create_session",
          "Create New Session",
          value = FALSE
        ),
        
        conditionalPanel(
          
          condition = "input.show_create_session == true",
          
          hr(),
          
          fluidRow(
            
            column(
              width = 4,
              
              dateInput(
                "new_session_date",
                "Session Date",
                value = Sys.Date()
              )
              
            ),
            
            column(
              width = 4,
              
              textInput(
                "new_session_name",
                "Session Name",
                placeholder = "Example: Fall Live AB #1"
              )
              
            ),
            
            column(
              width = 4,
              
              selectInput(
                "new_session_type",
                "Session Type",
                choices = c(
                  "Live AB",
                  "Scrimmage",
                  "Practice",
                  "Game",
                  "Other"
                ),
                selected = "Live AB"
              )
              
            )
            
          ),
          
          fluidRow(
            
            column(
              width = 4,
              
              textInput(
                "new_session_opponent",
                "Opponent",
                placeholder = "Optional"
              )
              
            ),
            
            column(
              width = 4,
              
              textInput(
                "new_session_location",
                "Location",
                placeholder = "Optional"
              )
              
            ),
            
            column(
              width = 4,
              
              textInput(
                "new_session_created_by",
                "Created By",
                value = "Nate Marko"
              )
              
            )
            
          ),
          
          textAreaInput(
            "new_session_notes",
            "Notes",
            placeholder = "Optional session notes"
          ),
          
          actionButton(
            "create_session",
            "CREATE SESSION"
          )
          
        )
        
      ),
      
      hr(),
      
      # ==================================================
      # SESSION MODE
      # ==================================================
      
      div(
        class="bullpen-mode-card",
        div(class="bullpen-mode-title","Session Mode"),
        div(
          class="bullpen-mode-grid",
          selectInput("charting_mode","Mode",choices=c("Live AB / Game"="Live","Bullpen"="Bullpen"),selected="Live"),
          conditionalPanel(condition="input.charting_mode == 'Bullpen'",textInput("bullpen_focus","Bullpen Focus",placeholder="ex: Fastball glove-side command")),
          conditionalPanel(condition="input.charting_mode == 'Bullpen'",textInput("bullpen_notes","Bullpen Notes",placeholder="Optional notes"))
        )
      ),
      
      # ==================================================
      # GAME STATE
      # ==================================================
      
      conditionalPanel(
        condition="input.charting_mode != 'Bullpen'",
        div(
          class = "game-state-box",
          div(class = "game-state-title", "Game State"),
          div(
            class = "game-state-grid",
            numericInput(
              "inning_number",
              "Inning",
              value = 1,
              min = 1,
              max = 30,
              step = 1
            ),
            radioButtons(
              "inning_half",
              "Half",
              choices = c("Top" = "Top", "Bottom" = "Bottom"),
              selected = "Top",
              inline = TRUE
            ),
            div(
              div(style="font-weight:700;margin-bottom:5px;", "Outs"),
              div(
                class = "outs-controls",
                actionButton("outs_minus", "- OUT"),
                div(class="outs-display", textOutput("game_outs_display", inline=TRUE)),
                actionButton("outs_plus", "+ OUT")
              )
            )
          )
        ),
        
      ),
      
      # ==================================================
      # BATTER / PITCHER
      # ==================================================
      
      fluidRow(
        column(
          width=6,
          conditionalPanel(
            condition="input.charting_mode != 'Bullpen'",
            selectInput("batter","Batter",choices=NULL)
          )
        ),
        column(
          width=6,
          selectInput("pitcher","Pitcher",choices=NULL)
        )
      ),
      
      conditionalPanel(
        condition="input.charting_mode == 'Bullpen'",
        div(
          class="bullpen-target-card",
          div(class="bullpen-target-title","Bullpen Location Workflow"),
          div(
            class="bullpen-target-note",
            "1) Click the strike-zone map where the catcher is setting up. A catcher's mitt will appear. 2) Click the map again where the pitch actually crossed. 3) Click BALL or STRIKE to save the pitch."
          ),
          div(
            class="bullpen-click-instructions",
            uiOutput("bullpen_click_step_ui")
          ),
          div(
            class="bullpen-reset-target",
            actionButton("bullpen_reset_target","RESET TARGET / LOCATION")
          )
        )
      ),
      
      conditionalPanel(
        condition="input.charting_mode != 'Bullpen'",
        div(
          class = "quab-charting-box",
          div(class = "quab-charting-title", "QUAB / Offensive Play Tracking"),
          div(
            class = "quab-charting-grid",
            numericInput("pa_rbi", "RBI", value = 0, min = 0, max = 10, step = 1),
            checkboxInput("quab_barrel", "Barrel", value = FALSE),
            checkboxInput("quab_offensive_play", "Successful Offensive Play", value = FALSE),
            checkboxInput("quab_move_runner_third", "Moved Runner to 3rd (<2 outs)", value = FALSE)
          ),
          div(
            class = "quab-charting-note",
            "Automatically tracked QUAB criteria: Hit, Walk/HBP, RBI, 8+ pitch PA, 4+ pitches after reaching 2 strikes, and Reached on Error. ",
            "Barrel is automatically credited whenever Contact Quality is charted as Hard. Use the manual tags only for successful offensive plays that are not already obvious from the PA result and moving a runner to third with fewer than two outs."
          )
        ),
        
      ),
      
      # ==================================================
      # COUNT
      # ==================================================
      
      conditionalPanel(
        condition="input.charting_mode != 'Bullpen'",
        h3("Count"),
        
        h1(
          textOutput("count")
        ),
        
        hr(),
        
      ),
      
      # ==================================================
      # PITCH TYPE
      # ==================================================
      
      h3("Pitch Type"),
      
      fluidRow(
        column(1, actionButton("pitch_fb", "FB")),
        column(1, actionButton("pitch_si", "SI")),
        column(1, actionButton("pitch_ct", "CT")),
        column(1, actionButton("pitch_sl", "SL")),
        column(1, actionButton("pitch_cb", "CB")),
        column(1, actionButton("pitch_sw", "SW")),
        column(1, actionButton("pitch_ch", "CH")),
        column(1, actionButton("pitch_split", "SPLIT")),
        column(1, actionButton("pitch_other", "OTHER"))
      ),
      
      br(),
      
      h4("Selected Pitch Type:"),
      
      h3(
        textOutput("selected_pitch_type")
      ),
      
      hr(),
      
      # ==================================================
      # PITCH LOCATION
      # ==================================================
      
      h3("Pitch Location"),
      
      p("Click the location where the pitch crossed the zone."),
      
      div(
        class = "zone-container",
        uiOutput("strike_zone_svg"),
        uiOutput("bullpen_target_mitt_overlay")
      ),
      
      h4("Selected Location:"),
      
      div(
        class = "selected-zone-text",
        textOutput("selected_zone_text")
      ),
      
      hr(),
      
      # ==================================================
      # RESULT
      # ==================================================
      
      h3("Pitch Result"),
      
      conditionalPanel(
        condition="input.charting_mode == 'Bullpen'",
        div(
          class="bullpen-result-row",
          actionButton("bullpen_result_strike","STRIKE",class="result-button"),
          actionButton("bullpen_result_ball","BALL",class="result-button")
        )
      ),
      
      conditionalPanel(
        condition="input.charting_mode != 'Bullpen'",
        div(
          actionButton("result_ball","BALL",class="result-button"),
          actionButton("result_hbp","HIT BY PITCH",class="result-button"),
          actionButton("result_called_strike","CALLED STRIKE",class="result-button"),
          actionButton("result_whiff","WHIFF",class="result-button"),
          actionButton("result_foul","FOUL",class="result-button"),
          actionButton("result_in_play","IN PLAY",class="result-button")
        )
      ),
      
      h4("Last Pitch Result:"),
      
      h3(
        textOutput("last_pitch_result")
      ),
      
      uiOutput("in_play_ui"),
      
      uiOutput("charting_message"),
      
      uiOutput("save_message"),
      
      uiOutput("pa_complete_ui")
      
    ),
    
    tabPanel(
      "Hitter Report",
      
      div(
        class = "player-report-shell",
        
        div(
          class = "report-topbar",
          
          div(
            class = "report-player-card",
            uiOutput("report_player_headshot"),
            div(
              div(
                class = "player-report-kicker",
                "PLAYER REPORT"
              ),
              div(
                class = "report-player-name",
                textOutput("report_player_name", inline = TRUE)
              ),
              div(
                class = "report-player-meta",
                uiOutput("report_player_bio")
              )
            )
          ),
          
          div(
            class = "report-filters-card",
            div(
              class = "report-filter-grid",
              
              selectInput(
                "report_batter",
                "Player",
                choices = NULL
              ),
              
              selectInput(
                "report_session",
                "Session",
                choices = c("All Sessions (Cumulative)" = "ALL"),
                selected = "ALL"
              ),
              
              dateRangeInput(
                "report_date_range",
                "Date Range",
                start = Sys.Date() - 365,
                end = Sys.Date()
              ),
              
              actionButton(
                "refresh_report",
                "REFRESH"
              )
            ),
            
            div(
              class = "player-report-status",
              uiOutput("report_status")
            )
          )
        ),
        
        div(
          class = "report-grade-comparison",
          
          div(
            class = "grade-block",
            div(class = "grade-block-title", "Cumulative (All Sessions)"),
            div(
              class = "grade-block-grid",
              uiOutput("cumulative_grade_cells")
            )
          ),
          
          div(
            class = "grade-block",
            div(class = "grade-block-title", "Selected Session"),
            div(
              class = "grade-block-subtitle",
              textOutput("selected_session_label", inline = TRUE)
            ),
            div(
              class = "grade-block-grid",
              uiOutput("selected_session_grade_cells")
            )
          )
        ),
        div(
          class = "benchmark-legend",
          tags$span(tags$span(class = "benchmark-dot good"), "Better than team avg"),
          tags$span(tags$span(class = "benchmark-dot average"), "Near team avg"),
          tags$span(tags$span(class = "benchmark-dot poor"), "Below team avg")
        ),
        
        div(
          class = "compact-metric-strip",
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Heart Swing %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_heart_swing_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Chase %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_chase_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Shadow Swing %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_shadow_swing_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Overall Swing %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_overall_swing_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Whiff %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_whiff_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Contact %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_contact_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Hard Contact %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_hard_contact_benchmark", inline = TRUE)
            )
          ),
          
          div(
            class = "compact-metric-cell",
            div(class = "compact-metric-label", "Heart Take %"),
            div(
              class = "compact-metric-number",
              uiOutput("metric_heart_take_benchmark", inline = TRUE)
            )
          )
        ),
        
        div(
          class = "compact-count-strip",
          
          div(
            class = "compact-count-cell compact-count-label",
            "Count State"
          ),
          
          div(
            class = "compact-count-cell",
            div(
              class = "compact-count-head",
              "Pre-2K"
            ),
            div(
              class = "compact-count-value",
              uiOutput("metric_pre2k_heart_benchmark", inline = TRUE),
              " Heart Swing  •  ",
              uiOutput("metric_pre2k_chase_benchmark", inline = TRUE),
              " Chase"
            )
          ),
          
          div(
            class = "compact-count-cell",
            div(
              class = "compact-count-head",
              "2K"
            ),
            div(
              class = "compact-count-value",
              uiOutput("metric_twok_heart_benchmark", inline = TRUE),
              " Heart Swing  •  ",
              uiOutput("metric_twok_chase_benchmark", inline = TRUE),
              " Chase"
            )
          )
        ),
        
        div(
          class = "heatmap-row",
          
          div(
            class = "heatmap-panel",
            
            div(
              class = "heatmap-title",
              "SWING RATE"
            ),
            
            div(
              class = "heatmap-subtitle",
              textOutput(
                "swing_rate_overall",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-visual-wrap",
              
              uiOutput("swing_batter_silhouette"),
              
              div(
                class = "heatmap-plot-wrap",
                uiOutput("swing_rate_heatmap")
              )
            ),
            
            div(
              class = "heatmap-sample",
              textOutput(
                "swing_rate_sample",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-legend",
              "Blue = Lower Swing Rate • Red = Higher Swing Rate"
            )
          ),
          
          div(
            class = "heatmap-panel",
            
            div(
              class = "heatmap-title",
              "CHASE RATE"
            ),
            
            div(
              class = "heatmap-subtitle",
              textOutput(
                "chase_rate_overall",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-visual-wrap",
              
              uiOutput("chase_batter_silhouette"),
              
              div(
                class = "heatmap-plot-wrap",
                uiOutput("chase_rate_heatmap")
              )
            ),
            
            div(
              class = "heatmap-sample",
              textOutput(
                "chase_rate_sample",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-legend",
              "Blue = Lower Chase Rate • Red = Higher Chase Rate"
            )
          ),
          
          div(
            class = "heatmap-panel",
            
            div(
              class = "heatmap-title",
              "WHIFF RATE"
            ),
            
            div(
              class = "heatmap-subtitle",
              textOutput(
                "whiff_rate_overall",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-visual-wrap",
              
              uiOutput("whiff_batter_silhouette"),
              
              div(
                class = "heatmap-plot-wrap",
                uiOutput("whiff_rate_heatmap")
              )
            ),
            
            div(
              class = "heatmap-sample",
              textOutput(
                "whiff_rate_sample",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-legend",
              "Blue = Lower Whiff Rate • Red = Higher Whiff Rate"
            )
          ),
          
          div(
            class = "heatmap-panel",
            
            div(
              class = "heatmap-title",
              "DECISION QUALITY"
            ),
            
            div(
              class = "heatmap-subtitle",
              textOutput(
                "decision_quality_overall",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-visual-wrap",
              
              uiOutput("decision_batter_silhouette"),
              
              div(
                class = "heatmap-plot-wrap",
                uiOutput("decision_quality_heatmap")
              )
            ),
            
            div(
              class = "heatmap-sample",
              textOutput(
                "decision_quality_sample",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-legend",
              "Blue = Poorer Decisions • Red = Better Decisions"
            )
          ),
          
          div(
            class = "heatmap-panel",
            
            div(
              class = "heatmap-title",
              "CONTACT QUALITY"
            ),
            
            div(
              class = "heatmap-subtitle",
              textOutput(
                "contact_quality_overall",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-visual-wrap",
              
              uiOutput("contact_batter_silhouette"),
              
              div(
                class = "heatmap-plot-wrap",
                uiOutput("contact_quality_heatmap")
              )
            ),
            
            div(
              class = "heatmap-sample",
              textOutput(
                "contact_quality_sample",
                inline = TRUE
              )
            ),
            
            div(
              class = "heatmap-legend",
              "Blue = Weaker Contact • Red = Better Contact"
            )
          )
        ),
        
        div(
          class = "heatmap-shared-note",
          tags$span(
            style = "color:#A7191F;font-weight:700;",
            "Red = Higher / Better"
          ),
          "   •   ",
          tags$span(
            style = "color:#1F4BA8;font-weight:700;",
            "Blue = Lower / Worse"
          ),
          "   •   Heat maps use exact charted pitch locations."
        ),
        
        div(
          class = "catchers-view-note",
          "View shown from catcher's perspective."
        ),
        
        div(
          class = "decision-quality-explainer",
          tags$strong("WHAT IS DECISION QUALITY? "),
          "Decision Quality reflects how good each swing/take decision was based on pitch location and count context. ",
          "It combines the value of taking vs. swinging at Heart, Shadow, Chase and Waste pitches, then adjusts for execution outcomes such as contact quality and strikeouts. ",
          "Higher values indicate better decisions."
        ),
        
        div(
          class = "report-breakdown-grid",
          
          div(
            class = "report-breakdown-card",
            div(
              class = "report-breakdown-title",
              "Pitch Type Breakdown"
            ),
            uiOutput("report_pitch_type_table"),
            div(
              class = "report-breakdown-note",
              "Swing and whiff rates are calculated within each pitch type."
            )
          ),
          
          div(
            class = "report-breakdown-card",
            div(
              class = "report-breakdown-title",
              "Count Breakdown"
            ),
            uiOutput("report_count_table"),
            div(
              class = "report-breakdown-note",
              "Chase % uses pitches charted in Chase or Waste zones."
            )
          ),
          
          div(
            class = "report-breakdown-card",
            div(
              class = "report-breakdown-title",
              "Results"
            ),
            uiOutput("report_in_play_table"),
            div(
              class = "report-breakdown-note",
              "Includes all recorded PA-ending results, including strikeouts and walks."
            )
          ),
          
          div(
            class = "report-breakdown-card",
            div(
              class = "report-breakdown-title",
              "Player Statistics"
            ),
            uiOutput("report_player_stats"),
            div(
              class = "report-breakdown-note",
              "wOBA and wRC+ require league/year run-environment constants, so they remain N/A until those benchmarks are configured."
            )
          )
        )
        ,
        
        div(
          style = "text-align:center;margin:10px 0 18px 0;",
          downloadButton(
            "export_player_report_pdf",
            "EXPORT REPORT (PDF)",
            class = "btn btn-danger"
          )
        )
      )
    ),
    tabPanel(
      "Leaderboard",
      div(
        class = "leaderboard-shell",
        div(
          class = "leaderboard-header-card",
          div(class = "leaderboard-title", "Team Leaderboard"),
          div(
            class = "leaderboard-filter-grid",
            selectInput("leaderboard_type","Leaderboard",choices=c("Hitters"="Hitter","Pitchers"="Pitcher"),selected="Hitter"),
            selectInput("leaderboard_rank_metric","Leaderboard Stat",choices=c("Overall Grade"="Overall_Grade"),selected="Overall_Grade"),
            selectInput("leaderboard_session","Session",choices=c("All Sessions (Cumulative)"="ALL"),selected="ALL"),
            dateRangeInput("leaderboard_date_range","Date Range",start=Sys.Date()-365,end=Sys.Date()),
            actionButton("leaderboard_refresh","REFRESH")
          ),
          div(class="leaderboard-note","Green = better than the player-weighted team/staff average • Yellow = near average • Red = below average. Click a player name to jump directly to that player's full report.")
        ),
        uiOutput("leaderboard_quab_definition"),
        div(class="leaderboard-podium-card",div(class="leaderboard-podium-title","Top 3"),uiOutput("leaderboard_podium")),
        div(class="leaderboard-table-card",div(class="leaderboard-section-title",textOutput("leaderboard_table_title",inline=TRUE)),uiOutput("leaderboard_table"))
      )
    ),
    
    tabPanel(
      "Pitcher Report",
      div(
        class = "pitcher-report-shell",
        div(
          class = "pitcher-topbar",
          div(
            class = "pitcher-bio-card",
            uiOutput("pitcher_report_headshot"),
            div(
              div(class="player-report-kicker","PITCHER REPORT"),
              div(class="pitcher-name",textOutput("pitcher_report_name",inline=TRUE)),
              div(class="pitcher-meta",uiOutput("pitcher_report_bio"))
            )
          ),
          div(
            class = "pitcher-filter-card",
            div(
              class = "pitcher-filter-grid",
              selectInput("pitcher_report_pitcher","Pitcher",choices=NULL),
              selectInput("pitcher_report_session","Session",choices=c("All Sessions (Cumulative)"="ALL"),selected="ALL"),
              dateRangeInput("pitcher_report_date_range","Date Range",start=Sys.Date()-365,end=Sys.Date()),
              actionButton("refresh_pitcher_report","REFRESH")
            ),
            div(class="player-report-status",uiOutput("pitcher_report_status"))
          )
        ),
        div(class="pitcher-grade-grid",uiOutput("pitcher_report_grades")),
        div(
          class = "decision-quality-explainer",
          style = "margin-top:0;margin-bottom:7px;",
          tags$strong("HOW ARE THE PITCHER GRADES CALCULATED? "),
          tags$strong("Overall Grade: "),
          "Composite of Command, Miss and Efficiency.  ",
          tags$strong("Command Grade: "),
          "First-pitch strike %, overall strike %, zone % and avoiding behind counts.  ",
          tags$strong("Miss Grade: "),
          "Whiff % and chase %.  ",
          tags$strong("Efficiency Grade: "),
          "Getting ahead, creating contact within the first three pitches, and the percentage of tracked innings completed in 15 pitches or fewer. ",
          "Grades are centered against the current pitching-staff average, which also drives the green / yellow / red comparisons."
        ),
        div(
          class="pitcher-team-legend",
          tags$span(class="g","● Better than staff avg"), "   ",
          tags$span(class="y","● Near staff avg"), "   ",
          tags$span(class="r","● Below staff avg")
        ),
        div(class="pitcher-kpi-grid",uiOutput("pitcher_report_kpis")),
        div(
          class="pitcher-section-grid-2",
          div(class="pitcher-section-card",div(class="pitcher-section-title","Count Leverage"),uiOutput("pitcher_count_leverage"),div(class="pitcher-section-note","Ahead = 0-1, 0-2, 1-2. Even = 0-0, 1-1, 2-2. Behind = 1-0, 2-0, 2-1, 3-0, 3-1, 3-2.")),
          div(class="pitcher-section-card",div(class="pitcher-section-title","Pitch Efficiency by Inning"),uiOutput("pitcher_inning_efficiency_table"),div(class="pitcher-section-note","Staff goal: 15 pitches or fewer per inning. New pitches charted with this version store inning."))
        ),
        div(
          class="pitcher-section-grid-2",
          div(class="pitcher-section-card",div(class="pitcher-section-title","Pitch Arsenal / Outcomes"),uiOutput("pitcher_arsenal_table"),div(class="pitcher-section-note","Whiff % = whiffs / swings. Chase % = swings on Chase/Waste pitches. Zone % = Heart + Shadow.")),
          div(class="pitcher-section-card",div(class="pitcher-section-title","Pitch Usage by Count"),uiOutput("pitcher_count_usage_table"),div(class="pitcher-section-note","Hard = FB/SI/CT. Breaking = SL/CB/SW. Soft = CH/SPLIT."))
        ),
        div(
          class="pitcher-section-grid-2",
          div(
            class="pitcher-section-card",
            div(class="pitcher-section-title","Pitch Location"),
            div(
              class="pitcher-location-control",
              selectInput("pitcher_location_pitch_type","Pitch Type",choices=c("All Pitches"="ALL"),selected="ALL"),
              selectInput("pitcher_location_batter_side","Batter Side",choices=c("All"="ALL","vs RHH"="R","vs LHH"="L"),selected="ALL")
            ),
            div(class="pitcher-section-note","Exact charted locations. Silhouette is shown from catcher view; both sides are ghosted when All is selected."),
            uiOutput("pitcher_location_heatmap")
          ),
          div(class="pitcher-section-card",div(class="pitcher-section-title","Batter-Side Splits"),uiOutput("pitcher_side_splits_table"))
        ),
        div(
          class="pitcher-section-grid-3",
          div(class="pitcher-section-card",div(class="pitcher-section-title","Results"),uiOutput("pitcher_results_table")),
          div(class="pitcher-section-card",div(class="pitcher-section-title","Count Averages / Tendencies"),uiOutput("pitcher_count_summary_table"),div(class="pitcher-section-note","Share % = percentage of all charted pitches thrown while the pitcher was Ahead, Even, or Behind.")),
          div(class="pitcher-section-card",div(class="pitcher-section-title","Pitch Group Summary"),uiOutput("pitcher_group_summary_table"))
        ),
        div(
          class="pitcher-section-card",
          style="margin-bottom:8px;",
          div(class="pitcher-section-title","Pitcher Statistics / Contact Allowed"),
          uiOutput("pitcher_statistics_grid"),
          div(class="pitcher-section-note","K%, BB%, K-BB%, HR%, BABIP and opponent slash line are supported from charted PA data. ERA, xERA, FIP, xFIP, GS, QS and CG require run/game-state data or league constants that this manual system does not currently collect, so they are intentionally not estimated.")
        ),
        div(
          class="pitcher-section-card",
          style="margin-bottom:8px;",
          div(class="pitcher-section-title","Bullpen Progress"),
          
          div(
            class="bullpen-report-control-row",
            selectInput(
              "pitcher_bullpen_session",
              "Bullpen Session",
              choices=c("All Bullpens (Cumulative)"="ALL"),
              selected="ALL"
            ),
            selectInput(
              "pitcher_bullpen_plot_pitch_type",
              "Bullpen Visual Pitch Type",
              choices=c("All Pitches"="ALL"),
              selected="ALL"
            )
          ),
          
          uiOutput("pitcher_bullpen_banner"),
          
          div(
            class="bullpen-progress-grid",
            uiOutput("pitcher_bullpen_kpis")
          ),
          
          div(
            class="bullpen-visual-grid",
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Target vs Actual"),
              div(class="bullpen-visual-note","Catcher target → actual pitch location. Each line shows the direction and size of the miss."),
              div(class="bullpen-plot-wrap",plotOutput("pitcher_bullpen_target_actual_plot",height="390px"))
            ),
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Command Heatmap — Relative to Target"),
              div(class="bullpen-visual-note",uiOutput("pitcher_bullpen_relative_note")),
              div(class="bullpen-plot-wrap",plotOutput("pitcher_bullpen_relative_heatmap",height="390px"))
            )
          ),
          
          div(
            class="bullpen-visual-grid",
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Miss Direction"),
              div(class="bullpen-visual-note",uiOutput("pitcher_bullpen_direction_note")),
              div(
                class="bullpen-direction-grid",
                div(class="bullpen-plot-wrap",plotOutput("pitcher_bullpen_miss_direction_plot",height="300px")),
                uiOutput("pitcher_bullpen_miss_direction_table")
              )
            ),
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Bullpen Pitch-Type Command"),
              uiOutput("pitcher_bullpen_pitch_type_table")
            )
          ),
          
          div(
            class="bullpen-visual-card",
            style="margin-bottom:10px;",
            div(class="bullpen-visual-title","Bullpen Progress Over Time"),
            div(class="bullpen-visual-note","Session-by-session development. Command Grade and Target Execution should trend up; Avg Miss Distance should trend down."),
            div(
              class="bullpen-trend-grid",
              div(class="bullpen-trend-card",div(class="bullpen-trend-label","Command Grade"),plotOutput("pitcher_bullpen_command_trend",height="190px")),
              div(class="bullpen-trend-card",div(class="bullpen-trend-label","Target Execution %"),plotOutput("pitcher_bullpen_target_trend",height="190px")),
              div(class="bullpen-trend-card",div(class="bullpen-trend-label","Avg Miss Distance"),plotOutput("pitcher_bullpen_miss_trend",height="190px")),
              div(class="bullpen-trend-card",div(class="bullpen-trend-label","Strike %"),plotOutput("pitcher_bullpen_strike_trend",height="190px"))
            )
          ),
          
          div(
            class="bullpen-visual-grid",
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Recent Bullpen Sessions"),
              uiOutput("pitcher_bullpen_trend_table")
            ),
            
            div(
              class="bullpen-visual-card",
              div(class="bullpen-visual-title","Session-to-Session Comparison"),
              div(class="bullpen-visual-note","Compare any two bullpen sessions for the selected pitcher. Change is Session B minus Session A."),
              div(
                class="bullpen-comparison-controls",
                selectInput("pitcher_bullpen_compare_a","Session A",choices=c("Select Session"=""),selected=""),
                selectInput("pitcher_bullpen_compare_b","Session B",choices=c("Select Session"=""),selected="")
              ),
              uiOutput("pitcher_bullpen_comparison")
            )
          ),
          
          div(class="pitcher-section-note",uiOutput("pitcher_bullpen_explainer"))
        ),
        
        div(style="text-align:center;margin:10px 0 18px 0;",downloadButton("export_pitcher_report_pdf","EXPORT PITCHER REPORT (PDF)",class="btn btn-danger"))
      )
    ),
    
    tabPanel(
      "Team Report",
      
      div(
        class = "team-report-shell",
        
        div(
          class = "team-report-header",
          div(class = "team-report-title", "Team Reports"),
          
          div(
            class = "team-report-filter-grid",
            
            selectInput(
              "team_report_type",
              "Report",
              choices = c(
                "Hitters" = "Hitter",
                "Pitchers" = "Pitcher"
              ),
              selected = "Hitter"
            ),
            
            selectInput(
              "team_report_session",
              "Session",
              choices = c(
                "All Sessions (Cumulative)" = "ALL"
              ),
              selected = "ALL"
            ),
            
            dateRangeInput(
              "team_report_date_range",
              "Date Range",
              start = Sys.Date() - 365,
              end = Sys.Date()
            ),
            
            actionButton(
              "team_report_refresh",
              "REFRESH"
            )
          ),
          
          div(
            class = "team-report-note",
            uiOutput("team_report_status")
          )
        ),
        
        div(
          class = "team-report-kpi-grid",
          uiOutput("team_report_kpis")
        ),
        
        conditionalPanel(
          condition = "input.team_report_type == 'Hitter'",
          
          div(
            class = "team-report-grid-3",
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Pitch Type Breakdown"),
              uiOutput("team_hitter_pitch_type_table")
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Count Breakdown"),
              uiOutput("team_hitter_count_table")
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Results"),
              uiOutput("team_hitter_results_table")
            )
          ),
          
          div(
            class = "team-report-grid-2",
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Player vs Team Average"),
              uiOutput("team_hitter_player_status"),
              div(
                class = "team-report-note",
                "Status compares each hitter's Overall Decision Grade to the selected team's player average."
              )
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "QUAB Summary"),
              uiOutput("team_hitter_quab_table"),
              div(
                class = "team-report-note",
                "QUAB = Hit, Walk/HBP, RBI, 8+ pitch PA, 4+ pitches after 2K, Hard-contact barrel, successful offensive play, runner moved to third with <2 outs, or reached on error."
              )
            )
          ),
          
          div(
            class = "team-report-trend-card",
            div(class = "team-report-section-title", "Last 5 Session Trends"),
            uiOutput("team_hitter_trend_table"),
            div(
              class = "team-report-note",
              "Shows the five most recent charted sessions inside the selected date range."
            )
          )
        ),
        
        conditionalPanel(
          condition = "input.team_report_type == 'Pitcher'",
          
          div(
            class = "team-report-grid-3",
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Pitch Type / Arsenal"),
              uiOutput("team_pitcher_pitch_type_table")
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Count Tendencies"),
              uiOutput("team_pitcher_count_table")
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Results"),
              uiOutput("team_pitcher_results_table")
            )
          ),
          
          div(
            class = "team-report-grid-2",
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Pitcher vs Staff Average"),
              uiOutput("team_pitcher_player_status"),
              div(
                class = "team-report-note",
                "Status compares each pitcher's Overall Grade to the selected pitching-staff average."
              )
            ),
            
            div(
              class = "team-report-card",
              div(class = "team-report-section-title", "Contact Allowed"),
              uiOutput("team_pitcher_contact_table")
            )
          ),
          
          div(
            class = "team-report-trend-card",
            div(class = "team-report-section-title", "Last 5 Session Trends"),
            uiOutput("team_pitcher_trend_table"),
            div(
              class = "team-report-note",
              "Tracks staff process metrics session-to-session without relying on TrackMan velocity, movement, or spin."
            )
          )
        )
      )
    ),
    
    tabPanel(
      "Sessions",
      div(class="admin-page",
          h2("Sessions"),
          div(class="admin-toolbar",
              actionButton("sessions_refresh","REFRESH"),
              selectInput("sessions_status_filter","Status",choices=c("All"="ALL","Active"="Active","Completed"="Completed"),selected="ALL"),
              selectInput("sessions_type_filter","Type",choices=c("All Types"="ALL"),selected="ALL"),
              dateRangeInput("sessions_date_filter","Date Range",start=Sys.Date()-90,end=Sys.Date())
          ),
          div(class="admin-grid-4",
              div(class="admin-kpi",div(class="admin-kpi-label","Sessions"),div(class="admin-kpi-value",textOutput("sessions_kpi_sessions",inline=TRUE))),
              div(class="admin-kpi",div(class="admin-kpi-label","Pitches"),div(class="admin-kpi-value",textOutput("sessions_kpi_pitches",inline=TRUE))),
              div(class="admin-kpi",div(class="admin-kpi-label","Plate Appearances"),div(class="admin-kpi-value",textOutput("sessions_kpi_pas",inline=TRUE))),
              div(class="admin-kpi",div(class="admin-kpi-label","Active Sessions"),div(class="admin-kpi-value",textOutput("sessions_kpi_active",inline=TRUE)))
          ),
          div(class="admin-grid-2",
              div(class="admin-card",
                  div(class="admin-title","Session Directory"),
                  div(style="max-width:520px;",selectInput("sessions_manage_id","Manage Session",choices=c("Select Session"=""),selected="")),
                  uiOutput("sessions_table")
              ),
              div(class="admin-card",
                  div(class="admin-title","Selected Session"),
                  uiOutput("sessions_selected_detail"),
                  div(class="admin-toolbar",
                      actionButton("sessions_open_live","OPEN IN LIVE CHARTING"),
                      actionButton("sessions_mark_active","MARK ACTIVE"),
                      actionButton("sessions_mark_complete","MARK COMPLETE")
                  ),
                  div(class="admin-note","Opening a session sends this browser to Live Charting. Status changes are shared across all devices.")
              )
          ),
          div(class="admin-card",
              div(class="admin-title","Create New Session"),
              div(class="admin-grid-3",
                  dateInput("sessions_new_date","Session Date",value=Sys.Date()),
                  textInput("sessions_new_name","Session Name",placeholder="Example: Bullpens — Friday"),
                  selectInput("sessions_new_type","Session Type",choices=c("Live AB","Bullpen","Scrimmage","Practice","Game","Other"),selected="Practice")
              ),
              div(class="admin-grid-3",
                  textInput("sessions_new_opponent","Opponent",placeholder="Optional"),
                  textInput("sessions_new_location","Location",placeholder="Optional"),
                  textInput("sessions_new_created_by","Created By",value="")
              ),
              textAreaInput("sessions_new_notes","Notes",placeholder="Optional session notes"),
              actionButton("sessions_create","CREATE SESSION")
          )
      )
    ),
    
    tabPanel(
      "Settings",
      div(class="admin-page",
          h2("Settings"),
          div(class="admin-grid-2",
              div(class="admin-card",
                  div(class="admin-title","Organization"),
                  textInput("setting_org_name","Organization Name",value="LaGrange College"),
                  textInput("setting_org_id","Organization ID",value="LAGRANGE"),
                  textInput("setting_default_user","Default Charting User",value="Nate Marko"),
                  div(class="admin-note","Organization ID is stored with new records. Existing historical records are not rewritten.")
              ),
              div(class="admin-card",
                  div(class="admin-title","Multi-User / Server Readiness"),
                  uiOutput("settings_multi_user_status"),
                  div(class="connection-card",uiOutput("settings_connection_status")),
                  div(class="admin-note","Each browser gets its own independent Shiny session. Pitch, PA, and Session records use append-based writes so multiple devices do not compete for the same next row.")
              )
          ),
          div(class="admin-card",
              div(class="admin-title","Bullpen Command Configuration"),
              div(class="admin-grid-2",
                  numericInput("setting_target_execution","Target Execution Radius (inches)",value=13,min=1,max=36,step=.5),
                  numericInput("setting_mlb_reference","MLB Avg Miss Reference (inches)",value=12,min=1,max=36,step=.5)
              ),
              div(class="admin-note","At the default 12-inch reference, 12 inches = a 70 Miss Distance Score."),
              hr(),
              div(class="admin-title","Bullpen Command Grade Weights"),
              div(class="settings-weight-grid",
                  numericInput("setting_weight_target","Target Execution",value=.50,min=0,max=1,step=.05),
                  numericInput("setting_weight_miss","Avg Miss Distance",value=.25,min=0,max=1,step=.05),
                  numericInput("setting_weight_zone","Zone %",value=.15,min=0,max=1,step=.05),
                  numericInput("setting_weight_strike","Strike %",value=.10,min=0,max=1,step=.05)
              ),
              uiOutput("settings_weight_check")
          ),
          div(class="admin-card",
              div(class="admin-title","Save Configuration"),
              div(class="admin-toolbar",actionButton("settings_save","SAVE SETTINGS"),actionButton("settings_reload","RELOAD SETTINGS")),
              uiOutput("settings_save_status")
          )
      )
    )
    
  )
)

# ==================================================
# V48 — CONNECT CLOUD BACKEND CACHE / QUOTA FIX
# ==================================================
# ==================================================
# SERVER
# ==================================================

server <- function(input, output, session) {
  
  balls <- reactiveVal(0)
  strikes <- reactiveVal(0)
  game_outs <- reactiveVal(0)
  
  selected_pitch_type <- reactiveVal("None")
  selected_zone <- reactiveVal(NULL)
  selected_location_x <- reactiveVal(NULL)
  selected_location_y <- reactiveVal(NULL)
  bullpen_target_x <- reactiveVal(NULL)
  bullpen_target_y <- reactiveVal(NULL)
  bullpen_target_zone <- reactiveVal(NULL)
  
  last_pitch_result <- reactiveVal("None")
  
  pa_complete <- reactiveVal(FALSE)
  pa_result <- reactiveVal(NULL)
  
  in_play_active <- reactiveVal(FALSE)
  
  selected_contact_quality <- reactiveVal(NULL)
  selected_in_play_result <- reactiveVal(NULL)
  
  save_status <- reactiveVal(NULL)
  
  pitch_number <- reactiveVal(1)
  pa_number <- reactiveVal(1)
  pa_pitch_count <- reactiveVal(0)
  pitches_after_2k <- reactiveVal(0)
  
  client_instance_id <- paste0(
    format(Sys.time(), "%Y%m%d%H%M%OS3"),
    "_",
    sprintf("%06d", sample.int(999999, 1))
  )
  client_instance_id <- gsub("[^0-9A-Za-z_]", "", client_instance_id)
  
  app_settings <- reactiveVal(list(
    Organization_Name="LaGrange College",
    Organization_ID="LAGRANGE",
    Default_Charting_User="Nate Marko",
    Bullpen_Target_Execution_In=13,
    Bullpen_MLB_Reference_In=12,
    Bullpen_Weight_Target=.50,
    Bullpen_Weight_Miss=.25,
    Bullpen_Weight_Zone=.15,
    Bullpen_Weight_Strike=.10
  ))
  settings_message <- reactiveVal(NULL)
  sessions_admin_sessions <- reactiveVal(data.frame())
  sessions_admin_pitches <- reactiveVal(data.frame())
  sessions_admin_pas <- reactiveVal(data.frame())
  
  session_lookup <- reactiveVal(
    data.frame()
  )
  
  player_lookup <- reactiveVal(
    data.frame()
  )
  
  report_pitches <- reactiveVal(data.frame())
  report_plate_appearances <- reactiveVal(data.frame())
  report_load_error <- reactiveVal(NULL)
  pitcher_report_pitches_raw <- reactiveVal(data.frame())
  pitcher_report_pa_raw <- reactiveVal(data.frame())
  pitcher_report_error <- reactiveVal(NULL)
  # ==================================================
  # SETTINGS / MULTI-USER HELPERS
  # ==================================================
  setting_chr <- function(key,default=""){
    s<-app_settings()
    if(is.null(s[[key]])||length(s[[key]])==0||is.na(s[[key]][1]))return(default)
    as.character(s[[key]][1])
  }
  setting_num <- function(key,default=NA_real_){
    x<-suppressWarnings(as.numeric(setting_chr(key,as.character(default))))
    if(!is.finite(x))default else x
  }
  current_org_id <- function(){
    x<-trimws(setting_chr("Organization_ID","LAGRANGE"))
    if(x=="")"LAGRANGE"else x
  }
  current_charting_user <- function(){
    x<-if(!is.null(input$charting_user))trimws(as.character(input$charting_user))else""
    if(x=="")x<-trimws(setting_chr("Default_Charting_User","Nate Marko"))
    x
  }
  unique_record_id <- function(prefix,session_id=""){
    stamp<-gsub("[^0-9]","",format(Sys.time(),"%Y%m%d%H%M%OS6"))
    rnd<-sprintf("%06d",sample.int(999999,1))
    if(!is.null(session_id)&&nzchar(session_id)){
      paste0(session_id,"_",prefix,"_",client_instance_id,"_",stamp,"_",rnd)
    }else{
      paste0(current_org_id(),"_",prefix,"_",client_instance_id,"_",stamp,"_",rnd)
    }
  }
  one_row_df <- function(values){
    out<-as.data.frame(as.list(values),stringsAsFactors=FALSE,check.names=FALSE)
    rownames(out)<-NULL
    out
  }
  append_row_atomic <- function(sheet_name,values){
    googlesheets4::sheet_append(ss=SHEET_URL,data=one_row_df(values),sheet=sheet_name)
    invisible(TRUE)
  }
  ensure_multi_user_pitch_columns <- function(){
    tryCatch({
      googlesheets4::range_write(
        ss=SHEET_URL,
        data=data.frame(Charted_By="Charted_By",Client_ID="Client_ID",stringsAsFactors=FALSE),
        sheet="Pitches",range="AM1:AN1",col_names=FALSE
      )
    },error=function(e){})
  }
  
  compact_pitches_sheet_if_needed <- function(){
    tryCatch({
      # Read as character so blank/preallocated cells cannot become list columns.
      raw<-suppressMessages(
        googlesheets4::range_read(
          ss=SHEET_URL,
          sheet="Pitches",
          range="A2:AN10000",
          col_names=FALSE,
          col_types="c"
        )
      )
      raw<-as.data.frame(raw,stringsAsFactors=FALSE)
      
      if(nrow(raw)==0 || ncol(raw)<7) return(invisible(FALSE))
      
      nonblank <- function(x){
        x<-as.character(x)
        !is.na(x) & trimws(x)!=""
      }
      
      # A = Pitch_ID, C = Session_ID, G = Pitcher_ID.
      # A real pitch should have at least one of these key identifiers.
      keep <- nonblank(raw[[1]]) | nonblank(raw[[3]]) | nonblank(raw[[7]])
      
      real_rows <- which(keep)
      if(length(real_rows)==0) return(invisible(FALSE))
      
      last_real_position <- max(real_rows)
      real_count <- length(real_rows)
      gap_count <- last_real_position - real_count
      
      # Only compact when there is a meaningful hole in the middle of the table.
      # In the user's current backend this detects the gap from ~row 98 to 5001.
      if(gap_count < 25) return(invisible(FALSE))
      
      compact <- raw[keep,,drop=FALSE]
      rownames(compact)<-NULL
      
      # Clear the old data area, including empty-string/formula rows that caused
      # sheet_append() to think the table extended to row 5001.
      googlesheets4::range_clear(
        ss=SHEET_URL,
        range="'Pitches'!A2:AN10000"
      )
      
      # Put every real pitch back contiguously starting at row 2.
      googlesheets4::range_write(
        ss=SHEET_URL,
        data=compact,
        sheet="Pitches",
        range="A2",
        col_names=FALSE
      )
      
      save_status(
        paste0(
          "Backend cleaned: ",
          real_count,
          " real pitches compacted with ",
          gap_count,
          " empty/preallocated rows removed."
        )
      )
      
      invisible(TRUE)
    },error=function(e){
      save_status(
        paste0(
          "Pitch-sheet cleanup warning: ",
          conditionMessage(e)
        )
      )
      invisible(FALSE)
    })
  }
  
  compact_plate_appearances_sheet_if_needed <- function(){
    tryCatch({
      raw<-suppressMessages(
        googlesheets4::range_read(
          ss=SHEET_URL,
          sheet="Plate_Appearances",
          range="A2:Z10000",
          col_names=FALSE,
          col_types="c"
        )
      )
      raw<-as.data.frame(raw,stringsAsFactors=FALSE)
      
      if(nrow(raw)==0 || ncol(raw)<6) return(invisible(FALSE))
      
      nonblank <- function(x){
        x<-as.character(x)
        !is.na(x) & trimws(x)!=""
      }
      
      # A = PA_ID, C = Session_ID, E = Batter_ID, F = Pitcher_ID.
      keep <- nonblank(raw[[1]]) | nonblank(raw[[3]]) |
        nonblank(raw[[5]]) | nonblank(raw[[6]])
      
      real_rows <- which(keep)
      if(length(real_rows)==0) return(invisible(FALSE))
      
      last_real_position <- max(real_rows)
      real_count <- length(real_rows)
      gap_count <- last_real_position - real_count
      
      # Only compact when there is a meaningful hole/preallocated block.
      if(gap_count < 25) return(invisible(FALSE))
      
      compact <- raw[keep,,drop=FALSE]
      rownames(compact)<-NULL
      
      googlesheets4::range_clear(
        ss=SHEET_URL,
        range="'Plate_Appearances'!A2:Z10000"
      )
      
      googlesheets4::range_write(
        ss=SHEET_URL,
        data=compact,
        sheet="Plate_Appearances",
        range="A2",
        col_names=FALSE
      )
      
      save_status(
        paste0(
          "Backend cleaned: ",
          real_count,
          " real plate appearances compacted with ",
          gap_count,
          " empty/preallocated rows removed."
        )
      )
      
      invisible(TRUE)
    },error=function(e){
      save_status(
        paste0(
          "Plate-appearance cleanup warning: ",
          conditionMessage(e)
        )
      )
      invisible(FALSE)
    })
  }
  
  ensure_settings_sheet <- function(){
    tryCatch({
      # First try to read the worksheet directly. This avoids relying on
      # sheet_names(), which can surface an unhelpful purrr "In index: 3"
      # error on some workbook metadata.
      settings_exists <- tryCatch({
        suppressMessages(
          googlesheets4::range_read(
            ss=SHEET_URL,
            sheet="Settings",
            range="A1:B2",
            col_names=FALSE,
            col_types="c"
          )
        )
        TRUE
      },error=function(e) FALSE)
      
      if(!settings_exists){
        defaults<-app_settings()
        
        default_values<-vapply(
          defaults,
          function(x){
            if(is.null(x)||length(x)==0||is.na(x[[1]]))"" else as.character(x[[1]])
          },
          character(1)
        )
        
        dat<-data.frame(
          Key=names(defaults),
          Value=unname(default_values),
          stringsAsFactors=FALSE
        )
        
        googlesheets4::sheet_add(
          ss=SHEET_URL,
          sheet="Settings",
          gridProperties=list(
            rowCount=100,
            columnCount=2,
            frozenRowCount=1
          )
        )
        
        googlesheets4::range_write(
          ss=SHEET_URL,
          data=dat,
          sheet="Settings",
          range="A1",
          col_names=TRUE
        )
      }
      
      TRUE
    },error=function(e){
      settings_message(
        paste0(
          "Settings setup error: ",
          conditionMessage(e)
        )
      )
      FALSE
    })
  }
  load_app_settings <- function(update_ui=TRUE){
    if(!ensure_settings_sheet())return(invisible(FALSE))
    tryCatch({
      d<-googlesheets4::range_read(ss=SHEET_URL,sheet="Settings",range="A1:B100",col_names=TRUE)
      d<-as.data.frame(d,stringsAsFactors=FALSE)
      vals<-app_settings()
      if(nrow(d)>0&&all(c("Key","Value")%in%names(d))){
        for(i in seq_len(nrow(d))){
          k<-trimws(as.character(d$Key[i]))
          if(k!=""&&k%in%names(vals))vals[[k]]<-as.character(d$Value[i])
        }
      }
      app_settings(vals)
      if(update_ui){
        updateTextInput(session,"setting_org_name",value=setting_chr("Organization_Name","LaGrange College"))
        updateTextInput(session,"setting_org_id",value=setting_chr("Organization_ID","LAGRANGE"))
        updateTextInput(session,"setting_default_user",value=setting_chr("Default_Charting_User","Nate Marko"))
        updateNumericInput(session,"setting_target_execution",value=setting_num("Bullpen_Target_Execution_In",13))
        updateNumericInput(session,"setting_mlb_reference",value=setting_num("Bullpen_MLB_Reference_In",12))
        updateNumericInput(session,"setting_weight_target",value=setting_num("Bullpen_Weight_Target",.50))
        updateNumericInput(session,"setting_weight_miss",value=setting_num("Bullpen_Weight_Miss",.25))
        updateNumericInput(session,"setting_weight_zone",value=setting_num("Bullpen_Weight_Zone",.15))
        updateNumericInput(session,"setting_weight_strike",value=setting_num("Bullpen_Weight_Strike",.10))
        updateTextInput(session,"charting_user",value=setting_chr("Default_Charting_User","Nate Marko"))
        updateTextInput(session,"sessions_new_created_by",value=setting_chr("Default_Charting_User","Nate Marko"))
      }
      settings_message("Settings loaded successfully.")
      TRUE
    },error=function(e){settings_message(paste0("Settings load error: ",e$message));FALSE})
  }
  save_app_settings <- function(){
    vals<-list(
      Organization_Name=trimws(as.character(input$setting_org_name)),
      Organization_ID=trimws(as.character(input$setting_org_id)),
      Default_Charting_User=trimws(as.character(input$setting_default_user)),
      Bullpen_Target_Execution_In=as.numeric(input$setting_target_execution),
      Bullpen_MLB_Reference_In=as.numeric(input$setting_mlb_reference),
      Bullpen_Weight_Target=as.numeric(input$setting_weight_target),
      Bullpen_Weight_Miss=as.numeric(input$setting_weight_miss),
      Bullpen_Weight_Zone=as.numeric(input$setting_weight_zone),
      Bullpen_Weight_Strike=as.numeric(input$setting_weight_strike)
    )
    w<-as.numeric(unlist(vals[c("Bullpen_Weight_Target","Bullpen_Weight_Miss","Bullpen_Weight_Zone","Bullpen_Weight_Strike")]))
    if(any(!is.finite(w))||sum(w)<=0)stop("Bullpen command weights must contain at least one positive value.")
    w<-w/sum(w)
    vals$Bullpen_Weight_Target<-w[1]; vals$Bullpen_Weight_Miss<-w[2]; vals$Bullpen_Weight_Zone<-w[3]; vals$Bullpen_Weight_Strike<-w[4]
    if(vals$Organization_ID=="")vals$Organization_ID<-"LAGRANGE"
    if(vals$Organization_Name=="")vals$Organization_Name<-"LaGrange College"
    ensure_settings_sheet()
    dat<-data.frame(Key=names(vals),Value=vapply(vals,as.character,character(1)),stringsAsFactors=FALSE)
    googlesheets4::range_write(ss=SHEET_URL,data=dat,sheet="Settings",range="A1",col_names=TRUE)
    app_settings(vals)
    settings_message("Settings saved successfully.")
    load_app_settings(update_ui=TRUE)
  }
  
  output$settings_weight_check<-renderUI({
    w<-suppressWarnings(as.numeric(c(input$setting_weight_target,input$setting_weight_miss,input$setting_weight_zone,input$setting_weight_strike)))
    if(any(!is.finite(w)))return(div(class="warning-text","Enter valid command-grade weights."))
    total<-sum(w)
    div(class=if(abs(total-1)<.0001)"success-text"else"warning-text",
        paste0("Current total: ",sprintf("%.2f",total),". Saving normalizes the weights to 1.00."))
  })
  output$settings_multi_user_status<-renderUI({
    div(class="multi-user-ready",HTML(paste0(
      "<strong>Multi-user write mode: READY</strong><br>",
      "This browser instance: <code>",client_instance_id,"</code><br>",
      "Pitch / PA / Session saves use append operations instead of selecting the next empty row."
    )))
  })
  output$settings_connection_status<-renderUI({
    path<-Sys.getenv("GS4_SERVICE_ACCOUNT_JSON",unset="")
    auth_mode<-if(nzchar(path)&&file.exists(path))"Service account (server-ready)"else"Local Google OAuth"
    HTML(paste0("<strong>Backend:</strong> Google Sheets<br><strong>Authentication:</strong> ",auth_mode,
                "<br><strong>Sheet:</strong> LaGrange Swing Decision Platform — Backend"))
  })
  output$settings_save_status<-renderUI({
    msg<-settings_message()
    if(is.null(msg)||msg=="")return(NULL)
    div(class=if(grepl("error",tolower(msg)))"warning-text"else"success-text",msg)
  })
  observeEvent(input$settings_save,{tryCatch(save_app_settings(),error=function(e)settings_message(paste0("Settings save error: ",e$message)))})
  observeEvent(input$settings_reload,{load_app_settings(update_ui=TRUE)})
  
  # ==================================================
  # PLAYER HELPERS
  # ==================================================
  
  current_batter_id <- function() {
    
    if (
      is.null(input$batter) ||
      input$batter == ""
    ) {
      return(NULL)
    }
    
    input$batter
    
  }
  
  current_batter_side <- function() {
    
    batter_id <- current_batter_id()
    
    if (is.null(batter_id)) {
      return("")
    }
    
    players_data <- player_lookup()
    
    if (
      nrow(players_data) == 0 ||
      !"Player_ID" %in% names(players_data) ||
      !"Bats" %in% names(players_data)
    ) {
      return("")
    }
    
    batter_row <- players_data[
      players_data$Player_ID == batter_id,
      ,
      drop = FALSE
    ]
    
    if (
      nrow(batter_row) == 0 ||
      is.na(batter_row$Bats[1])
    ) {
      return("")
    }
    
    as.character(batter_row$Bats[1])
    
  }
  
  current_pitcher_id <- function() {
    
    if (
      is.null(input$pitcher) ||
      input$pitcher == ""
    ) {
      return(NULL)
    }
    
    input$pitcher
    
  }
  
  current_session_id <- function() {
    
    if (
      is.null(input$session_select) ||
      input$session_select == ""
    ) {
      
      return(NULL)
      
    }
    
    input$session_select
    
  }
  
  current_pa_id <- function() {
    
    session_id <- current_session_id()
    
    if (is.null(session_id)) {
      return(NULL)
    }
    
    paste0(
      session_id,
      "_PA_",
      client_instance_id,
      "_",
      sprintf("%04d",pa_number())
    )
    
  }
  
  # ==================================================
  # ZONE / PITCH HELPERS
  # ==================================================
  
  zone_group <- function(zone) {
    
    if (zone >= 1 && zone <= 9) {
      return("Heart")
    }
    
    if (zone >= 11 && zone <= 19) {
      return("Shadow")
    }
    
    if (zone >= 21 && zone <= 29) {
      return("Chase")
    }
    
    if (zone >= 31 && zone <= 39) {
      return("Waste")
    }
    
    return("")
  }
  
  pitch_group <- function(pitch_type) {
    
    if (pitch_type %in% c("FB", "SI", "CT")) {
      return("Hard")
    }
    
    if (pitch_type %in% c("SL", "CB", "SW")) {
      return("Breaking")
    }
    
    if (pitch_type %in% c("CH", "SPLIT")) {
      return("Soft")
    }
    
    return("Other")
  }
  
  swing_take <- function(result) {
    
    if (
      result %in%
      c(
        "Whiff",
        "Foul",
        "In Play"
      )
    ) {
      
      return("Swing")
      
    }
    
    if (
      result %in%
      c(
        "Ball",
        "Called Strike"
      )
    ) {
      
      return("Take")
      
    }
    
    return("")
  }
  
  count_state <- function(strikes_before) {
    
    if (strikes_before == 2) {
      return("2K")
    }
    
    "Pre-2K"
  }
  
  # ==================================================
  # LOAD SESSIONS
  # ==================================================
  
  append_session_record <- function(session_date,session_name,session_type,opponent="",location="",created_by="",notes=""){
    session_name<-trimws(as.character(session_name))
    if(session_name=="")session_name<-paste0(as.character(session_type)," — ",format(as.Date(session_date),"%m/%d/%Y"))
    sid<-unique_record_id("SESSION")
    append_row_atomic("Sessions",list(
      sid,current_org_id(),format(as.Date(session_date),"%Y-%m-%d"),session_name,
      as.character(opponent),as.character(location),as.character(session_type),
      format(Sys.time(),"%H:%M:%S"),"",as.character(created_by),as.character(notes),"Active"
    ))
    sid
  }
  
  refresh_sessions_admin_data <- function(){
    tryCatch({
      s<-as.data.frame(googlesheets4::range_read(ss=SHEET_URL,sheet="Sessions",range="A1:L1001",col_names=TRUE),stringsAsFactors=FALSE)
      if(nrow(s)>0&&"Session_ID"%in%names(s))s<-s[!is.na(s$Session_ID)&trimws(as.character(s$Session_ID))!="",,drop=FALSE]
      sessions_admin_sessions(s)
      
      p<-as.data.frame(googlesheets4::range_read(ss=SHEET_URL,sheet="Pitches",range="A1:AN10001",col_names=TRUE),stringsAsFactors=FALSE)
      if(nrow(p)>0&&"Session_ID"%in%names(p))p<-p[!is.na(p$Session_ID)&trimws(as.character(p$Session_ID))!="",,drop=FALSE]
      sessions_admin_pitches(p)
      
      pa<-as.data.frame(googlesheets4::range_read(ss=SHEET_URL,sheet="Plate_Appearances",range="A1:Z10001",col_names=TRUE),stringsAsFactors=FALSE)
      if(nrow(pa)>0&&"Session_ID"%in%names(pa))pa<-pa[!is.na(pa$Session_ID)&trimws(as.character(pa$Session_ID))!="",,drop=FALSE]
      sessions_admin_pas(pa)
      
      choices<-if(nrow(s)>0){
        vals<-as.character(s$Session_ID)
        labs<-paste0(as.character(s$Session_Date)," — ",as.character(s$Session_Name)," [",
                     ifelse(is.na(s$Status)|trimws(as.character(s$Status))=="","Active",as.character(s$Status)),"]")
        names(vals)<-labs
        c("Select Session"="",vals)
      }else c("Select Session"="")
      cur<-isolate(input$sessions_manage_id)
      if(is.null(cur)||!cur%in%unname(choices))cur<-""
      updateSelectInput(session,"sessions_manage_id",choices=choices,selected=cur)
      
      types<-if(nrow(s)>0&&"Session_Type"%in%names(s))sort(unique(trimws(as.character(s$Session_Type))))else character(0)
      types<-types[!is.na(types)&types!=""]
      tc<-c("All Types"="ALL")
      if(length(types)>0){tmp<-types;names(tmp)<-types;tc<-c(tc,tmp)}
      curt<-isolate(input$sessions_type_filter)
      if(is.null(curt)||!curt%in%unname(tc))curt<-"ALL"
      updateSelectInput(session,"sessions_type_filter",choices=tc,selected=curt)
      TRUE
    },error=function(e){save_status(paste0("Sessions refresh error: ",e$message));FALSE})
  }
  
  sessions_filtered <- reactive({
    d<-sessions_admin_sessions()
    if(is.null(d)||nrow(d)==0)return(data.frame())
    if("Session_Date"%in%names(d)){
      dt<-as.Date(as.character(d$Session_Date)); rg<-input$sessions_date_filter
      if(!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2]))d<-d[!is.na(dt)&dt>=as.Date(rg[1])&dt<=as.Date(rg[2]),,drop=FALSE]
    }
    sf<-input$sessions_status_filter
    if(!is.null(sf)&&sf!=""&&sf!="ALL"&&"Status"%in%names(d))d<-d[as.character(d$Status)==sf,,drop=FALSE]
    tf<-input$sessions_type_filter
    if(!is.null(tf)&&tf!=""&&tf!="ALL"&&"Session_Type"%in%names(d))d<-d[as.character(d$Session_Type)==tf,,drop=FALSE]
    if("Session_Date"%in%names(d))d<-d[order(as.Date(as.character(d$Session_Date)),decreasing=TRUE,na.last=TRUE),,drop=FALSE]
    d
  })
  
  update_session_status <- function(session_id,new_status){
    if(is.null(session_id)||session_id=="")stop("Select a session first.")
    d<-as.data.frame(googlesheets4::range_read(ss=SHEET_URL,sheet="Sessions",range="A1:L1001",col_names=TRUE),stringsAsFactors=FALSE)
    idx<-which(as.character(d$Session_ID)==as.character(session_id))
    if(length(idx)==0)stop("Session ID was not found.")
    i<-idx[1]; row<-i+1
    googlesheets4::range_write(
      ss=SHEET_URL,
      data=data.frame(
        End_Time=if(new_status=="Completed")format(Sys.time(),"%H:%M:%S")else"",
        Created_By=if("Created_By"%in%names(d))as.character(d$Created_By[i])else"",
        Notes=if("Notes"%in%names(d))as.character(d$Notes[i])else"",
        Status=new_status,stringsAsFactors=FALSE
      ),
      sheet="Sessions",range=paste0("I",row,":L",row),col_names=FALSE
    )
  }
  
  load_sessions <- function(
    select_session_id = NULL
  ) {
    
    tryCatch(
      
      {
        
        # V48: render from the in-memory backend snapshot.
        sessions_data <- sessions_admin_sessions()
        
        if (
          is.null(sessions_data) ||
          nrow(sessions_data) == 0 ||
          !"Session_ID" %in% names(sessions_data)
        ) {
          
          session_lookup(data.frame())
          
          updateSelectInput(
            session,
            "session_select",
            choices = c("No Sessions Yet" = ""),
            selected = ""
          )
          
          return()
        }
        
        sessions_data <- sessions_data[
          !is.na(sessions_data$Session_ID) &
            trimws(as.character(sessions_data$Session_ID)) != "",
          ,
          drop = FALSE
        ]
        
        session_lookup(sessions_data)
        
        if (nrow(sessions_data) == 0) {
          updateSelectInput(
            session,
            "session_select",
            choices = c("No Sessions Yet" = ""),
            selected = ""
          )
          return()
        }
        
        session_labels <- paste0(
          sessions_data$Session_Date,
          " — ",
          sessions_data$Session_Name,
          ifelse(
            is.na(sessions_data$Status) |
              trimws(as.character(sessions_data$Status)) == "",
            "",
            paste0(" [", sessions_data$Status, "]")
          )
        )
        
        choices <- as.character(sessions_data$Session_ID)
        names(choices) <- session_labels
        
        if (
          !is.null(select_session_id) &&
          select_session_id %in% as.character(sessions_data$Session_ID)
        ) {
          selected_id <- select_session_id
        } else {
          selected_id <- tail(as.character(sessions_data$Session_ID), 1)
        }
        
        updateSelectInput(
          session,
          "session_select",
          choices = choices,
          selected = selected_id
        )
        
      },
      
      error = function(e) {
        save_status(paste0("Session load error: ", e$message))
      }
      
    )
    
  }
  
  # ==================================================
  # SESSION DISPLAY
  # ==================================================
  
  output$selected_session_text <- renderText({
    
    session_id <- current_session_id()
    
    if (is.null(session_id)) {
      return("No Session Selected")
    }
    
    session_data <- session_lookup()
    
    if (
      nrow(session_data) == 0
    ) {
      
      return(session_id)
      
    }
    
    row <- session_data[
      session_data$Session_ID ==
        session_id,
    ]
    
    if (nrow(row) == 0) {
      return(session_id)
    }
    
    paste0(
      row$Session_Name[1],
      " — ",
      row$Session_Date[1]
    )
    
  })
  
  # ==================================================
  # CREATE SESSION
  # ==================================================
  
  observeEvent(
    input$create_session,
    {
      
      req(
        input$new_session_date
      )
      
      session_name <-
        trimws(
          input$new_session_name
        )
      
      if (session_name == "") {
        
        session_name <- paste0(
          "Live AB — ",
          format(
            input$new_session_date,
            "%m/%d/%Y"
          )
        )
        
      }
      
      new_session_id <- unique_record_id("SESSION")
      
      session_data <- data.frame(
        
        Session_ID =
          new_session_id,
        
        Organization_ID =
          current_org_id(),
        
        Session_Date =
          format(
            input$new_session_date,
            "%Y-%m-%d"
          ),
        
        Session_Name =
          session_name,
        
        Opponent =
          input$new_session_opponent,
        
        Location =
          input$new_session_location,
        
        Session_Type =
          input$new_session_type,
        
        Start_Time =
          format(
            Sys.time(),
            "%H:%M:%S"
          ),
        
        End_Time =
          "",
        
        Created_By =
          input$new_session_created_by,
        
        Notes =
          input$new_session_notes,
        
        Status =
          "Active",
        
        stringsAsFactors = FALSE
        
      )
      
      tryCatch(
        
        {
          
          append_row_atomic("Sessions",unname(as.list(session_data[1,])))
          
          save_status(
            paste0(
              "Created Session: ",
              session_name
            )
          )
          
          refresh_sessions_admin_data()
          
          load_sessions(
            select_session_id =
              new_session_id
          )
          
          updateCheckboxInput(
            session,
            "show_create_session",
            value = FALSE
          )
          
        },
        
        error = function(e) {
          
          save_status(
            paste0(
              "Session create error: ",
              e$message
            )
          )
          
        }
        
      )
      
    }
  )
  
  # ==================================================
  # REFRESH SESSIONS
  # ==================================================
  
  observeEvent(
    input$refresh_sessions,
    {
      
      load_sessions(
        select_session_id =
          current_session_id()
      )
      
    }
  )
  
  # ==================================================
  # SESSIONS PAGE
  # ==================================================
  output$sessions_kpi_sessions<-renderText(nrow(sessions_filtered()))
  output$sessions_kpi_pitches<-renderText({
    s<-sessions_filtered();p<-sessions_admin_pitches()
    if(nrow(s)==0||nrow(p)==0||!"Session_ID"%in%names(p))return("0")
    sum(as.character(p$Session_ID)%in%as.character(s$Session_ID),na.rm=TRUE)
  })
  output$sessions_kpi_pas<-renderText({
    s<-sessions_filtered();p<-sessions_admin_pas()
    if(nrow(s)==0||nrow(p)==0||!"Session_ID"%in%names(p))return("0")
    sum(as.character(p$Session_ID)%in%as.character(s$Session_ID),na.rm=TRUE)
  })
  output$sessions_kpi_active<-renderText({
    s<-sessions_admin_sessions()
    if(nrow(s)==0||!"Status"%in%names(s))return("0")
    sum(as.character(s$Status)=="Active",na.rm=TRUE)
  })
  output$sessions_table<-renderUI({
    d<-sessions_filtered()
    if(nrow(d)==0)return(div(class="admin-note","No sessions match the current filters."))
    p<-sessions_admin_pitches();pa<-sessions_admin_pas()
    cnt<-function(dat,sid)if(is.null(dat)||nrow(dat)==0||!"Session_ID"%in%names(dat))0L else sum(as.character(dat$Session_ID)==sid,na.rm=TRUE)
    rows<-lapply(seq_len(min(nrow(d),100)),function(i){
      sid<-as.character(d$Session_ID[i]); status<-if("Status"%in%names(d))as.character(d$Status[i])else"Active"
      tags$tr(
        tags$td(as.character(d$Session_Date[i])),
        tags$td(as.character(d$Session_Name[i])),
        tags$td(if("Session_Type"%in%names(d))as.character(d$Session_Type[i])else""),
        tags$td(tags$span(class=paste("admin-status-pill",if(status=="Active")"admin-status-active"else"admin-status-complete"),ifelse(status=="","Active",status))),
        tags$td(cnt(p,sid)),tags$td(cnt(pa,sid))
      )
    })
    tags$table(class="table table-striped table-condensed",
               tags$thead(tags$tr(tags$th("Date"),tags$th("Session"),tags$th("Type"),tags$th("Status"),tags$th("Pitches"),tags$th("PA"))),
               tags$tbody(rows))
  })
  output$sessions_selected_detail<-renderUI({
    sid<-input$sessions_manage_id;d<-sessions_admin_sessions()
    if(is.null(sid)||sid==""||nrow(d)==0)return(div(class="admin-note","Select a session to manage it."))
    z<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
    if(nrow(z)==0)return(div(class="warning-text","Selected session was not found."))
    p<-sessions_admin_pitches();pa<-sessions_admin_pas()
    pc<-if(nrow(p)>0&&"Session_ID"%in%names(p))sum(as.character(p$Session_ID)==sid,na.rm=TRUE)else 0
    pac<-if(nrow(pa)>0&&"Session_ID"%in%names(pa))sum(as.character(pa$Session_ID)==sid,na.rm=TRUE)else 0
    tagList(
      h4(as.character(z$Session_Name[1])),
      tags$p(tags$strong("Date: "),as.character(z$Session_Date[1])),
      tags$p(tags$strong("Type: "),if("Session_Type"%in%names(z))as.character(z$Session_Type[1])else""),
      tags$p(tags$strong("Status: "),if("Status"%in%names(z))as.character(z$Status[1])else"Active"),
      tags$p(tags$strong("Pitches: "),pc,"   |   ",tags$strong("PA: "),pac),
      if("Opponent"%in%names(z)&&!is.na(z$Opponent[1])&&trimws(as.character(z$Opponent[1]))!="")tags$p(tags$strong("Opponent: "),as.character(z$Opponent[1]))else NULL,
      if("Location"%in%names(z)&&!is.na(z$Location[1])&&trimws(as.character(z$Location[1]))!="")tags$p(tags$strong("Location: "),as.character(z$Location[1]))else NULL,
      if("Notes"%in%names(z)&&!is.na(z$Notes[1])&&trimws(as.character(z$Notes[1]))!="")tags$p(tags$strong("Notes: "),as.character(z$Notes[1]))else NULL
    )
  })
  observeEvent(input$sessions_refresh,{refresh_sessions_admin_data();load_sessions(select_session_id=current_session_id())})
  observeEvent(input$sessions_create,{
    tryCatch({
      who<-trimws(as.character(input$sessions_new_created_by));if(who=="")who<-setting_chr("Default_Charting_User","Nate Marko")
      sid<-append_session_record(input$sessions_new_date,input$sessions_new_name,input$sessions_new_type,
                                 input$sessions_new_opponent,input$sessions_new_location,who,input$sessions_new_notes)
      refresh_sessions_admin_data();load_sessions(select_session_id=sid);updateSelectInput(session,"sessions_manage_id",selected=sid)
      save_status(paste0("Created session: ",input$sessions_new_name))
    },error=function(e)save_status(paste0("Session create error: ",e$message)))
  })
  observeEvent(input$sessions_mark_active,{
    tryCatch({update_session_status(input$sessions_manage_id,"Active");refresh_sessions_admin_data();load_sessions(select_session_id=current_session_id())},
             error=function(e)save_status(paste0("Session update error: ",e$message)))
  })
  observeEvent(input$sessions_mark_complete,{
    tryCatch({update_session_status(input$sessions_manage_id,"Completed");refresh_sessions_admin_data();load_sessions(select_session_id=current_session_id())},
             error=function(e)save_status(paste0("Session update error: ",e$message)))
  })
  observeEvent(input$sessions_open_live,{
    sid<-input$sessions_manage_id
    if(is.null(sid)||sid=="")return()
    updateSelectInput(session,"session_select",selected=sid)
    session$sendCustomMessage("switch-tab-from-r","Live Charting")
  })
  
  # ==================================================
  # SYNC COUNTERS WHEN SESSION CHANGES
  # ==================================================
  
  sync_session_counters <- function(
    session_id
  ) {
    
    if (
      is.null(session_id) ||
      session_id == ""
    ) {
      
      pitch_number(1)
      pa_number(1)
      
      return()
    }
    
    # --------------------------
    # PITCH NUMBER
    # --------------------------
    
    tryCatch(
      
      {
        
        pitch_data <- gs_read_pitch_counters(
          sheet_url = SHEET_URL
        )
        
        if (
          nrow(pitch_data) > 0 &&
          all(
            c(
              "Session_ID",
              "Pitch_Number"
            ) %in%
            names(pitch_data)
          )
        ) {
          
          session_pitches <-
            pitch_data[
              !is.na(
                pitch_data$Session_ID
              ) &
                pitch_data$Session_ID ==
                session_id,
            ]
          
          if (
            nrow(session_pitches) > 0
          ) {
            
            nums <-
              suppressWarnings(
                as.numeric(
                  session_pitches$Pitch_Number
                )
              )
            
            nums <- nums[
              !is.na(nums)
            ]
            
            if (length(nums) > 0) {
              
              pitch_number(
                max(nums) + 1
              )
              
            } else {
              
              pitch_number(1)
              
            }
            
          } else {
            
            pitch_number(1)
            
          }
          
        }
        
      },
      
      error = function(e) {
        
        pitch_number(1)
        
      }
      
    )
    
    # --------------------------
    # PA NUMBER
    # --------------------------
    
    tryCatch(
      
      {
        
        pa_data <- gs_read_pa_counters(
          sheet_url = SHEET_URL
        )
        
        if (
          nrow(pa_data) > 0 &&
          all(
            c(
              "Session_ID",
              "PA_Number"
            ) %in%
            names(pa_data)
          )
        ) {
          
          session_pas <-
            pa_data[
              !is.na(
                pa_data$Session_ID
              ) &
                pa_data$Session_ID ==
                session_id,
            ]
          
          if (
            nrow(session_pas) > 0
          ) {
            
            nums <-
              suppressWarnings(
                as.numeric(
                  session_pas$PA_Number
                )
              )
            
            nums <- nums[
              !is.na(nums)
            ]
            
            if (length(nums) > 0) {
              
              pa_number(
                max(nums) + 1
              )
              
            } else {
              
              pa_number(1)
              
            }
            
          } else {
            
            pa_number(1)
            
          }
          
        }
        
      },
      
      error = function(e) {
        
        pa_number(1)
        
      }
      
    )
    
  }
  
  observeEvent(
    input$session_select,
    {
      
      if (
        is.null(
          input$session_select
        ) ||
        input$session_select == ""
      ) {
        
        return()
      }
      
      sync_session_counters(
        input$session_select
      )
      
      balls(0)
      strikes(0)
      
      pa_complete(FALSE)
      pa_result(NULL)
      
      selected_pitch_type("None")
      selected_zone(NULL)
      selected_location_x(NULL)
      selected_location_y(NULL)
      
      last_pitch_result("None")
      
      in_play_active(FALSE)
      
      selected_contact_quality(NULL)
      selected_in_play_result(NULL)
      
    },
    
    ignoreInit = TRUE
  )
  
  # ==================================================
  # INITIAL APP LOAD
  # ==================================================
  
  observeEvent(
    TRUE,
    {
      
      load_sessions()
      
      tryCatch(
        
        {
          
          players_data <- gs_read_players(
            sheet_url = SHEET_URL
          )
          
          player_lookup(
            players_data
          )
          
          if (
            nrow(players_data) == 0
          ) {
            
            updateSelectInput(
              session,
              "batter",
              choices = c(
                "No Active Hitters" = ""
              )
            )
            
            updateSelectInput(
              session,
              "pitcher",
              choices = c(
                "No Active Pitchers" = ""
              )
            )
            
          } else {
            
            # ------------------------------------------
            # ACTIVE PLAYERS
            # ------------------------------------------
            
            active_flag <- tolower(
              as.character(
                players_data$Active
              )
            ) %in% c(
              "true",
              "1",
              "yes"
            )
            
            active_players <- players_data[
              active_flag,
              ,
              drop = FALSE
            ]
            
            # ------------------------------------------
            # BATTERS
            # ------------------------------------------
            
            batters <- active_players[
              active_players$Player_Type %in%
                c(
                  "Hitter",
                  "Two-Way"
                ),
              ,
              drop = FALSE
            ]
            
            if (nrow(batters) > 0) {
              
              batter_order <- order(
                batters$Last_Name,
                batters$First_Name
              )
              
              batters <- batters[
                batter_order,
                ,
                drop = FALSE
              ]
              
              batter_choices <- as.character(
                batters$Player_ID
              )
              
              names(batter_choices) <- paste0(
                batters$Display_Name,
                ifelse(
                  is.na(
                    batters$Primary_Position
                  ) |
                    batters$Primary_Position == "",
                  "",
                  paste0(
                    " — ",
                    batters$Primary_Position
                  )
                )
              )
              
              updateSelectInput(
                session,
                "batter",
                choices = batter_choices,
                selected = batter_choices[1]
              )
              
              updateSelectInput(
                session,
                "report_batter",
                choices = batter_choices,
                selected = batter_choices[1]
              )
              
            } else {
              
              updateSelectInput(
                session,
                "batter",
                choices = c(
                  "No Active Hitters" = ""
                )
              )
              
            }
            
            # ------------------------------------------
            # PITCHERS
            # ------------------------------------------
            
            pitchers <- active_players[
              active_players$Player_Type %in%
                c(
                  "Pitcher",
                  "Two-Way"
                ),
              ,
              drop = FALSE
            ]
            
            if (nrow(pitchers) > 0) {
              
              pitcher_order <- order(
                pitchers$Last_Name,
                pitchers$First_Name
              )
              
              pitchers <- pitchers[
                pitcher_order,
                ,
                drop = FALSE
              ]
              
              pitcher_choices <- as.character(
                pitchers$Player_ID
              )
              
              names(pitcher_choices) <- paste0(
                pitchers$Display_Name,
                ifelse(
                  is.na(
                    pitchers$Primary_Position
                  ) |
                    pitchers$Primary_Position == "",
                  "",
                  paste0(
                    " — ",
                    pitchers$Primary_Position
                  )
                )
              )
              
              updateSelectInput(
                session,
                "pitcher",
                choices = pitcher_choices,
                selected = pitcher_choices[1]
              )
              updateSelectInput(
                session,
                "pitcher_report_pitcher",
                choices = pitcher_choices,
                selected = pitcher_choices[1]
              )
              
            } else {
              
              updateSelectInput(
                session,
                "pitcher",
                choices = c(
                  "No Active Pitchers" = ""
                )
              )
              
            }
            
          }
          
        },
        
        error = function(e) {
          
          save_status(
            paste0(
              "Roster load error: ",
              e$message
            )
          )
          
        }
        
      )
      
    },
    
    once = TRUE
  )
  
  # ==================================================
  # GAME STATE / INNING TRACKING
  # ==================================================
  
  output$game_outs_display <- renderText({
    paste0(game_outs(), " / 3")
  })
  
  advance_half_inning <- function() {
    current_half <- input$inning_half
    current_inning <- suppressWarnings(as.integer(input$inning_number))
    if (!is.finite(current_inning) || current_inning < 1) current_inning <- 1L
    
    game_outs(0)
    
    if (is.null(current_half) || current_half == "Top") {
      updateRadioButtons(session, "inning_half", selected = "Bottom")
    } else {
      updateRadioButtons(session, "inning_half", selected = "Top")
      updateNumericInput(session, "inning_number", value = current_inning + 1L)
    }
  }
  
  add_recorded_outs <- function(n_outs = 1L) {
    n_outs <- suppressWarnings(as.integer(n_outs))
    if (!is.finite(n_outs) || n_outs <= 0) return(invisible(NULL))
    new_outs <- game_outs() + n_outs
    if (new_outs >= 3L) {
      advance_half_inning()
    } else {
      game_outs(new_outs)
    }
    invisible(NULL)
  }
  
  outs_for_pa_result <- function(result) {
    result <- as.character(result)
    if (result %in% c(
      "Strikeout Swinging",
      "Strikeout Looking",
      "Out",
      "Fielder's Choice",
      "Sac Fly",
      "Sac Bunt"
    )) return(1L)
    0L
  }
  
  observeEvent(input$outs_plus, {
    add_recorded_outs(1L)
  })
  
  observeEvent(input$outs_minus, {
    game_outs(max(0L, game_outs() - 1L))
  })
  
  # ==================================================
  # BULLPEN HELPERS
  # ==================================================
  bullpen_miss_inches <- function(actual_x,actual_y,target_x,target_y) {
    ax<-suppressWarnings(as.numeric(actual_x)); ay<-suppressWarnings(as.numeric(actual_y))
    tx<-suppressWarnings(as.numeric(target_x)); ty<-suppressWarnings(as.numeric(target_y))
    if(any(!is.finite(c(ax,ay,tx,ty))))return(NA_real_)
    # Strike-zone drawing uses approximately 0.223 of normalized width for 17 inches
    # and 0.260 of normalized height for a standardized ~24-inch zone height.
    dx_inches <- (ax-tx) * (17/0.2231)
    dy_inches <- (ay-ty) * (24/0.2596)
    sqrt(dx_inches^2+dy_inches^2)
  }
  bullpen_target_hit <- function(actual_x,actual_y,target_x,target_y,tolerance_inches=NULL) {
    if(is.null(tolerance_inches)||!is.finite(suppressWarnings(as.numeric(tolerance_inches))))tolerance_inches<-setting_num("Bullpen_Target_Execution_In",13)
    d<-bullpen_miss_inches(actual_x,actual_y,target_x,target_y)
    is.finite(d) && d<=as.numeric(tolerance_inches)
  }
  
  # Converts average miss distance into a 0-100 command score.
  # 12 inches is treated as an MLB-average reference point (~70 score).
  bullpen_miss_distance_score <- function(avg_miss_inches) {
    x<-suppressWarnings(as.numeric(avg_miss_inches))
    if(!is.finite(x))return(NA_real_)
    ref<-setting_num("Bullpen_MLB_Reference_In",12)
    knots<-pmax(0,ref+c(-12,-6,-4,-2,0,2,4,6,8,10,12,14))
    scores<-c(100,100,90,80,70,60,50,40,30,20,10,0)
    keep<-!duplicated(knots,fromLast=TRUE)
    knots<-knots[keep]; scores<-scores[keep]
    approx(x=knots,y=scores,xout=min(max(x,min(knots)),max(knots)),rule=2)$y
  }
  
  bullpen_command_grade_value <- function(target_pct,avg_miss,zone_pct,strike_pct) {
    miss_score<-bullpen_miss_distance_score(avg_miss)
    if(!all(is.finite(c(target_pct,miss_score,zone_pct,strike_pct))))return(NA_real_)
    w<-c(setting_num("Bullpen_Weight_Target",.50),setting_num("Bullpen_Weight_Miss",.25),
         setting_num("Bullpen_Weight_Zone",.15),setting_num("Bullpen_Weight_Strike",.10))
    if(any(!is.finite(w))||sum(w)<=0)w<-c(.50,.25,.15,.10)
    w<-w/sum(w)
    sum(w*c(100*target_pct,miss_score,100*zone_pct,100*strike_pct))
  }
  
  bullpen_xy_inches <- function(actual_x,actual_y,target_x,target_y) {
    ax<-suppressWarnings(as.numeric(actual_x))
    ay<-suppressWarnings(as.numeric(actual_y))
    tx<-suppressWarnings(as.numeric(target_x))
    ty<-suppressWarnings(as.numeric(target_y))
    if(any(!is.finite(c(ax,ay,tx,ty)))) {
      return(c(dx=NA_real_,dy=NA_real_,distance=NA_real_))
    }
    dx <- (ax-tx) * (17/0.2231)
    # Screen coordinates increase downward, so positive dy below means "Down".
    dy <- (ay-ty) * (24/0.2596)
    c(dx=dx,dy=dy,distance=sqrt(dx^2+dy^2))
  }
  
  bullpen_throw_hand <- function() {
    r <- pitcher_player_row()
    if(is.null(r) || nrow(r)==0 || !"Throws"%in%names(r)) return("R")
    h <- toupper(trimws(as.character(r$Throws[1])))
    if(!h %in% c("R","L")) "R" else h
  }
  
  bullpen_relative_frame <- function(d) {
    if(is.null(d) || nrow(d)==0) return(data.frame())
    req<-c("Location_X","Location_Y","Bullpen_Target_X","Bullpen_Target_Y")
    if(!all(req%in%names(d))) return(data.frame())
    
    hand<-bullpen_throw_hand()
    out<-vector("list",nrow(d))
    
    for(i in seq_len(nrow(d))){
      q<-bullpen_xy_inches(
        d$Location_X[i],d$Location_Y[i],
        d$Bullpen_Target_X[i],d$Bullpen_Target_Y[i]
      )
      dx<-unname(q["dx"])
      dy<-unname(q["dy"])
      dist<-unname(q["distance"])
      
      # Convert catcher-view horizontal miss to pitcher-relative command:
      # positive = arm side, negative = glove side.
      arm_x <- if(hand=="R") -dx else dx
      up_y <- -dy
      
      out[[i]]<-data.frame(
        ArmSide_In=arm_x,
        Up_In=up_y,
        Catcher_DX_In=dx,
        Screen_DY_In=dy,
        Miss_In=dist,
        Pitch_Type=if("Pitch_Type"%in%names(d))as.character(d$Pitch_Type[i])else"",
        Pitch_Result=if("Pitch_Result"%in%names(d))as.character(d$Pitch_Result[i])else"",
        Session_ID=if("Session_ID"%in%names(d))as.character(d$Session_ID[i])else"",
        stringsAsFactors=FALSE
      )
    }
    
    z<-do.call(rbind,out)
    z[is.finite(z$ArmSide_In)&is.finite(z$Up_In)&is.finite(z$Miss_In),,drop=FALSE]
  }
  
  bullpen_miss_direction <- function(arm_x,up_y,miss_inches) {
    if(!all(is.finite(c(arm_x,up_y,miss_inches)))) return(NA_character_)
    if(miss_inches<=setting_num("Bullpen_Target_Execution_In",13)) return("Executed")
    
    ax<-abs(arm_x)
    ay<-abs(up_y)
    
    horiz<-if(arm_x>=0)"Arm Side"else"Glove Side"
    vert<-if(up_y>=0)"Up"else"Down"
    
    if(ax < 0.5*ay) return(vert)
    if(ay < 0.5*ax) return(horiz)
    paste(vert,horiz,sep=" / ")
  }
  
  bullpen_session_label_map <- reactive({
    s<-session_lookup()
    if(is.null(s)||nrow(s)==0||!"Session_ID"%in%names(s)){
      return(setNames(character(0),character(0)))
    }
    ids<-as.character(s$Session_ID)
    date<-if("Session_Date"%in%names(s))as.character(s$Session_Date)else rep("",nrow(s))
    nm<-if("Session_Name"%in%names(s))as.character(s$Session_Name)else rep("",nrow(s))
    lab<-ifelse(
      !is.na(nm)&trimws(nm)!="",
      paste0(date," — ",nm),
      date
    )
    lab[is.na(lab)|trimws(lab)==""]<-ids[is.na(lab)|trimws(lab)==""]
    setNames(lab,ids)
  })
  
  bullpen_session_summary <- function(d) {
    if(is.null(d)||nrow(d)==0)return(NULL)
    
    strike<-as.character(d$Pitch_Result)%in%c("Called Strike","Strike")
    zone<-if("Zone_Group"%in%names(d)){
      as.character(d$Zone_Group)%in%c("Heart","Shadow")
    } else rep(FALSE,nrow(d))
    
    rel<-bullpen_relative_frame(d)
    if(nrow(rel)==0)return(NULL)
    
    target_pct<-mean(rel$Miss_In<=setting_num("Bullpen_Target_Execution_In",13),na.rm=TRUE)
    avg_miss<-mean(rel$Miss_In,na.rm=TRUE)
    strike_pct<-mean(strike,na.rm=TRUE)
    zone_pct<-mean(zone,na.rm=TRUE)
    
    list(
      pitches=nrow(d),
      command_grade=bullpen_command_grade_value(target_pct,avg_miss,zone_pct,strike_pct),
      strike=strike_pct,
      zone=zone_pct,
      target_hit=target_pct,
      avg_miss=avg_miss,
      miss_score=bullpen_miss_distance_score(avg_miss)
    )
  }
  
  bullpen_pitchtype_filter_frame <- function(d) {
    if(is.null(d)||nrow(d)==0)return(data.frame())
    pt<-input$pitcher_bullpen_plot_pitch_type
    if(!is.null(pt)&&pt!=""&&pt!="ALL"&&"Pitch_Type"%in%names(d)){
      d<-d[as.character(d$Pitch_Type)==pt,,drop=FALSE]
    }
    d
  }
  
  bullpen_history_data <- reactive({
    d<-bullpen_valid_rows(pitcher_report_pitches_raw())
    id<-input$pitcher_report_pitcher
    if(nrow(d)==0||is.null(id)||id==""||!"Pitcher_ID"%in%names(d))return(data.frame())
    
    d<-d[as.character(d$Pitcher_ID)==as.character(id),,drop=FALSE]
    if(nrow(d)==0)return(data.frame())
    
    sd<-p_session_dates()
    if(nrow(sd)>0&&"Session_ID"%in%names(d)){
      d$Session_ID<-as.character(d$Session_ID)
      d<-merge(d,sd,by="Session_ID",all.x=TRUE,sort=FALSE)
      rg<-input$pitcher_report_date_range
      if(!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2])){
        d<-d[
          is.na(d$Session_Date_Report) |
            (d$Session_Date_Report>=as.Date(rg[1])&d$Session_Date_Report<=as.Date(rg[2])),
          ,
          drop=FALSE
        ]
      }
    }
    d
  })
  
  bullpen_session_history <- reactive({
    d<-bullpen_history_data()
    if(nrow(d)==0||!"Session_ID"%in%names(d))return(data.frame())
    
    sids<-unique(trimws(as.character(d$Session_ID)))
    sids<-sids[!is.na(sids)&sids!=""]
    if(length(sids)==0)return(data.frame())
    
    mp<-lb_session_date_map()
    labels<-bullpen_session_label_map()
    
    rows<-lapply(sids,function(sid){
      z<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
      sm<-bullpen_session_summary(z)
      if(is.null(sm))return(NULL)
      
      data.frame(
        Session_ID=sid,
        Label=if(sid%in%names(labels))unname(labels[sid])else sid,
        Date=as.Date(unname(mp[sid])),
        Pitches=sm$pitches,
        Command=sm$command_grade,
        Target=sm$target_hit,
        AvgMiss=sm$avg_miss,
        Strike=sm$strike,
        Zone=sm$zone,
        stringsAsFactors=FALSE
      )
    })
    
    rows<-Filter(Negate(is.null),rows)
    if(length(rows)==0)return(data.frame())
    
    df<-do.call(rbind,rows)
    df<-df[order(df$Date,df$Session_ID),,drop=FALSE]
    rownames(df)<-NULL
    df
  })
  
  bullpen_plot_empty <- function(message="No bullpen data available.") {
    plot.new()
    text(.5,.5,message,cex=.95,col="#666666")
    box()
  }
  
  bullpen_plot_axes <- function(main="",xlab="",ylab="") {
    title(main=main,xlab=xlab,ylab=ylab,cex.main=.95,cex.lab=.8)
    box(col="#bbbbbb")
    grid(col="#eeeeee")
  }
  
  
  # ==================================================
  # PITCHER REPORT
  # ==================================================
  # Manual charting only. No velocity, movement, spin or TrackMan required.
  
  ensure_inning_column <- function() {
    tryCatch({
      googlesheets4::range_write(
        ss=SHEET_URL,
        data=data.frame(Inning="Inning",Half_Inning="Half_Inning",Outs_Before="Outs_Before",stringsAsFactors=FALSE),
        sheet="Pitches",
        range="AD1:AF1",
        col_names=FALSE
      )
    },error=function(e){})
  }
  
  ensure_bullpen_columns <- function() {
    tryCatch({
      googlesheets4::range_write(
        ss=SHEET_URL,
        data=data.frame(
          Charting_Mode="Charting_Mode",
          Bullpen_Target_X="Bullpen_Target_X",
          Bullpen_Target_Y="Bullpen_Target_Y",
          Bullpen_Target_Zone="Bullpen_Target_Zone",
          Bullpen_Focus="Bullpen_Focus",
          Bullpen_Notes="Bullpen_Notes",
          stringsAsFactors=FALSE
        ),
        sheet="Pitches",
        range="AG1:AL1",
        col_names=FALSE
      )
    },error=function(e){})
  }
  
  load_pitcher_report_data <- function() {
    tryCatch({
      d <- sessions_admin_pitches()
      if(is.null(d)) d <- data.frame()
      d <- as.data.frame(d,stringsAsFactors=FALSE)
      
      if(nrow(d)>0){
        meaningful_cols <- intersect(
          c("Session_ID","Pitcher_ID","Batter_ID","Pitch_Type","Pitch_Result","Timestamp","Location_X","Location_Y"),
          names(d)
        )
        if(length(meaningful_cols)>0){
          row_has_data <- apply(
            d[,meaningful_cols,drop=FALSE],
            1,
            function(r) any(!is.na(r) & trimws(as.character(r))!="")
          )
          d <- d[row_has_data,,drop=FALSE]
        }
      }
      
      if (!"Inning" %in% names(d) && ncol(d)>=30) names(d)[30] <- "Inning"
      if (!"Half_Inning" %in% names(d) && ncol(d)>=31) names(d)[31] <- "Half_Inning"
      if (!"Outs_Before" %in% names(d) && ncol(d)>=32) names(d)[32] <- "Outs_Before"
      
      pitcher_report_pitches_raw(d)
      pitcher_report_error(NULL)
    },error=function(e){
      pitcher_report_pitches_raw(data.frame())
      pitcher_report_error(e$message)
    })
    
    tryCatch({
      p <- sessions_admin_pas()
      if(is.null(p)) p <- data.frame()
      pitcher_report_pa_raw(as.data.frame(p,stringsAsFactors=FALSE))
    },error=function(e){
      pitcher_report_pa_raw(data.frame())
    })
  }
  
  observeEvent(TRUE,{ load_pitcher_report_data() },once=TRUE)
  observeEvent(input$refresh_pitcher_report,{ refresh_sessions_admin_data(); load_sessions(select_session_id=current_session_id()); load_pitcher_report_data() })
  observeEvent(input$pitcher_report_pitcher,{ load_pitcher_report_data() },ignoreInit=TRUE)
  
  observe({
    s <- session_lookup()
    if (nrow(s)==0 || !"Session_ID" %in% names(s)) return()
    v <- s[!is.na(s$Session_ID) & as.character(s$Session_ID)!="",,drop=FALSE]
    labs <- if (all(c("Session_Date","Session_Name") %in% names(v))) paste0(v$Session_Date," — ",v$Session_Name) else as.character(v$Session_ID)
    ch <- as.character(v$Session_ID); names(ch) <- labs; ch <- c("All Sessions (Cumulative)"="ALL",ch)
    cur <- isolate(input$pitcher_report_session); if (is.null(cur) || !cur %in% ch) cur <- "ALL"
    updateSelectInput(session,"pitcher_report_session",choices=ch,selected=cur)
    if ("Session_Date" %in% names(v)) { dd<-suppressWarnings(as.Date(v$Session_Date)); dd<-dd[!is.na(dd)]; if(length(dd)>0) updateDateRangeInput(session,"pitcher_report_date_range",start=min(dd),end=max(dd)) }
  })
  
  p_safe <- function(row,col,default="—") {
    if(nrow(row)==0 || !col %in% names(row) || is.na(row[[col]][1]) || trimws(as.character(row[[col]][1]))=="") return(default)
    trimws(as.character(row[[col]][1]))
  }
  pitcher_player_row <- reactive({
    id<-input$pitcher_report_pitcher; x<-player_lookup()
    if(is.null(id)||id==""||nrow(x)==0||!"Player_ID"%in%names(x)) return(data.frame())
    x[as.character(x$Player_ID)==id,,drop=FALSE]
  })
  output$pitcher_report_name <- renderText({ p_safe(pitcher_player_row(),"Display_Name","Pitcher") })
  output$pitcher_report_bio <- renderUI({ r<-pitcher_player_row(); tagList(div(paste0("#",p_safe(r,"Jersey_Number")," • ",p_safe(r,"Primary_Position","P")," • Class: ",p_safe(r,"Class"))),div(paste0("Throws: ",p_safe(r,"Throws"))),div(paste0("Height: ",p_safe(r,"Height"),"   Weight: ",p_safe(r,"Weight")))) })
  output$pitcher_report_headshot <- renderUI({ id<-input$pitcher_report_pitcher; if(is.null(id)||id=="") return(tags$div(class="pitcher-headshot")); tags$img(class="pitcher-headshot",src=paste0("headshots/",id,".png"),onerror="this.style.visibility='hidden';") })
  
  p_session_dates <- reactive({ s<-session_lookup(); if(nrow(s)==0||!all(c("Session_ID","Session_Date")%in%names(s))) return(data.frame()); data.frame(Session_ID=as.character(s$Session_ID),Session_Date_Report=suppressWarnings(as.Date(s$Session_Date)),stringsAsFactors=FALSE) })
  pitcher_pitches <- reactive({
    d<-p_live_only(pitcher_report_pitches_raw()); id<-input$pitcher_report_pitcher
    if(nrow(d)==0||is.null(id)||id==""||!"Pitcher_ID"%in%names(d)) return(data.frame())
    d<-d[!is.na(d$Pitcher_ID)&as.character(d$Pitcher_ID)==id,,drop=FALSE]
    sd<-p_session_dates()
    if(nrow(sd)>0&&"Session_ID"%in%names(d)){ d$Session_ID<-as.character(d$Session_ID); d<-merge(d,sd,by="Session_ID",all.x=TRUE,sort=FALSE); rg<-input$pitcher_report_date_range; if(!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2])) d<-d[is.na(d$Session_Date_Report)|(d$Session_Date_Report>=as.Date(rg[1])&d$Session_Date_Report<=as.Date(rg[2])),,drop=FALSE] }
    sid<-input$pitcher_report_session; if(!is.null(sid)&&sid!=""&&sid!="ALL"&&"Session_ID"%in%names(d)) d<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
    d
  })
  pitcher_pas <- reactive({ d<-pitcher_report_pa_raw(); id<-input$pitcher_report_pitcher; if(nrow(d)==0||is.null(id)||id==""||!"Pitcher_ID"%in%names(d))return(data.frame()); d<-d[!is.na(d$Pitcher_ID)&as.character(d$Pitcher_ID)==id,,drop=FALSE]; sid<-input$pitcher_report_session; if(!is.null(sid)&&sid!=""&&sid!="ALL"&&"Session_ID"%in%names(d))d<-d[as.character(d$Session_ID)==sid,,drop=FALSE]; d })
  
  p_rate <- function(a,b){ a<-suppressWarnings(as.numeric(a));b<-suppressWarnings(as.numeric(b));if(length(a)==0||length(b)==0||!is.finite(a)||!is.finite(b)||b<=0)return(NA_real_);a/b }
  p_pct <- function(x){ x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x))return("N/A");paste0(sprintf("%.1f",100*x),"%") }
  p_strike <- function(x) as.character(x)%in%c("Called Strike","Whiff","Foul","In Play")
  p_lev <- function(x){x<-as.character(x);if(x%in%c("0-1","0-2","1-2"))"Ahead" else if(x%in%c("0-0","1-1","2-2"))"Even" else if(x%in%c("1-0","2-0","2-1","3-0","3-1","3-2"))"Behind" else "Other"}
  p_group <- function(pt,pg=NA_character_){pg<-toupper(trimws(as.character(pg)));pt<-toupper(trimws(as.character(pt)));if(!is.na(pg)&&pg!=""){if(pg%in%c("HARD","FASTBALL"))return("Hard");if(pg%in%c("BREAKING","BREAK"))return("Breaking");if(pg%in%c("SOFT","OFFSPEED","OFF-SPEED"))return("Soft")};if(pt%in%c("FB","FF","FA","SI","SINKER","CT","CUTTER"))"Hard" else if(pt%in%c("SL","SLIDER","CB","CURVEBALL","SW","SWEEPER"))"Breaking" else if(pt%in%c("CH","CHANGEUP","SPLIT","SPLITTER","SPL"))"Soft" else "Other"}
  p_live_only <- function(d){if(is.null(d)||nrow(d)==0||!"Charting_Mode"%in%names(d))return(d);d[is.na(d$Charting_Mode)|as.character(d$Charting_Mode)==""|as.character(d$Charting_Mode)=="Live",,drop=FALSE]}
  ptd <- function(x) tags$td(x); phead <- function(x) tags$thead(tags$tr(lapply(x,tags$th)))
  
  p_early_contact <- function(d) {
    if (nrow(d)==0 || !all(c("PA_ID","Pitch_Number","Pitch_Result") %in% names(d))) return(NA_real_)
    pa_ids <- unique(as.character(d$PA_ID))
    pa_ids <- pa_ids[!is.na(pa_ids) & pa_ids!=""]
    if (length(pa_ids)==0) return(NA_real_)
    hit_early <- logical(length(pa_ids))
    for (i in seq_along(pa_ids)) {
      z <- d[as.character(d$PA_ID)==pa_ids[i],,drop=FALSE]
      pn <- suppressWarnings(as.numeric(z$Pitch_Number))
      z <- z[order(pn),,drop=FALSE]
      z <- head(z,3)
      hit_early[i] <- any(as.character(z$Pitch_Result) %in% c("Foul","In Play"),na.rm=TRUE)
    }
    mean(hit_early)
  }
  
  p_metrics_from_data <- function(d) {
    if(nrow(d)==0)return(NULL)
    n<-nrow(d)
    st<-p_strike(d$Pitch_Result)
    fp<-suppressWarnings(as.numeric(d$Balls_Before))==0&suppressWarnings(as.numeric(d$Strikes_Before))==0
    sw<-as.character(d$Swing_Take)=="Swing"
    wh<-as.character(d$Pitch_Result)=="Whiff"
    ch<-as.character(d$Zone_Group)%in%c("Chase","Waste")
    zn<-as.character(d$Zone_Group)%in%c("Heart","Shadow")
    lv<-vapply(d$Count,p_lev,character(1));ld<-sum(lv%in%c("Ahead","Even","Behind"),na.rm=TRUE)
    inn<-if("Inning"%in%names(d))suppressWarnings(as.integer(d$Inning))else rep(NA_integer_,n)
    half<-if("Half_Inning"%in%names(d))as.character(d$Half_Inning)else rep("",n)
    vi<-is.finite(inn);eff<-api<-NA_real_;ni<-0
    if(any(vi)&&"Session_ID"%in%names(d)){
      tb<-table(paste(as.character(d$Session_ID[vi]),inn[vi],half[vi],sep="__"))
      ni<-length(tb);eff<-mean(as.numeric(tb)<=15);api<-mean(as.numeric(tb))
    }
    list(
      pitches=n,
      fps=p_rate(sum(fp&st,na.rm=TRUE),sum(fp,na.rm=TRUE)),
      strike=p_rate(sum(st,na.rm=TRUE),n),
      zone=p_rate(sum(zn,na.rm=TRUE),n),
      whiff=p_rate(sum(wh,na.rm=TRUE),sum(sw,na.rm=TRUE)),
      chase=p_rate(sum(ch&sw,na.rm=TRUE),sum(ch,na.rm=TRUE)),
      ahead=p_rate(sum(lv=="Ahead",na.rm=TRUE),ld),
      behind=p_rate(sum(lv=="Behind",na.rm=TRUE),ld),
      early_contact=p_early_contact(d),
      eff=eff,api=api,ni=ni
    )
  }
  
  p_metrics <- reactive({ p_metrics_from_data(pitcher_pitches()) })
  
  pitcher_team_pitches <- reactive({
    d <- p_live_only(pitcher_report_pitches_raw())
    if(nrow(d)==0 || !"Pitcher_ID"%in%names(d)) return(d)
    sd<-p_session_dates()
    if(nrow(sd)>0&&"Session_ID"%in%names(d)){
      d$Session_ID<-as.character(d$Session_ID);d<-merge(d,sd,by="Session_ID",all.x=TRUE,sort=FALSE)
      rg<-input$pitcher_report_date_range
      if(!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2])) d<-d[is.na(d$Session_Date_Report)|(d$Session_Date_Report>=as.Date(rg[1])&d$Session_Date_Report<=as.Date(rg[2])),,drop=FALSE]
    }
    sid<-input$pitcher_report_session
    if(!is.null(sid)&&sid!=""&&sid!="ALL"&&"Session_ID"%in%names(d))d<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
    d
  })
  
  pitcher_team_benchmarks <- reactive({
    d<-pitcher_team_pitches();if(nrow(d)==0)return(NULL)
    ids<-unique(as.character(d$Pitcher_ID));ids<-ids[!is.na(ids)&ids!=""]
    vals<-lapply(ids,function(id){m<-p_metrics_from_data(d[as.character(d$Pitcher_ID)==id,,drop=FALSE]);if(is.null(m))return(NULL);data.frame(id=id,fps=m$fps,strike=m$strike,zone=m$zone,whiff=m$whiff,chase=m$chase,ahead=m$ahead,behind=m$behind,early_contact=m$early_contact,eff=m$eff)})
    vals<-Filter(Negate(is.null),vals);if(length(vals)==0)return(NULL);df<-do.call(rbind,vals)
    out<-lapply(names(df)[-1],function(nm){x<-suppressWarnings(as.numeric(df[[nm]]));x<-x[is.finite(x)];if(length(x)==0)NA_real_ else mean(x)})
    names(out)<-names(df)[-1];out
  })
  
  p_bench_class <- function(value,avg,higher=TRUE,tol=.02){
    benchmark_class(value,avg,higher_is_better=higher,tolerance=tol)
  }
  pkpi <- function(l,v,s="",cl="")div(class="pitcher-kpi-card",div(class="pitcher-kpi-label",l),div(class=paste("pitcher-kpi-value",cl),v),div(class="pitcher-kpi-sub",s))
  
  output$pitcher_report_kpis <- renderUI({
    x<-p_metrics();b<-pitcher_team_benchmarks()
    if(is.null(x))return(tagList(pkpi("Pitches","0"),pkpi("1st Pitch Strike %","N/A"),pkpi("Strike %","N/A"),pkpi("Whiff %","N/A"),pkpi("Chase %","N/A"),pkpi("Ahead %","N/A"),pkpi("Behind %","N/A"),pkpi("Contact ≤3 Pitches","N/A"),pkpi("≤15 Pitch Innings","N/A")))
    av<-function(nm)if(is.null(b))NA_real_ else b[[nm]]
    tagList(
      pkpi("Pitches",x$pitches),
      pkpi("1st Pitch Strike %",p_pct(x$fps),"",p_bench_class(x$fps,av("fps"),TRUE)),
      pkpi("Strike %",p_pct(x$strike),"",p_bench_class(x$strike,av("strike"),TRUE)),
      pkpi("Whiff %",p_pct(x$whiff),"",p_bench_class(x$whiff,av("whiff"),TRUE)),
      pkpi("Chase %",p_pct(x$chase),"",p_bench_class(x$chase,av("chase"),TRUE)),
      pkpi("Ahead %",p_pct(x$ahead),"",p_bench_class(x$ahead,av("ahead"),TRUE)),
      pkpi("Behind %",p_pct(x$behind),"",p_bench_class(x$behind,av("behind"),FALSE)),
      pkpi("Contact ≤3 Pitches",p_pct(x$early_contact),"PA with Foul/In Play in first 3",p_bench_class(x$early_contact,av("early_contact"),TRUE)),
      pkpi("≤15 Pitch Innings",p_pct(x$eff),if(x$ni>0)paste0("Avg ",sprintf("%.1f",x$api)," pitches/inning")else"Inning data begins with new charting",p_bench_class(x$eff,av("eff"),TRUE))
    )
  })
  
  p_staff_grade_component <- function(value,avg,higher=TRUE){
    value<-suppressWarnings(as.numeric(value));avg<-suppressWarnings(as.numeric(avg))
    if(!is.finite(value)||!is.finite(avg))return(NA_real_)
    delta<-if(higher)value-avg else avg-value
    max(50,min(100,75+200*delta))
  }
  p_grade_letter <- function(v){if(!is.finite(v))return("—");if(v>=93)"A+"else if(v>=90)"A"else if(v>=87)"A-"else if(v>=83)"B+"else if(v>=80)"B"else if(v>=77)"B-"else if(v>=73)"C+"else if(v>=70)"C"else if(v>=67)"C-"else if(v>=63)"D+"else if(v>=60)"D"else"F"}
  p_mean_grade <- function(x){x<-x[is.finite(x)];if(length(x)==0)NA_real_ else mean(x)}
  pitcher_grades <- reactive({
    x<-p_metrics();b<-pitcher_team_benchmarks();if(is.null(x)||is.null(b))return(NULL)
    command<-p_mean_grade(c(p_staff_grade_component(x$fps,b$fps,TRUE),p_staff_grade_component(x$strike,b$strike,TRUE),p_staff_grade_component(x$zone,b$zone,TRUE),p_staff_grade_component(x$behind,b$behind,FALSE)))
    miss<-p_mean_grade(c(p_staff_grade_component(x$whiff,b$whiff,TRUE),p_staff_grade_component(x$chase,b$chase,TRUE)))
    efficiency<-p_mean_grade(c(p_staff_grade_component(x$ahead,b$ahead,TRUE),p_staff_grade_component(x$early_contact,b$early_contact,TRUE),p_staff_grade_component(x$eff,b$eff,TRUE)))
    overall<-p_mean_grade(c(command,miss,efficiency))
    list(overall=overall,command=command,miss=miss,efficiency=efficiency)
  })
  p_grade_card <- function(label,v){
    div(class="pitcher-grade-card",div(class="pitcher-grade-label",label),div(class="pitcher-grade-letter",p_grade_letter(v)),div(class="pitcher-grade-number",if(is.finite(v))paste0(sprintf("%.1f",v)," / 100")else"N/A"))
  }
  output$pitcher_report_grades <- renderUI({
    g<-pitcher_grades();if(is.null(g))return(tagList(p_grade_card("Overall Grade",NA),p_grade_card("Command Grade",NA),p_grade_card("Miss Grade",NA),p_grade_card("Efficiency Grade",NA)))
    tagList(p_grade_card("Overall Grade",g$overall),p_grade_card("Command Grade",g$command),p_grade_card("Miss Grade",g$miss),p_grade_card("Efficiency Grade",g$efficiency))
  })
  
  p_pa_stats <- reactive({
    pa<-pitcher_pas();d<-pitcher_pitches();if(nrow(pa)==0)return(NULL)
    n<-nrow(pa)
    num<-function(col)if(col%in%names(pa))sum(suppressWarnings(as.numeric(pa[[col]])),na.rm=TRUE)else 0
    ab<-num("Is_AB");hits<-num("Is_Hit");tb<-num("Bases_Total");bb<-num("Is_BB");hbp<-num("Is_HBP");sf<-num("Is_SF");k<-num("Is_K")
    res<-if("PA_Result"%in%names(pa))as.character(pa$PA_Result)else rep("",n);hr<-sum(res=="Home Run",na.rm=TRUE)
    avg<-p_rate(hits,ab);obp<-p_rate(hits+bb+hbp,ab+bb+hbp+sf);slg<-p_rate(tb,ab);babip<-p_rate(hits-hr,ab-k-hr+sf)
    cq<-if(nrow(d)>0&&"Contact_Quality"%in%names(d))as.character(d$Contact_Quality)else character(0);cden<-sum(cq%in%c("Hard","Average","Avg","Weak"),na.rm=TRUE)
    games<-if("Session_ID"%in%names(pa))length(unique(as.character(pa$Session_ID[!is.na(pa$Session_ID)&as.character(pa$Session_ID)!=""])))else NA_integer_
    list(BF=n,G=games,K=k,BB=bb,HBP=hbp,HR=hr,KPct=p_rate(k,n),BBPct=p_rate(bb,n),KBB=p_rate(k-bb,n),HRPct=p_rate(hr,n),BABIP=babip,AVG=avg,OBP=obp,SLG=slg,Hard=p_rate(sum(cq=="Hard",na.rm=TRUE),cden),Medium=p_rate(sum(cq%in%c("Average","Avg"),na.rm=TRUE),cden),Soft=p_rate(sum(cq=="Weak",na.rm=TRUE),cden))
  })
  p_bat_fmt <- function(x){if(!is.finite(x))"N/A"else sub("^0","",sprintf("%.3f",x))}
  p_stat_cell <- function(l,v,cl="")div(class="pitcher-stat-cell",div(class="pitcher-stat-label",l),div(class=paste("pitcher-stat-value",cl),v))
  output$pitcher_statistics_grid <- renderUI({
    s<-p_pa_stats();if(is.null(s))return(div(class="report-breakdown-note","No PA statistics available."))
    tagList(div(class="pitcher-stats-grid",
                p_stat_cell("BF",s$BF),p_stat_cell("G",s$G),p_stat_cell("K",s$K),p_stat_cell("BB",s$BB),p_stat_cell("HBP",s$HBP),p_stat_cell("HR",s$HR),
                p_stat_cell("K%",p_pct(s$KPct)),p_stat_cell("BB%",p_pct(s$BBPct)),p_stat_cell("K-BB%",p_pct(s$KBB)),p_stat_cell("HR%",p_pct(s$HRPct)),p_stat_cell("BABIP",p_bat_fmt(s$BABIP)),p_stat_cell("OPP AVG",p_bat_fmt(s$AVG)),
                p_stat_cell("OPP OBP",p_bat_fmt(s$OBP)),p_stat_cell("OPP SLG",p_bat_fmt(s$SLG)),p_stat_cell("Hard Contact %",p_pct(s$Hard)),p_stat_cell("Medium Contact %",p_pct(s$Medium)),p_stat_cell("Soft Contact %",p_pct(s$Soft)),p_stat_cell("IP","N/A")
    ))
  })
  
  output$pitcher_report_status <- renderUI({e<-pitcher_report_error();d<-pitcher_pitches();if(!is.null(e))div(class="warning-text",paste0("Pitcher report load error: ",e))else div(class="success-text",paste0("Report loaded from ",nrow(d)," charted pitches."))})
  output$pitcher_count_leverage <- renderUI({d<-pitcher_pitches();if(nrow(d)==0)return(div(class="report-breakdown-note","No count data available."));lv<-vapply(d$Count,p_lev,character(1));den<-sum(lv%in%c("Ahead","Even","Behind"));f<-function(z)p_pct(p_rate(sum(lv==z),den));div(class="count-leverage-strip",div(class="count-leverage-cell",div(class="count-leverage-label","Ahead"),div(class="count-leverage-value pitch-eff-good",f("Ahead"))),div(class="count-leverage-cell",div(class="count-leverage-label","Even"),div(class="count-leverage-value",f("Even"))),div(class="count-leverage-cell",div(class="count-leverage-label","Behind"),div(class="count-leverage-value pitch-eff-poor",f("Behind"))))})
  
  output$pitcher_inning_efficiency_table <- renderUI({d<-pitcher_pitches();if(nrow(d)==0||!"Inning"%in%names(d)||!"Session_ID"%in%names(d))return(div(class="report-breakdown-note","No inning data available yet."));inn<-suppressWarnings(as.integer(d$Inning));v<-is.finite(inn);if(!any(v))return(div(class="report-breakdown-note","No inning values are stored yet. New pitches charted with this version will include inning."));x<-d[v,,drop=FALSE];x$Inn<-inn[v];x$Half<-if("Half_Inning"%in%names(x))as.character(x$Half_Inning)else"";keys<-unique(paste(x$Session_ID,x$Inn,x$Half,sep="__"));rr<-lapply(keys,function(k){p<-strsplit(k,"__",fixed=TRUE)[[1]];z<-x[as.character(x$Session_ID)==p[1]&x$Inn==as.integer(p[2]),,drop=FALSE];st<-sum(p_strike(z$Pitch_Result));data.frame(Session=p[1],Inning=as.integer(p[2]),Pitches=nrow(z),Strikes=st,Balls=nrow(z)-st,Strike=p_rate(st,nrow(z)),Eff=nrow(z)<=15)});df<-do.call(rbind,rr);body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,,drop=FALSE];tags$tr(class=if(r$Eff)"inning-efficient"else"inning-over",ptd(r$Session),ptd(r$Inning),ptd(r$Pitches),ptd(r$Strikes),ptd(r$Balls),ptd(p_pct(r$Strike)),ptd(if(r$Eff)"YES"else"NO"))});tags$table(class="table table-striped table-condensed",phead(c("Session","Inn","Pitches","Strikes","Balls","Strike %","≤15?")),tags$tbody(body))})
  
  p_arsenal <- reactive({d<-pitcher_pitches();if(nrow(d)==0)return(data.frame());pts<-trimws(as.character(d$Pitch_Type));d<-d[!is.na(pts)&pts!=""&pts!="None",,drop=FALSE];pts<-trimws(as.character(d$Pitch_Type));if(nrow(d)==0)return(data.frame());do.call(rbind,lapply(unique(pts),function(pt){z<-d[pts==pt,,drop=FALSE];n<-nrow(z);st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";ch<-as.character(z$Zone_Group)%in%c("Chase","Waste");zn<-as.character(z$Zone_Group)%in%c("Heart","Shadow");cq<-as.character(z$Contact_Quality);cd<-sum(cq%in%c("Hard","Average","Avg","Weak"));pg<-if("Pitch_Group"%in%names(z))z$Pitch_Group[1]else NA;data.frame(Pitch=pt,Group=p_group(pt,pg),Pitches=n,Usage=p_rate(n,nrow(d)),Strike=p_rate(sum(st),n),Zone=p_rate(sum(zn),n),Swing=p_rate(sum(sw),n),Whiff=p_rate(sum(wh),sum(sw)),Chase=p_rate(sum(ch&sw),sum(ch)),Hard=p_rate(sum(cq=="Hard"),cd),stringsAsFactors=FALSE)}))})
  p_colored_td <- function(display,value,avg,higher=TRUE,tol=.02){tags$td(class=p_bench_class(value,avg,higher,tol),display)}
  pitcher_team_pitchtype_bench <- reactive({
    d<-pitcher_team_pitches();if(nrow(d)==0||!"Pitch_Type"%in%names(d))return(data.frame())
    ids<-unique(as.character(d$Pitcher_ID));pts<-unique(as.character(d$Pitch_Type));rows<-list()
    for(pt in pts){if(is.na(pt)||pt==""||pt=="None")next;vals<-list();for(id in ids){z<-d[as.character(d$Pitcher_ID)==id&as.character(d$Pitch_Type)==pt,,drop=FALSE];if(nrow(z)==0)next;st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";ch<-as.character(z$Zone_Group)%in%c("Chase","Waste");zn<-as.character(z$Zone_Group)%in%c("Heart","Shadow");cq<-as.character(z$Contact_Quality);cd<-sum(cq%in%c("Hard","Average","Avg","Weak"),na.rm=TRUE);vals[[length(vals)+1]]<-data.frame(Strike=p_rate(sum(st),nrow(z)),Zone=p_rate(sum(zn),nrow(z)),Swing=p_rate(sum(sw),nrow(z)),Whiff=p_rate(sum(wh),sum(sw)),Chase=p_rate(sum(ch&sw),sum(ch)),Hard=p_rate(sum(cq=="Hard"),cd))};if(length(vals)>0){v<-do.call(rbind,vals);rows[[length(rows)+1]]<-data.frame(Pitch=pt,Strike=mean(v$Strike,na.rm=TRUE),Zone=mean(v$Zone,na.rm=TRUE),Swing=mean(v$Swing,na.rm=TRUE),Whiff=mean(v$Whiff,na.rm=TRUE),Chase=mean(v$Chase,na.rm=TRUE),Hard=mean(v$Hard,na.rm=TRUE))}}
    if(length(rows)==0)data.frame()else do.call(rbind,rows)
  })
  output$pitcher_arsenal_table <- renderUI({
    df<-p_arsenal();if(nrow(df)==0)return(div(class="report-breakdown-note","No pitch data available."));df<-df[order(-df$Pitches),];tb<-pitcher_team_pitchtype_bench()
    body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,];b<-tb[as.character(tb$Pitch)==as.character(r$Pitch),,drop=FALSE];av<-function(nm)if(nrow(b)>0)b[[nm]][1]else NA_real_;tags$tr(ptd(r$Pitch),ptd(r$Group),ptd(r$Pitches),ptd(p_pct(r$Usage)),p_colored_td(p_pct(r$Strike),r$Strike,av("Strike"),TRUE),p_colored_td(p_pct(r$Zone),r$Zone,av("Zone"),TRUE),p_colored_td(p_pct(r$Swing),r$Swing,av("Swing"),FALSE),p_colored_td(p_pct(r$Whiff),r$Whiff,av("Whiff"),TRUE),p_colored_td(p_pct(r$Chase),r$Chase,av("Chase"),TRUE),p_colored_td(p_pct(r$Hard),r$Hard,av("Hard"),FALSE))})
    tags$table(class="table table-striped table-condensed",phead(c("Pitch","Group","Pitches","Usage %","Strike %","Zone %","Swing %","Whiff %","Chase %","Hard Contact %")),tags$tbody(body))
  })
  
  output$pitcher_count_usage_table <- renderUI({d<-pitcher_pitches();if(nrow(d)==0)return(div(class="report-breakdown-note","No count data available."));cts<-c("0-0","1-0","0-1","2-0","1-1","0-2","3-0","2-1","1-2","3-1","2-2","3-2");rows<-list();for(ct in cts){z<-d[as.character(d$Count)==ct,,drop=FALSE];if(nrow(z)==0)next;pg<-if("Pitch_Group"%in%names(z))as.character(z$Pitch_Group)else rep(NA,nrow(z));g<-mapply(p_group,as.character(z$Pitch_Type),pg,USE.NAMES=FALSE);tab<-sort(table(z$Pitch_Type),decreasing=TRUE);most<-if(length(tab)>0)names(tab)[1]else"—";st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";rows[[length(rows)+1]]<-data.frame(Count=ct,Pitches=nrow(z),Hard=mean(g=="Hard"),Breaking=mean(g=="Breaking"),Soft=mean(g=="Soft"),Most=most,Strike=p_rate(sum(st),nrow(z)),Whiff=p_rate(sum(wh),sum(sw)))};if(length(rows)==0)return(div(class="report-breakdown-note","No count data available."));df<-do.call(rbind,rows);body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,];tags$tr(ptd(r$Count),ptd(r$Pitches),ptd(p_pct(r$Hard)),ptd(p_pct(r$Breaking)),ptd(p_pct(r$Soft)),ptd(r$Most),ptd(p_pct(r$Strike)),ptd(p_pct(r$Whiff)))});tags$table(class="table table-striped table-condensed",phead(c("Count","Pitches","Hard %","Breaking %","Soft %","Most Used","Strike %","Whiff %")),tags$tbody(body))})
  
  observe({d<-pitcher_pitches();pts<-if(nrow(d)>0)sort(unique(trimws(as.character(d$Pitch_Type))))else character(0);pts<-pts[!is.na(pts)&pts!=""&pts!="None"];ch<-c("All Pitches"="ALL",setNames(pts,pts));cur<-isolate(input$pitcher_location_pitch_type);if(is.null(cur)||!cur%in%ch)cur<-"ALL";updateSelectInput(session,"pitcher_location_pitch_type",choices=ch,selected=cur)})
  p_loc <- reactive({
    d<-pitcher_pitches();sel<-input$pitcher_location_pitch_type;side_sel<-input$pitcher_location_batter_side
    if(nrow(d)==0||!all(c("Location_X","Location_Y")%in%names(d)))return(data.frame(X=numeric(0),Y=numeric(0)))
    if(!is.null(sel)&&sel!=""&&sel!="ALL")d<-d[as.character(d$Pitch_Type)==sel,,drop=FALSE]
    if(!is.null(side_sel)&&side_sel!=""&&side_sel!="ALL"&&"Batter_ID"%in%names(d)){
      lu<-player_lookup();if(nrow(lu)>0&&all(c("Player_ID","Bats")%in%names(lu))){idx<-match(as.character(d$Batter_ID),as.character(lu$Player_ID));bs<-toupper(as.character(lu$Bats[idx]));d<-d[bs==side_sel,,drop=FALSE]}
    }
    x<-suppressWarnings(as.numeric(d$Location_X));y<-suppressWarnings(as.numeric(d$Location_Y));k<-is.finite(x)&is.finite(y)&x>=0&x<=1&y>=0&y<=1;data.frame(X=x[k],Y=y[k])
  })
  p_color <- function(v)c("#2459E6","#1FAEE0","#39DC44","#FFCD37","#EF3124")[min(5,max(1,1+floor(max(0,min(1,v))*4)))]
  p_heat <- function(sp){xmin<-.10;xmax<-.90;ymin<-.08;ymax<-.84;px<-40;py<-18;pw<-300;ph<-285;nc<-48;nr<-46;bw<-.075;den<-matrix(0,nr,nc);if(nrow(sp)>0)for(r in seq_len(nr))for(c in seq_len(nc)){cx<-xmin+((c-.5)/nc)*(xmax-xmin);cy<-ymin+((r-.5)/nr)*(ymax-ymin);dd<-sqrt((sp$X-cx)^2+(sp$Y-cy)^2);den[r,c]<-sum(exp(-.5*(dd/bw)^2))};mx<-max(den);if(!is.finite(mx)||mx<=0)mx<-1;cw<-pw/nc;ch<-ph/nr;cells<-character();for(r in seq_len(nr))for(c in seq_len(nc)){v<-den[r,c]/mx;if(v<.025)next;cells<-c(cells,paste0('<rect x="',round(px+(c-1)*cw,2),'" y="',round(py+(r-1)*ch,2),'" width="',round(cw+.8,2),'" height="',round(ch+.8,2),'" fill="',p_color(v),'" fill-opacity="',round(min(.95,.10+.88*v),3),'" stroke="none"/>'))};sl<-202/520;sr<-318/520;st<-200/520;sb<-335/520;mxp<-function(v)px+pw*((v-xmin)/(xmax-xmin));myp<-function(v)py+ph*((v-ymin)/(ymax-ymin));sx<-mxp(sl);sy<-myp(st);sw<-mxp(sr)-sx;sh<-myp(sb)-sy;zone<-paste0('<rect x="',sx,'" y="',sy,'" width="',sw,'" height="',sh,'" fill="none" stroke="#2F2F2F" stroke-width="1.7"/>');platey<-sy+sh+25;plate<-paste0('<polygon points="157,',platey,' 223,',platey,' 231,',platey+7,' 190,',platey+18,' 149,',platey+7,'" fill="#fff" stroke="#333" stroke-width="1.3"/>');empty<-if(nrow(sp)==0)'<text x="190" y="155" text-anchor="middle" font-size="13" fill="#666">No exact pitch-location data available</text>'else'';HTML(paste0('<div class="pitcher-location-svg"><svg viewBox="0 0 380 340" width="100%" xmlns="http://www.w3.org/2000/svg"><rect x="40" y="18" width="300" height="285" fill="#fff"/>',paste0(cells,collapse=''),zone,plate,empty,'</svg></div>'))}
  output$pitcher_location_heatmap <- renderUI({
    side<-input$pitcher_location_batter_side
    sil<-if(is.null(side)||side=="ALL"){
      tagList(tags$img(class="pitcher-batter-silhouette all-left",src="batter_silhouette.png"),tags$img(class="pitcher-batter-silhouette all-right",src="batter_silhouette.png"))
    }else if(side=="R"){
      tags$img(class="pitcher-batter-silhouette rhh",src="batter_silhouette.png")
    }else{
      tags$img(class="pitcher-batter-silhouette lhh",src="batter_silhouette.png")
    }
    div(class="pitcher-location-stage",sil,p_heat(p_loc()))
  })
  
  output$pitcher_side_splits_table <- renderUI({d<-pitcher_pitches();if(nrow(d)==0)return(div(class="report-breakdown-note","No split data available."));lu<-player_lookup();side<-rep(NA_character_,nrow(d));if("Batter_ID"%in%names(d)&&nrow(lu)>0&&all(c("Player_ID","Bats")%in%names(lu))){idx<-match(as.character(d$Batter_ID),as.character(lu$Player_ID));side<-as.character(lu$Bats[idx])};rows<-list();for(s in c("R","L")){z<-d[toupper(side)==s,,drop=FALSE];if(nrow(z)==0)next;st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";ch<-as.character(z$Zone_Group)%in%c("Chase","Waste");cq<-as.character(z$Contact_Quality);cd<-sum(cq%in%c("Hard","Average","Avg","Weak"));rows[[length(rows)+1]]<-data.frame(Side=s,Pitches=nrow(z),Strike=p_rate(sum(st),nrow(z)),Whiff=p_rate(sum(wh),sum(sw)),Chase=p_rate(sum(ch&sw),sum(ch)),Hard=p_rate(sum(cq=="Hard"),cd))};if(length(rows)==0)return(div(class="report-breakdown-note","Batter handedness is not available."));df<-do.call(rbind,rows);body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,];tags$tr(ptd(paste0("vs ",r$Side,"HH")),ptd(r$Pitches),ptd(p_pct(r$Strike)),ptd(p_pct(r$Whiff)),ptd(p_pct(r$Chase)),ptd(p_pct(r$Hard)))});tags$table(class="table table-striped table-condensed",phead(c("Split","Pitches","Strike %","Whiff %","Chase %","Hard Contact %")),tags$tbody(body))})
  
  output$pitcher_results_table <- renderUI({pa<-pitcher_pas();if(nrow(pa)==0||!"PA_Result"%in%names(pa))return(div(class="report-breakdown-note","No PA results available."));r<-trimws(as.character(pa$PA_Result));r<-r[!is.na(r)&r!=""];if(length(r)==0)return(div(class="report-breakdown-note","No PA results available."));tb<-sort(table(r),decreasing=TRUE);tot<-sum(tb);body<-lapply(seq_along(tb),function(i)tags$tr(ptd(names(tb)[i]),ptd(as.integer(tb[i])),ptd(p_pct(p_rate(tb[i],tot)))));body<-c(body,list(tags$tr(class="breakdown-total-row",ptd("TOTAL"),ptd(tot),ptd("100.0%"))));tags$table(class="table table-striped table-condensed",phead(c("Result","PA","%")),tags$tbody(body))})
  output$pitcher_count_summary_table <- renderUI({d<-pitcher_pitches();if(nrow(d)==0)return(div(class="report-breakdown-note","No count data available."));lv<-vapply(d$Count,p_lev,character(1));rows<-lapply(c("Ahead","Even","Behind"),function(s){z<-d[lv==s,,drop=FALSE];if(nrow(z)==0)return(NULL);st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";data.frame(State=s,Pitches=nrow(z),Share=p_rate(nrow(z),nrow(d)),Strike=p_rate(sum(st),nrow(z)),Whiff=p_rate(sum(wh),sum(sw)))});rows<-Filter(Negate(is.null),rows);df<-do.call(rbind,rows);body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,];tags$tr(ptd(r$State),ptd(r$Pitches),ptd(p_pct(r$Share)),ptd(p_pct(r$Strike)),ptd(p_pct(r$Whiff)))});tags$table(class="table table-striped table-condensed",phead(c("State","Pitches","Share %","Strike %","Whiff %")),tags$tbody(body))})
  output$pitcher_group_summary_table <- renderUI({d<-pitcher_pitches();if(nrow(d)==0)return(div(class="report-breakdown-note","No pitch-group data available."));pg<-if("Pitch_Group"%in%names(d))as.character(d$Pitch_Group)else rep(NA,nrow(d));g<-mapply(p_group,as.character(d$Pitch_Type),pg,USE.NAMES=FALSE);rows<-lapply(c("Hard","Breaking","Soft"),function(s){z<-d[g==s,,drop=FALSE];if(nrow(z)==0)return(NULL);st<-p_strike(z$Pitch_Result);sw<-as.character(z$Swing_Take)=="Swing";wh<-as.character(z$Pitch_Result)=="Whiff";data.frame(Group=s,Pitches=nrow(z),Usage=p_rate(nrow(z),nrow(d)),Strike=p_rate(sum(st),nrow(z)),Whiff=p_rate(sum(wh),sum(sw)))});rows<-Filter(Negate(is.null),rows);if(length(rows)==0)return(div(class="report-breakdown-note","No pitch-group data available."));df<-do.call(rbind,rows);body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,];tags$tr(ptd(r$Group),ptd(r$Pitches),ptd(p_pct(r$Usage)),ptd(p_pct(r$Strike)),ptd(p_pct(r$Whiff)))});tags$table(class="table table-striped table-condensed",phead(c("Group","Pitches","Usage %","Strike %","Whiff %")),tags$tbody(body))})
  
  output$export_pitcher_report_pdf <- downloadHandler(filename=function(){paste0(gsub("[^A-Za-z0-9_-]+","_",p_safe(pitcher_player_row(),"Display_Name","pitcher")),"_pitcher_report.pdf")},content=function(file){if(!requireNamespace("webshot2",quietly=TRUE))stop("PDF export requires webshot2. Install with install.packages('webshot2').");u<-session$clientData$url_protocol;h<-session$clientData$url_hostname;p<-session$clientData$url_port;url<-paste0(u,"//",h,if(!is.null(p)&&p!="")paste0(":",p)else"");webshot2::webshot(url=url,file=file,vwidth=1800,vheight=1050,zoom=1)},contentType="application/pdf")
  
  # ==================================================
  # QUAB STORAGE + LEADERBOARD
  # ==================================================
  ensure_quab_pa_columns <- function(){tryCatch({googlesheets4::range_write(ss=SHEET_URL,data=data.frame(Is_Barrel="Is_Barrel",Is_Offensive_Play="Is_Offensive_Play",Move_Runner_3rd_LT2="Move_Runner_3rd_LT2",Is_QUAB="Is_QUAB",QUAB_Reasons="QUAB_Reasons",stringsAsFactors=FALSE),sheet="Plate_Appearances",range="V1:Z1",col_names=FALSE)},error=function(e){})}
  observeEvent(TRUE,{ensure_quab_pa_columns()},once=TRUE)
  
  lb_safe_num<-function(x,default=NA_real_){x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x[1]))default else x[1]}
  lb_rate<-function(a,b){a<-suppressWarnings(as.numeric(a));b<-suppressWarnings(as.numeric(b));if(length(a)==0||length(b)==0||!is.finite(a)||!is.finite(b)||b<=0)NA_real_ else a/b}
  lb_normalize_pct<-function(x){x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x[1]))return(NA_real_);x<-x[1];if(abs(x)>1.000001)x<-x/100;x}
  lb_pct<-function(x){x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x))"N/A" else paste0(sprintf("%.1f",100*x),"%")}
  lb_avg_fmt<-function(x){x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x))"N/A" else sub("^0","",sprintf("%.3f",x))}
  lb_grade_fmt<-function(x){x<-suppressWarnings(as.numeric(x));if(length(x)==0||!is.finite(x))"N/A" else paste0(grade_letter(x),"  ",sprintf("%.1f",x))}
  lb_name<-function(id){lu<-player_lookup();if(nrow(lu)==0||!"Player_ID"%in%names(lu))return(as.character(id));r<-lu[as.character(lu$Player_ID)==as.character(id),,drop=FALSE];if(nrow(r)==0)return(as.character(id));if("Display_Name"%in%names(r)&&!is.na(r$Display_Name[1])&&trimws(as.character(r$Display_Name[1]))!="")trimws(as.character(r$Display_Name[1])) else as.character(id)}
  lb_session_date_map<-reactive({s<-session_lookup();if(nrow(s)==0||!all(c("Session_ID","Session_Date")%in%names(s)))return(setNames(as.Date(character(0)),character(0)));setNames(suppressWarnings(as.Date(s$Session_Date)),as.character(s$Session_ID))})
  lb_filter_frame<-function(d){if(is.null(d)||nrow(d)==0)return(data.frame());sid<-input$leaderboard_session;if(!is.null(sid)&&sid!=""&&sid!="ALL"&&"Session_ID"%in%names(d))d<-d[as.character(d$Session_ID)==sid,,drop=FALSE];rg<-input$leaderboard_date_range;mp<-lb_session_date_map();if("Session_ID"%in%names(d)&&length(mp)>0&&!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2])){dd<-unname(mp[as.character(d$Session_ID)]);keep<-!is.na(dd)&dd>=as.Date(rg[1])&dd<=as.Date(rg[2]);d<-d[keep,,drop=FALSE]};d}
  leaderboard_pitches<-reactive({lb_filter_frame(p_live_only(pitcher_report_pitches_raw()))})
  leaderboard_pas<-reactive({lb_filter_frame(pitcher_report_pa_raw())})
  
  observe({s<-session_lookup();if(nrow(s)==0||!"Session_ID"%in%names(s))return();v<-s[!is.na(s$Session_ID)&as.character(s$Session_ID)!="",,drop=FALSE];labs<-if(all(c("Session_Date","Session_Name")%in%names(v)))paste0(v$Session_Date," — ",v$Session_Name)else as.character(v$Session_ID);ch<-as.character(v$Session_ID);names(ch)<-labs;ch<-c("All Sessions (Cumulative)"="ALL",ch);cur<-isolate(input$leaderboard_session);if(is.null(cur)||!cur%in%ch)cur<-"ALL";updateSelectInput(session,"leaderboard_session",choices=ch,selected=cur);if("Session_Date"%in%names(v)){dd<-suppressWarnings(as.Date(v$Session_Date));dd<-dd[!is.na(dd)];if(length(dd)>0)updateDateRangeInput(session,"leaderboard_date_range",start=min(dd),end=max(dd))}})
  
  lb_hitter_metric_choices <- c(
    "Overall Grade"="Overall_Grade",
    "Pre-2K Grade"="Pre2K_Grade",
    "2K Grade"="TwoK_Grade",
    "Swing Rate %"="Swing_Pct",
    "Heart Swing %"="Heart_Swing_Pct",
    "Chase Rate %"="Chase_Pct",
    "Whiff Rate %"="Whiff_Pct",
    "Contact Rate %"="Contact_Pct",
    "Decision Quality"="Decision_Quality",
    "Contact Quality"="Contact_Quality_Score",
    "Hard Contact %"="Hard_Contact_Pct",
    "QUAB %"="QUAB_Pct",
    "QUABs"="QUABs",
    "PA"="PA","AB"="AB","Hits"="Hits",
    "AVG"="AVG","OBP"="OBP","SLG"="SLG","OPS"="OPS",
    "Strikeouts"="SO","Walks"="BB","HBP"="HBP","RBI"="RBI",
    "K%"="K_Pct","BB%"="BB_Pct","BABIP"="BABIP",
    "8+ Pitch PA"="QUAB_8Pitch",
    "4+ Pitches After 2K"="QUAB_4After2K",
    "Hard-Contact Barrels"="QUAB_Barrel",
    "Successful Offensive Plays"="QUAB_Offensive",
    "Moved Runner to 3rd (<2 outs)"="QUAB_MoveThird",
    "Reached on Error"="QUAB_Error"
  )
  lb_pitcher_metric_choices <- c(
    "Overall Grade"="Overall_Grade",
    "Command Grade"="Command_Grade",
    "Miss Grade"="Miss_Grade",
    "Efficiency Grade"="Efficiency_Grade",
    "≤15 Pitch Innings %"="Efficient_Inning_Pct",
    "1st Pitch Strike %"="FPS_Pct",
    "Strike %"="Strike_Pct",
    "Zone %"="Zone_Pct",
    "Whiff %"="Whiff_Pct",
    "Chase %"="Chase_Pct",
    "Ahead %"="Ahead_Pct",
    "Behind %"="Behind_Pct",
    "Contact ≤3 Pitches %"="Early_Contact_Pct",
    "Avg Pitches / Inning"="Avg_Pitches_Inning",
    "Pitches"="Pitches","Batters Faced"="BF","Games"="G",
    "Strikeouts"="K","Walks"="BB","HBP"="HBP","Home Runs Allowed"="HR",
    "K%"="K_Pct","BB%"="BB_Pct","K-BB%"="KBB_Pct","HR%"="HR_Pct",
    "BABIP"="BABIP","Opponent AVG"="Opp_AVG","Opponent OBP"="Opp_OBP","Opponent SLG"="Opp_SLG",
    "Hard Contact Allowed %"="Hard_Contact_Pct",
    "Medium Contact Allowed %"="Medium_Contact_Pct",
    "Soft Contact Allowed %"="Soft_Contact_Pct"
  )
  observeEvent(input$leaderboard_type,{
    ch<-if(identical(input$leaderboard_type,"Pitcher"))lb_pitcher_metric_choices else lb_hitter_metric_choices
    updateSelectInput(session,"leaderboard_rank_metric",choices=ch,selected=unname(ch[1]))
  },ignoreInit=FALSE)
  
  lb_sum_col<-function(d,col){if(nrow(d)==0||!col%in%names(d))return(0);sum(suppressWarnings(as.numeric(d[[col]])),na.rm=TRUE)}
  
  lb_quab_summary<-function(pa,pitches){if(nrow(pa)==0)return(list(PA=0,QUABs=0,QUAB_Pct=NA_real_,Hit=0,BBHBP=0,RBI=0,EightPitch=0,FourAfter2K=0,Barrel=0,Offensive=0,MoveThird=0,Error=0));ids<-if("PA_ID"%in%names(pa))as.character(pa$PA_ID)else paste0("ROW_",seq_len(nrow(pa)));hit<-bbhbp<-rbi<-eight<-four2k<-barrel<-off<-move3<-err<-out<-logical(nrow(pa));for(i in seq_len(nrow(pa))){r<-pa[i,,drop=FALSE];res<-if("PA_Result"%in%names(r))as.character(r$PA_Result[1])else"";hit[i]<-("Is_Hit"%in%names(r)&&lb_safe_num(r$Is_Hit[1],0)>0)||res%in%c("Single","Double","Triple","Home Run");bbhbp[i]<-("Is_BB"%in%names(r)&&lb_safe_num(r$Is_BB[1],0)>0)||("Is_HBP"%in%names(r)&&lb_safe_num(r$Is_HBP[1],0)>0)||res%in%c("Walk","Hit By Pitch");rbi[i]<-"Runs_Batted_In"%in%names(r)&&lb_safe_num(r$Runs_Batted_In[1],0)>0;barrel[i]<-FALSE;off[i]<-("Is_Offensive_Play"%in%names(r)&&lb_safe_num(r$Is_Offensive_Play[1],0)>0)||res%in%c("Sac Fly","Sac Bunt");move3[i]<-"Move_Runner_3rd_LT2"%in%names(r)&&lb_safe_num(r$Move_Runner_3rd_LT2[1],0)>0;err[i]<-res=="Reached on Error";if(nrow(pitches)>0&&"PA_ID"%in%names(pitches)){z<-pitches[as.character(pitches$PA_ID)==ids[i],,drop=FALSE];eight[i]<-nrow(z)>=8;if(nrow(z)>0&&"Contact_Quality"%in%names(z))barrel[i]<-any(as.character(z$Contact_Quality)=="Hard",na.rm=TRUE);if(nrow(z)>0&&"Strikes_Before"%in%names(z))four2k[i]<-sum(suppressWarnings(as.numeric(z$Strikes_Before))>=2,na.rm=TRUE)>=4};out[i]<-any(c(hit[i],bbhbp[i],rbi[i],eight[i],four2k[i],barrel[i],off[i],move3[i],err[i]))};list(PA=nrow(pa),QUABs=sum(out),QUAB_Pct=mean(out),Hit=sum(hit),BBHBP=sum(bbhbp),RBI=sum(rbi),EightPitch=sum(eight),FourAfter2K=sum(four2k),Barrel=sum(barrel),Offensive=sum(off),MoveThird=sum(move3),Error=sum(err))}
  
  lb_hitter_rows<-reactive({
    p<-leaderboard_pitches();pa<-leaderboard_pas()
    ids<-unique(c(if(nrow(p)>0&&"Batter_ID"%in%names(p))as.character(p$Batter_ID)else character(0),if(nrow(pa)>0&&"Batter_ID"%in%names(pa))as.character(pa$Batter_ID)else character(0)))
    ids<-ids[!is.na(ids)&ids!=""];if(length(ids)==0)return(data.frame())
    do.call(rbind,lapply(ids,function(id){
      pd<-if(nrow(p)>0&&"Batter_ID"%in%names(p))p[as.character(p$Batter_ID)==id,,drop=FALSE]else data.frame()
      ad<-if(nrow(pa)>0&&"Batter_ID"%in%names(pa))pa[as.character(pa$Batter_ID)==id,,drop=FALSE]else data.frame()
      g<-tryCatch(summarize_player_grades(pd),error=function(e)NULL);m<-tryCatch(summarize_decision_metrics(pd),error=function(e)NULL)
      n<-nrow(ad);ab<-lb_sum_col(ad,"Is_AB");hits<-lb_sum_col(ad,"Is_Hit");tb<-lb_sum_col(ad,"Bases_Total");bb<-lb_sum_col(ad,"Is_BB");hbp<-lb_sum_col(ad,"Is_HBP");sf<-lb_sum_col(ad,"Is_SF");so<-lb_sum_col(ad,"Is_K");rbi<-lb_sum_col(ad,"Runs_Batted_In")
      avg<-lb_rate(hits,ab);obp<-lb_rate(hits+bb+hbp,ab+bb+hbp+sf);slg<-lb_rate(tb,ab);ops<-if(is.finite(obp)&&is.finite(slg))obp+slg else NA_real_
      res<-if(nrow(ad)>0&&"PA_Result"%in%names(ad))as.character(ad$PA_Result)else character(0);hr<-sum(res=="Home Run",na.rm=TRUE);babip<-lb_rate(hits-hr,ab-so-hr+sf)
      q<-lb_quab_summary(ad,pd)
      cm<-NA_real_
      if(nrow(pd)>0&&all(c("Pitch_Result","Contact_Modifier")%in%names(pd))){zz<-suppressWarnings(as.numeric(pd$Contact_Modifier));kk<-as.character(pd$Pitch_Result)=="In Play"&is.finite(zz);if(any(kk))cm<-mean(zz[kk],na.rm=TRUE)}
      data.frame(Player_ID=id,Player=lb_name(id),
                 Overall_Grade=safe_first_numeric(g,"Overall_Grade"),Pre2K_Grade=safe_first_numeric(g,"Pre2K_Grade"),TwoK_Grade=safe_first_numeric(g,"TwoK_Grade"),Decision_Quality=safe_first_numeric(g,"Overall_Grade"),
                 Swing_Pct=lb_normalize_pct(safe_first_numeric(m,"Overall_Swing_Pct")),Heart_Swing_Pct=lb_normalize_pct(safe_first_numeric(m,"Heart_Swing_Pct")),Chase_Pct=lb_normalize_pct(safe_first_numeric(m,"Chase_Pct")),Whiff_Pct=lb_normalize_pct(safe_first_numeric(m,"Whiff_Pct")),Contact_Pct=lb_normalize_pct(safe_first_numeric(m,"Contact_Pct")),Hard_Contact_Pct=lb_normalize_pct(safe_first_numeric(m,"Hard_Contact_Pct")),Contact_Quality_Score=cm,
                 PA=n,AB=ab,Hits=hits,AVG=avg,OBP=obp,SLG=slg,OPS=ops,SO=so,BB=bb,HBP=hbp,RBI=rbi,K_Pct=lb_rate(so,n),BB_Pct=lb_rate(bb,n),BABIP=babip,
                 QUABs=q$QUABs,QUAB_Pct=q$QUAB_Pct,QUAB_Hit=q$Hit,QUAB_BBHBP=q$BBHBP,QUAB_RBI=q$RBI,QUAB_8Pitch=q$EightPitch,QUAB_4After2K=q$FourAfter2K,QUAB_Barrel=q$Barrel,QUAB_Offensive=q$Offensive,QUAB_MoveThird=q$MoveThird,QUAB_Error=q$Error,stringsAsFactors=FALSE)
    }))
  })
  
  lb_pitcher_rows<-reactive({
    p<-leaderboard_pitches();pa<-leaderboard_pas();if(nrow(p)==0||!"Pitcher_ID"%in%names(p))return(data.frame())
    ids<-unique(as.character(p$Pitcher_ID));ids<-ids[!is.na(ids)&ids!=""]
    mr<-Filter(Negate(is.null),lapply(ids,function(id){m<-p_metrics_from_data(p[as.character(p$Pitcher_ID)==id,,drop=FALSE]);if(is.null(m))return(NULL);data.frame(Player_ID=id,FPS_Pct=m$fps,Strike_Pct=m$strike,Zone_Pct=m$zone,Whiff_Pct=m$whiff,Chase_Pct=m$chase,Ahead_Pct=m$ahead,Behind_Pct=m$behind,Early_Contact_Pct=m$early_contact,Efficient_Inning_Pct=m$eff,Avg_Pitches_Inning=m$api,stringsAsFactors=FALSE)}))
    if(length(mr)==0)return(data.frame());met<-do.call(rbind,mr);mn<-setdiff(names(met),"Player_ID");staff<-lapply(mn,function(nm){x<-suppressWarnings(as.numeric(met[[nm]]));x<-x[is.finite(x)];if(length(x)==0)NA_real_ else mean(x)});names(staff)<-mn
    do.call(rbind,lapply(seq_len(nrow(met)),function(i){
      r<-met[i,,drop=FALSE];command<-p_mean_grade(c(p_staff_grade_component(r$FPS_Pct,staff$FPS_Pct,TRUE),p_staff_grade_component(r$Strike_Pct,staff$Strike_Pct,TRUE),p_staff_grade_component(r$Zone_Pct,staff$Zone_Pct,TRUE),p_staff_grade_component(r$Behind_Pct,staff$Behind_Pct,FALSE)));miss<-p_mean_grade(c(p_staff_grade_component(r$Whiff_Pct,staff$Whiff_Pct,TRUE),p_staff_grade_component(r$Chase_Pct,staff$Chase_Pct,TRUE)));eff<-p_mean_grade(c(p_staff_grade_component(r$Ahead_Pct,staff$Ahead_Pct,TRUE),p_staff_grade_component(r$Early_Contact_Pct,staff$Early_Contact_Pct,TRUE),p_staff_grade_component(r$Efficient_Inning_Pct,staff$Efficient_Inning_Pct,TRUE)));overall<-p_mean_grade(c(command,miss,eff))
      id<-as.character(r$Player_ID);pd<-p[as.character(p$Pitcher_ID)==id,,drop=FALSE];ad<-if(nrow(pa)>0&&"Pitcher_ID"%in%names(pa))pa[as.character(pa$Pitcher_ID)==id,,drop=FALSE]else data.frame()
      bf<-nrow(ad);k<-lb_sum_col(ad,"Is_K");bb<-lb_sum_col(ad,"Is_BB");hbp<-lb_sum_col(ad,"Is_HBP");hits<-lb_sum_col(ad,"Is_Hit");ab<-lb_sum_col(ad,"Is_AB");sf<-lb_sum_col(ad,"Is_SF");tb<-lb_sum_col(ad,"Bases_Total");res<-if(nrow(ad)>0&&"PA_Result"%in%names(ad))as.character(ad$PA_Result)else character(0);hr<-sum(res=="Home Run",na.rm=TRUE)
      cq<-if("Contact_Quality"%in%names(pd))as.character(pd$Contact_Quality)else character(0);cd<-sum(cq%in%c("Hard","Average","Avg","Weak"),na.rm=TRUE);games<-if("Session_ID"%in%names(pd))length(unique(as.character(pd$Session_ID[!is.na(pd$Session_ID)&as.character(pd$Session_ID)!=""])))else NA_real_
      data.frame(Player_ID=id,Player=lb_name(id),Overall_Grade=overall,Command_Grade=command,Miss_Grade=miss,Efficiency_Grade=eff,Pitches=nrow(pd),BF=bf,G=games,K=k,BB=bb,HBP=hbp,HR=hr,FPS_Pct=r$FPS_Pct,Strike_Pct=r$Strike_Pct,Zone_Pct=r$Zone_Pct,Whiff_Pct=r$Whiff_Pct,Chase_Pct=r$Chase_Pct,Ahead_Pct=r$Ahead_Pct,Behind_Pct=r$Behind_Pct,Early_Contact_Pct=r$Early_Contact_Pct,Efficient_Inning_Pct=r$Efficient_Inning_Pct,Avg_Pitches_Inning=r$Avg_Pitches_Inning,K_Pct=lb_rate(k,bf),BB_Pct=lb_rate(bb,bf),KBB_Pct=lb_rate(k-bb,bf),HR_Pct=lb_rate(hr,bf),BABIP=lb_rate(hits-hr,ab-k-hr+sf),Opp_AVG=lb_rate(hits,ab),Opp_OBP=lb_rate(hits+bb+hbp,ab+bb+hbp+sf),Opp_SLG=lb_rate(tb,ab),Hard_Contact_Pct=lb_rate(sum(cq=="Hard",na.rm=TRUE),cd),Medium_Contact_Pct=lb_rate(sum(cq%in%c("Average","Avg"),na.rm=TRUE),cd),Soft_Contact_Pct=lb_rate(sum(cq=="Weak",na.rm=TRUE),cd),stringsAsFactors=FALSE)
    }))
  })
  
  lb_rows<-reactive({if(identical(input$leaderboard_type,"Pitcher"))lb_pitcher_rows()else lb_hitter_rows()})
  lb_higher<-function(metric){
    lower<-c("Chase_Pct","Whiff_Pct","K_Pct","Behind_Pct","Avg_Pitches_Inning","BB_Pct","HR_Pct","Opp_AVG","Opp_OBP","Opp_SLG","Hard_Contact_Pct","Medium_Contact_Pct")
    if(identical(input$leaderboard_type,"Pitcher"))lower<-setdiff(lower,c("Whiff_Pct","Chase_Pct"))
    !metric%in%lower
  }
  lb_team_avg<-function(df,metric){if(nrow(df)==0||!metric%in%names(df))return(NA_real_);x<-suppressWarnings(as.numeric(df[[metric]]));x<-x[is.finite(x)];if(length(x)==0)NA_real_ else mean(x)}
  lb_class<-function(v,a,m){v<-suppressWarnings(as.numeric(v));a<-suppressWarnings(as.numeric(a));if(!is.finite(v)||!is.finite(a))return("leaderboard-neutral");tol<-if(grepl("Grade$",m))2 else .02;d<-if(lb_higher(m))v-a else a-v;if(d>tol)"leaderboard-good"else if(d< -tol)"leaderboard-poor"else"leaderboard-average"}
  lb_display<-function(m,v){
    if(m%in%c("Overall_Grade","Pre2K_Grade","TwoK_Grade","Decision_Quality","Command_Grade","Miss_Grade","Efficiency_Grade"))return(lb_grade_fmt(v))
    if(m%in%c("AVG","OBP","SLG","OPS","BABIP","Opp_AVG","Opp_OBP","Opp_SLG"))return(lb_avg_fmt(v))
    if(m=="Contact_Quality_Score"){v<-suppressWarnings(as.numeric(v));return(if(!is.finite(v))"N/A"else paste0(ifelse(v>0,"+",""),sprintf("%.2f",v)))}
    counts<-c("PA","AB","Hits","SO","BB","HBP","RBI","Pitches","BF","G","K","HR","QUABs","QUAB_Hit","QUAB_BBHBP","QUAB_RBI","QUAB_8Pitch","QUAB_4After2K","QUAB_Barrel","QUAB_Offensive","QUAB_MoveThird","QUAB_Error")
    if(m%in%counts){v<-suppressWarnings(as.numeric(v));return(if(!is.finite(v))"0"else as.character(as.integer(round(v))))}
    if(m=="Avg_Pitches_Inning"){v<-suppressWarnings(as.numeric(v));return(if(!is.finite(v))"N/A"else sprintf("%.1f",v))}
    lb_pct(v)
  }
  leaderboard_sort_best_first<-reactiveVal(TRUE)
  observeEvent(input$leaderboard_rank_metric,{leaderboard_sort_best_first(TRUE)},ignoreInit=TRUE)
  observeEvent(input$leaderboard_sort_toggle,{leaderboard_sort_best_first(!leaderboard_sort_best_first())},ignoreInit=TRUE)
  
  lb_sorted<-reactive({
    df<-lb_rows();if(nrow(df)==0)return(df);m<-input$leaderboard_rank_metric
    if(is.null(m)||!m%in%names(df))m<-if("Overall_Grade"%in%names(df))"Overall_Grade"else names(df)[1]
    x<-suppressWarnings(as.numeric(df[[m]]));besthigh<-lb_higher(m);bestfirst<-leaderboard_sort_best_first();ascending<-if(bestfirst)!besthigh else besthigh
    o<-if(ascending)x else -x;o[!is.finite(o)]<-Inf;df<-df[order(o,df$Player),,drop=FALSE];rownames(df)<-NULL;df
  })
  
  output$leaderboard_quab_definition<-renderUI({if(!identical(input$leaderboard_type,"Hitter")||!input$leaderboard_rank_metric%in%c("QUAB_Pct","QUABs","QUAB_8Pitch","QUAB_4After2K","QUAB_Barrel","QUAB_Offensive","QUAB_MoveThird","QUAB_Error"))return(NULL);div(class="leaderboard-quab-card",tags$strong("QUAB = Quality At-Bat. "),"A plate appearance counts as one QUAB when it meets at least one of the following: Hit • Walk/HBP • RBI • 8+ pitch PA • 4+ pitches after reaching two strikes • Barrel • any successful offensive play • move a runner to third with fewer than two outs • reach base on an error.",div(class="leaderboard-note","A PA can satisfy multiple criteria, but it counts as only one QUAB. QUAB % = QUABs ÷ plate appearances. Barrel is defined here as any ball charted with Hard contact. Successful-offensive-play and runner-to-third remain manual context tags."))})
  output$leaderboard_table_title<-renderText({
    ch<-if(identical(input$leaderboard_type,"Pitcher"))lb_pitcher_metric_choices else lb_hitter_metric_choices
    m<-input$leaderboard_rank_metric;lab<-names(ch)[match(m,unname(ch))];if(length(lab)==0||is.na(lab))lab<-m
    paste0(lab," Leaderboard")
  })
  lb_link<-function(id,name,type){idj<-gsub("'","\\\\'",as.character(id));tpj<-gsub("'","\\\\'",as.character(type));tags$a(class="leaderboard-player-link",href="#",onclick=paste0("Shiny.setInputValue('leaderboard_open_player','",tpj,"|",idj,"',{priority:'event'}); return false;"),name)}
  output$leaderboard_table<-renderUI({
    df<-lb_sorted();if(nrow(df)==0)return(div(class="report-breakdown-note","No leaderboard data is available for the selected filters."))
    m<-input$leaderboard_rank_metric;if(is.null(m)||!m%in%names(df))m<-"Overall_Grade"
    ch<-if(identical(input$leaderboard_type,"Pitcher"))lb_pitcher_metric_choices else lb_hitter_metric_choices
    lab<-names(ch)[match(m,unname(ch))];if(length(lab)==0||is.na(lab))lab<-m
    best<-leaderboard_sort_best_first();icon<-if(best)"  ⇅ Best → Worst"else"  ⇅ Worst → Best";a<-lb_team_avg(df,m)
    body<-lapply(seq_len(nrow(df)),function(i){r<-df[i,,drop=FALSE];v<-r[[m]][1];tags$tr(tags$td(class="leaderboard-rank",i),tags$td(lb_link(r$Player_ID,r$Player,input$leaderboard_type)),tags$td(class=lb_class(v,a,m),lb_display(m,v)))})
    hdr<-tags$a(href="#",style="color:#A7191F;text-decoration:none;font-weight:900;",onclick="Shiny.setInputValue('leaderboard_sort_toggle', Date.now(), {priority:'event'}); return false;",paste0(lab,icon))
    tags$table(class="table table-striped table-condensed leaderboard-table",tags$thead(tags$tr(tags$th("Rank"),tags$th("Player"),tags$th(hdr))),tags$tbody(body))
  })
  
  output$leaderboard_podium<-renderUI({df<-lb_sorted();if(nrow(df)==0)return(div(class="report-breakdown-note","No rankings available."));m<-input$leaderboard_rank_metric;if(is.null(m)||!m%in%names(df))m<-"Overall_Grade";top<-head(df,3);cards<-lapply(seq_len(nrow(top)),function(i){r<-top[i,,drop=FALSE];div(class="leaderboard-podium-place",div(class="leaderboard-podium-rank",paste0("#",i)),div(class="leaderboard-podium-name",lb_link(r$Player_ID,r$Player,input$leaderboard_type)),div(class="leaderboard-podium-value",lb_display(m,r[[m]][1])))});div(class="leaderboard-podium-grid",cards)})
  observeEvent(input$leaderboard_open_player,{x<-as.character(input$leaderboard_open_player);parts<-strsplit(x,"\\|")[[1]];if(length(parts)<2)return();tp<-parts[1];id<-paste(parts[-1],collapse="|");if(identical(tp,"Pitcher")){updateSelectInput(session,"pitcher_report_pitcher",selected=id);session$sendCustomMessage("leaderboardNavigate",list(tab="Pitcher Report",sidebar="PITCHER REPORTS"))}else{updateSelectInput(session,"report_batter",selected=id);session$sendCustomMessage("leaderboardNavigate",list(tab="Hitter Report",sidebar="HITTER'S REPORTS"))}})
  observeEvent(input$leaderboard_refresh,{refresh_sessions_admin_data();load_sessions(select_session_id=current_session_id());load_pitcher_report_data();load_report_pitches()})
  
  # ==================================================
  # PITCHER REPORT - BULLPEN PROGRESS
  # ==================================================
  
  observe({
    d<-bullpen_valid_rows(pitcher_report_pitches_raw())
    id<-input$pitcher_report_pitcher
    choices<-c("All Bullpens (Cumulative)"="ALL")
    if(nrow(d)>0&&!is.null(id)&&id!=""&&all(c("Pitcher_ID","Session_ID")%in%names(d))) {
      z<-d[as.character(d$Pitcher_ID)==as.character(id),,drop=FALSE]
      if(nrow(z)>0) {
        sids<-unique(as.character(z$Session_ID))
        sids<-sids[!is.na(sids)&sids!=""]
        sl<-session_lookup()
        for(sid in sids) {
          label<-sid
          if(nrow(sl)>0&&"Session_ID"%in%names(sl)) {
            row<-sl[as.character(sl$Session_ID)==sid,,drop=FALSE]
            if(nrow(row)>0) {
              nm<-if("Session_Name"%in%names(row))as.character(row$Session_Name[1])else""
              dt<-if("Session_Date"%in%names(row))as.character(row$Session_Date[1])else""
              if(nm!=""||dt!="")label<-paste(trimws(paste(dt,nm)),collapse=" ")
            }
          }
          choices[label]<-sid
        }
      }
    }
    cur<-isolate(input$pitcher_bullpen_session)
    if(is.null(cur)||!cur%in%unname(choices))cur<-"ALL"
    updateSelectInput(session,"pitcher_bullpen_session",choices=choices,selected=cur)
  })
  
  bullpen_valid_rows <- function(d) {
    if(is.null(d) || nrow(d)==0) return(data.frame())
    
    required <- c(
      "Charting_Mode","Pitcher_ID","Session_ID",
      "Pitch_Type","Pitch_Result","Location_X","Location_Y",
      "Bullpen_Target_X","Bullpen_Target_Y"
    )
    
    if(!all(required %in% names(d))) return(data.frame())
    
    # googlesheets4 can return newly-created / mostly-empty columns as list
    # columns. Normalize every bullpen field to a simple atomic vector before
    # filtering or doing numeric math so opening Pitcher Reports cannot crash.
    safe_chr <- function(x) {
      vapply(
        seq_along(x),
        function(i) {
          z <- x[[i]]
          if(is.null(z) || length(z)==0 || all(is.na(z))) return(NA_character_)
          z <- z[!is.na(z)]
          if(length(z)==0) return(NA_character_)
          as.character(z[[1]])
        },
        character(1)
      )
    }
    
    safe_num <- function(x) {
      vapply(
        seq_along(x),
        function(i) {
          z <- x[[i]]
          if(is.null(z) || length(z)==0 || all(is.na(z))) return(NA_real_)
          z <- z[!is.na(z)]
          if(length(z)==0) return(NA_real_)
          suppressWarnings(as.numeric(as.character(z[[1]])))
        },
        numeric(1)
      )
    }
    
    mode <- trimws(safe_chr(d$Charting_Mode))
    pitcher <- trimws(safe_chr(d$Pitcher_ID))
    session_id <- trimws(safe_chr(d$Session_ID))
    pitch_type <- trimws(safe_chr(d$Pitch_Type))
    result <- trimws(safe_chr(d$Pitch_Result))
    
    x <- safe_num(d$Location_X)
    y <- safe_num(d$Location_Y)
    target_x <- safe_num(d$Bullpen_Target_X)
    target_y <- safe_num(d$Bullpen_Target_Y)
    
    # Store the normalized values back into the frame so every downstream
    # bullpen calculation receives ordinary character/numeric columns.
    d$Charting_Mode <- mode
    d$Pitcher_ID <- pitcher
    d$Session_ID <- session_id
    d$Pitch_Type <- pitch_type
    d$Pitch_Result <- result
    d$Location_X <- x
    d$Location_Y <- y
    d$Bullpen_Target_X <- target_x
    d$Bullpen_Target_Y <- target_y
    
    keep <-
      !is.na(mode) & mode=="Bullpen" &
      !is.na(pitcher) & pitcher!="" &
      !is.na(session_id) & session_id!="" &
      !is.na(pitch_type) & pitch_type!="" & pitch_type!="None" &
      result %in% c("Ball","Called Strike","Strike") &
      is.finite(x) & is.finite(y) &
      is.finite(target_x) & is.finite(target_y)
    
    d[keep,,drop=FALSE]
  }
  
  
  
  observe({
    d<-bullpen_history_data()
    
    # Pitch-type choices are based on the currently selected pitcher's bullpen history.
    pts<-if(nrow(d)>0&&"Pitch_Type"%in%names(d)){
      sort(unique(trimws(as.character(d$Pitch_Type))))
    } else character(0)
    pts<-pts[!is.na(pts)&pts!=""&pts!="None"]
    pt_choices<-c("All Pitches"="ALL")
    if(length(pts)>0){
      x<-pts
      names(x)<-pts
      pt_choices<-c(pt_choices,x)
    }
    cur_pt<-isolate(input$pitcher_bullpen_plot_pitch_type)
    if(is.null(cur_pt)||!cur_pt%in%unname(pt_choices))cur_pt<-"ALL"
    updateSelectInput(session,"pitcher_bullpen_plot_pitch_type",choices=pt_choices,selected=cur_pt)
    
    # Session comparison choices.
    h<-bullpen_session_history()
    if(nrow(h)==0){
      updateSelectInput(session,"pitcher_bullpen_compare_a",choices=c("Select Session"=""),selected="")
      updateSelectInput(session,"pitcher_bullpen_compare_b",choices=c("Select Session"=""),selected="")
      return()
    }
    
    vals<-as.character(h$Session_ID)
    labs<-as.character(h$Label)
    choices<-vals
    names(choices)<-labs
    choices<-c("Select Session"="",choices)
    
    cur_a<-isolate(input$pitcher_bullpen_compare_a)
    cur_b<-isolate(input$pitcher_bullpen_compare_b)
    
    if(is.null(cur_a)||!cur_a%in%vals){
      cur_a<-if(nrow(h)>=2)as.character(h$Session_ID[nrow(h)-1])else as.character(h$Session_ID[nrow(h)])
    }
    if(is.null(cur_b)||!cur_b%in%vals){
      cur_b<-as.character(h$Session_ID[nrow(h)])
    }
    
    updateSelectInput(session,"pitcher_bullpen_compare_a",choices=choices,selected=cur_a)
    updateSelectInput(session,"pitcher_bullpen_compare_b",choices=choices,selected=cur_b)
  })
  
  
  pitcher_bullpen_data <- reactive({
    d<-bullpen_valid_rows(pitcher_report_pitches_raw())
    id<-input$pitcher_report_pitcher
    
    if(
      nrow(d)==0 ||
      is.null(id) ||
      id=="" ||
      !"Pitcher_ID"%in%names(d)
    ) return(data.frame())
    
    d<-d[
      as.character(d$Pitcher_ID)==as.character(id),
      ,
      drop=FALSE
    ]
    
    sid<-input$pitcher_bullpen_session
    if(!is.null(sid)&&sid!=""&&sid!="ALL"&&"Session_ID"%in%names(d)){
      d<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
    }
    
    # Apply pitcher-report date range using session dates.
    sd<-p_session_dates()
    if(nrow(sd)>0&&"Session_ID"%in%names(d)){
      d$Session_ID<-as.character(d$Session_ID)
      d<-merge(d,sd,by="Session_ID",all.x=TRUE,sort=FALSE)
      rg<-input$pitcher_report_date_range
      if(!is.null(rg)&&length(rg)==2&&!is.na(rg[1])&&!is.na(rg[2])){
        d<-d[
          is.na(d$Session_Date_Report) |
            (d$Session_Date_Report>=as.Date(rg[1])&d$Session_Date_Report<=as.Date(rg[2])),
          ,
          drop=FALSE
        ]
      }
    }
    
    d
  })
  
  
  pitcher_bullpen_metrics <- reactive({
    d<-pitcher_bullpen_data()
    if(nrow(d)==0)return(NULL)
    
    strike<-as.character(d$Pitch_Result)%in%c("Called Strike","Strike")
    zone<-if("Zone_Group"%in%names(d)){
      as.character(d$Zone_Group)%in%c("Heart","Shadow")
    } else rep(FALSE,nrow(d))
    
    target_hit<-rep(NA,nrow(d))
    miss_distance<-rep(NA_real_,nrow(d))
    
    if(all(c("Location_X","Location_Y","Bullpen_Target_X","Bullpen_Target_Y")%in%names(d))){
      for(i in seq_len(nrow(d))){
        target_hit[i]<-bullpen_target_hit(
          d$Location_X[i],
          d$Location_Y[i],
          d$Bullpen_Target_X[i],
          d$Bullpen_Target_Y[i]
        )
        miss_distance[i]<-bullpen_miss_inches(
          d$Location_X[i],
          d$Location_Y[i],
          d$Bullpen_Target_X[i],
          d$Bullpen_Target_Y[i]
        )
      }
    }
    
    strike_pct<-mean(strike,na.rm=TRUE)
    zone_pct<-mean(zone,na.rm=TRUE)
    target_pct<-if(any(!is.na(target_hit)))mean(target_hit,na.rm=TRUE)else NA_real_
    avg_miss<-if(any(is.finite(miss_distance)))mean(miss_distance,na.rm=TRUE)else NA_real_
    miss_score<-bullpen_miss_distance_score(avg_miss)
    
    # Bullpen Command Grade:
    # 50% Target Execution % (within 13 inches)
    # 25% Avg Miss Distance Score
    # 15% Zone %
    # 10% Strike %
    command_grade <- bullpen_command_grade_value(
      target_pct,
      avg_miss,
      zone_pct,
      strike_pct
    )
    
    list(
      pitches=nrow(d),
      command_grade=command_grade,
      strike=strike_pct,
      zone=zone_pct,
      target_hit=target_pct,
      avg_miss=avg_miss,
      miss_score=miss_score
    )
  })
  
  
  output$pitcher_bullpen_relative_note<-renderUI({
    HTML(paste0("Every catcher target is recentered to 0,0. Positive horizontal = arm-side; negative = glove-side. The ",
                sprintf("%.1f",setting_num("Bullpen_Target_Execution_In",13)),
                "-inch circle is the Target Execution boundary."))
  })
  output$pitcher_bullpen_direction_note<-renderUI({
    HTML(paste0("Direction of pitches that finish outside the ",
                sprintf("%.1f",setting_num("Bullpen_Target_Execution_In",13)),
                "-inch Target Execution radius. Arm/glove side is adjusted for pitcher handedness."))
  })
  
  output$pitcher_bullpen_explainer<-renderUI({
    radius<-setting_num("Bullpen_Target_Execution_In",13)
    ref<-setting_num("Bullpen_MLB_Reference_In",12)
    w<-c(setting_num("Bullpen_Weight_Target",.50),setting_num("Bullpen_Weight_Miss",.25),
         setting_num("Bullpen_Weight_Zone",.15),setting_num("Bullpen_Weight_Strike",.10))
    if(any(!is.finite(w))||sum(w)<=0)w<-c(.50,.25,.15,.10)
    w<-100*w/sum(w)
    HTML(paste0("<strong>Bullpen Command Grade:</strong> ",sprintf("%.0f",w[1]),"% Target Execution + ",
                sprintf("%.0f",w[2]),"% Avg Miss Distance + ",sprintf("%.0f",w[3]),"% Zone % + ",
                sprintf("%.0f",w[4]),"% Strike %. <strong>Target Execution</strong> = pitches within ",
                sprintf("%.1f",radius)," inches of the catcher target. <strong>Avg Miss Distance</strong> uses ",
                sprintf("%.1f",ref)," inches as the MLB-average reference (70 Miss Score). ",
                "Miss Direction only classifies pitches outside the execution radius. Bullpen data remains separate from live/game results."))
  })
  
  output$pitcher_bullpen_banner<-renderUI({
    d<-pitcher_bullpen_data()
    
    if(nrow(d)==0){
      return(
        div(
          class="bullpen-session-banner",
          "No bullpen pitches are available for the selected pitcher / session / date range."
        )
      )
    }
    
    focus<-""
    if("Bullpen_Focus"%in%names(d)){
      f<-unique(trimws(as.character(d$Bullpen_Focus)))
      f<-f[!is.na(f)&f!=""]
      if(length(f)>0)focus<-paste0(" • Focus: ",paste(f,collapse=" / "))
    }
    
    div(
      class="bullpen-session-banner",
      paste0(nrow(d)," bullpen pitches in the current filters",focus)
    )
  })
  
  
  output$pitcher_bullpen_kpis<-renderUI({
    x<-pitcher_bullpen_metrics()
    
    card<-function(label,value){
      div(
        class="bullpen-progress-card",
        div(class="bullpen-progress-label",label),
        div(class="bullpen-progress-value",value)
      )
    }
    
    if(is.null(x)){
      return(
        tagList(
          card("Pitches","0"),
          card("Bullpen Command Grade","N/A"),
          card("Strike %","N/A"),
          card("Zone %","N/A"),
          card("Target Execution %","N/A"),
          card("Avg Miss Distance","N/A")
        )
      )
    }
    
    grade<-if(is.finite(x$command_grade)){
      paste0(grade_letter(x$command_grade)," ",sprintf("%.1f",x$command_grade))
    } else "N/A"
    
    miss<-if(is.finite(x$avg_miss)){
      paste0(sprintf("%.2f",x$avg_miss)," in")
    } else "N/A"
    
    tagList(
      card("Pitches",x$pitches),
      card("Bullpen Command Grade",grade),
      card("Strike %",p_pct(x$strike)),
      card("Zone %",p_pct(x$zone)),
      card("Target Execution %",p_pct(x$target_hit)),
      card("Avg Miss Distance",miss)
    )
  })
  
  
  
  # --------------------------------------------------
  # BULLPEN TARGET VS ACTUAL
  # --------------------------------------------------
  output$pitcher_bullpen_target_actual_plot<-renderPlot({
    d<-bullpen_pitchtype_filter_frame(pitcher_bullpen_data())
    if(nrow(d)==0){
      bullpen_plot_empty("No bullpen pitches in the current filters.")
      return()
    }
    
    req<-c("Location_X","Location_Y","Bullpen_Target_X","Bullpen_Target_Y")
    if(!all(req%in%names(d))){
      bullpen_plot_empty("Target / actual location data is unavailable.")
      return()
    }
    
    ax<-suppressWarnings(as.numeric(d$Location_X))
    ay<-suppressWarnings(as.numeric(d$Location_Y))
    tx<-suppressWarnings(as.numeric(d$Bullpen_Target_X))
    ty<-suppressWarnings(as.numeric(d$Bullpen_Target_Y))
    keep<-is.finite(ax)&is.finite(ay)&is.finite(tx)&is.finite(ty)
    
    if(!any(keep)){
      bullpen_plot_empty("No valid target / actual locations.")
      return()
    }
    
    ax<-ax[keep];ay<-ay[keep];tx<-tx[keep];ty<-ty[keep]
    
    par(mar=c(4,4,2,1))
    plot(
      NA,
      xlim=c(0.18,0.82),
      ylim=c(0.82,0.18),
      xaxs="i",yaxs="i",
      asp=1,
      xlab="Catcher View — Horizontal Location",
      ylab="Vertical Location",
      axes=FALSE
    )
    axis(1,labels=FALSE,tick=FALSE)
    axis(2,labels=FALSE,tick=FALSE)
    box(col="#bbbbbb")
    
    # Approximate 17x24 inch strike-zone reference using the app's normalized geometry.
    zx1<-0.5-(0.2231/2);zx2<-0.5+(0.2231/2)
    zy1<-0.5-(0.2596/2);zy2<-0.5+(0.2596/2)
    rect(zx1,zy1,zx2,zy2,border="#777777",lwd=2)
    abline(v=0.5,h=0.5,col="#eeeeee",lty=3)
    
    # Connection line, target, actual.
    segments(tx,ty,ax,ay,col=adjustcolor("#777777",alpha.f=.45),lwd=1)
    points(tx,ty,pch=4,cex=1.05,lwd=2,col="#6c3b14")
    points(ax,ay,pch=16,cex=.8,col="#A7191F")
    
    legend(
      "topright",
      legend=c("Catcher Target","Actual Pitch"),
      pch=c(4,16),
      col=c("#6c3b14","#A7191F"),
      bty="n",cex=.78
    )
  },bg="white")
  
  
  # --------------------------------------------------
  # BULLPEN RELATIVE COMMAND HEATMAP
  # --------------------------------------------------
  output$pitcher_bullpen_relative_heatmap<-renderPlot({
    d<-bullpen_pitchtype_filter_frame(pitcher_bullpen_data())
    rel<-bullpen_relative_frame(d)
    
    if(nrow(rel)==0){
      bullpen_plot_empty("No target-relative bullpen data.")
      return()
    }
    
    x<-rel$ArmSide_In
    y<-rel$Up_In
    
    lim<-max(24,quantile(abs(c(x,y)),.96,na.rm=TRUE))
    lim<-min(max(lim,24),40)
    
    # 2D histogram built with base R so no new package is required.
    breaks<-seq(-lim,lim,length.out=24)
    xi<-cut(x,breaks=breaks,include.lowest=TRUE,labels=FALSE)
    yi<-cut(y,breaks=breaks,include.lowest=TRUE,labels=FALSE)
    mat<-matrix(0,nrow=length(breaks)-1,ncol=length(breaks)-1)
    for(i in seq_along(xi)){
      if(is.finite(xi[i])&&is.finite(yi[i])){
        mat[xi[i],yi[i]]<-mat[xi[i],yi[i]]+1
      }
    }
    
    mids<-(breaks[-1]+breaks[-length(breaks)])/2
    pal<-colorRampPalette(c("#ffffff","#f6d6d7","#d8676b","#A7191F"))(30)
    
    par(mar=c(4,4,2,1))
    image(
      mids,mids,mat,
      xlim=c(-lim,lim),ylim=c(-lim,lim),
      col=pal,
      xlab="Glove Side  ←   Inches From Target   →  Arm Side",
      ylab="Down  ←   Inches From Target   →  Up",
      asp=1,
      axes=FALSE
    )
    axis(1)
    axis(2)
    box(col="#bbbbbb")
    abline(h=0,v=0,col="#777777",lty=3)
    
    # Target Execution radius.
    target_radius<-setting_num("Bullpen_Target_Execution_In",13)
    th<-seq(0,2*pi,length.out=240)
    lines(target_radius*cos(th),target_radius*sin(th),lwd=2,col="#222222")
    points(0,0,pch=3,cex=1.2,lwd=2,col="#222222")
    text(0,target_radius+.8,paste0(sprintf("%.1f",target_radius)," in"),cex=.72,font=2)
  },bg="white")
  
  
  # --------------------------------------------------
  # BULLPEN MISS DIRECTION
  # --------------------------------------------------
  bullpen_miss_direction_data<-reactive({
    d<-bullpen_pitchtype_filter_frame(pitcher_bullpen_data())
    rel<-bullpen_relative_frame(d)
    if(nrow(rel)==0)return(data.frame())
    
    rel$Direction<-mapply(
      bullpen_miss_direction,
      rel$ArmSide_In,
      rel$Up_In,
      rel$Miss_In,
      USE.NAMES=FALSE
    )
    
    rel<-rel[
      !is.na(rel$Direction)&rel$Direction!="Executed",
      ,
      drop=FALSE
    ]
    rel
  })
  
  
  output$pitcher_bullpen_miss_direction_plot<-renderPlot({
    rel<-bullpen_miss_direction_data()
    
    if(nrow(rel)==0){
      bullpen_plot_empty(paste0("No misses outside ",setting_num("Bullpen_Target_Execution_In",13)," inches."))
      return()
    }
    
    tab<-sort(table(rel$Direction),decreasing=TRUE)
    pct<-100*as.numeric(tab)/sum(tab)
    
    par(mar=c(8,4,2,1))
    bp<-barplot(
      pct,
      names.arg=names(tab),
      las=2,
      ylim=c(0,max(100,max(pct)*1.18)),
      ylab="% of Misses",
      border=NA,
      col="#A7191F",
      cex.names=.72
    )
    text(bp,pct,labels=paste0(sprintf("%.0f",pct),"%"),pos=3,cex=.72,font=2)
    abline(h=seq(0,100,20),col="#eeeeee",lty=3)
  },bg="white")
  
  
  output$pitcher_bullpen_miss_direction_table<-renderUI({
    rel<-bullpen_miss_direction_data()
    
    if(nrow(rel)==0){
      return(div(class="report-breakdown-note",paste0("Every pitch in the current filters finished within ",setting_num("Bullpen_Target_Execution_In",13)," inches, or there is no valid miss-direction data.")))
    }
    
    tab<-sort(table(rel$Direction),decreasing=TRUE)
    total<-sum(tab)
    
    rows<-lapply(seq_along(tab),function(i){
      tags$tr(
        tags$td(names(tab)[i]),
        tags$td(as.integer(tab[i])),
        tags$td(p_pct(as.numeric(tab[i])/total))
      )
    })
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(tags$tr(tags$th("Direction"),tags$th("Misses"),tags$th("%"))),
      tags$tbody(rows)
    )
  })
  
  
  # --------------------------------------------------
  # BULLPEN PROGRESS OVER TIME
  # --------------------------------------------------
  bullpen_trend_plot<-function(metric,label,pct=FALSE,lower_better=FALSE,reference=NULL){
    h<-bullpen_session_history()
    
    if(nrow(h)==0||!metric%in%names(h)){
      bullpen_plot_empty("No bullpen history.")
      return()
    }
    
    y<-suppressWarnings(as.numeric(h[[metric]]))
    keep<-is.finite(y)
    if(!any(keep)){
      bullpen_plot_empty("No trend data.")
      return()
    }
    
    h<-h[keep,,drop=FALSE]
    y<-y[keep]
    x<-seq_along(y)
    
    if(pct)y<-100*y
    
    if(length(y)==1){
      ylim<-range(c(y-5,y+5),finite=TRUE)
    } else {
      pad<-max(2,diff(range(y,finite=TRUE))*.18)
      ylim<-range(c(y-pad,y+pad),finite=TRUE)
    }
    
    if(!is.null(reference)&&is.finite(reference)){
      ylim<-range(c(ylim,reference),finite=TRUE)
    }
    
    par(mar=c(4,4,1,1))
    plot(
      x,y,type="o",pch=16,lwd=2,
      col="#A7191F",
      xaxt="n",
      xlab="Bullpen Session",
      ylab=label,
      ylim=ylim
    )
    
    axis(1,at=x,labels=format(h$Date,"%m/%d"),cex.axis=.72)
    grid(col="#eeeeee")
    
    if(!is.null(reference)&&is.finite(reference)){
      abline(h=reference,lty=2,col="#777777")
    }
    
    # Display the most recent value.
    last<-length(y)
    lab<-if(pct)paste0(sprintf("%.1f",y[last]),"%")else sprintf("%.1f",y[last])
    text(x[last],y[last],labels=lab,pos=3,cex=.72,font=2)
  }
  
  output$pitcher_bullpen_command_trend<-renderPlot({
    bullpen_trend_plot("Command","Grade",pct=FALSE,reference=70)
  },bg="white")
  
  output$pitcher_bullpen_target_trend<-renderPlot({
    bullpen_trend_plot("Target","Target Execution %",pct=TRUE)
  },bg="white")
  
  output$pitcher_bullpen_miss_trend<-renderPlot({
    bullpen_trend_plot("AvgMiss","Avg Miss (in)",pct=FALSE,lower_better=TRUE,reference=12)
  },bg="white")
  
  output$pitcher_bullpen_strike_trend<-renderPlot({
    bullpen_trend_plot("Strike","Strike %",pct=TRUE)
  },bg="white")
  
  
  # --------------------------------------------------
  # BULLPEN SESSION COMPARISON
  # --------------------------------------------------
  output$pitcher_bullpen_comparison<-renderUI({
    d<-bullpen_history_data()
    a<-input$pitcher_bullpen_compare_a
    b<-input$pitcher_bullpen_compare_b
    
    if(
      nrow(d)==0 ||
      is.null(a)||is.null(b) ||
      a==""||b==""
    ){
      return(div(class="report-breakdown-note","Choose two bullpen sessions to compare."))
    }
    
    za<-d[as.character(d$Session_ID)==as.character(a),,drop=FALSE]
    zb<-d[as.character(d$Session_ID)==as.character(b),,drop=FALSE]
    sa<-bullpen_session_summary(za)
    sb<-bullpen_session_summary(zb)
    
    if(is.null(sa)||is.null(sb)){
      return(div(class="report-breakdown-note","One of the selected sessions does not have enough valid target / actual pitch data."))
    }
    
    delta_class<-function(delta,higher_better=TRUE){
      if(!is.finite(delta)||abs(delta)<1e-9)return("bullpen-delta-neutral")
      good<-if(higher_better)delta>0 else delta<0
      if(good)"bullpen-delta-good"else"bullpen-delta-bad"
    }
    
    delta_fmt<-function(delta,suffix="",digits=1){
      if(!is.finite(delta))return("—")
      paste0(if(delta>0)"+","",sprintf(paste0("%.",digits,"f"),delta),suffix)
    }
    
    compare_card<-function(label,b_value,delta,higher_better=TRUE,suffix="",digits=1){
      div(
        class="bullpen-compare-card",
        div(class="bullpen-compare-label",label),
        div(class="bullpen-compare-value",b_value),
        div(
          class=paste("bullpen-compare-delta",delta_class(delta,higher_better)),
          paste0("Δ ",delta_fmt(delta,suffix,digits))
        )
      )
    }
    
    labels<-bullpen_session_label_map()
    la<-if(a%in%names(labels))unname(labels[a])else a
    lb<-if(b%in%names(labels))unname(labels[b])else b
    
    dg<-sb$command_grade-sa$command_grade
    dt<-100*(sb$target_hit-sa$target_hit)
    dm<-sb$avg_miss-sa$avg_miss
    ds<-100*(sb$strike-sa$strike)
    
    tagList(
      div(
        class="bullpen-session-banner",
        paste0("Session A: ",la,"   |   Session B: ",lb,"   |   Change = B − A")
      ),
      div(
        class="bullpen-comparison-summary",
        compare_card(
          "Command Grade",
          if(is.finite(sb$command_grade))sprintf("%.1f",sb$command_grade)else"N/A",
          dg,TRUE,"",1
        ),
        compare_card(
          "Target Execution %",
          p_pct(sb$target_hit),
          dt,TRUE," pts",1
        ),
        compare_card(
          "Avg Miss Distance",
          if(is.finite(sb$avg_miss))paste0(sprintf("%.1f",sb$avg_miss)," in")else"N/A",
          dm,FALSE," in",1
        ),
        compare_card(
          "Strike %",
          p_pct(sb$strike),
          ds,TRUE," pts",1
        )
      ),
      tags$table(
        class="table table-striped table-condensed",
        tags$thead(
          tags$tr(
            tags$th("Metric"),
            tags$th("Session A"),
            tags$th("Session B"),
            tags$th("Change")
          )
        ),
        tags$tbody(
          tags$tr(tags$td("Pitches"),tags$td(sa$pitches),tags$td(sb$pitches),tags$td(sb$pitches-sa$pitches)),
          tags$tr(tags$td("Command Grade"),tags$td(sprintf("%.1f",sa$command_grade)),tags$td(sprintf("%.1f",sb$command_grade)),tags$td(delta_fmt(dg))),
          tags$tr(tags$td("Target Execution %"),tags$td(p_pct(sa$target_hit)),tags$td(p_pct(sb$target_hit)),tags$td(delta_fmt(dt," pts"))),
          tags$tr(tags$td("Avg Miss Distance"),tags$td(paste0(sprintf("%.1f",sa$avg_miss)," in")),tags$td(paste0(sprintf("%.1f",sb$avg_miss)," in")),tags$td(delta_fmt(dm," in"))),
          tags$tr(tags$td("Miss Distance Score"),tags$td(sprintf("%.1f",sa$miss_score)),tags$td(sprintf("%.1f",sb$miss_score)),tags$td(delta_fmt(sb$miss_score-sa$miss_score))),
          tags$tr(tags$td("Zone %"),tags$td(p_pct(sa$zone)),tags$td(p_pct(sb$zone)),tags$td(delta_fmt(100*(sb$zone-sa$zone)," pts"))),
          tags$tr(tags$td("Strike %"),tags$td(p_pct(sa$strike)),tags$td(p_pct(sb$strike)),tags$td(delta_fmt(ds," pts")))
        )
      )
    )
  })
  
  
  output$pitcher_bullpen_pitch_type_table<-renderUI({
    d<-pitcher_bullpen_data()
    
    if(nrow(d)==0||!"Pitch_Type"%in%names(d)){
      return(div(class="report-breakdown-note","No bullpen pitch-type data available."))
    }
    
    types<-unique(as.character(d$Pitch_Type))
    types<-types[!is.na(types)&types!=""&types!="None"]
    if(length(types)==0)return(div(class="report-breakdown-note","No bullpen pitch-type data available."))
    
    rows<-lapply(types,function(pt){
      z<-d[as.character(d$Pitch_Type)==pt,,drop=FALSE]
      strike<-as.character(z$Pitch_Result)%in%c("Called Strike","Strike")
      zone<-if("Zone_Group"%in%names(z))as.character(z$Zone_Group)%in%c("Heart","Shadow")else rep(FALSE,nrow(z))
      
      target_hit<-rep(NA,nrow(z))
      miss_distance<-rep(NA_real_,nrow(z))
      
      if(all(c("Location_X","Location_Y","Bullpen_Target_X","Bullpen_Target_Y")%in%names(z))){
        for(i in seq_len(nrow(z))){
          target_hit[i]<-bullpen_target_hit(z$Location_X[i],z$Location_Y[i],z$Bullpen_Target_X[i],z$Bullpen_Target_Y[i])
          miss_distance[i]<-bullpen_miss_inches(z$Location_X[i],z$Location_Y[i],z$Bullpen_Target_X[i],z$Bullpen_Target_Y[i])
        }
      }
      
      avg_miss_pt<-if(any(is.finite(miss_distance)))mean(miss_distance,na.rm=TRUE)else NA_real_
      data.frame(
        Pitch=pt,
        Pitches=nrow(z),
        Strike=mean(strike,na.rm=TRUE),
        Zone=mean(zone,na.rm=TRUE),
        TargetHit=if(any(!is.na(target_hit)))mean(target_hit,na.rm=TRUE)else NA_real_,
        AvgMiss=avg_miss_pt,
        MissScore=bullpen_miss_distance_score(avg_miss_pt),
        stringsAsFactors=FALSE
      )
    })
    
    df<-do.call(rbind,rows)
    df<-df[order(-df$Pitches),,drop=FALSE]
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Pitch"),
          tags$th("Pitches"),
          tags$th("Strike %"),
          tags$th("Zone %"),
          tags$th("Target Execution %"),
          tags$th("Avg Miss"),
          tags$th("Miss Score")
        )
      ),
      tags$tbody(
        lapply(seq_len(nrow(df)),function(i){
          r<-df[i,,drop=FALSE]
          tags$tr(
            tags$td(r$Pitch),
            tags$td(r$Pitches),
            tags$td(p_pct(r$Strike)),
            tags$td(p_pct(r$Zone)),
            tags$td(p_pct(r$TargetHit)),
            tags$td(if(is.finite(r$AvgMiss))paste0(sprintf("%.2f",r$AvgMiss)," in")else"N/A"),
            tags$td(if(is.finite(r$MissScore))sprintf("%.1f",r$MissScore)else"N/A")
          )
        })
      )
    )
  })
  
  
  output$pitcher_bullpen_trend_table<-renderUI({
    d<-bullpen_valid_rows(pitcher_report_pitches_raw())
    id<-input$pitcher_report_pitcher
    
    if(
      nrow(d)==0 ||
      is.null(id) ||
      id=="" ||
      !"Pitcher_ID"%in%names(d) ||
      !"Session_ID"%in%names(d)
    ){
      return(div(class="report-breakdown-note","No bullpen session history available."))
    }
    
    d<-d[
      as.character(d$Pitcher_ID)==as.character(id),
      ,
      drop=FALSE
    ]
    
    if(nrow(d)==0)return(div(class="report-breakdown-note","No bullpen session history available."))
    
    mp<-lb_session_date_map()
    sids<-unique(trimws(as.character(d$Session_ID)))
    sids<-sids[!is.na(sids)&sids!=""]
    
    if(length(sids)==0){
      return(div(class="report-breakdown-note","No bullpen session history available."))
    }
    
    rows<-lapply(sids,function(sid){
      z<-d[as.character(d$Session_ID)==sid,,drop=FALSE]
      strike<-as.character(z$Pitch_Result)%in%c("Called Strike","Strike")
      zone<-if("Zone_Group"%in%names(z))as.character(z$Zone_Group)%in%c("Heart","Shadow")else rep(FALSE,nrow(z))
      
      target_hit<-rep(NA,nrow(z))
      miss_distance<-rep(NA_real_,nrow(z))
      
      if(all(c("Location_X","Location_Y","Bullpen_Target_X","Bullpen_Target_Y")%in%names(z))){
        for(i in seq_len(nrow(z))){
          target_hit[i]<-bullpen_target_hit(z$Location_X[i],z$Location_Y[i],z$Bullpen_Target_X[i],z$Bullpen_Target_Y[i])
          miss_distance[i]<-bullpen_miss_inches(z$Location_X[i],z$Location_Y[i],z$Bullpen_Target_X[i],z$Bullpen_Target_Y[i])
        }
      }
      
      sp<-mean(strike,na.rm=TRUE)
      zp<-mean(zone,na.rm=TRUE)
      hp<-if(any(!is.na(target_hit)))mean(target_hit,na.rm=TRUE)else NA_real_
      avg_miss_session<-if(any(is.finite(miss_distance)))mean(miss_distance,na.rm=TRUE)else NA_real_
      miss_score_session<-bullpen_miss_distance_score(avg_miss_session)
      
      command_grade_session<-bullpen_command_grade_value(
        hp,
        avg_miss_session,
        zp,
        sp
      )
      
      data.frame(
        Session_ID=sid,
        Date=as.character(unname(mp[sid])),
        Pitches=nrow(z),
        Grade=command_grade_session,
        Strike=sp,
        Zone=zp,
        TargetHit=hp,
        AvgMiss=avg_miss_session,
        MissScore=miss_score_session,
        stringsAsFactors=FALSE
      )
    })
    
    df<-do.call(rbind,rows)
    df$SortDate<-suppressWarnings(as.Date(df$Date))
    df<-df[order(df$SortDate,decreasing=TRUE),,drop=FALSE]
    df<-head(df,5)
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Date"),
          tags$th("Pitches"),
          tags$th("Command Grade"),
          tags$th("Strike %"),
          tags$th("Zone %"),
          tags$th("Target Execution %"),
          tags$th("Avg Miss"),
          tags$th("Miss Score")
        )
      ),
      tags$tbody(
        lapply(seq_len(nrow(df)),function(i){
          r<-df[i,,drop=FALSE]
          tags$tr(
            tags$td(ifelse(is.na(r$Date)||r$Date=="NA",r$Session_ID,r$Date)),
            tags$td(r$Pitches),
            tags$td(if(is.finite(r$Grade))paste0(grade_letter(r$Grade)," ",sprintf("%.1f",r$Grade))else"N/A"),
            tags$td(p_pct(r$Strike)),
            tags$td(p_pct(r$Zone)),
            tags$td(p_pct(r$TargetHit)),
            tags$td(if(is.finite(r$AvgMiss))paste0(sprintf("%.2f",r$AvgMiss)," in")else"N/A"),
            tags$td(if(is.finite(r$MissScore))sprintf("%.1f",r$MissScore)else"N/A")
          )
        })
      )
    )
  })
  
  
  # ==================================================
  # TEAM REPORT
  # ==================================================
  
  team_report_filter_frame <- function(d) {
    if (is.null(d) || nrow(d) == 0) {
      return(data.frame())
    }
    
    sid <- input$team_report_session
    
    if (
      !is.null(sid) &&
      sid != "" &&
      sid != "ALL" &&
      "Session_ID" %in% names(d)
    ) {
      d <- d[
        as.character(d$Session_ID) == sid,
        ,
        drop = FALSE
      ]
    }
    
    rg <- input$team_report_date_range
    mp <- lb_session_date_map()
    
    if (
      "Session_ID" %in% names(d) &&
      length(mp) > 0 &&
      !is.null(rg) &&
      length(rg) == 2 &&
      !is.na(rg[1]) &&
      !is.na(rg[2])
    ) {
      dd <- unname(
        mp[
          as.character(d$Session_ID)
        ]
      )
      
      keep <- !is.na(dd) &
        dd >= as.Date(rg[1]) &
        dd <= as.Date(rg[2])
      
      d <- d[
        keep,
        ,
        drop = FALSE
      ]
    }
    
    d
  }
  
  
  team_report_pitches <- reactive({
    team_report_filter_frame(
      p_live_only(pitcher_report_pitches_raw())
    )
  })
  
  
  team_report_pas <- reactive({
    team_report_filter_frame(
      pitcher_report_pa_raw()
    )
  })
  
  
  observe({
    s <- session_lookup()
    
    if (
      nrow(s) == 0 ||
      !"Session_ID" %in% names(s)
    ) {
      return()
    }
    
    valid <- s[
      !is.na(s$Session_ID) &
        as.character(s$Session_ID) != "",
      ,
      drop = FALSE
    ]
    
    labels <- if (
      all(c("Session_Date","Session_Name") %in% names(valid))
    ) {
      paste0(
        valid$Session_Date,
        " — ",
        valid$Session_Name
      )
    } else {
      as.character(valid$Session_ID)
    }
    
    choices <- as.character(valid$Session_ID)
    names(choices) <- labels
    
    choices <- c(
      "All Sessions (Cumulative)" = "ALL",
      choices
    )
    
    current <- isolate(input$team_report_session)
    
    if (
      is.null(current) ||
      !current %in% choices
    ) {
      current <- "ALL"
    }
    
    updateSelectInput(
      session,
      "team_report_session",
      choices = choices,
      selected = current
    )
    
    if ("Session_Date" %in% names(valid)) {
      dd <- suppressWarnings(as.Date(valid$Session_Date))
      dd <- dd[!is.na(dd)]
      
      if (length(dd) > 0) {
        updateDateRangeInput(
          session,
          "team_report_date_range",
          start = min(dd),
          end = max(dd)
        )
      }
    }
  })
  
  
  observeEvent(
    input$team_report_refresh,
    {
      refresh_sessions_admin_data()
      load_sessions(select_session_id=current_session_id())
      load_pitcher_report_data()
      load_report_pitches()
    }
  )
  
  
  team_pct_display <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    
    if (
      length(x) == 0 ||
      !is.finite(x[1])
    ) {
      return("N/A")
    }
    
    x <- x[1]
    
    if (abs(x) > 1.000001) {
      x <- x / 100
    }
    
    paste0(
      sprintf("%.1f", 100 * x),
      "%"
    )
  }
  
  
  team_grade_display <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    
    if (
      length(x) == 0 ||
      !is.finite(x[1])
    ) {
      return("N/A")
    }
    
    paste0(
      grade_letter(x[1]),
      "  ",
      sprintf("%.1f", x[1])
    )
  }
  
  
  team_kpi_card <- function(label, value, cls = "") {
    div(
      class = "team-report-kpi-card",
      div(class = "team-report-kpi-label", label),
      div(
        class = paste("team-report-kpi-value", cls),
        value
      )
    )
  }
  
  
  team_hitter_summary <- reactive({
    p <- team_report_pitches()
    pa <- team_report_pas()
    
    if (nrow(p) == 0) {
      return(NULL)
    }
    
    g <- tryCatch(
      summarize_player_grades(p),
      error = function(e) NULL
    )
    
    m <- tryCatch(
      summarize_decision_metrics(p),
      error = function(e) NULL
    )
    
    q <- lb_quab_summary(pa, p)
    
    ab <- lb_sum_col(pa, "Is_AB")
    hits <- lb_sum_col(pa, "Is_Hit")
    bb <- lb_sum_col(pa, "Is_BB")
    hbp <- lb_sum_col(pa, "Is_HBP")
    sf <- lb_sum_col(pa, "Is_SF")
    tb <- lb_sum_col(pa, "Bases_Total")
    so <- lb_sum_col(pa, "Is_K")
    
    list(
      overall = safe_first_numeric(g, "Overall_Grade"),
      pre2k = safe_first_numeric(g, "Pre2K_Grade"),
      twok = safe_first_numeric(g, "TwoK_Grade"),
      heart = lb_normalize_pct(
        safe_first_numeric(m, "Heart_Swing_Pct")
      ),
      chase = lb_normalize_pct(
        safe_first_numeric(m, "Chase_Pct")
      ),
      whiff = lb_normalize_pct(
        safe_first_numeric(m, "Whiff_Pct")
      ),
      contact = lb_normalize_pct(
        safe_first_numeric(m, "Contact_Pct")
      ),
      hard = lb_normalize_pct(
        safe_first_numeric(m, "Hard_Contact_Pct")
      ),
      quab = q$QUAB_Pct,
      avg = lb_rate(hits, ab),
      obp = lb_rate(
        hits + bb + hbp,
        ab + bb + hbp + sf
      ),
      slg = lb_rate(tb, ab),
      k_pct = lb_rate(so, nrow(pa)),
      bb_pct = lb_rate(bb, nrow(pa)),
      pa = nrow(pa),
      pitches = nrow(p)
    )
  })
  
  
  team_pitcher_rows_for_data <- function(p, pa) {
    if (
      nrow(p) == 0 ||
      !"Pitcher_ID" %in% names(p)
    ) {
      return(data.frame())
    }
    
    ids <- unique(as.character(p$Pitcher_ID))
    ids <- ids[!is.na(ids) & ids != ""]
    
    if (length(ids) == 0) {
      return(data.frame())
    }
    
    metric_rows <- Filter(
      Negate(is.null),
      lapply(
        ids,
        function(id) {
          d <- p[
            as.character(p$Pitcher_ID) == id,
            ,
            drop = FALSE
          ]
          
          m <- p_metrics_from_data(d)
          
          if (is.null(m)) {
            return(NULL)
          }
          
          data.frame(
            Player_ID = id,
            FPS_Pct = m$fps,
            Strike_Pct = m$strike,
            Zone_Pct = m$zone,
            Whiff_Pct = m$whiff,
            Chase_Pct = m$chase,
            Ahead_Pct = m$ahead,
            Behind_Pct = m$behind,
            Early_Contact_Pct = m$early_contact,
            Efficient_Inning_Pct = m$eff,
            Avg_Pitches_Inning = m$api,
            stringsAsFactors = FALSE
          )
        }
      )
    )
    
    if (length(metric_rows) == 0) {
      return(data.frame())
    }
    
    met <- do.call(rbind, metric_rows)
    mn <- setdiff(names(met), "Player_ID")
    
    staff <- lapply(
      mn,
      function(nm) {
        x <- suppressWarnings(as.numeric(met[[nm]]))
        x <- x[is.finite(x)]
        if (length(x) == 0) NA_real_ else mean(x)
      }
    )
    names(staff) <- mn
    
    rows <- lapply(
      seq_len(nrow(met)),
      function(i) {
        r <- met[i,,drop=FALSE]
        
        command <- p_mean_grade(
          c(
            p_staff_grade_component(r$FPS_Pct, staff$FPS_Pct, TRUE),
            p_staff_grade_component(r$Strike_Pct, staff$Strike_Pct, TRUE),
            p_staff_grade_component(r$Zone_Pct, staff$Zone_Pct, TRUE),
            p_staff_grade_component(r$Behind_Pct, staff$Behind_Pct, FALSE)
          )
        )
        
        miss <- p_mean_grade(
          c(
            p_staff_grade_component(r$Whiff_Pct, staff$Whiff_Pct, TRUE),
            p_staff_grade_component(r$Chase_Pct, staff$Chase_Pct, TRUE)
          )
        )
        
        efficiency <- p_mean_grade(
          c(
            p_staff_grade_component(r$Ahead_Pct, staff$Ahead_Pct, TRUE),
            p_staff_grade_component(r$Early_Contact_Pct, staff$Early_Contact_Pct, TRUE),
            p_staff_grade_component(
              r$Efficient_Inning_Pct,
              staff$Efficient_Inning_Pct,
              TRUE
            )
          )
        )
        
        overall <- p_mean_grade(
          c(command, miss, efficiency)
        )
        
        data.frame(
          Player_ID = as.character(r$Player_ID),
          Player = lb_name(r$Player_ID),
          Overall_Grade = overall,
          Command_Grade = command,
          Miss_Grade = miss,
          Efficiency_Grade = efficiency,
          FPS_Pct = r$FPS_Pct,
          Strike_Pct = r$Strike_Pct,
          Zone_Pct = r$Zone_Pct,
          Whiff_Pct = r$Whiff_Pct,
          Chase_Pct = r$Chase_Pct,
          Ahead_Pct = r$Ahead_Pct,
          Behind_Pct = r$Behind_Pct,
          Early_Contact_Pct = r$Early_Contact_Pct,
          Efficient_Inning_Pct = r$Efficient_Inning_Pct,
          Avg_Pitches_Inning = r$Avg_Pitches_Inning,
          stringsAsFactors = FALSE
        )
      }
    )
    
    do.call(rbind, rows)
  }
  
  
  team_pitcher_summary <- reactive({
    p <- team_report_pitches()
    pa <- team_report_pas()
    
    if (nrow(p) == 0) {
      return(NULL)
    }
    
    pr <- team_pitcher_rows_for_data(p, pa)
    raw <- p_metrics_from_data(p)
    
    cq <- if (
      "Contact_Quality" %in% names(p)
    ) {
      as.character(p$Contact_Quality)
    } else {
      character(0)
    }
    
    cden <- sum(
      cq %in% c("Hard","Average","Avg","Weak"),
      na.rm = TRUE
    )
    
    finite_mean <- function(x) {
      x <- suppressWarnings(as.numeric(x))
      x <- x[is.finite(x)]
      if (length(x) == 0) NA_real_ else mean(x)
    }
    
    list(
      overall = if (nrow(pr) > 0) finite_mean(pr$Overall_Grade) else NA_real_,
      command = if (nrow(pr) > 0) finite_mean(pr$Command_Grade) else NA_real_,
      miss = if (nrow(pr) > 0) finite_mean(pr$Miss_Grade) else NA_real_,
      efficiency = if (nrow(pr) > 0) finite_mean(pr$Efficiency_Grade) else NA_real_,
      fps = if (!is.null(raw)) raw$fps else NA_real_,
      strike = if (!is.null(raw)) raw$strike else NA_real_,
      whiff = if (!is.null(raw)) raw$whiff else NA_real_,
      chase = if (!is.null(raw)) raw$chase else NA_real_,
      ahead = if (!is.null(raw)) raw$ahead else NA_real_,
      behind = if (!is.null(raw)) raw$behind else NA_real_,
      early_contact = if (!is.null(raw)) raw$early_contact else NA_real_,
      efficient_innings = if (!is.null(raw)) raw$eff else NA_real_,
      avg_pitches_inning = if (!is.null(raw)) raw$api else NA_real_,
      hard = lb_rate(sum(cq == "Hard", na.rm = TRUE), cden),
      medium = lb_rate(
        sum(cq %in% c("Average","Avg"), na.rm = TRUE),
        cden
      ),
      soft = lb_rate(sum(cq == "Weak", na.rm = TRUE), cden),
      pitches = nrow(p),
      bf = nrow(pa)
    )
  })
  
  
  output$team_report_status <- renderUI({
    p <- team_report_pitches()
    pa <- team_report_pas()
    
    if (identical(input$team_report_type, "Pitcher")) {
      HTML(
        paste0(
          "<strong>",
          nrow(p),
          "</strong> charted staff pitches • <strong>",
          nrow(pa),
          "</strong> charted batters faced in the selected filters."
        )
      )
    } else {
      HTML(
        paste0(
          "<strong>",
          nrow(p),
          "</strong> charted hitter pitches • <strong>",
          nrow(pa),
          "</strong> charted plate appearances in the selected filters."
        )
      )
    }
  })
  
  
  output$team_report_kpis <- renderUI({
    if (identical(input$team_report_type, "Pitcher")) {
      x <- team_pitcher_summary()
      
      if (is.null(x)) {
        return(
          tagList(
            team_kpi_card("Overall Grade","N/A"),
            team_kpi_card("Command Grade","N/A"),
            team_kpi_card("Miss Grade","N/A"),
            team_kpi_card("Efficiency Grade","N/A"),
            team_kpi_card("1st Pitch Strike %","N/A"),
            team_kpi_card("Whiff %","N/A"),
            team_kpi_card("≤15 Pitch Innings %","N/A"),
            team_kpi_card("Contact ≤3 Pitches %","N/A")
          )
        )
      }
      
      tagList(
        team_kpi_card("Overall Grade", team_grade_display(x$overall)),
        team_kpi_card("Command Grade", team_grade_display(x$command)),
        team_kpi_card("Miss Grade", team_grade_display(x$miss)),
        team_kpi_card("Efficiency Grade", team_grade_display(x$efficiency)),
        team_kpi_card("1st Pitch Strike %", team_pct_display(x$fps)),
        team_kpi_card("Whiff %", team_pct_display(x$whiff)),
        team_kpi_card("≤15 Pitch Innings %", team_pct_display(x$efficient_innings)),
        team_kpi_card("Contact ≤3 Pitches %", team_pct_display(x$early_contact))
      )
      
    } else {
      x <- team_hitter_summary()
      
      if (is.null(x)) {
        return(
          tagList(
            team_kpi_card("Overall Grade","N/A"),
            team_kpi_card("Pre-2K Grade","N/A"),
            team_kpi_card("2K Grade","N/A"),
            team_kpi_card("Heart Swing %","N/A"),
            team_kpi_card("Chase %","N/A"),
            team_kpi_card("Whiff %","N/A"),
            team_kpi_card("Hard Contact %","N/A"),
            team_kpi_card("QUAB %","N/A")
          )
        )
      }
      
      tagList(
        team_kpi_card("Overall Grade", team_grade_display(x$overall)),
        team_kpi_card("Pre-2K Grade", team_grade_display(x$pre2k)),
        team_kpi_card("2K Grade", team_grade_display(x$twok)),
        team_kpi_card("Heart Swing %", team_pct_display(x$heart)),
        team_kpi_card("Chase %", team_pct_display(x$chase)),
        team_kpi_card("Whiff %", team_pct_display(x$whiff)),
        team_kpi_card("Hard Contact %", team_pct_display(x$hard)),
        team_kpi_card("QUAB %", team_pct_display(x$quab))
      )
    }
  })
  
  
  team_pitch_type_table <- function(d, hitter = TRUE) {
    if (
      nrow(d) == 0 ||
      !"Pitch_Type" %in% names(d)
    ) {
      return(
        div(class="report-breakdown-note","No pitch-type data available.")
      )
    }
    
    pt <- trimws(as.character(d$Pitch_Type))
    valid <- !is.na(pt) & pt != "" & pt != "None"
    d <- d[valid,,drop=FALSE]
    pt <- pt[valid]
    
    if (nrow(d) == 0) {
      return(
        div(class="report-breakdown-note","No pitch-type data available.")
      )
    }
    
    rows <- lapply(
      unique(pt),
      function(x) {
        z <- d[pt == x,,drop=FALSE]
        swings <- as.character(z$Swing_Take) == "Swing"
        whiffs <- as.character(z$Pitch_Result) == "Whiff"
        strikes <- p_strike(z$Pitch_Result)
        chase_zone <- as.character(z$Zone_Group) %in% c("Chase","Waste")
        
        data.frame(
          Pitch = x,
          Pitches = nrow(z),
          Usage = lb_rate(nrow(z), nrow(d)),
          Strike = lb_rate(sum(strikes,na.rm=TRUE), nrow(z)),
          Swing = lb_rate(sum(swings,na.rm=TRUE), nrow(z)),
          Whiff = lb_rate(sum(whiffs,na.rm=TRUE), sum(swings,na.rm=TRUE)),
          Chase = lb_rate(
            sum(chase_zone & swings,na.rm=TRUE),
            sum(chase_zone,na.rm=TRUE)
          ),
          stringsAsFactors = FALSE
        )
      }
    )
    
    df <- do.call(rbind, rows)
    df <- df[order(-df$Pitches),,drop=FALSE]
    
    body <- lapply(
      seq_len(nrow(df)),
      function(i) {
        r <- df[i,,drop=FALSE]
        
        tags$tr(
          tags$td(r$Pitch),
          tags$td(r$Pitches),
          tags$td(team_pct_display(r$Usage)),
          tags$td(team_pct_display(r$Strike)),
          tags$td(team_pct_display(r$Swing)),
          tags$td(team_pct_display(r$Whiff)),
          tags$td(team_pct_display(r$Chase))
        )
      }
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Pitch"),
          tags$th("Pitches"),
          tags$th("Usage %"),
          tags$th("Strike %"),
          tags$th("Swing %"),
          tags$th("Whiff %"),
          tags$th("Chase %")
        )
      ),
      tags$tbody(body)
    )
  }
  
  
  team_count_table <- function(d) {
    if (
      nrow(d) == 0 ||
      !"Count" %in% names(d)
    ) {
      return(
        div(class="report-breakdown-note","No count data available.")
      )
    }
    
    counts <- c(
      "0-0","1-0","0-1","2-0","1-1","0-2",
      "3-0","2-1","1-2","3-1","2-2","3-2"
    )
    
    rows <- list()
    
    for (ct in counts) {
      z <- d[as.character(d$Count) == ct,,drop=FALSE]
      if (nrow(z) == 0) next
      
      swings <- as.character(z$Swing_Take) == "Swing"
      whiffs <- as.character(z$Pitch_Result) == "Whiff"
      chase_zone <- as.character(z$Zone_Group) %in% c("Chase","Waste")
      
      pgraw <- if ("Pitch_Group" %in% names(z)) {
        as.character(z$Pitch_Group)
      } else {
        rep(NA_character_, nrow(z))
      }
      
      groups <- mapply(
        p_group,
        as.character(z$Pitch_Type),
        pgraw,
        USE.NAMES = FALSE
      )
      
      rows[[length(rows)+1]] <- data.frame(
        Count = ct,
        Pitches = nrow(z),
        Swing = lb_rate(sum(swings,na.rm=TRUE), nrow(z)),
        Chase = lb_rate(
          sum(chase_zone & swings,na.rm=TRUE),
          sum(chase_zone,na.rm=TRUE)
        ),
        Whiff = lb_rate(sum(whiffs,na.rm=TRUE), sum(swings,na.rm=TRUE)),
        Hard = mean(groups == "Hard", na.rm=TRUE),
        Breaking = mean(groups == "Breaking", na.rm=TRUE),
        Soft = mean(groups == "Soft", na.rm=TRUE),
        stringsAsFactors = FALSE
      )
    }
    
    if (length(rows) == 0) {
      return(
        div(class="report-breakdown-note","No count data available.")
      )
    }
    
    df <- do.call(rbind, rows)
    
    body <- lapply(
      seq_len(nrow(df)),
      function(i) {
        r <- df[i,,drop=FALSE]
        tags$tr(
          tags$td(r$Count),
          tags$td(r$Pitches),
          tags$td(team_pct_display(r$Swing)),
          tags$td(team_pct_display(r$Chase)),
          tags$td(team_pct_display(r$Whiff)),
          tags$td(team_pct_display(r$Hard)),
          tags$td(team_pct_display(r$Breaking)),
          tags$td(team_pct_display(r$Soft))
        )
      }
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Count"),
          tags$th("Pitches"),
          tags$th("Swing %"),
          tags$th("Chase %"),
          tags$th("Whiff %"),
          tags$th("Hard %"),
          tags$th("Breaking %"),
          tags$th("Soft %")
        )
      ),
      tags$tbody(body)
    )
  }
  
  
  team_results_table <- function(pa) {
    if (
      nrow(pa) == 0 ||
      !"PA_Result" %in% names(pa)
    ) {
      return(
        div(class="report-breakdown-note","No PA results available.")
      )
    }
    
    result <- trimws(as.character(pa$PA_Result))
    result <- result[!is.na(result) & result != ""]
    
    if (length(result) == 0) {
      return(
        div(class="report-breakdown-note","No PA results available.")
      )
    }
    
    tab <- sort(table(result), decreasing = TRUE)
    total <- sum(tab)
    
    body <- lapply(
      seq_along(tab),
      function(i) {
        tags$tr(
          tags$td(names(tab)[i]),
          tags$td(as.integer(tab[i])),
          tags$td(
            team_pct_display(
              lb_rate(tab[i], total)
            )
          )
        )
      }
    )
    
    body <- c(
      body,
      list(
        tags$tr(
          style = "font-weight:900;border-top:2px solid #A7191F;",
          tags$td("TOTAL"),
          tags$td(total),
          tags$td("100.0%")
        )
      )
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Result"),
          tags$th("PA"),
          tags$th("%")
        )
      ),
      tags$tbody(body)
    )
  }
  
  
  output$team_hitter_pitch_type_table <- renderUI({
    team_pitch_type_table(
      team_report_pitches(),
      TRUE
    )
  })
  
  
  output$team_hitter_count_table <- renderUI({
    team_count_table(
      team_report_pitches()
    )
  })
  
  
  output$team_hitter_results_table <- renderUI({
    team_results_table(
      team_report_pas()
    )
  })
  
  
  output$team_pitcher_pitch_type_table <- renderUI({
    team_pitch_type_table(
      team_report_pitches(),
      FALSE
    )
  })
  
  
  output$team_pitcher_count_table <- renderUI({
    team_count_table(
      team_report_pitches()
    )
  })
  
  
  output$team_pitcher_results_table <- renderUI({
    team_results_table(
      team_report_pas()
    )
  })
  
  
  team_hitter_player_rows <- reactive({
    p <- team_report_pitches()
    pa <- team_report_pas()
    
    ids <- unique(
      c(
        if ("Batter_ID" %in% names(p)) as.character(p$Batter_ID) else character(0),
        if ("Batter_ID" %in% names(pa)) as.character(pa$Batter_ID) else character(0)
      )
    )
    
    ids <- ids[!is.na(ids) & ids != ""]
    
    if (length(ids) == 0) {
      return(data.frame())
    }
    
    rows <- lapply(
      ids,
      function(id) {
        z <- p[
          as.character(p$Batter_ID) == id,
          ,
          drop = FALSE
        ]
        
        g <- tryCatch(
          summarize_player_grades(z),
          error = function(e) NULL
        )
        
        data.frame(
          Player_ID = id,
          Player = lb_name(id),
          Overall_Grade = safe_first_numeric(g, "Overall_Grade"),
          stringsAsFactors = FALSE
        )
      }
    )
    
    do.call(rbind, rows)
  })
  
  
  team_status_class <- function(value, avg) {
    if (
      !is.finite(value) ||
      !is.finite(avg)
    ) {
      return("team-status-near")
    }
    
    if (value > avg + 2) {
      "team-status-above"
    } else if (value < avg - 2) {
      "team-status-below"
    } else {
      "team-status-near"
    }
  }
  
  
  team_status_label <- function(value, avg) {
    if (
      !is.finite(value) ||
      !is.finite(avg)
    ) {
      return("N/A")
    }
    
    if (value > avg + 2) {
      "Above"
    } else if (value < avg - 2) {
      "Below"
    } else {
      "Near"
    }
  }
  
  
  output$team_hitter_player_status <- renderUI({
    df <- team_hitter_player_rows()
    
    if (nrow(df) == 0) {
      return(
        div(class="report-breakdown-note","No hitter data available.")
      )
    }
    
    vals <- suppressWarnings(as.numeric(df$Overall_Grade))
    avg <- mean(vals[is.finite(vals)], na.rm=TRUE)
    
    df <- df[
      order(-df$Overall_Grade),
      ,
      drop=FALSE
    ]
    
    body <- lapply(
      seq_len(nrow(df)),
      function(i) {
        r <- df[i,,drop=FALSE]
        
        tags$tr(
          tags$td(r$Player),
          tags$td(team_grade_display(r$Overall_Grade)),
          tags$td(
            class = team_status_class(r$Overall_Grade, avg),
            team_status_label(r$Overall_Grade, avg)
          )
        )
      }
    )
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Hitter"),
          tags$th("Overall Grade"),
          tags$th("vs Team Avg")
        )
      ),
      tags$tbody(body)
    )
  })
  
  
  output$team_pitcher_player_status <- renderUI({
    df <- team_pitcher_rows_for_data(
      team_report_pitches(),
      team_report_pas()
    )
    
    if (nrow(df) == 0) {
      return(
        div(class="report-breakdown-note","No pitcher data available.")
      )
    }
    
    vals <- suppressWarnings(as.numeric(df$Overall_Grade))
    avg <- mean(vals[is.finite(vals)], na.rm=TRUE)
    
    df <- df[
      order(-df$Overall_Grade),
      ,
      drop=FALSE
    ]
    
    body <- lapply(
      seq_len(nrow(df)),
      function(i) {
        r <- df[i,,drop=FALSE]
        
        tags$tr(
          tags$td(r$Player),
          tags$td(team_grade_display(r$Overall_Grade)),
          tags$td(
            class = team_status_class(r$Overall_Grade, avg),
            team_status_label(r$Overall_Grade, avg)
          )
        )
      }
    )
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Pitcher"),
          tags$th("Overall Grade"),
          tags$th("vs Staff Avg")
        )
      ),
      tags$tbody(body)
    )
  })
  
  
  output$team_hitter_quab_table <- renderUI({
    q <- lb_quab_summary(
      team_report_pas(),
      team_report_pitches()
    )
    
    if (q$PA == 0) {
      return(
        div(class="report-breakdown-note","No PA data available.")
      )
    }
    
    df <- data.frame(
      Metric = c(
        "QUABs",
        "QUAB %",
        "Hit",
        "Walk/HBP",
        "RBI",
        "8+ Pitch PA",
        "4+ After 2K",
        "Hard-Contact Barrel",
        "Successful Offensive Play",
        "Move Runner to 3rd",
        "Reached on Error"
      ),
      Value = c(
        as.character(q$QUABs),
        team_pct_display(q$QUAB_Pct),
        as.character(q$Hit),
        as.character(q$BBHBP),
        as.character(q$RBI),
        as.character(q$EightPitch),
        as.character(q$FourAfter2K),
        as.character(q$Barrel),
        as.character(q$Offensive),
        as.character(q$MoveThird),
        as.character(q$Error)
      ),
      stringsAsFactors = FALSE
    )
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("QUAB Criterion"),
          tags$th("Team Total")
        )
      ),
      tags$tbody(
        lapply(
          seq_len(nrow(df)),
          function(i) {
            tags$tr(
              tags$td(df$Metric[i]),
              tags$td(df$Value[i])
            )
          }
        )
      )
    )
  })
  
  
  output$team_pitcher_contact_table <- renderUI({
    x <- team_pitcher_summary()
    
    if (is.null(x)) {
      return(
        div(class="report-breakdown-note","No contact data available.")
      )
    }
    
    df <- data.frame(
      Contact = c("Hard","Medium","Soft"),
      Pct = c(x$hard, x$medium, x$soft),
      stringsAsFactors = FALSE
    )
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Contact Allowed"),
          tags$th("%")
        )
      ),
      tags$tbody(
        lapply(
          seq_len(nrow(df)),
          function(i) {
            tags$tr(
              tags$td(df$Contact[i]),
              tags$td(team_pct_display(df$Pct[i]))
            )
          }
        )
      )
    )
  })
  
  
  team_recent_sessions <- reactive({
    s <- session_lookup()
    rg <- input$team_report_date_range
    
    if (
      nrow(s) == 0 ||
      !all(c("Session_ID","Session_Date") %in% names(s))
    ) {
      return(data.frame())
    }
    
    x <- s
    x$Team_Report_Date <- suppressWarnings(
      as.Date(x$Session_Date)
    )
    
    x <- x[
      !is.na(x$Team_Report_Date),
      ,
      drop=FALSE
    ]
    
    if (
      !is.null(rg) &&
      length(rg) == 2 &&
      !is.na(rg[1]) &&
      !is.na(rg[2])
    ) {
      x <- x[
        x$Team_Report_Date >= as.Date(rg[1]) &
          x$Team_Report_Date <= as.Date(rg[2]),
        ,
        drop=FALSE
      ]
    }
    
    x <- x[
      order(x$Team_Report_Date, decreasing=TRUE),
      ,
      drop=FALSE
    ]
    
    head(x, 5)
  })
  
  
  output$team_hitter_trend_table <- renderUI({
    s <- team_recent_sessions()
    p_all <- pitcher_report_pitches_raw()
    pa_all <- pitcher_report_pa_raw()
    
    if (
      nrow(s) == 0 ||
      nrow(p_all) == 0
    ) {
      return(
        div(class="report-breakdown-note","Not enough session history is available yet.")
      )
    }
    
    rows <- list()
    
    for (i in seq_len(nrow(s))) {
      sid <- as.character(s$Session_ID[i])
      
      p <- p_all[
        as.character(p_all$Session_ID) == sid,
        ,
        drop=FALSE
      ]
      
      pa <- if (
        nrow(pa_all) > 0 &&
        "Session_ID" %in% names(pa_all)
      ) {
        pa_all[
          as.character(pa_all$Session_ID) == sid,
          ,
          drop=FALSE
        ]
      } else {
        data.frame()
      }
      
      if (nrow(p) == 0) next
      
      g <- tryCatch(
        summarize_player_grades(p),
        error=function(e)NULL
      )
      m <- tryCatch(
        summarize_decision_metrics(p),
        error=function(e)NULL
      )
      q <- lb_quab_summary(pa,p)
      
      ab <- lb_sum_col(pa,"Is_AB")
      hits <- lb_sum_col(pa,"Is_Hit")
      
      rows[[length(rows)+1]] <- data.frame(
        Date = as.character(s$Team_Report_Date[i]),
        Session = if (
          "Session_Name" %in% names(s)
        ) as.character(s$Session_Name[i]) else sid,
        Overall = safe_first_numeric(g,"Overall_Grade"),
        Heart = lb_normalize_pct(
          safe_first_numeric(m,"Heart_Swing_Pct")
        ),
        Chase = lb_normalize_pct(
          safe_first_numeric(m,"Chase_Pct")
        ),
        Whiff = lb_normalize_pct(
          safe_first_numeric(m,"Whiff_Pct")
        ),
        QUAB = q$QUAB_Pct,
        AVG = lb_rate(hits,ab),
        stringsAsFactors=FALSE
      )
    }
    
    if (length(rows) == 0) {
      return(
        div(class="report-breakdown-note","Not enough session history is available yet.")
      )
    }
    
    df <- do.call(rbind,rows)
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Date"),
          tags$th("Session"),
          tags$th("Overall"),
          tags$th("Heart Swing %"),
          tags$th("Chase %"),
          tags$th("Whiff %"),
          tags$th("QUAB %"),
          tags$th("AVG")
        )
      ),
      tags$tbody(
        lapply(
          seq_len(nrow(df)),
          function(i) {
            r <- df[i,,drop=FALSE]
            tags$tr(
              tags$td(r$Date),
              tags$td(r$Session),
              tags$td(team_grade_display(r$Overall)),
              tags$td(team_pct_display(r$Heart)),
              tags$td(team_pct_display(r$Chase)),
              tags$td(team_pct_display(r$Whiff)),
              tags$td(team_pct_display(r$QUAB)),
              tags$td(lb_avg_fmt(r$AVG))
            )
          }
        )
      )
    )
  })
  
  
  output$team_pitcher_trend_table <- renderUI({
    s <- team_recent_sessions()
    p_all <- pitcher_report_pitches_raw()
    pa_all <- pitcher_report_pa_raw()
    
    if (
      nrow(s) == 0 ||
      nrow(p_all) == 0
    ) {
      return(
        div(class="report-breakdown-note","Not enough session history is available yet.")
      )
    }
    
    rows <- list()
    
    for (i in seq_len(nrow(s))) {
      sid <- as.character(s$Session_ID[i])
      
      p <- p_all[
        as.character(p_all$Session_ID) == sid,
        ,
        drop=FALSE
      ]
      
      pa <- if (
        nrow(pa_all) > 0 &&
        "Session_ID" %in% names(pa_all)
      ) {
        pa_all[
          as.character(pa_all$Session_ID) == sid,
          ,
          drop=FALSE
        ]
      } else {
        data.frame()
      }
      
      if (nrow(p) == 0) next
      
      pr <- team_pitcher_rows_for_data(p,pa)
      raw <- p_metrics_from_data(p)
      
      if (
        nrow(pr) == 0 ||
        is.null(raw)
      ) next
      
      finite_mean <- function(x) {
        x <- suppressWarnings(as.numeric(x))
        x <- x[is.finite(x)]
        if (length(x) == 0) NA_real_ else mean(x)
      }
      
      rows[[length(rows)+1]] <- data.frame(
        Date = as.character(s$Team_Report_Date[i]),
        Session = if (
          "Session_Name" %in% names(s)
        ) as.character(s$Session_Name[i]) else sid,
        Overall = finite_mean(pr$Overall_Grade),
        FPS = raw$fps,
        Strike = raw$strike,
        Whiff = raw$whiff,
        Chase = raw$chase,
        Efficient = raw$eff,
        Early = raw$early_contact,
        stringsAsFactors=FALSE
      )
    }
    
    if (length(rows) == 0) {
      return(
        div(class="report-breakdown-note","Not enough session history is available yet.")
      )
    }
    
    df <- do.call(rbind,rows)
    
    tags$table(
      class="table table-striped table-condensed",
      tags$thead(
        tags$tr(
          tags$th("Date"),
          tags$th("Session"),
          tags$th("Overall"),
          tags$th("1st Pitch Strike %"),
          tags$th("Strike %"),
          tags$th("Whiff %"),
          tags$th("Chase %"),
          tags$th("≤15 Pitch Innings %"),
          tags$th("Contact ≤3 %")
        )
      ),
      tags$tbody(
        lapply(
          seq_len(nrow(df)),
          function(i) {
            r <- df[i,,drop=FALSE]
            tags$tr(
              tags$td(r$Date),
              tags$td(r$Session),
              tags$td(team_grade_display(r$Overall)),
              tags$td(team_pct_display(r$FPS)),
              tags$td(team_pct_display(r$Strike)),
              tags$td(team_pct_display(r$Whiff)),
              tags$td(team_pct_display(r$Chase)),
              tags$td(team_pct_display(r$Efficient)),
              tags$td(team_pct_display(r$Early))
            )
          }
        )
      )
    )
  })
  
  
  # ==================================================
  # PLAYER REPORT
  # ==================================================
  
  load_report_pitches <- function() {
    
    tryCatch(
      {
        pitches_data <- sessions_admin_pitches()
        if(is.null(pitches_data)) pitches_data <- data.frame()
        
        report_pitches(
          as.data.frame(pitches_data, stringsAsFactors = FALSE)
        )
        
        report_load_error(NULL)
      },
      error = function(e) {
        report_pitches(data.frame())
        report_load_error(e$message)
      }
    )
    
    tryCatch(
      {
        pa_data <- sessions_admin_pas()
        if(is.null(pa_data)) pa_data <- data.frame()
        
        report_plate_appearances(
          as.data.frame(pa_data, stringsAsFactors = FALSE)
        )
      },
      error = function(e) {
        report_plate_appearances(data.frame())
      }
    )
  }
  
  observeEvent(input$report_batter, {
    load_report_pitches()
  }, ignoreInit = TRUE)
  
  observeEvent(input$refresh_report, {
    refresh_sessions_admin_data()
    load_sessions(select_session_id=current_session_id())
    load_report_pitches()
  })
  
  # ==================================================
  # REPORT BATTER SILHOUETTE
  # ==================================================
  # The actual silhouette image lives in:
  #   www/batter_silhouette.png
  #
  # Handedness controls which side of the heat map
  # the silhouette appears on, and LHH is flipped so
  # the hitter faces the opposite direction.
  # IMPORTANT: silhouette/heat-map spacing is now LOCKED
  # to a fixed visual stage. Do not position the silhouette
  # relative to the full heatmap card again, or browser-width
  # changes will make the batter drift away from the zone.
  #
  # The sizing is intentionally tied to the report
  # strike-zone proportions:
  #   chest ~= top of strike zone
  #   knees ~= bottom of strike zone
  # ==================================================
  
  report_batter_side <- reactive({
    
    batter_id <- input$report_batter
    
    if (
      is.null(batter_id) ||
      batter_id == ""
    ) {
      return("R")
    }
    
    lookup <- player_lookup()
    
    if (
      nrow(lookup) == 0 ||
      !"Player_ID" %in% names(lookup) ||
      !"Bats" %in% names(lookup)
    ) {
      return("R")
    }
    
    row <- lookup[
      lookup$Player_ID == batter_id,
      ,
      drop = FALSE
    ]
    
    if (nrow(row) == 0) {
      return("R")
    }
    
    bats_value <- toupper(
      trimws(
        as.character(
          row$Bats[1]
        )
      )
    )
    
    if (bats_value %in% c("L", "LEFT", "LHH")) {
      return("L")
    }
    
    if (bats_value %in% c("S", "SWITCH")) {
      return("S")
    }
    
    "R"
  })
  
  
  build_batter_silhouette_ui <- function() {
    
    side <- report_batter_side()
    
    css_class <- if (
      side == "L"
    ) {
      "batter-silhouette lhh"
    } else if (
      side == "S"
    ) {
      "batter-silhouette switch"
    } else {
      "batter-silhouette rhh"
    }
    
    div(
      class = css_class,
      tags$img(
        src = "batter_silhouette.png",
        alt = "Batter silhouette"
      )
    )
  }
  
  
  output$swing_batter_silhouette <- renderUI({
    build_batter_silhouette_ui()
  })
  
  output$chase_batter_silhouette <- renderUI({
    build_batter_silhouette_ui()
  })
  
  output$whiff_batter_silhouette <- renderUI({
    build_batter_silhouette_ui()
  })
  
  output$decision_batter_silhouette <- renderUI({
    build_batter_silhouette_ui()
  })
  
  output$contact_batter_silhouette <- renderUI({
    build_batter_silhouette_ui()
  })
  
  
  # ==================================================
  # V24 REPORT FILTERS / PLAYER BIO / GRADE BLOCKS
  # ==================================================
  
  safe_player_value <- function(row, column_name, default = "—") {
    if (
      nrow(row) == 0 ||
      !column_name %in% names(row) ||
      is.na(row[[column_name]][1]) ||
      trimws(as.character(row[[column_name]][1])) == ""
    ) {
      return(default)
    }
    trimws(as.character(row[[column_name]][1]))
  }
  
  
  report_player_row <- reactive({
    id <- input$report_batter
    lookup <- player_lookup()
    if (
      is.null(id) || id == "" ||
      nrow(lookup) == 0 ||
      !"Player_ID" %in% names(lookup)
    ) {
      return(data.frame())
    }
    lookup[
      as.character(lookup$Player_ID) == id,
      ,
      drop = FALSE
    ]
  })
  
  
  output$report_player_name <- renderText({
    row <- report_player_row()
    safe_player_value(row, "Display_Name", "Player")
  })
  
  
  output$report_player_bio <- renderUI({
    row <- report_player_row()
    
    jersey <- safe_player_value(row, "Jersey_Number")
    bats <- safe_player_value(row, "Bats")
    throws <- safe_player_value(row, "Throws")
    class_year <- safe_player_value(row, "Class")
    position <- safe_player_value(row, "Primary_Position")
    height <- safe_player_value(row, "Height")
    weight <- safe_player_value(row, "Weight")
    
    tagList(
      div(paste0("#", jersey, "  •  ", position, "  •  Class: ", class_year)),
      div(paste0("Bats: ", bats, "   Throws: ", throws)),
      div(paste0("Height: ", height, "   Weight: ", weight))
    )
  })
  
  
  output$report_player_headshot <- renderUI({
    id <- input$report_batter
    if (is.null(id) || id == "") {
      return(tags$div(class = "report-player-photo"))
    }
    
    # Optional convention:
    # www/headshots/<Player_ID>.png
    tags$img(
      class = "report-player-photo",
      src = paste0("headshots/", id, ".png"),
      onerror = "this.style.visibility='hidden';"
    )
  })
  
  
  observe({
    sessions <- session_lookup()
    if (
      nrow(sessions) == 0 ||
      !"Session_ID" %in% names(sessions)
    ) {
      updateSelectInput(
        session,
        "report_session",
        choices = c("All Sessions (Cumulative)" = "ALL"),
        selected = "ALL"
      )
      return()
    }
    
    valid <- sessions[
      !is.na(sessions$Session_ID) &
        as.character(sessions$Session_ID) != "",
      ,
      drop = FALSE
    ]
    
    labels <- if (
      all(c("Session_Date", "Session_Name") %in% names(valid))
    ) {
      paste0(valid$Session_Date, " — ", valid$Session_Name)
    } else {
      as.character(valid$Session_ID)
    }
    
    choices <- as.character(valid$Session_ID)
    names(choices) <- labels
    
    choices <- c(
      "All Sessions (Cumulative)" = "ALL",
      choices
    )
    
    current <- isolate(input$report_session)
    if (is.null(current) || !current %in% choices) {
      current <- "ALL"
    }
    
    updateSelectInput(
      session,
      "report_session",
      choices = choices,
      selected = current
    )
    
    if (
      "Session_Date" %in% names(valid) &&
      nrow(valid) > 0
    ) {
      dates <- suppressWarnings(as.Date(valid$Session_Date))
      dates <- dates[!is.na(dates)]
      if (length(dates) > 0) {
        updateDateRangeInput(
          session,
          "report_date_range",
          start = min(dates),
          end = max(dates)
        )
      }
    }
  })
  
  
  report_date_filtered_pitches <- reactive({
    d <- report_pitches()
    
    if (nrow(d) == 0) {
      return(d)
    }
    
    sessions <- session_lookup()
    
    if (
      !"Session_ID" %in% names(d) ||
      nrow(sessions) == 0 ||
      !all(c("Session_ID", "Session_Date") %in% names(sessions))
    ) {
      return(d)
    }
    
    session_dates <- data.frame(
      Session_ID = as.character(sessions$Session_ID),
      Session_Date_Report = suppressWarnings(as.Date(sessions$Session_Date)),
      stringsAsFactors = FALSE
    )
    
    d$Session_ID <- as.character(d$Session_ID)
    d <- merge(
      d,
      session_dates,
      by = "Session_ID",
      all.x = TRUE,
      sort = FALSE
    )
    
    rng <- input$report_date_range
    
    if (
      !is.null(rng) &&
      length(rng) == 2 &&
      !is.na(rng[1]) &&
      !is.na(rng[2])
    ) {
      d <- d[
        is.na(d$Session_Date_Report) |
          (
            d$Session_Date_Report >= as.Date(rng[1]) &
              d$Session_Date_Report <= as.Date(rng[2])
          ),
        ,
        drop = FALSE
      ]
    }
    
    d
  })
  
  
  cumulative_batter_pitches <- reactive({
    id <- input$report_batter
    d <- report_date_filtered_pitches()
    
    if (
      is.null(id) || id == "" ||
      nrow(d) == 0 ||
      !"Batter_ID" %in% names(d)
    ) {
      return(data.frame())
    }
    
    d[
      !is.na(d$Batter_ID) &
        as.character(d$Batter_ID) == id,
      ,
      drop = FALSE
    ]
  })
  
  
  selected_session_batter_pitches <- reactive({
    d <- cumulative_batter_pitches()
    selected_session <- input$report_session
    
    if (
      nrow(d) == 0 ||
      is.null(selected_session) ||
      selected_session == "" ||
      selected_session == "ALL" ||
      !"Session_ID" %in% names(d)
    ) {
      return(data.frame())
    }
    
    d[
      as.character(d$Session_ID) == selected_session,
      ,
      drop = FALSE
    ]
  })
  
  
  grade_letter <- function(value) {
    value <- suppressWarnings(as.numeric(value))
    if (!is.finite(value)) return("—")
    
    if (value >= 93) "A+" else
      if (value >= 90) "A" else
        if (value >= 87) "A-" else
          if (value >= 83) "B+" else
            if (value >= 80) "B" else
              if (value >= 77) "B-" else
                if (value >= 73) "C+" else
                  if (value >= 70) "C" else
                    if (value >= 67) "C-" else
                      if (value >= 63) "D+" else
                        if (value >= 60) "D" else "F"
  }
  
  
  grade_cell_ui <- function(label, value, pitches) {
    cls <- benchmark_class(
      value = value,
      team_avg = 75,
      higher_is_better = TRUE,
      tolerance = 3
    )
    
    div(
      class = "grade-block-cell",
      div(
        class = paste("grade-letter", cls),
        grade_letter(value)
      ),
      div(
        class = "grade-number-small",
        if (is.finite(suppressWarnings(as.numeric(value)))) {
          paste0(sprintf("%.1f", as.numeric(value)), " / 100")
        } else {
          "N/A"
        }
      ),
      div(
        class = "grade-pitch-count",
        paste0(label, " • Pitches: ", pitches)
      )
    )
  }
  
  
  grade_summary_from_data <- function(d) {
    if (nrow(d) == 0) return(NULL)
    tryCatch(
      summarize_player_grades(d),
      error = function(e) NULL
    )
  }
  
  
  output$cumulative_grade_cells <- renderUI({
    s <- grade_summary_from_data(cumulative_batter_pitches())
    if (is.null(s)) {
      return(tagList(
        grade_cell_ui("Overall", NA_real_, 0),
        grade_cell_ui("Pre-2K", NA_real_, 0),
        grade_cell_ui("2K", NA_real_, 0)
      ))
    }
    
    tagList(
      grade_cell_ui("Overall", s$Overall_Grade[1], s$Overall_Pitches[1]),
      grade_cell_ui("Pre-2K", s$Pre2K_Grade[1], s$Pre2K_Pitches[1]),
      grade_cell_ui("2K", s$TwoK_Grade[1], s$TwoK_Pitches[1])
    )
  })
  
  
  output$selected_session_grade_cells <- renderUI({
    s <- grade_summary_from_data(selected_session_batter_pitches())
    if (is.null(s)) {
      return(tagList(
        grade_cell_ui("Overall", NA_real_, 0),
        grade_cell_ui("Pre-2K", NA_real_, 0),
        grade_cell_ui("2K", NA_real_, 0)
      ))
    }
    
    tagList(
      grade_cell_ui("Overall", s$Overall_Grade[1], s$Overall_Pitches[1]),
      grade_cell_ui("Pre-2K", s$Pre2K_Grade[1], s$Pre2K_Pitches[1]),
      grade_cell_ui("2K", s$TwoK_Grade[1], s$TwoK_Pitches[1])
    )
  })
  
  
  output$selected_session_label <- renderText({
    sid <- input$report_session
    if (is.null(sid) || sid == "" || sid == "ALL") {
      return("Select a session to compare")
    }
    
    sessions <- session_lookup()
    row <- sessions[
      as.character(sessions$Session_ID) == sid,
      ,
      drop = FALSE
    ]
    
    if (nrow(row) == 0) return(sid)
    
    name <- safe_player_value(row, "Session_Name", sid)
    date <- safe_player_value(row, "Session_Date", "")
    
    paste0(date, if (date != "") " — " else "", name)
  })
  
  
  report_batter_pitches <- reactive({
    batter_id <- input$report_batter
    
    if (is.null(batter_id) || batter_id == "") {
      return(data.frame())
    }
    
    pitches_data <- report_pitches()
    
    if (
      nrow(pitches_data) == 0 ||
      !"Batter_ID" %in% names(pitches_data)
    ) {
      return(data.frame())
    }
    
    pitches_data[
      !is.na(pitches_data$Batter_ID) &
        pitches_data$Batter_ID == batter_id,
      ,
      drop = FALSE
    ]
  })
  
  report_batter_pas <- reactive({
    
    batter_id <- input$report_batter
    pa_data <- report_plate_appearances()
    
    if (
      is.null(batter_id) ||
      batter_id == "" ||
      nrow(pa_data) == 0 ||
      !"Batter_ID" %in% names(pa_data)
    ) {
      return(data.frame())
    }
    
    pa_data[
      !is.na(pa_data$Batter_ID) &
        as.character(pa_data$Batter_ID) == batter_id,
      ,
      drop = FALSE
    ]
  })
  
  
  safe_sum_column <- function(
    df,
    column_name
  ) {
    
    if (
      nrow(df) == 0 ||
      !column_name %in% names(df)
    ) {
      return(0)
    }
    
    values <- suppressWarnings(
      as.numeric(
        df[[column_name]]
      )
    )
    
    sum(
      values,
      na.rm = TRUE
    )
  }
  
  
  safe_rate_value <- function(
    numerator,
    denominator
  ) {
    
    numerator <- suppressWarnings(
      as.numeric(numerator)
    )
    
    denominator <- suppressWarnings(
      as.numeric(denominator)
    )
    
    if (
      length(numerator) == 0 ||
      length(denominator) == 0 ||
      !is.finite(numerator) ||
      !is.finite(denominator) ||
      denominator <= 0
    ) {
      return(NA_real_)
    }
    
    numerator / denominator
  }
  
  
  format_batting_rate <- function(value) {
    
    value <- suppressWarnings(
      as.numeric(value)
    )
    
    if (
      length(value) == 0 ||
      !is.finite(value)
    ) {
      return("N/A")
    }
    
    sub(
      "^0",
      "",
      sprintf(
        "%.3f",
        value
      )
    )
  }
  
  
  format_count_stat <- function(value) {
    
    value <- suppressWarnings(
      as.numeric(value)
    )
    
    if (
      length(value) == 0 ||
      !is.finite(value)
    ) {
      return("0")
    }
    
    as.character(
      round(value)
    )
  }
  
  
  report_player_stat_values <- reactive({
    
    d <- report_batter_pas()
    
    if (nrow(d) == 0) {
      return(NULL)
    }
    
    pa <- nrow(d)
    ab <- safe_sum_column(d, "Is_AB")
    hits <- safe_sum_column(d, "Is_Hit")
    total_bases <- safe_sum_column(d, "Bases_Total")
    bb <- safe_sum_column(d, "Is_BB")
    hbp <- safe_sum_column(d, "Is_HBP")
    sf <- safe_sum_column(d, "Is_SF")
    strikeouts <- safe_sum_column(d, "Is_K")
    rbi <- safe_sum_column(d, "Runs_Batted_In")
    
    result_text <- if (
      "PA_Result" %in% names(d)
    ) {
      as.character(
        d$PA_Result
      )
    } else {
      rep(
        "",
        pa
      )
    }
    
    home_runs <- sum(
      result_text == "Home Run",
      na.rm = TRUE
    )
    
    avg <- safe_rate_value(
      hits,
      ab
    )
    
    obp <- safe_rate_value(
      hits + bb + hbp,
      ab + bb + hbp + sf
    )
    
    slg <- safe_rate_value(
      total_bases,
      ab
    )
    
    k_pct <- safe_rate_value(
      strikeouts,
      pa
    )
    
    bb_pct <- safe_rate_value(
      bb,
      pa
    )
    
    babip <- safe_rate_value(
      hits - home_runs,
      ab - strikeouts - home_runs + sf
    )
    
    list(
      PA = pa,
      AVG = avg,
      OBP = obp,
      SLG = slg,
      Strikeouts = strikeouts,
      Walks = bb,
      HBP = hbp,
      K_Pct = k_pct,
      BB_Pct = bb_pct,
      RBI = rbi,
      BABIP = babip,
      wOBA = NA_real_,
      wRC_Plus = NA_real_
    )
  })
  
  
  stat_cell <- function(
    label,
    value,
    value_class = ""
  ) {
    
    div(
      class = "player-stat-cell",
      div(
        class = "player-stat-label",
        label
      ),
      div(
        class = paste(
          "player-stat-value",
          value_class
        ),
        value
      )
    )
  }
  
  
  output$report_player_stats <- renderUI({
    
    stats <- report_player_stat_values()
    
    if (is.null(stats)) {
      return(
        div(
          class = "report-breakdown-note",
          "No plate-appearance data available."
        )
      )
    }
    
    div(
      class = "player-stat-grid",
      
      stat_cell(
        "AVG",
        format_batting_rate(stats$AVG)
      ),
      
      stat_cell(
        "OBP",
        format_batting_rate(stats$OBP)
      ),
      
      stat_cell(
        "SLG",
        format_batting_rate(stats$SLG)
      ),
      
      stat_cell(
        "PA",
        format_count_stat(stats$PA)
      ),
      
      stat_cell(
        "SO",
        format_count_stat(stats$Strikeouts)
      ),
      
      stat_cell(
        "BB",
        format_count_stat(stats$Walks)
      ),
      
      stat_cell(
        "HBP",
        format_count_stat(stats$HBP)
      ),
      
      stat_cell(
        "K%",
        if (
          is.finite(stats$K_Pct)
        ) {
          paste0(
            sprintf(
              "%.1f",
              100 * stats$K_Pct
            ),
            "%"
          )
        } else {
          "N/A"
        }
      ),
      
      stat_cell(
        "BB%",
        if (
          is.finite(stats$BB_Pct)
        ) {
          paste0(
            sprintf(
              "%.1f",
              100 * stats$BB_Pct
            ),
            "%"
          )
        } else {
          "N/A"
        }
      ),
      
      stat_cell(
        "RBI",
        format_count_stat(stats$RBI)
      ),
      
      stat_cell(
        "BABIP",
        format_batting_rate(stats$BABIP)
      ),
      
      stat_cell(
        "wOBA",
        "N/A"
      ),
      
      stat_cell(
        "wRC+",
        "N/A"
      )
    )
  })
  
  
  report_grade_summary <- reactive({
    batter_pitches <- report_batter_pitches()
    
    if (nrow(batter_pitches) == 0) {
      return(NULL)
    }
    
    summarize_player_grades(
      batter_pitches
    )
  })
  
  report_decision_metrics <- reactive({
    batter_pitches <- report_batter_pitches()
    
    if (nrow(batter_pitches) == 0) {
      return(NULL)
    }
    
    summarize_decision_metrics(
      batter_pitches
    )
  })
  
  
  
  # ==================================================
  # TEAM-AVERAGE BENCHMARKS
  # ==================================================
  # Player-weighted team averages.
  #
  # Green  = better than team average by > tolerance
  # Yellow = within tolerance of team average
  # Red    = worse than team average by > tolerance
  #
  # Grade tolerance = 2.0 points
  # Metric tolerance = 2 percentage points
  # ==================================================
  
  safe_first_numeric <- function(df, column_name) {
    
    if (
      is.null(df) ||
      !column_name %in% names(df) ||
      length(df[[column_name]]) == 0
    ) {
      return(NA_real_)
    }
    
    value <- suppressWarnings(
      as.numeric(
        df[[column_name]][1]
      )
    )
    
    if (
      length(value) == 0 ||
      !is.finite(value)
    ) {
      return(NA_real_)
    }
    
    value
  }
  
  
  team_report_benchmarks <- reactive({
    
    all_pitches <- report_pitches()
    
    if (
      nrow(all_pitches) == 0 ||
      !"Batter_ID" %in% names(all_pitches)
    ) {
      return(NULL)
    }
    
    batter_ids <- unique(
      as.character(
        all_pitches$Batter_ID
      )
    )
    
    batter_ids <- batter_ids[
      !is.na(batter_ids) &
        batter_ids != ""
    ]
    
    if (length(batter_ids) == 0) {
      return(NULL)
    }
    
    rows <- lapply(
      batter_ids,
      function(id) {
        
        d <- all_pitches[
          !is.na(all_pitches$Batter_ID) &
            as.character(all_pitches$Batter_ID) == id,
          ,
          drop = FALSE
        ]
        
        grades <- tryCatch(
          summarize_player_grades(d),
          error = function(e) {
            NULL
          }
        )
        
        metrics <- tryCatch(
          summarize_decision_metrics(d),
          error = function(e) {
            NULL
          }
        )
        
        data.frame(
          Batter_ID = id,
          Overall_Grade = safe_first_numeric(
            grades,
            "Overall_Grade"
          ),
          Pre2K_Grade = safe_first_numeric(
            grades,
            "Pre2K_Grade"
          ),
          TwoK_Grade = safe_first_numeric(
            grades,
            "TwoK_Grade"
          ),
          Heart_Swing_Pct = safe_first_numeric(
            metrics,
            "Heart_Swing_Pct"
          ),
          Heart_Take_Pct = safe_first_numeric(
            metrics,
            "Heart_Take_Pct"
          ),
          Chase_Pct = safe_first_numeric(
            metrics,
            "Chase_Pct"
          ),
          Shadow_Swing_Pct = safe_first_numeric(
            metrics,
            "Shadow_Swing_Pct"
          ),
          Overall_Swing_Pct = safe_first_numeric(
            metrics,
            "Overall_Swing_Pct"
          ),
          Whiff_Pct = safe_first_numeric(
            metrics,
            "Whiff_Pct"
          ),
          Contact_Pct = safe_first_numeric(
            metrics,
            "Contact_Pct"
          ),
          Hard_Contact_Pct = safe_first_numeric(
            metrics,
            "Hard_Contact_Pct"
          ),
          Pre2K_Heart_Swing_Pct = safe_first_numeric(
            metrics,
            "Pre2K_Heart_Swing_Pct"
          ),
          TwoK_Heart_Swing_Pct = safe_first_numeric(
            metrics,
            "TwoK_Heart_Swing_Pct"
          ),
          Pre2K_Chase_Pct = safe_first_numeric(
            metrics,
            "Pre2K_Chase_Pct"
          ),
          TwoK_Chase_Pct = safe_first_numeric(
            metrics,
            "TwoK_Chase_Pct"
          ),
          stringsAsFactors = FALSE
        )
      }
    )
    
    if (length(rows) == 0) {
      return(NULL)
    }
    
    team_df <- do.call(
      rbind,
      rows
    )
    
    numeric_cols <- setdiff(
      names(team_df),
      "Batter_ID"
    )
    
    averages <- lapply(
      numeric_cols,
      function(column_name) {
        
        values <- suppressWarnings(
          as.numeric(
            team_df[[column_name]]
          )
        )
        
        values <- values[
          is.finite(values)
        ]
        
        if (length(values) == 0) {
          return(NA_real_)
        }
        
        mean(values)
      }
    )
    
    names(averages) <- numeric_cols
    
    averages
  })
  
  
  benchmark_class <- function(
    value,
    team_avg,
    higher_is_better = TRUE,
    tolerance = 0.02,
    neutral = FALSE
  ) {
    
    value <- suppressWarnings(
      as.numeric(value)
    )
    
    team_avg <- suppressWarnings(
      as.numeric(team_avg)
    )
    
    if (
      length(value) == 0 ||
      length(team_avg) == 0 ||
      !is.finite(value) ||
      !is.finite(team_avg) ||
      neutral
    ) {
      return("benchmark-neutral")
    }
    
    difference <- value - team_avg
    
    if (abs(difference) <= tolerance) {
      return("benchmark-average")
    }
    
    if (higher_is_better) {
      
      if (difference > tolerance) {
        return("benchmark-good")
      }
      
      return("benchmark-poor")
    }
    
    if (difference < -tolerance) {
      return("benchmark-good")
    }
    
    "benchmark-poor"
  }
  
  
  benchmark_span <- function(
    display_value,
    raw_value,
    team_avg,
    higher_is_better = TRUE,
    tolerance = 0.02,
    neutral = FALSE
  ) {
    
    team_avg_numeric <- suppressWarnings(
      as.numeric(team_avg)
    )
    
    if (
      length(team_avg_numeric) > 0 &&
      is.finite(team_avg_numeric)
    ) {
      
      if (tolerance < 1) {
        avg_label <- format_metric_pct(
          team_avg_numeric
        )
      } else {
        avg_label <- sprintf(
          "%.1f",
          team_avg_numeric
        )
      }
      
    } else {
      
      avg_label <- "N/A"
    }
    
    tags$span(
      class = paste(
        "benchmark-value",
        benchmark_class(
          raw_value,
          team_avg_numeric,
          higher_is_better,
          tolerance,
          neutral
        )
      ),
      title = paste0(
        "Team average: ",
        avg_label
      ),
      display_value
    )
  }
  
  
  output$overall_grade_benchmark <- renderUI({
    
    summary_data <- report_grade_summary()
    team <- team_report_benchmarks()
    
    if (is.null(summary_data)) {
      return("N/A")
    }
    
    team_avg <- NA_real_
    
    if (
      !is.null(team) &&
      "Overall_Grade" %in% names(team)
    ) {
      team_avg <- team$Overall_Grade
    }
    
    value <- safe_first_numeric(
      summary_data,
      "Overall_Grade"
    )
    
    benchmark_span(
      format_report_grade(value),
      value,
      team_avg,
      higher_is_better = TRUE,
      tolerance = 2.0
    )
  })
  
  
  output$pre2k_grade_benchmark <- renderUI({
    
    summary_data <- report_grade_summary()
    team <- team_report_benchmarks()
    
    if (is.null(summary_data)) {
      return("N/A")
    }
    
    team_avg <- NA_real_
    
    if (
      !is.null(team) &&
      "Pre2K_Grade" %in% names(team)
    ) {
      team_avg <- team$Pre2K_Grade
    }
    
    value <- safe_first_numeric(
      summary_data,
      "Pre2K_Grade"
    )
    
    benchmark_span(
      format_report_grade(value),
      value,
      team_avg,
      higher_is_better = TRUE,
      tolerance = 2.0
    )
  })
  
  
  output$twok_grade_benchmark <- renderUI({
    
    summary_data <- report_grade_summary()
    team <- team_report_benchmarks()
    
    if (is.null(summary_data)) {
      return("N/A")
    }
    
    team_avg <- NA_real_
    
    if (
      !is.null(team) &&
      "TwoK_Grade" %in% names(team)
    ) {
      team_avg <- team$TwoK_Grade
    }
    
    value <- safe_first_numeric(
      summary_data,
      "TwoK_Grade"
    )
    
    benchmark_span(
      format_report_grade(value),
      value,
      team_avg,
      higher_is_better = TRUE,
      tolerance = 2.0
    )
  })
  
  
  metric_benchmark_ui <- function(
    column_name,
    higher_is_better = TRUE,
    neutral = FALSE
  ) {
    
    summary_data <- report_decision_metrics()
    team <- team_report_benchmarks()
    
    if (
      is.null(summary_data) ||
      !column_name %in% names(summary_data)
    ) {
      return("N/A")
    }
    
    raw_value <- safe_first_numeric(
      summary_data,
      column_name
    )
    
    team_avg <- NA_real_
    
    if (
      !is.null(team) &&
      column_name %in% names(team)
    ) {
      team_avg <- team[[column_name]]
    }
    
    benchmark_span(
      format_metric_pct(raw_value),
      raw_value,
      team_avg,
      higher_is_better = higher_is_better,
      tolerance = 0.02,
      neutral = neutral
    )
  }
  
  
  output$metric_heart_swing_benchmark <- renderUI({
    metric_benchmark_ui(
      "Heart_Swing_Pct",
      higher_is_better = TRUE
    )
  })
  
  
  output$metric_chase_benchmark <- renderUI({
    metric_benchmark_ui(
      "Chase_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  output$metric_shadow_swing_benchmark <- renderUI({
    metric_benchmark_ui(
      "Shadow_Swing_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  output$metric_overall_swing_benchmark <- renderUI({
    metric_benchmark_ui(
      "Overall_Swing_Pct",
      neutral = TRUE
    )
  })
  
  
  output$metric_whiff_benchmark <- renderUI({
    metric_benchmark_ui(
      "Whiff_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  output$metric_contact_benchmark <- renderUI({
    metric_benchmark_ui(
      "Contact_Pct",
      higher_is_better = TRUE
    )
  })
  
  
  output$metric_hard_contact_benchmark <- renderUI({
    metric_benchmark_ui(
      "Hard_Contact_Pct",
      higher_is_better = TRUE
    )
  })
  
  
  output$metric_heart_take_benchmark <- renderUI({
    metric_benchmark_ui(
      "Heart_Take_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  output$metric_pre2k_heart_benchmark <- renderUI({
    metric_benchmark_ui(
      "Pre2K_Heart_Swing_Pct",
      higher_is_better = TRUE
    )
  })
  
  
  output$metric_pre2k_chase_benchmark <- renderUI({
    metric_benchmark_ui(
      "Pre2K_Chase_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  output$metric_twok_heart_benchmark <- renderUI({
    metric_benchmark_ui(
      "TwoK_Heart_Swing_Pct",
      higher_is_better = TRUE
    )
  })
  
  
  output$metric_twok_chase_benchmark <- renderUI({
    metric_benchmark_ui(
      "TwoK_Chase_Pct",
      higher_is_better = FALSE
    )
  })
  
  
  # ==================================================
  # SPATIAL SWING RATE HEAT MAP — V4
  # ==================================================
  # Uses exact Location_X / Location_Y from each click.
  # Zone / Zone_Group scoring logic is unchanged.
  # ==================================================
  
  report_spatial_swing_data <- reactive({
    
    batter_pitches <- report_batter_pitches()
    
    required_cols <- c(
      "Location_X",
      "Location_Y",
      "Swing_Take"
    )
    
    if (
      nrow(batter_pitches) == 0 ||
      !all(required_cols %in% names(batter_pitches))
    ) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Swing = numeric(0)
      ))
    }
    
    x <- suppressWarnings(as.numeric(batter_pitches$Location_X))
    y <- suppressWarnings(as.numeric(batter_pitches$Location_Y))
    swing_take <- as.character(batter_pitches$Swing_Take)
    
    keep <-
      is.finite(x) &
      is.finite(y) &
      x >= 0 & x <= 1 &
      y >= 0 & y <= 1 &
      swing_take %in% c("Swing", "Take")
    
    if (!any(keep)) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Swing = numeric(0)
      ))
    }
    
    data.frame(
      X = x[keep],
      Y = y[keep],
      Swing = ifelse(swing_take[keep] == "Swing", 1, 0),
      stringsAsFactors = FALSE
    )
  })
  
  
  report_spatial_chase_data <- reactive({
    
    batter_pitches <- report_batter_pitches()
    
    required_cols <- c(
      "Location_X",
      "Location_Y",
      "Swing_Take",
      "Zone_Group"
    )
    
    if (
      nrow(batter_pitches) == 0 ||
      !all(required_cols %in% names(batter_pitches))
    ) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    x <- suppressWarnings(
      as.numeric(batter_pitches$Location_X)
    )
    
    y <- suppressWarnings(
      as.numeric(batter_pitches$Location_Y)
    )
    
    swing_take <- as.character(
      batter_pitches$Swing_Take
    )
    
    zone_group <- as.character(
      batter_pitches$Zone_Group
    )
    
    keep <-
      is.finite(x) &
      is.finite(y) &
      x >= 0 &
      x <= 1 &
      y >= 0 &
      y <= 1 &
      zone_group %in% c("Chase", "Waste") &
      swing_take %in% c("Swing", "Take")
    
    if (!any(keep)) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    data.frame(
      X = x[keep],
      Y = y[keep],
      Value = ifelse(
        swing_take[keep] == "Swing",
        1,
        0
      ),
      stringsAsFactors = FALSE
    )
  })
  
  
  report_spatial_whiff_data <- reactive({
    
    batter_pitches <- report_batter_pitches()
    
    required_cols <- c(
      "Location_X",
      "Location_Y",
      "Pitch_Result",
      "Swing_Take"
    )
    
    if (
      nrow(batter_pitches) == 0 ||
      !all(required_cols %in% names(batter_pitches))
    ) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    x <- suppressWarnings(
      as.numeric(batter_pitches$Location_X)
    )
    
    y <- suppressWarnings(
      as.numeric(batter_pitches$Location_Y)
    )
    
    pitch_result <- as.character(
      batter_pitches$Pitch_Result
    )
    
    swing_take <- as.character(
      batter_pitches$Swing_Take
    )
    
    keep <-
      is.finite(x) &
      is.finite(y) &
      x >= 0 &
      x <= 1 &
      y >= 0 &
      y <= 1 &
      swing_take == "Swing" &
      pitch_result %in% c(
        "Whiff",
        "Foul",
        "In Play"
      )
    
    if (!any(keep)) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    data.frame(
      X = x[keep],
      Y = y[keep],
      Value = ifelse(
        pitch_result[keep] == "Whiff",
        1,
        0
      ),
      stringsAsFactors = FALSE
    )
  })
  
  
  report_spatial_decision_quality_data <- reactive({
    
    batter_pitches <- report_batter_pitches()
    
    required_cols <- c(
      "Location_X",
      "Location_Y",
      "Pitch_Score",
      "Best_Possible",
      "Worst_Possible"
    )
    
    if (
      nrow(batter_pitches) == 0 ||
      !all(required_cols %in% names(batter_pitches))
    ) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    x <- suppressWarnings(
      as.numeric(batter_pitches$Location_X)
    )
    
    y <- suppressWarnings(
      as.numeric(batter_pitches$Location_Y)
    )
    
    pitch_score <- suppressWarnings(
      as.numeric(batter_pitches$Pitch_Score)
    )
    
    best_possible <- suppressWarnings(
      as.numeric(batter_pitches$Best_Possible)
    )
    
    worst_possible <- suppressWarnings(
      as.numeric(batter_pitches$Worst_Possible)
    )
    
    denominator <-
      best_possible -
      worst_possible
    
    normalized_grade <- (
      pitch_score -
        worst_possible
    ) /
      denominator
    
    normalized_grade <- pmax(
      0,
      pmin(
        1,
        normalized_grade
      )
    )
    
    keep <-
      is.finite(x) &
      is.finite(y) &
      x >= 0 &
      x <= 1 &
      y >= 0 &
      y <= 1 &
      is.finite(normalized_grade) &
      is.finite(denominator) &
      denominator != 0
    
    if (!any(keep)) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    data.frame(
      X = x[keep],
      Y = y[keep],
      Value = normalized_grade[keep],
      stringsAsFactors = FALSE
    )
  })
  
  
  report_spatial_contact_quality_data <- reactive({
    
    batter_pitches <- report_batter_pitches()
    
    required_cols <- c(
      "Location_X",
      "Location_Y",
      "Pitch_Result",
      "Contact_Quality",
      "Contact_Modifier"
    )
    
    if (
      nrow(batter_pitches) == 0 ||
      !all(required_cols %in% names(batter_pitches))
    ) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    x <- suppressWarnings(
      as.numeric(batter_pitches$Location_X)
    )
    
    y <- suppressWarnings(
      as.numeric(batter_pitches$Location_Y)
    )
    
    pitch_result <- as.character(
      batter_pitches$Pitch_Result
    )
    
    contact_quality <- as.character(
      batter_pitches$Contact_Quality
    )
    
    contact_modifier <- suppressWarnings(
      as.numeric(batter_pitches$Contact_Modifier)
    )
    
    # Contact Quality heat map is based on balls put in play.
    # Foul balls and whiffs are excluded because the chart is
    # intended to describe quality of batted-ball contact.
    
    keep <-
      is.finite(x) &
      is.finite(y) &
      x >= 0 &
      x <= 1 &
      y >= 0 &
      y <= 1 &
      pitch_result == "In Play" &
      is.finite(contact_modifier)
    
    if (!any(keep)) {
      return(data.frame(
        X = numeric(0),
        Y = numeric(0),
        Value = numeric(0)
      ))
    }
    
    # Current contact modifier range is approximately:
    #   Weak  = -2
    #   Avg   =  0
    #   Hard  = +2
    #
    # Normalize to 0-1 for the shared blue->red heatmap:
    #   -2 -> 0.00
    #    0 -> 0.50
    #   +2 -> 1.00
    
    normalized_contact <- (
      contact_modifier[keep] + 2
    ) / 4
    
    normalized_contact <- pmax(
      0,
      pmin(
        1,
        normalized_contact
      )
    )
    
    data.frame(
      X = x[keep],
      Y = y[keep],
      Value = normalized_contact,
      stringsAsFactors = FALSE
    )
  })
  
  
  spatial_heat_color <- function(rate) {
    
    if (
      length(rate) == 0 ||
      is.na(rate) ||
      !is.finite(rate)
    ) {
      return("#F4F4F4")
    }
    
    rate <- max(0, min(100, as.numeric(rate)))
    
    stops <- data.frame(
      value = c(0, 25, 50, 75, 100),
      r = c(36, 31, 57, 255, 239),
      g = c(89, 174, 220, 205, 49),
      b = c(230, 224, 68, 55, 36)
    )
    
    upper <- which(stops$value >= rate)[1]
    if (is.na(upper)) upper <- nrow(stops)
    lower <- if (upper == 1) 1 else upper - 1
    
    if (lower == upper) {
      rr <- stops$r[lower]
      gg <- stops$g[lower]
      bb <- stops$b[lower]
    } else {
      span <- stops$value[upper] - stops$value[lower]
      pct <- (rate - stops$value[lower]) / span
      
      rr <- round(stops$r[lower] + pct * (stops$r[upper] - stops$r[lower]))
      gg <- round(stops$g[lower] + pct * (stops$g[upper] - stops$g[lower]))
      bb <- round(stops$b[lower] + pct * (stops$b[upper] - stops$b[lower]))
    }
    
    sprintf("#%02X%02X%02X", rr, gg, bb)
  }
  
  
  build_spatial_rate_heatmap <- function(spatial_data) {
    
    # ==================================================
    # POLISHED REPORT HEAT MAP — V5
    # ==================================================
    # Same exact X/Y data and smoothing concept as V4.
    # Changes here are visual only:
    #   - compact report-sized canvas
    #   - no pitch dots
    #   - no visible cell/grid effect
    #   - softer fade into white
    #   - larger strike zone relative to plot
    #   - smooth heat surface
    # ==================================================
    
    # ------------------------------------------------
    # DISPLAY WINDOW
    # ------------------------------------------------
    # Crop the full 0-1 charting coordinate system to
    # the useful report window around the plate.
    #
    # Exact pitch coordinates are NOT changed in storage.
    # This only controls what part of the field is shown.
    # ------------------------------------------------
    
    x_min <- 0.10
    x_max <- 0.90
    y_min <- 0.08
    y_max <- 0.84
    
    plot_x <- 40
    plot_y <- 18
    plot_w <- 300
    plot_h <- 285
    
    # Finer grid + SVG blur makes the individual cells
    # disappear visually into one continuous surface.
    n_cols <- 54
    n_rows <- 52
    
    cell_w <- plot_w / n_cols
    cell_h <- plot_h / n_rows
    
    # Spatial smoothing.
    bandwidth <- 0.085
    
    grid_cells <- character(0)
    
    for (row in seq_len(n_rows)) {
      
      for (col in seq_len(n_cols)) {
        
        # Grid point in DISPLAY-WINDOW coordinates.
        gx <- (col - 0.5) / n_cols
        gy <- (row - 0.5) / n_rows
        
        # Convert display point back into the original
        # normalized 0-1 charting coordinate system.
        cx <- x_min + gx * (x_max - x_min)
        cy <- y_min + gy * (y_max - y_min)
        
        rate <- NA_real_
        opacity <- 0
        
        if (nrow(spatial_data) > 0) {
          
          distances <- sqrt(
            (spatial_data$X - cx)^2 +
              (spatial_data$Y - cy)^2
          )
          
          weights <- exp(
            -0.5 * (distances / bandwidth)^2
          )
          
          weight_sum <- sum(
            weights,
            na.rm = TRUE
          )
          
          if (
            is.finite(weight_sum) &&
            weight_sum > 0.015
          ) {
            
            rate <- 100 * sum(
              weights * spatial_data$Value,
              na.rm = TRUE
            ) / weight_sum
            
            # Density-based opacity. Sparse areas fade
            # gradually to white instead of ending at a
            # hard radius.
            opacity <- 1 - exp(
              -0.42 * weight_sum
            )
            
            opacity <- max(
              0,
              min(
                0.96,
                opacity
              )
            )
          }
        }
        
        if (!is.na(rate) && opacity > 0.02) {
          
          fill <- spatial_heat_color(rate)
          
          x <- plot_x + (col - 1) * cell_w
          y <- plot_y + (row - 1) * cell_h
          
          grid_cells <- c(
            grid_cells,
            paste0(
              '<rect x="', round(x, 2),
              '" y="', round(y, 2),
              '" width="', round(cell_w + 0.8, 2),
              '" height="', round(cell_h + 0.8, 2),
              '" fill="', fill,
              '" fill-opacity="', round(opacity, 3),
              '" stroke="none"/>'
            )
          )
        }
      }
    }
    
    # ------------------------------------------------
    # STRIKE ZONE OVERLAY
    # ------------------------------------------------
    # Same locked geometry, transformed into the cropped
    # display window.
    # ------------------------------------------------
    
    strike_left_norm <- 202 / 520
    strike_right_norm <- 318 / 520
    strike_top_norm <- 200 / 520
    strike_bottom_norm <- 335 / 520
    
    map_x <- function(x_norm) {
      plot_x +
        plot_w *
        (
          (x_norm - x_min) /
            (x_max - x_min)
        )
    }
    
    map_y <- function(y_norm) {
      plot_y +
        plot_h *
        (
          (y_norm - y_min) /
            (y_max - y_min)
        )
    }
    
    strike_x <- map_x(
      strike_left_norm
    )
    
    strike_y <- map_y(
      strike_top_norm
    )
    
    strike_w <- map_x(
      strike_right_norm
    ) - strike_x
    
    strike_h <- map_y(
      strike_bottom_norm
    ) - strike_y
    
    strike_overlay <- paste0(
      
      '<rect x="', strike_x,
      '" y="', strike_y,
      '" width="', strike_w,
      '" height="', strike_h,
      '" fill="none" stroke="#2F2F2F" stroke-width="1.7"/>',
      
      '<line x1="', strike_x + strike_w/3,
      '" y1="', strike_y,
      '" x2="', strike_x + strike_w/3,
      '" y2="', strike_y + strike_h,
      '" stroke="#575757" stroke-width="0.8"/>',
      
      '<line x1="', strike_x + 2*strike_w/3,
      '" y1="', strike_y,
      '" x2="', strike_x + 2*strike_w/3,
      '" y2="', strike_y + strike_h,
      '" stroke="#575757" stroke-width="0.8"/>',
      
      '<line x1="', strike_x,
      '" y1="', strike_y + strike_h/3,
      '" x2="', strike_x + strike_w,
      '" y2="', strike_y + strike_h/3,
      '" stroke="#575757" stroke-width="0.8"/>',
      
      '<line x1="', strike_x,
      '" y1="', strike_y + 2*strike_h/3,
      '" x2="', strike_x + strike_w,
      '" y2="', strike_y + 2*strike_h/3,
      '" stroke="#575757" stroke-width="0.8"/>'
    )
    
    # ------------------------------------------------
    # HOME PLATE
    # ------------------------------------------------
    
    plate_y <- plot_y + plot_h + 7
    
    plate <- paste0(
      '<polygon points="157,', plate_y,
      ' 223,', plate_y,
      ' 231,', plate_y + 7,
      ' 190,', plate_y + 18,
      ' 149,', plate_y + 7,
      '" fill="#fff" stroke="#333" stroke-width="1.3"/>'
    )
    
    # ------------------------------------------------
    # COLOR LEGEND
    # ------------------------------------------------
    
    legend_y <- plate_y + 27
    
    legend <- paste0(
      '<defs>',
      
      '<linearGradient id="spatialSwingGradientV5" x1="0%" x2="100%" y1="0%" y2="0%">',
      '<stop offset="0%" stop-color="#2459E6"/>',
      '<stop offset="25%" stop-color="#1FAEE0"/>',
      '<stop offset="50%" stop-color="#39DC44"/>',
      '<stop offset="75%" stop-color="#FFCD37"/>',
      '<stop offset="100%" stop-color="#EF3124"/>',
      '</linearGradient>',
      
      '<filter id="heatBlurV5" x="-15%" y="-15%" width="130%" height="130%">',
      '<feGaussianBlur stdDeviation="2.7"/>',
      '</filter>',
      
      '<clipPath id="heatClipV5">',
      '<rect x="', plot_x,
      '" y="', plot_y,
      '" width="', plot_w,
      '" height="', plot_h,
      '"/>',
      '</clipPath>',
      
      '</defs>',
      
      '<rect x="78" y="', legend_y,
      '" width="224" height="9" ',
      'rx="1" ry="1" ',
      'fill="url(#spatialSwingGradientV5)" ',
      'stroke="#777777" stroke-width="0.6"/>',
      
      '<text x="78" y="', legend_y + 24,
      '" text-anchor="middle" font-size="9.5">0%</text>',
      
      '<text x="190" y="', legend_y + 24,
      '" text-anchor="middle" font-size="9.5">50%</text>',
      
      '<text x="302" y="', legend_y + 24,
      '" text-anchor="middle" font-size="9.5">100%</text>'
    )
    
    # ------------------------------------------------
    # EMPTY STATE
    # ------------------------------------------------
    
    empty_message <- if (
      nrow(spatial_data) == 0
    ) {
      
      paste0(
        '<text x="190" y="145" ',
        'text-anchor="middle" ',
        'font-size="13" ',
        'font-weight="700" ',
        'fill="#777777">',
        'No exact pitch-location data available',
        '</text>'
      )
      
    } else {
      
      ""
    }
    
    # ------------------------------------------------
    # FINAL SVG
    # ------------------------------------------------
    
    HTML(
      paste0(
        '<div style="max-width:168px;margin:0 auto;">',
        '<svg viewBox="0 0 380 372" width="100%" height="auto" ',
        'xmlns="http://www.w3.org/2000/svg">',
        
        legend,
        
        '<rect x="', plot_x,
        '" y="', plot_y,
        '" width="', plot_w,
        '" height="', plot_h,
        '" fill="#ffffff"/>',
        
        '<g clip-path="url(#heatClipV5)" filter="url(#heatBlurV5)">',
        paste0(
          grid_cells,
          collapse = ""
        ),
        '</g>',
        
        strike_overlay,
        plate,
        empty_message,
        
        '</svg>',
        '</div>'
      )
    )
  }
  
  
  build_spatial_swing_rate_heatmap <- function(spatial_data) {
    
    if (
      nrow(spatial_data) > 0 &&
      "Swing" %in% names(spatial_data)
    ) {
      spatial_data$Value <- spatial_data$Swing
    }
    
    build_spatial_rate_heatmap(
      spatial_data
    )
  }
  
  
  build_spatial_chase_rate_heatmap <- function(spatial_data) {
    
    build_spatial_rate_heatmap(
      spatial_data
    )
  }
  
  
  build_spatial_whiff_rate_heatmap <- function(spatial_data) {
    
    build_spatial_rate_heatmap(
      spatial_data
    )
  }
  
  
  build_spatial_decision_quality_heatmap <- function(spatial_data) {
    
    build_spatial_rate_heatmap(
      spatial_data
    )
  }
  
  
  build_spatial_contact_quality_heatmap <- function(spatial_data) {
    
    build_spatial_rate_heatmap(
      spatial_data
    )
  }
  
  
  format_report_grade <- function(x) {
    if (length(x) == 0 || is.na(x)) return("N/A")
    sprintf("%.1f", as.numeric(x))
  }
  
  
  format_metric_pct <- function(x) {
    if (length(x) == 0 || is.na(x)) return("N/A")
    paste0(sprintf("%.1f", as.numeric(x)), "%")
  }
  
  output$overall_grade <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("N/A")
    format_report_grade(x$Overall_Grade[1])
  })
  
  output$overall_sample <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("0 pitches")
    paste0(x$Overall_Pitches[1], " pitches")
  })
  
  output$pre2k_grade <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("N/A")
    format_report_grade(x$Pre2K_Grade[1])
  })
  
  output$pre2k_sample <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("0 pitches")
    paste0(x$Pre2K_Pitches[1], " pitches")
  })
  
  output$twok_grade <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("N/A")
    format_report_grade(x$TwoK_Grade[1])
  })
  
  output$twok_sample <- renderText({
    x <- report_grade_summary()
    if (is.null(x)) return("0 pitches")
    paste0(x$TwoK_Pitches[1], " pitches")
  })
  
  output$metric_heart_swing <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Heart_Swing_Pct[1])
  })
  
  output$metric_heart_take <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Heart_Take_Pct[1])
  })
  
  output$metric_chase <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Chase_Pct[1])
  })
  
  output$metric_shadow_swing <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Shadow_Swing_Pct[1])
  })
  
  output$metric_overall_swing <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Overall_Swing_Pct[1])
  })
  
  output$metric_whiff <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Whiff_Pct[1])
  })
  
  output$metric_contact <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Contact_Pct[1])
  })
  
  output$metric_hard_contact <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Hard_Contact_Pct[1])
  })
  
  output$metric_pre2k_heart <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Pre2K_Heart_Swing_Pct[1])
  })
  
  output$metric_twok_heart <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$TwoK_Heart_Swing_Pct[1])
  })
  
  output$metric_pre2k_chase <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$Pre2K_Chase_Pct[1])
  })
  
  output$metric_twok_chase <- renderText({
    x <- report_decision_metrics()
    if (is.null(x)) return("N/A")
    format_metric_pct(x$TwoK_Chase_Pct[1])
  })
  
  output$swing_rate_overall <- renderText({
    x <- report_decision_metrics()
    
    if (
      is.null(x) ||
      is.na(x$Overall_Swing_Pct[1])
    ) {
      return("N/A")
    }
    
    paste0(
      sprintf(
        "%.1f",
        x$Overall_Swing_Pct[1]
      ),
      "%"
    )
  })
  
  output$swing_rate_sample <- renderText({
    batter_pitches <- report_batter_pitches()
    
    paste0(
      "Pitches: ",
      nrow(batter_pitches)
    )
  })
  
  output$swing_rate_heatmap <- renderUI({
    
    spatial_data <- report_spatial_swing_data()
    
    build_spatial_swing_rate_heatmap(
      spatial_data
    )
  })
  
  
  output$chase_rate_overall <- renderText({
    
    x <- report_decision_metrics()
    
    if (
      is.null(x) ||
      is.na(x$Chase_Pct[1])
    ) {
      return("N/A")
    }
    
    paste0(
      sprintf(
        "%.1f",
        x$Chase_Pct[1]
      ),
      "%"
    )
  })
  
  output$chase_rate_sample <- renderText({
    
    spatial_data <- report_spatial_chase_data()
    
    paste0(
      "Chase-zone pitches: ",
      nrow(spatial_data)
    )
  })
  
  output$chase_rate_heatmap <- renderUI({
    
    spatial_data <- report_spatial_chase_data()
    
    build_spatial_chase_rate_heatmap(
      spatial_data
    )
  })
  
  
  output$whiff_rate_overall <- renderText({
    
    x <- report_decision_metrics()
    
    if (
      is.null(x) ||
      is.na(x$Whiff_Pct[1])
    ) {
      return("N/A")
    }
    
    paste0(
      sprintf(
        "%.1f",
        x$Whiff_Pct[1]
      ),
      "%"
    )
  })
  
  output$whiff_rate_sample <- renderText({
    
    spatial_data <- report_spatial_whiff_data()
    
    paste0(
      "Swings: ",
      nrow(spatial_data)
    )
  })
  
  output$whiff_rate_heatmap <- renderUI({
    
    spatial_data <- report_spatial_whiff_data()
    
    build_spatial_whiff_rate_heatmap(
      spatial_data
    )
  })
  
  
  output$decision_quality_overall <- renderText({
    
    x <- report_grade_summary()
    
    if (
      is.null(x) ||
      is.na(x$Overall_Grade[1])
    ) {
      return("N/A")
    }
    
    sprintf(
      "%.1f",
      x$Overall_Grade[1]
    )
  })
  
  output$decision_quality_sample <- renderText({
    
    spatial_data <- report_spatial_decision_quality_data()
    
    paste0(
      "Pitches: ",
      nrow(spatial_data)
    )
  })
  
  output$decision_quality_heatmap <- renderUI({
    
    spatial_data <- report_spatial_decision_quality_data()
    
    build_spatial_decision_quality_heatmap(
      spatial_data
    )
  })
  
  
  output$contact_quality_overall <- renderText({
    
    spatial_data <- report_spatial_contact_quality_data()
    
    if (nrow(spatial_data) == 0) {
      return("N/A")
    }
    
    # Convert the normalized 0-1 values back to the
    # original contact-modifier scale (-2 to +2) for
    # the headline value shown above the heat map.
    
    avg_normalized <- mean(
      spatial_data$Value,
      na.rm = TRUE
    )
    
    avg_modifier <- (
      avg_normalized * 4
    ) - 2
    
    paste0(
      ifelse(
        avg_modifier > 0,
        "+",
        ""
      ),
      sprintf(
        "%.2f",
        avg_modifier
      )
    )
  })
  
  output$contact_quality_sample <- renderText({
    
    spatial_data <- report_spatial_contact_quality_data()
    
    paste0(
      "Balls in play: ",
      nrow(spatial_data)
    )
  })
  
  output$contact_quality_heatmap <- renderUI({
    
    spatial_data <- report_spatial_contact_quality_data()
    
    build_spatial_contact_quality_heatmap(
      spatial_data
    )
  })
  
  output$report_status <- renderUI({
    if (!is.null(report_load_error())) {
      return(div(class = "warning-text", paste0("Report load error: ", report_load_error())))
    }
    
    if (is.null(input$report_batter) || input$report_batter == "") {
      return(div(class = "warning-text", "Select a hitter to view the report."))
    }
    
    pitches_data <- report_pitches()
    if (nrow(pitches_data) == 0) {
      return(div(class = "warning-text", "No charted pitches are available yet."))
    }
    
    batter_pitches <- report_batter_pitches()
    
    if (nrow(batter_pitches) == 0) {
      return(div(class = "warning-text", "No charted pitches are available for this hitter yet."))
    }
    
    div(class = "success-text",
        paste0("Report loaded from ", nrow(batter_pitches), " charted pitches."))
  })
  
  # ==================================================
  # SAVE PITCH
  # ==================================================
  
  save_pitch_to_sheet <- function(
    pitch_result,
    contact_quality = "",
    pa_result_on_pitch = ""
  ) {
    
    session_id <-
      current_session_id()
    
    if (is.null(session_id)) {
      
      save_status(
        "Select a Session before charting."
      )
      
      return(FALSE)
    }
    
    zone <- selected_zone()
    location_x <- selected_location_x()
    location_y <- selected_location_y()
    
    pitch_type <-
      selected_pitch_type()
    
    balls_before <- balls()
    strikes_before <- strikes()
    
    score_details <- score_pitch_decision_details(
      zone = zone,
      strikes_before = strikes_before,
      pitch_result = pitch_result,
      contact_quality = contact_quality,
      pa_result_on_pitch = pa_result_on_pitch
    )
    
    base_decision_value <- score_details$Base_Decision_Score[1]
    contact_modifier <- score_details$Execution_Modifier[1]
    pitch_score <- score_details$Final_Pitch_Score[1]
    
    pitch_data_main <-
      data.frame(
        
        Pitch_ID = unique_record_id("PITCH",session_id),
        
        Organization_ID =
          current_org_id(),
        
        Session_ID =
          session_id,
        
        PA_ID =
          ifelse(identical(input$charting_mode,"Bullpen"),"",current_pa_id()),
        
        Pitch_Number =
          pitch_number(),
        
        Batter_ID =
          ifelse(identical(input$charting_mode,"Bullpen"),"",current_batter_id()),
        
        Pitcher_ID =
          current_pitcher_id(),
        
        Balls_Before =
          balls_before,
        
        Strikes_Before =
          strikes_before,
        
        Count =
          paste0(
            balls_before,
            "-",
            strikes_before
          ),
        
        Count_State =
          count_state(
            strikes_before
          ),
        
        Pitch_Type =
          pitch_type,
        
        Pitch_Group =
          pitch_group(
            pitch_type
          ),
        
        Zone =
          zone,
        
        Zone_Group =
          zone_group(
            zone
          ),
        
        Pitch_Result =
          pitch_result,
        
        Swing_Take =
          ifelse(identical(input$charting_mode,"Bullpen"),"",swing_take(pitch_result)),
        
        Contact_Quality =
          contact_quality,
        
        PA_Result_On_Pitch =
          pa_result_on_pitch,
        
        stringsAsFactors = FALSE
      )
    
    pitch_score_data <- data.frame(
      
      Base_Decision_Value =
        base_decision_value,
      
      Contact_Modifier =
        contact_modifier,
      
      Pitch_Score =
        pitch_score,
      
      stringsAsFactors = FALSE
    )
    pitch_data_end <-
      data.frame(
        
        Timestamp =
          format(
            Sys.time(),
            "%Y-%m-%d %H:%M:%S"
          ),
        
        Notes = "",
        
        stringsAsFactors = FALSE
      )
    
    tryCatch(
      
      {
        
        pitch_location_data <- data.frame(
          Location_X=ifelse(is.null(location_x)||is.na(location_x),"",round(location_x,6)),
          Location_Y=ifelse(is.null(location_y)||is.na(location_y),"",round(location_y,6)),
          Inning=ifelse(identical(input$charting_mode,"Bullpen"),"",ifelse(is.null(input$inning_number)||is.na(input$inning_number),"",as.integer(input$inning_number))),
          Half_Inning=ifelse(identical(input$charting_mode,"Bullpen"),"",ifelse(is.null(input$inning_half)||input$inning_half=="","Top",as.character(input$inning_half))),
          Outs_Before=ifelse(identical(input$charting_mode,"Bullpen"),"",as.integer(game_outs())),
          stringsAsFactors=FALSE
        )
        bullpen_extra_data <- data.frame(
          Charting_Mode=ifelse(identical(input$charting_mode,"Bullpen"),"Bullpen","Live"),
          Bullpen_Target_X=ifelse(identical(input$charting_mode,"Bullpen")&&!is.null(bullpen_target_x()),round(as.numeric(bullpen_target_x()),6),""),
          Bullpen_Target_Y=ifelse(identical(input$charting_mode,"Bullpen")&&!is.null(bullpen_target_y()),round(as.numeric(bullpen_target_y()),6),""),
          Bullpen_Target_Zone=ifelse(identical(input$charting_mode,"Bullpen")&&!is.null(bullpen_target_zone()),as.character(bullpen_target_zone()),""),
          Bullpen_Focus=ifelse(identical(input$charting_mode,"Bullpen"),as.character(input$bullpen_focus),""),
          Bullpen_Notes=ifelse(identical(input$charting_mode,"Bullpen"),as.character(input$bullpen_notes),""),
          stringsAsFactors=FALSE
        )
        ensure_multi_user_pitch_columns()
        pitch_row_values<-c(
          unname(as.list(pitch_data_main[1,])),
          unname(as.list(pitch_score_data[1,])),
          unname(as.list(pitch_data_end[1,])),
          list("","",""),
          unname(as.list(pitch_location_data[1,])),
          unname(as.list(bullpen_extra_data[1,])),
          list(current_charting_user(),client_instance_id)
        )
        append_row_atomic("Pitches",pitch_row_values)
        
        save_status(
          paste0(
            "Saved Pitch ",
            pitch_number(),
            " — Session ",
            session_id
          )
        )
        
        if(!identical(input$charting_mode,"Bullpen")) {
          pa_pitch_count(pa_pitch_count()+1)
          if(is.finite(suppressWarnings(as.numeric(strikes_before)))&&suppressWarnings(as.numeric(strikes_before))>=2){
            pitches_after_2k(pitches_after_2k()+1)
          }
        }
        
        pitch_number(
          pitch_number() + 1
        )
        
        TRUE
        
      },
      
      error = function(e) {
        
        save_status(
          paste0(
            "Pitch save error: ",
            e$message
          )
        )
        
        FALSE
        
      }
      
    )
    
  }
  
  # ==================================================
  # SAVE PA
  # ==================================================
  
  save_pa_to_sheet <- function(
    result
  ) {
    
    session_id <-
      current_session_id()
    
    if (is.null(session_id)) {
      
      save_status(
        "Select a Session before saving a PA."
      )
      
      return(FALSE)
    }
    
    is_ab <- ifelse(
      result %in% c(
        "Walk",
        "Hit By Pitch",
        "Sac Fly",
        "Sac Bunt"
      ),
      0,
      1
    )
    
    is_hit <- ifelse(
      result %in% c(
        "Single",
        "Double",
        "Triple",
        "Home Run"
      ),
      1,
      0
    )
    
    bases_total <- ifelse(
      result == "Single",
      1,
      ifelse(
        result == "Double",
        2,
        ifelse(
          result == "Triple",
          3,
          ifelse(
            result == "Home Run",
            4,
            0
          )
        )
      )
    )
    
    is_bb <- ifelse(
      result == "Walk",
      1,
      0
    )
    
    is_hbp <- ifelse(
      result == "Hit By Pitch",
      1,
      0
    )
    
    is_sf <- ifelse(
      result == "Sac Fly",
      1,
      0
    )
    
    is_sac_bunt <- ifelse(
      result == "Sac Bunt",
      1,
      0
    )
    
    is_k <- ifelse(
      result %in% c(
        "Strikeout Swinging",
        "Strikeout Looking"
      ),
      1,
      0
    )
    
    k_type <- ifelse(
      result ==
        "Strikeout Swinging",
      "Swinging",
      ifelse(
        result ==
          "Strikeout Looking",
        "Looking",
        ""
      )
    )
    
    quab_rbi <- ifelse(is.null(input$pa_rbi) || is.na(input$pa_rbi),0L,as.integer(input$pa_rbi))
    quab_pitch_count <- max(0L,as.integer(pa_pitch_count()))
    quab_after_2k_count <- max(0L,as.integer(pitches_after_2k()))
    quab_barrel_flag <- identical(
      selected_contact_quality(),
      "Hard"
    )
    quab_offensive_play_flag <- isTRUE(input$quab_offensive_play) || result %in% c("Sac Fly","Sac Bunt")
    quab_move_runner_third_flag <- isTRUE(input$quab_move_runner_third)
    quab_reasons <- character(0)
    if(is_hit==1) quab_reasons<-c(quab_reasons,"Hit")
    if(is_bb==1 || is_hbp==1) quab_reasons<-c(quab_reasons,"Walk/HBP")
    if(quab_rbi>0) quab_reasons<-c(quab_reasons,"RBI")
    if(quab_pitch_count>=8) quab_reasons<-c(quab_reasons,"8+ Pitch PA")
    if(quab_after_2k_count>=4) quab_reasons<-c(quab_reasons,"4+ Pitches After 2K")
    if(quab_barrel_flag) quab_reasons<-c(quab_reasons,"Barrel")
    if(quab_offensive_play_flag) quab_reasons<-c(quab_reasons,"Successful Offensive Play")
    if(quab_move_runner_third_flag) quab_reasons<-c(quab_reasons,"Moved Runner to 3rd <2 Outs")
    if(result=="Reached on Error") quab_reasons<-c(quab_reasons,"Reached on Error")
    quab_flag <- length(quab_reasons)>0
    
    pa_data <- data.frame(
      
      PA_ID =
        current_pa_id(),
      
      Organization_ID =
        current_org_id(),
      
      Session_ID =
        session_id,
      
      PA_Number =
        pa_number(),
      
      Batter_ID =
        current_batter_id(),
      
      Pitcher_ID =
        current_pitcher_id(),
      
      Batter_Side =
        current_batter_side(),
      
      Start_Balls = 0,
      
      Start_Strikes = 0,
      
      PA_Result =
        result,
      
      Is_AB =
        is_ab,
      
      Is_Hit =
        is_hit,
      
      Bases_Total =
        bases_total,
      
      Is_BB =
        is_bb,
      
      Is_HBP =
        is_hbp,
      
      Is_SF =
        is_sf,
      
      Is_SAC_Bunt =
        is_sac_bunt,
      
      Is_K =
        is_k,
      
      K_Type =
        k_type,
      
      Runs_Batted_In = ifelse(is.null(input$pa_rbi) || is.na(input$pa_rbi), 0, as.integer(input$pa_rbi)),
      
      Notes = "",
      
      stringsAsFactors = FALSE
    )
    
    tryCatch(
      
      {
        
        quab_extra_data <- data.frame(
          Is_Barrel=as.integer(quab_barrel_flag),
          Is_Offensive_Play=as.integer(quab_offensive_play_flag),
          Move_Runner_3rd_LT2=as.integer(quab_move_runner_third_flag),
          Is_QUAB=as.integer(quab_flag),
          QUAB_Reasons=paste(unique(quab_reasons),collapse="; "),
          stringsAsFactors=FALSE
        )
        pa_row_values<-c(unname(as.list(pa_data[1,])),unname(as.list(quab_extra_data[1,])))
        append_row_atomic("Plate_Appearances",pa_row_values)
        
        save_status(
          paste0(
            "Saved PA ",
            pa_number(),
            " — ",
            result
          )
        )
        
        add_recorded_outs(outs_for_pa_result(result))
        
        TRUE
        
      },
      
      error = function(e) {
        
        save_status(
          paste0(
            "PA save error: ",
            e$message
          )
        )
        
        FALSE
        
      }
      
    )
    
  }
  
  # ==================================================
  # COUNT
  # ==================================================
  
  output$count <- renderText({
    
    if (pa_complete()) {
      
      paste0(
        balls(),
        " - ",
        strikes(),
        "   |   PA COMPLETE"
      )
      
    } else {
      
      paste0(
        balls(),
        " - ",
        strikes()
      )
      
    }
    
  })
  
  # ==================================================
  # PITCH TYPE BUTTONS
  # ==================================================
  
  output$selected_pitch_type <-
    renderText({
      selected_pitch_type()
    })
  
  observeEvent(input$pitch_fb, {
    selected_pitch_type("FB")
  })
  
  observeEvent(input$pitch_si, {
    selected_pitch_type("SI")
  })
  
  observeEvent(input$pitch_ct, {
    selected_pitch_type("CT")
  })
  
  observeEvent(input$pitch_sl, {
    selected_pitch_type("SL")
  })
  
  observeEvent(input$pitch_cb, {
    selected_pitch_type("CB")
  })
  
  observeEvent(input$pitch_sw, {
    selected_pitch_type("SW")
  })
  
  observeEvent(input$pitch_ch, {
    selected_pitch_type("CH")
  })
  
  observeEvent(input$pitch_split, {
    selected_pitch_type("SPLIT")
  })
  
  observeEvent(input$pitch_other, {
    selected_pitch_type("OTHER")
  })
  
  # ==================================================
  # STRIKE ZONE
  # ==================================================
  
  output$strike_zone_svg <- renderUI({
    build_strike_zone(
      selected_zone = selected_zone()
    )
  })
  
  # ==================================================
  # ZONE CLICK
  # ==================================================
  
  observeEvent(
    input$zone_click,
    {
      if(identical(input$charting_mode,"Bullpen")) {
        if(is.null(bullpen_target_x())) {
          bullpen_target_zone(as.integer(input$zone_click))
        } else {
          selected_zone(as.integer(input$zone_click))
        }
      } else if(!pa_complete()) {
        selected_zone(as.integer(input$zone_click))
      }
    }
  )
  
  
  # ==================================================
  # EXACT CLICK LOCATION
  # ==================================================
  
  observeEvent(
    input$zone_click_location,
    {
      if(is.null(input$zone_click_location))return()
      x<-suppressWarnings(as.numeric(input$zone_click_location$x_norm))
      y<-suppressWarnings(as.numeric(input$zone_click_location$y_norm))
      if(!is.finite(x)||!is.finite(y))return()
      
      if(identical(input$charting_mode,"Bullpen")) {
        if(is.null(bullpen_target_x())||is.null(bullpen_target_y())) {
          bullpen_target_x(x)
          bullpen_target_y(y)
          selected_zone(NULL)
          selected_location_x(NULL)
          selected_location_y(NULL)
        } else {
          selected_location_x(x)
          selected_location_y(y)
        }
      } else if(!pa_complete()) {
        selected_location_x(x)
        selected_location_y(y)
      }
    }
  )
  
  observeEvent(input$bullpen_reset_target,{
    bullpen_target_x(NULL)
    bullpen_target_y(NULL)
    bullpen_target_zone(NULL)
    selected_zone(NULL)
    selected_location_x(NULL)
    selected_location_y(NULL)
  })
  
  observeEvent(input$charting_mode,{
    bullpen_target_x(NULL)
    bullpen_target_y(NULL)
    bullpen_target_zone(NULL)
    selected_zone(NULL)
    selected_location_x(NULL)
    selected_location_y(NULL)
  },ignoreInit=TRUE)
  
  output$bullpen_click_step_ui<-renderUI({
    if(!identical(input$charting_mode,"Bullpen"))return(NULL)
    target_set<-!is.null(bullpen_target_x())&&!is.null(bullpen_target_y())
    actual_set<-!is.null(selected_location_x())&&!is.null(selected_location_y())
    tagList(
      div(class=paste("bullpen-click-step",if(!target_set)"active"else""),"1. SET CATCHER TARGET"),
      div(class=paste("bullpen-click-step",if(target_set&&!actual_set)"active"else""),"2. CHART ACTUAL PITCH"),
      div(class=paste("bullpen-click-step",if(target_set&&actual_set)"active"else""),"3. BALL / STRIKE")
    )
  })
  
  output$bullpen_target_mitt_overlay<-renderUI({
    if(!identical(input$charting_mode,"Bullpen")||is.null(bullpen_target_x())||is.null(bullpen_target_y()))return(NULL)
    x<-max(0,min(1,as.numeric(bullpen_target_x())))
    y<-max(0,min(1,as.numeric(bullpen_target_y())))
    tagList(
      div(
        class="bullpen-target-mitt",
        style=paste0("left:",sprintf("%.3f",100*x),"%;top:",sprintf("%.3f",100*y),"%;"),
        HTML('<svg viewBox="0 0 48 48" aria-hidden="true"><path d="M12 28c-1-8 2-16 8-18 3-1 5 1 5 4 1-4 5-5 7-2 1 1 1 4 0 6 3-3 7-1 7 2 0 2-2 5-4 7 0 8-6 14-15 14-7 0-11-5-12-12z" fill="#9a5b2d" stroke="#5e3216" stroke-width="2"/><path d="M22 16c1 5 1 10 0 15M28 16c0 5-1 10-3 15M34 20c-2 4-4 8-7 12" fill="none" stroke="#5e3216" stroke-width="1.5" stroke-linecap="round"/></svg>')
      ),
      div(
        class="bullpen-target-label",
        style=paste0("left:",sprintf("%.3f",100*x),"%;top:",sprintf("%.3f",100*y),"%;"),
        "TARGET"
      )
    )
  })
  
  output$selected_zone_text <-
    renderText({
      
      if(identical(input$charting_mode,"Bullpen")) {
        if(is.null(bullpen_target_x()))return("Click the catcher target first")
        if(is.null(selected_location_x()))return("Target set — now click actual pitch location")
        return("Target + actual location set — choose BALL or STRIKE")
      }
      if(is.null(selected_zone()))return("None")
      paste0(selected_zone()," — ",zone_group(selected_zone()))
      
    })
  
  # ==================================================
  # LAST RESULT
  # ==================================================
  
  output$last_pitch_result <-
    renderText({
      last_pitch_result()
    })
  
  # ==================================================
  # VALIDATION
  # ==================================================
  
  pitch_ready <- function() {
    
    if (
      is.null(
        current_session_id()
      )
    ) {
      
      save_status(
        "Select or create a Session first."
      )
      
      return(FALSE)
    }
    
    if(!identical(input$charting_mode,"Bullpen")) {
      if(pa_complete()) return(FALSE)
      if(in_play_active()) return(FALSE)
    }
    
    if (
      selected_pitch_type() ==
      "None"
    ) {
      return(FALSE)
    }
    
    if(identical(input$charting_mode,"Bullpen")) {
      if(is.null(bullpen_target_x())||is.null(bullpen_target_y())) {
        save_status("Click the catcher target on the strike-zone map first.")
        return(FALSE)
      }
      if(is.null(selected_zone())||is.null(selected_location_x())||is.null(selected_location_y())) {
        save_status("Now click the actual pitch location on the strike-zone map.")
        return(FALSE)
      }
    } else if(is.null(selected_zone())) {
      return(FALSE)
    }
    TRUE
  }
  
  reset_pitch_selection <-
    function() {
      
      selected_pitch_type(
        "None"
      )
      
      selected_zone(NULL)
      selected_location_x(NULL)
      selected_location_y(NULL)
      if(identical(input$charting_mode,"Bullpen")) {
        bullpen_target_x(NULL)
        bullpen_target_y(NULL)
        bullpen_target_zone(NULL)
      }
      
    }
  
  # ==================================================
  # BALL
  # ==================================================
  
  observeEvent(
    input$result_ball,
    {
      
      if (!pitch_ready()) {
        return()
      }
      
      is_walk <-
        balls() == 3
      
      save_pitch_to_sheet(
        
        pitch_result =
          "Ball",
        
        pa_result_on_pitch =
          ifelse(
            is_walk,
            "Walk",
            ""
          )
        
      )
      
      last_pitch_result(
        "Ball"
      )
      
      if (is_walk) {
        
        save_pa_to_sheet(
          "Walk"
        )
        
        pa_complete(TRUE)
        
        pa_result(
          "Walk"
        )
        
      } else {
        
        balls(
          balls() + 1
        )
        
        reset_pitch_selection()
        
      }
      
    }
  )
  
  # ==================================================
  # CALLED STRIKE
  # ==================================================
  
  observeEvent(input$result_hbp,{if(pa_complete()||in_play_active())return();if(!pitch_ready())return();save_pitch_to_sheet(pitch_result="Ball",pa_result_on_pitch="Hit By Pitch");save_pa_to_sheet("Hit By Pitch");pa_complete(TRUE);pa_result("Hit By Pitch")})
  
  observeEvent(input$bullpen_result_strike,{
    if(!identical(input$charting_mode,"Bullpen"))return()
    if(!pitch_ready())return()
    if(isTRUE(save_pitch_to_sheet("Called Strike","",""))) {
      last_pitch_result("Strike")
      reset_pitch_selection()
    }
  })
  observeEvent(input$bullpen_result_ball,{
    if(!identical(input$charting_mode,"Bullpen"))return()
    if(!pitch_ready())return()
    if(isTRUE(save_pitch_to_sheet("Ball","",""))) {
      last_pitch_result("Ball")
      reset_pitch_selection()
    }
  })
  
  observeEvent(
    input$result_called_strike,
    {
      
      if (!pitch_ready()) {
        return()
      }
      
      is_k <-
        strikes() == 2
      
      save_pitch_to_sheet(
        
        pitch_result =
          "Called Strike",
        
        pa_result_on_pitch =
          ifelse(
            is_k,
            "Strikeout Looking",
            ""
          )
        
      )
      
      last_pitch_result(
        "Called Strike"
      )
      
      if (is_k) {
        
        save_pa_to_sheet(
          "Strikeout Looking"
        )
        
        pa_complete(TRUE)
        
        pa_result(
          "Strikeout Looking"
        )
        
      } else {
        
        strikes(
          strikes() + 1
        )
        
        reset_pitch_selection()
        
      }
      
    }
  )
  
  # ==================================================
  # WHIFF
  # ==================================================
  
  observeEvent(
    input$result_whiff,
    {
      
      if (!pitch_ready()) {
        return()
      }
      
      is_k <-
        strikes() == 2
      
      save_pitch_to_sheet(
        
        pitch_result =
          "Whiff",
        
        pa_result_on_pitch =
          ifelse(
            is_k,
            "Strikeout Swinging",
            ""
          )
        
      )
      
      last_pitch_result(
        "Whiff"
      )
      
      if (is_k) {
        
        save_pa_to_sheet(
          "Strikeout Swinging"
        )
        
        pa_complete(TRUE)
        
        pa_result(
          "Strikeout Swinging"
        )
        
      } else {
        
        strikes(
          strikes() + 1
        )
        
        reset_pitch_selection()
        
      }
      
    }
  )
  
  # ==================================================
  # FOUL
  # ==================================================
  
  observeEvent(
    input$result_foul,
    {
      
      if (!pitch_ready()) {
        return()
      }
      
      save_pitch_to_sheet(
        "Foul"
      )
      
      last_pitch_result(
        "Foul"
      )
      
      if (
        strikes() < 2
      ) {
        
        strikes(
          strikes() + 1
        )
        
      }
      
      reset_pitch_selection()
      
    }
  )
  
  # ==================================================
  # IN PLAY
  # ==================================================
  
  observeEvent(
    input$result_in_play,
    {
      
      if (!pitch_ready()) {
        return()
      }
      
      last_pitch_result(
        "In Play"
      )
      
      in_play_active(
        TRUE
      )
      
      selected_contact_quality(
        NULL
      )
      
      selected_in_play_result(
        NULL
      )
      
    }
  )
  
  # ==================================================
  # CONTACT QUALITY
  # ==================================================
  
  observeEvent(
    input$contact_hard,
    {
      selected_contact_quality(
        "Hard"
      )
    }
  )
  
  observeEvent(
    input$contact_average,
    {
      selected_contact_quality(
        "Average"
      )
    }
  )
  
  observeEvent(
    input$contact_weak,
    {
      selected_contact_quality(
        "Weak"
      )
    }
  )
  
  # ==================================================
  # IN PLAY RESULTS
  # ==================================================
  
  observeEvent(input$pa_single, {
    selected_in_play_result("Single")
  })
  
  observeEvent(input$pa_double, {
    selected_in_play_result("Double")
  })
  
  observeEvent(input$pa_triple, {
    selected_in_play_result("Triple")
  })
  
  observeEvent(input$pa_home_run, {
    selected_in_play_result("Home Run")
  })
  
  observeEvent(input$pa_out, {
    selected_in_play_result("Out")
  })
  
  observeEvent(input$pa_error, {
    selected_in_play_result(
      "Reached on Error"
    )
  })
  
  observeEvent(input$pa_fc, {
    selected_in_play_result(
      "Fielder's Choice"
    )
  })
  
  observeEvent(input$pa_sac_fly, {
    selected_in_play_result(
      "Sac Fly"
    )
  })
  
  observeEvent(input$pa_sac_bunt, {
    selected_in_play_result(
      "Sac Bunt"
    )
  })
  
  # ==================================================
  # IN PLAY UI
  # ==================================================
  
  output$in_play_ui <-
    renderUI({
      
      if (
        !in_play_active() ||
        pa_complete()
      ) {
        
        return(NULL)
        
      }
      
      div(
        
        class =
          "selection-box",
        
        h3(
          "Contact Quality"
        ),
        
        div(
          
          actionButton(
            "contact_hard",
            "HARD",
            class =
              "contact-button"
          ),
          
          actionButton(
            "contact_average",
            "AVERAGE",
            class =
              "contact-button"
          ),
          
          actionButton(
            "contact_weak",
            "WEAK",
            class =
              "contact-button"
          )
          
        ),
        
        h4(
          "Selected Contact Quality:"
        ),
        
        div(
          
          class =
            "selected-value",
          
          ifelse(
            is.null(
              selected_contact_quality()
            ),
            "None",
            selected_contact_quality()
          )
          
        ),
        
        hr(),
        
        h3("PA Result"),
        
        div(
          
          actionButton(
            "pa_single",
            "SINGLE",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_double",
            "DOUBLE",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_triple",
            "TRIPLE",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_home_run",
            "HOME RUN",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_out",
            "OUT",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_error",
            "REACHED ON ERROR",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_fc",
            "FIELDER'S CHOICE",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_sac_fly",
            "SAC FLY",
            class =
              "pa-result-button"
          ),
          
          actionButton(
            "pa_sac_bunt",
            "SAC BUNT",
            class =
              "pa-result-button"
          )
          
        ),
        
        h4(
          "Selected PA Result:"
        ),
        
        div(
          
          class =
            "selected-value",
          
          ifelse(
            is.null(
              selected_in_play_result()
            ),
            "None",
            selected_in_play_result()
          )
          
        ),
        
        br(),
        
        actionButton(
          "complete_in_play_pa",
          "COMPLETE PA"
        )
        
      )
      
    })
  
  # ==================================================
  # COMPLETE IN PLAY PA
  # ==================================================
  
  observeEvent(
    input$complete_in_play_pa,
    {
      
      if (!in_play_active()) {
        return()
      }
      
      if (
        is.null(
          selected_contact_quality()
        )
      ) {
        return()
      }
      
      if (
        is.null(
          selected_in_play_result()
        )
      ) {
        return()
      }
      
      save_pitch_to_sheet(
        
        pitch_result =
          "In Play",
        
        contact_quality =
          selected_contact_quality(),
        
        pa_result_on_pitch =
          selected_in_play_result()
        
      )
      
      save_pa_to_sheet(
        selected_in_play_result()
      )
      
      pa_result(
        selected_in_play_result()
      )
      
      pa_complete(TRUE)
      
    }
  )
  
  # ==================================================
  # MESSAGES
  # ==================================================
  
  output$charting_message <-
    renderUI({
      
      if (
        is.null(
          current_session_id()
        )
      ) {
        
        div(
          class =
            "warning-text",
          "Create or select a Session before charting."
        )
        
      } else if (
        
        !pa_complete() &&
        !in_play_active() &&
        
        (
          selected_pitch_type() ==
          "None" ||
          is.null(
            selected_zone()
          )
        )
        
      ) {
        
        div(
          class =
            "warning-text",
          paste(
            "Select both a Pitch Type and",
            "Pitch Location before choosing",
            "a Pitch Result."
          )
        )
        
      } else if (
        
        in_play_active() &&
        !pa_complete()
        
      ) {
        
        if (
          
          is.null(
            selected_contact_quality()
          ) ||
          
          is.null(
            selected_in_play_result()
          )
          
        ) {
          
          div(
            class =
              "warning-text",
            paste(
              "Select both Contact Quality",
              "and PA Result to complete",
              "the plate appearance."
            )
          )
          
        }
        
      }
      
    })
  
  output$save_message <-
    renderUI({
      
      if (
        is.null(
          save_status()
        )
      ) {
        
        return(NULL)
        
      }
      
      div(
        class =
          "success-text",
        save_status()
      )
      
    })
  
  # ==================================================
  # PA COMPLETE
  # ==================================================
  
  output$pa_complete_ui <-
    renderUI({
      
      if (!pa_complete()) {
        return(NULL)
      }
      
      div(
        
        class =
          "pa-complete-box",
        
        div(
          class =
            "pa-complete-title",
          "PA COMPLETE"
        ),
        
        h3(
          pa_result()
        ),
        
        if (
          
          !is.null(
            selected_contact_quality()
          ) &&
          
          last_pitch_result() ==
          "In Play"
          
        ) {
          
          tags$p(
            paste0(
              "Contact Quality: ",
              selected_contact_quality()
            )
          )
          
        },
        
        actionButton(
          "new_pa",
          "NEW PA"
        )
        
      )
      
    })
  
  # ==================================================
  # PLAYER REPORT BREAKDOWN TABLES
  # ==================================================
  # Context-specific team benchmarking:
  #   Pitch type values compare to team average for SAME pitch type.
  #   Count values compare to team average for SAME count.
  #   In-play contact values compare to team average for SAME result.
  #
  # Player-weighted averages are used so hitters with many more
  # charted pitches do not dominate the team benchmark.
  # ==================================================
  
  report_pct_numeric <- function(numerator, denominator) {
    
    numerator <- suppressWarnings(as.numeric(numerator))
    denominator <- suppressWarnings(as.numeric(denominator))
    
    if (
      length(numerator) == 0 ||
      length(denominator) == 0 ||
      !is.finite(numerator) ||
      !is.finite(denominator) ||
      denominator <= 0
    ) {
      return(NA_real_)
    }
    
    numerator / denominator
  }
  
  
  report_pct_display <- function(value) {
    
    value <- suppressWarnings(as.numeric(value))
    
    if (
      length(value) == 0 ||
      !is.finite(value)
    ) {
      return("—")
    }
    
    paste0(
      sprintf("%.1f", 100 * value),
      "%"
    )
  }
  
  
  table_benchmark_class <- function(
    value,
    team_avg,
    higher_is_better = TRUE,
    tolerance = 0.02,
    neutral = FALSE
  ) {
    
    value <- suppressWarnings(as.numeric(value))
    team_avg <- suppressWarnings(as.numeric(team_avg))
    
    if (
      length(value) == 0 ||
      length(team_avg) == 0 ||
      !is.finite(value) ||
      !is.finite(team_avg) ||
      neutral
    ) {
      return("table-benchmark-neutral")
    }
    
    difference <- value - team_avg
    
    if (abs(difference) <= tolerance) {
      return("table-benchmark-average")
    }
    
    if (higher_is_better) {
      if (difference > tolerance) {
        return("table-benchmark-good")
      }
      return("table-benchmark-poor")
    }
    
    if (difference < -tolerance) {
      return("table-benchmark-good")
    }
    
    "table-benchmark-poor"
  }
  
  
  benchmark_td <- function(
    display_value,
    raw_value,
    team_avg,
    higher_is_better = TRUE,
    tolerance = 0.02,
    neutral = FALSE
  ) {
    
    avg_display <- report_pct_display(team_avg)
    
    tags$td(
      class = table_benchmark_class(
        raw_value,
        team_avg,
        higher_is_better,
        tolerance,
        neutral
      ),
      title = paste0(
        "Team average for this context: ",
        avg_display
      ),
      display_value
    )
  }
  
  
  plain_td <- function(value) {
    tags$td(value)
  }
  
  
  table_header <- function(labels) {
    tags$thead(
      tags$tr(
        lapply(
          labels,
          tags$th
        )
      )
    )
  }
  
  
  normalize_pitch_group <- function(
    pitch_type,
    pitch_group = NA_character_
  ) {
    
    pg <- toupper(trimws(as.character(pitch_group)))
    pt <- toupper(trimws(as.character(pitch_type)))
    
    if (!is.na(pg) && pg != "") {
      if (pg %in% c("HARD", "FASTBALL")) return("Hard")
      if (pg %in% c("BREAKING", "BREAK")) return("Breaking")
      if (pg %in% c("SOFT", "OFFSPEED", "OFF-SPEED")) return("Soft")
    }
    
    if (pt %in% c(
      "FB","FF","FA","4-SEAM FASTBALL","4-SEAM","FOUR-SEAM",
      "CT","CUTTER","SI","SINKER","SNK","TWO-SEAM","2-SEAM"
    )) {
      return("Hard")
    }
    
    if (pt %in% c(
      "SL","SLIDER","CB","CURVEBALL","CU","SW","SWEEPER"
    )) {
      return("Breaking")
    }
    
    if (pt %in% c(
      "CH","CHANGEUP","CHANGE-UP","SPL","SPLT","SPLITTER","FS"
    )) {
      return("Soft")
    }
    
    "Other"
  }
  
  
  pitch_group_mix <- function(d) {
    
    if (nrow(d) == 0) {
      return(
        c(
          Hard = NA_real_,
          Breaking = NA_real_,
          Soft = NA_real_
        )
      )
    }
    
    types <- if ("Pitch_Type" %in% names(d)) {
      as.character(d$Pitch_Type)
    } else {
      rep("", nrow(d))
    }
    
    groups_raw <- if ("Pitch_Group" %in% names(d)) {
      as.character(d$Pitch_Group)
    } else {
      rep(NA_character_, nrow(d))
    }
    
    groups <- mapply(
      normalize_pitch_group,
      types,
      groups_raw,
      USE.NAMES = FALSE
    )
    
    c(
      Hard = mean(groups == "Hard", na.rm = TRUE),
      Breaking = mean(groups == "Breaking", na.rm = TRUE),
      Soft = mean(groups == "Soft", na.rm = TRUE)
    )
  }
  
  
  group_summary_row <- function(d, group_name) {
    
    if (nrow(d) == 0) {
      return(NULL)
    }
    
    types <- if ("Pitch_Type" %in% names(d)) {
      as.character(d$Pitch_Type)
    } else {
      rep("", nrow(d))
    }
    
    groups_raw <- if ("Pitch_Group" %in% names(d)) {
      as.character(d$Pitch_Group)
    } else {
      rep(NA_character_, nrow(d))
    }
    
    groups <- mapply(
      normalize_pitch_group,
      types,
      groups_raw,
      USE.NAMES = FALSE
    )
    
    idx <- groups == group_name
    
    if (!any(idx, na.rm = TRUE)) {
      return(NULL)
    }
    
    pitches <- sum(idx, na.rm = TRUE)
    
    swings <- if ("Swing_Take" %in% names(d)) {
      sum(
        idx &
          as.character(d$Swing_Take) == "Swing",
        na.rm = TRUE
      )
    } else {
      0
    }
    
    whiffs <- if ("Pitch_Result" %in% names(d)) {
      sum(
        idx &
          as.character(d$Pitch_Result) == "Whiff",
        na.rm = TRUE
      )
    } else {
      0
    }
    
    list(
      Group = group_name,
      Pitches = pitches,
      Share = report_pct_numeric(pitches, nrow(d)),
      Swing_Pct = report_pct_numeric(swings, pitches),
      Whiff_Pct = report_pct_numeric(whiffs, swings)
    )
  }
  
  
  build_pitch_type_rows <- function(d) {
    
    if (
      nrow(d) == 0 ||
      !"Pitch_Type" %in% names(d)
    ) {
      return(list())
    }
    
    pitch_type <- trimws(
      as.character(d$Pitch_Type)
    )
    
    valid <- !is.na(pitch_type) & pitch_type != ""
    
    d <- d[valid, , drop = FALSE]
    pitch_type <- pitch_type[valid]
    
    types <- unique(pitch_type)
    
    lapply(
      types,
      function(pt) {
        
        idx <- pitch_type == pt
        pitches <- sum(idx)
        
        swings <- if ("Swing_Take" %in% names(d)) {
          sum(
            as.character(d$Swing_Take[idx]) == "Swing",
            na.rm = TRUE
          )
        } else {
          0
        }
        
        whiffs <- if ("Pitch_Result" %in% names(d)) {
          sum(
            as.character(d$Pitch_Result[idx]) == "Whiff",
            na.rm = TRUE
          )
        } else {
          0
        }
        
        data.frame(
          Pitch_Type = pt,
          Pitches = pitches,
          Share = report_pct_numeric(pitches, nrow(d)),
          Swing_Pct = report_pct_numeric(swings, pitches),
          Whiff_Pct = report_pct_numeric(whiffs, swings),
          stringsAsFactors = FALSE
        )
      }
    )
  }
  
  
  team_pitch_type_benchmarks <- reactive({
    
    all_pitches <- report_pitches()
    
    if (
      nrow(all_pitches) == 0 ||
      !"Batter_ID" %in% names(all_pitches)
    ) {
      return(data.frame())
    }
    
    batter_ids <- unique(
      as.character(all_pitches$Batter_ID)
    )
    
    batter_ids <- batter_ids[
      !is.na(batter_ids) &
        batter_ids != ""
    ]
    
    player_rows <- list()
    
    for (id in batter_ids) {
      
      d <- all_pitches[
        !is.na(all_pitches$Batter_ID) &
          as.character(all_pitches$Batter_ID) == id,
        ,
        drop = FALSE
      ]
      
      rows <- build_pitch_type_rows(d)
      
      if (length(rows) > 0) {
        player_df <- do.call(rbind, rows)
        player_df$Batter_ID <- id
        player_rows[[length(player_rows) + 1]] <- player_df
      }
    }
    
    if (length(player_rows) == 0) {
      return(data.frame())
    }
    
    team_df <- do.call(rbind, player_rows)
    
    contexts <- unique(team_df$Pitch_Type)
    
    out <- lapply(
      contexts,
      function(pt) {
        
        x <- team_df[
          team_df$Pitch_Type == pt,
          ,
          drop = FALSE
        ]
        
        data.frame(
          Pitch_Type = pt,
          Swing_Pct = if (all(is.na(x$Swing_Pct))) NA_real_ else mean(x$Swing_Pct, na.rm = TRUE),
          Whiff_Pct = if (all(is.na(x$Whiff_Pct))) NA_real_ else mean(x$Whiff_Pct, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    )
    
    do.call(rbind, out)
  })
  
  
  output$report_pitch_type_table <- renderUI({
    
    d <- report_batter_pitches()
    rows <- build_pitch_type_rows(d)
    team <- team_pitch_type_benchmarks()
    
    if (length(rows) == 0) {
      return(
        tags$div(
          class = "report-breakdown-note",
          "No pitch-type data available."
        )
      )
    }
    
    player_df <- do.call(rbind, rows)
    player_df <- player_df[
      order(-player_df$Pitches, player_df$Pitch_Type),
      ,
      drop = FALSE
    ]
    
    body_rows <- lapply(
      seq_len(nrow(player_df)),
      function(i) {
        
        row <- player_df[i, , drop = FALSE]
        
        team_row <- team[
          team$Pitch_Type == row$Pitch_Type,
          ,
          drop = FALSE
        ]
        
        team_swing <- if (nrow(team_row) > 0) team_row$Swing_Pct[1] else NA_real_
        team_whiff <- if (nrow(team_row) > 0) team_row$Whiff_Pct[1] else NA_real_
        
        tags$tr(
          plain_td(row$Pitch_Type),
          plain_td(row$Pitches),
          plain_td(report_pct_display(row$Share)),
          benchmark_td(
            report_pct_display(row$Swing_Pct),
            row$Swing_Pct,
            team_swing,
            higher_is_better = TRUE
          ),
          benchmark_td(
            report_pct_display(row$Whiff_Pct),
            row$Whiff_Pct,
            team_whiff,
            higher_is_better = FALSE
          )
        )
      }
    )
    
    group_rows <- lapply(
      c("Hard","Breaking","Soft"),
      function(group_name) {
        g <- group_summary_row(d, group_name)
        if (is.null(g)) return(NULL)
        
        css_class <- paste0(
          "pitch-group-",
          tolower(group_name)
        )
        
        tags$tr(
          class = "breakdown-group-row",
          tags$td(
            class = css_class,
            paste0(group_name, " Total")
          ),
          plain_td(g$Pitches),
          plain_td(report_pct_display(g$Share)),
          plain_td(report_pct_display(g$Swing_Pct)),
          plain_td(report_pct_display(g$Whiff_Pct))
        )
      }
    )
    
    group_rows <- Filter(
      Negate(is.null),
      group_rows
    )
    
    total_pitches <- nrow(d)
    
    total_swings <- if ("Swing_Take" %in% names(d)) {
      sum(as.character(d$Swing_Take) == "Swing", na.rm = TRUE)
    } else {
      0
    }
    
    total_whiffs <- if ("Pitch_Result" %in% names(d)) {
      sum(as.character(d$Pitch_Result) == "Whiff", na.rm = TRUE)
    } else {
      0
    }
    
    total_row <- tags$tr(
      class = "breakdown-total-row",
      plain_td("TOTAL"),
      plain_td(total_pitches),
      plain_td("100.0%"),
      plain_td(
        report_pct_display(
          report_pct_numeric(total_swings, total_pitches)
        )
      ),
      plain_td(
        report_pct_display(
          report_pct_numeric(total_whiffs, total_swings)
        )
      )
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      table_header(
        c(
          "Pitch Type",
          "Pitches",
          "%",
          "Swing %",
          "Whiff %"
        )
      ),
      tags$tbody(
        c(
          body_rows,
          group_rows,
          list(total_row)
        )
      )
    )
  })
  
  
  build_count_rows <- function(d) {
    
    if (
      nrow(d) == 0 ||
      !"Count" %in% names(d)
    ) {
      return(list())
    }
    
    counts <- trimws(
      as.character(d$Count)
    )
    
    valid <- !is.na(counts) & counts != ""
    
    d <- d[valid, , drop = FALSE]
    counts <- counts[valid]
    
    contexts <- unique(counts)
    
    lapply(
      contexts,
      function(ct) {
        
        idx <- counts == ct
        pitches <- sum(idx)
        
        swings <- if ("Swing_Take" %in% names(d)) {
          sum(
            as.character(d$Swing_Take[idx]) == "Swing",
            na.rm = TRUE
          )
        } else {
          0
        }
        
        whiffs <- if ("Pitch_Result" %in% names(d)) {
          sum(
            as.character(d$Pitch_Result[idx]) == "Whiff",
            na.rm = TRUE
          )
        } else {
          0
        }
        
        chase_denominator <- 0
        chase_swings <- 0
        
        if (
          all(
            c("Zone_Group", "Swing_Take") %in% names(d)
          )
        ) {
          
          chase_zone <- as.character(
            d$Zone_Group[idx]
          ) %in% c("Chase", "Waste")
          
          chase_denominator <- sum(
            chase_zone,
            na.rm = TRUE
          )
          
          chase_swings <- sum(
            chase_zone &
              as.character(d$Swing_Take[idx]) == "Swing",
            na.rm = TRUE
          )
        }
        
        count_data <- d[
          idx,
          ,
          drop = FALSE
        ]
        
        pitch_mix <- pitch_group_mix(
          count_data
        )
        
        data.frame(
          Count = ct,
          Pitches = pitches,
          Swing_Pct = report_pct_numeric(swings, pitches),
          Chase_Pct = report_pct_numeric(
            chase_swings,
            chase_denominator
          ),
          Whiff_Pct = report_pct_numeric(whiffs, swings),
          Hard_Pct = pitch_mix[["Hard"]],
          Breaking_Pct = pitch_mix[["Breaking"]],
          Soft_Pct = pitch_mix[["Soft"]],
          stringsAsFactors = FALSE
        )
      }
    )
  }
  
  
  team_count_benchmarks <- reactive({
    
    all_pitches <- report_pitches()
    
    if (
      nrow(all_pitches) == 0 ||
      !"Batter_ID" %in% names(all_pitches)
    ) {
      return(data.frame())
    }
    
    batter_ids <- unique(
      as.character(all_pitches$Batter_ID)
    )
    
    batter_ids <- batter_ids[
      !is.na(batter_ids) &
        batter_ids != ""
    ]
    
    player_rows <- list()
    
    for (id in batter_ids) {
      
      d <- all_pitches[
        !is.na(all_pitches$Batter_ID) &
          as.character(all_pitches$Batter_ID) == id,
        ,
        drop = FALSE
      ]
      
      rows <- build_count_rows(d)
      
      if (length(rows) > 0) {
        player_df <- do.call(rbind, rows)
        player_df$Batter_ID <- id
        player_rows[[length(player_rows) + 1]] <- player_df
      }
    }
    
    if (length(player_rows) == 0) {
      return(data.frame())
    }
    
    team_df <- do.call(rbind, player_rows)
    contexts <- unique(team_df$Count)
    
    out <- lapply(
      contexts,
      function(ct) {
        
        x <- team_df[
          team_df$Count == ct,
          ,
          drop = FALSE
        ]
        
        data.frame(
          Count = ct,
          Swing_Pct = if (all(is.na(x$Swing_Pct))) NA_real_ else mean(x$Swing_Pct, na.rm = TRUE),
          Chase_Pct = if (all(is.na(x$Chase_Pct))) NA_real_ else mean(x$Chase_Pct, na.rm = TRUE),
          Whiff_Pct = if (all(is.na(x$Whiff_Pct))) NA_real_ else mean(x$Whiff_Pct, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    )
    
    do.call(rbind, out)
  })
  
  
  output$report_count_table <- renderUI({
    
    d <- report_batter_pitches()
    rows <- build_count_rows(d)
    team <- team_count_benchmarks()
    
    if (length(rows) == 0) {
      return(
        tags$div(
          class = "report-breakdown-note",
          "No count data available."
        )
      )
    }
    
    player_df <- do.call(rbind, rows)
    
    preferred_order <- c(
      "0-0","1-0","0-1","2-0","1-1","0-2",
      "3-0","2-1","1-2","3-1","2-2","3-2"
    )
    
    player_df$Order <- match(
      player_df$Count,
      preferred_order
    )
    
    player_df$Order[
      is.na(player_df$Order)
    ] <- 999
    
    player_df <- player_df[
      order(player_df$Order, player_df$Count),
      ,
      drop = FALSE
    ]
    
    body_rows <- lapply(
      seq_len(nrow(player_df)),
      function(i) {
        
        row <- player_df[i, , drop = FALSE]
        
        team_row <- team[
          team$Count == row$Count,
          ,
          drop = FALSE
        ]
        
        team_swing <- if (nrow(team_row) > 0) team_row$Swing_Pct[1] else NA_real_
        team_chase <- if (nrow(team_row) > 0) team_row$Chase_Pct[1] else NA_real_
        team_whiff <- if (nrow(team_row) > 0) team_row$Whiff_Pct[1] else NA_real_
        
        tags$tr(
          plain_td(row$Count),
          plain_td(row$Pitches),
          benchmark_td(
            report_pct_display(row$Swing_Pct),
            row$Swing_Pct,
            team_swing,
            higher_is_better = TRUE
          ),
          benchmark_td(
            report_pct_display(row$Chase_Pct),
            row$Chase_Pct,
            team_chase,
            higher_is_better = FALSE
          ),
          benchmark_td(
            report_pct_display(row$Whiff_Pct),
            row$Whiff_Pct,
            team_whiff,
            higher_is_better = FALSE
          ),
          plain_td(report_pct_display(row$Hard_Pct)),
          plain_td(report_pct_display(row$Breaking_Pct)),
          plain_td(report_pct_display(row$Soft_Pct))
        )
      }
    )
    
    total_pitches <- nrow(d)
    
    total_swings <- if ("Swing_Take" %in% names(d)) {
      sum(as.character(d$Swing_Take) == "Swing", na.rm = TRUE)
    } else {
      0
    }
    
    total_whiffs <- if ("Pitch_Result" %in% names(d)) {
      sum(as.character(d$Pitch_Result) == "Whiff", na.rm = TRUE)
    } else {
      0
    }
    
    chase_zone <- if ("Zone_Group" %in% names(d)) {
      as.character(d$Zone_Group) %in% c("Chase","Waste")
    } else {
      rep(FALSE, nrow(d))
    }
    
    chase_den <- sum(chase_zone, na.rm = TRUE)
    
    chase_swings <- if ("Swing_Take" %in% names(d)) {
      sum(
        chase_zone &
          as.character(d$Swing_Take) == "Swing",
        na.rm = TRUE
      )
    } else {
      0
    }
    
    total_mix <- pitch_group_mix(d)
    
    total_row <- tags$tr(
      class = "breakdown-total-row",
      plain_td("TOTAL"),
      plain_td(total_pitches),
      plain_td(
        report_pct_display(
          report_pct_numeric(total_swings, total_pitches)
        )
      ),
      plain_td(
        report_pct_display(
          report_pct_numeric(chase_swings, chase_den)
        )
      ),
      plain_td(
        report_pct_display(
          report_pct_numeric(total_whiffs, total_swings)
        )
      ),
      plain_td(report_pct_display(total_mix[["Hard"]])),
      plain_td(report_pct_display(total_mix[["Breaking"]])),
      plain_td(report_pct_display(total_mix[["Soft"]]))
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      table_header(
        c(
          "Count",
          "Pitches",
          "Swing %",
          "Chase %",
          "Whiff %",
          "Hard %",
          "Breaking %",
          "Soft %"
        )
      ),
      tags$tbody(
        c(
          body_rows,
          list(total_row)
        )
      )
    )
  })
  
  
  build_in_play_rows <- function(d) {
    
    if (
      nrow(d) == 0 ||
      !"PA_Result_On_Pitch" %in% names(d)
    ) {
      return(list())
    }
    
    result <- trimws(
      as.character(d$PA_Result_On_Pitch)
    )
    
    valid <- !is.na(result) & result != ""
    
    d <- d[valid, , drop = FALSE]
    result <- result[valid]
    
    contexts <- unique(result)
    
    lapply(
      contexts,
      function(res) {
        
        idx <- result == res
        pa_count <- sum(idx)
        
        contact <- if ("Contact_Quality" %in% names(d)) {
          trimws(
            as.character(
              d$Contact_Quality[idx]
            )
          )
        } else {
          rep("", pa_count)
        }
        
        contact_denominator <- sum(
          contact %in% c("Hard", "Average", "Avg", "Weak"),
          na.rm = TRUE
        )
        
        hard_count <- sum(contact == "Hard", na.rm = TRUE)
        avg_count <- sum(
          contact %in% c("Average", "Avg"),
          na.rm = TRUE
        )
        weak_count <- sum(contact == "Weak", na.rm = TRUE)
        
        data.frame(
          Result = res,
          PA = pa_count,
          Share = report_pct_numeric(pa_count, nrow(d)),
          Hard_Pct = report_pct_numeric(
            hard_count,
            contact_denominator
          ),
          Avg_Pct = report_pct_numeric(
            avg_count,
            contact_denominator
          ),
          Weak_Pct = report_pct_numeric(
            weak_count,
            contact_denominator
          ),
          stringsAsFactors = FALSE
        )
      }
    )
  }
  
  
  team_in_play_benchmarks <- reactive({
    
    all_pitches <- report_pitches()
    
    if (
      nrow(all_pitches) == 0 ||
      !"Batter_ID" %in% names(all_pitches)
    ) {
      return(data.frame())
    }
    
    batter_ids <- unique(
      as.character(all_pitches$Batter_ID)
    )
    
    batter_ids <- batter_ids[
      !is.na(batter_ids) &
        batter_ids != ""
    ]
    
    player_rows <- list()
    
    for (id in batter_ids) {
      
      d <- all_pitches[
        !is.na(all_pitches$Batter_ID) &
          as.character(all_pitches$Batter_ID) == id,
        ,
        drop = FALSE
      ]
      
      rows <- build_in_play_rows(d)
      
      if (length(rows) > 0) {
        player_df <- do.call(rbind, rows)
        player_df$Batter_ID <- id
        player_rows[[length(player_rows) + 1]] <- player_df
      }
    }
    
    if (length(player_rows) == 0) {
      return(data.frame())
    }
    
    team_df <- do.call(rbind, player_rows)
    contexts <- unique(team_df$Result)
    
    out <- lapply(
      contexts,
      function(res) {
        
        x <- team_df[
          team_df$Result == res,
          ,
          drop = FALSE
        ]
        
        data.frame(
          Result = res,
          Hard_Pct = if (all(is.na(x$Hard_Pct))) NA_real_ else mean(x$Hard_Pct, na.rm = TRUE),
          Avg_Pct = if (all(is.na(x$Avg_Pct))) NA_real_ else mean(x$Avg_Pct, na.rm = TRUE),
          Weak_Pct = if (all(is.na(x$Weak_Pct))) NA_real_ else mean(x$Weak_Pct, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    )
    
    do.call(rbind, out)
  })
  
  
  output$report_in_play_table <- renderUI({
    
    d <- report_batter_pitches()
    rows <- build_in_play_rows(d)
    team <- team_in_play_benchmarks()
    
    if (length(rows) == 0) {
      return(
        tags$div(
          class = "report-breakdown-note",
          "No result data available."
        )
      )
    }
    
    player_df <- do.call(rbind, rows)
    player_df <- player_df[
      order(-player_df$PA, player_df$Result),
      ,
      drop = FALSE
    ]
    
    body_rows <- lapply(
      seq_len(nrow(player_df)),
      function(i) {
        
        row <- player_df[i, , drop = FALSE]
        
        team_row <- team[
          team$Result == row$Result,
          ,
          drop = FALSE
        ]
        
        team_hard <- if (nrow(team_row) > 0) team_row$Hard_Pct[1] else NA_real_
        team_avg <- if (nrow(team_row) > 0) team_row$Avg_Pct[1] else NA_real_
        team_weak <- if (nrow(team_row) > 0) team_row$Weak_Pct[1] else NA_real_
        
        tags$tr(
          plain_td(row$Result),
          plain_td(row$PA),
          plain_td(report_pct_display(row$Share)),
          benchmark_td(
            report_pct_display(row$Hard_Pct),
            row$Hard_Pct,
            team_hard,
            higher_is_better = TRUE
          ),
          benchmark_td(
            report_pct_display(row$Avg_Pct),
            row$Avg_Pct,
            team_avg,
            neutral = TRUE
          ),
          benchmark_td(
            report_pct_display(row$Weak_Pct),
            row$Weak_Pct,
            team_weak,
            higher_is_better = FALSE
          )
        )
      }
    )
    
    total_pa <- sum(player_df$PA, na.rm = TRUE)
    
    contact_hard_num <- 0
    contact_avg_num <- 0
    contact_weak_num <- 0
    contact_den <- 0
    
    if ("Contact_Quality" %in% names(d)) {
      cq <- trimws(as.character(d$Contact_Quality))
      contact_den <- sum(
        cq %in% c("Hard","Average","Avg","Weak"),
        na.rm = TRUE
      )
      contact_hard_num <- sum(cq == "Hard", na.rm = TRUE)
      contact_avg_num <- sum(cq %in% c("Average","Avg"), na.rm = TRUE)
      contact_weak_num <- sum(cq == "Weak", na.rm = TRUE)
    }
    
    total_row <- tags$tr(
      class = "breakdown-total-row",
      plain_td("TOTAL"),
      plain_td(total_pa),
      plain_td("100.0%"),
      plain_td(
        report_pct_display(
          report_pct_numeric(contact_hard_num, contact_den)
        )
      ),
      plain_td(
        report_pct_display(
          report_pct_numeric(contact_avg_num, contact_den)
        )
      ),
      plain_td(
        report_pct_display(
          report_pct_numeric(contact_weak_num, contact_den)
        )
      )
    )
    
    tags$table(
      class = "table table-striped table-condensed",
      table_header(
        c(
          "Result",
          "PA",
          "%",
          "Hard",
          "Avg",
          "Weak"
        )
      ),
      tags$tbody(
        c(
          body_rows,
          list(total_row)
        )
      )
    )
  })
  
  
  output$export_player_report_pdf <- downloadHandler(
    filename = function() {
      player_name <- gsub(
        "[^A-Za-z0-9_-]+",
        "_",
        safe_player_value(
          report_player_row(),
          "Display_Name",
          "player"
        )
      )
      paste0(
        player_name,
        "_swing_decision_report.pdf"
      )
    },
    content = function(file) {
      if (!requireNamespace("webshot2", quietly = TRUE)) {
        stop(
          "PDF export requires the R package 'webshot2'. Install it with install.packages('webshot2')."
        )
      }
      
      url <- session$clientData$url_protocol
      host <- session$clientData$url_hostname
      port <- session$clientData$url_port
      
      report_url <- paste0(
        url,
        "//",
        host,
        if (!is.null(port) && port != "") paste0(":", port) else ""
      )
      
      webshot2::webshot(
        url = report_url,
        file = file,
        vwidth = 1800,
        vheight = 1050,
        zoom = 1
      )
    },
    contentType = "application/pdf"
  )
  
  
  # ==================================================
  # NEW PA
  # ==================================================
  
  observeEvent(
    input$new_pa,
    {
      
      balls(0)
      strikes(0)
      
      pa_complete(FALSE)
      pa_result(NULL)
      
      last_pitch_result(
        "None"
      )
      
      selected_pitch_type(
        "None"
      )
      
      selected_zone(NULL)
      selected_location_x(NULL)
      selected_location_y(NULL)
      
      in_play_active(FALSE)
      
      selected_contact_quality(
        NULL
      )
      
      selected_in_play_result(
        NULL
      )
      
      pa_pitch_count(0)
      pitches_after_2k(0)
      updateNumericInput(session,"pa_rbi",value=0)
      updateCheckboxInput(session,"quab_barrel",value=FALSE)
      updateCheckboxInput(session,"quab_offensive_play",value=FALSE)
      updateCheckboxInput(session,"quab_move_runner_third",value=FALSE)
      
      pa_number(
        pa_number() + 1
      )
      
    }
  )
  
  # ==================================================
  # STARTUP INITIALIZATION
  # ==================================================
  observeEvent(TRUE,{
    ensure_multi_user_pitch_columns()
    compact_pitches_sheet_if_needed()
    compact_plate_appearances_sheet_if_needed()
    load_app_settings(update_ui=TRUE)
    
    # V48: one backend snapshot hydrates Sessions, Pitches and PAs.
    # Reports and leaderboards calculate from memory instead of repeatedly
    # hitting the Google Sheets API for every reactive UI change.
    refresh_sessions_admin_data()
    load_sessions()
    load_report_pitches()
    load_pitcher_report_data()
  },once=TRUE)
  
}

shinyApp(
  ui = ui,
  server = server
)
