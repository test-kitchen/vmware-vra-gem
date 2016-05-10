# vmware-vra-gem CHANGELOG

## v1.6.0 (2016-05-10)
* [pr#28](https://github.com/chef-partners/vmware-vra-gem/pull/28) Remove rest-client dependency

## v1.5.4 (2016-04-27)
* [pr#29](https://github.com/chef-partners/vmware-vra-gem/pull/29) Bug fix: handle more gracefully the situations where a resource or catalog item is missing data in the API response

## v1.5.3 (2016-04-18)
* [pr#25](https://github.com/chef-partners/vmware-vra-gem/pull/25) Bug fix: use the proper exception helper method when raising exceptions encountered during HTTP HEAD requests

## v1.5.2 (2016-04-01)
* [pr#22](https://github.com/chef-partners/vmware-vra-gem/pull/22) Bug fix: Using FFI_Yajl to encode JSON rather than the #to_json method

## v1.5.1 (2016-03-11)
* [pr#19](https://github.com/chef-partners/vmware-vra-gem/pull/19) Treating a `MachineActivated` state as a machine in the process of being turned on. Fixes abnormal behavior in vRA 7.x.

## v1.5.0 (2015-11-18)
* [pr#15](https://github.com/chef-partners/vmware-vra-gem/pull/15) Adding support for Infrastructure.Cloud resources, such as EC2 resources created by vRA catalog items

## v1.4.0
* [pr#14](https://github.com/chef-partners/vmware-vra-gem/pull/14) Adding appropriate methods for managing the bearer_token

## v1.3.0
* [pr#13](https://github.com/chef-partners/vmware-vra-gem/pull/13) Additional methods to support a vRA driver for Chef Provisioning

## v1.2.0
* [pr#11](https://github.com/chef-partners/vmware-vra-gem/pull/11) Ability to set paginated results page size, which is a workaround for issue reported in #10 regarding duplicate items returned in paginated results.

## v1.1.0
* [pr#9](https://github.com/chef-partners/vmware-vra-gem/pull/9) Mask password and bearer token in console/debug/log output.
  Thanks to [@rubytester](https://github.com/rubytester) for the idea and initial proposal to address in [pr#7](https://github.com/chef-partners/vmware-vra-gem/pull/7)

## v1.0.0
* Initial release.
