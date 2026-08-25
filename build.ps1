param(
    [string]$InputFile = "adas_master.md",
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputPath = Join-Path $repoRoot $InputFile

if (-not (Test-Path $inputPath)) {
    throw "Input file not found: $inputPath"
}

$outputPath = Join-Path $repoRoot $OutputDir
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$markdown = Get-Content -Path $inputPath -Raw -Encoding UTF8
$markdownJson = $markdown | ConvertTo-Json -Compress
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
$htmlPath = Join-Path $outputPath ($baseName + ".html")

$html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$baseName</title>
    <style>
        :root {
            color-scheme: light dark;
            --bg: #ffffff;
            --fg: #1f2328;
            --muted: #59636e;
            --border: #d0d7de;
            --code-bg: #f6f8fa;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #0d1117;
                --fg: #e6edf3;
                --muted: #8b949e;
                --border: #30363d;
                --code-bg: #161b22;
            }
        }
        body {
            margin: 0;
            font-family: "Segoe UI", Arial, sans-serif;
            background: var(--bg);
            color: var(--fg);
        }
        main {
            max-width: 1200px;
            margin: 0 auto;
            padding: 32px 24px 48px;
        }
        h1, h2, h3, h4, h5, h6 {
            line-height: 1.25;
        }
        pre, code {
            font-family: Consolas, "Courier New", monospace;
        }
        pre {
            padding: 16px;
            border: 1px solid var(--border);
            border-radius: 8px;
            background: var(--code-bg);
            overflow-x: auto;
        }
        code {
            background: var(--code-bg);
            padding: 0.1em 0.3em;
            border-radius: 4px;
        }
        img {
            max-width: 100%;
        }
        .mermaid {
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 16px;
            background: var(--bg);
            overflow-x: auto;
        }
        .meta {
            color: var(--muted);
            margin-bottom: 24px;
        }
    </style>
</head>
<body>
    <main>
        <div class="meta">Generated from <code>$InputFile</code></div>
        <article id="content"></article>
    </main>
    <script type="module">
        import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
        import markdownit from "https://cdn.jsdelivr.net/npm/markdown-it@14/+esm";

        const markdownSource = $markdownJson;
        const md = markdownit({
            html: true,
            breaks: true,
            linkify: true
        });

        const defaultFence = md.renderer.rules.fence || function(tokens, idx, options, env, self) {
            return self.renderToken(tokens, idx, options);
        };

        md.renderer.rules.fence = (tokens, idx, options, env, self) => {
            const token = tokens[idx];
            const info = (token.info || "").trim();
            if (info === "mermaid") {
                return '<div class="mermaid">' + md.utils.escapeHtml(token.content) + '</div>';
            }
            return defaultFence(tokens, idx, options, env, self);
        };

        document.getElementById("content").innerHTML = md.render(markdownSource);
        mermaid.initialize({ startOnLoad: false });
        await mermaid.run({ querySelector: ".mermaid" });
    </script>
</body>
</html>
"@

[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.Encoding]::UTF8)
Write-Output "Built: $htmlPath"
