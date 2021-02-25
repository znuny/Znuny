# Contributing to Znuny

## What is Znuny?
Please have a look [here](https://www.znuny.org/).

## How to contribute?
If you have a fix for some bug you found or any other improvement of the code and want to share it, please create a [pull request](https://github.com/znuny/Znuny/pulls).

Znuny is (at least for now) focused on security and bug fixes. Therefore we would like to politely ask you to not provide new features or changes in behavior via pull requests. See "Contributing new features and changes in behavior" below.

### Check your code with the code policy package

#### What is the OTRS code policy package?
With the help of the [OTRS code policy package](https://github.com/OTRS/otrscodepolicy) you can check if your code matches the OTRS code style. It's based on TidyAll, extended by many plugins specific to OTRS.

#### How to use it?
When you made your changes and before you commit them, execute the code policy to let it check your changes. If executed without any parameters, the following command will check all changed files that haven't been committed yet. The command should be executed from within the Znuny base directory. You should stage your changes (via `git add`) before running it, so that you can afterwards see the changes made by the code policy package (via `git diff`), if any.

`perl <path-to-your-code-policy-package>/bin/otrs.CodePolicy.pl`

### Tests
If you fix something, a test should be provided or extended to test your changes. You can find all tests in the directory `scripts/test` in your Znuny base directory. Ideally there already should exist one or more tests for the part of Znuny that your code changes. You then can update these tests to also test your fix. If in doubt, create a new test file specifically for your fix. Have a look at said existing tests to find out how to write tests.

You can execute a single test with the following command from within your Znuny base directory:
`perl bin/otrs.Console.pl Dev::UnitTest::Run --verbose --test <path to test file>`

If there is for example a test file `scripts/test/Ticket/NumberGenerator.t` you have to execute the following command (please note how to give the test file without the `scripts/test/` prefix and without the `.t` suffix):
`perl bin/otrs.Console.pl Dev::UnitTest::Run --verbose --test Ticket/NumberGenerator`

### Contributing new features and changes in behavior
As mentioned, the focus of Znuny is for now on security and bug fixes.

Currently, the only way to contribute new features to Znuny (or older OTRS versions) is to put your changes into a package (OPM). A package consists of a source OPM file and all files added or changed by you which will be copied to your Znuny installation directory upon installation of the package. The directory structure within your package must match the one of Znuny.

You then can build an installable package of your code with the following command, executed from within your Znuny base directory:
`bin/otrs.Console.pl Dev::Package::Build --module-directory <path-to-the-base-directory-of-your-package> <path-to-the-sopm-file-of-your-package> <directory-to-put-in-the-created-opm-package-file>`

The package name should always be prepended by your company name (e. g. `MyCompany-PackageName`). Example for building your package `MyCompany-MyFirstPackage`:
`bin/otrs.Console.pl Dev::Package::Build --module-directory /path/to/MyCompany-MyFirstPackage/ /path/to/MyCompany-MyFirstPackage/MyCompany-MyFirstPackage.sopm /path/to/created/package/`

#### Example packages
You can find many open source packages from and for Znuny at [GitHub](https://github.com/znuny/), for example the package [Znuny4OTRS-CTI](https://github.com/znuny/Znuny4OTRS-CTI). Have a look at them, especially their sopm file in the root directory.
