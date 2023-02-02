.PHONY: setup %/backend/requirements.txt
# .SILENT:
.PRECIOUS: \
	%/.venv \
	%/.git \
	%/makefiles \
	%/frontend %/backend %/src \
	%/.browserlistrc \
	%/activate.bat \
	%/requirements.txt %/backend/requirements.txt %/backend/api/requirements.txt \
	%/.gitignore \
	%/backend/app.py \
	%/README.md \
	%/.flake8


# This is a way to bypass a bug in $(lastword...)
mymakefile=$(word $(words $(1)), $(1))
# Replace windows pathsep with unix pathsep
MKFILE:=$(subst \,/,$(call mymakefile, $(MAKEFILE_LIST)))
ROOTDIR:=$(dir $(MKFILE))
MKDIR=@mkdir -p $(dir $@)
match=$*
ECHO=@echo
log=$(ECHO) -e "\n** Making $@...\n"
dosdir=$(subst /,\\\\\\\\,$(subst /d/,d:/,$(subst /c/,c:/,$(1))))
CP=@cp
MAKEFILE_REPO_URL?=https://github.com/aditrologistics/makefiles.git
GITHUB_ROOT_URL?=https://github.com/aditrologistics
-include $(ROOTDIR)/../makevars.mak


default: help
prereqs:
	pip install -r $(ROOTDIR)/requirements.txt
# Target-specific parametrization.
# These variables will be sent to a submake (cannot use target specific variables as prereqs).
# If we need more setup-types, more (and different) parametrization may have to be made.
# The MODE variable is used for conditionals in the submake.
setup_webapp: MODE=webapp
setup_webapp: coredirs=$(NAME)/frontend $(NAME)/backend $(NAME)/.git $(NAME)/makefiles
setup_webapp: backend_prereqs=$(NAME)/backend/app.py \
	$(NAME)/backend/api/requirements.txt \
	$(NAME)/backend/requirements.txt \
	$(NAME)/backend/.flake8 \
	$(NAME)/frontend/.browserlistrc \
	$(NAME)/requirements.txt \
	$(NAME)/README.md

setup_backend: MODE=webapp
setup_backend: coredirs=$(NAME)/backend $(NAME)/.git $(NAME)/makefiles
setup_backend: backend_prereqs=$(NAME)/backend/app.py \
	$(NAME)/backend/api/requirements.txt \
	$(NAME)/backend/requirements.txt \
	$(NAME)/backend/.flake8 \
	$(NAME)/requirements.txt \
	$(NAME)/README.md

setup_local: MODE=local
setup_local: coredirs=$(NAME)/src $(NAME)/.git
setup_local: backend_prereqs=$(NAME)/requirements.txt \
	$(NAME)/.flake8 \
	$(NAME)/README.md

vpath %.md $(ROOTDIR)
vpath %.flake8.template $(ROOTDIR)/templates
vpath %.gitignore.template $(ROOTDIR)/templates
vpath %.browserlistrc.template $(ROOTDIR)/templates
vpath %activate.bat.template $(ROOTDIR)/templates
vpath %app.py.template $(ROOTDIR)/templates

%/.flake8: .flake8.template
	$(log)
	$(CP) $< $@

%/.gitignore: .gitignore.template
	$(log)
	$(CP) $< $@

%/.browserlistrc: .browserlistrc.template
	$(log)
	$(CP) $< $@

%/activate.bat: activate.bat.template
	$(log)
	@sed s#$$\(DIR\)#$(call dosdir,$(shell pwd))\\\\\\\\$(NAME)#g $< > $@

%/backend/api/requirements.txt:
	$(log)
	$(MKDIR)
	@touch $@
	$(ECHO) fastapi >> $@
	$(ECHO) pydantic >> $@
	$(ECHO) mangum >> $@
	$(ECHO) python-dotenv >> $@

%/backend/requirements.txt:
	$(log)
	$(MKDIR)
	@touch $@
	$(ECHO) "-r api/requirements.txt" >> $@
# 	$(ECHO) git+https://github.com/aditrologistics/awscdk.git >> $@

%/README.md:
	$(ECHO) "Please find time to add information here" > $@

%/requirements.txt:
	$(log)
	@touch $@
	$(ECHO) rope >> $@
	$(ECHO) flake8 >> $@
	$(ECHO) python-dotenv >> $@
ifeq ($(MODE),webapp)
	$(ECHO) "-r backend/requirements.txt" >> $@
endif

# This looks very much like a file, but the directory
# part is only there to help the recipe.
%/init_cdk:
	$(log)
	$(MKDIR)
	cd $(dir $@) \
		&& cdk init app --language python --generate-only

%/backend/app.py: app.py.template %/backend/init_cdk
	$(log)
	$(MKDIR)
	$(CP) $< $@
	$(CP) $(dir $<)/backend_stack.py.template $(dir $@)/backend/backend_stack.py

