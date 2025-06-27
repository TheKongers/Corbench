# infra: CLI Tool for Managing Kubernetes Clusters

`infra` is a CLI tool designed to create, scale, and delete Kubernetes clusters and deploy manifest files.

## Table of Contents

1. [Parsing of Files](#parsing-of-files)
2. [Usage and Examples](#usage-and-examples)
   - [General Flags](#general-flags)
   - [Commands](#commands)
     - [EKS Commands](#eks-commands)
3. [Building Docker Image](#building-docker-image)

## Parsing of Files

Files passed to `infra` will be parsed using Go templates. To skip parsing and load the file as is, use the `noparse` suffix.

- **Parsed File**: `somefile.yaml`
- **Non-Parsed File**: `somefile_noparse.yaml`

## Usage and Examples

### General Flags

```txt
usage: infra [<flags>] <command> [<args> ...]

The prometheus/test-infra deployment tool

Flags:
  -h, --help           Show context-sensitive help (also try --help-long and --help-man).
  -f, --file=FILE ...  YAML file or folder describing the parameters for the object that will be deployed.
  -v, --vars=VARS ...  Substitutes the token holders in the YAML file. Follows standard Go template formatting (e.g., {{ .hashStable }}).
```

### Commands

#### EKS Commands

- **eks info**
  ```bash
  eks info -v hashStable:COMMIT1 -v hashTesting:COMMIT2
  ```

- **eks cluster create**
  ```bash
  eks cluster create -a credentials -f FileOrFolder
  ```

- **eks cluster delete**
  ```bash
  eks cluster delete -a credentials -f FileOrFolder
  ```

- **eks nodes create**
  ```bash
  eks nodes create -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test \
    -v EKS_SUBNET_IDS:subnetId1,subnetId2,subnetId3
  ```

- **eks nodes delete**
  ```bash
  eks nodes delete -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test \
    -v EKS_SUBNET_IDS:subnetId1,subnetId2,subnetId3
  ```

- **eks nodes check-running**
  ```bash
  eks nodes check-running -a credentials -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test \
    -v EKS_SUBNET_IDS:subnetId1,subnetId2,subnetId3
  ```

- **eks nodes check-deleted**
  ```bash
  eks nodes check-deleted -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test \
    -v EKS_SUBNET_IDS:subnetId1,subnetId2,subnetId3
  ```

- **eks resource apply**
  ```bash
  eks resource apply -a credentials -f manifestsFileOrFolder -v hashStable:COMMIT1 -v hashTesting:COMMIT2
  ```

- **eks resource delete**
  ```bash
  eks resource delete -a credentials -f manifestsFileOrFolder -v hashStable:COMMIT1 -v hashTesting:COMMIT2
  ```

## Building Docker Image

To build the Docker image for `infra`, use the following command:

```bash
docker build -t prominfra/infra:master .
```
