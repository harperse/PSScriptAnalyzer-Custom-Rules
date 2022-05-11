ConvertFrom-StringData @'
MeasureOverComment                = Commented code should not be let into a production environment without good reason, approved by a BP stakeholder.  Makes the code less readable, creates technical debt, makes the code more difficult to debug, and often leads to unassigned variables and functions
MeasureAdvancedFunctions          = Advanced functions add additional capabilities that are not present in simple functions.  Capabilities to your scripts including commands such as whatif, verbose, Debug.
MeasurePotentialPasswordsOrKeys   = MAPS code should never contain keys in plain text under any circumstances.  Keys can end up in commit history or exposed to screen-scraper malware
MeasureFunctionSizeByLines        = Function size should be limited to a maximum of 150 lines. It is best practice for functions to do one thing. This will enforce modular, testable, and more efficient code.
MeasureLinesByCharacterCount      = Max Line length should be 120 characters. Keeping lines to a small width allows scripts to be read in one direction (top to bottom) without scrolling back-and-forth horizontally. Debugging and reading the code is a lot easier. This is particularly valuable for reading Runbook code in the Azure Automation Account.
MeasureLinesEndingWithSemicolon   = Semicolons do not serve any function in PowerShell as line terminators and are permitted in PowerShell but do not provide any benefit.
MeasureCamelCaseVariableNames     = Variables should follow camel casing.
MeasurePascalCaseFunctionNames    = PowerShell uses PascalCase for all public identifiers including classes and enums. Function names should follow PowerShell's Verb-Noun naming conventions.
MeasureOrphanedFunction           = Functions that are created but are not assigned create technical debt
MeasureVerbNounFunctionNames      = Ensure that function names follow the Verb-Noun naming conventions.
'@