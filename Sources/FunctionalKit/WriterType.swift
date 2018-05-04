#if SWIFT_PACKAGE
    import Operadics
#endif
import Abstract

// MARK: - Definiton

// sourcery: split8
// sourcery: functor
// sourcery: traversable
// sourcery: monad
// sourcery: concrete = "Writer"
// sourcery: secondaryParameter = "LogType"
public protocol WriterType: PureConstructible, ProductType {
    associatedtype LogType: Monoid
    
    static func from(concrete: Concrete<LogType,ParameterType>) -> Self
    var run: (LogType,ParameterType) { get }
    func fold <T> (_ transform: (LogType,ParameterType) -> T) -> T
}

// MARK: - Data

// sourcery: testFunctor
// sourcery: testApplicative
// sourcery: testMonad
// sourcery: testConstruct = "init(log: .empty, value: x)"
// sourcery: testSecondaryParameter
public struct Writer<L,A>: WriterType where L: Monoid {
    public typealias ParameterType = A
    
    fileprivate let log: L
    fileprivate let value: A
    
    public init(log: L, value: A) {
        self.log = log
        self.value = value
    }
    
    public static func from(concrete: Writer<L, A>) -> Writer<L, A> {
        return concrete
    }
    
    public var run: (L,A) {
        return (log,value)
    }
    
    public func fold<T>(_ transform: (L, A) -> T) -> T {
        return withoutActuallyEscaping(transform) { transform in
            f.destructure(transform) § run
        }
    }
}

// MARK: - Concrete

public extension WriterType {
    typealias Concrete<L,T> = Writer<L,T> where L: Monoid
}

// MARK: - Equatable

extension Writer: Equatable where L: Equatable, A: Equatable {}

// MARK: - Functor

public extension WriterType {
    func map <T> (_ transform: (ParameterType) -> T) -> Writer<LogType,T> {
        return fold { log, value in Writer<LogType,T>.init(log: log, value: transform(value)) }
    }
    
    func mapLog <T> (_ transform: (LogType) -> T) -> Writer<T,ParameterType> where T: Monoid {
        return fold { log, value in Writer<T,ParameterType>.init(log: transform(log), value: value) }
    }
    
    static func lift<A>(_ function: @escaping (ParameterType) -> A) -> (Self) -> Writer<LogType, A> {
        return { $0.map(function) }
    }
    
    
    static func lift<A,Applicative2>(_ function: @escaping (ParameterType, Applicative2.ParameterType) -> A) -> (Self, Applicative2) -> Writer<LogType, A> where Applicative2: WriterType, Applicative2.LogType == LogType {
        return { ap1, ap2 in
            Concrete.pure(f.curry(function)) <*> ap1 <*> ap2
        }
    }
    
    static func lift<A,Applicative2,Applicative3>(_ function: @escaping (ParameterType, Applicative2.ParameterType, Applicative3.ParameterType) -> A) -> (Self, Applicative2, Applicative3) -> Writer<LogType, A> where Applicative2: WriterType, Applicative3: WriterType, Applicative2.LogType == LogType, Applicative3.LogType == LogType {
        return { ap1, ap2, ap3 in
            Concrete.pure(f.curry(function)) <*> ap1 <*> ap2 <*> ap3
        }
    }
}

// MARK: - Cartesian

public extension WriterType {
    static func zip <W1,W2> (_ first: W1, _ second: W2) -> Writer<Product<W1.LogType,W2.LogType>,(W1.ParameterType,W2.ParameterType)> where W1: WriterType, W2: WriterType, LogType == Product<W1.LogType,W2.LogType>, ParameterType == (W1.ParameterType, W2.ParameterType) {
        return first.fold { l1, v1 in second.fold { l2, v2 in Writer.init(log: Product.init(l1, l2), value: (v1, v2)) } }
    }
    
    static func zipMerge <W1,W2> (_ first: W1, _ second: W2) -> Writer<W1.LogType,(W1.ParameterType,W2.ParameterType)> where W1: WriterType, W2: WriterType, W1.LogType == W2.LogType, LogType == W1.LogType, ParameterType == (W1.ParameterType, W2.ParameterType) {
        return first.fold { l1, v1 in second.fold { l2, v2 in Writer.init(log: l1 <> l2, value: (v1, v2)) } }
    }
}

// MARK: - Applicative

public extension WriterType {
    static func pure(_ value: ParameterType) -> Writer<LogType,ParameterType> {
        return Writer.init(log: .empty, value: value)
    }
    
