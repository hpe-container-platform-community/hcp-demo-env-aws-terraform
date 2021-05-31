// retrieve the ingress gateway host IPs with
/*

    kubectl get po -l istio=ingressgateway -n istio-system \
      -o jsonpath='{.items[*].status.hostIP}'
     
    // e.g. 10.1.0.193 10.1.0.132 10.1.0.174
     
*/

resource "aws_route53_record" "knative" {
    zone_id = aws_route53_zone.main.zone_id
    name = "*.knative.${var.dns_zone_name}"
    type = "A"
    ttl = "300"
    records = [ "10.1.0.193","10.1.0.132","10.1.0.174" ] 
    
    multivalue_answer_routing_policy = true
}


// now patch knative with the domain
/*

kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.samdom.example.com":""}}'
  
  
*/