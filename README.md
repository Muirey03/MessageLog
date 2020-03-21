# MessageLog
### A simple library to log all objc_msgSend calls

MessageLog is a small library to log Objective-C method calls. It can be used to either log all messages, or to filter messages based off regular expressions, and even to implement your own logging functions. The default log location is `/tmp/objcMessages~<processname>_<pid>.txt`.

## Usage

First copy `MessageLog.h` to `$THEOS/include`, then copy `usr/lib/libmessagelog.dylib` to `$THEOS/lib`. You can then add `XXX_LIBRARIES = messagelog` to the Makefile of any project you want to use it, and `#import <MessageLog.h>` to source files you want to use it in. Ensure the library is installed on any devices you try to use it on.

### Enabling logs for all methods:

	void MLSetFullLoggingEnabled(bool enabled);
To enable logs for all methods, call `MLSetFullLoggingEnabled(true);`. Call `MLSetFullLoggingEnabled(false);` afterwards to halt the logs.


### Enabling logs based of regular expressions:
To filter logs by regex, use:

	void MLEnableSelectiveLogging(MLMethodType type, const char* classRegex, const char* selectorRegex);
`type` can be either `MLMethodTypeAny`, `MLMethodTypeClass` or `MLMethodTypeInstance`. Use `MLMethodTypeAny` if you do not want to filter by method type, `MLMethodTypeClass` if you want to only log class methods, and `MLMethodTypeInstance` if you want to only log instance methods.

`classRegex` should be set to a regular expression for which to filter the class by. Only classes matching this expression will be logged. Set this to `NULL` if you do not want to filter by class.

`selectorRegex` should be set to a regular expression for which to filter the selector by. Only selectors matching this expression will be logged. Set this to `NULL` if you do not want to filter by selector.

`MLDisableSelectiveLogging();` should be called to disable the logging once you are done.


### Using custom loggers:
Sometimes, it will be desirable to use custom logging logic, MessageLog makes this easy with the `MLSetLogger` function:

	void MLSetLogger(MLLoggerFunc_t logger);
`logger` should be a function of type `MLLoggerFunc_t`:

	typedef void (*MLLoggerFunc_t)(bool, const char*, const char*);
where the arguments are:

	bool isClassMethod, const char* className, const char* selectorName

Here is an example usage:

	void customLogger(bool isClassMethod, const char* className, const char* selectorName)
	{
		NSLog(@"[MyTweak] %c[%s %s]", isClassMethod ? '+' : '-', className, selectorName);
	}


## Credits
Feel free to follow me on Twitter [@Muirey03](https://twitter.com/muirey03). If you have any contributions you want to make to this, please submit a Pull Request.
