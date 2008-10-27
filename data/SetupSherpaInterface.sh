#!/bin/bash
#
#  file:        SetupSherpaInterface.sh
#  description: BASH script for the LOCAL installation of the SHERPA MC generator,
#               HepMC2 & LHAPDF (optional) and the CMSSW SHERPA interface
#  uses:        install_sherpa.sh
#               install_hepmc2.sh
#               install_lhapdf.sh
#               SHERPA patches (optional)
#               SHERPA fixes (optional)
#
#  author:      Markus Merschmeyer, RWTH Aachen
#  date:        2008/10/09
#  version:     2.2
#



# +-----------------------------------------------------------------------------------------------+
# function definitions
# +-----------------------------------------------------------------------------------------------+

function print_help() {
    echo "" && \
    echo "SetupSherpaInterface version 2.2" && echo && \
    echo "options: -i  path       installation directory for SHERPA" && \
    echo "                         -> ( "${instdir}" )" && \
    echo "         -v  version    SHERPA version ( "${SHERPAVER}" )" && \
    echo "         -s  path       location of necessary shell scripts" && \
    echo "                         -> ( "${scrpth}" )" && \
    echo "         -p  path       location of required SHERPA patches/fixes" && \
    echo "                         -> ( "${patdir}" )" && \
    echo "         -d  path       location of the CMSSW directory" && \
    echo "                         -> ( "${cmsswd}" )" && \
    echo "         -l  path       location of SHERPA interface tarball" && \
    echo "                         -> ( "${ship}" )" && \
    echo "         -f  filename   name of SHERPA interface tarball ( "${shif}" )" && \
    echo "         -o  option(s)  expert options ( "${xopt}" )" && \
    echo "         -m  mode       running mode ['LOCAL','CRAB','GRID'] ( "${imode}" )" && \
    echo "         -W  location   (optional) location of SHERPA tarball ( "${SHERPAWEBLOCATION}" )" && \
    echo "         -S  filename   (optional) file name of SHERPA tarball ( "${SHERPAFILE}" )" && \
    echo "         -C  level      cleaning level of (SHERPA) installation ("${LVLCLEAN}" )" && \
    echo "                         -> 0: nothing, 1: +objects, 2: +sourcecode" && \
    echo "         -D             debug flag, compile with '-g' option ("${FLGDEBUG}" )" && \
    echo "         -h             display this help and exit" && echo
}

