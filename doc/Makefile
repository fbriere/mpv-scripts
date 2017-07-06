# Generate Markdown documentation from Lua script comments

SCRIPT := ../lua2md.pl

SCRIPTS_DIR := ../scripts

FILES := $(patsubst %.lua,%.md,$(notdir $(wildcard $(SCRIPTS_DIR)/*.lua)))

doc: $(FILES)

%.md: $(SCRIPTS_DIR)/%.lua $(SCRIPT)
	$(SCRIPT) $< > $@
