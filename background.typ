= Background: The Jolie Programming Language <background>

This chapter provides the essential background for understanding the contributions of this thesis. We begin by examining the fundamental challenges of distributed systems programming---heterogeneity, fault handling, and evolution---and the verbosity they introduce in traditional languages. We then introduce Jolie, a service-oriented programming language designed to address these challenges through protocol independence and tree-structured variables. The chapter explores how Jolie's architecture separates communication protocols from business logic, and how its tree variable model eliminates impedance mismatch with hierarchical data formats. Finally, we examine existing approaches to querying tree-structured data, focusing on the TQuery library and the performance limitations that arise from moving data between a program and the library and its deep cloning semantics, motivating the need for native language primitives.

== Challenges in Distributed Systems Programming

=== What & Why Distributed Systems?

A distributed system is a network of software components that communicate by exchanging messages. Service-Oriented Computing (SOC) structures these distributed systems around _services_---independent applications that offer operations and communicate through message passing. This paradigm draws a natural parallel with Object-Oriented Programming:

#table(
  columns: (auto, auto),
  align: (center, center),
  table.header([*Service-Oriented*], [*Object-Oriented*]),
  table.hline(),
  [Services], [Objects],
  [Operations], [Methods],
)

Just as objects encapsulate state and expose methods, services encapsulate functionality and expose operations. The key difference: services communicate across process and network boundaries via message passing, not method calls.

These systems are ubiquitous at every scale: from microservices architectures to cloud platforms. However, programming these systems introduces challenges that compound with those of local programming.
Despite their complexity, distributed systems offer compelling advantages:

- *Scalability*: Workloads distribute across multiple machines, scaling horizontally as demand grows.
- *Fault tolerance*: Redundant services continue operating when individual components fail.
- *Geographic distribution*: Services deployed close to users reduce latency.
- *Organizational alignment*: Different teams independently develop and deploy services that integrate through well-defined interfaces.
- *Technology heterogeneity*: Each service uses the most appropriate technology for its task---Python for machine learning, Rust for performance-critical components, Java for business logic.

These benefits explain why modern architectures---from microservices to cloud platforms---embrace distribution despite its inherent complexity.

=== The Verbosity of Low-Level Communications

This section demonstrates how even basic communication operations require extensive boilerplate code for proper error handling and resource management, both on the client and server side.

Consider one of the most basic distributed operation: sending data over a TCP socket. A naive Java implementation:

```java
SocketChannel socketChannel = SocketChannel.open();
socketChannel.connect(new InetSocketAddress("http://someurl.com", 80));
Buffer buffer = . . .; // byte buffer
while (buffer.hasRemaining()) {
    channel.write(buffer);
}
```

This code is incomplete---it handles neither exceptions nor resource cleanup. A correct implementation requires extensive boilerplate:

```java
SocketChannel socketChannel = SocketChannel.open();
try {
    socketChannel.connect(new InetSocketAddress("http://someurl.com", 80));
    Buffer buffer = . . .;
    while (buffer.hasRemaining()) {
        channel.write(buffer);
    }
}
catch (UnresolvedAddressException e) { . . . }
catch (SecurityException e) { . . . }
/* . . . many catches later . . . */
catch (IOException e) { . . . }
finally { channel.close(); }
```

Server-side code is even more complex. Handling asynchronous events on a channel requires selectors, key registration, and manual event dispatch:

```java
Selector selector = Selector.open();
channel.configureBlocking(false);
SelectionKey key = channel.register(selector, SelectionKey.OP_READ);
while(true) {
    int readyChannels = selector.select();
    if(readyChannels == 0) continue;
    Set<SelectionKey> selectedKeys = selector.selectedKeys();
    Iterator<SelectionKey> keyIterator = selectedKeys.iterator();
    while(keyIterator.hasNext()) {
        SelectionKey key = keyIterator.next();
        if(key.isAcceptable()) { /* connection accepted */ }
        else if (key.isConnectable()) { /* connection established */ }
        else if (key.isReadable()) { /* ready for reading */ }
        else if (key.isWritable()) { /* ready for writing */ }
        keyIterator.remove();
    }
}
```

And this still omits exception handling. Further questions arise: What if different operations share the same channel? What data format for transmission? How to validate message types? How to change protocols after deployment?

=== Core Challenges

In addition to verbosity, distributed systems face fundamental challenges that arise from coordinating multiple independent services:

*Heterogeneity.* Different applications within the same system may use different communication mediums (Bluetooth, TCP/IP), different data protocols (HTTP, SOAP, XML-RPC), or different versions of the same protocol (SOAP 1.1 vs 1.2). For example, an internal high-performance service might use raw TCP with a binary protocol for speed, while a public-facing API uses HTTP with JSON for browser compatibility. Integrating these systems requires translation layers that understand both protocols---code that is tedious to write and maintain, and error-prone to maintain.

*Faults.* Distributed transactions span multiple services that can fail independently. Consider a purchase: a client contacts a store, the store requests payment from a bank, the client authenticates with the bank, and finally the store delivers goods. At any step, a service may be offline, a payment may be rejected, or delivery may fail---each requiring coordinated recovery.

*Evolution.* Distributed systems evolve independently. Each service may be maintained by different teams or organizations. Updates may introduce incompatible protocols, changed interfaces, or new behavioral requirements (e.g., adding authentication). Without careful design, evolution breaks existing integrations.

== Jolie: A Service-Oriented Approach

Jolie is a service-oriented programming language designed to address the challenges of distributed systems programming through native support for Service-Oriented Computing. Jolie embodies SOC through three fundamental principles:

1. *Everything is a service*: The basic computational unit is a service, not a class or function.
2. *Services offer operations*: Each service exposes operations that define its interface.
3. *Services invoke operations*: Services interact by sending messages to operations offered by other services.

=== Hello World in Jolie

Even a minimal Jolie program demonstrates these principles:

```jolie
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("Hello, world!")()
    }
}
```

This program embeds the `Console` service and invokes its `println` operation. The syntax `operation@Service(request)(response)` makes service invocation explicit---every interaction is a message exchange between services.

=== Protocol Independence: A First Glimpse

Jolie's distinctive feature is _protocol independence_. Consider a calculator service exposed over HTTP with JSON:

```jolie
service Calculator {
    inputPort CalculatorPort {
        Location: "socket://localhost:8000"
        Protocol: http { .format = "json" }
        Interfaces: CalculatorInterface
    }
    main {
        [add(request)(response) {
            response = request.x + request.y
        }]
    }
}
```

To switch to raw TCP with Jolie's native binary protocol (SODEP), only the port declaration changes:

```jolie
inputPort CalculatorPort {
    Location: "socket://localhost:8000"
    Protocol: sodep
    Interfaces: CalculatorInterface
}
```

The business logic remains untouched. No code changes, no recompilation---just a declaration change. This separation between _what_ a service does and _how_ it communicates is fundamental to Jolie's design.

#include "protocol-separation.typ"

#include "tree-variables.typ"
