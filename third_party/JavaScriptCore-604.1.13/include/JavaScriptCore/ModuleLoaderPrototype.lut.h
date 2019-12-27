// Automatically generated from /Users/hejian/Downloads/dev_multi_process/Source/JavaScriptCore/runtime/ModuleLoaderPrototype.cpp using /Users/hejian/Downloads/dev_multi_process/Source/JavaScriptCore/create_hash_table. DO NOT EDIT!

#include "JSCBuiltins.h"
#include "Lookup.h"

namespace JSC {

static const struct CompactHashIndex moduleLoaderPrototypeTableIndex[70] = {
    { 18, -1 },
    { 22, -1 },
    { -1, -1 },
    { 14, -1 },
    { 3, 66 },
    { -1, -1 },
    { -1, -1 },
    { 16, 67 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 1, -1 },
    { -1, -1 },
    { 5, 68 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 6, -1 },
    { -1, -1 },
    { -1, -1 },
    { 15, -1 },
    { -1, -1 },
    { 17, -1 },
    { 9, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 4, 65 },
    { -1, -1 },
    { -1, -1 },
    { 12, -1 },
    { 10, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 24, -1 },
    { -1, -1 },
    { 0, 64 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 13, -1 },
    { 8, -1 },
    { -1, -1 },
    { 11, -1 },
    { -1, -1 },
    { -1, -1 },
    { -1, -1 },
    { 2, 69 },
    { 7, -1 },
    { 19, -1 },
    { 20, -1 },
    { 21, -1 },
    { 23, -1 },
    { 25, -1 },
};

static const struct HashTableValue moduleLoaderPrototypeTableValues[26] = {
   { "ensureRegistered", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeEnsureRegisteredCodeGenerator), (intptr_t)1 } },
   { "forceFulfillPromise", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeForceFulfillPromiseCodeGenerator), (intptr_t)2 } },
   { "fulfillFetch", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeFulfillFetchCodeGenerator), (intptr_t)2 } },
   { "fulfillInstantiate", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeFulfillInstantiateCodeGenerator), (intptr_t)2 } },
   { "commitInstantiated", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeCommitInstantiatedCodeGenerator), (intptr_t)3 } },
   { "instantiation", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeInstantiationCodeGenerator), (intptr_t)3 } },
   { "requestFetch", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestFetchCodeGenerator), (intptr_t)2 } },
   { "requestInstantiate", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestInstantiateCodeGenerator), (intptr_t)2 } },
   { "requestSatisfy", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestSatisfyCodeGenerator), (intptr_t)2 } },
   { "requestLink", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestLinkCodeGenerator), (intptr_t)2 } },
   { "requestReady", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestReadyCodeGenerator), (intptr_t)2 } },
   { "link", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeLinkCodeGenerator), (intptr_t)2 } },
   { "moduleDeclarationInstantiation", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeModuleDeclarationInstantiation), (intptr_t)(2) } },
   { "moduleEvaluation", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeModuleEvaluationCodeGenerator), (intptr_t)2 } },
   { "evaluate", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeEvaluate), (intptr_t)(3) } },
   { "provide", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeProvideCodeGenerator), (intptr_t)3 } },
   { "loadAndEvaluateModule", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeLoadAndEvaluateModuleCodeGenerator), (intptr_t)3 } },
   { "loadModule", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeLoadModuleCodeGenerator), (intptr_t)3 } },
   { "linkAndEvaluateModule", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeLinkAndEvaluateModuleCodeGenerator), (intptr_t)2 } },
   { "requestImportModule", ((DontEnum|Function) & ~Function) | Builtin, NoIntrinsic, { (intptr_t)static_cast<BuiltinGenerator>(moduleLoaderPrototypeRequestImportModuleCodeGenerator), (intptr_t)2 } },
   { "getModuleNamespaceObject", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeGetModuleNamespaceObject), (intptr_t)(1) } },
   { "parseModule", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeParseModule), (intptr_t)(2) } },
   { "requestedModules", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeRequestedModules), (intptr_t)(1) } },
   { "resolve", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeResolve), (intptr_t)(2) } },
   { "fetch", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeFetch), (intptr_t)(2) } },
   { "instantiate", DontEnum|Function, NoIntrinsic, { (intptr_t)static_cast<NativeFunction>(moduleLoaderPrototypeInstantiate), (intptr_t)(3) } },
};

static const struct HashTable moduleLoaderPrototypeTable =
    { 26, 63, false, moduleLoaderPrototypeTableValues, moduleLoaderPrototypeTableIndex };

} // namespace JSC
