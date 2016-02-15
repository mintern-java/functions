## Java Functions

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/net.mintern/functions-ternary-core/badge.svg)](https://maven-badges.herokuapp.com/maven-central/net.mintern/functions-ternary-core)
[![Javadoc](https://javadoc-emblem.rhcloud.com/doc/net.mintern/functions-ternary-core/badge.svg)](http://www.javadoc.io/doc/net.mintern/functions-ternary-core)

- [Every Java `@FunctionalInterface` you want!](#every-java-functionalinterface-you-want)
- [Checked interfaces](#checked-interfaces)
- [Static methods](#static-methods)
- [But `Stream.map` takes a `Function`!](#but-streammap-takes-a-function)
- [`bind`](#bind)
- [Sensible packaging](#sensible-packaging)
- [Contributing](#contributing)
    - [Building](#building)
    - [Where are all the source files?](#where-are-all-the-source-files)
- [What's next?](#whats-next)

To include the full library in your project (not recommended!), add the
following to your POM:
```xml
<project>
...
    <dependencies>
        ...
        <dependency>
            <groupId>net.mintern</groupId>
            <artifactId>functions-ternary-all</artifactId>
            <version>2.0</version>
        </dependency>
        ...
    </dependencies>
...
</project>
```

You almost certainly do not want or need all of the 16,000+ (!) classes, so
replace `ternary-all` with [the subset you need](#sensible-packaging).

### Every Java `@FunctionalInterface` you want!

This project provides `@FunctionalInterface`s for every possible function of 0
to 3 arguments. It enumerates all combinations of parameters and return values
for all Java types:

- `void`
- `boolean`
- `byte`
- `short`
- `char`
- `int`
- `long`
- `float`
- `double`
- `Object`

The functions are named in a logical way that is well-suited for automatic code
generation but remains readable. For example:

- `NilToLong`: `long call()`
- `ObjIntToNil<T>`: `void call(T t, int i)`
- `BoolToShort`: `short call(boolean bool)`
- `DblFloatByteToChar`: `char call(double d, float fl, byte b)`
- `ObjObjObjToObj<T, U, V, R>`: `R call(T t, U u, V v)`

### Checked interfaces

As with Java 8's `java.util.function` package, none of the above methods throw
exceptions. Especially in the case of `IOException` this can lead to lambdas
that are much uglier than necessary. To solve this problem, this project also
provides a checked version for every interface, indicated by its presence in a
`.checked` package and an `E` suffix:

- `NilToLongE<E extends Exception>`: `long call() throws E`
- `ObjIntToNilE<T, E extends Exception>`: `void call(T t, int i) throws E`
- `BoolToShortE<E extends Exception>`: `short call(boolean bool) throws E`

...and so on. This means that you can now write a method like this:

```java
void withReader(Path p, ObjToNilE<BufferedReader, IOException> f) throws IOException {
    try (BufferedReader r = Files.newBufferedReader(p, Charset.forName("UTF-8"))) {
        f.call(r);
    }
}
```

and call it as follows:

```java
withReader(path, reader -> {
    String line;
    while ((line = reader.readLine()) != null) { // <-- may throw!
        // do something with line
    }
});
```

This works! In other words, there's no need to catch and wrap the exception when
you use these checked interfaces in obvious places.

### Static methods

It gets better than that! Even when a method expects an unchecked functional
interface, you can still avoid the exception handling boilerplate:

```java
Stream<Path> paths = ...;
String[] firstLines = paths
        .map(ObjToObj.uncheckedIO(path -> Files.newBufferedReader(path, utf8)))
        .map(ObjToObj.uncheckedIO(BufferedReader::readLine))
        .toArray(String[]::new);
```

Both `newBufferedReader` and `getLine` can throw exceptions, but the
`uncheckedIO` method transparently converts an `ObjToObjE<T, U, IOException>`
to an `ObjToObj<T, U>`, wrapping any thrown `IOException` with an
`UncheckedIOException`!

A more general `unchecked(Function<? super E, RuntimeException> wrap, f)` is
also provided that allows you to wrap your exception however you wish, or you
can use `unchecked(f)` to simply wrap it in a `RuntimeException`.

### But `Stream.map` takes a `Function`!

I'm glad you noticed that! Any `net.mintern.functions` interface that has the
same signature as a Java interface extends the Java one, meaning that you can
just plug it right in! For example:

- `NilToNil extends Runnable`
- `ObjIntToNil<T> extends ObjIntConsumer<T>`
- `ObjObjToObj<T, U, R> extends BiFunction<T, U, R>`

and so on. There is one exception: as of 2.0, `NilToObjE<V>` doesn't extends
`Callable<V>`, as this breaks lambda type inference. See #2.

### `bind`

In case that's not enough, every non-nullary function provides both `static`
and instance `bind` and `rbind` methods. If you are tired of this pattern:

```java
hexStrings.mapToInt(hexString -> Integer.valueOf(hexString, 16))
```

then you can replace it with:

```java
hexStrings.mapToInt(ObjIntToInt.rbind(Integer::valueOf, 16))
```

It's not a huge win in this case, but perhaps you'll find places where it is!

### Sensible packaging

As you might imagine, providing all of these type combinations results in an
explosion in the number of classes. In order to avoid pulling in *so* many
functions that you are unlikely to use, I've split them up as follows:

- **nullary** (*20 classes*): checked and unchecked functions to produce every
  type (a la Java's `Supplier`s)
- **unary-core** (*48 classes*): 1-argument functions that accept `int`,
  `long`, `double`, or `Object`, returning `void`, `boolean`, `int`, `long`,
  `double`, or `Object`. The unchecked unary-core functions correspond to
  Java's `Function` and `Predicate` types.
- **unary-extended** (*96 classes*): unary-core, but with `boolean`, `byte`,
  `char`, and `float` arguments and return values
- **unary-all** (*36 classes*): all of unary-extended, plus `short` types
  (because who uses short?)
- **binary-core** (*192 classes*): like unary-core, but for 2-argument
  functions (includes replacements for `BiFunction`, `ObjIntConsumer`,
  `BiPredicate`, etc.)
- **binary-extended** (*960 classes*):  you get the idea
- **binary-all** (*468 classes*)
- **ternary-core** (*768 classes*): exactly what you think it is
- **ternary-extended** (*8448 classes*): not a typo!
- **ternary-all** (*5364 classes*)

Only pull in what you need!

Note that every `extended` package pulls in its corresponding `core` package,
in addition to the other `extended` packages that take fewer arguments.
Likewise, `all` pulls in `extended`. This means that a dependency on
`binary-extended` will also pull in `binary-core`, `unary-extended`,
`unary-core`, and `nullary`.

### Contributing

I will happily accept Pull Requests. If you have any questions, ask away.

#### Building

In the root directory, run `mvn install`. That will build everything.

#### Where are all the source files?

For this project, I used an ancient-but-solid (by modern standards) template
language called [FreeMarker](http://freemarker.org) to provide a template that
generates all of the source. A handy [FreeMarker PreProcessor
(FMPP)](http://fmpp.sourceforge.net/index.html)&mdash;in conjunction with an
[FMPP Maven plugin](https://code.google.com/p/freemarkerpp-maven-plugin/) that
I came across on [Stack
Overflow](http://stackoverflow.com/a/3925944/1237044)&mdash;turns that
template into thousands of Java source files.

Some data definitions are in semicolon-delimited (`scsv`!) files in the
[FreeMarker
configuration](https://github.com/mintern-java/functions/tree/master/src/main/fmpp),
but most of the logic for generating everything is in a single template file:
[Functions.java.ft](https://github.com/mintern-java/functions/blob/master/src/main/fmpp/templates/net/mintern/functions/Functions.java.ft).

### What's next?

I'll be using this library to build out modern `Pair` and `Triple` libraries,
`Either` types, `Collection` and `Stream` (and `BiStream` and `TriStream`)
enhancements, and more. If you like this library, keep an eye on the
[mintern-java](https://github.com/mintern-java) organization for new ones!
