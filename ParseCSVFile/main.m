//
//  main.m
//  ParseCSVFile
//
//  Created by kibernet on 14/5/15.
//  Copyright (c) 2015年 kibernet. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdio.h>

#define DEFAULT_EXPORT_DIRECTOR_NAME @"CSVExport"
#define DESCRIPTION_ROW_COUNT 0

#define DEFAULT_LUA_ONE_FILE_NAME @"config.lua"
#define LUA_MODULE_NAME @"module(\"Table\")"
#define LUA_KEY_NAME @"key"

#define CSV_FILE_EXTENSION @"csv"
#define FILE_CLASS_PREFIX @"C"

#define FILE_CLASS_SUFFIX @"Attribute"
#define FILE_CTRL_CLASS_SUFFIX @"AttributeManager"

#define CLASS_FILE_NAME_SUFFIX @"_attribute"
#define CLASS_FILE_CTRL_SUFFIX @"_attribute_manager"

#define CLASS_ATTRIBUTE_MANAGER_MACRO       @"__ATTRIBUTE_MANAGER_CTRL_H__"
#define CLASS_ATTRIBUTE_MANAGER_H_NAME      @"attribute_manager.h"
#define CLASS_ATTRIBUTE_MANAGER_CPP_NAME    @"attribute_manager.cpp"

#define CLASS_MEMBER_PREFIX_INT         @"m_i"
#define CLASS_MEMBER_PREFIX_FLOAT       @"m_f"
#define CLASS_MEMBER_PREFIX_BOOL        @"m_b"
#define CLASS_MEMBER_PREFIX_STRING      @"m_s"
#define CLASS_MEMBER_PREFIX_ARRAY       @"m_o"

#define TEMP_VAR_PREFIX_INT             @"i"
#define TEMP_VAR_PREFIX_FLOAT           @"f"
#define TEMP_VAR_PREFIX_BOOL            @"b"
#define TEMP_VAR_PREFIX_STRING          @"s"
#define TEMP_VAR_PREFIX_ARRAY           @"o"

#define CLASS_OBJECT @"object"

#define CLASS_INCLUDE_FILE_LIST         \
@"#include <string>\n\
#include \"../common/csv_array.h\"\n\
#include <sys/types.h>\n\n"

#define CLASS_MANAGER_INCLUDE_FILE_LIST \
@"#include <map>\n\
#include <stdexcept>\n\
#include <vector>\n\
#include \"../common/csv_parse.h\"\n\
#include \"../common/csv_array.h\"\n\
#ifdef YANGMAN_CLIENT\n\
#include \"config.h\"\n\
#include \"attribute_manager.h\"\n\
#else\n\
#include <common/base/config.h>\n\
#endif\n\n"

#define VERSION @"1.0.0.1"

#define FILE_MODE_LUA       @"lua"
#define FILE_MODE_CLASS     @"class"

#define COMMAND_VERSION         @"-version"
#define COMMAND_HELP            @"-help"
#define COMMAND_RESOURCEPATH    @"-r"
#define COMMAND_OUTPUTPATH      @"-o"
#define COMMAND_MODE            @"-m"
#define COMMAND_AFILE           @"-afile"
#define COMMAND_FILES           @"-files"

void parseCSVToClassFile();
void parseCSVToLuaFile();

void version() {
    NSLog(@"\nParseCSVFile version %@", VERSION);
}

void usage() {
NSLog(@"usage: ParseCSVFile");
NSLog(@"                                                                \n\
[-version] [-help] [-r <resourcePath>] [-o <outputPath>]                 \n\
[-m <mode(lua:-afile/-files,c++)>]                                      \n\
      ");

NSLog(@"                                                                \n\
The most commonly used ParseCSVFile commands are:                       \n\
-version    show version info                                           \n\
-help       show help usage                                             \n\
-r          input CSV file resource directory                           \n\
-o          output file directory                                       \n\
-m          lua or c++                                                  \n\
-afile      only for -mode lua, -afile:all out put in one file          \n\
-files      only for -mode lua, -files:all out put in each file         \n\
  ");
}

