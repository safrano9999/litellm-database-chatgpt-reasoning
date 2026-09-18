#!/usr/bin/env python3
"""Reject source/metadata drift before building the pinned backport."""
import hashlib
import json
from pathlib import Path

root=Path.cwd()
m=json.loads((root/'patches/manifest.json').read_text())
for name,expected in [(m['runtime_patch'],m['runtime_patch_sha256']),
                      (m['upstream_diff'],m['patch_sha256'])]+[
                          ('tests/'+name,value) for name,value in m['test_sha256'].items()]:
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==expected,'Source hash changed: '+name
recipe=(root/'.github/scripts/Containerfile').read_text()
# The updater retains the release tag alongside the same immutable digest.
allowed_bases = {'FROM ' + m['base_image'] + suffix + '@' + m['base_digest']
                 for suffix in ['', ':v' + m['version']]}
from_lines = [line.strip() for line in recipe.splitlines() if line.lstrip().startswith('FROM ')]
assert len(from_lines) == 1 and from_lines[0] in allowed_bases, 'Base differs from verified manifest'
assert m['runtime_patch'].removeprefix('patches/') in recipe
assert m['base_checksums'].removeprefix('patches/') in recipe
print('Patch, upstream identity, tests and pinned base verified')
