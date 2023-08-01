#!/bin/bash

MATLAB_BIN_DIR=/usr/local/MATLAB/R2018a/bin/

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

PAR_FILE_AFF=${ROOT_DIR}/mirtk/mirtk-aff.cfg
PAR_FILE_FFD=${ROOT_DIR}/mirtk/mirtk-ffd.cfg

labels=('background' 'r_sn' 'l_sn' 'r_peduncle' 'l_peduncle' 'r_midbrain' 'l_midbrain')

tmp_dir=`mktemp -d -p /tmp create_synth_image_XXXXXXXXX`

sub_id=$1
type=$2

nm_img_file=${REG_DIR}/${sub_id}_${type}.nii.gz
synth_img_file=`echo ${nm_img_file} | sed s/${type}/synth-${type}/g`

if [[ -f ${nm_img_file} ]]; then

	for index in {0..6}; do
		label=${labels[$index]}
		
		echo -n "[(Initial) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
		mirtk transform-image ${TEMPLATE_DIR}/${label}_weight_map.nii.gz ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -target ${nm_img_file} -dofin_i ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.dof.gz
		echo "done"
	done

	echo -n "[(Initial) Subject ${sub_id}] Computing initial synthetic ${type} image ... "
	${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath(genpath('${SELF_DIR}')); create_synth_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
	echo "done"

	echo -n "[(Initial) Subject ${sub_id}] Non-linearly registering synthetic ${type} image to MNI space ... "
	mirtk register ${TEMPLATE_DIR}/synth_template.nii.gz ${synth_img_file} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
	echo "done"
	
	echo -n "[(Initial) Subject ${sub_id}] Making backup of current synthetic ${type} image ... "
	cp ${synth_img_file} ${tmp_dir}/synth_image_prev.nii.gz
	echo "done"

	for iter in {1..9}; do
		for index in {0..6}; do
			label=${labels[$index]}
			
			echo -n "[(Iteration ${iter}) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
			mirtk transform-image ${TEMPLATE_DIR}/${label}_weight_map.nii.gz ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -target ${nm_img_file} -dofin_i ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz
			echo "done"
		done

		echo -n "[(Iteration ${iter}) Subject ${sub_id}] Computing refined synthetic ${type} image ... "
		${MATLAB_BIN_DIR}/matlab -nodesktop -nosplash -r "addpath(genpath('${SELF_DIR}')); create_synth_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
		echo "done"

		echo -n "[(Iteration ${iter}) Subject ${sub_id}] Non-linearly registering synthetic ${type} image to MNI space ... "
		mirtk register ${TEMPLATE_DIR}/synth_template.nii.gz ${synth_img_file} -parin ${PAR_FILE_FFD} -dofin ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.dof.gz -dofout ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.dof.gz -mask ${TEMPLATE_DIR}/ROI_mask.nii.gz -v 0
		echo "done"
		
		diff_thresh=`mirtk calculate ${synth_img_file} -mul 0.005 -range | awk -F ' ' '{print $3}'`
		diff=`mirtk calculate ${synth_img_file} -sub ${tmp_dir}/synth_image_prev.nii.gz -abs -mask ${REG_DIR}/${sub_id}_brain_mask.nii.gz -pad 0 -mean | awk -F ' ' '{print $3}'`
		diff_test=`echo "${diff} < ${diff_thresh}" | bc -l`

		if [ ${diff_test} -eq 1 ]; then
			echo "[(Iteration ${iter}) Subject ${sub_id}] Synthetic image creation converged (difference [${diff}] - difference threshold [${diff_thresh}])"
			break
		fi
		
		echo -n "[(Iteration ${iter}) Subject ${sub_id}] Making backup of current synthetic ${type} image ... "
		cp ${synth_img_file} ${tmp_dir}/synth_image_prev.nii.gz
		echo "done"
	done
	
	echo -n "[Subject ${sub_id}] Cleaning temporary data ... "
	rm -rf ${tmp_dir}
	echo "done"
fi
