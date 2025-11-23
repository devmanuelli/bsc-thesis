type EmployeeRequest {
    id: string
}

type EmployeeData {
    name: string
}

type PayrollData {
    salary: int
}

interface EmployeeInterface {
    RequestResponse:
        getEmployee(EmployeeRequest)(EmployeeData)
}

interface PayrollInterface {
    RequestResponse:
        getPayroll(EmployeeRequest)(PayrollData)
}
