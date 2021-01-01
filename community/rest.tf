resource "oci_core_instance" "rest" {
  display_name        = "rest-${count.index}"
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  shape               = var.rest["shape"]
  subnet_id           = oci_core_subnet.subnet.id
  fault_domain        = "FAULT-DOMAIN-${count.index % 3 + 1}"

  source_details {
    source_id   = var.images[var.region]
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.subnet.id
    hostname_label = "rest-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrw1MzdnciMQS5wd/6yHyylIRo/8IQB9Be8Pl2CnC2R1YkhbvDdnf6Ye0W1s/yroTigaSMHCpYAP+JBYUt8o8LQfTW9dXytnRgNPCFjx1YMdMmBWTXqA2zYI86ggcNfaBSLHDY4uQWOrsi4h40SJX9+jH7/32r5xfm/Y4fvDx/jva0ZdPZfKRgS0vG1QxcAKWhsI21ag62EC7hKWwVsUlMFjZn31yAifGPMs0Sfv4XF1ppV+LkaL87nLjf/Gse+9xHr7WiqTyXkqVpUR6IjlaFOxuhB4jl5t1lek+pYYbzlV0TTDkIrgDd+MeCfwj/xKEYuRo1ICesCKs5mUKLX2L5 root@rcarrascogb"
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "version=${var.confluent["version"]}",
          "edition=${var.confluent["edition"]}",
          "zookeeperNodeCount=${var.zookeeper["node_count"]}",
          "brokerNodeCount=${var.broker["node_count"]}",
          "schemaRegistryNodeCount=${var.schema_registry["node_count"]}",
          file("../scripts/firewall.sh"),
          file("../scripts/install.sh"),
          file("../scripts/kafka_deploy_helper.sh"),
          file("../scripts/rest.sh"),
        ],
      ),
    )
  }

  count = var.rest["node_count"]
}

output "rest_proxy_public_ips" {
  value = join(",", oci_core_instance.rest.*.public_ip)
}

output "rest_proxy_url" {
  value = <<END
http://${oci_core_instance.rest[0].private_ip}:8082/topics
END

}