# function to copy files from different locations (WWW, SE, local)
function file_get() {
# $1 : target path
# $2 : file name
# $3 : destination path
#
#  srmopt=" -debug -streams_num=1 "
  srmopt=" -streams_num=1 "
#
  tpath="./"
  fname="xxx.yyy"
  dpath="./"
  if [ $# -ge 1 ]; then
    tpath=$1
    if [ $# -ge 2 ]; then
      fname=$2
      if [ $# -ge 3 ]; then
        dpath=$3
      fi
    fi
  fi
  ILOC0=`echo ${tpath} | cut -f1 -d "/" | grep -c -i http`
  ILOC1=`echo ${tpath} | cut -f1 -d "/" | grep -c -i srm`
  cd ${dpath}
  if [ ${ILOC0} -gt 0 ]; then    # file is in WWW
    echo " <I> retrieving WWW file: "${fname}
    echo " <I>  from path: "${tpath}
    wget ${tpath}/${fname}
  elif [ ${ILOC1} -gt 0 ]; then  # file is in SE
    echo " <I> retrieving SE file: "${fname}
    echo " <I>  from path: "${tpath}
#    srmcp ${tpath}/${fname} file:///${PWD}/${fname}
    srmcp ${srmopt} ${tpath}/${fname} file:///${PWD}/${fname}
  else                           # local file
    echo " <I> copying local file: "${fname}
    echo " <I>  from path: "${tpath}
    cp ${tpath}/${fname} ./
  fi
  cd -
}



# +-----------------------------------------------------------------------------------------------+
# start of the script
# +-----------------------------------------------------------------------------------------------+

# save current directory
HDIR=`pwd`

# set installation versions
SHERPAVER="1.1.2"                                 # SHERPA version
HEPMC2VER="2.03.09"                               # HepMC2 version
LHAPDFVER="5.3.1"                                 # LHAPDF version

SHERPAWEBLOCATION=""      # (web)location of SHERPA tarball
SHERPAFILE=""             # file name of SHERPA tarball

LVLCLEAN=0                # cleaning level (0-2)
FLGDEBUG="FALSE"          # debug flag for compilation


###CRAB stuff
imode="LOCAL"                                     # operation mode (local/CRAB installation/GRID)
# dummy setup (if all options are missing)
if [ "${imode}" = "LOCAL" ]; then
  instdir=${HDIR}                                 # installation directory for SHERPA
  scrpth=${HDIR}                                  # location of necessary shell scripts
  patdir=${HDIR}                                  # location of required SHERPA patches
  cmsswd=${HDIR}/CMSSW_X_Y_Z                      # location of the CMSSW directory
  ship=${HDIR}                                    # location of SHERPA interface tarball
  shif=SherpaInterface.tgz                        # name of SHERPA interface tarball
  xopt="SOpOhOlOfOF"                              # expert options
#  xopt=""
elif [ "${imode}" = "CRAB" ]; then
  instdir=${HOME}                                 # installation directory for SHERPA
  scrpth=${HDIR}                                  # location of necessary shell scripts
  patdir=${HDIR}                                  # location of required SHERPA patches
  cmsswd=${HDIR}                                  # location of the CMSSW directory
  xopt="SOpOhOlOfOF"                              # expert options
  xopt="SOpOhOlOfOFOI"                            # + configure/make/make install
#  xopt=""
  dataloc="XXX"                                   # location of data set (WWW, SE)
  dataset="YYY"                                   # name of dataset (SHERPA process)
fi

if [ "${imode}" = "LOCAL" ]; then                 # local installation?
# get & evaluate options
  while getopts :i:s:p:d:l:f:o:m:v:W:S:C:Dh OPT
  do
    case $OPT in
    i) instdir=$OPTARG ;;
    s) scrpth=$OPTARG ;;
    p) patdir=$OPTARG ;;
    d) cmsswd=$OPTARG ;;
    l) ship=$OPTARG ;;
    f) shif=$OPTARG ;;
    o) xopt=$OPTARG ;;
    m) imode=$OPTARG ;;
    v) SHERPAVER=$OPTARG ;;
    W) SHERPAWEBLOCATION=$OPTARG ;;
    S) SHERPAFILE=$OPTARG ;;
    C) LVLCLEAN=$OPTARG ;;
    D) FLGDEBUG=TRUE ;;
    h) print_help && exit 0 ;;
    \?)
      shift `expr $OPTIND - 1`
      if [ "$1" = "--help" ]; then print_help && exit 0;
      else 
        echo -n "SetupSherpaInterface: error: unrecognized option "
        if [ $OPTARG != "-" ]; then echo "'-$OPTARG'. try '-h'"
        else echo "'$1'. try '-h'"
        fi
        print_help && exit 1
      fi
      shift 1
      OPTIND=1
    esac
  done
fi

# make sure all path names are absolute
cd ${instdir}; instdir=`pwd`; cd ${HDIR}
cd ${scrpth};  scrpth=`pwd`;  cd ${HDIR}
cd ${patdir};  patdir=`pwd`;  cd ${HDIR}
if [ ! "${imode}" = "GRID" ]; then
  cd ${cmsswd};  cmsswd=`pwd`;  cd ${HDIR}
fi
if [ "${imode}" = "LOCAL" ]; then
  cd ${ship};    ship=`pwd`;    cd ${HDIR}
fi

echo " SHERPA interface setup (local/CRAB/GRID)"
echo "  -> SHERPA installation directory: '"${instdir}"'"
echo "  -> SHERPA version: '"${SHERPAVER}"'"
echo "  -> location of SHERPA patches/fixes: '"${patdir}"'"
echo "  -> script path: '"${scrpth}"'"
if [ ! "${imode}" = "GRID" ]; then
  echo "  -> location of CMSSW: '"${cmsswd}"'"
  if [ "${imode}" = "LOCAL" ]; then
    echo "  -> location of SHERPA interface tarball: '"${ship}"'"
    echo "  -> name of SHERPA interface tarball: '"${shif}"'"
  fi
fi
echo "  -> expert options: '"${xopt}"'"
echo "  -> operation mode: '"${imode}"'"


echo "------------------------------------------------------------------------------------------"
echo " --> setup phase..."
echo "------------------------------------------------------------------------------------------"

# set path names for SHERPA interface in CMSSW
SHIFPTH1="GeneratorInterface"                     # subdirectory for the SHERPA interface
SHIFPTH2="SherpaInterface"                        # subdirectory for the SHERPA interface components
# set up file names (files are expected to be located under ${MSI})
shshifile="install_sherpa.sh"                     # script for SHERPA installation
shhmifile="install_hepmc2.sh"                     # script for HepMC2 installation
shlhifile="install_lhapdf.sh"                     # script for LHAPDF installation
# XML TOOL definition files necessary for the SHERPA interface
toolshfile="sherpa.xml"
toolhmfile="hepmc.xml"
toollhfile="lhapdf.xml"


chmod u+x *.sh                                    # make scripts executable again

# set up paths and CMSSW properties
if [ "${imode}" = "CRAB" ]; then                  # define CMSSW properties
  export MSI=${HOME}                              # main installation directory for SHERPA,...
  SCRIPTPATH=${HDIR}                              # location of scripts
  SHPATPATH=${HDIR}                               # location of SHERPA patches
  SHFIXPATH=${HDIR}                               # location of SHERPA fixes
  export CMSSWDIR=${HDIR}                         # path to CMSSW release
  SHERPAPRCLOCATION=${dataloc}                    # location of SHERPA libraries & cross sections
  SHERPAPROCESS=${dataset}                        # SHERPA process specifier
  SHERPADCDFILE=sherpa_${SHERPAPROCESS}_cards.tgz # name of SHERPA data card file
  SHERPALIBFILE=sherpa_${SHERPAPROCESS}_libs.tgz  # name of SHERPA library file
  SHERPACRSFILE=sherpa_${SHERPAPROCESS}_crss.tgz  # name of SHERPA cross section file
  ICRS="TRUE"                                     # use cross sectiond provided in tarball (FALSE: recalculate)
elif [ "${imode}" = "LOCAL" ]; then
  export MSI=${instdir}                           # main installation directory for SHERPA,...
  SCRIPTPATH=${scrpth}                            # location of scripts
  SHPATPATH=${patdir}                             # location of SHERPA patches
  SHFIXPATH=${patdir}                             # location of SHERPA fixes
  export CMSSWDIR=${cmsswd}                       # path to CMSSW release
  SHERPAINTERFACELOCATION=${ship}                 # location SHERPA interface tarball
  SHERPAINTERFACEFILE=${shif}                     # name of SHERPA interface tarball
elif [ "${imode}" = "GRID" ]; then
  export MSI=${instdir}                           # main installation directory for SHERPA,...
  SCRIPTPATH=${scrpth}                            # location of scripts
  SHPATPATH=${patdir}                             # location of SHERPA patches
  SHFIXPATH=${patdir}                             # location of SHERPA fixes
  export CMSSWDIR=${cmsswd}                       # path to CMSSW release [DUMMY]
fi

# extract CMSSW version
if [ -e ${CMSSWDIR} ]; then
  CMSSWVERM=`echo ${CMSSWDIR} | awk 'match($0,/CMSSW_.*/){print substr($0,RSTART+6,1)}'`
  echo " --> recovered CMSSW version: "${CMSSWVERM}
  va=`echo ${CMSSWVERM} | cut -f1 -d"_"`
  vb=`echo ${CMSSWVERM} | cut -f2 -d"_"`
  vc=`echo ${CMSSWVERM} | cut -f3 -d"_"`
else
  if [ ! "${imode}" = "GRID" ]; then
    echo " <E> CMSSW directory does not exist: "${CMSSWDIR}
    echo " <E> ...stopping..."
    exit 1
  fi
fi

# evaluate expert options
FORCESHERPA="FALSE"                               # flags to force (override) installation of SHERPA, HepMC2, LHAPDF
FORCEHEPMC2="FALSE"
FORCELHAPDF="FALSE"
OINST=""                                          # SHERPA installation options
#                                                 # ['p': SHERPA patches, 'h': HepMC2, 'l': LHAPDF, 'f': 32-bit comp. mode ]

