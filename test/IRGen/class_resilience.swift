// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -enable-resilience -emit-module-path=%t/resilient_struct.swiftmodule -module-name=resilient_struct %S/../Inputs/resilient_struct.swift
// RUN: %target-swift-frontend -emit-module -enable-resilience -emit-module-path=%t/resilient_enum.swiftmodule -module-name=resilient_enum -I %t %S/../Inputs/resilient_enum.swift
// RUN: %target-swift-frontend -emit-module -enable-resilience -emit-module-path=%t/resilient_class.swiftmodule -module-name=resilient_class -I %t %S/../Inputs/resilient_class.swift
// RUN: %target-swift-frontend -I %t -emit-ir -enable-resilience %s | %FileCheck %s
// RUN: %target-swift-frontend -I %t -emit-ir -enable-resilience -O %s

// CHECK: %swift.type = type { [[INT:i32|i64]] }

// CHECK: @_T016class_resilience26ClassWithResilientPropertyC1s16resilient_struct4SizeVvpWvd = {{(protected )?}}global [[INT]] 0
// CHECK: @_T016class_resilience26ClassWithResilientPropertyC5colors5Int32VvpWvd = {{(protected )?}}global [[INT]] 0

// CHECK: @_T016class_resilience33ClassWithResilientlySizedPropertyC1r16resilient_struct9RectangleVvpWvd = {{(protected )?}}global [[INT]] 0
// CHECK: @_T016class_resilience33ClassWithResilientlySizedPropertyC5colors5Int32VvpWvd = {{(protected )?}}global [[INT]] 0

// CHECK: @_T016class_resilience14ResilientChildC5fields5Int32VvpWvd = {{(protected )?}}global [[INT]] {{8|16}}

// CHECK: @_T016class_resilience21ResilientGenericChildCMo = {{(protected )?}}global [[INT]] 0

// CHECK: @_T016class_resilience26ClassWithResilientPropertyCMo = {{(protected )?}}constant [[INT]] {{52|80}}

// CHECK: @_T016class_resilience28ClassWithMyResilientPropertyC1rAA0eF6StructVvpWvd = {{(protected )?}}constant [[INT]] {{8|16}}
// CHECK: @_T016class_resilience28ClassWithMyResilientPropertyC5colors5Int32VvpWvd = {{(protected )?}}constant [[INT]] {{12|20}}

// CHECK: @_T016class_resilience30ClassWithIndirectResilientEnumC1s14resilient_enum10FunnyShapeOvpWvd = {{(protected )?}}constant [[INT]] {{8|16}}
// CHECK: @_T016class_resilience30ClassWithIndirectResilientEnumC5colors5Int32VvpWvd = {{(protected )?}}constant [[INT]] {{12|24}}

// CHECK: @_T016class_resilience14ResilientChildCMo = {{(protected )?}}global [[INT]] 0

// CHECK: @_T016class_resilience16FixedLayoutChildCMo = {{(protected )?}}global [[INT]] 0

// CHECK: @_T016class_resilience17MyResilientParentCMo = {{(protected )?}}constant [[INT]] {{52|80}}

// CHECK: @_T016class_resilience16MyResilientChildCMo = {{(protected )?}}constant [[INT]] {{60|96}}

import resilient_class
import resilient_struct
import resilient_enum


// Concrete class with resilient stored property

public class ClassWithResilientProperty {
  public let p: Point
  public let s: Size
  public let color: Int32

  public init(p: Point, s: Size, color: Int32) {
    self.p = p
    self.s = s
    self.color = color
  }
}


// Concrete class with non-fixed size stored property

public class ClassWithResilientlySizedProperty {
  public let r: Rectangle
  public let color: Int32

  public init(r: Rectangle, color: Int32) {
    self.r = r
    self.color = color
  }
}


// Concrete class with resilient stored property that
// is fixed-layout inside this resilience domain

public struct MyResilientStruct {
  public let x: Int32
}

