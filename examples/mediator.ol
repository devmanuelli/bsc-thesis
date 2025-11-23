/**
 * Jolie Mediator demonstrating Protocol Translation
 *
 * Problem: Two services use different data formats
 *   - Employee Service: HTTP + JSON
 *   - Payroll Service: HTTP + XML
 *
 * Solution: Jolie bridges them automatically
 *   - Converts JSON ↔ XML transparently
 *   - No manual parsing/serialization code needed
 *   - Tree-based data model handles both formats naturally
 */

from console import Console
include "interface.iol"

service MediatorService {
    embed Console as Console

    execution: concurrent

    // Output port for JSON service
    outputPort EmployeeService {
        Location: "socket://localhost:8001"
        Protocol: http {
            .method = "get";
            .format = "json";
            .osc.getEmployee.alias = "/employee?id=%{id}"
        }
        Interfaces: EmployeeInterface
    }

    // Output port for XML service
    outputPort PayrollService {
        Location: "socket://localhost:8002"
        Protocol: http {
            .method = "get";
            .format = "xml";
            .osc.getPayroll.alias = "/payroll?id=%{id}"
        }
        Interfaces: PayrollInterface
    }

    // Unified API exposed by mediator
    inputPort MediatorAPI {
        Location: "socket://localhost:8000"
        Protocol: http {
            .format = "json"
        }
        Interfaces: EmployeeInterface, PayrollInterface
    }

    main {
        [getEmployee(request)(response) {
            println@Console("\n[MEDIATOR] Request for employee: " + request.id)();

            // Call JSON service
            println@Console("  → Calling JSON service...")();
            getEmployee@EmployeeService(request)(empData);
            println@Console("  ← Received JSON: " + empData.name)();

            response << empData
        }]

        [getPayroll(request)(response) {
            println@Console("\n[MEDIATOR] Request for payroll: " + request.id)();

            // Call XML service - Jolie converts JSON → XML automatically
            println@Console("  → Calling XML service...")();
            getPayroll@PayrollService(request)(payrollData);
            println@Console("  ← Received XML (auto converted): $" + payrollData.salary)();

            response << payrollData
        }]
    }
}
