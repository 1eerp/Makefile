# Makefile helper variables
BLANK =
SLASH = \${BLANK}
# Executable/Project name
PROJECT_NAME = test
EXEC = ${PROJECT_NAME}.exe

# Platform Configuration
TARGET_PLATFORM = X64
SUBSYSTEM = CONSOLE # Other options: Windows

# Build Configuration
DEBUG ?= 1
OPTIMIZE ?= 0
CC = cl
LNK = link
DEBUGGER = devenv

# Build could be one of three types: debug, release and dist 
ifeq (${DEBUG},0)
# If this is not a debug build, it could only be an optimized build, built for disribution
	BUILD_CONFIG = dist
else ifeq ($(OPTIMIZE),1)
	BUILD_CONFIG = release
else
	BUILD_CONFIG = debug
endif

# Directory names, some of which depend on BUILD_CONFIG
BUILD_DIR = build\\
OUT_DIR = ${BUILD_DIR}${BUILD_CONFIG}\\
INT_DIR = ${OUT_DIR}
ifneq (${BUILD_CONFIG}, dist)
	INT_DIR = ${OUT_DIR}intermediates\\
endif

# TODO: Update compiler and linker options if needed
FLAGS_COMPILER = -nologo -EHsc -Wall -WL -std:c++20 -c -Fo${INT_DIR}
FLAGS_LINKER = -DEBUG -PDB:${OUT_DIR}${PROJECT_NAME}.pdb -ILK:${OUT_DIR}${PROJECT_NAME}.ilk

ifeq (${BUILD_CONFIG},dist)
	FLAGS_COMPILER += -Ox
# Replaces earlier initialization that had debugger related options
	FLAGS_LINKER = -INCREMENTAL:NO
else ifeq ($(BUILD_CONFIG),release)
	FLAGS_COMPILER += -Ox -Zi -Fd${OUT_DIR}
else
	FLAGS_COMPILER += -Od -Zi -Fd${OUT_DIR}
endif

FLAGS_LINKER += -VERBOSE:INCR -TIME -NOLOGO -MACHINE:${TARGET_PLATFORM} -SUBSYSTEM:${SUBSYSTEM} -OUT:${OUT_DIR}${EXEC}

# Generate assembly for source files?
# Use -FA[] with options s(w/ source code), c(w/ machine code), u(encode the asm listing in UTF-8)
GEN_ASM ?= 0
ifeq (${DEBUG},1)
ifeq (${GEN_ASM},1)
	FLAGS_COMPILER += -FAs -Fa${INT_DIR}
endif
endif

# Source files
SOURCE_DIRS = source
# wildcard only seems to like forward slashes, and its annoying
TMP_SRC_PATHS = ${foreach dir,${SOURCE_DIRS},${wildcard ${dir}/*.cpp}}
TMP_OBJS = ${foreach dir,${SOURCE_DIRS},${patsubst ${dir}/%.cpp,%.obj, ${wildcard ${dir}/*.cpp}}}
# Final result of the above operations are source files w/ relative paths, and all respective object files(sotred in the intermediates directory of the build)
SOURCE_FILES = ${subst /,\\,${TMP_SRC_PATHS}}
OBJ_FILES = ${foreach obj,${TMP_OBJS},${INT_DIR}${obj}}

# TODO: Add an exclusion list for source files

# RECIPES
all: dirs $(EXEC)

# Makes directories if they don't already exist
dirs:
	if not exist $(INT_DIR) mkdir $(INT_DIR)

# START: Project Recipes
# RECIPE TEMPLATE:
# CSRC_DIR = [DIRECTORY THE FILE IS LOCATED IN]
# ${INT_DIR}[REPLACE_NAME].obj: ${CSRC_DIR}[FILENAME].cpp [OTHER DEPENDENCIES]
# 	${CC} ${FLAGS_COMPILER} ${CSRC_DIR}[FILENAME].cpp

# TODO: Distribution build shouldn't output anything other than executable
$(EXEC): ${OBJ_FILES}
	${LNK} ${OBJ_FILES} ${FLAGS_LINKER}

# INSERT YOUR RECIPES HERE

# END: Project Recipes

# Recipe to launch debugger
debug:
	${DEBUGGER} ${OUT_DIR}${EXEC}
# CHECK SYNTAX, GENERATE NO OUTPUT
# Use option -Zs to check syntax only
FILES ?=
syntax:
	${CC} ${FLAGS_COMPILER} -Zs ${FILE}

# Helps debug makefile
print:
	@echo COMPILER FLAGS: ${FLAGS_COMPILER}
	@echo LINKER FLAGS: ${FLAGS_LINKER}
	@echo BUILD DIR: ${BUILD_DIR}
	@echo OUTPUT DIR: ${OUT_DIR}
	@echo INTERMEDIATE DIR: ${INT_DIR}
	@echo SOURCE FILES: ${SOURCE_FILES}
	@echo OBJECT FILES: ${OBJ_FILES}

RM = del /S
clean:
	${RM} ${OUT_DIR}/*.*
