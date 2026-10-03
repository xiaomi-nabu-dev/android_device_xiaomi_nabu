#!/usr/bin/env python3
"""Check the nabu/common split without compiling Android."""
from pathlib import Path
import argparse
import collections
import re
import subprocess
import concurrent.futures
import sys
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--copy-files', type=Path, help='Expanded PRODUCT_COPY_FILES from get_build_var')
parser.add_argument('--check-elf-dependencies', action='store_true',
                    help='Check that retained blobs do not need explicitly filtered libraries (requires --copy-files and readelf)')
args = parser.parse_args()
if args.check_elf_dependencies and not args.copy_files:
    parser.error('--check-elf-dependencies requires --copy-files')
device = Path(__file__).resolve().parents[1]
root = device.parents[2]
errors = []


def entries(path):
    result = []
    for line in path.read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        spec = line.lstrip('-').split('|')[0].split(';')[0]
        target = spec.split(':')[-1]
        result.append(target if target.startswith(('vendor/', 'odm/', 'product/', 'system/', 'system_ext/')) else 'system/' + target)
    return sorted(set(result))


common = root / 'device/xiaomi/sm8150-common'
seen = {}
for name, dt in [('nabu', device), ('sm8150-common', common)]:
    files = entries(dt / 'proprietary-files.txt')
    vendor = root / 'vendor/xiaomi' / name / 'proprietary'
    for target in files:
        actual = vendor / target
        legacy = vendor / target.removeprefix('system/')
        if not actual.is_file() and not legacy.is_file():
            errors.append(f'Missing {name} blob: {target}')
        if target in seen:
            errors.append(f'Duplicate blob destination: {target} ({seen[target]}, {name})')
        seen[target] = name
    print(f'{name}: {len(files)} blob entries')

kernel = root / 'kernel/xiaomi/sm8150'
for fragment in ['vendor/sm8150-perf_defconfig', 'vendor/xiaomi/sm8150-common.config', 'vendor/xiaomi/nabu.config']:
    if not (kernel / 'arch/arm64/configs' / fragment).is_file():
        errors.append(f'Missing kernel config: {fragment}')
for source in ['arch/arm64/boot/dts/qcom/nabu-sm8150-overlay.dts', 'drivers/input/touchscreen/xiaomi/nt36523/nt36xxx.c']:
    if not (kernel / source).is_file():
        errors.append(f'Missing nabu kernel support: {source}')

for xml in device.rglob('*.xml'):
    try:
        ET.parse(xml)
    except ET.ParseError as error:
        errors.append(f'{xml.relative_to(device)}: {error}')

if args.copy_files:
    copies = collections.defaultdict(set)
    for item in args.copy_files.read_text().split():
        parts = item.split(':')
        if len(parts) < 2:
            continue
        source, target = parts[:2]
        if not (root / source).is_file():
            errors.append(f'Missing copy source: {source}')
        copies[target].add(source)
    for target, sources in copies.items():
        if len(sources) > 1:
            if any(source.startswith(('device/xiaomi/', 'vendor/xiaomi/')) for source in sources):
                errors.append(f'Conflicting device PRODUCT_COPY_FILES: {target}: {sorted(sources)}')
            else:
                print(f'Upstream duplicate copy destination (first entry wins): {target}')
    print(f'PRODUCT_COPY_FILES: {len(copies)} destinations')
    if args.check_elf_dependencies:
        # Phone-only filtering must not remove a shared library used by a
        # retained HAL. Keep this scoped to explicit exclusions: framework
        # and source-built library dependencies are resolved by Soong.
        excluded = re.findall(
            r'\$\(TARGET_COPY_OUT_(VENDOR|SYSTEM_EXT)\)(/[^\s]+\.so)',
            (device / 'common-vendor.mk').read_text())
        filtered = {}
        for partition, suffix in excluded:
            target = partition.lower() + suffix
            if target not in copies:
                bits = 64 if '/lib64/' in target else 32
                filtered[(partition.lower(), bits, Path(target).name)] = target

        def check_needed(item):
            source, target = item
            path = root / source
            with path.open('rb') as stream:
                header = stream.read(5)
            if header[:4] != b'\x7fELF':
                return []
            bits = 64 if header[4] == 2 else 32
            result = subprocess.run(['readelf', '-d', str(path)],
                                    capture_output=True, text=True, check=True)
            missing = []
            for name in re.findall(r'\(NEEDED\).*\[(.*?)\]', result.stdout):
                dependency = filtered.get((target.split('/')[0], bits, name))
                if dependency:
                    missing.append(f'Filtered ELF dependency: {target} needs {dependency}')
            return missing

        inputs = [(source, target) for target, sources in copies.items()
                  for source in sources if source.startswith('vendor/xiaomi/')
                  and (root / source).is_file()]
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            for result in executor.map(check_needed, inputs):
                errors.extend(result)
        print(f'Filtered ELF dependency checks: {len(inputs)} retained blob copies')


for error in errors:
    print('ERROR:', error, file=sys.stderr)
if errors:
    sys.exit(1)
print('Tree checks passed. Runtime behavior still requires a built image and device testing.')
