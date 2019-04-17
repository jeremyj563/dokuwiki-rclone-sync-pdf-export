### **Notes:**
* This consists of two shell script tasks: rclone-sync and pdf-export. Modify these scripts as needed.
* I'm running my DokuWiki site on Debian so some of the commands below may need to be changed to suit your distro.
* The pdf-export task utilizes Kerberos authentication via a keytab since this is how I setup SSO in my environment.
* Before beginning:
  * Ensure that email is configured and working on your DokuWiki linux host.
  * If using the rclone-sync task then you will need to create a Google account and enable Google Drive API access.
* After the scripts are installed, sync and export logs will be viewable within the wiki site at 'information:dokuwiki'.
<br />

## **Part 1: rclone-sync**
Purpose: Sync the data folder of DokuWiki to Google Drive. Notify the administrator if the sync fails.
<br />
<br />

#### INSTALL RCLONE
`$ sudo apt install rclone`
<br />
<br />

#### CONFIGURE RCLONE
`$ sudo rclone config`

##### create new remote
```
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
name> remote
```

##### choose storage service
```
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / A stackable unification remote, which can appear to merge the contents of several remotes
   \ "union"
 2 / Alias for a existing remote
   \ "alias"
 3 / Amazon Drive
   \ "amazon cloud drive"
 4 / Amazon S3 Compliant Storage Providers (AWS, Ceph, Dreamhost, IBM COS, Minio)
   \ "s3"
 5 / Backblaze B2
   \ "b2"
 6 / Box
   \ "box"
 7 / Cache a remote
   \ "cache"
 8 / Dropbox
   \ "dropbox"
 9 / Encrypt/Decrypt a remote
   \ "crypt"
10 / FTP Connection
   \ "ftp"
11 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
12 / Google Drive
   \ "drive"
13 / Hubic
   \ "hubic"
14 / JottaCloud
   \ "jottacloud"
15 / Local Disk
   \ "local"
16 / Microsoft Azure Blob Storage
   \ "azureblob"
17 / Microsoft OneDrive
   \ "onedrive"
18 / OpenDrive
   \ "opendrive"
19 / Openstack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
20 / Pcloud
   \ "pcloud"
21 / SSH/SFTP Connection
   \ "sftp"
22 / Webdav
   \ "webdav"
23 / Yandex Disk
   \ "yandex"
24 / http Connection
   \ "http"
Storage> 12
** See help for drive backend at: https://rclone.org/drive/ **
```

##### google client id
```
Google Application Client Id
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_id>
Google Application Client Secret
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_secret>
```

##### access scope
```
Scope that rclone should use when requesting access from drive.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 2 / Read-only access to file metadata and file contents.
   \ "drive.readonly"
   / Access to files created by rclone only.
 3 | These are visible in the drive website.
   | File authorization is revoked when the user deauthorizes the app.
   \ "drive.file"
   / Allows read and write access to the Application Data folder.
 4 | This is not visible in the drive website.
   \ "drive.appfolder"
   / Allows read-only access to file metadata but
 5 | does not allow any access to read or download file content.
   \ "drive.metadata.readonly"
scope> 1
```

##### root folder
```
ID of the root folder
Leave blank normally.
Fill in to access "Computers" folders. (see docs).
Enter a string value. Press Enter for the default ("").
root_folder_id>
```

##### service account
```
Service Account Credentials JSON file path
Leave blank normally.
Needed only if you want use SA instead of interactive login.
Enter a string value. Press Enter for the default ("").
service_account_file>
```

##### advanced config
```
Edit advanced config? (y/n)
y) Yes
n) No
y/n> n
```

##### client api authorization
```
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine or Y didn't work
y) Yes
n) No
y/n> n

If your browser doesn't open automatically go to the following link: https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=xxxxxxxxxxxx.apps.googleusercontent.com&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive&state=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Log in and authorize rclone for access
Enter verification code> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

##### team drive
```
Configure this as a team drive?
y) Yes
n) No
y/n> n
```

##### verify configuration
```
--------------------
[remote]
scope = drive
token = {"access_token":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","token_type":"Bearer","refresh_token":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","expiry":"xxxx-xx-xxxxx:xx:xx.xxxxxxxxx-xx:xx"}
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y

Current remotes:

Name                 Type
====                 ====
remote               drive
```

##### quit config
```
e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q
```
<br />

#### CREATE IGNORE FILES
```
$ sudo touch /var/lib/dokuwiki/data/cache/.ignore
$ sudo touch /var/lib/dokuwiki/data/locks/.ignore
$ sudo touch /var/lib/dokuwiki/data/tmp/.ignore
$ sudo touch /var/lib/dokuwiki/data/index/.ignore
```
<br />

#### MAKE GOOGLE DRIVE DIR
`$ sudo rclone mkdir remote:data`
<br />
<br />

#### SHELL SCRIPTS

##### clone repository
```
$ sudo -i
~# mkdir scripts && cd scripts
~/scripts# git clone https://github.com/jeremyj563/dokuwiki-rclone-sync-pdf-export.git .
```

##### make scripts executable
`~/scripts# chmod +x rclone-sync.sh pdf-export.sh`
<br />
<br />

#### INSTALL CRONTAB

##### edit crontab
`$ sudo crontab -e`

##### crontab entry
```
# rclone to google drive - every day at 2:00 AM
0 2 * * * ~/scripts/rclone-sync.sh > /dev/null
```
<br />
<br />

## **Part 2: pdf-export**
Purpose: Export every page into PDF and store in a folder structure that matches the wiki layout.
<br />
<br />

#### DW2PDF PLUGIN

##### install
`DokuWiki > Administration > Extension Manager`
<br />
![alt text](https://raw.githubusercontent.com/jeremyj563/images-github/master/DokuWiki/procedures/dokuwiki/automated-pdf-export/1.png "DokuWiki > Administration > Extension Manager")

`Search and Install tab > DW2PDF Plugin > Install`
<br />
![alt text](https://raw.githubusercontent.com/jeremyj563/images-github/master/DokuWiki/procedures/dokuwiki/automated-pdf-export/2.png "Search and Install tab > DW2PDF Plugin > Install")
<br />
![alt text](https://raw.githubusercontent.com/jeremyj563/images-github/master/DokuWiki/procedures/dokuwiki/automated-pdf-export/3.png "Search and Install tab > DW2PDF Plugin > Install")
<br />
<br />

#### MBSTRING PHP MODULE

##### install
`$ sudo apt install php7.0-mbstring`

##### enable
`$ sudo phpenmod mbstring`

##### restart apache
`$ sudo apachectl graceful`
<br />
<br />

#### CURL

##### install
`$ sudo apt install curl`

##### verify gss-api support (only needed if using Kerberos auth)
```
$ curl --version | grep GSS
Features: AsynchDNS IDN IPv6 Largefile GSS-API Kerberos SPNEGO NTLM NTLM_WB SSL libz TLS-SRP HTTP2 UnixSockets HTTPS-proxy PSL
```
```
$ ldd /usr/bin/curl | grep gss
libgssapi_krb5.so.2 => /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 (0x00007f1ee1c00000)
```
<br />

#### INSTALL CRONTAB

##### edit crontab
`$ sudo crontab -e`

##### crontab entry
```
# pdf export - every day at 1:00 AM
0 1 * * * ~/scripts/pdf-export.sh > /dev/null
```
