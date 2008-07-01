#!/bin/bash
#
#  file:        SetupSherpaInterface.sh
#  description: BASH script for the LOCAL installation of the SHERPA MC generator,
#               HepMC2 & LHAPDF (optional) and the CMSSW SHERPA interface
#  uses:        install_sherpa.sh
#               install_hepmc2.sh
#               install_lhapdf.sh
#               SHERPA patches (optional)
#
#  author:      Markus Merschmeyer, RWTH Aachen
#  date:        2008/06/13
#  version:     1.9
#



# +-----------------------------------------------------------------------------------------------+
# function definitions
# +-----------------------------------------------------------------------------------------------+

function print_help() {
    echo "" && \
    echo "SetupSherpaInterface version 1.9" && echo && \
    echo "options: -i  path       installation directory for SHERPA" && \
    echo "                         -> ( "${instdir}" )" && \
    echo "         -v  version    SHERPA version ("${SHERPAVER}")" && \
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
#SHERPAVER="1.0.11"                                # SHERPA version
#SHERPAVER="1.1.0"                                 # SHERPA version
SHERPAVER="1.1.1"                                 # SHERPA version
#HEPMC2VER="2.00.02"                               # HepMC2 version
#HEPMC2VER="2.01.08"                               # HepMC2 version
HEPMC2VER="2.01.10"                               # HepMC2 version
#LHAPDFVER="5.2.3"                                 # LHAPDF version
LHAPDFVER="5.3.1"                                 # LHAPDF version

SHERPAWEBLOCATION=""      # (web)location of SHERPA tarball
SHERPAFILE=""             # file name of SHERPA tarball

###CRAB stuff
imode="LOCAL"                                     # operation mode (local/CRAB installation/GRID)
# dummy setup (if all options are missing)
if [ "${imode}" = "LOCAL" ]; then
  instdir=${HDIR}                                 # installation directory for SHERPA
  scrpth=${HDIR}                                  # location of necessary shell scripts
  patdir=${HDIR}                                  # location of required SHERPA patches
  cmsswd=${HDIR}/CMSSW_2_0_6                      # location of the CMSSW directory
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
#  xopt=""
  dataloc="XXX"                                   # location of data set (WWW, SE)
  dataset="YYY"                                   # name of dataset (SHERPA process)
fi

if [ "${imode}" = "LOCAL" ]; then                 # local installation?
# get & evaluate options
  while getopts :i:s:p:d:l:f:o:m:v:W:S:h OPT
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
# TOOL definition files necessary for the SHERPA interface
##toolshfile="Sherpa.tool"
toolshfile="Sherpa_"${SHERPAVER}".tool"
toolhmfile="Hepmc2.tool"
toollhfile="Lhapdf.tool"

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
FIXGCC="FALSE"                                    # flag to fix gcc 32-bit mode (overrides 'f' flag in $OINST)
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
  if [ ${MMTMP} -gt 0 ]; then
    FIXGCC="TRUE"
  fi
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
  echo " <I> LHAPDF directory in CMSSW is "${LHAPDFDIR}
# get gcc version and path (fix for 32-/64-bit problem)
  if [ "${FIXGCC}" = "TRUE" ]; then
    export FIXGCCPATH=`scramv1 tool info cxxcompiler | grep -i "gcc_base" | cut -f2 -d"="`
    source ${FIXGCCPATH}/etc/profile.d/init.sh
    echo " <I> gcc path fixed to: "${FIXGCCPATH}
  fi
  cd -
fi

# forced installation?
if [ "${FORCESHERPA}" = "TRUE" ]; then
  export SHERPADIR=${MSI}/SHERPA-MC-${SHERPAVER} # SHERPA installation directory
  echo " <W> forcing SHERPA installation "
  echo " <W> ... to path: "${SHERPADIR}
fi
if [ "${FORCEHEPMC2}" = "TRUE" ]; then
  export HEPMC2DIR=${MSI}/HepMC-${HEPMC2VER}    # HepMC2 installation directory
  echo " <W> forcing HepMC2 installation "
  echo " <W> ... to path: "${HEPMC2DIR}
fi
if [ "${FORCELHAPDF}" = "TRUE" ]; then
  export LHAPDFDIR=${MSI}/lhapdf-${LHAPDFVER}   # LHAPDF installation directory
  echo " <W> forcing LHAPDF installation "
  echo " <W> ... to path: "${LHAPDFDIR}
fi


# forced SHERPA installation???
if [ "${FORCESHERPA}" = "TRUE" ]; then

# evaluate installation options
  pflag=" "
  hflag=" "
  hpath=" "
  lflag=" "
  lpath=" "
  ILHAPDF="false"
  fflag=" "
  fixflag=" "
  mttflag=" "
  locflg=" "
  filflg=" "
  MMTMP=`echo ${OINST} | grep -c "p"`
  if [ ${MMTMP} -gt 0 ]; then # install SHERPA patches?
    pflag=" -p "${SHPATPATH}
  fi
  MMTMP=`echo ${OINST} | grep -c "h"`
  if [ ${MMTMP} -gt 0 ]; then # install HepMC2 ?
    hflag=" -m "${HEPMC2VER}
    hpath=" -M "${HEPMC2DIR}
  fi
  MMTMP=`echo ${OINST} | grep -c "l"`
  if [ ${MMTMP} -gt 0 ]; then # install LHAPDF ?
    lflag=" -l "${LHAPDFVER}
    lpath=" -L "${LHAPDFDIR}
    ILHAPDF="true"
  fi
  MMTMP=`echo ${OINST} | grep -c "f"`
  if [ ${MMTMP} -gt 0 ]; then # 32-bit compatibility mode ?
    fflag=" -f "
  fi
  MMTMP=`echo ${OINST} | grep -c "F"`
  if [ ${MMTMP} -gt 0 ]; then # apply extra fixes (LHAPDF in CMSSW,...) ?
    fixflag=" -F "${SHFIXPATH}
  fi
  MMTMP=`echo ${OINST} | grep -c "M"`
  if [ ${MMTMP} -gt 0 ]; then # use multithreading ?
    mttflag=" -M "
  fi
###
  if [ ! "${SHERPAWEBLOCATION}" = "" ]; then
    locflg=" -W "${SHERPAWEBLOCATION}
  fi
  if [ ! "${SHERPAFILE}" = "" ]; then
    filflg=" -S "${SHERPAFILE}
  fi
###
  if [ "${FIXGCC}" = "TRUE" ]; then
    fflag=" "
  fi

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
    allflags=" -v "${SHERPAVER}" -d "${MSI}" "${pflag}" "${hflag}" "${lflag}" "${fflag}" "${fixflag}" "${mttflag}" "${locflg}" "${filflg}
    if [ "${imode}" = "LOCAL" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${allflags} -L
      ${SCRIPTPATH}/${shshifile} ${allflags} -L
    elif [ "${imode}" = "CRAB" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${allflags} -L
      ${SCRIPTPATH}/${shshifile} ${allflags} -L
    elif [ "${imode}" = "GRID" ]; then
      echo ${SCRIPTPATH}/${shshifile} ${allflags}
      ${SCRIPTPATH}/${shshifile} ${allflags}
    fi
#    echo ${SCRIPTPATH}/${shshifile} -v ${SHERPAVER} -d ${MSI} ${pflag} ${hflag} ${lflag} ${fflag} ${fixflag} ${mttflag} ${locflg} ${filflg}
#         ${SCRIPTPATH}/${shshifile} -v ${SHERPAVER} -d ${MSI} ${pflag} ${hflag} ${lflag} ${fflag} ${fixflag} ${mttflag} ${locflg} ${filflg}
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

#####ls -C1 *.so.0.0.0 | cut -f1 -d"." | sed -e 's:lib:<lib name=":' | sed -e 's:$:"/>:'
if [ "${imode}" = "LOCAL" ]; then
  cd ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data
  if [ "${FORCESHERPA}" = "TRUE" ]; then # substitute correct SHERPA version in tool definition file 'Sherpa'
    echo " <I> substituting correct SHERPA version in file 'Sherpa'"
    cp ${toolshfile}_template ${toolshfile}
    sed -e 's:name="Sherpa" version=".*:name="Sherpa" version="'${SHERPAVER}'">:' < ${toolshfile} > ${toolshfile}.tmp
    mv ${toolshfile}.tmp ${toolshfile}
  fi 
  if [ "${FORCEHEPMC2}" = "TRUE" ]; then # substitute correct HepMC2 version in tool definition file 'Hepmc2'
    echo " <I> substituting correct HepMC2 version in file 'Hepmc2'"
    cp ${toolhmfile}_template ${toolhmfile}
    sed -e 's:name="Hepmc2" version=".*:name="Hepmc2" version="'${HEPMC2VER}'">:' < ${toolhmfile} > ${toolhmfile}.tmp
    mv ${toolhmfile}.tmp ${toolhmfile}
  fi
  if [ "${FORCELHAPDF}" = "TRUE" ]; then # substitute correct LHAPDF version in tool definition file 'Lhapdf'
    echo " <I> substituting correct LHAPDF version in file 'Lhapdf'"
    cp ${toollhfile}_template ${toollhfile}
    sed -e 's:name="Lhapdf" version=".*:name="Lhapdf" version="'${LHAPDFVER}'">:' < ${toollhfile} > ${toollhfile}.tmp
    mv ${toollhfile}.tmp ${toollhfile}
  fi
  cd -
fi

# check existence of CMSSW standalone config file
cnffile=${CMSSWDIR}/config/site/tools-STANDALONE.conf
if [ -e ${cnffile} ]; then
  echo " <I> configuration file exists, registering components (SHERPA, HepMC2, LHAPDF)"

# insert SHERPA, HepMC2, LHAPDF information into tools-STANDALONE.conf
  if [ "${FORCESHERPA}" = "TRUE" ]; then
    if [ `grep -c -i sherpa ${cnffile}` -eq 0 ]; then
      cat >> ${cnffile} << EOF
TOOL:sherpa:
  +SHERPA_BASE:${SHERPADIR}
  +PATH:${SHERPADIR}/bin
  +LIBDIR:${SHERPADIR}/lib/SHERPA-MC
  +INCLUDE:${SHERPADIR}/include
EOF
    fi
  fi
  if [ "${FORCEHEPMC2}" = "TRUE" ]; then
   if [ `grep -c -i hepmc2 ${cnffile}` -eq 0 ]; then
    cat >> ${cnffile} << EOF
TOOL:hepmc2:
  +HEPMC2_BASE:${HEPMC2DIR}
  +LIBDIR:${HEPMC2DIR}/lib
  +INCLUDE:${HEPMC2DIR}/include
EOF
   fi
  fi
  if [ "${FORCELHAPDF}" = "TRUE" ]; then
   if [ `grep -c -i lhapdf ${cnffile}` -eq 0 ]; then
    cat >> ${cnffile} << EOF
TOOL:lhapdf:
  +LHAPDF_BASE:${LHAPDFDIR}
  +PATH:${LHAPDFDIR}/bin
  +LIBDIR:${LHAPDFDIR}/lib
EOF
   fi
  fi

  scramopt=" -f "${cnffile}
else
  echo " <W> no configuration file found, registering components,..."
  scramopt=""
fi

if [ ! "${imode}" = "GRID" ]; then
if [ "${FORCESHERPA}" = "TRUE" ]; then # register SHERPA as a tool
  cd ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/
  sed -e 's:"SHERPA_BASE"/>:"SHERPA_BASE" value="'${SHERPADIR}'"/>:' < ${toolshfile} > ${toolshfile}.bak
  if [ ${CMSSWVERM} -lt 2 ]; then
    mv ${toolshfile}.bak ${toolshfile}
    sed -e 's:/>:>:' < ${toolshfile} > ${toolshfile}.bak
  fi
  mv ${toolshfile}.bak ${toolshfile}
### FIXME (in CMSSW, for unknown reasons 'LHAPDF' is 'lhapdf'...)
  sed -e 's:LHAPDF":lhapdf":' < ${toolshfile} > ${toolshfile}.bak
  mv ${toolshfile}.bak ${toolshfile}
### FIXME
  cd -
  scramv1 setup ${scramopt} sherpa ${SHERPAVER} file:${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/${toolshfile}
fi
if [ "${FORCEHEPMC2}" = "TRUE" ]; then # register HepMC2 as a tool
  cd ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/
  mv ${toolhmfile} ${toolhmfile}.bak
  sed -e 's:"HEPMC2_BASE"/>:"HEPMC2_BASE" value="'${HEPMC2DIR}'"/>:' < ${toolhmfile}.bak > ${toolhmfile}
  if [ ${CMSSWVERM} -lt 2 ]; then
    mv ${toolhmfile}.bak ${toolhmfile}
    sed -e 's:/>:>:' < ${toolhmfile} > ${toolhmfile}.bak
  fi
  mv ${toolhmfile}.bak ${toolhmfile}
  cd -
  scramv1 setup ${scramopt} hepmc2 ${HEPMC2VER} file:${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/${toolhmfile}
fi
if [ "${FORCELHAPDF}" = "TRUE" ]; then # register LHAPDF as a tool
  cd ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/
  mv ${toollhfile} ${toollhfile}.bak
  sed -e 's:"LHAPDF_BASE"/>:"LHAPDF_BASE" value="'${LHAPDFDIR}'"/>:' < ${toollhfile}.bak > ${toollhfile}
  if [ ${CMSSWVERM} -lt 2 ]; then
    mv ${toollhfile}.bak ${toollhfile}
    sed -e 's:/>:>:' < ${toolslfile} > ${toollhfile}.bak
  fi
  mv ${toollhfile}.bak ${toollhfile}
  cd -
  scramv1 setup ${scramopt} lhapdf ${LHAPDFVER} file:${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/${toollhfile}
fi
fi # check for 'GRID' mode




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

#  cd ${CMSSWDIR}/src/${SHIFPTH1}/${SHIFPTH2}/data/${SHERPAPROCESS}/Run
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
