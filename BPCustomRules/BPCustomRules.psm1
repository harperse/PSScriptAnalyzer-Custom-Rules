#Requires -Version 3.0

# Import Localized Data
# Explicit culture needed for culture that do not match when using PowerShell Core: https://github.com/PowerShell/PowerShell/issues/8219
switch ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name) {
    'en-US' { Import-LocalizedData -BindingVariable Messages -UICulture 'en-US' }
    Default { Import-LocalizedData -BindingVariable Messages }
}

#region Global Variables
[int]$Global:OverCommentPercentage = 10
[int]$Global:FunctionLineLimit = 150
[int]$Global:LineCharacterLimit = 120
#endregion Global Variables

#region Unnecessary Comments
<#
.SYNOPSIS
    Notifies if the script contains an unnecessary percent of the file as comments.
.DESCRIPTION
    Don't precede each line of code with a comment. Doing so breaks up the code and makes it harder to follow. A well-written PowerShell command, with full command and parameter names, can be pretty self-explanatory.
    Don't comment-explain it unless it isn't self-explanatory. To fix a violation of this rule, please remove these unnecessary comments.
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {
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

            if ($actualPercentage -ge $Global:OverCommentPercentage) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureOverComment, $Token[0].Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion Unnecessary Comments

#region Advanced Functions
<#
.SYNOPSIS
    Finds and detects advanced function capability
.DESCRIPTION
    Advanced functions add additional capabilities that are not present in simple functions.  
    Capabilities to your scripts including commands such as whatif, verbose, Debug.
.EXAMPLE
    Measure-AdvancedFunction -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 6.4 UseAdvancedFunctionsAttribute (Custom)
#>
function Measure-AdvancedFunction {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Information
        $results = @()
    }

    Process {
        try {
            #region Define predicates to find ASTs.
            [ScriptBlock]$predicate = {
                param (
                    [System.Management.Automation.Language.Ast]$Ast
                )
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

            [System.Management.Automation.Language.AttributeAst[]]$attrAsts = $FunctionDefinitionAst.Find($predicate, $true)
            if ($FunctionDefinitionAst.IsWorkflow -or !$attrAsts) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureAdvancedFunctions, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion Advanced Functions

#region PSNoKeys  --INCOMPLETE--
<#
.SYNOPSIS
    Checks whether a string could potentially be a Key, Certificate or password.
.DESCRIPTION
    MAPS code should never contain keys in plain text under any circumstances
    Keys can end up in commit history or exposed to screen-scraper malware
.EXAMPLE
    Measure-LinesEndingWithSemicolons -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 8.5 PSNoKeys (Custom)
#>
function Measure-PotentialPasswordsOrKeys {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        #$Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion PSNoKeys

#region Function Size by Lines
<#
.SYNOPSIS
    Function size should be limited to a maximum number of lines
.DESCRIPTION
    It is best practice for functions to do one thing. This will enforce modular, testable, and more efficient code
.EXAMPLE
    Measure-FunctionSizeByLines -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 6.3 PSFunctionSizeLimit (Custom)
#>
function Measure-FunctionSizeByLines {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {
            if (($FunctionDefinitionAst.Extent.EndScriptPosition.LineNumber - $FunctionDefinitionAst.Extent.StartScriptPosition.LineNumber) -gt $Global:FunctionLineLimit) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureFunctionSizeByLines, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion

#region Lines by Character Count
<#
.SYNOPSIS
    Max Line length should be a set number of characters
.DESCRIPTION
    Keeping lines to a small width allows scripts to be read in one direction (top to bottom) without scrolling back-and-forth horizontally.
    Debugging and reading the code is a lot easier.
    This is particularly valuable for reading Runbook code in the Azure Automation Account.
.EXAMPLE
    Measure-LinesByCharacterCount -Token $Token
.INPUTS
    [System.Management.Automation.Language.CommandAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 3.3 AvoidLongLines (Default)
#>
function Measure-LinesByCharacterCount {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {
            if (($CommandAst.Extent.EndColumnNumber - $CommandAst.Extent.StartColumnNumber) -gt $Global:LineCharacterLimit) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureLinesByCharacterCount, $CommandAst.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion Lines by Character Count

#region Lines Ending with a Semicolon
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {
            foreach ($subToken in $Token) {
                if ($subToken.Text.EndsWith(";")) {
                    $result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList $Messages.MeasureLinesEndingWithSemicolon, $subToken.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                    $results += $result
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion Lines Ending with a Semicolon

#region FunctionsPascalCasing
<#
.SYNOPSIS
    Function names should follow PowerShell's Verb-Noun naming conventions.
.DESCRIPTION
    PowerShell uses PascalCase for all public identifiers including classes and enums. 
    Function names should follow PowerShell's Verb-Noun naming conventions.
.EXAMPLE
    Measure-PascalCaseFunctionNames -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 5.5 FunctionsPascalCasing (Custom)
#>
function Measure-PascalCaseFunctionNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $results = @()
    }

    Process {
        try {
            if ($FunctionDefinitionAst.Name -cnotmatch "^[A-Z]\w+-[A-Z]\w+$") {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasurePascalCaseFunctionNames, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion FunctionsPascalCasing

#region VariableCamelCasing
<#
.SYNOPSIS
    Variables should follow camel casing
.DESCRIPTION
    Variables should follow camel casing
.EXAMPLE
    Measure-CamelCaseVariableNames -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 3.7 No Semicolons as Line Terminators (Custom)
#>
function Measure-CamelCaseVariableNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        [string[]]$autoVariables = ([psobject].Assembly.GetType('System.Management.Automation.SpecialVariables').GetFields('NonPublic,Static') | Where-Object FieldType -EQ ([string])).Name
        $autoVariables += @("FormatEnumerationLimit", "MaximumAliasCount", "MaximumDriveCount", "MaximumErrorCount", "MaximumFunctionCount", "MaximumVariableCount", "PGHome", "PGSE", "PGUICulture", "PGVersionTable", "PROFILE", "PSSessionOption")
        $results = @()
    }

    Process {
        try {
            foreach ($subToken in $Token) {
                if (($subToken -is [System.Management.Automation.Language.VariableToken]) -and ($subToken.Name -cnotin $autoVariables) -and ($subToken.Name -cmatch '^[A-Z]')) {
                    $result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList $Messages.MeasureCamelCaseVariableNames, $subToken.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                    $results += $result
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion VariableCamelCasing

#region PSFunctionHyphens
<#
.SYNOPSIS
    Ensure that function names follow the Verb-Noun naming conventions
.DESCRIPTION
    Ensure that function names follow the Verb-Noun naming conventions
.EXAMPLE
    Measure-HyphenInFunctionNames -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 6.2 PSFunctionNaming (Custom)
#>
function Measure-HyphenInFunctionNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $wellDefinedFunctions = $Token | Where-Object { $_.Kind -eq 'Generic' -and $_.TokenFlags -eq [System.Management.Automation.Language.TokenFlags]::None }
        $poorDefinedFunctions = $Token | Where-Object { $_.Extent.StartLineNumber -in $functionLines.Extent.StartLineNumber -and $_ -notin $wellDefinedFunctions }
        $results = @()
    }

    Process {
        #$functionLines = $($Token | Where-Object { $_.Kind -eq 'Function' })
        try {
            foreach ($poorDefinedFunction in $poorDefinedFunctions) {
                if (($poorDefinedFunction.Text -ne "function") -and ($poorDefinedFunction.Kind -ne "LCurly") -and ($poorDefinedFunction.Kind -ne "Newline")) {
                    $result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList $Messages.MeasureHyphenInFunctionNames, $poorDefinedFunction.Extent, $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                    $results += $result
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion PSFunctionHyphens

#region PSFunctionNaming
<#
.SYNOPSIS
    Functions should follow PowerShell’s verb-noun naming convention
.DESCRIPTION
    Functions should follow PowerShell’s verb-noun naming convention
.EXAMPLE
    Measure-VerbNounFunctionNames -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 6.2 PSFunctionNaming (Custom)
#>
function Measure-VerbNounFunctionNames {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $definedFunctions = $Token | Where-Object { $_.Kind -eq 'Generic' -and $_.TokenFlags -eq [System.Management.Automation.Language.TokenFlags]::None }
        $results = @()
    }

    Process {
        try {
            foreach ($definedFunction in $definedFunctions) {
                $functionName = $definedFunction.Text.Split('-')
                if ($functionName[0] -notin $(Get-Verb).Verb) {
                    $result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList $Messages.MeasureVerbNounFunctionNames, $definedFunction.Extent , $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                    $results += $result
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    End {
        return $results
    }
}
#endregion PSFunctionNaming

#region FunctionsShouldBeReferenced 
<#
.SYNOPSIS
    All functions should be referenced
.DESCRIPTION
    Functions that are created but are not assigned create technical debt
.EXAMPLE
    Measure-OrphanedFunctions -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Reference: 6.5 FunctionsShouldBeReferenced (Custom)
#>
function Measure-OrphanedFunctions {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$Token
    )

    Begin {
        $Severity = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
        $functions = $Token | Where-Object { $_.Kind -eq 'Generic' -and $_.TokenFlags -eq [System.Management.Automation.Language.TokenFlags]::None }
        $commands = $Token | Where-Object { $_.Kind -eq 'Generic' -and $_.TokenFlags -eq [System.Management.Automation.Language.TokenFlags]::CommandName }
        $results = @()
    }

    Process {
        try {
            $CompareResults = Compare-Object -ReferenceObject $functions -DifferenceObject $commands | Where-Object { $_.SideIndicator -eq "<=" }
            foreach ($CompareResult in $CompareResults) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureOrphanedFunctions, $($Token.Extent | Where-Object { $_.Text -eq $CompareResult.InputObject.ToString() }) , $PSCmdlet.MyInvocation.InvocationName, $Severity, $null
                $results += $result
            }
        }
        catch { 
            $PSCmdlet.ThrowTerminatingError($PSItem) 
        }
    }

    End { 
        return $results 
    }
}
#endregion FunctionsShouldBeReferenced

Export-ModuleMember -Function Measure*

# Invoke-ScriptAnalyzer -Path .\scratch.ps1 -CustomRulePath .\BPCustomRules.psm1 -Verbose