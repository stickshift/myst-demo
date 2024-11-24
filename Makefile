################################################################################
# Makefile
#
#   * General
#   * Output Dirs
#   * Environment
#   * Site
#   * Tests
#   * Linters
#   * Phonies
#
################################################################################

# Verify environment.sh
ifneq ($(PROJECT_NAME),myst-demo)
$(error Environment not configured. Run `source environment.sh`)
endif


################################################################################
# Settings
################################################################################


#-------------------------------------------------------------------------------
# General
#-------------------------------------------------------------------------------

# Bash
export SHELL := /bin/bash
.SHELLFLAGS := -e -u -o pipefail -c

# Colors - Supports colorized messages
COLOR_H1=\033[38;5;12m
COLOR_OK=\033[38;5;02m
COLOR_COMMENT=\033[38;5;08m
COLOR_RESET=\033[0m

# EXCLUDE_SRC - Source patterns to ignore

EXCLUDE_SRC := __pycache__ \
			   .egg-info \
			   .ipynb_checkpoints \
			   .venv
EXCLUDE_SRC := $(subst $(eval ) ,|,$(EXCLUDE_SRC))

# Commands
RM := rm -rf


#-------------------------------------------------------------------------------
# Output Dirs
#-------------------------------------------------------------------------------

OUTPUT_DIRS :=

BUILD_DIR := .build
OUTPUT_DIRS := $(OUTPUT_DIRS) $(BUILD_DIR)


#-------------------------------------------------------------------------------
# Environment
#-------------------------------------------------------------------------------

VENV_ROOT := .venv
VENV_SRC := pyproject.toml uv.lock
VENV := $(VENV_ROOT)/bin/activate


#-------------------------------------------------------------------------------
# Articles
#-------------------------------------------------------------------------------

ARTICLES_DIR := articles
ARTICLE_IDS := $(foreach dir,$(shell find $(ARTICLES_DIR) -mindepth 1 -maxdepth 1 -type d),$(notdir $(dir)))
ARTICLE_VENVS := $(foreach id,$(ARTICLE_IDS),$(ARTICLES_DIR)/$(id)/.venv/bin/activate)
ARTICLE_KERNEL_SPECS := $(foreach id,$(ARTICLE_IDS),$(JUPYTER_DATA_DIR)/kernels/$(id)/kernel.json)
ARTICLE_MANIFESTS := $(foreach id,$(ARTICLE_IDS),$(ARTICLES_DIR)/$(id)/myst.yml)
ARTICLE_BUILDS := $(foreach id,$(ARTICLE_IDS),$(ARTICLES_DIR)/$(id)/_build/html/index.html)
ARTICLES := $(ARTICLE_VENVS) $(ARTICLE_KERNEL_SPECS) $(ARTICLE_MANIFESTS) $(ARTICLE_BUILDS)

#-------------------------------------------------------------------------------
# Site
#-------------------------------------------------------------------------------

SITE_BUILD_DIR := $(BUILD_DIR)/site
ARTICLE_BUNDLES := $(foreach id,$(ARTICLE_IDS),$(SITE_BUILD_DIR)/articles/$(id)/index.html)
SITE := $(SITE_BUILD_DIR)/index.html


#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

PYTEST_OPTS ?= -n auto


#-------------------------------------------------------------------------------
# Linters
#-------------------------------------------------------------------------------

RUFF_CHECK_OPTS ?= --preview
RUFF_FORMAT_OPTS ?= --preview


#-------------------------------------------------------------------------------
# Phonies
#-------------------------------------------------------------------------------

PHONIES :=


################################################################################
# Targets
################################################################################

all: site
	@echo
	@echo -e "$(COLOR_H1)# $(PROJECT_NAME)$(COLOR_RESET)"
	@echo
	@echo -e "$(COLOR_COMMENT)# Activate VENV$(COLOR_RESET)"
	@echo -e "source $(VENV)"
	@echo
	@echo -e "$(COLOR_COMMENT)# Deactivate VENV$(COLOR_RESET)"
	@echo -e "deactivate"
	@echo


#-------------------------------------------------------------------------------
# Output Dirs
#-------------------------------------------------------------------------------

$(BUILD_DIR):
	mkdir -p $@


#-------------------------------------------------------------------------------
# Environment
#-------------------------------------------------------------------------------

$(VENV): $(VENV_SRC)
	uv sync
	touch $@

venv: $(VENV)
PHONIES := $(PHONIES) venv


#-------------------------------------------------------------------------------
# Articles
#-------------------------------------------------------------------------------

$(ARTICLES_DIR)/%/.venv/bin/activate: $(ARTICLES_DIR)/%/pyproject.toml
	uv sync --directory "$(ARTICLES_DIR)/$*"
	
	touch $@

$(JUPYTER_DATA_DIR)/kernels/%/kernel.json: $(ARTICLES_DIR)/%/.venv/bin/activate
	@echo
	@echo -e "$(COLOR_H1)# Configure kernel $*$(COLOR_RESET)"
	@echo

	source "$<" && python -m ipykernel install --user --name "$*" --display-name "$*"
	
	touch $@

$(ARTICLES_DIR)/%/myst.yml: $(ARTICLES_DIR)/%/article.yml | $(VENV)
	@echo
	@echo -e "$(COLOR_H1)# Configure article $*$(COLOR_RESET)"
	@echo

	source "$(VENV)" && python -m myst_demo.configure_myst $(ARTICLES_DIR)/$*
	
	touch $@

$(ARTICLES_DIR)/%/_build/html/index.html: $(ARTICLES_DIR)/%/* $(ARTICLES_DIR)/%/myst.yml $(JUPYTER_DATA_DIR)/kernels/%/kernel.json | $(VENV)
	@echo
	@echo -e "$(COLOR_H1)# Build article $*$(COLOR_RESET)"
	@echo

	source "$(VENV)" && \
	  cd "$(ARTICLES_DIR)/$*" && \
	  BASE_URL="/articles/$*" myst build --html --execute
	
	touch $@

articles: $(ARTICLES)
PHONIES := $(PHONIES) articles


#-------------------------------------------------------------------------------
# Site
#-------------------------------------------------------------------------------

$(SITE_BUILD_DIR)/articles/%/index.html: $(ARTICLES_DIR)/%/_build/html/index.html
	@echo
	@echo -e "$(COLOR_H1)# Bundle article $*$(COLOR_RESET)"
	@echo

	mkdir -p $(dir $@)
	
	rsync -av $(ARTICLES_DIR)/$*/_build/html/* $(dir $@)
	
	touch $@

$(SITE): $(ARTICLE_BUNDLES)
	@echo
	@echo -e "$(COLOR_H1)# Site$(COLOR_RESET)"
	@echo

	touch $@

site: $(SITE)

deploy: $(SITE)
	source "$(VENV)" && python -m http.server -d $(SITE_BUILD_DIR)

PHONIES := $(PHONIES) site deploy


#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

tests: $(VENV)
	@echo
	@echo -e "$(COLOR_H1)# Tests$(COLOR_RESET)"
	@echo

	source "$(VENV)" && pytest $(PYTEST_OPTS) tests

coverage: $(VENV)
	@echo
	@echo -e "$(COLOR_H1)# Coverage$(COLOR_RESET)"
	@echo
	mkdir -p $$(dirname $(BUILD_DIR)/coverage)
	source "$(VENV)" && pytest $(PYTEST_OPTS) --cov=xformers --cov-report=html:$(BUILD_DIR)/coverage tests

PHONIES := $(PHONIES) tests coverage


#-------------------------------------------------------------------------------
# Linters
#-------------------------------------------------------------------------------

lint-fmt: venv
	source "$(VENV)" && \
	  ruff format $(RUFF_FORMAT_OPTS) && \
	  ruff check --fix $(RUFF_CHECK_OPTS) && \
	  make lint-style

lint-style: venv
	source "$(VENV)" && \
	  ruff check $(RUFF_CHECK_OPTS) && \
	  ruff format --check $(RUFF_FORMAT_OPTS)

PHONIES := $(PHONIES) lint-fmt lint-style


#-------------------------------------------------------------------------------
# Clean
#-------------------------------------------------------------------------------

clean-cache:
	find . -type d -name "__pycache__" -exec rm -rf {} +

clean-venv:
	$(RM) "$(VENV_ROOT)"

clean-articles:
	for article_id in $(ARTICLE_IDS); do \
	    $(RM) "$(ARTICLES_DIR)/$${article_id}/myst.yml"; \
	    $(RM) "$(ARTICLES_DIR)/$${article_id}/_build"; \
	    $(RM) "$(ARTICLES_DIR)/$${article_id}/.venv"; \
	    $(RM) "$(JUPYTER_DATA_DIR)/kernels/$${article_id}"; \
	done

clean-site:
	$(RM) "$(SITE_BUILD_DIR)"

clean-build: clean-articles clean-site
	$(RM) "$(BUILD_DIR)"

clean: clean-cache clean-venv clean-articles clean-site clean-build 
PHONIES := $(PHONIES) clean-cache clean-venv clean-articles clean-site clean-build 

.PHONY: $(PHONIES)


