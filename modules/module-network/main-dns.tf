
/* Prototype for ROUTE 53 internal IP addresses


resource "aws_vpc_dhcp_options" "mydhcp" {
    domain_name = var.dns_zone_name
    domain_name_servers = ["AmazonProvidedDNS"]
    tags = {
        Name = "${var.project_id}-vpc-dhcp-options"
        Project = var.project_id
        user = var.user
        deployment_uuid = var.deployment_uuid
    }
}
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id = aws_vpc.main.id
    dhcp_options_id = aws_vpc_dhcp_options.mydhcp.id
}

// DNS PART ZONE AND RECORDS
resource "aws_route53_zone" "main" {
    name = var.dns_zone_name
    vpc {
        vpc_id = aws_vpc.main.id
    }
    comment = var.project_id
}

resource "aws_route53_record" "controller" {
    zone_id = aws_route53_zone.main.zone_id
    name = "controller.${var.dns_zone_name}"
    type = "A"
    ttl = "300"
    records = [ var.controller_private_ip ] 
}

resource "aws_route53_record" "ad" {
    count = var.ad_server_enabled ? 1 : 0
    zone_id = aws_route53_zone.main.zone_id
    name = "ad.${var.dns_zone_name}"
    type = "A"
    ttl = "300"
    records = [ var.ad_private_ip ] 
}

// TODO add workers, gateway, RDP

*/

