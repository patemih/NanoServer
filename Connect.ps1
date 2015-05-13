#Set-Item WSMan:\localhost\Client\TrustedHosts '192.168.56.101'
$password = ConvertTo-SecureString "administrator" -AsPlainText -Force
$cred= New-Object System.Management.Automation.PSCredential ("administrator", $password )

Enter-PSSession -ComputerName '192.168.56.101' -Credential $cred