%/.venv:
	$(log)
	$(MKDIR)
	cd $(match) \
		&& python -m venv $(notdir $@)

%/backend: $(backend_prereqs) %/.venv %/.gitignore
	$(log)
	@mkdir -p $@
	$(ECHO) "Upgrading PIP and installing requirements. This can take a while..."
	cd $(match) \
		&& source .venv/Scripts/activate \
		&& python.exe -m pip install --upgrade pip \
		&& pip install -r requirements.txt && pip freeze


%/frontend:
	$(log)
	@mkdir -p $@
	$(ECHO) "Installing vue + components. This can take a while..."
# Some package complained about a too new version of node. Hence ask yarn to ignore
# version of node engine while instaling, then restore the value.
	yarn config get ignore-engines > /tmp/.yarn.config.get.ignore-engines
	yarn config set ignore-engines true
	@cd $(match) \
		&& vue create \
			--no-git \
			--merge \
			--skipGetStarted \
			--preset ../$(ROOTDIR)/templates/vuedefaults.json \
			frontend
	ignoreengines=$$(</tmp/.yarn.config.get.ignore-engines); \
	if [ "$$ignoreengines" = "undefined" ]; then \
		yarn config delete ignore-engines; \
	else \
		yarn config set ignore-engines $$ignoreengines; \
	fi

%/.git:
	$(log)
	cd $(match) \
		&& git init . \
		&& git submodule add $(MAKEFILE_REPO_URL) makefiles \
		&& git submodule init \

%/makefiles: %/.git
	$(log)
	cd $(match) \
		&& echo @include makefiles/Makefile > Makefile \
		&& echo -e \
			"WORKLOAD_NAME=$(NAME)\n" \
			"AWS_ACCOUNT_DEV=XXX\n" \
			"AWS_ACCOUNT_PROD=XXX\n" \
			"AWS_ACCOUNT_TEST=XXX\n" \
			"\n" \
			"AWS_REGION=eu-north-1\n" \
			"SSO_ROLE=ALAB-Admin" > makevars.mak

makedir_%:
	$(ECHO) coredirs $(coredirs)
	mkdir $(match)

%/README.html: README.md
	$(MKDIR)
	python $(ROOTDIR)mkhtml.py --input $< --output $@

help: $(ROOTDIR)/output/README.html
	cmd /c $(subst /,\\,$<)


tester:
	$(log)
	curl -i -u jhogstrom:$(githubtoken) https://api.github.com/users/jhogstrom


GITHUB_HEADERS=-H "Accept: application/vnd.github.v3+json"
GITHUB_AUTH=-u $(github_username):$(github_pat)
GITHUB_ORG_URL=https://api.github.com/orgs/$(github_org)
GITHUBAPI=curl \
	$(GITHUB_HEADERS) \
	$(GITHUB_AUTH)

GITHUB_PRIVATE_REPO?=true
GITHUB_HAS_ISSUES?=false
GITHUB_HAS_PROJECTS?=false
GITHUB_HAS_WIKI?=false

create_github_repo:
	# Create repository
	$(GITHUBAPI) $(GITHUB_ORG_URL)/repos \
	-X POST \
	-d '{ \
		"name":"$(NAME)", \
		"description":"Code pertaining to $(NAME).", \
		"homepage":"https://github.com/$(github_org)/$(NAME)", \
		"private":$(GITHUB_PRIVATE_REPO), \
		"has_issues":$(GITHUB_HAS_ISSUES), \
		"has_projects":$(GITHUB_HAS_PROJECTS), \
		"has_wiki":$(GITHUB_HAS_WIKI) \
	}'

	# Grant access to TEAM
	$(GITHUBAPI) $(GITHUB_ORG_URL)/teams/$(github_team)/repos/$(github_org)/$(NAME) \
		-X PUT \
		-d '{ \
			"permission": "maintain" \
		}'

GITPUSH=$(if $(github_username),git push -u origin main,echo done)
CREATE_GITHUB_REPO:=$(if $(github_username),create_github_repo)


%/first_commit: $(CREATE_GITHUB_REPO)
	$(log)
	cd $(match) \
		&& git add . \
		&& git commit -m "Initialized" \
		&& git remote add origin $(GITHUB_ROOT_URL)/$(match).git \
		&& $(GITPUSH)


setup: makedir_$(NAME) $(coredirs) $(NAME)/first_commit
# Ensure the NAME parameter is set.
ifeq ($(NAME),)
	$(error Pass NAME=<appname> on command line)
endif
	$(ECHO) Setup of $(NAME) completed.

setup_webapp setup_local setup_backend:
# Ensure the NAME parameter is set.
ifeq ($(NAME),)
	$(error Pass NAME=<appname> on command line)
endif
	$(MAKE) -f $(MKFILE) \
		setup NAME=$(NAME) MODE=$(MODE) \
		coredirs="$(coredirs)" backend_prereqs="$(backend_prereqs)"
