#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

PAR_FILE_AFF=${ROOT_DIR}/mirtk/mirtk-aff.cfg
PAR_FILE_FFD=${ROOT_DIR}/mirtk/mirtk-ffd.cfg

sub_id=$1

t1w_masked=`mktemp -p /tmp t1w_masked_XXXXXXXXX.nii.gz`

baseline_indicator=1
while [[ ! -f ${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do 
	let baseline_indicator=baseline_indicator+1
done

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz

if [[ "${sub_id:0-1}" == "${baseline_indicator}" ]]; then
	echo -n "[Subject ${sub_id}] Computing temporal brain-extracted T1w image for MNI registration ... "
	${ROBEXPATH}/runROBEX.sh ${t1w_img_file_reg} ${t1w_masked} > /dev/null
	echo "done"
	
	echo -n "[Subject ${sub_id}] Affinely registering temporal brain-extracted T1w image to T1w MNI template ... "
	${MIRTK_BIN_DIR}/mirtk register ${TEMPLATE_DIR}/brain_masked.nii.gz ${t1w_masked} -parin ${PAR_FILE_AFF} -dofout ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -v 0
	echo "done"

	echo -n "[Subject ${sub_id}] Affinely registering temporal brain-extracted T1w image to T1w MNI template (ROI only) ... "
	${MIRTK_BIN_DIR}/mirtk register ${TEMPLATE_DIR}/brain_masked.nii.gz ${t1w_masked} -parin ${PAR_FILE_AFF} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
	echo "done"

	echo -n "[Subject ${sub_id}] Non-linearly registering temporal brain-extracted T1w image to T1w MNI template (ROI only) ... "
	${MIRTK_BIN_DIR}/mirtk register ${TEMPLATE_DIR}/brain_masked.nii.gz ${t1w_masked} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
	echo "done"
else
	dof_file_baseline_aff=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_T1w_to_template_aff.dof.gz
	dof_file_baseline_ffd=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_T1w_to_template_ffd.dof.gz
	
	echo -n "[Subject ${sub_id}] Copying affine and non-linear transformations of baseline T1w image to T1w MNI template ... "
	cp ${dof_file_baseline_aff} ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz
	cp ${dof_file_baseline_ffd} ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz
	echo "done"
fi

echo -n "[Subject ${sub_id}] Propagating T1w image to MNI space ... "
${MIRTK_BIN_DIR}/mirtk transform-image ${t1w_img_file_reg} ${REG_MNI_DIR}/${sub_id}_T1w.nii.gz -target ${TEMPLATE_DIR}/brain_masked.nii.gz -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz -interp Linear
echo "done"

rm -f ${t1w_masked}