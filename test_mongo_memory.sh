#!/bin/bash

MONGO_PID=$(pidof mongod)

echo "=== MongoDB Memory Test ==="
echo "Process ID: $MONGO_PID"
echo ""

echo "Baseline memory:"
grep "VmRSS" /proc/$MONGO_PID/status

echo ""
echo "Running \$unwind query..."
mongosh test --quiet --eval '
db.data.aggregate([
  { $unwind: "$companies" },
  { $unwind: "$companies.company.departments" },
  { $unwind: "$companies.company.departments.teams" },
  { $unwind: "$companies.company.departments.teams.projects" },
  { $match: {
      "companies.company.departments.teams.projects.status": "in_progress",
      "companies.company.departments.teams.projects.technologies": "Python"
  }}
]).itcount()
' > /dev/null

echo "After \$unwind:"
grep "VmRSS" /proc/$MONGO_PID/status

sleep 2

echo ""
echo "Running \$reduce query..."
mongosh test --quiet --eval '
db.data.aggregate([{
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
}}]}).itcount()
' > /dev/null

echo "After \$reduce:"
grep "VmRSS" /proc/$MONGO_PID/status
