#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

sub_id=$1
type=$2

nm_img_file=${REG_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_corrected=${REG_DIR}/${sub_id}_${type}-corrected.nii.gz
synth_img_file=`echo ${nm_img_file} | sed s/${type}/synth-${type}/g`

if [[ -f ${nm_img_file} ]]; then

	echo -n "[Subject ${sub_id}] Propagating ${type} image to MNI space ... "
	mirtk transform-image ${nm_img_file} ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -target ${TEMPLATE_DIR}/synth_template.nii.gz -dofin ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
	echo "done"
	
	echo -n "[Subject ${sub_id}] Propagating corrected ${type} image to MNI space ... "
	mirtk transform-image ${nm_img_file_corrected} ${REG_MNI_DIR}/${sub_id}_${type}-corrected.nii.gz -target ${TEMPLATE_DIR}/synth_template.nii.gz -dofin ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
	echo "done"

	echo -n "[Subject ${sub_id}] Propagating synthetic ${type} image to MNI space ... "
	mirtk transform-image ${synth_img_file} ${REG_MNI_DIR}/${sub_id}_synth-${type}.nii.gz -target ${TEMPLATE_DIR}/synth_template.nii.gz -dofin ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
	echo "done"
fi
