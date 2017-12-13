# PantheonSiteSync
## Description
PantheonSiteSync syncs Drupal sites on Pantheon to a local machine via automation. Essentially, it helps manage codebases, databases and filebases locally by keeping them in sync with their Pantheon counterparts.

## Initializing
### User setup
Add your user information to PantheonSiteSync/config/user.sh before using.

### Start clean
Make PantheonSiteSync/drupal/data/tokens_to_restore_db empty. Your usage will populate it with your data.

### Root directory
We are expecting the root directory to be named 'PantheonSiteSync'. If you wish to change your scripts' root directory folder name, add the following line to your's and the root user's .profile file:
```
export PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=<YOUR SCRIPT ROOT FOLDER NAME>
```

### IDE directory
This is empty, but if you wish to automate some of your IDE's setup, add the code here and call it from the install.sh file.

### Personalization
Customize the files in the PantheonSiteSync/config directory to your needs.

## Requirements
### brew
You will need Homebrew/brew for, well, everything.

### rsync
rsync must be version 3.1+. It is on brew.

You will need an ssh key for the root user for the rsync operation. You do this with:
```
sudo bash -i
mkdir .ssh
cd .ssh
ssh-keygen -t rsa -b 4096
```
Copy your new rsa.pub file to Pantheon

### gsed
You need it, get it from brew.

### tree
You need it, get it from brew. Alternatively, replace it with the reporting of your liking.

### mysql_config_editor
If your mysql is older you might not have this, update mysql or alter the code to not need it.

### apache
This uses apache 2.4 from brew. If you have a different web server write your own scripts for your web server and then include the script in the install.sh file and of course exclude apache. This way we build up a library of web servers and people can just "plug in" the one they want.

Even if you are using apache 2.4 from brew you will most probably have different paths for location of things. To handle this change the paths in: ./web-server/templates/* which you will want to match up with any patch changes you make in ./config/system.sh

### pv
You need it, get it from brew. Alternatively, replace it with the reporting of your liking.

## Usage
### ./install.sh
Put PantheonSiteSync as a sibling folder to your other projects. Perform the following commands:
```
cd PantheonSiteSync
sudo
./install.sh <folder name for desired project>
```

### ./drupal/drupal_setup.sh
Some components (eventually all hopefully) can be run independent of ./install.sh. Primarily these are the DB commands to set and restore user-1 in a Drupal DB. You do this by running:
```
./drupal/drupal_setup.sh -f <FUNCTION> <PROJECT-QUERY>
```
<FUNCTION> is the name of the function to call in drupal_setup.sh. These will almost certainly be one of:
* set_local_user_one_pass
* restore_local_user_one_pass
* set_remote_user_one_pass
* restore_remote_user_one_pass

<PROJECT-QUERY> is the first few letters of the project's folder name, enough letters to determine which project is best but less will still work, you'll just have to make a decision when prompted with options.

### ./git-merge-from-upstream.sh
This is not really part of the automation. It's really just a convenience in case you are prone to forget the commands for merging upstream into your local git repo. You can use it with the following commands:
```
cd <DRUPAL ROOT DIRECTORY>
./git-merge-from-upstream.sh
```
You can run the script (as we do above) or just paste it's content on the command line.

### remove_cmds.sh
The file PantheonSiteSync/remove/remove_cmds.sh is not meant to be run. It is instead a reminder of all the things touched by the install script and you should use it as a guide to everything to check and modify if you wish to remove an install.

### Workflow directory
Throw anything in PantheonSiteSync/workflow that helps you with your overall workflow. This is not part of the automation, just a placeholder for things you may use repeatedly in your workflow.

## Credits
* Creator/Maintainer: Reg Proctor, r100@regproctor.com
* Maintainer: Michael Gilardi, mgilardi@asu.edu / mdgilardi@gmail.com