MMTMP=`echo ${xopt} | grep -c "S"`
if [ ${MMTMP} -gt 0 ]; then                       # force SHERPA installation
  FORCESHERPA="TRUE"
fi
MMTMP=`echo ${xopt} | grep -c "H"`
if [ ${MMTMP} -gt 0 ]; then                       # force HepMC2 installation
  FORCEHEPMC2="TRUE"
  FORCESHERPA="TRUE"
fi
MMTMP=`echo ${xopt} | grep -c "L"`
if [ ${MMTMP} -gt 0 ]; then                       # force LHAPDF installation
  FORCELHAPDF="TRUE"
#  FORCEHEPMC2="TRUE"
  FORCESHERPA="TRUE"
fi
if [ "${FORCESHERPA}" = "TRUE" ]; then
  MMTMP=`echo ${xopt} | grep -c "G"`
  if [ "${FORCEHEPMC2}" = "TRUE" ]; then
    if [ `echo ${xopt} | grep -c "Oh"` -eq 0 ]; then
      xopt=${xopt}"Oh"
    fi
  fi
  if [ "${FORCELHAPDF}" = "TRUE" ]; then
    if [ `echo ${xopt} | grep -c "Ol"` -eq 0 ]; then
      xopt=${xopt}"Ol"
    fi
  fi
  MMTMP=`echo ${xopt} | grep -o "O" | grep -c "O"`
  lcnt=1
  OINST=""
  while [ ${lcnt} -le ${MMTMP} ]; do
    let lcnt=${lcnt}+1
    ctmp=`echo ${xopt} | cut -f ${lcnt} -d "O"`
    OINST=${OINST}""${ctmp}
  done
  echo "DEBUG: installation options: "$OINST
fi



echo "------------------------------------------------------------------------------------------"
echo " --> SHERPA installation phase..."
echo "------------------------------------------------------------------------------------------"

if [ ! -e  ${CMSSWDIR} ]; then
  if [ ! "${imode}" = "GRID" ]; then
    echo " <E> CMSSW installation "${CMSSWDIR}
    echo " <E>  does not exist -> stopping..."
    exit 1
  fi
else
# get SHERPA, HepMC2 and LHAPDF tool path in current CMSSW version
  cd ${CMSSWDIR}
  export SHERPADIR=`scramv1 tool info sherpa  | grep -i sherpa_base  | cut -f2 -d"="`
  echo " <I> SHERPA directory in CMSSW is "${SHERPADIR}
  export HEPMC2DIR=`scramv1 tool info hepmc  | grep -i hepmc_base  | cut -f2 -d"="`
  echo " <I> HepMC2 directory in CMSSW is "${HEPMC2DIR}
  export LHAPDFDIR=`scramv1 tool info lhapdf | grep -i lhapdf_base | cut -f2 -d"="`
### needed since SHERPA 1.1.2
  export LHAPATH=${LHAPDFDIR}
###
  echo " <I> LHAPDF directory in CMSSW is "${LHAPDFDIR}
  cd -
fi

# forced installation?
if [ "${FORCESHERPA}" = "TRUE" ]; then
  export SHERPADIR=${MSI}/SHERPA-MC-${SHERPAVER} # SHERPA installation directory
  echo " <W> forcing SHERPA installation to path:"
  echo " <W> ... "${SHERPADIR}
fi
if [ "${FORCEHEPMC2}" = "TRUE" ]; then
  export HEPMC2DIR=${MSI}/HepMC-${HEPMC2VER}    # HepMC2 installation directory
  echo " <W> forcing HepMC2 installation to path:"
  echo " <W> ... "${HEPMC2DIR}
fi
if [ "${FORCELHAPDF}" = "TRUE" ]; then
  export LHAPDFDIR=${MSI}/lhapdf-${LHAPDFVER}   # LHAPDF installation directory
  echo " <W> forcing LHAPDF installation to path:"
  echo " <W> ... "${LHAPDFDIR}
fi


