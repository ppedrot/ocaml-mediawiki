# $Id: Makefile

OCAMLYACC=ocamlyacc
OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
OCAMLDEP=ocamlfind ocamldep

INCLUDES=-I tools -I api

SYNTAX=camlp4o
PACKAGES=threads expat pcre netstring netclient netcgi2 zip

LIB=zip.cma expat.cma unix.cma pcre.cma equeue.cma netsys.cma netstring.cma netcgi.cma netclient.cma

OCAMLFLAGS=$(INCLUDES) -thread -g -w s $(addprefix -package , $(PACKAGES)) $(LIB)
OCAMLOPTFLAGS=$(INCLUDES) -w s $(addprefix -package , $(PACKAGES))
OCAMLYACCFLAGS=
OCAMLDEPFLAGS=$(INCLUDES)

API_FILES=call.mli call.ml site.mli site.ml datatypes.mli utils.mli utils.ml \
options.mli options.ml login.mli login.ml prop.mli prop.ml enum.mli enum.ml edit.mli edit.ml wikipedia.ml

TOOLS_FILES=netgzip.mli netgzip.ml xml.mli xml.ml cookie.mli cookie.ml

FILES=$(addprefix tools/, $(TOOLS_FILES)) $(addprefix api/, $(API_FILES))

MLFILES=$(filter %.ml, $(FILES))
MLIFILES=$(filter %.mli, $(FILES))

BYTEFILES=$(addsuffix .cmo, $(basename $(MLFILES)))
INTERFACES=$(addsuffix .cmi, $(basename $(MLIFILES)))
OPTFILES=$(addsuffix .cmx, $(basename $(MLFILES)))

PROG=wikipedia

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<


all: dep $(BYTEFILES)

$(PROG): all
	$(OCAMLC) $(OCAMLFLAGS) $(BYTEFILES) -o $(PROG) api/wikipedia.ml

opt: dep wikipedia.cmx

dep:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) $(MLFILES) $(MLIFILES) > .depend

yacc:

clean:
	rm -rf *.cm[oix]

include .depend 
