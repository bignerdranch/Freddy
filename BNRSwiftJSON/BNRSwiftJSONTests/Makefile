all: download

download: Benchmark/AllSetsArray.json

Benchmark/AllSetsArray.json:
	curl -L http://mtgjson.com/json/AllSetsArray.json -o Benchmark/AllSetsArray.json

clean:
	-rm -f Benchmark/AllSetsArray.json

install:
