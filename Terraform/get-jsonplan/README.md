# Terraform helper

Outputs a JSON formated plan from a workspace, using the workspaces latest planned run.
Useful for getting and testing your plan for policy checks (Rego Playground for example)

## Parameters

- organization = the terraform organisation you are retrieveing the plan from
- workspace_is = The ID for the workspace you are wanting the JSON formwatted plan from