public class ClassWithMyResilientProperty {
  public let r: MyResilientStruct
  public let color: Int32

  public init(r: MyResilientStruct, color: Int32) {
    self.r = r
    self.color = color
  }
}


// Enums with indirect payloads are fixed-size

public class ClassWithIndirectResilientEnum {
  public let s: FunnyShape
  public let color: Int32

  public init(s: FunnyShape, color: Int32) {
    self.s = s
    self.color = color
  }
}


// Superclass is resilient, so the number of fields and their
// offsets is not known at compile time

public class ResilientChild : ResilientOutsideParent {
  public let field: Int32 = 0
}

// Superclass is resilient, but the class is fixed-layout.
// This simulates a user app subclassing a class in a resilient
// framework. In this case, we still want to emit a base offset
// global.

@_fixed_layout public class FixedLayoutChild : ResilientOutsideParent {
  public let field: Int32 = 0
}

// Superclass is resilient, so the number of fields and their
// offsets is not known at compile time

public class ResilientGenericChild<T> : ResilientGenericOutsideParent<T> {
  public let field: Int32 = 0
}


// Superclass is resilient and has a resilient value type payload,
// but everything is in one module


public class MyResilientParent {
  public let s: MyResilientStruct = MyResilientStruct(x: 0)
}

public class MyResilientChild : MyResilientParent {
  public let field: Int32 = 0
}


// ClassWithResilientProperty.color getter

// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience26ClassWithResilientPropertyC5colors5Int32Vvg(%T16class_resilience26ClassWithResilientPropertyC* swiftself)
// CHECK:      [[OFFSET:%.*]] = load [[INT]], [[INT]]* @_T016class_resilience26ClassWithResilientPropertyC5colors5Int32VvpWvd
// CHECK-NEXT: [[PTR:%.*]] = bitcast %T16class_resilience26ClassWithResilientPropertyC* %0 to i8*
// CHECK-NEXT: [[FIELD_ADDR:%.*]] = getelementptr inbounds i8, i8* [[PTR]], [[INT]] [[OFFSET]]
// CHECK-NEXT: [[FIELD_PTR:%.*]] = bitcast i8* [[FIELD_ADDR]] to %Ts5Int32V*
// CHECK:      call void @swift_beginAccess
// CHECK-NEXT: [[FIELD_PAYLOAD:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_PTR]], i32 0, i32 0
// CHECK-NEXT: [[FIELD_VALUE:%.*]] = load i32, i32* [[FIELD_PAYLOAD]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK: ret i32 [[FIELD_VALUE]]

// ClassWithResilientProperty metadata accessor

// CHECK-LABEL: define{{( protected)?}} %swift.type* @_T016class_resilience26ClassWithResilientPropertyCMa()
// CHECK:      [[CACHE:%.*]] = load %swift.type*, %swift.type** @_T016class_resilience26ClassWithResilientPropertyCML
// CHECK-NEXT: [[COND:%.*]] = icmp eq %swift.type* [[CACHE]], null
// CHECK-NEXT: br i1 [[COND]], label %cacheIsNull, label %cont

// CHECK:    cacheIsNull:
// CHECK-NEXT: call void @swift_once([[INT]]* @_T016class_resilience26ClassWithResilientPropertyCMa.once_token, i8* bitcast (void (i8*)* @initialize_metadata_ClassWithResilientProperty to i8*), i8* undef)
// CHECK-NEXT: [[METADATA:%.*]] = load %swift.type*, %swift.type** @_T016class_resilience26ClassWithResilientPropertyCML
// CHECK-NEXT: br label %cont

// CHECK:    cont:
// CHECK-NEXT: [[RESULT:%.*]] = phi %swift.type* [ [[CACHE]], %entry ], [ [[METADATA]], %cacheIsNull ]
// CHECK-NEXT: ret %swift.type* [[RESULT]]

// ClassWithResilientlySizedProperty.color getter

// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience33ClassWithResilientlySizedPropertyC5colors5Int32Vvg(%T16class_resilience33ClassWithResilientlySizedPropertyC* swiftself)
// CHECK:      [[OFFSET:%.*]] = load [[INT]], [[INT]]* @_T016class_resilience33ClassWithResilientlySizedPropertyC5colors5Int32VvpWvd
// CHECK-NEXT: [[PTR:%.*]] = bitcast %T16class_resilience33ClassWithResilientlySizedPropertyC* %0 to i8*
// CHECK-NEXT: [[FIELD_ADDR:%.*]] = getelementptr inbounds i8, i8* [[PTR]], [[INT]] [[OFFSET]]
// CHECK-NEXT: [[FIELD_PTR:%.*]] = bitcast i8* [[FIELD_ADDR]] to %Ts5Int32V*
// CHECK:      call void @swift_beginAccess
// CHECK-NEXT: [[FIELD_PAYLOAD:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_PTR]], i32 0, i32 0
// CHECK-NEXT: [[FIELD_VALUE:%.*]] = load i32, i32* [[FIELD_PAYLOAD]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK:      ret i32 [[FIELD_VALUE]]

// ClassWithResilientlySizedProperty metadata accessor

// CHECK-LABEL: define{{( protected)?}} %swift.type* @_T016class_resilience33ClassWithResilientlySizedPropertyCMa()
// CHECK:      [[CACHE:%.*]] = load %swift.type*, %swift.type** @_T016class_resilience33ClassWithResilientlySizedPropertyCML
// CHECK-NEXT: [[COND:%.*]] = icmp eq %swift.type* [[CACHE]], null
// CHECK-NEXT: br i1 [[COND]], label %cacheIsNull, label %cont

// CHECK:    cacheIsNull:
// CHECK-NEXT: call void @swift_once([[INT]]* @_T016class_resilience33ClassWithResilientlySizedPropertyCMa.once_token, i8* bitcast (void (i8*)* @initialize_metadata_ClassWithResilientlySizedProperty to i8*), i8* undef)
// CHECK-NEXT: [[METADATA:%.*]] = load %swift.type*, %swift.type** @_T016class_resilience33ClassWithResilientlySizedPropertyCML
// CHECK-NEXT: br label %cont

// CHECK:    cont:
// CHECK-NEXT: [[RESULT:%.*]] = phi %swift.type* [ [[CACHE]], %entry ], [ [[METADATA]], %cacheIsNull ]
// CHECK-NEXT: ret %swift.type* [[RESULT]]


// ClassWithIndirectResilientEnum.color getter

// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience30ClassWithIndirectResilientEnumC5colors5Int32Vvg(%T16class_resilience30ClassWithIndirectResilientEnumC* swiftself)
// CHECK:      [[FIELD_PTR:%.*]] = getelementptr inbounds %T16class_resilience30ClassWithIndirectResilientEnumC, %T16class_resilience30ClassWithIndirectResilientEnumC* %0, i32 0, i32 2
// CHECK: call void @swift_beginAccess
// CHECK-NEXT: [[FIELD_PAYLOAD:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_PTR]], i32 0, i32 0
// CHECK-NEXT: [[FIELD_VALUE:%.*]] = load i32, i32* [[FIELD_PAYLOAD]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK: ret i32 [[FIELD_VALUE]]


// ResilientChild.field getter

// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience14ResilientChildC5fields5Int32Vvg(%T16class_resilience14ResilientChildC* swiftself)
// CHECK:      [[OFFSET:%.*]] = load [[INT]], [[INT]]* @_T016class_resilience14ResilientChildC5fields5Int32VvpWvd
// CHECK-NEXT: [[PTR:%.*]] = bitcast %T16class_resilience14ResilientChildC* %0 to i8*
// CHECK-NEXT: [[FIELD_ADDR:%.*]] = getelementptr inbounds i8, i8* [[PTR]], [[INT]] [[OFFSET]]
// CHECK-NEXT: [[FIELD_PTR:%.*]] = bitcast i8* [[FIELD_ADDR]] to %Ts5Int32V*
// CHECK: call void @swift_beginAccess
// CHECK-NEXT: [[FIELD_PAYLOAD:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_PTR]], i32 0, i32 0
// CHECK-NEXT: [[FIELD_VALUE:%.*]] = load i32, i32* [[FIELD_PAYLOAD]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK: ret i32 [[FIELD_VALUE]]


