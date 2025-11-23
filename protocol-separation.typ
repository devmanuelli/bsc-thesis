== Solving Protocol Heterogeneity

Distributed systems commonly integrate services that communicate via heterogeneous protocols—not every service uses a unique protocol, but the system as a whole must handle multiple incompatible communication standards. This heterogeneity arises from various factors: legacy systems, different organizational standards, or independent development by separate teams. Different applications within the same system may use different communication mediums (Bluetooth, TCP/IP), different data protocols (HTTP, SOAP, XML-RPC), or even different versions of the same protocol (SOAP 1.1 vs 1.2).

A common scenario involves integrating services where one service exposes its API using HTTP with JSON serialization, while another uses HTTP with XML serialization. Critically, these services cannot be easily modified—they may be legacy systems, third-party services, or systems with existing clients that depend on their current protocol.

Consider an organization requiring a unified interface to integrate:
- An *Employee Service* (HTTP + JSON, port 8001)
- A *Payroll Service* (HTTP + XML, port 8002)

The adapter must expose both functionalities through a single, consistent API while handling protocol translation transparently.

=== Traditional Approach: Protocol Adapters

In conventional programming languages, protocol translation necessitates the implementation of wrapper services. A Python-based adapter exemplifies this pattern:

```python
@app.route('/payroll')
def get_payroll():
    emp_id = request.args.get('id', '1')

    # Call XML service
    response = requests.get(f"http://localhost:8002/payroll?id={emp_id}")

    # Parse XML
    root = ET.fromstring(response.text)

    # Extract and convert to JSON
    return jsonify({"salary": int(root.find('salary').text)})
```

This code implements a *protocol adapter*—a software component that encapsulates protocol-specific operations (XML parsing, data extraction, JSON serialization) to bridge the impedance mismatch between heterogeneous systems. While functionally correct, this approach conflates business logic with deployment concerns, resulting in code that is tightly coupled to specific protocol implementations and requires modification whenever protocol details change.

=== Jolie's Approach: Declarative Protocol Separation

Jolie addresses this coupling through a fundamental language design principle: *separation of behavior from deployment* @montesi2014jolie[p. 81]. As stated in the foundational work on Jolie, "the behaviour and deployment of a Jolie program are orthogonal: they can be independently defined and recombined as long as they have compatible typing" @montesi2014jolie[p. 81]. In Jolie, business logic and communication protocols are specified in distinct, orthogonal language constructs.

The equivalent adapter in Jolie demonstrates this separation:

```jolie
service AdapterService {
    inputPort AdapterAPI {  // HOW we transmit
        Location: "socket://localhost:8000"
        Protocol: http { .format = "json" }
        Interfaces: EmployeeInterface, PayrollInterface
    }
    outputPort EmployeeService {
        Location: "socket://localhost:8001"
        Protocol: http {
            .method = "get"; .format = "json";
            .osc.getEmployee.alias = "/employee?id=%{id}"
        }
        Interfaces: EmployeeInterface
    }
    outputPort PayrollService {
        Location: "socket://localhost:8002"
        Protocol: http {
            .method = "get"; .format = "xml";
            .osc.getPayroll.alias = "/payroll?id=%{id}"
        }
        Interfaces: PayrollInterface
    }
    main {  // WHAT we transmit
        [getEmployee(request)(response) {
            getEmployee@EmployeeService(request)(empData);
            response << empData
        }]
        [getPayroll(request)(response) {
            getPayroll@PayrollService(request)(payrollData);
            response << payrollData
        }]
    }
}
```

=== Key Observations

*Separation of Transmission from Logic*: Protocol specifications (HOW we transmit) are isolated in port declarations, while business logic (WHAT we transmit) resides in `main`. Modifying protocols requires no changes to business logic.

*Declarative Protocol Configuration*: The `Protocol` blocks are pure declarations—data formats, communication mediums, endpoint locations. No imperative parsing, serialization, or conversion code.

*Automatic Protocol Translation*: The Jolie runtime handles all protocol operations transparently: serialization to target formats (JSON/XML), deserialization from responses, and data structure mapping according to interface types.

*Type Safety and Error Handling*: The runtime automatically validates both incoming and outgoing data against interface types, detecting type mismatches and protocol violations in both directions without explicit validation code in the business logic.

*Location and Protocol Transparency*: Changing from `localhost:8002` to a remote server, or from HTTP to SOAP, requires only updating port declarations. Business logic remains completely unchanged.

