# add anything that should be done during first startup

#configure git
New-Item -ItemType Directory $HOME\workspace
git config --global --add safe.directory C:/Users/SSHUser/workspace/ # trust workspace
git config --global http.sslBackend schannel # use windows certificate store
git config --global user.name $env:gitUsername
git config --global user.email $env:gitEmailaddress
git config --global credential.credentialStore dpapi
git config --global credential.https://github.com.username $env:gitHubUsername
