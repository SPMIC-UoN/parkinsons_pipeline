#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

# Required folders
SCRIPTS_DIR=${SELF_DIR}/scripts
DATA_DIR=${SELF_DIR}/Original

# File structure folders
REG_DIR=${SELF_DIR}/Registered
DOFS_DIR=${REG_DIR}/dofs
MNI_SPACE_DIR=${REG_DIR}/MNI_space
MPRAGE_SPACE_DIR=${REG_DIR}/MPRAGE_space

if [[ ! -d ${DATA_DIR} ]]; then
	echo "No original data folder found!"
	exit 1
fi

# Create necessary structure directories if they do not exist
mkdir -p ${DOFS_DIR}
mkdir -p ${MNI_SPACE_DIR}
mkdir -p ${MPRAGE_SPACE_DIR}

# Run pipeline for all subjects with T1w and NM/MAGiC sequences
for img_file in ${DATA_DIR}/sub-*_T1w.nii.gz; do
	sub_id=`basename ${img_file} | sed s/_T1w.nii.gz//g`
	flag_file=`echo ${img_file} | sed s/_T1w.nii.gz/.processed/g`

	if [[ ! -f ${flag_file} ]]; then
		${SCRIPTS_DIR}/process_t1w_image.sh ${sub_id}
		${SCRIPTS_DIR}/t1w_to_mni_registration.sh ${sub_id}
		
		${SCRIPTS_DIR}/process_nm_image.sh ${sub_id} NM
		${SCRIPTS_DIR}/process_nm_image.sh ${sub_id} MAGiC-PD
		
		${SCRIPTS_DIR}/create_synth_image.sh ${sub_id} NM
		${SCRIPTS_DIR}/create_synth_image.sh ${sub_id} MAGiC-PD
		
		${SCRIPTS_DIR}/propagate_image.sh ${sub_id} NM
		${SCRIPTS_DIR}/propagate_image.sh ${sub_id} MAGiC-PD
		
		touch ${flag_file}
	else
		echo "Subject '${sub_id}' has already been processed. Skipping."
	fi
done
