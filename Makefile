define HELPTEXT
`make validate`            - Schema validation on examples.
`make transform`           - XSLT transformation on examples.
`make validate-transform`  - Schema validation on XSLT results.
`make` or `make all`       - All of the above.
`make clean`               - Remove generated files.

Requirements (see shell.nix):
  - curl                 - for https-downloaded schema files
  - vnu                  - for XHTML validation (https://validator.github.io/validator/)
  - xmllint, xmlcatalog  - for XSD validation   (part of libxml2)
  - xsltproc             - for XSLT 1.0 processing (part of libxslt)
endef

SCHEMA   := breezipe.xsd

XSL_MAIN := breezipe-xhtml.xsl
XSL_ALL  := $(wildcard *.xsl)
XML_SRC  := $(wildcard examples/*.xml)

XHTML11_DEPLIST   := xhtml11 xhtml11-model-1 xhtml-datatypes-1 xhtml11-modules-1 xhtml-framework-1 xhtml-attribs-1 xhtml-text-1 xhtml-blkphras-1 xhtml-blkstruct-1 xhtml-inlphras-1 xhtml-inlstruct-1 xhtml-hypertext-1.xsd xhtml-hypertext-1 xhtml-list-1 xhtml-struct-1 xhtml-edit-1 xhtml-bdo-1 xhtml-pres-1 xhtml-blkpres-1 xhtml-inlpres-1 xhtml-link-1 xhtml-meta-1 xhtml-base-1 xhtml-script-1 xhtml-style-1 xhtml-inlstyle-1 xhtml-image-1 xhtml-csismap-1 xhtml-ssismap-1 xhtml-object-1 xhtml-param-1 xhtml-table-1 xhtml-form-1 xhtml-ruby-1 xhtml-events-1 xhtml-target-1
XHTML11_DEP_FILES := $(patsubst %,xsd/%.xsd,$(XHTML11_DEPLIST))

CSS := recipe.css
JS  := highlight-crossrefd.js

CURL = curl --silent --show-error --fail --create-dirs

.PHONY: all help validate transform validate-transform clean clean-generated clean-catalog

all: validate transform validate-transform

export HELPTEXT
help:
	@echo "$$HELPTEXT"


# Validation ---------------------------------------------------------
# Each XML file gets a “.valid” stamp file when validation succeeds.
# The stamp is touched only on success, so a later `make validate`
# will skip files that are already known to be valid.

xsd/xml.xsd:
	@echo "Downloading $@"
	@$(CURL) --location http://www.w3.org/2001/xml.xsd --output "$@"

$(XHTML11_DEP_FILES):
	@echo "Downloading $@"
	@$(CURL) --location http://www.w3.org/MarkUp/SCHEMA/$(notdir $@) --output "$@"
# Patch the XSD to get all dependencies through a single public URI
	@echo "Patching $@"
	@sed -i -E 's|(schemaLocation=")(xhtml[^"]+\.xsd)"|\1http://www.w3.org/MarkUp/SCHEMA/\2"|g' "$@"


catalog.xml: xsd/xml.xsd $(XHTML11_DEP_FILES)
	@echo "Adding the XSD dependencies to $@"
	xmlcatalog --noout --add system http://www.w3.org/2001/xml.xsd xsd/xml.xsd --create "$@"
	for DEP in $(XHTML11_DEPLIST); do \
		xmlcatalog --noout --add system http://www.w3.org/MarkUp/SCHEMA/$$DEP.xsd xsd/$$DEP.xsd "$@"; \
	done

validate: $(XML_SRC:.xml=.valid)

%.valid: %.xml $(SCHEMA) | catalog.xml
	@echo "Validating $<"
	XML_CATALOG_FILES=catalog.xml xmllint --noout --nonet --schema $(SCHEMA) "$<" && touch $@


# XSLT transformation ------------------------------------------------

transform: $(XML_SRC:.xml=.xhtml)

%.xhtml: %.xml $(XSL_ALL)
	@echo "Transforming $< to $@"
	xsltproc \
		--stringparam css \
		$(shell realpath --relative-to $$(dirname $@) $(CSS)) \
		--stringparam js \
		$(shell realpath --relative-to $$(dirname $@) $(JS)) \
		-o $@ $(XSL_MAIN) $<

# Validation of the XSLT products ------------------------------------

validate-transform: $(XML_SRC:.xml=.xhtml-valid)

%.xhtml-valid: %.xhtml
	@echo "Validating $<"
	vnu $< && touch $@

# Cleanup ------------------------------------------------------------

clean: clean-generated clean-catalog

clean-generated:
	$(RM) $(XML_SRC:.xml=.valid) $(XML_SRC:.xml=.xhtml) $(XML_SRC:.xml=.xhtml-valid)

clean-catalog:
	$(RM) xsd/xml.xsd $(XHTML11_DEP_FILES) catalog.xml
