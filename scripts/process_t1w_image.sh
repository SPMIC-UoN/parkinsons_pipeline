#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

PAR_FILE_RIG_LARGE=${ROOT_DIR}/mirtk/mirtk-rig-large.cfg

sub_id=$1

baseline_indicator=1
while [[ ! -f ${DATA_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do
	let baseline_indicator=baseline_indicator+1
done

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz
t1w_img_file_reg_baseline=${REG_DIR}/${sub_id::-2}-${baseline_indicator}_T1w.nii.gz

echo -n "[Subject ${sub_id}] Copying original T1w image ... "
cp ${DATA_DIR}/${sub_id}_T1w.nii.gz ${t1w_img_file_reg}
echo "done"

echo -n "[Subject ${sub_id}] Running N4 on T1w image ... "
${ANTSPATH}/N4BiasFieldCorrection -i ${t1w_img_file_reg} -o ${t1w_img_file_reg} -d 3 -s 3 > /dev/null
echo "done"

if [[ "${sub_id:0-1}" != "${baseline_indicator}" ]]; then

	echo -n "[Subject ${sub_id}] Rigidly registering T1w image to baseline T1w image ... "
	${MIRTK_BIN_DIR}/mirtk register ${t1w_img_file_reg_baseline} ${t1w_img_file_reg} -parin ${PAR_FILE_RIG_LARGE} -dofout ${DOFS_DIR}/${sub_id}_initial_rigid_transform.dof.gz -v 0
	echo "done"
	
	echo -n "[Subject ${sub_id}] Transforming T1w image to baseline T1w image space ... "
	${MIRTK_BIN_DIR}/mirtk transform-image ${t1w_img_file_reg} ${t1w_img_file_reg} -dofin ${DOFS_DIR}/${sub_id}_initial_rigid_transform.dof.gz -target ${t1w_img_file_reg_baseline} -interp BSpline
	echo "done"
else
	${MIRTK_BIN_DIR}/mirtk init-dof ${DOFS_DIR}/${sub_id}_initial_rigid_transform.dof.gz -rigid
fi
