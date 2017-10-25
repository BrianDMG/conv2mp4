## **Scheduled Task Example**

To fully automate this script on a Windows system, you will need to set it as a scheduled task. The following is a brief example of how to do that.

1. Open task scheduler and choose **"Create task"**
2.  On the **General** tab:
	- Give the task a name. This can be whatever you like, but should be something descriptive.
	- (*Optional*) Write a short description of the task.
	- Click the **Change User or group** button, and ensure that both the computer name and user name show up in the format of "```Computer\User```".
	- Click the **Run whether user is logged in or not** radio button
	- Check the **Run with highest privileges** button
	- <img src="http://teague.io/wp-content/uploads/2017/04/1.png">
3. Under the **Triggers** tab:
	- Change "Begin the task" dropdown to **On a schedule**
	- Change the scheduling settings to your liking. Choose a time when your server's usage is typically minimal, and allows time for the script to run and complete before usage picks back up.
	- Ensure the **Enabled** checkbox is selected
	- <img src="http://teague.io/wp-content/uploads/2017/04/2.png">
4. On the **Actions** tab:
	- Click the **New action** button.
	- Change the **Action** dropdown to **Start a program**.
	- Under **Program/script**, type **Powershell.exe**
	- In the **Add arguments** field, enter **-ExecutionPolicy Bypass -File c:\path\to\script\conv2mp4-ps.ps1**
	- <img src="http://teague.io/wp-content/uploads/2017/04/3.png">
	- (*Optional*) Tailor settings under the **Conditions** and **Settings** tabs to your liking

The script will now run automatically to your specifications.
