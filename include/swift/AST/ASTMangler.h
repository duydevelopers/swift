//===--- ASTMangler.h - Swift AST symbol mangling ---------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef __SWIFT_AST_ASTMANGLER_H__
#define __SWIFT_AST_ASTMANGLER_H__

#include "swift/Basic/Mangler.h"
#include "swift/AST/Types.h"
#include "swift/AST/Decl.h"
#include "swift/AST/GenericSignature.h"

namespace swift {

class AbstractClosureExpr;

namespace Mangle {

/// The mangler for AST declarations.
class ASTMangler : public Mangler {
protected:
  CanGenericSignature CurGenericSignature;
  ModuleDecl *Mod = nullptr;
  const DeclContext *DeclCtx = nullptr;
  GenericEnvironment *GenericEnv = nullptr;

  /// Optimize out protocol names if a type only conforms to one protocol.
  bool OptimizeProtocolNames = true;

  /// If enabled, Arche- and Alias types are mangled with context.
  bool DWARFMangling;

public:
  enum class SymbolKind {
    Default,
    DynamicThunk,
    SwiftAsObjCThunk,
    ObjCAsSwiftThunk,
    DirectMethodReferenceThunk,
  };

  ASTMangler(bool DWARFMangling = false)
    : DWARFMangling(DWARFMangling) {}

  std::string mangleClosureEntity(const AbstractClosureExpr *closure,
                                  SymbolKind SKind);

  std::string mangleEntity(const ValueDecl *decl, bool isCurried,
                           SymbolKind SKind = SymbolKind::Default);

  std::string mangleDestructorEntity(const DestructorDecl *decl,
                                     bool isDeallocating, SymbolKind SKind);

  std::string mangleConstructorEntity(const ConstructorDecl *ctor,
                                      bool isAllocating, bool isCurried,
                                      SymbolKind SKind = SymbolKind::Default);

  std::string mangleIVarInitDestroyEntity(const ClassDecl *decl,
                                          bool isDestroyer, SymbolKind SKind);

  std::string mangleAccessorEntity(AccessorKind kind,
                                   AddressorKind addressorKind,
                                   const ValueDecl *decl,
                                   bool isStatic,
                                   SymbolKind SKind);

  std::string mangleGlobalGetterEntity(const ValueDecl *decl,
                                       SymbolKind SKind = SymbolKind::Default);

  std::string mangleDefaultArgumentEntity(const DeclContext *func,
                                          unsigned index,
                                          SymbolKind SKind);

  std::string mangleInitializerEntity(const VarDecl *var, SymbolKind SKind);

  std::string mangleNominalType(const NominalTypeDecl *decl);

  std::string mangleVTableThunk(const FuncDecl *Base,
                                const FuncDecl *Derived);

  std::string mangleConstructorVTableThunk(const ConstructorDecl *Base,
                                           const ConstructorDecl *Derived,
                                           bool isAllocating);

  std::string mangleWitnessTable(const NormalProtocolConformance *C);

  std::string mangleWitnessThunk(const ProtocolConformance *Conformance,
                                 const ValueDecl *Requirement);

  std::string mangleClosureWitnessThunk(const ProtocolConformance *Conformance,
                                        const AbstractClosureExpr *Closure);

  std::string mangleBehaviorInitThunk(const VarDecl *decl);

  std::string mangleGlobalVariableFull(const VarDecl *decl);

  std::string mangleGlobalInit(const VarDecl *decl, int counter,
                               bool isInitFunc);

  std::string mangleReabstractionThunkHelper(CanSILFunctionType ThunkType,
                                             Type FromType, Type ToType,
                                             ModuleDecl *Module);

  std::string mangleTypeForDebugger(Type decl, const DeclContext *DC,
                                    GenericEnvironment *GE);

  std::string mangleDeclType(const ValueDecl *decl);
  
  std::string mangleObjCRuntimeName(const NominalTypeDecl *Nominal);

  std::string mangleTypeAsUSR(Type type) {
    return mangleTypeWithoutPrefix(type);
  }

