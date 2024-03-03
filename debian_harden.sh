

#The default umask for all users should be set to 077 in login.defs
#The default umask for all users should be set to 077 in login.defs
#""Reason"":""File /etc/login.defs should contain one or more lines matching ['^UMASK\\s+077']""}}
#"remediation"":""Run the command '/opt/microsoft/omsagent/plugin/omsremediate -r set-default-user-umask'.
# This will add the line 'UMASK 077' to the file '/etc/login.defs owned by other users.""}


