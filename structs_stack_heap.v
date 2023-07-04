// Last updated:
// V 0.4.0 5d269ba, timestamp: 2023-07-04 06:48:53 +0300

struct SomeStruct {
mut:
	val string
}

// According to the docs
// https://github.com/vlang/v/blob/3558e05bfb6f5a1607bf60dd503786a90c1fdbc3/doc/docs.md#heap-structs
// new_stack_struct returns a copy of the struct allocated on the stack.
// Or at least it should. The compiler might allocate it to the heap.
// https://github.com/vlang/v/blob/3558e05bfb6f5a1607bf60dd503786a90c1fdbc3/doc/docs.md#stack-and-heap
fn new_stack_struct() SomeStruct {
	return SomeStruct{
		val: 'new'
	}
}

// new_heap_struct returns a reference to the struct allocated on the heap.
//
// Some people say this kind of function does not return a reference type, just a heap-allocated struct.
// Removing the `&` from the return type will cause a compiler error explaining that the return type
// is indeed expected to be a reference type.
fn new_heap_struct() &SomeStruct {
	return &SomeStruct{
		val: 'new'
	}
}

// https://github.com/vlang/v/blob/3558e05bfb6f5a1607bf60dd503786a90c1fdbc3/doc/docs.md#heap-structs
// copy_of_struct_method receives a copy of a struct instance.
fn (s SomeStruct) copy_of_struct_method() {
	// s.val = 'sugma' // this is not allowed because s is immutable.
}

fn (s &SomeStruct) reference_of_struct_method() {
	// s.val = 'sugma' // this is now allowed because s is immutable.
	//*s.val = 'sugma' // error: invalid indirect of `string`, the type `string` is not a pointer
	mut value := *s
	value.val = 'reference_of_struct_method' // this is not printed
	println('value: ${value}') // this shows that value.val is set
	// What is happening is that `value` is an independent copy of the dereferenced `s`.
}

fn (mut s SomeStruct) mut_copy_of_struct_method() {
	s.val = 'mut_copy_of_struct_method'
}

// error: use `(mut f Foo)` or `(f &Foo)` instead of `(mut f &Foo)`
// The compiler does not allow mutable references
// fn (mut s &SomeStruct) mut_reference_of_struct_method() {
// }

fn mut_copy_of_struct_function(mut s SomeStruct) {
	s.val = 'mut_copy_of_struct_function'
}

// For some reason, here `(mut f &Foo)` is allowed.
// https://github.com/vlang/v/discussions/18634
fn mut_reference_of_struct_function(mut s SomeStruct) {
	s.val = 'mut_reference_of_struct_function'
}

/*
* Dereferencing
*/
fn accepts_values(mut s SomeStruct, v string) {
	s.val = v
}

fn accepts_references(mut s &SomeStruct, v string) {
	s.val = v
	// No dereferencing is needed.
	// My suspicion is that the `.` dereferences structs.
}

fn main() {
	mut stack_struct := new_stack_struct() // copy of struct created in the function
	mut heap_struct := new_heap_struct() // reference to the struct created in the function

	println('copy_of_struct_method')
	// copy_of_struct_method accepts both copy and reference of a struct instance.
	stack_struct.copy_of_struct_method()
	heap_struct.copy_of_struct_method()

	println('reference_of_struct_method')
	// reference_of_struct_method also accepts both copy and reference of a struct instance.
	stack_struct.reference_of_struct_method()
	println('stack_struct: ${stack_struct}') // stack_struct.val is unchanged
	heap_struct.reference_of_struct_method()
	println('heap_struct: ${heap_struct}') // heap_struct.val is unchanged

	println('mut_copy_of_struct_method')
	// mut_copy_of_struct_method again accepts both copy and reference of a struct instance.
	// Additionally, in both cases, the val property is changed.
	stack_struct.mut_copy_of_struct_method()
	println('stack_struct: ${stack_struct}') // change of stack_struct.val
	heap_struct.mut_copy_of_struct_method()
	println('heap_struct: ${heap_struct}') // change of heap_struct.val

	println('mut_copy_of_struct_function')
	// Structs in V are passed by either value or reference. The compiler decides.
	// This magic is something I am unable to predict.
	mut_copy_of_struct_function(mut stack_struct)
	println('stack_struct: ${stack_struct}') // change of stack_struct.val
	mut_copy_of_struct_function(mut heap_struct)
	println('heap_struct: ${heap_struct}') // change of heap_struct.val

	println('mut_reference_of_struct_function')
	mut_reference_of_struct_function(mut stack_struct)
	println('stack_struct: ${stack_struct}') // change of stack_struct.val
	mut_reference_of_struct_function(mut heap_struct)
	println('heap_struct: ${heap_struct}') // change of heap_struct.val

	println('Dereferencing')
	// If you have a reference and want to pass it to a function that expects a value, you would expect
	// to have to dereference it with `*`.
	mut another_heap_struct := new_heap_struct()
	println(another_heap_struct)
	accepts_values(mut *another_heap_struct, 'Passed a dereferenced value')
	println(another_heap_struct)
	// However, the compiler may automatically dereference the passed reference, and modify the underlying 
	// value.
	accepts_values(mut another_heap_struct, 'Passed a reference')
	println(another_heap_struct)

	// A function that expects a reference accepts references.
	accepts_references(mut another_heap_struct, 'Passed a reference')
	println(another_heap_struct)
	// But also values.
	accepts_references(mut *another_heap_struct, 'Passed a dereferenced value')
	println(another_heap_struct)

	println('Closures')
	// Predictability is even more difficult when closures come into play.
	// https://github.com/vlang/v/blob/3558e05bfb6f5a1607bf60dd503786a90c1fdbc3/doc/docs.md#closures
	// Closures require a declaration of variables to `capture` in order to make them available inside
	// the scope of the closure.
	// The captured variables are copied, according to the documentation.
	// Still according to the documentation, the only way to propagate changes outside the closure is
	// to use references.
	//
	// this closure does not compile with error:
	// `heap_struct` is immutable, declare it with `mut` to make it mutable
	// some_closure := fn [heap_struct](){
	// 	heap_struct.val = 'set_by_closure'
	// 	println(heap_struct)
	// }
	//
	// This compiles and the value is changed both inside and outside the closure.
	// Presumably because heap_struct is a reference type.
	heap_closure := fn [mut heap_struct] () {
		heap_struct.val = 'set_by_closure'
		println(heap_struct)
	}
	heap_closure()
	println(heap_struct) // change
	// This compiles and the value is changed only inside of the closure.
	// Presumably because stack_struct is a value type.
	stack_closure := fn [mut stack_struct] () {
		stack_struct.val = 'set_by_closure'
		println(stack_struct)
	}
	stack_closure()
	println(stack_struct) // no change
	// More complex situations arise with more complex closures.
	// https://github.com/vlang/v/discussions/18755#discussioncomment-6347133
	/*
	* In V, there are structs allocated to the stack and structs allocated to the heap.
	* Structs are "usually" allocated to the stack, but they can be allocated to the heap by the compiler.
	* Structs can also forcefully allocated to the heap using the `&` prefix, which is also the prefix
	* used for reference types.
	* Functions can receive both values and references.
	* The keyword `mut` signals whether or not the function can modify the original struct, no matter
	* if the struct given to the function is a value or a reference.
	* In closures there is a difference in whether the type is a value or a reference.
	*/
}
