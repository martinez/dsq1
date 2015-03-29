
targets = esq-jack esq-synthui esq-banker esq-esqtest esq-fptest
default_targets = esq-jack esq-synthui
build_flags = -b release #-v

all: $(default_targets)

$(targets):
	dub build $(build_flags) $(subst -,:,$@)

clean:
	dub clean

.PHONY: all clean $(targets)
