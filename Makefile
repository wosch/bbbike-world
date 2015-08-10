
TARGETS=jsb perltidy \
	git-push git-pull git-diff git-fetch \
	help update-files \
	check check-w check-full \


help-local:
	@echo "make ${TARGETS}"

${TARGETS}:
	${MAKE} -C ../ $@



