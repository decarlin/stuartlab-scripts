source  = $(wildcard */*.pl)
targets = tags

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

make:

back:
	mkdir -p Backup; \
	cp $(targets) Backup; \

back_clean:
	rm -rf Backup; \

tags: $(source)
	ctags */*.pl; \


