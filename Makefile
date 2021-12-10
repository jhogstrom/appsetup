.PHONY: setup %/backend/requirements.txt
# .SILENT:
.PRECIOUS: \
	%/.env \
	%/.git \
	%/frontend %/backend %/src \
	%/requirements.txt %/backend/requirements.txt %/backend/api/requirements.txt \
	%/.gitignore \
	%/backend/app.py \
	%/README.md

match=$*
log=echo "** Making $@..."

# This is a way to bypass a bug in $(lastword...)
mymakefile=$(word $(words $(1)), $(1))
MKFILE=$(call mymakefile, $(MAKEFILE_LIST))

# Target-specific parametrization.
# These variables will be sent to a submake (cannot use target specific variables as prereqs).
# If we need more setup-types, more (and different) parametrization may have to be made.
# The MODE variable is used for conditionals in the submake.
setup_webapp: coredirs=$(NAME)/frontend $(NAME)/backend $(NAME)/.git
setup_webapp: backend_prereqs=$(NAME)/backend/app.py \
	$(NAME)/backend/api/requirements.txt \
	$(NAME)/backend/requirements.txt \
	$(NAME)/requirements.txt \
	$(NAME)/README.md
setup_webapp: MODE=webapp

setup_local: coredirs=$(NAME)/src $(NAME)/.git
setup_local: backend_prereqs=$(NAME)/requirements.txt $(NAME)/README.md
setup_local: MODE=local

vpath %.md $(dir $(MKFILE))

%/.gitignore:
	$(log)
	echo foo > $@

%/backend/api/requirements.txt:
	$(log)
	mkdir -p $(dir $@)
	echo fastapi > $@
	echo pydantic >> $@
	echo mangum >> $@
	echo python-dotenv >> $@

%/backend/requirements.txt:
	$(log)
	mkdir -p $(dir $@)
	touch $@
	echo -r api/requirements.txt >> $@
	echo git+https://github.com/aditrologistics/awscdk.git >> $@

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
	mkdir -p $(dir $@)
	cd $(dir $@) && \
	cdk init app --language python --generate-only
	sed -i -r 's/BackendStack(.,)/$(NAME)Stack\\1/g' $@

%/.env:
	$(log)
	mkdir -p $(dir $@)
	cd $(match) && python -m venv .env

%/backend: $(backend_prereqs) %/.env %/.gitignore
	$(log)
	mkdir -p $@

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

dir_%: makedir_% $(coredirs)

setup: dir_$(NAME)
	echo Setup of $(subst dir_,,$<) completed.


setup_webapp setup_local:
# Ensure the NAME parameter is set.
ifeq ($(NAME),)
	$(error Pass NAME=<appname> on command line)
endif
	$(MAKE) -f $(MKFILE) \
		setup NAME=$(NAME) MODE=$(MODE)\
		"coredirs=$(coredirs)" "backend_prereqs=$(backend_prereqs)"


tester:
	$(log)
	touch foobar

%.html: %.md
	python $(dir $(MKFILE))mkhtml.py --input $< --output $@

help: $(dir $(MKFILE))README.html
	cmd /c $(subst /,\\,$<)

