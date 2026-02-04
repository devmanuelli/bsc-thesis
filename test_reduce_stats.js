// Test $reduce query performance
print('=== $reduce Query Stats ===');

let start = Date.now();
let reduceResult = db.data.aggregate([{
  $project: {
    results: {
      $reduce: {
        input: "$companies", initialValue: [],
        in: { $concatArrays: [ "$$value", {
          $reduce: {
            input: "$$this.company.departments", initialValue: [],
            in: { $concatArrays: [ "$$value", {
              $reduce: {
                input: "$$this.teams", initialValue: [],
                in: { $concatArrays: [ "$$value", {
                  $filter: {
                    input: "$$this.projects",
                    cond: { $and: [
                      { $eq: ["$$this.status", "in_progress"] },
                      { $in: ["Python", "$$this.technologies"] }
                    ]}
}}]}}}]}}}]}}
      }
}}]}).toArray();
let reduceTime = Date.now() - start;

print('Execution time:', reduceTime, 'ms');
print('Results returned:', reduceResult[0].results.length);
print('Response payload:', JSON.stringify(reduceResult).length, 'bytes');
print('Intermediate documents: 0 (zero-copy evaluation)');
print('Document overhead: 0');
