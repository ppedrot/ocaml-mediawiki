# $Id: Makefile

OCAMLLIB=$(shell ocamlc -where)

OCAMLYACC=ocamlyacc
OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
OCAMLDEP=ocamlfind ocamldep
OCAMLMKLIB=ocamlfind ocamlmklib
OCAMLDOC=ocamlfind ocamldoc

INCLUDES=-I tools -I api -I wikisource -I script
INCLUDE_FOLDERS=tools api wikisource script

SYNTAX=camlp4o
PACKAGES=threads batteries expat pcre netstring netclient netcgi2 zip netzip

# LIB=zip.cma expat.cma unix.cma pcre.cma equeue.cma netsys.cma netstring.cma netcgi.cma netclient.cma

OCAMLFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLOPTFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLYACCFLAGS=
OCAMLDEPFLAGS=$(INCLUDES)
OCAMLMKLIBFLAGS=$(INCLUDES)
OCAMLDOCFLAGS=$(INCLUDES) -hide Datatypes,WTypes -thread $(addprefix -package , $(PACKAGES))

# SOURCE = tools/cookie.cmo tools/xml.cmo
# API_EXPORTED = api/call.cmo api/datatypes.cmi api/utils.cmo api/make.cmo api/options.cmo api/site.cmo api/login.cmo api/prop.cmo api/enum.cmo api/edit.cmo api/misc.cmo api/meta.cmo

INTERFACE=tools/xml.mli api/call.mli api/enum.mli api/wTypes.mli api/datatypes.mli api/utils.mli api/site.mli api/login.mli api/wProp.mli api/wList.mli api/wEdit.mli api/wMisc.mli api/wMeta.mli wikisource/proofread.mli script/script.mli

OBJS=tools/cookie.cmo tools/multipart.cmo tools/xml.cmo api/call.cmo api/enum.cmo api/wTypes.cmo api/datatypes.cmi api/utils.cmo api/make.cmo api/options.cmo api/site.cmo api/login.cmo api/wProp.cmo api/wList.cmo api/wEdit.cmo api/wMisc.cmo api/wMeta.cmo wikisource/proofread.cmo script/script.cmo

# TOOLS=wikisource/proofread.cmo
# OPTTOOLS=$(patsubst %.cmo,%.cmx, $(TOOLS))

OPTOBJS=$(patsubst %.cmo,%.cmx, $(OBJS))

CMOS=$(filter %.cmo,$(OBJS))
CMXS=$(patsubst %.cmo,%.cmx, $(CMOS))


INSTALLED=META mediawiki.cmi mediawiki.cma mediawiki.cmxa mediawiki.a

# OSOURCE=$(patsubst %.cmo,%.cmx,$(SOURCE))
# OAPI_EXPORTED=$(patsubst %.cmo,%.cmx, $(API_EXPORTED))

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) $(OCAMLFLAGS) -for-pack Mediawiki -c $<

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -for-pack Mediawiki -c $<

all: dep runlib optlib

run: $(OBJS) $(TOOLS)

runlib: run mediawiki.cmi
	$(OCAMLC) $(OCAMLFLAGS) -pack $(OBJS) -o mediawiki.cmo
	$(OCAMLC) $(OCAMLFLAGS) -a mediawiki.cmo -o mediawiki.cma

opt: $(OPTOBJS) $(OPTTOOLS)

optlib: opt mediawiki.cmi 
	$(OCAMLOPT) $(OCAMLFLAGS) -pack $(OPTOBJS) -o mediawiki.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -a $(CMXS) -o mediawiki.cmxa

dep:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) $(shell find $(INCLUDE_FOLDERS) -name "*.ml") $(shell find . -name "*.mli") > .depend

yacc:

clean:
	rm -f mediawiki.mli mediawiki.cmi mediawiki.cma mediawiki.cmxa mediawiki.a
	rm -rf $(shell find . -name "*.cm[aoix]*") $(shell find . -name "*.o")
	rm -rf doc

doc: $(OBJS)
	mkdir -p doc
	$(OCAMLDOC) $(OCAMLDOCFLAGS) -d doc -html $(INTERFACE)

install:
	mkdir -p $(OCAMLLIB)/mediawiki
	cp  $(INSTALLED) $(OCAMLLIB)/mediawiki

mediawiki.mli: $(INTERFACE)
	ocaml make_interface.ml $(INTERFACE)

-include .depend 
