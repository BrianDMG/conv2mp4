## Please do not create a Pull Request without creating an issue first.
- Any change needs to be discussed before proceeding.
- Failure to do so may result in the rejection of the pull request.
- Pull requests should be directed at the `develop` branch.

#### **Please provide enough information so that others can review your pull request**:

- Explain the **details*- for making this change. What existing problem does the pull request solve?

<!-- Example: When "Adding a function to do X", explain why it is necessary to have a way to do X. -->

#### **Code formatting**

- Use 4 spaces for indentation
- Use camelCase for any new variables that are created
- New functions should follow the `NewFunction` naming format, and be located in `files/functions`
- If a new feature is being proposed, update `files/cfg/config.template` to reflect the change
- Update the `README.md` file to reflect any changes made in `files/cfg/config.template`.
- Increase the version number in any examples files to the new version that this Pull Request would represent. The versioning scheme we use is [SemVer](http://semver.org/).
- Make sure you didn't accidentally leave your personal configuration settings in `files/cfg/config.template`.

#### **Closing issues**

- Put `closes #XXXX` in your comment to auto-close the issue that your PR fixes (if an issue is directly addressed).
