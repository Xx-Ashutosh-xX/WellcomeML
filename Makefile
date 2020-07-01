.DEFAULT_GOAL := all

VIRTUALENV := build/virtualenv/bin
PYTHON_VERSION := python3

$(VIRTUALENV)/.installed:
	@if [ -d $(VIRTUALENV) ]; then rm -rf $(VIRTUALENV); fi
	@mkdir -p $(VIRTUALENV)
	virtualenv --python $(PYTHON_VERSION) $(VIRTUALENV)
	$(VIRTUALENV)/pip3 install -r requirements_test.txt
	$(VIRTUALENV)/pip3 install -r docs/requirements.txt # Installs requirements to docs
	$(VIRTUALENV)/pip3 install -e .[deep-learning]
	touch $@

.PHONY: update-docs
update-docs:
	$(VIRTUALENV)/sphinx-apidoc --no-toc -d 5 -H WellcomeML -o ./docs -f wellcomeml
	. $(VIRTUALENV)/activate && cd docs && make html

.PHONY: virtualenv
virtualenv: $(VIRTUALENV)/.installed

.PHONY: dist
dist: update-docs
	./create_release.sh

# Spacy is require for testing spacy_to_prodigy

$(VIRTUALENV)/.models:
	$(VIRTUALENV)/python -m spacy download en_core_web_sm
	touch $@

$(VIRTUALENV)/.deep_learning_models:
	$(VIRTUALENV)/python -m spacy download en_trf_bertbaseuncased_lg
	touch $@

$(VIRTUALENV)/.non_pypi_packages:
	$(VIRTUALENV)/pip install git+https://github.com/epfml/sent2vec.git
	touch $@

.PHONY: download_models
download_models: $(VIRTUALENV)/.installed $(VIRTUALENV)/.models

.PHONY: download_deep_learning_models
download_deep_learning_models: $(VIRTUALENV)/.models $(VIRTUALENV)/.deep_learning_models

.PHONY: download_nonpypi_packages
download_nonpypi_packages: $(VIRTUALENV)/.installed $(VIRTUALENV)/.non_pypi_packages

.PHONY: test
test: $(VIRTUALENV)/.models $(VIRTUALENV)/.deep_learning_models $(VIRTUALENV)/.non_pypi_packages
	$(VIRTUALENV)/pytest -m  "not (integration or transformers)" --durations=0 --disable-warnings --tb=line --cov=wellcomeml ./tests

.PHONY: test-transformers
test-transformers:
	$(VIRTUALENV)/pip install -r requirements_transformers.txt
	export WELLCOMEML_ENV=development_transformers && $(VIRTUALENV)/pytest -m "transformers" --durations=0 --disable-warnings --cov-append --tb=line --cov=wellcomeml ./tests/transformers


.PHONY: test-integrations
test-integrations:
	$(VIRTUALENV)/pytest -m "integration" --disable-warnings --tb=line ./tests

all: virtualenv
