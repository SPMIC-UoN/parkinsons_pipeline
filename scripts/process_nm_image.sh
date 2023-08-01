#!/bin/bash

MATLAB_BIN_DIR=/usr/local/MATLAB/R2018a/bin/

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

PAR_FILE_RIG=${ROOT_DIR}/mirtk/mirtk-rig.cfg

sub_id=$1
type=$2

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz
t1w_img_file_mask=${REG_DIR}/${sub_id}_brain_mask.nii.gz

nm_img_file_orig=${DATA_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_orig_corr=${DATA_DIR}/${sub_id}_${type}_corrected.nii.gz
nm_img_file_reg=${REG_DIR}/${sub_id}_${type}.nii.gz

if [[ -f ${nm_img_file_orig} ]]; then
	echo -n "[Subject ${sub_id}] Correcting interleaving artefacts on ${type} image ... "
	${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath(genpath('${SELF_DIR}')); create_corrected_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
	echo "done"
	
	echo -n "[Subject ${sub_id}] Copying corrected ${type} image ... "
	cp ${nm_img_file_orig_corr} ${nm_img_file_reg}
	echo "done"

	echo -n "[Subject ${sub_id}] Rigidly registering ${type} image to T1w image ... "
	mirtk register ${t1w_img_file_reg} ${nm_img_file_reg} -parin ${PAR_FILE_RIG} -dofin ${DOFS_DIR}/${sub_id}_initial_rigid_transform.dof.gz -dofout ${DOFS_DIR}/${sub_id}_${type}_to_${sub_id}_T1w.dof.gz -v 0
	echo "done"

	echo -n "[Subject ${sub_id}] Computing transformed ${type} image ... "
	mirtk transform-image ${nm_img_file_reg} ${nm_img_file_reg} -target ${t1w_img_file_reg} -dofin ${DOFS_DIR}/${sub_id}_${type}_to_${sub_id}_T1w.dof.gz
	echo "done"

	echo -n "[Subject ${sub_id}] Masking ${type} image ... "
	mirtk calculate ${nm_img_file_reg} -mask ${t1w_img_file_mask} -pad 0 -o ${nm_img_file_reg}
	echo "done"
fi
