#!/usr/bin/env bash

# how to use?
echo "Usage:" $0 "<target dir>"
echo ""
echo "<target dir> : Full path to a target dir.  Should be different from the"
echo "               conda installation."
echo ""
[ $# -ne 1 ] && exit

# read target dir
target_dir=$1
mkdir -p ${target_dir}

# create tmp dir
[[ -n ${TMPDIR} ]] || TMPDIR=/tmp
tmp_dir=${TMPDIR}/`date +%s%N`_get_full_cartopy
mkdir ${tmp_dir}

# cd to tmp dir, get cartopy source, download data to repo data path
(
    cd ${tmp_dir}
    version=`python -c "import cartopy; print(cartopy.__version__)"`
    wget https://raw.githubusercontent.com/SciTools/cartopy/v${version}/tools/feature_download.py
    touch __init__.py

    cat <<EOF >> download_cartopy.py
#!/usr/bin/env python
import argparse
import os
import cartopy
from cartopy import config
from feature_download import FEATURE_DEFN_GROUPS, download_features


def main(target_dir):

    # add Antarctic ice shelves
    FEATURE_DEFN_GROUPS['physical'] = \
        FEATURE_DEFN_GROUPS['physical'] + \
        (('physical', 'antarctic_ice_shelves_polys', ('50m', '10m')),)

    config['pre_existing_data_dir'] = target_dir
    config['data_dir'] = target_dir
    config['repo_data_dir'] = target_dir
    download_features(
        ['cultural-extra', 'cultural', 'gshhs', 'physical'], dry_run=False)
    os.chdir(owd)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Download cartopy data for caching.')
    parser.add_argument('--output', '-o', required=True,
                        help='save datasets in the specified directory')
    args = parser.parse_args()
    main(args.output)
EOF

    python download_cartopy.py -o ${target_dir}
)

# clean up
rm -rf ${tmp_dir}
