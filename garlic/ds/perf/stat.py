import json, re, sys, os, glob
from os import path

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, flush=True, **kwargs)

def process_run(tree, runPath):
	with open(".garlic/perf.csv", "r") as f:
		lines = [line.strip() for line in f.readlines()]

	perf_data = {}

	for line in lines:
		if len(line) == 0: continue
		if line[0] == '#': continue

		slices = line.split(',')
		if len(slices) != 7:
			print("error: mismatched columns")
			exit(1)

		name = slices[2].replace("-", "_")
		value = float(slices[0])

		perf_data[name] = value

	tree['perf'] = perf_data

	print(json.dumps(tree))

def process_result_tree(resultTree):

	eprint("processing resultTree: " + resultTree)

	os.chdir(resultTree)

	experiments = glob.glob(resultTree + "/*-experiment")

	for exp in glob.glob("*-experiment"):
		eprint("found experiment: " + exp)
		expPath = path.join(resultTree, exp)
		os.chdir(expPath)

		for unit in glob.glob("*-unit"):
			eprint("found unit: " + unit)
			unitPath = path.join(resultTree, exp, unit)
			os.chdir(unitPath)

			with open('garlic_config.json') as json_file:
				garlic_conf = json.load(json_file)

			tree = {"exp":exp, "unit":unit, "config":garlic_conf}

			for i in range(garlic_conf['loops']):
				run = str(i + 1)
				runPath = path.join(resultTree, exp, unit, run)
				if path.isdir(runPath) == False:
					eprint("missing run {}, aborting".format(run))
					exit(1)

				tree["run"] = run
				os.chdir(runPath)

				process_run(tree, runPath)


if len(sys.argv) != 2:
	eprint("usage: python {} <resultTree>".format(argv[0]))
	exit(1)

process_result_tree(sys.argv[1])
