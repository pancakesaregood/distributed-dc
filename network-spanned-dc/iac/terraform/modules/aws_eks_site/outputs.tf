output "summary" {
  description = "EKS cluster summary."
  value = {
    cluster_name              = aws_eks_cluster.this.name
    cluster_arn               = aws_eks_cluster.this.arn
    endpoint                  = aws_eks_cluster.this.endpoint
    version                   = aws_eks_cluster.this.version
    status                    = aws_eks_cluster.this.status
    cluster_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    role_arn                  = aws_iam_role.eks_cluster.arn
    oidc_issuer               = aws_eks_cluster.this.identity[0].oidc[0].issuer
  }
}
