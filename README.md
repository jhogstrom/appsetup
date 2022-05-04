# Objective

The purpose of this script is to reduce the setup time for a 'plain vanilla´ application, be it a web application or just a local python app - with all the standard bits and pieces already in place.

When you find yourself repeatedly adding more things manually, please update the script to save time in the future.

# Usage

```
make setup_webapp NAME=mynewproject
```
_To create a full stack application (JS/Vue + CDK/Python)_

```
make setup_backend NAME=mynewproject
```
_To create a backend application (CDK/Python)_

```
make setup_local NAME=mynewproject
```
_To create a local python application (venv)_

or


or if you do not have the makefile in the same directory:

```
make -f <path_to_makefile>\Makefile setup_local NAME=<mynewproject>
make -f <path_to_makefile>\Makefile setup_webapp NAME=<mynewproject>
```

The directory `mynewproject` will be created under the current directory. For `setup_local` a python venv will be set up. `setup_webapp` adds structure to create both frontend (JS/Vue/Vuex/router) and backend (Python/CDK/FastAPI) generated.

Additionally a git repository will be initiated, and a first commit made.

## Creating github repo

If the root directory contains `makevars.mak` that file will be included. It should contain the following variables:
```
github_pat=<github personal access token>
github_username=<github user name>
github_org=<github organization name>
github_team=<github team>
```

To create a personal access token, please refer to the [github documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). The token needs at least `admin:org/write:org`, probably also `repo`.

If `github_username` is not set the script will attempt to create a repository named `$(NAME)` for the `$(github_org)` in github and grant `maintain` access to `$(github_team)`.

Finally the first commit will be pushed.

# Requirements
You will need to have (at least) the following components installed for `setup_local`:

* [Python](https://www.python.org/downloads/release/python-399/) (3.10 is not yet supported in Lambda runtime)
* [git](https://git-scm.com/downloads)
* make

Also make sure to install the requirements.

```
pip install -r requirements.txt
```

For `setup_webapp` you also need the following:

* [Node](https://nodejs.org/en/download/)
* CDK (`npm install -g aws-cdk`)
* Vue CLI (`npm install -g @vue/cli`)

## make
`make` is available on most linux systems set up for development, but
is lacking on Windows.

The easiest way to install make is to download the mingw [build of make](https://sourceforge.net/projects/mingw/files/MinGW/Extension/make/mingw32-make-3.80-3/) and drop it into
git's bin-folder.

Download the `.tar.gz` file and unpack it (use [7zip](https://www.7-zip.org/download.html)). Rename the file `bin/mingw32-make.exe` to `bin/make.exe` and copy it to `C:\Program Files\Git\mingw64\bin` (or wherever you have installed `git`).

