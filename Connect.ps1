$ip = '192.168.56.101'
Set-Item WSMan:\localhost\Client\TrustedHosts $ip
$password = ConvertTo-SecureString "administrator" -AsPlainText -Force
$cred= New-Object System.Management.Automation.PSCredential ("administrator", $password )
Enter-PSSession -ComputerName $ip -Credential $cred