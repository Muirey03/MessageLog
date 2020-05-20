@import Foundation;
#import <objc/runtime.h>
#include <string>
#include <sstream>
#include <regex.h>
#include <substrate.h>
#include <pthread.h>
#import "MessageLog.h"

static void openLogFile(void);
static void closeLogFile(void);
static void flushCaches();
static void defaultLogger(bool isCls, const char* clsName, const char* selName);

static IMP (*lookUpImpOrForwardPtr)(Class, SEL, id, bool, bool, bool) = NULL;
static FILE* logFile = NULL;
static MLLoggerFunc_t MLLoggerFunc = &defaultLogger;
static bool loggingEnabled = false;
static MLMethodType matchType = MLMethodTypeAny;
static regex_t* matchClassRegex = nullptr;
static regex_t* matchSelRegex = nullptr;
static pthread_t inspectedThread = NULL;

extern "C"
{
	void MLSetLogger(MLLoggerFunc_t logger)
	{
		MLLoggerFunc = logger;
	}

	void MLSetFullLoggingEnabled(bool enabled)
	{
		if (loggingEnabled == enabled)
			return;
		
		if (enabled)
			flushCaches();

		matchType = MLMethodTypeAny;
		if (matchClassRegex)
			delete matchClassRegex, matchClassRegex = nullptr;
		if (matchSelRegex)
			delete matchSelRegex, matchSelRegex = nullptr;
		
		if (MLLoggerFunc == &defaultLogger)
		{
			if (enabled)
			{
				//open log file for appending
				openLogFile();
			}
			else
			{
				//close log file
				closeLogFile();
			}
		}
		loggingEnabled = enabled;
	}

	void MLEnableSelectiveLogging(MLMethodType type, const char* classRegex, const char* selectorRegex)
	{
		flushCaches();

		matchType = type;
		if (classRegex)
		{
			matchClassRegex = new regex_t;
			int ret = regcomp(matchClassRegex, classRegex, REG_ICASE);
			if (ret)
				delete matchClassRegex, matchClassRegex = nullptr;
		}
		if (selectorRegex)
		{
			matchSelRegex = new regex_t;
			int ret = regcomp(matchSelRegex, selectorRegex, 0);
			if (ret)
				delete matchSelRegex, matchSelRegex = nullptr;
		}
		if (MLLoggerFunc == &defaultLogger)
			openLogFile();
		loggingEnabled = YES;
	}

	void MLDisableSelectiveLogging()
	{
		MLSetFullLoggingEnabled(false);
	}

	void MLLogBlock(void(^block)(void))
	{
		inspectedThread = pthread_self();
		MLSetFullLoggingEnabled(true);
		block();
		MLSetFullLoggingEnabled(false);
		inspectedThread = NULL;
	}
}

static void openLogFile()
{
	if (logFile) return;
	std::stringstream ss;
	ss << "/tmp/MessageLog/objcMessages~" << getprogname() << "_" << getpid() << ".txt";
	std::string filenameStr = ss.str();
	logFile = fopen(filenameStr.c_str(), "a");
	NSLog(@"[MobileLogger] Logging started to %s", filenameStr.c_str());
}

static void closeLogFile()
{
	if (!logFile) return;
	fclose(logFile);
	logFile = NULL;
}

static void defaultLogger(bool isCls, const char* clsName, const char* selName)
{
	fprintf(logFile, "%c[%s %s]\n", isCls ? '+' : '-', clsName, selName);
}

static void flushCaches()
{
	//flush caches when logging starts so we gets traces
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	_objc_flush_caches(nil);
	#pragma clang diagnostic pop
}

%hookf (IMP, lookUpImpOrForwardPtr, Class cls, SEL sel, id inst, bool initialize, bool cache, bool resolver)
{
	if (loggingEnabled && (!inspectedThread || pthread_equal(inspectedThread, pthread_self())) && inst && sel)
	{
		loggingEnabled = false;
		//don't cache anything when we're logging
		cache = false;

		bool isCls = class_isMetaClass(inst);
		const char* clsName = class_getName(inst);
		const char* selName = sel_getName(sel);

		bool match = true;
		if ((isCls && matchType == MLMethodTypeInstance) || (!isCls && matchType == MLMethodTypeClass))
			match = false;
		if (match && matchClassRegex)
			match = (regexec(matchClassRegex, clsName, 0, NULL, 0) == 0);
		if (match && matchSelRegex)
			match = (regexec(matchSelRegex, selName, 0, NULL, 0) == 0);

		if (match)
			MLLoggerFunc(isCls, clsName ?: "<null>", selName ?: "<null>");
		loggingEnabled = true;
	}
	return %orig;
}

%ctor
{
	@autoreleasepool
	{
		lookUpImpOrForwardPtr = (IMP (*)(Class, SEL, id, bool, bool, bool))MSFindSymbol(MSGetImageByName("/usr/lib/libobjc.A.dylib"), "_lookUpImpOrForward");
		%init;
	}
}
