$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 4188
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()

$types = @{
  ".html" = "text/html; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".css" = "text/css; charset=utf-8"
  ".js" = "application/javascript; charset=utf-8"
}

while ($listener.IsListening) {
  $context = $listener.GetContext()
  try {
    $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart("/"))
    if ([string]::IsNullOrWhiteSpace($requestPath)) {
      $requestPath = "index.html"
    }

    $target = [System.IO.Path]::GetFullPath((Join-Path $root $requestPath))
    if (-not $target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
      $context.Response.StatusCode = 403
      $buffer = [Text.Encoding]::UTF8.GetBytes("Forbidden")
    } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($target).ToLowerInvariant()
      $context.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
      $buffer = [System.IO.File]::ReadAllBytes($target)
    } elseif ($requestPath.StartsWith("napoj/", [StringComparison]::OrdinalIgnoreCase) -or $requestPath.StartsWith("napoje/", [StringComparison]::OrdinalIgnoreCase) -or $requestPath.StartsWith("kategorie/", [StringComparison]::OrdinalIgnoreCase)) {
      $target = Join-Path $root "index.html"
      $context.Response.ContentType = $types[".html"]
      $buffer = [System.IO.File]::ReadAllBytes($target)
    } else {
      $context.Response.StatusCode = 404
      $buffer = [Text.Encoding]::UTF8.GetBytes("Not found")
    }

    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
  } catch {
    $context.Response.StatusCode = 500
  } finally {
    $context.Response.OutputStream.Close()
  }
}
