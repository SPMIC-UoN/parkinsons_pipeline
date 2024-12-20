#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

PAR_FILE_AFF=${ROOT_DIR}/mirtk/mirtk-aff.cfg
PAR_FILE_FFD=${ROOT_DIR}/mirtk/mirtk-ffd.cfg

labels=('background' 'brainstem' 'r_sn' 'l_sn')

sub_id=$1
type=$2

baseline_indicator=1
while [[ ! -f ${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do 
	let baseline_indicator=baseline_indicator+1
done

nm_img_file=${REG_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_baseline=${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_${type}.nii.gz

synth_img_file=`echo ${nm_img_file} | sed s/${type}/synth-${type}/g`

if [[ -f ${nm_img_file} ]]; then
	if [[ "${sub_id:0-1}" == "${baseline_indicator}" ]] || [[ ! -f ${nm_img_file_baseline} ]]; then
		for index in {0..3}; do
			label=${labels[$index]}
			
			echo -n "[(Initial) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
			${MIRTK_BIN_DIR}/mirtk transform-image ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -target ${nm_img_file} -dofin_i ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz
			echo "done"
		done

		echo -n "[(Initial) Subject ${sub_id}] Computing initial synthetic ${type} image ... "
		${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath('${MATLAB_NIFTI_LIB}'); addpath('${MATLAB_CODE_DIR}'); create_synth_image('${sub_id}', '${type}'); exit" > /dev/null
		echo "done"

		echo -n "[(Initial) Subject ${sub_id}] Non-linearly registering synthetic ${type} image to MNI space (ROI only) ... "
		${MIRTK_BIN_DIR}/mirtk register ${TEMPLATE_DIR}/synth_template.nii.gz ${synth_img_file} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
		echo "done"

		for index in {0..3}; do
			label=${labels[$index]}
			
			echo -n "[(Refined) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
			${MIRTK_BIN_DIR}/mirtk transform-image ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -target ${nm_img_file} -dofin_i ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
			echo "done"
		done

		echo -n "[(Refined) Subject ${sub_id}] Computing refined synthetic ${type} image ... "
		${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath('${MATLAB_NIFTI_LIB}'); addpath('${MATLAB_CODE_DIR}'); create_synth_image('${sub_id}', '${type}'); exit" > /dev/null
		echo "done"

		echo -n "[(Refined) Subject ${sub_id}] Non-linearly registering synthetic ${type} image to MNI space (ROI only) ... "
		${MIRTK_BIN_DIR}/mirtk register ${TEMPLATE_DIR}/synth_template.nii.gz ${synth_img_file} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
		echo "done"
	else
		dof_file_baseline_ffd=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_synth-${type}_to_template_ffd.dof.gz
		
		echo -n "[Subject ${sub_id}] Copying non-linear transformation of baseline synthetic ${type} image to synthetic MNI template ... "
		cp ${dof_file_baseline_ffd} ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
		echo "done"
	fi
	
	for index in {0..3}; do
		label=${labels[$index]}
		
		echo -n "[(Final) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
		${MIRTK_BIN_DIR}/mirtk transform-image ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -target ${nm_img_file} -dofin_i ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
		echo "done"
	done

	echo -n "[(Final) Subject ${sub_id}] Computing final synthetic ${type} image ... "
	${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath('${MATLAB_NIFTI_LIB}'); addpath('${MATLAB_CODE_DIR}'); create_synth_image('${sub_id}', '${type}'); exit" > /dev/null
	echo "done"
fi