  std::string mangleTypeAsContextUSR(const NominalTypeDecl *type);

  std::string mangleDeclAsUSR(ValueDecl *Decl, StringRef USRPrefix);

  std::string mangleAccessorEntityAsUSR(AccessorKind kind,
                                        AddressorKind addressorKind,
                                        const ValueDecl *decl,
                                        StringRef USRPrefix);

protected:

  void appendSymbolKind(SymbolKind SKind);

  void appendType(Type type);
  
  void appendDeclName(const ValueDecl *decl);

  GenericTypeParamType *appendAssocType(DependentMemberType *DepTy,
                                        bool &isAssocTypeAtDepth);

  void appendOpWithGenericParamIndex(StringRef,
                                     const GenericTypeParamType *paramTy);

  void bindGenericParameters(const DeclContext *DC);

  void bindGenericParameters(CanGenericSignature sig);

  /// \brief Mangles a sugared type iff we are mangling for the debugger.
  template <class T> void appendSugaredType(Type type) {
    assert(DWARFMangling &&
           "sugared types are only legal when mangling for the debugger");
    auto *BlandTy = cast<T>(type.getPointer())->getSinglyDesugaredType();
    appendType(BlandTy);
  }

  void appendBoundGenericArgs(Type type, bool &isFirstArgList);

  void appendImplFunctionType(SILFunctionType *fn);

  void appendContextOf(const ValueDecl *decl);

  void appendContext(const DeclContext *ctx);

  void appendModule(const ModuleDecl *module);

  void appendProtocolName(const ProtocolDecl *protocol);

  void appendNominalType(const NominalTypeDecl *decl);

  void appendFunctionType(AnyFunctionType *fn, bool forceSingleParam);

  void appendFunctionSignature(AnyFunctionType *fn, bool forceSingleParam);

  void appendParams(Type ParamsTy, bool forceSingleParam);

  void appendTypeList(Type listTy);

  void appendGenericSignature(const GenericSignature *sig);

  void appendRequirement(const Requirement &reqt);

  void appendGenericSignatureParts(ArrayRef<GenericTypeParamType*> params,
                                   unsigned initialParamDepth,
                                   ArrayRef<Requirement> requirements);

  void appendAssociatedTypeName(DependentMemberType *dmt);

  void appendClosureEntity(const SerializedAbstractClosureExpr *closure);
  
  void appendClosureEntity(const AbstractClosureExpr *closure);

  void appendClosureComponents(Type Ty, unsigned discriminator, bool isImplicit,
                               const DeclContext *parentContext,
                               const DeclContext *localContext);

  void appendDefaultArgumentEntity(const DeclContext *ctx, unsigned index);

  void appendInitializerEntity(const VarDecl *var);

  CanType getDeclTypeForMangling(const ValueDecl *decl,
                                 ArrayRef<GenericTypeParamType *> &genericParams,
                                 unsigned &initialParamIndex,
                                 ArrayRef<Requirement> &requirements,
                                 SmallVectorImpl<Requirement> &requirementsBuf);

  void appendDeclType(const ValueDecl *decl, bool isFunctionMangling = false);

  bool tryAppendStandardSubstitution(const NominalTypeDecl *type);

  void appendConstructorEntity(const ConstructorDecl *ctor, bool isAllocating);
  
  void appendDestructorEntity(const DestructorDecl *decl, bool isDeallocating);

  void appendAccessorEntity(AccessorKind kind,
                            AddressorKind addressorKind,
                            const ValueDecl *decl,
                            bool isStatic);

  void appendEntity(const ValueDecl *decl, StringRef EntityOp, bool isStatic);

  void appendEntity(const ValueDecl *decl);

  void appendProtocolConformance(const ProtocolConformance *conformance);

  void appendOpParamForLayoutConstraint(LayoutConstraint Layout);

  std::string mangleTypeWithoutPrefix(Type type) {
    appendType(type);
    return finalize();
  }
};

} // end namespace Mangle
} // end namespace swift

#endif // __SWIFT_AST_ASTMANGLER_H__
