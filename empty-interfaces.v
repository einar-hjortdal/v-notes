import arrays

interface Param {}

// https://github.com/vlang/v/issues/18900
fn test(params ...Param) {
	match params[0] {
		string {
			println('it is a string: ${params[0]}') // it is a string: Param('a string')
			// What I want is `it is a string: a string`
		}
		else {
			panic('oops')
		}
	}
	param := params[0]
	match param {
		string {
			println('it is a string: ${param}') // it is a string: &a string
			println('it is a string: ${*param}') // it is a string: a string
		}
		else {
			panic('oops')
		}
	}
}

fn main() {
	test('a string')
	mut ar := []Param{}
	// https://github.com/vlang/v/issues/18906
	arrays.concat(ar, Param('a string'), Param('another string'))
	ar << 'string'
	println(ar)
}
