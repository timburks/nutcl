/*!
@file Tcl.m
@discussion Objective-C wrapper for the Tcl interpreter.
@copyright Copyright (c) 2008 Neon Design Technology, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import <Foundation/Foundation.h>
#import <readline/readline.h>
//#import <editline/readline.h>
#import <tcl.h>

static void freeObjC(Tcl_Obj *objPtr)
{
    id object = objPtr->internalRep.otherValuePtr;
    [object release];
}

static void dupObjC(Tcl_Obj *srcPtr, Tcl_Obj *dupPtr)
{
    dupPtr->internalRep.otherValuePtr = srcPtr->internalRep.otherValuePtr;
    id object = srcPtr->internalRep.otherValuePtr;
    [object retain];
}

static void updateStringObjC (Tcl_Obj *objPtr)
{
    char *string;
    int length = asprintf(&string, "obj-%p", objPtr->internalRep.otherValuePtr);
    if (!length) {
        NSLog(@"out of memory");
        exit(-1);
    }
    length++;
    objPtr->bytes = Tcl_Alloc(length);
    strcpy(objPtr->bytes, string);
    objPtr->length = length;
    free(string);
}

static Tcl_ObjType tclObjCType =
{
    "object",                                     /* name */
    freeObjC,                                     /* freeIntRepProc */
    dupObjC,                                      /* dupIntRepProc */
    updateStringObjC,                             /* updateStringProc */
    NULL                                          /* setFromAnyProc */
};

// The TclCommand is the base class for commands to be added to the interpreter.
@interface TclCommand : NSObject
{
}

// override main: to implement a Tcl Command.
- (id) main:(NSArray *) arguments;
@end

@implementation TclCommand
- (id) main:(NSArray *) arguments
{
    [NSException raise:@"InvalidTclCommand"
        format:@"Please inherit from the TclCommand class and override main: to create command handlers."];
    return nil;
}

@end

// Create one of these to get a Tcl interpreter.
@interface TclInterpreter : NSObject
{
    Tcl_Interp *interp;
}

@end

//typedef int (Tcl_ObjCmdProc) _ANSI_ARGS_((ClientData clientData,
//Tcl_Interp *interp, int objc, struct Tcl_Obj * CONST * objv));

int TclCommandHandler(ClientData clientData, Tcl_Interp *interp, int objc, struct Tcl_Obj *objv[])
{
    NSMutableArray *arguments = [NSMutableArray array];
    int i;
    for(i = 0; i < objc; i++) {
        Tcl_Obj *obj = objv[i];
        if (obj->typePtr == &tclObjCType) {
            //NSLog(@"passing object as argument %d", i);
            [arguments addObject:obj->internalRep.otherValuePtr];
        }
        else if (obj->typePtr == Tcl_GetObjType("int")) {
            int argInt;
            Tcl_GetIntFromObj(interp, obj, &argInt);
            [arguments addObject:[NSNumber numberWithInt:argInt]];
        }
        else if (obj->typePtr == Tcl_GetObjType("double")) {
            double argDouble;
            Tcl_GetDoubleFromObj(interp, obj, &argDouble);
            [arguments addObject:[NSNumber numberWithDouble:argDouble]];
        }
        else {
            int argLength;
            const char *argString = Tcl_GetStringFromObj(obj, &argLength);
            //NSLog(@"passing string %s as argument %d", argString, i);
            [arguments addObject:[NSString stringWithCString:argString encoding:NSUTF8StringEncoding]];
        }
    }
    TclCommand *command = (TclCommand *) clientData;
    @try
    {
        id result = [command main:arguments];
        if ([result isKindOfClass:[NSString class]]) {
            Tcl_SetResult(interp, (char *) [result cStringUsingEncoding:NSUTF8StringEncoding], TCL_VOLATILE);
        }
        else if ([result isKindOfClass:[NSNumber class]]) {
            const char *typeCode = [result objCType];
            //NSLog(@"converting number of type %s", typeCode);
            if (!strcmp(typeCode, "i")) {
                Tcl_Obj *tclObj = Tcl_NewIntObj([result intValue]);
                Tcl_SetObjResult(interp, tclObj);
            }
            else {
                Tcl_Obj *tclObj = Tcl_NewDoubleObj([result doubleValue]);
                Tcl_SetObjResult(interp, tclObj);
            }
        }
        else {
            //NSLog(@"returning object as an objc object: %@", [result description]);
            Tcl_Obj *tclObj = Tcl_NewObj();
            tclObj->typePtr = &tclObjCType;
            tclObj->internalRep.otherValuePtr = [result retain];
            tclObj->bytes = 0;
            tclObj->length = 0;
            Tcl_SetObjResult(interp, tclObj);
        }
        return TCL_OK;
    }
    @catch(id exception) {
        return TCL_ERROR;
    }
}

void TclCommandRelease(ClientData clientData)
{
    TclCommand *command = (TclCommand *) clientData;
    [command release];
}

@implementation TclInterpreter

- (TclInterpreter *) init
{
    [super init];
    interp = Tcl_CreateInterp();
    Tcl_RegisterObjType(&tclObjCType);
    return self;
}

- (void) dealloc
{
    Tcl_DeleteInterp(interp);
    [super dealloc];
}

- (NSString *) eval:(NSString *) script
{
    int resultCode = Tcl_Eval(interp, [script cStringUsingEncoding:NSUTF8StringEncoding]);
    switch (resultCode) {
        case TCL_OK:
        {
            return [NSString stringWithCString:Tcl_GetStringResult(interp) encoding:NSUTF8StringEncoding];
        }
        case TCL_ERROR:
        {
            return  [NSString stringWithFormat:@"error: %s", Tcl_GetStringResult(interp)];
        }
        default:
        {
            return [NSString stringWithFormat:@"result code: %d", resultCode];
        }
    }
}

- (int) addCommand:(TclCommand *) handler withName:(NSString *) name
{
    [handler retain];
    Tcl_CreateObjCommand(interp,
        [name cStringUsingEncoding:NSUTF8StringEncoding], TclCommandHandler,
        (ClientData) handler, (Tcl_CmdDeleteProc *) TclCommandRelease);
}

- (int) interact
{
    printf("Tcl Shell.\n");
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        char *prompt = ("Tcl> ");
        char *line = readline(prompt);
        if (line && *line)
            add_history(line);
        if(!line || !strcmp(line, "quit") || !strcmp(line, "exit")) {
            break;
        }
        else {
            id result = [self eval:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]];
            printf("%s\n", [result cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        [pool release];
    } while(1);
    return 0;
}

- (NSString *) types
{
    Tcl_Obj *tclObj = Tcl_NewObj();
    Tcl_AppendAllObjTypes(interp, tclObj);
    int argLength;
    const char *argString = Tcl_GetStringFromObj(tclObj, &argLength);
    return [NSString stringWithCString:argString encoding:NSUTF8StringEncoding];
}

- (id) valueForKey:(NSString *) key
{
    const char *value = Tcl_GetVar(interp, [key cStringUsingEncoding:NSUTF8StringEncoding], 0);
    if (value)
        return [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
    else
        return nil;
}

@end
