output "summary" {
  description = "EKS node group summary."
  value = {
    cluster_name    = aws_eks_node_group.this.cluster_name
    node_group_name = aws_eks_node_group.this.node_group_name
    workload        = var.node_group_suffix
    status          = aws_eks_node_group.this.status
    node_role_arn   = aws_iam_role.node.arn
    scaling_config = {
      desired_size = aws_eks_node_group.this.scaling_config[0].desired_size
      min_size     = aws_eks_node_group.this.scaling_config[0].min_size
      max_size     = aws_eks_node_group.this.scaling_config[0].max_size
    }
  }
}