// ResilientGenericChild.field getter


// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience21ResilientGenericChildC5fields5Int32Vvg(%T16class_resilience21ResilientGenericChildC* swiftself)

// FIXME: we could eliminate the unnecessary isa load by lazily emitting
// metadata sources in EmitPolymorphicParameters

// CHECK:      load %swift.type*

// CHECK-NEXT: [[ADDR:%.*]] = getelementptr inbounds %T16class_resilience21ResilientGenericChildC, %T16class_resilience21ResilientGenericChildC* %0, i32 0, i32 0, i32 0
// CHECK-NEXT: [[ISA:%.*]] = load %swift.type*, %swift.type** [[ADDR]]
// CHECK-NEXT: [[BASE:%.*]] = load [[INT]], [[INT]]* @_T016class_resilience21ResilientGenericChildCMo
// CHECK-NEXT: [[METADATA_OFFSET:%.*]] = add [[INT]] [[BASE]], {{4|8}}
// CHECK-NEXT: [[ISA_ADDR:%.*]] = bitcast %swift.type* [[ISA]] to i8*
// CHECK-NEXT: [[FIELD_OFFSET_TMP:%.*]] = getelementptr inbounds i8, i8* [[ISA_ADDR]], [[INT]] [[METADATA_OFFSET]]
// CHECK-NEXT: [[FIELD_OFFSET_ADDR:%.*]] = bitcast i8* [[FIELD_OFFSET_TMP]] to [[INT]]*
// CHECK-NEXT: [[FIELD_OFFSET:%.*]] = load [[INT]], [[INT]]* [[FIELD_OFFSET_ADDR:%.*]]
// CHECK-NEXT: [[OBJECT:%.*]] = bitcast %T16class_resilience21ResilientGenericChildC* %0 to i8*
// CHECK-NEXT: [[ADDR:%.*]] = getelementptr inbounds i8, i8* [[OBJECT]], [[INT]] [[FIELD_OFFSET]]
// CHECK-NEXT: [[FIELD_ADDR:%.*]] = bitcast i8* [[ADDR]] to %Ts5Int32V*
// CHECK:      call void @swift_beginAccess
// CHECK-NEXT: [[PAYLOAD_ADDR:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_ADDR]], i32 0, i32 0
// CHECK-NEXT: [[RESULT:%.*]] = load i32, i32* [[PAYLOAD_ADDR]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK:      ret i32 [[RESULT]]


// MyResilientChild.field getter

// CHECK-LABEL: define{{( protected)?}} swiftcc i32 @_T016class_resilience16MyResilientChildC5fields5Int32Vvg(%T16class_resilience16MyResilientChildC* swiftself)
// CHECK:      [[FIELD_ADDR:%.*]] = getelementptr inbounds %T16class_resilience16MyResilientChildC, %T16class_resilience16MyResilientChildC* %0, i32 0, i32 2
// CHECK:      call void @swift_beginAccess
// CHECK-NEXT: [[PAYLOAD_ADDR:%.*]] = getelementptr inbounds %Ts5Int32V, %Ts5Int32V* [[FIELD_ADDR]], i32 0, i32 0
// CHECK-NEXT: [[RESULT:%.*]] = load i32, i32* [[PAYLOAD_ADDR]]
// CHECK-NEXT: call void @swift_endAccess
// CHECK:      ret i32 [[RESULT]]


// ClassWithResilientProperty metadata initialization function


