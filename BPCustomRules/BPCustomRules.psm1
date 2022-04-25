#Requires -Version 3.0

# Import Localized Data
# Explicit culture needed for culture that do not match when using PowerShell Core: https://github.com/PowerShell/PowerShell/issues/8219
if ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name -ne 'en-US') {
    Import-LocalizedData -BindingVariable Messages -UICulture 'en-US'
}
else {
    Import-LocalizedData -BindingVariable Messages
}
<#
.SYNOPSIS
    Removes these unnecessary comments.
.DESCRIPTION
    Don't precede each line of code with a comment. Doing so breaks up the code and makes it harder to follow. A well-written PowerShell command, with full command and parameter names, can be pretty self-explanatory.
    Don't comment-explain it unless it isn't self-explanatory.To fix a violation of this rule, please remove these unnecessary comments.
.EXAMPLE
    Measure-OverComment -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: DOC-07 Don't over-comment, The Community Book of PowerShell Practices.
#>
function Measure-OverComment {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]
        $Token
    )

    Process {
        $results = @()

        try {
            # Calculates comment tokens length
            foreach ($subToken in $Token) {
                $allTokensLength += $subToken.Text.Length
                if ($subToken.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment) {
                    $commentTokensLength += $subToken.Text.Length
                }
                else {
                    $otherTokensLength += $subToken.Text.Length
                }
            }

            $actualPercentage = [int]($commentTokensLength / $allTokensLength * 100)

            if ($actualPercentage -ge 10) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureOverComment, $Token[0].Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null

                $results += $result
            }

            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

<#
.SYNOPSIS
    Adds a .NOTE keyword in your comment-based help.
.DESCRIPTION
    Comment-based help is written as a series of comments. You can write comment-based help topics for end users to better understand your functions. Additionally, it’s better to explain the detail about how the function works.
    To fix a violation of this rule, add a .NOTE keyword in your comment-based help. You can get more details by running “Get-Help about_Comment_Based_Help” command in Windows PowerShell.
.EXAMPLE
    Measure-HelpNote -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: Writing Help and Comments, Windows PowerShell Best Practices.
#>
function Measure-HelpNote {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = @()

        try {
            #region Define predicates to find ASTs.

            # Finds CmdletBinding attribute.
            [ScriptBlock]$predicate = {
                param ([System.Management.Automation.Language.Ast]$Ast)

                [bool]$returnValue = $false

                if ($Ast -is [System.Management.Automation.Language.AttributeAst]) {
                    [System.Management.Automation.Language.AttributeAst]$attrAst = $ast;
                    if ($attrAst.TypeName.Name -eq 'CmdletBinding') {
                        $returnValue = $true
                    }
                }

                return $returnValue
            }

            #endregion

            # Return directly if function is not an advanced function.
            [System.Management.Automation.Language.AttributeAst[]]$attrAsts = $FunctionDefinitionAst.Find($predicate, $true)
            if ($FunctionDefinitionAst.IsWorkflow -or !$attrAsts) {
                return $results
            }

            if (!$FunctionDefinitionAst.GetHelpContent().Notes) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureHelpNote, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null

                $results += $result
            }

            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

function Measure-PotentialPasswordsOrKeys {

}

function Measure-FunctionSizeByLines {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = $null
        
        if (($FunctionDefinitionAst.Extent.EndScriptPosition.LineNumber - $FunctionDefinitionAst.Extent.StartScriptPosition.LineNumber) -gt 10) {
            $result = New-Object `
                -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                -ArgumentList $Messages.MeasureFunctionSizeByLines, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
        
            $results += $result
        }
        return $results
    }
}

function Measure-LinesByCharacterCount {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.CommandAst]$CommandAst
    )

    Process {
        $results = @()

        try {
            if (($CommandAst.Extent.EndColumnNumber - $CommandAst.Extent.StartColumnNumber) -gt 120) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureLinesByCharacterCount, $CommandAst.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
                $results += $result
            }
            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
#>
<#
.SYNOPSIS
    Searches for lines ending in a semicolon
.DESCRIPTION
    Don't end lines with semicolons, as they are not necessary in PowerShell
.EXAMPLE
    Measure-LinesEndingWithSemicolons -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 3.7 No Semicolons as Line Terminators (Custom)
#>
function Measure-LinesEndingWithSemicolons {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Process {
        $results = @()

        try {
            # Calculates comment tokens length
            foreach ($subToken in $Token) {
                if ($subToken.Text.EndsWith(";")) {
                    $result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList $Messages.MeasureLinesEndingWithSemicolon, $subToken.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
                    $results += $result
                }
            }
            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

function Measure-PascalCaseFunctionNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = $null
        
        return $results
    }
}

function Measure-CamelCaseVariableNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = $null
        
        return $results
    }
}

function Measure-VerbNounFunctionNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = $null
        
        return $results
    }
}

function Measure-OrphanedFunctions {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = $null
        
        return $results
    }
}

Export-ModuleMember -Function Measure*

# Invoke-ScriptAnalyzer -Path .\scratch.ps1 -CustomRulePath .\BPCustomRules.psm1 -Verbose