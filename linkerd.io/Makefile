check:
	htmltest

lint:
	markdownlint -c .markdownlint.yaml ./content

production-build:
	hugo --minify

preview-build:
	hugo \
	--baseURL $(DEPLOY_PRIME_URL) \
	--buildDrafts \
	--buildFuture \
	--minify