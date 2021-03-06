# Makefile for building Kerbulator

ifeq ($(OS),Windows_NT)
	KSPDIR  := C:/Program Files\ \(x86\)/Steam/SteamApps/common/Kerbal\ Space\ Program
	MANAGED := KSP_Data/Managed/
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S), Darwin)
		KSPDIR  := ${HOME}/Library/Application\ Support/Steam/SteamApps/common/Kerbal\ Space\ Program
		MANAGED := KSP.app/Contents/Data/Managed/
	endif
	ifeq ($(UNAME_S), Linux)
		KSPDIR  := ${HOME}/.local/share/Steam/SteamApps/common/Kerbal\ Space\ Program
		MANAGED := KSP_Data/Managed/
	endif
	ifeq ($(UNAME_S), FreeBSD)
		KSPDIR  := ${HOME}/KSP
		MANAGED := KSP_Data/Managed/
	endif
endif

SOURCEFILES := $(wildcard *.cs)

RESGEN2 := /usr/local/bin/resgen2
MCS    := /usr/local/bin/mcs
MONO    := /usr/local/bin/mono
GIT     := /usr/local/bin/git
TAR     := /usr/bin/tar
ZIP     := /usr/local/bin/zip
PDFLATEX   := /usr/local/bin/pdflatex

all: build

info:
	@echo "== Kerbulator Build Information =="
	@echo "  resgen2: ${RESGEN2}"
	@echo "  mcs:    ${MCS}"
	@echo "  git:     ${GIT}"
	@echo "  tar:     ${TAR}"
	@echo "  zip:     ${ZIP}"
	@echo "  KSP Data: ${KSPDIR}"
	@echo "  Source: ${SOURCEFILES}"
	@echo "==================================="

build: info
	mkdir -p build
	${MCS} -t:library -lib:${KSPDIR}/${MANAGED} \
		-r:Assembly-CSharp,Assembly-CSharp-firstpass,UnityEngine \
		-out:build/Kerbulator.dll \
		${SOURCEFILES}

doc: doc/space.tex
	cd doc; ${PDFLATEX} space; ${PDFLATEX} space

package: build 
	mkdir -p package/Kerbulator/Plugins
	mkdir -p package/Kerbulator/Textures
	cp build/Kerbulator.dll package/Kerbulator/Plugins/
	cp icons/*.png package/Kerbulator/Textures/
	cp README.md package/Kerbulator
	cp LICENSE.md package/Kerbulator
	mkdir -p package/Kerbulator/doc
	cp doc/*.mkd doc/*.png package/Kerbulator/doc
	cp doc/space.pdf package/Kerbulator/doc/math_notes.pdf


tar.gz: package
	cd package; ${TAR} zcf Kerbulator-$(shell ${GIT} describe --tags).tar.gz Kerbulator

zip: package
	cd package; ${ZIP} -9 -r Kerbulator-$(shell ${GIT} describe --tags).zip Kerbulator

clean:
	@echo "Cleaning up build and package directories..."
	rm -rf build/ package/

install: package
	mkdir -p ${KSPDIR}/GameData/
	cp -r package/Kerbulator ${KSPDIR}/GameData/

uninstall: info
	rm -rf ${KSPDIR}/GameData/Kerbulator

test: info
	${MCS} Kerbulator.cs Function.cs Variable.cs Tokenizer.cs
	${MONO} Kerbulator.exe tests/expressions.test

unity: 
	cp Kerbulator.cs KerbulatorGUI.cs Function.cs Variable.cs Tokenizer.cs ~/Calculator/Assets/Standard\ Assets/
	cp UnityGlue.cs ~/Calculator/Assets/
	cp icons/*.png ~/Calculator/Assets/Resources

release: zip tar.gz
	cp Kerbulator-$(shell ${GIT} describe --tags).zip ~/Dropbox/Public/Kerbulator
	cp Kerbulator-$(shell ${GIT} describe --tags).tar.gz ~/Dropbox/Public/Kerbulator

.PHONY : all info doc build package tar.gz zip clean install uninstall
