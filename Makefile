LIBDIR := lib

# The vendored lib/ is pinned to i-d-template from 2022-10-01, whose config.mk still
# points at https://datatracker.ietf.org/api/submit -- retired, now answering HTTP 410.
# The current endpoint is /api/submission. config.mk uses ?=, so setting it here wins.
DATATRACKER_UPLOAD_URL := https://datatracker.ietf.org/api/submission

include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
