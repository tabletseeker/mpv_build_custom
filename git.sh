#!/bin/bash

unset CLONE GET TYPE TARGET REPO

while [[ $# -gt 0 ]]; do

	case ${1} in

		-w|--wget)
		GET=1
		case ${2} in

			*zip*)
			TARGET="zipball_url"
			EXT=".zip"
			shift
			;;
			
			*tar*)
			TARGET="tarball_url"
			EXT=".tar.gz"
			shift
			;;
		esac
		shift
		;;
		
		-r|--repo)
		REPO=${2}
		shift
		shift
		;;
		
		-t|--type)
		case ${2} in
		
			*rel*)
			TYPE="releases"
			shift
			;;
			
			*tag*)
			TYPE="tags"
			shift
			;;
			
			master)
			TYPE="master"
			shift
			;;
		esac
		shift
		;;
		
		-v|--version)
		VERSION=${2}
		shift
		shift
		;;
		
		-c|--clone)
		CLONE=1
		TARGET="name"
		shift
		;;
		
		-*|--*)
		echo "Unknown option $1"
		exit 1
		;;
		
		*)
		CUSTOM_ARGS+=("$1")
		shift
		;;

	esac

done

[[ -n ${CLONE} && -z ${TYPE} ]] && TYPE="master"
[[ -z ${TARGET} || -z ${REPO} || -z ${TYPE} ]] && { echo "missing options!"; exit 1 ; }
[[ -n ${CLONE} && -n ${GET} ]] && { echo "choose between cloning or wget!"; exit 1 ; }


GIT_URL="https://github.com/${REPO}"
API_URL="https://api.github.com/repos/${REPO}/${TYPE}"
ARCHIVE="${REPO#*/}${EXT}"
OUTPUT=${ARCHIVE%%.*}

[ ${TYPE} = master ] && BRANCH="master" || \
BRANCH=$(curl -s ${API_URL} | jq '.[]' | jq -r ".${TARGET}" | grep -Pm1 "${VERSION}")

[ ${TARGET} = name ] && \
{ git clone ${GIT_URL} --branch ${BRANCH} ${ARCHIVE} || exit 1; } || { wget ${BRANCH} -O ${ARCHIVE} && \
{ mkdir -p ${REPO#*/}; bsdtar -xvf ${ARCHIVE} -C ${OUTPUT} --strip-components 1; } || exit 1; }

