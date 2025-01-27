# modules/security/main.tf

# Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}

# Cluster egress rule - allows cluster to make outbound requests
resource "aws_security_group_rule" "cluster_egress" {
  description       = "Allow cluster egress access to the Internet"
  protocol         = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks      = ["0.0.0.0/0"]
  from_port        = 0
  to_port          = 0
  type             = "egress"
}

# Cluster ingress rule - allows nodes to communicate with control plane
resource "aws_security_group_rule" "cluster_ingress_node" {
  description              = "Allow pods to communicate with the cluster API Server"
  protocol                = "tcp"
  security_group_id       = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  from_port               = 443 # Kubernetes API port
  to_port                 = 443
  type                    = "ingress"
}

# Node Security Group
resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-node-sg"
  }
}

resource "aws_security_group_rule" "nodes_egress" {
  description       = "Allow node egress access to the Internet"
  protocol         = "-1" # all protocols
  security_group_id = aws_security_group.nodes.id
  cidr_blocks      = ["0.0.0.0/0"]
  from_port        = 0
  to_port          = 0
  type             = "egress"
}

resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  protocol                = "-1"
  security_group_id       = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
  from_port               = 0
  to_port                 = 65535
  type                    = "ingress"
}

# Control plane to node communication rule
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  protocol                = "tcp"
  security_group_id       = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  from_port               = 1025
  to_port                 = 65535
  type                    = "ingress"
}