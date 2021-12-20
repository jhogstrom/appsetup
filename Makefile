.PHONY: setup %/backend/requirements.txt
.SILENT:
.PRECIOUS: \
	%/.env \
	%/.git \
	%/frontend %/backend %/src \
	%/requirements.txt %/backend/requirements.txt %/backend/api/requirements.txt \
	%/.gitignore \
	%/backend/app.py \
	%/README.md \
	%/.flake8


# This is a way to bypass a bug in $(lastword...)
mymakefile=$(word $(words $(1)), $(1))
# Replace windows pathsep with unix pathsep
MKFILE=$(subst \,/,$(call mymakefile, $(MAKEFILE_LIST)))
ROOTDIR=$(dir $(MKFILE))
MKDIR=mkdir -p $(dir $@)
match=$*
log=echo "** Making $@..."

# Target-specific parametrization.
# These variables will be sent to a submake (cannot use target specific variables as prereqs).
# If we need more setup-types, more (and different) parametrization may have to be made.
# The MODE variable is used for conditionals in the submake.
setup_webapp: MODE=webapp
setup_webapp: coredirs=$(NAME)/frontend $(NAME)/backend $(NAME)/.git
setup_webapp: backend_prereqs=$(NAME)/backend/app.py \
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

%/.flake8: .flake8.template
	$(log)
	cp $< $@

%/.gitignore: .gitignore.template
	$(log)
	cp $< $@

%/backend/api/requirements.txt:
	$(log)
	$(MKDIR)
	echo fastapi > $@
	echo pydantic >> $@
	echo mangum >> $@
	echo python-dotenv >> $@

%/backend/requirements.txt:
	$(log)
	$(MKDIR)
	touch $@
	echo -r api/requirements.txt >> $@
# 	echo git+https://github.com/aditrologistics/awscdk.git >> $@

%/README.md:
	echo "Please find time to add information here" > $@

%/requirements.txt:
	$(log)
	echo rope > $@
	echo flake8 >> $@
	echo python-dotenv >> $@
ifeq ($(MODE),webapp)
	echo -r backend/requirements.txt >> $@
endif

%/backend/app.py:
	$(log)
	$(MKDIR)
	cd $(dir $@) && \
	cdk init app --language python --generate-only
	sed -i -r 's/BackendStack(.,)/$(NAME)Stack\\1/g' $@

%/.env:
	$(log)
	$(MKDIR)
	cd $(match) && python -m venv .env

%/backend: $(backend_prereqs) %/.env %/.gitignore
	$(log)
	mkdir -p $@
	echo "Upgrading PIP and installing requirements. This can take a while..."
	cd $(match) && \
	source .env/Scripts/activate && \
	python.exe -m pip install --upgrade pip && \
	pip install -r requirements.txt && pip freeze


%/frontend:
	$(log)
	mkdir -p $@
	cd $(match) && vue create --no-git --merge --skipGetStarted frontend
	cd $@ && vue add vuex
	cd $@ && vue add vuetify
	cd $@ && vue add router

%/.git:
	$(log)
	cd $(match) && git init .

makedir_%:
	echo coredirs $(coredirs)
	mkdir $(match)

%/README.html: README.md
	$(MKDIR)
	python $(ROOTDIR)mkhtml.py --input $< --output $@

help: $(ROOTDIR)/output/README.html
	cmd /c $(subst /,\\,$<)


tester:
	$(log)
	touch foobar


setup: makedir_$(NAME) $(coredirs)
# Ensure the NAME parameter is set.
ifeq ($(NAME),)
	$(error Pass NAME=<appname> on command line)
endif
	echo Setup of $(subst dir_,,$<) completed.

setup_webapp setup_local:
# Ensure the NAME parameter is set.
ifeq ($(NAME),)
	$(error Pass NAME=<appname> on command line)
endif
	$(MAKE) -f $(MKFILE) \
		setup NAME=$(NAME) MODE=$(MODE) \
		coredirs="$(coredirs)" backend_prereqs="$(backend_prereqs)"




