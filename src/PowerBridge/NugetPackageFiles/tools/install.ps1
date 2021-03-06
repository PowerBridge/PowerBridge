param($installPath, $toolsPath, $package, $project)

$ErrorActionPreference = 'Stop'

$buildScriptsDirectoryName = '.BuildScripts'
$buildScriptsSourceDirectoryPath = Join-Path $installPath $buildScriptsDirectoryName

$projectFilePath = $project.FileName
$projectDirectoryPath = Split-Path ($project.FileName)

$buildScriptsProjectItemExists = $project.ProjectItems | Where-Object { $_.Name -eq $buildScriptsDirectoryName }
$buildScriptsDestinationDirectoryPathExists = Test-Path (Join-Path $projectDirectoryPath $buildScriptsDirectoryName) -PathType Container

$projectXml = [xml](Get-Content $projectFilePath)
$namespaceManager = New-Object System.Xml.XmlNamespaceManager $projectXml.NameTable
$namespaceManager.AddNamespace('msbuild', 'http://schemas.microsoft.com/developer/msbuild/2003')
$invokePowerShellTaskExists = $projectXml.DocumentElement.SelectNodes('//msbuild:Target/msbuild:PowerBridge.Tasks.InvokePowerShell.InvokePowerShell', $namespaceManager) | ForEach-Object { $_.GetEnumerator }
$legacyInvokePowerShellTaskExists = $projectXml.DocumentElement.SelectNodes('//msbuild:Target/msbuild:InvokePowerShell', $namespaceManager) | ForEach-Object { $_.GetEnumerator }

$shouldCreateDefaultBuildScripts = -not $buildScriptsProjectItemExists -and `
                                   -not $buildScriptsDestinationDirectoryPathExists -and `
                                   -not $invokePowerShellTaskExists -and `
                                   -not $legacyInvokePowerShellTaskExists

if($shouldCreateDefaultBuildScripts)
{
    if ($project.Type -eq 'F#')
    {
        $buildScriptsDestinationDirectoryPath = Join-Path $projectDirectoryPath $buildScriptsDirectoryName
        robocopy $buildScriptsSourceDirectoryPath $buildScriptsDestinationDirectoryPath

        $folderNode = $project.Project.CreateFolderNodes($buildScriptsDestinationDirectoryPath)
        Get-ChildItem $buildScriptsDestinationDirectoryPath | ForEach-Object {
            $project.Project.AddNewFileNodeToHierarchy($folderNode, $_.FullName) | Out-Null
        }
    }
    else
    {
        $project.ProjectItems.AddFromDirectory($buildScriptsSourceDirectoryPath) | Out-Null
    }
}
