include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = cassowarykittest
BUNDLE_NAME = cassowarykittest

cassowarykittest_INCLUDE_DIRS = -I./../cassowary -I./../../tools-xctest 
cassowarykittest_LDFLAGS = -v
cassowarykittest_OBJC_FILES = \
CSWConstraintTests.m \
CSWLinearExpressionTests.m \
CSWSimplexSolverTests.m \
CSWStrengthTests.m \
CSWSymbolicWeightTests.m \
CSWTableauTests.m \
CSWVariableTests.m

ADDITIONAL_LIB_DIRS= -L ./../cassowary/obj
ADDITIONAL_TOOL_LIBS = -lxctest -lCassowaryKit

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble