// Copyright 2019 The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main // import "github.com/prometheus/test-infra/infra"

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"gopkg.in/alecthomas/kingpin.v2"

	"corbench/pkg/provider"
	"corbench/pkg/provider/eks"
)

func main() {
	log.SetFlags(log.Ltime | log.Lshortfile)

	dr := provider.NewDeploymentResource()

	app := kingpin.New(filepath.Base(os.Args[0]), "The prometheus/test-infra deployment tool")
	app.HelpFlag.Short('h')
	app.Flag("file", "yaml file or folder  that describes the parameters for the object that will be deployed.").
		Short('f').
		ExistingFilesOrDirsVar(&dr.DeploymentFiles)
	app.Flag("vars", "When provided it will substitute the token holders in the yaml file. Follows the standard golang template formating - {{ .hashStable }}.").
		Short('v').
		StringMapVar(&dr.FlagDeploymentVars)

	// EKS based commands
	e := eks.New(dr)
	k8sEKS := app.Command("eks", "Amazon Elastic Kubernetes Service - https://aws.amazon.com/eks").
		Action(e.SetupDeploymentResources)
	k8sEKS.Flag("auth", "filename which consist eks credentials.").
		PlaceHolder("credentials").
		Short('a').
		StringVar(&e.Auth)

	k8sEKS.Command("info", "eks info -v hashStable:COMMIT1 -v hashTesting:COMMIT2").
		Action(e.GetDeploymentVars)

	// EKS Cluster operations
	k8sEKSCluster := k8sEKS.Command("cluster", "manage EKS clusters").
		Action(e.NewEKSClient).
		Action(e.EKSDeploymentParse)
	k8sEKSCluster.Command("create", "eks cluster create -a credentials -f FileOrFolder").
		Action(e.ClusterCreate)
	k8sEKSCluster.Command("delete", "eks cluster delete -a credentials -f FileOrFolder").
		Action(e.ClusterDelete)

	// Cluster node-pool operations
	k8sEKSNodeGroup := k8sEKS.Command("nodes", "manage EKS clusters nodegroups").
		Action(e.NewEKSClient).
		Action(e.EKSDeploymentParse)
	k8sEKSNodeGroup.Command("create", "eks nodes create -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test -v EKS_SUBNET_IDS: subnetId1,subnetId2,subnetId3").
		Action(e.NodeGroupCreate)
	k8sEKSNodeGroup.Command("delete", "eks nodes delete -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test -v EKS_SUBNET_IDS: subnetId1,subnetId2,subnetId3").
		Action(e.NodeGroupDelete)
	k8sEKSNodeGroup.Command("check-running", "eks nodes check-running -a credentials -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test -v EKS_SUBNET_IDS: subnetId1,subnetId2,subnetId3").
		Action(e.AllNodeGroupsRunning)
	k8sEKSNodeGroup.Command("check-deleted", "eks nodes check-deleted -a authFile -f FileOrFolder -v ZONE:eu-west-1 -v CLUSTER_NAME:test -v EKS_SUBNET_IDS: subnetId1,subnetId2,subnetId3").
		Action(e.AllNodeGroupsDeleted)

	// K8s resource operations.
	k8sEKSResource := k8sEKS.Command("resource", `Apply and delete different k8s resources - deployments, services, config maps etc.Required variables -v ZONE:us-east-2 -v CLUSTER_NAME:test `).
		Action(e.NewEKSClient).
		Action(e.K8SDeploymentsParse).
		Action(e.NewK8sProvider)
	k8sEKSResource.Command("apply", "eks resource apply -a credentials -f manifestsFileOrFolder -v hashStable:COMMIT1 -v hashTesting:COMMIT2").
		Action(e.ResourceApply)
	k8sEKSResource.Command("delete", "eks resource delete -a credentials -f manifestsFileOrFolder -v hashStable:COMMIT1 -v hashTesting:COMMIT2").
		Action(e.ResourceDelete)

	if _, err := app.Parse(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, fmt.Errorf("Error parsing commandline arguments: %w", err))
		app.Usage(os.Args[1:])
		os.Exit(2)
	}
}