# forced SHERPA installation???
if [ "${FORCESHERPA}" = "TRUE" ]; then

# evaluate installation options
  ALLFLAGS=""
  ALLFLAGS=${ALLFLAGS}" -v "${SHERPAVER}
  ALLFLAGS=${ALLFLAGS}" -d "${MSI}
  ALLFLAGS=${ALLFLAGS}" -C "${LVLCLEAN}
  if [ `echo ${OINST} | grep -c "p"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -p "${SHPATPATH}; fi # install SHERPA patches?
  if [ `echo ${OINST} | grep -c "h"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -m "${HEPMC2VER}; fi # install HepMC2 ?
  if [ `echo ${OINST} | grep -c "l"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -l "${LHAPDFVER}; fi # install LHAPDF ?
  if [ `echo ${OINST} | grep -c "f"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -f";              fi # 32-bit compatibility mode ?
  if [ `echo ${OINST} | grep -c "F"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -F "${SHFIXPATH}; fi # apply extra fixes ?
  if [ `echo ${OINST} | grep -c "M"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -M";              fi  # use multithreading ?
  if [ "${FLGDEBUG}" = "TRUE" ];              then ALLFLAGS=${ALLFLAGS}" -D";                    fi
  if [ `echo ${OINST} | grep -c "I"` -gt 0 ]; then ALLFLAGS=${ALLFLAGS}" -I";              fi  # use configure/make/make install ?
###
  if [ ! "${SHERPAWEBLOCATION}" = "" ]; then ALLFLAGS=${ALLFLAGS}" -W "${SHERPAWEBLOCATION}; fi
  if [ ! "${SHERPAFILE}" = "" ];        then ALLFLAGS=${ALLFLAGS}" -S "${SHERPAFILE};      fi
###

# if needed, create installation directory
  if [ ! -d  ${MSI} ]; then
    echo " <W> installation directory does not exist, creating..."
    mkdir -p ${MSI}
  fi

# install SHERPA and - if required - HepMC2 and LHAPDF
  if [ ! -e ${SHERPADIR}/bin/Sherpa ]; then
    if [ -e  ${SHERPADIR} ]; then
      echo " <W> SHERPA directory exists but no executable found,"
      echo " <W>  deleting and reinstalling..."
      rm -rf ${SHERPADIR}
    fi
    echo " <I> installing SHERPA"
    if [ "${imode}" = "LOCAL" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${ALLFLAGS} -L
      ${SCRIPTPATH}/${shshifile} ${ALLFLAGS} -L
    elif [ "${imode}" = "CRAB" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${ALLFLAGS} -L
      ${SCRIPTPATH}/${shshifile} ${ALLFLAGS} -L
    elif [ "${imode}" = "GRID" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${ALLFLAGS}
      ${SCRIPTPATH}/${shshifile} ${ALLFLAGS}
    fi
  else
    echo " <I> SHERPA already installed"
  fi

fi # check FORCESHERPA flag


# set up SHERPA interface in CMSSW
if [ "${imode}" = "LOCAL" ]; then
  echo "------------------------------------------------------------------------------------------"
  echo " --> SHERPA interface setup phase..."
  echo "------------------------------------------------------------------------------------------"
  if [ ! -e  ${CMSSWDIR}/src/${SHIFPTH1} ]; then
    echo " <I> creating directory "${SHIFPTH1}" under "${CMSSWDIR}"/src"
    mkdir -p ${CMSSWDIR}/src/${SHIFPTH1}
  else
    echo " <I>  directory "${SHIFPTH1}" exists"
  fi
  if [ ! -e  ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2} ]; then
    echo " <I> SHERPA Interface is being installed"
    cd ${CMSSWDIR}/src/${SHIFPTH1}
    file_get ${SHERPAINTERFACELOCATION} ${SHERPAINTERFACEFILE} "./"
    tar -xzf ${SHERPAINTERFACEFILE}
    rm ${SHERPAINTERFACEFILE}
  else
    echo " <I>  <I> SHERPA Interface exists in CMSSW"
  fi
  cd  ${CMSSWDIR}/src
fi


echo "------------------------------------------------------------------------------------------"
echo " --> CMSSW + SHERPA setup phase..."
echo "------------------------------------------------------------------------------------------"

if [ "${imode}" = "GRID" ]; then
  cd ${MSI}
else
  cd ${CMSSWDIR}
fi

if [ "${imode}" = "LOCAL" ]; then
  ddir=${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data
  xmldir=${CMSSWDIR}/config/toolbox/slc4_ia32_gcc345/tools/selected
  cd ${ddir}

  if [ "${FORCESHERPA}" = "TRUE" ]; then # create SHERPA tool definition XML file
    echo " <I> creating Sherpa tool definition XML file"
    touch ${toolshfile}
    echo "  <tool name=\"Sherpa\" version=\""${SHERPAVER}"\">" >> ${toolshfile}
    for lib in `cd ${SHERPADIR}/lib/SHERPA-MC; ls -C1 *.so | cut -f 1 -d "." | sed -e 's/lib//'; cd ${ddir}`; do
      echo "    <lib name=\""${lib}"\"/>" >> ${toolshfile}
    done
    echo "    <client>" >> ${toolshfile}
    echo "      <Environment name=\"SHERPA_BASE\" value=\""${SHERPADIR}"\"/>" >> ${toolshfile}
    echo "      <Environment name=\"BINDIR\" default=\"\$SHERPA_BASE/bin\"/>" >> ${toolshfile}
    echo "      <Environment name=\"LIBDIR\" default=\"\$SHERPA_BASE/lib/SHERPA-MC\"/>" >> ${toolshfile}
    echo "      <Environment name=\"INCLUDE\" default=\"\$SHERPA_BASE/include\"/>" >> ${toolshfile}
    echo "    </client>" >> ${toolshfile}
    echo "    <runtime name=\"CMSSW_FWLITE_INCLUDE_PATH\" value=\"\$SHERPA_BASE/include\" type=\"path\"/>" >> ${toolshfile}
    echo "    <use name=\"HepMC\"/>" >> ${toolshfile}
    echo "    <use name=\"lhapdf\"/>" >> ${toolshfile}
    echo "  </tool>" >> ${toolshfile}
    cp ${toolshfile} ${xmldir}
  fi

  if [ "${FORCEHEPMC2}" = "TRUE" ]; then # create HepMC tool definition XML file
    echo " <I> creating HepMC tool definition XML file"
    touch ${toolhmfile}
    echo "  <tool name=\"HepMC\" version=\""${HEPMC2VER}"\">" >> ${toolhmfile}
    for lib in `cd ${HEPMC2DIR}/lib; ls -C1 *.so | cut -f 1 -d "." | sed -e 's/lib//'; cd ${ddir}`; do
      echo "    <lib name=\""${lib}"\"/>" >> ${toolhmfile}
    done
    echo "    <client>" >> ${toolhmfile}
    echo "      <Environment name=\"HEPMC_BASE\" value=\""${HEPMC2DIR}"\"/>" >> ${toolhmfile}
    echo "      <Environment name=\"LIBDIR\" default=\"\$HEPMC_BASE/lib\"/>" >> ${toolhmfile}
    echo "      <Environment name=\"INCLUDE\" default=\"\$HEPMC_BASE/include\"/>" >> ${toolhmfile}
    echo "    </client>" >> ${toolhmfile}
    echo "    <runtime name=\"CMSSW_FWLITE_INCLUDE_PATH\" value=\"\$HEPMC_BASE/include\" type=\"path\"/>" >> ${toolhmfile}
    echo "    <use name=\"CLHEP\"/>" >> ${toolhmfile}
    echo "  </tool>" >> ${toolhmfile}
    cp ${toolhmfile} ${xmldir}
  fi

  if [ "${FORCELHAPDF}" = "TRUE" ]; then # create LHAPDF tool definition XML file
    echo " <I> creating LHAPDF tool definition XML file"
    touch ${toollhfile}
    echo "  <tool name=\"lhapdf\" version=\""${LHAPDFVER}"\">" >> ${toollhfile}
    for lib in `cd ${LHAPDFDIR}/lib; ls -C1 *.so | cut -f 1 -d "." | sed -e 's/lib//'; cd ${ddir}`; do
      echo "    <lib name=\""${lib}"\"/>" >> ${toollhfile}
    done
    echo "    <client>" >> ${toollhfile}
    echo "      <Environment name=\"LHAPDF_BASE\" value=\""${LHAPDFDIR}"\"/>" >> ${toollhfile}
    echo "      <Environment name=\"LIBDIR\" default=\"\$LHAPDF_BASE/lib\"/>" >> ${toollhfile}
    echo "      <Environment name=\"LHAPATH\" default=\"\$LHAPDF_BASE/PDFsets\"/>" >> ${toollhfile}
    echo "    </client>" >> ${toollhfile}
    echo "    <runtime name=\"LHAPATH\" value=\"\$LHAPDF_BASE/PDFsets\" type=\"path\"/>" >> ${toollhfile}
    echo "    <use name=\"f77compiler\"/>" >> ${toollhfile}
    echo "  </tool>" >> ${toollhfile}
    cp ${toollhfile} ${xmldir}
  fi

  cd ${CMSSWDIR}
fi

if [ ! "${imode}" = "GRID" ]; then
  scramopt=""
  if [ "${FORCESHERPA}" = "TRUE" ]; then
    scramv1 setup ${scramopt} sherpa
  fi
  if [ "${FORCEHEPMC2}" = "TRUE" ]; then
    scramv1 setup ${scramopt} hepmc
  fi
  if [ "${FORCELHAPDF}" = "TRUE" ]; then
    scramv1 setup ${scramopt} lhapdf
  fi
fi



if [ "${imode}" = "CRAB" ]; then         # generate 'external(/...)' subdirectories
  echo "------------------------------------------------------------------------------------------"
  echo " --> SHERPA library and cross section setup phase..."
  echo "------------------------------------------------------------------------------------------"

  mkdir ${CMSSWDIR}/external
  mkdir ${CMSSWDIR}/external/slc4_ia32_gcc345
  mkdir ${CMSSWDIR}/external/slc4_ia32_gcc345/lib
  cd ${CMSSWDIR}/external/slc4_ia32_gcc345/lib
  for file in `ls ${SHERPADIR}/lib/SHERPA-MC/`; do
    echo " <I> creating softlink for file "$file
    ln -s ${SHERPADIR}/lib/SHERPA-MC/${file} ${file}
  done
  cd -

  cd ${CMSSWDIR}
  mkdir SherpaRun
  cd SherpaRun
# clean and recreate library & cross section folders
  rm -rf *
  mkdir Process
  mkdir Result
# get/unpack SHERPA library section file
  file_get ${SHERPAPRCLOCATION} ${SHERPALIBFILE} ./
  tar -xzf ${SHERPALIBFILE}; rm ${SHERPALIBFILE}
# get/unpack SHERPA cross section file (?)
  if [ "${ICRS}" = "TRUE" ]; then
    file_get ${SHERPAPRCLOCATION} ${SHERPACRSFILE} ./
    tar -xzf ${SHERPACRSFILE}; rm ${SHERPACRSFILE}
  fi
  cd -
fi



echo "------------------------------------------------------------------------------------------"
echo " --> CMSSW compile/run phase..."
echo "------------------------------------------------------------------------------------------"

if [ "${imode}" = "LOCAL" ]; then        # compile SHERPA interface in CMSSW
  cd  ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}
  scramv1 b
elif [ "${imode}" = "CRAB" ]; then       # run SHERPA interface in CRAB
  cd ${CMSSWDIR}
  eval `scramv1 ru -sh`
  cmsRun -p pset.cfg
  rm -rf ${SHERPADIR}
else                                     # do nothing
  echo "--- mode: "${imode}
fi

echo "--------------------------------------------------------------------------------"
PDFDIR=`find ${LHAPATH} -name PDFsets`
echo " <I> if AFTER executing \"eval \`scramv1 ru -(c)sh\`\" LHAPATH is not defined "
echo " <I> please set environment variable LHAPATH to"
echo " <I>  "${PDFDIR}
echo " <I>  e.g. (BASH): export LHAPATH="${PDFDIR}
echo " <I>  e.g. (CSH):  setenv LHAPATH "${PDFDIR}
echo "--------------------------------------------------------------------------------"
