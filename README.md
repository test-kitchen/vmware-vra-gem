# VMware vRA Gem

[![Gem Version](https://badge.fury.io/rb/vmware-vra.svg)](http://badge.fury.io/rb/vmware-vra)

Client gem for interacting with VMware's vRealize Automation application.

Not all vRA functionality is included in this gem; only API calls necessary
to interact with the catalog, requests, and existing items is included.

The primary goal of this gem is to provide a reusable set of methods in order
to create Chef plugins for knife, test-kitchen, and provisioning.

## Versions

`1.7.0` version can and will support vRA 6 and below.

`2.0.0` version and forward will support vRA 7+.

`3.0.0` version and forward will support vRA 8+.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vmware-vra'
```

And then execute:

```shell
bundle
```

Or install it yourself as:

```shell
gem install vmware-vra
```

## Usage

First, load in the gem.

```shell
require 'vra'
=> true
```

Then, set up your client object. You will need to know your tenant ID from your vRA administrator.

```shell
client = Vra::Client.new(username: 'devmgr@corp.local', password: 'mypassword', tenant: 'mytenant', base_url: 'https://vra.corp.local', verify_ssl: true)
=> #<Vra::Client:0x000000034c0df8 ... >
```

### Catalog Types

To list all the catalog types:

```shell
client.catalog.all_types
 => [#<Vra::CatalogType:0x00007fcde6855370 @id="com.vmw.vro.workflow", @data={"id"=>"com.vmw.vro.workflow", ... ]
```

### Catalog Sources

To list all the catalog sources:

```shell
client.catalog.all_sources
[#<Vra::CatalogSource:0x00007fcde3948c30 @id="2f5b2d5c-6dc2-4ea7-b304-cd8fea5ede0f", @data= ...]
```

And to list the sources that are entitled only:

```shell
client.catalog.entitled_sources(project_id)
=> [#<Vra::CatalogSource:0x00007fcde2a28c00 @id="18102dc2-9e48-487a-93a8-aafab2ecc05 ...]
```

Creating a new source can be done as follows:

```shell
source = Vra::CatalogSource.create(client, name: 'New source', catalog_type_id: 'com.vmw.vro.workflow', project_id: project_id)
 => #<Vra::CatalogSource:0x00007fad651f63b8 ... >
```

### Catalog Items

To list all items in the catalog:

```shell
client.catalog.all_items
 => [#<Vra::CatalogItem:0x00007fe583863b28>, #<Vra::CatalogItem:0x00007fe583863ad8 ... ]
```

To only list the items in the catalog for which you are entitled to request:

```shell
client.catalog.entitled_items(project_id)
=> [#<Vra::CatalogItem:0x00007fe583863b28>, #<Vra::CatalogItem:0x00007fe583863ad8 ... ]
```

To retrive catalog id from catalog name:

```shell
client.catalog.fetch_catalog_items('centos')
 =>
[#<Vra::CatalogItem:0x00007fb734110f60
  @id="f2e8c6ee-dd00-32c4-94c7-0a50046cb2f3",
  @data={
    "name"=>"oe-centos-1633598756_bp",
  ...>
]
```

### Requesting Deployments

When you are ready to request a deployment using a catalog, create a new deployment object:

```shell
request = client.catalog.request(
  catalog_id, 
  image_mapping: 'VRA-nc-lnx-ce8.4-Docker',
  flavor_mapping: 'Small',
  name: 'CentOS VRA8 Test',
  project_id: project_id,
  version: '1'
)
 =>
#<Vra::DeploymentRequest:0x00007fb7340b7438
...
```

To request a deployment from a catalog item, you can use the above method with a project ID that has a cloud template version released to the project.

The ID of the catalog item from which you are requesting the deployment should be also included, and the version of the released cloud template. If the user doesn't specify a version explicitly, the latest version will be fetched automatically and will be used for the request.

Additionally, the name of the deployment should be specified and it should be unique.
The image mapping specifies the OS image for a VM and the flavor mapping specifies the CPU count and RAM of a VM.

If your catalog blueprint item requires additional parameters to successfully submit your request, you may add them:

```shell
request.set_parameter('my_parameter', 'string', 'my value')
```

### Managing the deployment

Now, submit your request!  The client will return a new "Deployment" object you can use to query for status.

```shell
deployment = catalog_request.submit
=> #<Vra::Deployment:0x000000027caea0 ... >

deployment.status
=> "IN_PROGRESS"
```

You can refresh your deployment object to get the latest status:

```shell
deployment.refresh && deployment.status
=> "SUCCESSFUL"
```

You can also save the deployment ID for later, and create a new deployment object at your leisure to follow-up on your deployment request:

```shell
deployment.id
=> "aed22465-02db-481d-b55a-cefe216096a2"

new_deployment = client.deployments.by_id('aed22465-02db-481d-b55a-cefe216096a2')
=> #<Vra::Deployment:0x0000000564ac30 ... >

new_deployment.status
=> "CREATE_SUCCESSFUL"
```

### Deployment Resources

When the deployment request is successful, you can query the resources created as the result of your request. Assuming that the catalog item blueprint we requested only creates a single VM, we can get that resource and learn more information about it:

```shell
resource = deployment.resources.first
=> #<Vra::Resource:0x00000006772e68 ... >

resource.network_interfaces
=> [{"NETWORK_ADDRESS"=>"192.168.110.203", "NETWORK_MAC_ADDRESS"=>"00:50:56:ae:1d:c7", "NETWORK_NAME"=>"vxw-dvs-35-virtualwire-2-sid-5000-Edge_Transport"}]

resource.ip_addresses
=> ["192.168.110.203"]

resource.name
=> "hol-dev-32"
```

If you have the resource_id and the deployment object, you can fetch the resources details as follows

```shell
resource.id
=> "331fd10b-f2a2-40ae-86bc-1255c1ee9a6d"

new_resource = deployment.resource_by_id('331fd10b-f2a2-40ae-86bc-1255c1ee9a6d')
=> #<Vra::Resource:0x000000067c13b0 ... >

new_resource.name
=> "hol-dev-32"
```

### Deleting a deployment from vRA

When you no longer need the VM, you can destroy the deployment which will delete all the associated resources as well.
The method will return a request object you can query for status:

```shell
destroy_req = deployment.destroy
=> #<Vra::Request:0x00000006ea90d8 ... >

destroy_req.status
=> "SUCCESSFUL"
```

You can also list all resources and requests you have permission to see with these methods:

```shell
deployment.resources
deployment.requests
```

### Pagination

vRA paginates API requests where lists of items are returned.  By default, this gem will ask vRA to provide items in groups of 20.  However, as reported in [Issue 10](https://github.com/chef-partners/vmware-vra-gem/issues/10), it appears vRA may have a pagination bug.  You can change the default page size from 20 to a value of your choice by passing in a `page_size` option when setting up the client:

```ruby
vra = Vra::Client.new(username: 'devmgr@corp.local', password: 'mypassword', tenant: 'mytenant', base_url: 'https://vra.corp.local', verify_ssl: true, page_size: 100)
```

... or setting `page_size` on the client object after you've created it:

```ruby
client.page_size = 100
```

### Debugging

To aid diagnosis of deep API issues, set the following environment variable to enable logging of all API requests. Note that this will include requests to retrieve the bearer token.

MacOS/Linux:

```ruby
export VRA_HTTP_TRACE=1
```

Windows:

```powershell
$env:VRA_HTTP_TRACE=1
```

## License and Authors

Author:: Chef Partner Engineering (<partnereng@chef.io>)

Copyright:: Copyright (c) 2022 Chef Software, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the License at

```text
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.

## Contributing

1. Fork it ( <https://github.com/[my-github-username]/vmware-vra-gem/fork> )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