    func apply <W,T> (_ transform: W) -> Writer<LogType,T> where W: WriterType, W.ParameterType == (ParameterType) -> T, W.LogType == LogType {
        return Writer.zipMerge(self, transform).map { value, function in function(value) }
    }
    
    static func <*> <W,T> (lhs: W, rhs: Self) -> Writer<LogType,T> where W: WriterType, W.ParameterType == (ParameterType) -> T, W.LogType == LogType {
        return Writer.zipMerge(lhs, rhs).map { function, value in function(value) }
    }
}

// MARK: - Traversable

public extension WriterType {
    typealias Traversed<Applicative> = Writer<LogType,Applicative.ParameterType> where Applicative: TypeConstructor
    
    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> [Traversed<Applicative>] where Applicative: ArrayType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }
    
    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Future<Traversed<Applicative>> where Applicative: FutureType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }

	func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Effect<Traversed<Applicative>> where Applicative: EffectType {
		return fold { log, value in
			Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
		}
	}

    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Optional<Traversed<Applicative>> where Applicative: OptionalType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }
    
    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Reader<Applicative.EnvironmentType,Traversed<Applicative>> where Applicative: ReaderType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }
    
    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Result<Applicative.ErrorType,Traversed<Applicative>> where Applicative: ResultType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }

    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> State<Applicative.StateParameterType,Traversed<Applicative>> where Applicative: StateType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }

    func traverse<Applicative>(_ transform: (ParameterType) -> Applicative) -> Writer<Applicative.LogType,Traversed<Applicative>> where Applicative: WriterType {
        return fold { log, value in
            Applicative.Concrete.pure(f.curry(Traversed<Applicative>.init)) <*> Applicative.Concrete.pure(log) <*> transform(value)
        }
    }
}

// MARK: - Monad

public extension WriterType where ParameterType: WriterType, ParameterType.LogType == LogType {
    func joined() -> Writer<LogType,ParameterType.ParameterType> {
        return fold { externalLog, externalValue in
            externalValue.fold { internalLog, internalValue in
                Writer.init(log: externalLog <> internalLog, value: internalValue)
            }
        }
    }
}

public extension WriterType {
    func flatMap <W> (_ transform: (ParameterType) -> W) -> Writer<LogType,W.ParameterType> where W: WriterType, W.LogType == LogType {
        return map(transform).joined()
    }
}

// MARK: - Utility

public extension WriterType {
    func tell(_ newLog: LogType) -> Writer<LogType,ParameterType> {
        let (oldLog,value) = run
        return Writer.init(log: oldLog <> newLog, value: value)
    }
    
    func remember(_ oldLog: LogType) -> Writer<LogType,ParameterType> {
        let (newLog,value) = run
        return Writer.init(log: oldLog <> newLog, value: value)
    }
    
    func read(_ transform: (ParameterType) -> LogType) -> Writer<LogType,ParameterType> {
        let (log,value) = run
        return Writer.init(log: log <> transform(value), value: value)
    }
    
    var listen: Writer<LogType,(LogType,ParameterType)> {
        let (log,value) = run
        return Writer(log: log, value: (log,value))
    }

	func logValue<NewLog>(_ transform: (LogType,ParameterType) -> NewLog) -> Writer<NewLog,ParameterType> {
		let (_,value) = run
		return mapLog { log in transform(log,value) }
	}

	func swap<T>(_ transform: (ParameterType) -> T) -> Writer<T,LogType> where T: Monoid {
		let (log,value) = run
		return Writer<T,LogType>.init(log: transform(value), value: log)
	}

	func consumeLog(_ consumer: (LogType) -> ()) -> ParameterType {
		let (log,value) = run
		consumer(log)
		return value
	}

	var discardLog: ParameterType {
		let (_,value) = run
		return value
	}
}

// MARK: - Algebra

extension Writer: Magma where ParameterType: Magma {
	public static func <> (lhs: Writer, rhs: Writer) -> Writer<LogType,ParameterType> {
		let (lLog,lValue) = lhs.run
		let (rLog,rValue) = rhs.run
		return Writer<LogType,ParameterType>.init(log: lLog <> rLog, value: lValue <> rValue)
	}
}

extension Writer: Semigroup where ParameterType: Semigroup {}

extension Writer: Monoid where ParameterType: Monoid {
	public static var empty: Writer<LogType,ParameterType> {
		return Writer<LogType,ParameterType>.init(log: .empty, value: .empty)
	}
}

public extension WriterType where ParameterType: Monoid {
	func swapped() -> Writer<ParameterType,LogType> {
		return swap(f.identity)
	}
}
