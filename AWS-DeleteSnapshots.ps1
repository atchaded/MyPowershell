<#
How to run the script that Delete  AWS Instances snapshots. 
The instructions referenced in these steps are based on the following article that can be found on the NVD SharePoint Site : https://share.nist.gov/sites/oism/nvd/devwiki/Wiki%20Pages/Amazon%20Web%20Services.aspx
Prerequisites
1)	Obtain a credential for accessing NIST AWS VPC
2)	Make sure that the workstation you are using is configured to run Python as well as AWS Command Line 
3)	Get the NVD scripts that Scott Stankus has built ( save them in scripts-nvd folder)
Instructions 
2.  Create a temporary profile for connecting to AWS
a.	CMD   (Access the shell command prompt in Administrative Mode)
b.	cd \python27\scripts  (Move to Python Script Folder where awssaml.py is placed)
c.	python awssaml.py (Create a temporary profile for scripts execution)
Username: dba11
Password: 
Please choose the role you would like to assume:
[ 0 ]:  arn:aws:iam::593096591368:role/ADFS-ITL-NVD-PUBLIC
[ 1 ]:  arn:aws:iam::593096591368:role/ADFS-ITL-NVD
Selection:  0
d.	aws --profile saml s3 ls s3://nist-itl-nvd/  (Command to test the profile functionality)
#>

Set-ExecutionPolicy Unrestricted -FORCE  

$IDs = Get-Content -Path "C:\ExecFolder\Deletion_Candidates.txt"
cmd /c pause
foreach($volSnapId in $IDs){
                $cmd = "aws ec2 --profile saml describe-snapshots --snapshot-ids $volSnapId"
                $result = (cmd.exe /c $cmd | Out-String | ConvertFrom-Json).Snapshots
                
                if(($null -ne $result) -AND ($result.count -eq 1)){
                                Write-Host "Deleting $volSnapId"
                                $cmd = "aws ec2 --profile saml delete-snapshot --snapshot-id $volSnapId"
                                cmd.exe /c $cmd
                }
                else{
                                Write-Host "Snapshot ($volSnapId) does not exist - skipping delete."
                }
}

Set-ExecutionPolicy RemoteSigned
