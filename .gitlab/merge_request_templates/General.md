## Please do not create a Pull Request without creating an issue first.
- Merge requests should be directed at the `development` branch.
- Merge request pipeline must succeed
#### **Please provide enough information so that others can review your merge request**:

- Explain why this change needs to be made. What existing problem does the pull request solve (does it close an existing issue)?

#### **Code formatting**

- Use 2 spaces for indentation
- Use camelCase for any new variables that are created
- New functions should follow the `New-Function` naming format, follow PowerShell's [approved verbs guidance](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.1), and be located in `files/functions`
- If a new feature is being proposed, update `files/cfg/config.yaml.template` to reflect the change
- Update the wiki to reflect any changes made in `files/cfg/config.yaml.template`.
- Increase the version number (using semantic versioning) 

#### **Closing issues**

- Put `closes #XXXX` in your comment to auto-close the issue that your merge fixes (if an issue is directly addressed).