// CHECK-LABEL: define private void @initialize_metadata_ClassWithResilientProperty
// CHECK:             [[METADATA:%.*]] = call %swift.type* @swift_relocateClassMetadata({{.*}}, [[INT]] {{60|96}}, [[INT]] 4)
// CHECK:             [[SIZE_METADATA:%.*]] = call %swift.type* @_T016resilient_struct4SizeVMa()
// CHECK:             call void @swift_initClassMetadata_UniversalStrategy(%swift.type* [[METADATA]], [[INT]] 3, {{.*}})
// CHECK-native:      [[METADATA_PTR:%.*]] = bitcast %swift.type* [[METADATA]] to [[INT]]*
// CHECK-native-NEXT: [[FIELD_OFFSET_PTR:%.*]] = getelementptr inbounds [[INT]], [[INT]]* [[METADATA_PTR]], [[INT]] {{12|15}}
// CHECK-native-NEXT: [[FIELD_OFFSET:%.*]] = load [[INT]], [[INT]]* [[FIELD_OFFSET_PTR]]
// CHECK-native-NEXT: store [[INT]] [[FIELD_OFFSET]], [[INT]]* @_T016class_resilience26ClassWithResilientPropertyC1s16resilient_struct4SizeVvWvd
// CHECK-native-NEXT: [[FIELD_OFFSET_PTR:%.*]] = getelementptr inbounds [[INT]], [[INT]]* [[METADATA_PTR]], [[INT]] {{13|16}}
// CHECK-native-NEXT: [[FIELD_OFFSET:%.*]] = load [[INT]], [[INT]]* [[FIELD_OFFSET_PTR]]
// CHECK-native-NEXT: store [[INT]] [[FIELD_OFFSET]], [[INT]]* @_T016class_resilience26ClassWithResilientPropertyC5colors5Int32VvWvd
// CHECK:             store atomic %swift.type* [[METADATA]], %swift.type** @_T016class_resilience26ClassWithResilientPropertyCML release,
// CHECK:             ret void


// ClassWithResilientlySizedProperty metadata initialization function

// CHECK-LABEL: define private void @initialize_metadata_ClassWithResilientlySizedProperty
// CHECK:             [[METADATA:%.*]] = call %swift.type* @swift_relocateClassMetadata({{.*}}, [[INT]] {{60|96}}, [[INT]] 3)
// CHECK:             [[RECTANGLE_METADATA:%.*]] = call %swift.type* @_T016resilient_struct9RectangleVMa()
// CHECK:             call void @swift_initClassMetadata_UniversalStrategy(%swift.type* [[METADATA]], [[INT]] 2, {{.*}})
// CHECK-native:      [[METADATA_PTR:%.*]] = bitcast %swift.type* [[METADATA]] to [[INT]]*
// CHECK-native-NEXT: [[FIELD_OFFSET_PTR:%.*]] = getelementptr inbounds [[INT]], [[INT]]* [[METADATA_PTR]], [[INT]] {{11|14}}
// CHECK-native-NEXT: [[FIELD_OFFSET:%.*]] = load [[INT]], [[INT]]* [[FIELD_OFFSET_PTR]]
// CHECK-native-NEXT: store [[INT]] [[FIELD_OFFSET]], [[INT]]* @_T016class_resilience33ClassWithResilientlySizedPropertyC1r16resilient_struct9RectangleVvWvd
// CHECK-native-NEXT: [[FIELD_OFFSET_PTR:%.*]] = getelementptr inbounds [[INT]], [[INT]]* [[METADATA_PTR]], [[INT]] {{12|15}}
// CHECK-native-NEXT: [[FIELD_OFFSET:%.*]] = load [[INT]], [[INT]]* [[FIELD_OFFSET_PTR]]
// CHECK-native-NEXT: store [[INT]] [[FIELD_OFFSET]], [[INT]]* @_T016class_resilience33ClassWithResilientlySizedPropertyC5colors5Int32VvWvd
// CHECK:             store atomic %swift.type* [[METADATA]], %swift.type** @_T016class_resilience33ClassWithResilientlySizedPropertyCML release,
// CHECK:             ret void


