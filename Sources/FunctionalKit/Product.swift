#if SWIFT_PACKAGE
	import Operadics
#endif
import Abstract

public protocol ProductType {
	associatedtype FirstType
	associatedtype SecondType

	func fold<T>(_ transform: (FirstType,SecondType) -> T) -> T
}

// sourcery: testBifunctor
// sourcery: testConstruct = "init(x,y)"
public struct Product<A,B>: ProductType {
	private let _first: A
	private let _second: B

	public init(_ first: A, _ second: B) {
		self._first = first
		self._second = second
	}

	public func fold<T>(_ transform: (A, B) -> T) -> T {
		return transform(_first,_second)
	}
}

// MARK: - Equatable

extension Product: Equatable where A: Equatable, B: Equatable {
	public static func == (lhs: Product, rhs: Product) -> Bool {
		return lhs.first == rhs.first
			&& lhs.second == rhs.second
	}
}

// MARK: - Projections

extension ProductType {
	public func toProduct() -> Product<FirstType,SecondType> {
		return fold(Product<FirstType,SecondType>.init)
	}

	public var first: FirstType {
		return fold { first, _ in first }
	}

	public var second: SecondType {
		return fold { _, second in second }
	}

	public var unwrap: (FirstType,SecondType) {
		return fold(f.identity)
	}
}

// MARK: - Evaluation

extension ProductType where FirstType: ExponentialType, FirstType.SourceType == SecondType {
	public func eval() -> FirstType.TargetType {
		return fold { (exponential, value) -> FirstType.TargetType in
			exponential.call(value)
		}
	}
}

extension ProductType where SecondType: ExponentialType, SecondType.SourceType == FirstType {
	public func eval() -> SecondType.TargetType {
		return fold { (value, exponential) -> SecondType.TargetType in
			exponential.call(value)
		}
	}
}

// MARK: - Algebra

extension Product: Magma where A: Magma, B: Magma {
	public static func <> (left: Product<A, B>, right: Product<A, B>) -> Product<A, B> {
		return Product<A,B>.init(
			left.first <> right.first,
			left.second <> right.second)
	}
}

extension Product: Semigroup where A: Semigroup, B: Semigroup {}

extension Product: Monoid where A: Monoid, B: Monoid {
	public static var empty: Product<A, B> {
		return Product<A,B>.init(.empty, .empty)
	}
}

extension Product: CommutativeMonoid where A: CommutativeMonoid, B: CommutativeMonoid {}

extension Product: BoundedSemilattice where A: BoundedSemilattice, B: BoundedSemilattice {}

extension Product: Semiring where A: Semiring, B: Semiring {
	public typealias Additive = Product<A.Additive,B.Additive>
	public typealias Multiplicative = Product<A.Multiplicative,B.Multiplicative>

	public static func <>+ (left: Product<A, B>, right: Product<A, B>) -> Product<A, B> {
		return Product<A,B>.init(
			left.first <>+ right.first,
			left.second <>+ right.second)
	}

	public static func <>* (left: Product<A, B>, right: Product<A, B>) -> Product<A, B> {
		return Product<A,B>.init(
			left.first <>* right.first,
			left.second <>* right.second)
	}

	public static var zero: Product<A, B> {
		return Product<A,B>.init(.zero, .zero)
	}

	public static var one: Product<A, B> {
		return Product<A,B>.init(.one, .one)
	}
}

// MARK: - Functor

extension ProductType {
	public func bimap<T,U>(_ onFirst: (FirstType) -> T, _ onSecond: (SecondType) -> U) -> Product<T,U> {
		return fold { first, second in Product<T,U>.init(onFirst(first), onSecond(second)) }
	}

	public func mapFirst<T>(_ transform: (FirstType) -> T) -> Product<T,SecondType> {
		return bimap(transform, f.identity)
	}

	public func mapSecond<U>(_ transform: (SecondType) -> U) -> Product<FirstType,U> {
		return bimap(f.identity, transform)
	}
}

// MARK: - Cross Interactions

extension ProductType where FirstType: CoproductType {
	public func insideOut() -> Coproduct<Product<FirstType.LeftType,SecondType>,Product<FirstType.RightType,SecondType>> {
		return fold { first, second in
			first.bimap(
				{ Product.init($0, second) },
				{ Product.init($0, second) })
		}
	}
}

extension ProductType where SecondType: CoproductType {
	public func insideOut() -> Coproduct<Product<FirstType,SecondType.LeftType>,Product<FirstType,SecondType.RightType>> {
		return fold { first, second in
			second.bimap(
				{ Product.init(first, $0) },
				{ Product.init(first, $0) })
		}
	}
}
