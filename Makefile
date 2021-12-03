.PHONY: setup %/backend/requirements.txt
# .SILENT:
.PRECIOUS: \
	%/.env \
	%/.git \
	%/frontend %/backend \
	%/requirements.txt %/backend/requirements.txt %/backend/api/requirements.txt \
	%/.gitignore \
	%/backend/app.py
ifeq ($(NAME),)
$(error Pass NAME=<appname> on command line)
endif

match=$*
log=echo "** Making $@..."

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
	echo -r api/requirements.txt >> $@
	echo git+https://github.com/aditrologistics/awscdk.git >> $@

%/requirements.txt:
	$(log)
	echo rope > $@
	echo flake8 >> $@
	echo -r backend/requirements.txt >> $@

%/backend/app.py:
	$(log)
	mkdir -p $(dir $@)
	cd $(dir $@) && cdk init app --language python --generate-only

%/.env:
	$(log)
	mkdir -p $(dir $@)
	cd $(match) && python -m venv .env

%/backend: %/backend/app.py %/.env %/.gitignore \
		%/requirements.txt \
		%/backend/requirements.txt \
		%/backend/api/requirements.txt
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
	mkdir $(match)

dir_%: makedir_% %/frontend %/backend %/.git
	echo hello

setup: dir_$(NAME)
	echo Setup of $(subst dir_,,$<) completed.


tester:
	$(log)
	node