all: pep8 pylint tests build

build:
	python setup.py sdist

pep8:
	pep8 skipper tests

lint:
	mkdir -p reports
	PYLINTHOME=reports/ pylint skipper

tests:
	py.test --cov=skipper --cov-report=html --cov-report=term --cov-report=xml
install:
	pip install -U .

uninstall:
	pip uninstall -y strato-skipper

clean:
	rm -rf build dist *egg-info .tox tests/__pycache__ reports
	find -name *.pyc -delete

.PHONY: build pep8 pylint tests install uninstall clean
