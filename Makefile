install:
	bundle install

run:
	bundle exec rake run

build:
	bundle exec rake build

publish:
	bundle exec rake publish

.PHONY: install run build publish
