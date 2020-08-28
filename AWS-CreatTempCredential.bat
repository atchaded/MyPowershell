:: Script for creating a temporay AWS Credential/Role to run scripts. 

GOTO Code
Prerequisites
The instructions referenced in these steps are based on the following article that can be found on the NVD SharePoint 
Site : https://share.nist.gov/sites/oism/nvd/devwiki/Wiki%20Pages/Amazon%20Web%20Services.aspx
1)	Obtain a credential for accessing NIST AWS VPC
2)	Make sure that the workstation you are using is configured to run Python as well as AWS Command Line 
3)	Get the NVD scripts that Scott Stankus has built ( save them in scripts-nvd folder)
Instructions 
Create a temporary profile for connecting to AWS
 #>

:Code 
c:
pause
    ::(Move to Python Script Folder where awssaml.py is placed)
cd \python27\scripts  
    :: Create a temporary profile for scripts execution
python awssaml.py 

GOTO EXIT

Here is the result of running the Python Code

Rem Username: dba11
Rem Password: 

Please choose the role you would like to assume:
[ 0 ]:  arn:aws:iam::593096591368:role/ADFS-ITL-NVD-PUBLIC
[ 1 ]:  arn:aws:iam::593096591368:role/ADFS-ITL-NVD
Selection:  0
d.	aws --profile saml s3 ls s3://nist-itl-nvd/  (Command to test the profile functionality)

:EXIT


