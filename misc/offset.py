import sqlite3
from sys import argv
import numpy as np
import os
import glob

asset_ids = {
	'XGain': None,
	'YGain': None,
	'XOffset': None,
	'YOffset': None
}

asset_values = {}

for asset_id in asset_ids:
	asset_values[asset_id] = []

outerdir = argv[1]

subdirs = [name for name in os.listdir(outerdir) if os.path.isdir(os.path.join(outerdir, name))]

for subdir in subdirs:

	sql_files = glob.glob(os.path.join(outerdir, subdir, '*.sqlite'))

	file = os.path.join(outerdir, subdir, sql_files[0])

	conn = sqlite3.connect(file)
	curs = conn.cursor()

	for asset_id in asset_ids:
		curs.execute('SELECT assetid from propertylookup where name="{0}"'.format(asset_id))
		values = curs.fetchall()
		if len(values) != 1 or len(values[0]) != 1:
			raise ValueError('Expected one asset id associated with "{0}", but there were {1}'.format(asset_id, len(values)))
		asset_ids[asset_id] = values[0][0]

	for name, asset_id in asset_ids.iteritems():
		if asset_id is None:
			raise ValueError('Could not locate "{0}"'.format(asset_id))
		curs.execute('SELECT value FROM properties WHERE assetid={0}'.format(asset_id))
		values = curs.fetchall()
		transformed_values = [float(val[0]) for val in values]
		for val in transformed_values:
			asset_values[name].append(val)

	conn.close()

for name, asset in asset_values.iteritems():
	print('---')
	print(name)
	print(np.unique(asset))