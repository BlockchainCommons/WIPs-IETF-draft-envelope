# draft-mcnally-envelope 
# draft-mcnally-envelope-00
versioned:
	@mkdir -p $@
.INTERMEDIATE: versioned/draft-mcnally-envelope-00.md
versioned/draft-mcnally-envelope-00.md: | versioned
	git show "draft-mcnally-envelope-00:draft-mcnally-envelope.md" | sed -e 's/draft-mcnally-envelope-latest/draft-mcnally-envelope-00/g' >$@
.INTERMEDIATE: versioned/draft-mcnally-envelope-01.md
versioned/draft-mcnally-envelope-01.md: draft-mcnally-envelope.md | versioned
	sed -e 's/draft-mcnally-envelope-latest/draft-mcnally-envelope-01/g' $< >$@
diff-draft-mcnally-envelope.html: versioned/draft-mcnally-envelope-00.txt versioned/draft-mcnally-envelope-01.txt
	-$(iddiff) $^ > $@
