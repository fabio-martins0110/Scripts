<# 
.SYNOPSIS
    Busca, baixa e instala atualizacoes do Windows usando o WSUS configurado no computador.

.DESCRIPTION
    Este script funciona em Windows 10 e Windows 11. Ele usa a API nativa do Windows Update
    Agent, portanto respeita as configuracoes de WSUS aplicadas por GPO ou registro.

    Execute em uma janela do PowerShell aberta como Administrador.

.PARAMETER AcceptAll
    Instala todas as atualizacoes aplicaveis encontradas.

.PARAMETER AutoReboot
    Reinicia automaticamente o computador se alguma atualizacao exigir reinicializacao.

.PARAMETER IncludeDrivers
    Inclui atualizacoes de driver na pesquisa.

.PARAMETER LogPath
    Caminho do arquivo de log.

.EXAMPLE
    .\Instalar-AtualizacoesWSUS.ps1 -AcceptAll

.EXAMPLE
    .\Instalar-AtualizacoesWSUS.ps1 -AcceptAll -AutoReboot
#>

[CmdletBinding()]
param(
    [switch]$AcceptAll,
    [switch]$AutoReboot,
    [switch]$IncludeDrivers,
    [string]$LogPath = "$env:WINDIR\Temp\Instalar-AtualizacoesWSUS.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp][$Level] $Message"
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WSUSConfiguration {
    $wuPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $auPolicyPath = Join-Path $wuPolicyPath 'AU'

    $config = [ordered]@{
        WUServer      = $null
        WUStatusServer = $null
        UseWUServer   = $null
    }

    if (Test-Path -LiteralPath $wuPolicyPath) {
        $wuPolicy = Get-ItemProperty -LiteralPath $wuPolicyPath
        $config.WUServer = $wuPolicy.WUServer
        $config.WUStatusServer = $wuPolicy.WUStatusServer
    }

    if (Test-Path -LiteralPath $auPolicyPath) {
        $auPolicy = Get-ItemProperty -LiteralPath $auPolicyPath
        $config.UseWUServer = $auPolicy.UseWUServer
    }

    return [pscustomobject]$config
}

function Start-WindowsUpdateDetection {
    Write-Log 'Solicitando nova deteccao de atualizacoes.'

    try {
        $autoUpdate = New-Object -ComObject Microsoft.Update.AutoUpdate
        $autoUpdate.DetectNow()
        Write-Log 'DetectNow executado com sucesso.'
    }
    catch {
        Write-Log "Nao foi possivel executar DetectNow pela API COM: $($_.Exception.Message)" 'WARN'
    }

    $usoclient = Join-Path $env:WINDIR 'System32\UsoClient.exe'
    if (Test-Path -LiteralPath $usoclient) {
        try {
            Start-Process -FilePath $usoclient -ArgumentList 'StartScan' -WindowStyle Hidden -Wait
            Write-Log 'UsoClient StartScan executado.'
        }
        catch {
            Write-Log "Nao foi possivel executar UsoClient StartScan: $($_.Exception.Message)" 'WARN'
        }
    }
}

function New-UpdateCollection {
    return New-Object -ComObject Microsoft.Update.UpdateColl
}

function Add-UpdateToCollection {
    param(
        [Parameter(Mandatory = $true)]
        [__ComObject]$Collection,

        [Parameter(Mandatory = $true)]
        [__ComObject]$Update
    )

    [void]$Collection.Add($Update)
}

function Get-ResultCodeText {
    param([int]$Code)

    switch ($Code) {
        0 { 'NotStarted' }
        1 { 'InProgress' }
        2 { 'Succeeded' }
        3 { 'SucceededWithErrors' }
        4 { 'Failed' }
        5 { 'Aborted' }
        default { "Unknown ($Code)" }
    }
}

if (-not (Test-IsAdministrator)) {
    throw 'Execute este script em uma janela do PowerShell aberta como Administrador.'
}

$logDirectory = Split-Path -Path $LogPath -Parent
if ($logDirectory -and -not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
}

Write-Log 'Inicio da execucao.'
Write-Log "Sistema operacional: $((Get-CimInstance Win32_OperatingSystem).Caption)"

$wsusConfig = Get-WSUSConfiguration
if ($wsusConfig.UseWUServer -eq 1 -and $wsusConfig.WUServer) {
    Write-Log "WSUS configurado: $($wsusConfig.WUServer)"
}
else {
    Write-Log 'Este computador nao parece estar configurado para usar WSUS por politica. A pesquisa usara o servico de Windows Update configurado no sistema.' 'WARN'
}

Start-WindowsUpdateDetection
Start-Sleep -Seconds 10

Write-Log 'Criando sessao do Windows Update Agent.'
$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'Instalar-AtualizacoesWSUS.ps1'

$searcher = $session.CreateUpdateSearcher()
$searcher.ServerSelection = 0

$criteria = "IsInstalled=0 and IsHidden=0"
if (-not $IncludeDrivers) {
    $criteria += " and Type='Software'"
}

Write-Log "Pesquisando atualizacoes disponiveis. Criterio: $criteria"
$searchResult = $searcher.Search($criteria)

if ($searchResult.Updates.Count -eq 0) {
    Write-Log 'Nenhuma atualizacao disponivel foi encontrada.'
    Write-Log 'Fim da execucao.'
    return
}

Write-Log "Atualizacoes encontradas: $($searchResult.Updates.Count)"

$updatesToDownload = New-UpdateCollection
for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
    $update = $searchResult.Updates.Item($i)
    Write-Log ("Encontrada: {0} | Baixada: {1} | EULA aceita: {2}" -f $update.Title, $update.IsDownloaded, $update.EulaAccepted)

    if (-not $update.EulaAccepted) {
        if ($AcceptAll) {
            $update.AcceptEula()
            Write-Log "EULA aceita para: $($update.Title)"
        }
        else {
            Write-Log "Ignorando atualizacao porque a EULA ainda nao foi aceita. Use -AcceptAll para aceitar automaticamente: $($update.Title)" 'WARN'
            continue
        }
    }

    if (-not $update.IsDownloaded) {
        Add-UpdateToCollection -Collection $updatesToDownload -Update $update
    }
}

