
WORD_SIZE = 64

current_dir := ${shell pwd}

BUILD_CONTEXT = wacoq

COQBUILDDIR_REL := vendor/coq
COQBUILDDIR := $(current_dir)/_build/$(BUILD_CONTEXT)/$(COQBUILDDIR_REL)

export EMSDK = $(HOME)/var/ext/emsdk


.PHONY: default bootstrap setup deps wacoq coq-pkgs

default: wacoq

bootstrap: setup deps
	
setup:
	etc/setup.sh

deps: coq coq-serapi

wacoq:
	dune build @coq @wacoq

wacoq-only:
	dune build @wacoq

coq-pkgs:
	node dist/cli.js --nostdlib src/build/metadata/coq-pkgs.json


dist-npm:
	rm -rf staging
	parcel build -d staging/dist --no-source-maps src/index.html
	parcel build -d staging/dist --no-source-maps src/worker.ts
	cp package.json index.js staging/
	mkdir staging/bin && ln -s ../../bin/{icoq.bc,coq} staging/bin/
	mkdir staging/etc && cp etc/postinstall.js staging/etc
	tar zchf wacoq-bin.tar.gz -C staging \
		./package.json ./index.js ./dist ./bin ./etc

########################################################################
# Externals
########################################################################

.PHONY: coq

COQ_SRC = vendor/coq

COQ_BRANCH=V8.12.0
COQ_REPOS=https://github.com/coq/coq.git

COQ_PATCHES = timeout $(COQ_PATCHES|$(WORD_SIZE))

COQ_PATCHES|64 = coerce-32bit

$(COQ_SRC):
	git clone --depth=1 -b $(COQ_BRANCH) $(COQ_REPOS) $@
	cd $@ && git apply ${foreach p,$(COQ_PATCHES),$(current_dir)/etc/patches/$p.patch}

coq: $(COQ_SRC)
	eval `opam env --switch=$(BUILD_CONTEXT)` && \
	cd $(COQ_SRC) && ./configure -prefix $(current_dir) -native-compiler no -bytecode-compiler no -coqide no


.PHONY: coq-serapi

SERAPI_SRC = vendor/coq-serapi

coq-serapi:
	git submodule update $(SERAPI_SRC)