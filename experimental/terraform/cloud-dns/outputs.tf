/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "type" {
  description = "The DNS zone type."
  value       = var.type
}

output "name" {
  description = "The DNS zone name."

  value = element(
    concat(
      google_dns_managed_zone.peering.*.name,
      google_dns_managed_zone.forwarding.*.name,
      google_dns_managed_zone.private.*.name,
      google_dns_managed_zone.public.*.name,
    ),
    0,
  )
}

output "domain" {
  description = "The DNS zone domain."

  value = element(
    concat(
      google_dns_managed_zone.peering.*.dns_name,
      google_dns_managed_zone.forwarding.*.dns_name,
      google_dns_managed_zone.private.*.dns_name,
      google_dns_managed_zone.public.*.dns_name,
    ),
    0,
  )
}

output "name_servers" {
  description = "The DNS zone name servers."

  value = flatten(
    concat(
      google_dns_managed_zone.peering.*.name_servers,
      google_dns_managed_zone.forwarding.*.name_servers,
      google_dns_managed_zone.private.*.name_servers,
      google_dns_managed_zone.public.*.name_servers,
    ),
  )
}
