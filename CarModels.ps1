$Global:CarModels = @{ 
    Volvo = "v40", "v60", "v90", "xc40", "xc60", "xc90"; 
    Mercedes = "e180", "e200", "s320", "s600"; 
    VW = "polo", "golf", "passat" 
}

class BrandValidator : System.Management.Automation.IValidateSetValuesGenerator {
     
    [String[]] GetValidValues() {
        return ($Global:CarModels).Keys
    }
}

class CarModels {

    static [String[]] GetCarModels([String] $Brand) {
        return ($Global:CarModels)."$Brand"
    }
}

function Get-CarModels {
    [CmdletBinding()]
    param (
        [ValidateSet([BrandValidator],ErrorMessage="Value '{0}' is invalid. Try one of: {1}")]
        [Parameter(
            Mandatory = $true, 
            Position = 1, 
            HelpMessage = "Name of Brand"
        )]
        $Brand
    )
    dynamicparam {
        # Need dynamic parameters for Template, Storage, Project Type
        # Set the dynamic parameters' name
        $ParameterName = 'Model' 
        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 2
        $ParameterAttribute.HelpMessage = "Name of Model for selected Brand"
        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Generate and set the ValidateSet
        $ParameterValidateSet = [CarModels]::GetCarModels($Brand)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute) 
        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $model = $PSBoundParameters[$ParameterName]
    }
    
    process {
        write-output "Good choise!!! $model"
    }
    
    end {
        
    }
}
