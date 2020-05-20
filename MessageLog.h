#ifndef MESSAGE_LOG_H
#define MESSAGE_LOG_H

#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif

typedef void (*MLLoggerFunc_t)(bool, const char*, const char*);
// Set a custom logging function to use instead of the default
void MLSetLogger(MLLoggerFunc_t logger);

// Enable/disable logging of every selector on every class
void MLSetFullLoggingEnabled(bool enabled);

typedef NS_ENUM(NSInteger, MLMethodType)
{
	MLMethodTypeAny,
	MLMethodTypeClass,
	MLMethodTypeInstance
};
// Enable selective logging
void MLEnableSelectiveLogging(MLMethodType type, const char* classRegex, const char* selectorRegex);

// Disable selective logging
void MLDisableSelectiveLogging(void);

// Log methods called by a block of code
void MLLogBlock(void(^block)(void));

#ifdef __cplusplus
}
#endif

#endif //MESSAGE_LOG_H