typedef enum : NSUInteger {
    OUTPUT_LUA,         //输出LUA文件
    OUTPUT_CLASS,       //输出C++类文件
} FILE_MODE;

//该枚举只在输出位LUA时才可用
typedef enum : NSUInteger {
    IN_ONE_FILE,        //输出到一个文件中
    IN_EACH_FILE,       //输出到单独的文件中
} FILE_OUPUT_MODE;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        //默认为C++输出模式
        FILE_OUPUT_MODE fileOutputMode = IN_EACH_FILE;
        FILE_MODE fileMode = OUTPUT_CLASS;
        
        NSDictionary *dataTypeDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     @"int8_t",         @"int8_t",
                                     @"int16_t",        @"int16_t",
                                     @"int32_t",        @"int32_t",
                                     @"int64_t",        @"int64_t",
                                     @"u_int8_t",       @"u_int8_t",
                                     @"u_int16_t",      @"u_int16_t",
                                     @"u_int32_t",      @"u_int32_t",
                                     @"u_int64_t",      @"u_int64_t",
                                     @"int8_t",         @"char",
                                     @"int16_t",        @"short",
                                     @"int32_t",        @"int",
                                     @"int64_t",        @"long",
                                     @"u_int8_t",       @"unsigned char",
                                     @"u_int16_t",      @"unsigned short",
                                     @"u_int32_t",      @"unsigned int",
                                     @"u_int64_t",      @"unsigned long",
                                     @"u_int8_t",       @"u_char",
                                     @"u_int16_t",      @"u_short",
                                     @"u_int32_t",      @"u_int",
                                     @"u_int16_t",      @"ushort",
                                     @"u_int32_t",      @"uint",
                                     @"int8_t",         @"int8",
                                     @"int16_t",        @"int16",
                                     @"int32_t",        @"int32",
                                     @"int64_t",        @"int64",
                                     @"u_int8_t",       @"uint8",
                                     @"u_int16_t",      @"uint16",
                                     @"u_int32_t",      @"uint32",
                                     @"u_int64_t",      @"uint64",
                                     @"float",          @"float",
                                     @"float",          @"float_t",
                                     @"double",         @"double",
                                     @"double",         @"double_t",
                                     @"bool",           @"bool",
                                     @"string",         @"string",
                                     @"CCsvArray",      @"array",
                                     nil];
        
        NSString *currentPath = [[NSString stringWithUTF8String:argv[0]] stringByDeletingLastPathComponent];
        
        NSString *resPath = nil;    //CSV文件目录
        NSString *desPath = nil;    //输出文件目录
        
        //默认不提供参数,则在当前命令行目录查找CSV文件,并且输出路径为该路径下的 DEFAULT_EXPORT_DIRECTOR_NAME 目录
        resPath = currentPath;
        desPath = [currentPath stringByAppendingFormat:@"/%@", DEFAULT_EXPORT_DIRECTOR_NAME];

        NSMutableArray *argcArray = [NSMutableArray array];
        for (int32_t i = 1; i < argc; ++i) {
            [argcArray addObject:[NSString stringWithUTF8String:argv[i]]];
        }
        
        NSUInteger count = [argcArray count];
        NSString *arvString = nil;
        for (NSUInteger i = 0; i < count; ++i) {
            arvString = [argcArray objectAtIndex:i];
            NSString *key = [arvString lowercaseString];
            if ([key isEqualToString:COMMAND_VERSION]) {
                version();
                return 1;
            }
            else if ([key isEqualToString:COMMAND_HELP]) {
                usage();
                return 1;
            }
            else if ([key isEqualToString:COMMAND_RESOURCEPATH]) {
                if (count > i + 1) {
                    resPath = [argcArray objectAtIndex:i+1];
                }
            }
            else if ([key isEqualToString:COMMAND_MODE]) {
                if (count > i + 1) {
                    NSString *mode = [argcArray objectAtIndex:i+1];
                    if ([mode isEqualToString:FILE_MODE_LUA]) {
                        fileMode = OUTPUT_LUA;
                    }
                    else if ([mode isEqualToString:FILE_MODE_CLASS]) {
                        fileMode = OUTPUT_CLASS;
                    }
                    else {
                        NSLog(@"Invalid ouput mode %@!\n Enter file mode: %@ or %@, and try again!", mode, FILE_MODE_LUA, FILE_MODE_CLASS);
                        return 1;
                    }
                }
            }
            else if ([key isEqualToString:COMMAND_OUTPUTPATH]) {
                if (count > i + 1) {
                    desPath = [argcArray objectAtIndex:i+1];
                }
            }
            else if ([key isEqualToString:COMMAND_AFILE]) {
                fileOutputMode = IN_ONE_FILE;
            }
            else if ([key isEqualToString:COMMAND_FILES]) {
                fileOutputMode = IN_EACH_FILE;
            }
        }
        
        NSLog(@"Search CSV file in path:%@", resPath);
        NSLog(@"Output path:%@", desPath);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *removeDesFileError;
        [fileManager removeItemAtPath:desPath error:&removeDesFileError];
        
        NSError *error = nil;
        NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resPath error:&error];
        if (error) {
            NSLog(@"Get CSV file list Error!");
            return 1;
        }
        
        if ([fileArray count] > 0) {
            error = nil;
            [fileManager createDirectoryAtPath:desPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"Create output directory faild\n%@", desPath);
                return 1;
            }
        }
        else {
            NSLog(@"Not find CSV file!\n%@", resPath);
            return 1;
        }
        
        NSString *firstTableIndent  = @"    ";
        NSString *secondTableIndent = @"        ";
        NSString *thirdTableIndent  = @"            ";
        
        NSUInteger _count_ = 0;
        
        
        NSMutableString *oneLuaFileContent = [[NSMutableString alloc] init];
        [oneLuaFileContent appendFormat:@"%@\n\n", LUA_MODULE_NAME];
        
        NSMutableString *managerCtrlHContent = [[NSMutableString alloc] init];
        [managerCtrlHContent appendFormat:@"#ifndef %@\n", CLASS_ATTRIBUTE_MANAGER_MACRO];
        [managerCtrlHContent appendFormat:@"#define %@\n\n", CLASS_ATTRIBUTE_MANAGER_MACRO];
        [managerCtrlHContent appendString:@"#include \"singleton.hpp\"\n\n"];
        
        
        NSMutableString *managerCtrlCPPContent = [[NSMutableString alloc] init];
        [managerCtrlCPPContent appendString:@"#ifdef YANGMAN_CLIENT\n\n"];
        [managerCtrlCPPContent appendFormat:@"#include \"%@\"\n\n", CLASS_ATTRIBUTE_MANAGER_H_NAME];
        
        for (NSString *file in fileArray) {
            NSString *fileExtension = [[file pathExtension] lowercaseString];
            
            @autoreleasepool {
                if ([fileExtension isEqualToString:CSV_FILE_EXTENSION]) {
                    
                    ++_count_;
                    
                    NSLog(@"---------------------->%@", file);
                    NSError *readFileError;
                    NSString *filePath = [NSString stringWithFormat:@"%@/%@", resPath, file];
                    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:&readFileError];
                    if (readFileError) {
                        NSLog(@"Read CSV File Error!---:%@\n%@", file, readFileError.localizedDescription);
                        return 1;
                    }
    //                NSLog(@"----:%@", fileContent);
                    NSArray *fileContentLineArray = [fileContent componentsSeparatedByString:@"\r"];
                    NSUInteger fileContentLineCount = [fileContentLineArray count];
                    if ( fileContentLineCount < DESCRIPTION_ROW_COUNT) {
                        NSLog(@"CSV File must have  three lines!---:%@", file);
                        return 1;
                    }
                    
                    NSString *fileNameWithOutExt = [[file stringByDeletingPathExtension] capitalizedString];
                    
                    NSString *dataNameLine = [fileContentLineArray objectAtIndex:1];
                    NSString *dataTypeLine = [[fileContentLineArray objectAtIndex:2] lowercaseString];
                    
                    dataNameLine = [dataNameLine stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    dataNameLine = [dataNameLine stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    dataTypeLine = [dataTypeLine stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    dataTypeLine = [dataTypeLine stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    
                    
                    NSArray *dataNameArray = [dataNameLine componentsSeparatedByString:@","];
                    NSArray *dataTypeArray = [dataTypeLine componentsSeparatedByString:@","];
                    
                    NSUInteger dataNameCount = [dataNameArray count];
                    NSUInteger dataTypeCount = [dataTypeArray count];
                    
                    if (dataNameCount != dataTypeCount) {
                        NSLog(@"CSV name or type field may be empty!:%@", file);
                        return 1;
                    }
                    
                    if (fileMode == OUTPUT_CLASS) {
                        //output C++ class
                        
                        
                        NSString *attributeClassName = [NSString stringWithFormat:@"%@%@%@", FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX];
                        NSString *attributeCtrlClassName = [NSString stringWithFormat:@"%@%@%@", FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        
                        NSString *attributeClassFileHPP = [[NSString stringWithFormat:@"%@%@.h", fileNameWithOutExt, CLASS_FILE_NAME_SUFFIX] lowercaseString];
                        NSString *crtlClassFileHPP = [[NSString stringWithFormat:@"%@%@.h", fileNameWithOutExt, CLASS_FILE_CTRL_SUFFIX] lowercaseString];
//                        NSString *crtlClassFileCPP = [[NSString stringWithFormat:@"%@%@.cpp", fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX] lowercaseString];
                        
                        NSString *attributeClassDefine = [[NSString stringWithFormat:@"%@_HPP", attributeClassName] uppercaseString];
                        NSString *attributeCtrlClassDefine = [[NSString stringWithFormat:@"%@_HPP", attributeCtrlClassName] uppercaseString];
                        
                        NSMutableString *classContentHPP = [[NSMutableString alloc] init];
                        NSMutableString *classCtrlContentHPP = [[NSMutableString alloc] init];
//                        NSMutableString *classCtrlContentCPP = [[NSMutableString alloc] init];
                        
                        
                        //Attribute Class File HPP
                        
                        //HEADER
                        [classContentHPP appendFormat:@"#ifndef %@\n", attributeClassDefine];
                        [classContentHPP appendFormat:@"#define %@\n\n", attributeClassDefine];
                        
                        //INCLUDE
                        [classContentHPP appendString:CLASS_INCLUDE_FILE_LIST];
                        [classContentHPP appendFormat:@"class %@ {\n", attributeClassName];
                        [classContentHPP appendString:@"public:\n\n"];
                        
                        /*
                        //构造方法
                        [classContentHPP appendFormat:@"%@%@() {\n", firstTableIndent, attributeClassName];
                        
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = \"\";\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = .0f;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = false;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@%@%@ = 0;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name];
                            }
                        }
                        
                        [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //构造方法二
                        [classContentHPP appendFormat:@"%@%@(const %@ &%@) {\n", firstTableIndent, attributeClassName, attributeClassName, CLASS_OBJECT];
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_ARRAY, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_ARRAY, name];
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_STRING, name];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_FLOAT, name];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_BOOL, name];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_INT, name];
                            }
                        }
                        [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //重载复制操作符
                        [classContentHPP appendFormat:@"%@const %@ & operator=(const %@ &%@) {\n", firstTableIndent, attributeClassName, attributeClassName, CLASS_OBJECT];
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_ARRAY, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_ARRAY, name];
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_STRING, name];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_FLOAT, name];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_BOOL, name];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@%@%@ = %@.%@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name, CLASS_OBJECT, CLASS_MEMBER_PREFIX_INT, name];
                            }
                        }
                        [classContentHPP appendFormat:@"%@return *this;\n", secondTableIndent];
                        [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---clear
                        [classContentHPP appendFormat:@"%@ void clear() {\n", firstTableIndent];
                        
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = \"\";\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = .0f;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@%@%@ = false;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@%@%@ = 0;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name];
                            }
                        }
                        
                        [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        */
                        
                        //function---get and set
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                [classContentHPP appendFormat:@"%@void set%@(const std::string& %@%@) {\n", firstTableIndent, name, TEMP_VAR_PREFIX_ARRAY, name];
                                [classContentHPP appendFormat:@"%@%@%@ = %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_ARRAY, name, TEMP_VAR_PREFIX_ARRAY, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                                
                                [classContentHPP appendFormat:@"%@const %@& get%@() const {\n", firstTableIndent, dataType, name];
                                [classContentHPP appendFormat:@"%@return %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_ARRAY, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@void set%@(std::%@ %@%@) {\n", firstTableIndent, name, dataType, TEMP_VAR_PREFIX_STRING, name];
                                [classContentHPP appendFormat:@"%@%@%@ = %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name, TEMP_VAR_PREFIX_STRING, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                                
                                [classContentHPP appendFormat:@"%@const std::%@& get%@() const {\n", firstTableIndent, dataType, name];
                                [classContentHPP appendFormat:@"%@return %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_STRING, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@void set%@(%@ %@%@) {\n", firstTableIndent, name, dataType, TEMP_VAR_PREFIX_FLOAT, name];
                                [classContentHPP appendFormat:@"%@%@%@ = %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name, TEMP_VAR_PREFIX_FLOAT, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                                
                                [classContentHPP appendFormat:@"%@%@ get%@() const {\n", firstTableIndent, dataType, name];
                                [classContentHPP appendFormat:@"%@return %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_FLOAT, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@void set%@(%@ %@%@) {\n", firstTableIndent, name, dataType, TEMP_VAR_PREFIX_BOOL, name];
                                [classContentHPP appendFormat:@"%@%@%@ = %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name, TEMP_VAR_PREFIX_BOOL, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                                
                                [classContentHPP appendFormat:@"%@%@ get%@() const {\n", firstTableIndent, dataType, name];
                                [classContentHPP appendFormat:@"%@return %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_BOOL, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@void set%@(%@ i%@) {\n", firstTableIndent, name, dataType, name];
                                [classContentHPP appendFormat:@"%@%@%@ = i%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                                
                                [classContentHPP appendFormat:@"%@%@ get%@() const {\n", firstTableIndent, dataType, name];
                                [classContentHPP appendFormat:@"%@return %@%@;\n", secondTableIndent, CLASS_MEMBER_PREFIX_INT, name];
                                [classContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                            }
                            
                            
                        }
                        
                        //CLASS MEMBER
                        [classContentHPP appendString:@"private:\n"];
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"]) {
                                [classContentHPP appendFormat:@"%@%@ %@%@;\n", firstTableIndent, dataType, CLASS_MEMBER_PREFIX_ARRAY, name];
                            }
                            else if ([dataType isEqualToString:@"string"]) {
                                [classContentHPP appendFormat:@"%@std::%@ %@%@;\n", firstTableIndent, dataType, CLASS_MEMBER_PREFIX_STRING, name];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classContentHPP appendFormat:@"%@%@ %@%@;\n", firstTableIndent, dataType, CLASS_MEMBER_PREFIX_FLOAT, name];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classContentHPP appendFormat:@"%@%@ %@%@;\n", firstTableIndent, dataType, CLASS_MEMBER_PREFIX_BOOL, name];
                            }
                            else {
                                [classContentHPP appendFormat:@"%@%@ %@%@;\n", firstTableIndent, dataType, CLASS_MEMBER_PREFIX_INT, name];
                            }
                            
                            
                        }

                        //BOTTOM
                        [classContentHPP appendString:@"};\n\n"];
                        [classContentHPP appendFormat:@"#endif // %@\n\n", attributeClassDefine];
    //                    NSLog(@"%@", classContentHPP);
                        
                        [classContentHPP writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, attributeClassFileHPP] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        
                        NSLog(@"%@", attributeClassFileHPP);
                        
                        
                        //Attribute Class Ctrl File HPP
                        
                        [classCtrlContentHPP appendFormat:@"#ifndef %@\n", attributeCtrlClassDefine];
                        [classCtrlContentHPP appendFormat:@"#define %@\n\n", attributeCtrlClassDefine];
                        
                        //INCLUDE
                        [classCtrlContentHPP appendString:CLASS_MANAGER_INCLUDE_FILE_LIST];
                        [classCtrlContentHPP appendFormat:@"#include \"%@\"\n\n", attributeClassFileHPP];
                        
                        //HEADER
                        [classCtrlContentHPP appendFormat:@"class %@%@ : public IConfig {\n", fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        [classCtrlContentHPP appendString:@"public:\n\n"];
                        
                        //function---init
                        [classCtrlContentHPP appendFormat:@"%@virtual bool init(void* params = nullptr) {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return load(std::string((char*)params));\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---makeNewObject
                        [classCtrlContentHPP appendFormat:@"%@virtual std::shared_ptr<IConfig> makeNewObject() {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return std::make_shared<%@%@>();\n", secondTableIndent, fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---load
                        [classCtrlContentHPP appendFormat:@"%@bool load(const std::string& strPath) {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@CSVParse csvParser;\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@if ( !csvParser.openFile(strPath.c_str()) ) {\n", secondTableIndent];
                        NSString * openError = [NSString stringWithFormat:@"Open CSV file failed!---%@", file];
                        [classCtrlContentHPP appendFormat:@"%@throw std::runtime_error(\"%@\");\n", thirdTableIndent, openError];
                        [classCtrlContentHPP appendFormat:@"%@}\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@for ( int row = %d; row < csvParser.getRows(); ++row ) {\n", secondTableIndent, DESCRIPTION_ROW_COUNT];
                        [classCtrlContentHPP appendFormat:@"%@%@ oAttribute;\n", thirdTableIndent, attributeClassName];
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if ([dataType isEqualToString:@"CCsvArray"] || [dataType isEqualToString:@"string"]) {
                                [classCtrlContentHPP appendFormat:@"%@oAttribute.set%@(csvParser.getData(row, %lu));\n", thirdTableIndent, name, (unsigned long)i];
                            }
                            else if ([dataType isEqualToString:@"float"] || [dataType isEqualToString:@"double"]) {
                                [classCtrlContentHPP appendFormat:@"%@oAttribute.set%@(csvParser.getFloatData(row, %lu));\n", thirdTableIndent, name, (unsigned long)i];
                            }
                            else if ([dataType isEqualToString:@"bool"]) {
                                [classCtrlContentHPP appendFormat:@"%@oAttribute.set%@(csvParser.getBoolData(row, %lu));\n", thirdTableIndent, name, (unsigned long)i];
                            }
                            else {
                                [classCtrlContentHPP appendFormat:@"%@oAttribute.set%@(csvParser.getIntData(row, %lu));\n", thirdTableIndent, name, i];
                            }
                            
                            
                        }
                        [classCtrlContentHPP appendFormat:@"%@m%@.insert(std::make_pair(csvParser.getIntData(row, 0), oAttribute));\n", thirdTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@}\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return true;\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---reload
                        [classCtrlContentHPP appendFormat:@"%@bool reload(const std::string& strPath) {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@m%@.clear();\n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@return load(strPath);\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---get
                        [classCtrlContentHPP appendFormat:@"%@const %@%@%@& get(int iId) {\n", firstTableIndent, FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@std::map<int, %@%@%@>::iterator pGuard = m%@.find(iId);\n", secondTableIndent, FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@if (pGuard == m%@.end()) {\n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        NSString *getAttributeError = [NSString stringWithFormat:@"Invalid Config ID in file %@", file];
                        [classCtrlContentHPP appendFormat:@"%@throw std::runtime_error(\"%@\");\n", thirdTableIndent, getAttributeError];
                        [classCtrlContentHPP appendFormat:@"%@}\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return pGuard->second;\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---has
                        [classCtrlContentHPP appendFormat:@"%@bool has(int iId) {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@std::map<int, %@%@%@>::iterator pGuard = m%@.find(iId);\n", secondTableIndent, FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@if (pGuard == m%@.end()) {\n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@return false;\n", thirdTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return true;\n", secondTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---getAttribute
                        [classCtrlContentHPP appendFormat:@"%@const %@%@%@* get%@(int iId) {\n", firstTableIndent, FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX, FILE_CLASS_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@auto it = m%@.find(iId);\n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@return it == m%@.end() ? nullptr : &(it->second); \n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //function---size
                        [classCtrlContentHPP appendFormat:@"%@int size() {\n", firstTableIndent];
                        [classCtrlContentHPP appendFormat:@"%@return m%@.size();\n", secondTableIndent, CLASS_FILE_NAME_SUFFIX];
                        [classCtrlContentHPP appendFormat:@"%@}\n\n", firstTableIndent];
                        
                        //CLASS MEMBER
                        [classCtrlContentHPP appendFormat:@"public:\n"];
                        [classCtrlContentHPP appendFormat:@"%@std::map<int, %@%@%@> m%@;\n", firstTableIndent, FILE_CLASS_PREFIX, fileNameWithOutExt, FILE_CLASS_SUFFIX, CLASS_FILE_NAME_SUFFIX];
                        
                        //BOTTOM
                        [classCtrlContentHPP appendString:@"};\n\n"];
//                        [classCtrlContentHPP appendFormat:@"#define %@%@Ctrl Singleton<%@%@> ::Instance()\n\n", fileNameWithOutExt, FILE_CLASS_SUFFIX, fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        
                        
                        [managerCtrlHContent appendFormat:@"#define %@%@Ctrl Singleton<%@%@> ::Instance()\n\n", fileNameWithOutExt, FILE_CLASS_SUFFIX, fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        
                        [classCtrlContentHPP appendFormat:@"#endif // %@", attributeCtrlClassDefine];
                        
    //                    NSLog(@"%@", classCtrlContentHPP);
                        [classCtrlContentHPP writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, crtlClassFileHPP] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        
                        NSLog(@"%@", crtlClassFileHPP);
                        
                        //Attribute Class Ctrl File CPP
                        /*
                        [classCtrlContentCPP appendFormat:@"#include \"%@\"\n", crtlClassFileHPP];
                        [classCtrlContentCPP appendFormat:@"SINGLETON_INITILIAZE(%@%@%@);", FILE_CLASS_SUFFIX, fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                        [classCtrlContentCPP writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, crtlClassFileCPP] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    //                    NSLog(@"%@", classCtrlContentCPP);
                        NSLog(@"%@", crtlClassFileCPP);
                        */
                        
                        [managerCtrlCPPContent appendFormat:@"SINGLETON_INITILIAZE(%@%@);\n", fileNameWithOutExt, FILE_CTRL_CLASS_SUFFIX];
                    }
                    else {
                        //output lua table
                        
                        NSString *eachLuaFileName = nil;
                        if (fileOutputMode == IN_EACH_FILE) {
                            eachLuaFileName = [NSString stringWithFormat:@"%@.lua", fileNameWithOutExt];
                        }
                        
                        [oneLuaFileContent appendFormat:@"%@ = {\n", fileNameWithOutExt];
                        
                        [oneLuaFileContent appendFormat:@"%@ = {", LUA_KEY_NAME];
                        
                        
                        NSString *firstKeyName = nil;
                        NSString *firstKeyType = nil;
                        
                        for (NSUInteger i = 0; i < dataTypeCount; ++i) {
                            NSString *type = [dataTypeArray objectAtIndex:i];
                            NSString *name = [dataNameArray objectAtIndex:i];
                            
                            NSString *dataType = [dataTypeDic objectForKey:type];
                            if (dataType == nil) {
                                NSLog(@"Check list of data type! Not found type:%@!", type);
                                return 1;
                            }
                            
                            if (i == 0) {
                                firstKeyName = name;
                                firstKeyType = type;
                            }
                            
                            if (i == dataTypeCount - 1) {
                                [oneLuaFileContent appendFormat:@"%@=%lu", name, i+1];
                            }
                            else {
                                [oneLuaFileContent appendFormat:@"%@=%lu,", name, i+1];
                            }
                        }
                        [oneLuaFileContent appendString:@"},\n"];
                        
                        if (firstKeyName) {
                            //至少存在一个key,默认第一个Key为唯一标识
                            for (NSUInteger j = DESCRIPTION_ROW_COUNT; j < fileContentLineCount - 1; ++j) {
                                NSString *rowLineContent = [fileContentLineArray objectAtIndex:j];
                                rowLineContent = [rowLineContent stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                                rowLineContent = [rowLineContent stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                                NSArray *contentRowArray = [rowLineContent componentsSeparatedByString:@","];
                                
                                if ([firstKeyType isEqualTo:@"string"]) {
                                    [oneLuaFileContent appendFormat:@"[\"%@\"] = {", [contentRowArray objectAtIndex:0]];
                                }
                                else {
                                    [oneLuaFileContent appendFormat:@"[%@] = {", [contentRowArray objectAtIndex:0]];
                                }
                                
                                for (NSUInteger m = 0; m < dataTypeCount; ++m) {
                                    NSString *type = [dataTypeArray objectAtIndex:m];
                                    NSString *dataType = [dataTypeDic objectForKey:type];
                                    
                                    if ([dataType isEqualTo:@"string"]) {
                                        [oneLuaFileContent appendFormat:@"\"%@\"", [contentRowArray objectAtIndex:m]];
                                    }
                                    else {
                                        [oneLuaFileContent appendFormat:@"%@", [contentRowArray objectAtIndex:m]];
                                    }
                                    
                                    if (m != dataTypeCount - 1) {
                                        [oneLuaFileContent appendString:@", "];
                                    }
                                    
                                }
                                
                                [oneLuaFileContent appendString:@"},\n"];
                            }
                        }
                        
                        [oneLuaFileContent appendString:@"}\n\n"];
                        
                        if (fileOutputMode == IN_EACH_FILE) {
                            [oneLuaFileContent writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, eachLuaFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                            
                            [oneLuaFileContent setString:@""];
                            [oneLuaFileContent appendFormat:@"%@\n\n", LUA_MODULE_NAME];
                        }
                    }
                }
            }
        }
        
        if ( fileMode == OUTPUT_LUA && fileOutputMode == IN_ONE_FILE) {
            [oneLuaFileContent writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, DEFAULT_LUA_ONE_FILE_NAME] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        if (fileMode == OUTPUT_CLASS) {
            [managerCtrlHContent appendFormat:@"#endif // %@", CLASS_ATTRIBUTE_MANAGER_MACRO];
            [managerCtrlHContent writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, CLASS_ATTRIBUTE_MANAGER_H_NAME] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            [managerCtrlCPPContent appendString:@"\n#endif\n"];
            [managerCtrlCPPContent writeToFile:[NSString stringWithFormat:@"%@/%@", desPath, CLASS_ATTRIBUTE_MANAGER_CPP_NAME] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            NSLog(@"---------------------->attribute_manager macros");
            NSLog(@"%@", CLASS_ATTRIBUTE_MANAGER_H_NAME);
            NSLog(@"%@", CLASS_ATTRIBUTE_MANAGER_CPP_NAME);
            
        }
        
        NSLog(@"Work down!---%lu files!", _count_);
    }
    return 0;
}

void parseCSVToClassFile() {
    
}
void parseCSVToLuaFile() {
    
}
