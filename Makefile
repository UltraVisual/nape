SWFV = 11

FILES = $(shell find cx-src -type f -name "*.cx" -print)

local: $(FILES)
	mkdir -p bin
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyCppMain.cx -x DummyJSMain # cpp only
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 600:600:60:333333 -D haxe3 \
		-D NAPE_DEBUG --no-inline -debug -D NAPE_LOG
#		-D NAPE_RELEASE_BUILD
	debugfp bin/nape.swf

js: $(FILES)
	mkdir -p bin
	rm -rf src
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyMemory.cx -x DummyNapeMain.cx -x DummyCppMain.cx
	haxe -cp src -main DummyJSMain -js bin/nape.js --times \
        -D haxe3 --js-modern --dce full


cpp: $(FILES)
	mkdir -p bin
	rm -rf src
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyMemory.cx -x DummyNapeMain.cx -x DummyJSMain # flash only
	haxe -cp src -main DummyCppMain -cpp cpp --times \
		--remap flash:nme -lib nme \
		-D NAPE_RELEASE_BUILD
#		-D NAPE_DEBUG --no-inline -debug
	./cpp/DummyCppMain

#------------------------------------------------------------------------------------

clean:
	rm -rf __chxdoctmp
	rm -rf externs
	rm -rf bin
	rm -rf src
	rm -f nape.xml
	rm -f nape.xml.swf

#------------------------------------------------------------------------------------

docs: pre_compile
	haxe -cp src -xml nape.xml --macro "include('nape')" -D NAPE_RELEASE_BUILD -swf nape.xml.swf -swf-version 10.1 \
         -cp ../nape-hacks/src --macro "include('nape.hacks')" \
         -cp ../nape-symbolic/src --macro "include('nape.symbolic')" -lib Parsex -D haxe3
	./chxdoc/chxdoc -o ../www.napephys.com/docs --templateDir=chxdoc/src/templates/default \
		-f zpp_nape -f haxe -f flash --ignoreRoot=true -f com \
		--title="Nape Physics Library" nape.xml

#------------------------------------------------------------------------------------

externs: debugs
	rm -rf externs
	flib --externs bin/haxe_debug_nape.swf --include nape --include zpp_nape
	cp src/nape/TArray.hx externs/nape/

#------------------------------------------------------------------------------------

DUMMYS = $(shell find cx-src -type f -name "Dummy*" -print | sed 's/^/-x /')
pre_compile:
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times $(DUMMYS)

SWC_FLAGS = -cp src --dce full --macro "include('nape')" --macro "include('zpp_nape')" -D flib -D nape_swc

DEBUG_FLAGS = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_DEBUG
DEV_FLAGS  = $(SWC_FLAGS)
RELEASE_FLAGS= $(SWC_FLAGS) -D NAPE_RELEASE_BUILD

#------------------------------------------------------------------------------------

.PHONY: demos
demos:
	./buildlib
	$(MAKE) releases
	cp bin/release_nape.swc ../www.napephys.com/nape-release.swc
	$(MAKE) docs

releases: pre_compile
	mkdir -p bin/
	haxe -swf bin/release_nape.swc $(RELEASE_FLAGS) -swf-version $(SWFV)
	flib bin/release_nape.swc
	unzip bin/release_nape.swc -x catalog.xml
	mv library.swf bin/haxe_release_nape.swf
	du -h bin/release_nape.swc

developments: pre_compile
	mkdir -p bin/
	haxe -swf bin/development_nape.swc $(DEV_FLAGS) -swf-version $(SWFV)
	flib bin/development_nape.swc
	unzip bin/development_nape.swc -x catalog.xml
	mv library.swf bin/haxe_development_nape.swf
	du -h bin/development_nape.swc

debugs: pre_compile
	mkdir -p bin/
	haxe -swf bin/debug_nape.swc $(DEBUG_FLAGS) -swf-version $(SWFV)
	flib bin/debug_nape.swc
	unzip bin/debug_nape.swc -x catalog.xml
	mv library.swf bin/haxe_debug_nape.swf
	du -h bin/debug_nape.swc
