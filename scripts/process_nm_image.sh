#!/bin/bash

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

nm_img_file_orig=${DATA_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_reg=${REG_DIR}/${sub_id}_${type}.nii.gz

if [[ -f ${nm_img_file_orig} ]]; then
	echo -n "[Subject ${sub_id}] Copying corrected ${type} image ... "
	cp ${nm_img_file_orig} ${nm_img_file_reg}
	echo "done"

	echo -n "[Subject ${sub_id}] Rigidly registering ${type} image to T1w image ... "
	${MIRTK_BIN_DIR}/mirtk register ${t1w_img_file_reg} ${nm_img_file_reg} -parin ${PAR_FILE_RIG} -dofin ${DOFS_DIR}/${sub_id}_initial_rigid_transform.dof.gz -dofout ${DOFS_DIR}/${sub_id}_${type}_to_${sub_id}_T1w.dof.gz -v 0
	echo "done"

	echo -n "[Subject ${sub_id}] Computing transformed ${type} image ... "
	${MIRTK_BIN_DIR}/mirtk transform-image ${nm_img_file_reg} ${nm_img_file_reg} -target ${t1w_img_file_reg} -dofin ${DOFS_DIR}/${sub_id}_${type}_to_${sub_id}_T1w.dof.gz
	echo "done"
fi
