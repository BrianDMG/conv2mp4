## **Scheduled Task Example**

To fully automate this script on a Windows system, you will need to set it as a scheduled task. The following is a brief example of how to do that.

1. Open task scheduler and choose **"Create task"**
2.  On the **General** tab:
	- Give the task a name. This can be whatever you like, but should be something descriptive.</li>
	-(*Optional*) Write a short description of the task.</li>
	- Click the **Change User or group** button, and ensure that both the computer name and user name show up in the format of "Computer\User".</li>
	- Click the **Run whether user is logged in or not** radio button</li>
	- Check the **Run with highest privileges** button</li></ul>
	- <img src="http://teague.io/wp-content/uploads/2017/04/1.png"></li>
3. Under the **Triggers** tab:
	- Change "Begin the task" dropdown to **On a schedule**</li>
	- Change the scheduling settings to your liking. Choose a time when your server's usage is typically minimal, and allows time for the script to run and complete before usage picks back up.</li>
	- Ensure the **Enabled** checkbox is selected</li></ul>
	- <img src="http://teague.io/wp-content/uploads/2017/04/2.png"></li>
4. On the **Actions** tab:
	- Click the **New action** button.</li>
	- Change the **Action** dropdown to **Start a program**.</li>
	- Under **Program/script**, type **Powershell.exe**</li>
	- In the **Add arguments** field, enter **-ExecutionPolicy Bypass -File c:\path\to\script\conv2mp4-ps.ps1**</li></ul>
	- <img src="http://teague.io/wp-content/uploads/2017/04/3.png"></li>
	- (*Optional*) Tailor settings under the **Conditions** and **Settings** tabs to your liking</li></ol>

The script will now run automatically to your specifications.
