Setup
======

Setup is a script to set up a macOS laptop for development at IdeaCrew.

It can be run multiple times on the same machine safely.
It installs, upgrades, or skips packages
based on what is already installed on the machine.

Requirements
------------

We support:

* macOS Ventura (13.x) on Apple Silicon and Intel
* macOS Monterey (12.x) on Apple Silicon and Intel

Older versions may work but aren't regularly tested.
Bug reports for older versions are welcome.

If you run into any issues along the way you can re-run the script and only the missing pieces will be resolved.

Install
-------

Download the script:

```sh
curl --remote-name https://raw.githubusercontent.com/4till2/scripts/main/new-mac/setup
```

Review the script (avoid running scripts you haven't read!):

```sh
less setup
```

Execute the downloaded script:

```sh
sh setup 2>&1 | tee ~/setup.log
```

Optionally, review the log:

```sh
less ~/setup.log
```

Debugging
---------

Your last Setup run will be saved to `~/setup.log`.
Read through it to see if you can debug the issue yourself.
If not, copy the lines where the script failed into a
[new GitHub Issue](https://github.com/4till2/scripts/issues/new) for us.
Or, attach the whole log file as an attachment.

What it sets up
---------------

macOS tools:

* [Homebrew] for managing operating system libraries.

[Homebrew]: http://brew.sh/

Unix tools:

* [Git] for version control
* [Zsh] as your shell
* [Docker] for developing (you may need to download Docker Desktop manually if the script fails to do so)

[Git]: https://git-scm.com/
[Zsh]: http://www.zsh.org/
[Docker]: https://docker.com

Programming languages, package managers, and configuration:

* [asdf-vm] for managing programming language versions
* [Node.js] and [npm], for running apps and installing JavaScript packages
* [Ruby] stable for writing general-purpose code
* [Rosetta 2] for running tools that are not supported in Apple silicon processors

[Node.js]: http://nodejs.org/
[npm]: https://www.npmjs.org/
[asdf-vm]: https://github.com/asdf-vm/asdf
[Ruby]: https://www.ruby-lang.org/en/
[Rosetta 2]: https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment

Git:

We configure ssh and signed commits with gpg for you with a bit of interaction on your behalf.
Pay attention and when prompted follow the link to github to enter the generated keys respectively.

Repositories:

> The script clones into a directory `~/Projects`. Change that by resetting PROJECT_FOLDER at the top of the script

> The script will clone using the password-protected SSH key method (ie. git@github.com:ideacrew/repo.git).
> This is configured in previous steps.
> In the future you should do the same.
- https://github.com/ideacrew/ea_enterprise.git
- https://github.com/ideacrew/fdsh_gateway.git
- https://github.com/ideacrew/medicaid_gateway.git
- https://github.com/ideacrew/medicaid_eligibility.git
- https://github.com/ideacrew/polypress.git

Docker:

Once the repositories are downloaded we start Docker and you are ready to develop!

---

It should take less than 15 minutes to install (depends on your machine).

Contributing
------------

Edit the `script` file.
Document in the `README.md` file.
Update the `CHANGELOG`.

### Testing your changes

Test your changes by running the script on a fresh install of macOS.
You can use the free and open source emulator [UTM].

Tip: Make a fresh virtual machine with the installation of macOS completed and
your user created and first launch complete. Then duplicate that machine to test
the script each time on a fresh install thats ready to go.

[UTM]: https://mac.getutm.app
