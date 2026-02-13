param (
    [string]$Context
)

$args = @()
if ($context.Length -gt 0) {
    $args += "-c"
    $args += "$Context"
}
$args += "ps"

docker $args | Select-Object -Skip 1

