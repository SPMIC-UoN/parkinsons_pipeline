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

t1w_img_file=${REG_DIR}/${sub_id}_T1w.nii.gz

echo -n "[Subject ${sub_id}] Affinely registering T1w image to T1w MNI template ... "
mirtk register ${TEMPLATE_DIR}/brain_masked.nii.gz ${t1w_img_file} -parin ${PAR_FILE_AFF} -dofout ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -v 0
echo "done"

echo -n "[Subject ${sub_id}] Non-linearly registering T1w image to T1w MNI template ... "
mirtk register ${TEMPLATE_DIR}/brain_masked.nii.gz ${t1w_img_file} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
echo "done"

echo -n "[Subject ${sub_id}] Propagating T1w image to MNI space ... "
mirtk transform-image ${t1w_img_file} ${REG_MNI_DIR}/${sub_id}_T1w.nii.gz -target ${TEMPLATE_DIR}/brain_masked.nii.gz -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz
echo "done"