// CHECK-LABEL: define private void @initialize_metadata_ResilientChild(i8*)

// Get the superclass...

// CHECK:              [[SUPER:%.*]] = call %swift.type* @_T015resilient_class22ResilientOutsideParentCMa()
// CHECK:              [[SUPER_ADDR:%.*]] = bitcast %swift.type* [[SUPER]] to i8*
// CHECK:              [[SIZE_TMP:%.*]] = getelementptr inbounds i8, i8* [[SUPER_ADDR]], i32 {{36|56}}
// CHECK:              [[SIZE_ADDR:%.*]] = bitcast i8* [[SIZE_TMP]] to i32*
// CHECK:              [[SIZE:%.*]] = load i32, i32* [[SIZE_ADDR]]

// Initialize class metadata base offset...
// CHECK:              store [[INT]] {{.*}}, [[INT]]* @_T016class_resilience14ResilientChildCMo

// Initialize the superclass field...
// CHECK:              store %swift.type* [[SUPER]], %swift.type** getelementptr inbounds ({{.*}})

// Relocate metadata if necessary...
// CHECK:              call %swift.type* @swift_relocateClassMetadata(%swift.type* {{.*}}, [[INT]] {{60|96}}, [[INT]] 1)

// CHECK:              ret void

// CHECK-LABEL: define private void @initialize_metadata_FixedLayoutChild(i8*)

// Get the superclass...

// CHECK:              [[SUPER:%.*]] = call %swift.type* @_T015resilient_class22ResilientOutsideParentCMa()
// CHECK:              [[SUPER_ADDR:%.*]] = bitcast %swift.type* [[SUPER]] to i8*
// CHECK:              [[SIZE_TMP:%.*]] = getelementptr inbounds i8, i8* [[SUPER_ADDR]], i32 {{36|56}}
// CHECK:              [[SIZE_ADDR:%.*]] = bitcast i8* [[SIZE_TMP]] to i32*
// CHECK:              [[SIZE:%.*]] = load i32, i32* [[SIZE_ADDR]]

// Initialize class metadata base offset...
// CHECK:              store [[INT]] {{.*}}, [[INT]]* @_T016class_resilience16FixedLayoutChildCMo

// Initialize the superclass field...
// CHECK:              store %swift.type* [[SUPER]], %swift.type** getelementptr inbounds ({{.*}})

// Relocate metadata if necessary...
// CHECK:              call %swift.type* @swift_relocateClassMetadata(%swift.type* {{.*}}, [[INT]] {{60|96}}, [[INT]] 1)

// CHECK:              ret void

// CHECK-LABEL: define private %swift.type* @create_generic_metadata_ResilientGenericChild(%swift.type_pattern*, i8**)

// Get the superclass...

// CHECK:              [[SUPER:%.*]] = call %swift.type* @_T015resilient_class29ResilientGenericOutsideParentCMa(%swift.type* %T)
// CHECK:              [[SUPER_TMP:%.*]] = bitcast %swift.type* [[SUPER]] to %objc_class*
// CHECK:              [[SUPER_ADDR:%.*]] = bitcast %objc_class* [[SUPER_TMP]] to i8*
// CHECK:              [[SIZE_TMP:%.*]] = getelementptr inbounds i8, i8* [[SUPER_ADDR]], i32 {{36|56}}
// CHECK:              [[SIZE_ADDR:%.*]] = bitcast i8* [[SIZE_TMP]] to i32*
// CHECK:              [[SIZE:%.*]] = load i32, i32* [[SIZE_ADDR]]

// Initialize class metadata base offset...
// CHECK:              store [[INT]] {{.*}}, [[INT]]* @_T016class_resilience21ResilientGenericChildCMo

// CHECK:              [[METADATA:%.*]] = call %swift.type* @swift_allocateGenericClassMetadata(%swift.type_pattern* %0, i8** %1, %objc_class* [[SUPER_TMP]], [[INT]] 2)
// CHECK:              ret %swift.type* [[METADATA]]
