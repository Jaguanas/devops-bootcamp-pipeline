import os
import boto3

region = "eu-west-1"
cluster = "team3-app-cluster"
service_name = "team3-app-service"
container_name = "team3-app"

# Пока тестируем с latest.
# Позже заменим на уникальный тег Git-коммита.
image = os.environ.get("IMAGE_URI", "ricardssmans/app:latest")

ecs = boto3.client("ecs", region_name=region)

response = ecs.describe_services(
    cluster=cluster,
    services=[service_name]
)

if response.get("failures") or not response["services"]:
    raise RuntimeError("ECS Service not found")

service = response["services"][0]
if service["status"] != "ACTIVE":
    raise RuntimeError("ECS Service is not active")

task = ecs.describe_task_definition(
    taskDefinition=service["taskDefinition"]
)["taskDefinition"]

found = False
for container in task["containerDefinitions"]:
    if container["name"] == container_name:
        container["image"] = image
        found = True

if not found:
    raise RuntimeError("Application container not found")

print("Current task:", service["taskDefinition"])
print("New image:", image)

# Safe preview: no AWS resources changed
if os.environ.get("DEPLOY_ENABLED") != "yes":
    print("DRY RUN: no changes made")
    raise SystemExit(0)

allowed = [
    "family", "taskRoleArn", "executionRoleArn",
    "networkMode", "containerDefinitions", "volumes",
    "placementConstraints", "requiresCompatibilities",
    "cpu", "memory", "pidMode", "ipcMode",
    "proxyConfiguration", "ephemeralStorage",
    "runtimePlatform", "inferenceAccelerators"
]

definition = {k: task[k] for k in allowed if k in task}

registered = ecs.register_task_definition(
    **definition
)

new_arn = registered["taskDefinition"]["taskDefinitionArn"]

ecs.update_service(
    cluster=cluster,
    service=service_name,
    taskDefinition=new_arn
)

print("Deployment started:", new_arn)

ecs.get_waiter("services_stable").wait(
    cluster=cluster,
    services=[service_name],
    WaiterConfig={"Delay": 15, "MaxAttempts": 40}
)

print("ECS Service is stable")