if ($updatesToDownload.Count -gt 0) {
    Write-Log "Iniciando download de $($updatesToDownload.Count) atualizacao(oes)."
    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $updatesToDownload
    $downloadResult = $downloader.Download()
    Write-Log "Resultado do download: $(Get-ResultCodeText -Code $downloadResult.ResultCode)"

    if ($downloadResult.ResultCode -notin 2, 3) {
        throw "Download das atualizacoes falhou. Codigo: $(Get-ResultCodeText -Code $downloadResult.ResultCode)"
    }
}
else {
    Write-Log 'Todas as atualizacoes aplicaveis ja estavam baixadas ou foram ignoradas.'
}

$updatesToInstall = New-UpdateCollection
for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
    $update = $searchResult.Updates.Item($i)
    if ($update.IsDownloaded -and $update.EulaAccepted) {
        Add-UpdateToCollection -Collection $updatesToInstall -Update $update
    }
}

if ($updatesToInstall.Count -eq 0) {
    Write-Log 'Nenhuma atualizacao baixada esta pronta para instalacao.'
    Write-Log 'Fim da execucao.'
    return
}

Write-Log "Iniciando instalacao de $($updatesToInstall.Count) atualizacao(oes)."
$installer = $session.CreateUpdateInstaller()
$installer.Updates = $updatesToInstall
$installResult = $installer.Install()

Write-Log "Resultado geral da instalacao: $(Get-ResultCodeText -Code $installResult.ResultCode)"
Write-Log "Reinicializacao obrigatoria: $($installResult.RebootRequired)"

for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
    $update = $updatesToInstall.Item($i)
    $result = $installResult.GetUpdateResult($i)
    Write-Log ("Resultado: {0} | {1} | HResult: 0x{2:X8}" -f $update.Title, (Get-ResultCodeText -Code $result.ResultCode), $result.HResult)
}

if ($installResult.ResultCode -notin 2, 3) {
    throw "Instalacao finalizada com falha. Codigo: $(Get-ResultCodeText -Code $installResult.ResultCode)"
}

if ($installResult.RebootRequired) {
    if ($AutoReboot) {
        Write-Log 'Reiniciando o computador em 60 segundos por exigencia das atualizacoes.'
        shutdown.exe /r /t 60 /c "Reinicializacao necessaria apos instalacao de atualizacoes do Windows."
    }
    else {
        Write-Log 'Reinicializacao necessaria. Execute o restart manualmente ou rode o script com -AutoReboot.' 'WARN'
    }
}

Write-Log 'Fim da execucao.'
