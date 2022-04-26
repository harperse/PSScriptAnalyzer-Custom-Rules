#Requires -Version 3.0

# Import Localized Data
# Explicit culture needed for culture that do not match when using PowerShell Core: https://github.com/PowerShell/PowerShell/issues/8219
if ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name -ne 'en-US') {
    Import-LocalizedData -BindingVariable Messages -UICulture 'en-US'
}
else {
    Import-LocalizedData -BindingVariable Messages
}

#region Unnecessary Comments
<#
.SYNOPSIS
    Removes these unnecessary comments.
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
#endregion Unnecessary Comments

#region Advanced Functions --INCOMPLETE
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
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureAdvancedFunctions, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, Information, $null

                $results += $result
            }

            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
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

}
#endregion PSNoKeys

#region Function Size by Lines
<#
.SYNOPSIS
    Function size should be limited to a maximum of 150 lines
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

    Process {
        $results = @()
        
        try {
            if (($FunctionDefinitionAst.Extent.EndScriptPosition.LineNumber - $FunctionDefinitionAst.Extent.StartScriptPosition.LineNumber) -gt 10) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureFunctionSizeByLines, $FunctionDefinitionAst.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
        
                $results += $result
            }
            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
#endregion

#region Lines by Character Count
<#
.SYNOPSIS
    Max Line length should be 120 characters
.DESCRIPTION
    Keeping lines to a small width allows scripts to be read in one direction (top to bottom) without scrolling back-and-forth horizontally
    Debugging and reading the code is a lot easier
    This is particularly valuable for reading Runbook code in the Azure Automation Account
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
#endregion Lines Ending with a Semicolon

#region FunctionsPascalCasing  --INCOMPLETE--
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

    Process {
        $results = @()
        try {
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
        }
        catch {}
        
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
        [string[]]$autoVariables = ([psobject].Assembly.GetType('System.Management.Automation.SpecialVariables').GetFields('NonPublic,Static') | Where-Object FieldType -EQ ([string])).Name
        $autoVariables += @("FormatEnumerationLimit", "MaximumAliasCount", "MaximumDriveCount", "MaximumErrorCount", "MaximumFunctionCount", "MaximumVariableCount", "PGHome", "PGSE", "PGUICulture", "PGVersionTable", "PROFILE", "PSSessionOption")
    }

    Process {
        $results = @()
        
        foreach ($subToken in $Token) {
            if (($subToken -is [System.Management.Automation.Language.VariableToken]) -and ($subToken.Name -cnotin $autoVariables) -and ($subToken.Name -cmatch '^[A-Z]')) {
                $result = New-Object `
                    -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                    -ArgumentList $Messages.MeasureCamelCaseVariableNames, $subToken.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
                $results += $result
            }
        }

        return $results
    }
}
#endregion VariableCamelCasing

#region PSFunctionNaming  --INCOMPLETE--
<#
.SYNOPSIS
    Functions should follow PowerShell’s verb-noun naming convention
.DESCRIPTION
    Functions should follow PowerShell’s verb-noun naming convention
.EXAMPLE
    Measure-VerbNounFunctionNames -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
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
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = @()
        
        return $results
    }
}
#endregion PSFunctionNaming

#region FunctionsShouldBeReferenced --INCOMPLETE--
<#
.SYNOPSIS
    All functions should be referenced
.DESCRIPTION
    Functions that are created but are not assigned create technical debt
.EXAMPLE
    Measure-OrphanedFunctions -FunctionDefinitionAst $FunctionDefinitionAst
.INPUTS
    [System.Management.Automation.Language.FunctionDefinitionAst]
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionDefinitionAst
    )

    Process {
        $results = @()
        
        return $results
    }
}
#endregion FunctionsShouldBeReferenced

Export-ModuleMember -Function Measure*

# Invoke-ScriptAnalyzer -Path .\scratch.ps1 -CustomRulePath .\BPCustomRules.psm1 -Verbose