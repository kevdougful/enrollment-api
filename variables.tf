
variable "db_master_password" {
  description = "Master password for Aurora cluster"
  type = string
  sensitive = true
}