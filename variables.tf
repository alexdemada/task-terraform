variable "pm_api_url" {
  type    = string
  default = "https://10.8.200.100:8006/api2/json"
}

variable "pm_user" {
  type    = string
  default = "root@pam"
}

variable "pm_password" {
  type    = string
  default = "Admindevops8"
}

variable "vm_name" {
  type    = string
  default = "devopsmaster"
}

variable "vm_memory" {
  type    = number
  default = 4096
}

variable "vm_cores" {
  type    = number
  default = 4
}