# VMware vRA Gem
[![Gem Version](https://badge.fury.io/rb/vmware-vra.svg)](http://badge.fury.io/rb/vmware-vra)
[![Build Status](https://travis-ci.org/chef-partners/vmware-vra-gem.svg?branch=master)](https://travis-ci.org/chef-partners/vmware-vra-gem)

Client gem for interacting with VMware's vRealize Automation application.

Not all vRA functionality is included in this gem; only API calls necessary
to interact with the catalog, requests, and existing items is included.

The primary goal of this gem is to provide a reusable set of methods in order
to create Chef plugins for knife, test-kitchen, and provisioning.

## Versions

`1.7.0` version can and will support vRA 6 and below.

`2.0.0` version and forward will support vRA 7+.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vmware-vra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vmware-vra

## Usage

First, load in the gem.

```
require 'vra'
=> true
```

Then, set up your client object. You will need to know your tenant ID from your vRA administrator.

```
vra = Vra::Client.new(username: 'devmgr@corp.local', password: 'mypassword', tenant: 'mytenant', base_url: 'https://vra.corp.local', verify_ssl: true)
=> #<Vra::Client:0x000000034c0df8 ... >
```

To list all items in the catalog:

```
vra.catalog.all_items
=> [{"@type"=>"CatalogItem", "id"=>"a9cd6148-6e0b-4a80-ac47-f5255c52b43d", "version"=>2, "name"=>"CentOS 6.6", "description"=>"Blueprint for deploying a CentOS Linux development server", ... }]
```

To only list the items in the catalog for which you are entitled to request:

```
vra.catalog.entitled_items
=> [{"@type"=>"ConsumerEntitledCatalogItem", "catalogItem"=>{"id"=>"d29efd6b-3cd6-4f8d-b1d8-da4ddd4e52b1", "version"=>2, "name"=>"WindowsServer2012", "description"=>"Windows Server 2012", ... }]
```

When you are ready to request an item from the catalog, create a new catalog request object:

```
catalog_request = vra.catalog.request('a9cd6148-6e0b-4a80-ac47-f5255c52b43d', cpus: 1, memory: 512, requested_for: 'devmgr@corp.local', lease_days: 30)
=> #<Vra::CatalogRequest:0x00000003477c20 ... >
```

vRA requires your sub-tenant (a.k.a. "business group") to be specified when requesting an item from the catalog. If the catalog item you are requesting is specifically created for a given business group, the gem will use that ID automatically without you needing to specify it.

However, if there is no sub-tenant ID available for us to use, you will receive an error when you submit:

```
request = catalog_request.submit
ArgumentError: Unable to submit request, required param(s) missing => subtenant_id
	from /home/aleff/vmware-vra/lib/vra/catalog_request.rb:42:in `validate_params!'
	from /home/aleff/vmware-vra/lib/vra/catalog_request.rb:99:in `submit'
	from (irb):4
	from /opt/chefdk/embedded/bin/irb:11:in `<main>'

```

In this case, you will need to supply the sub-tenant ID manually:

```
catalog_request.subtenant_id = '5327ddd3-1a4e-4663-9e9d-63db86ffc8af'
=> "5327ddd3-1a4e-4663-9e9d-63db86ffc8af"
```

If your catalog blueprint item requires additional parameters to successfully submit your request, you may add them:

```
catalog_request.set_parameter('my_parameter', 'string', 'my value')
```

If you need to set a parameter on a child object in the blueprint, you can add them by using a ~:

```
catalog_request.set_parameter('object~my_parameter', 'string', 'my value')
```

### Creating a request from a yaml or json payload
Should you want to create a request ahead of time you can create the parameters up front by
reading from a file or a hard coded payload you use every time.  This is not required by any means but allows
for some extra flexibility when using this request object directly.  The only difference is that you can pass
in the request parameters instead of having to set them after you create the object.

Given a sample request object like the following you will want to read the yaml into an ruby object:

```yaml
requestData:
  entries:
    key: provider-provisioningGroupId
    value:
      type: string
      value: 93992-3929392-32323828-832882394
    key: provider-datacenter
      type: string
      value: datacenter1
    key: provider-domain
      type: string
      value: chef.com

```

And now use that data to create the Vra::RequestParameters to feed into the catalog request.

```ruby
# read in the request data
yaml_data = YAML,load(data)
# create a parameters array, although this only works with VRA6, since VRA7 can have complex data
parameters = yaml_data['requestData']['entries'].map {|item| [item['key'], item['value'].values].flatten }
# We put the values in a array so we can easily explode the parameters using the splat operator later
request_params = Vra::RequestParameters.new
# loop through each parameter and setting each parameter
parameters.each {|p| request_params.set(*p)  # splat
request_options = {
  cpus: 1,
  memory: 1024,
  requested_for: 'me@me.com',
  lease_days: 2,
  additional_params: request_params
}
# create the request
catalog_request = vra.catalog.request(blueprint, request_options)
```

Now, submit your request!  The client will return a new "Request" object you can use to query for status.

```
request = catalog_request.submit
=> #<Vra::Request:0x000000027caea0 ... >

request.status
=> "IN_PROGRESS"
```

You can easily refresh your request object to get the latest status:

```
request.refresh && request.status
=> "SUCCESSFUL"

request.completion_state
=> "SUCCESSFUL"

request.completion_details
=> "Request succeeded. Created hol-dev-32."
```

You can also save the request ID for later, and create a new request object at your leisure to follow-up on your request:

```
request.id
=> "aed22465-02db-481d-b55a-cefe216096a2"

new_request = vra.requests.by_id('aed22465-02db-481d-b55a-cefe216096a2')
=> #<Vra::Request:0x0000000564ac30 ... >

new_request.status
=> "SUCCESSFUL"
```

When the request is successful, you can query the resources created as the result of your request. Assuming that the catalog item blueprint we requested only creates a single VM, we can get that resource and learn more information about it:

```
resource = request.resources.first
=> #<Vra::Resource:0x00000006772e68 ... >

resource.network_interfaces
=> [{"NETWORK_ADDRESS"=>"192.168.110.203", "NETWORK_MAC_ADDRESS"=>"00:50:56:ae:1d:c7", "NETWORK_NAME"=>"vxw-dvs-35-virtualwire-2-sid-5000-Edge_Transport"}]

resource.ip_addresses
=> ["192.168.110.203"]

resource.name
=> "hol-dev-32"
```

And just like requests, you can save the resource ID and query it again later:

```
resource.id
=> "331fd10b-f2a2-40ae-86bc-1255c1ee9a6d"

new_resource = vra.resources.by_id('331fd10b-f2a2-40ae-86bc-1255c1ee9a6d')
=> #<Vra::Resource:0x000000067c13b0 ... >

new_resource.name
=> "hol-dev-32"
```

When you no longer need the VM, you can destroy it, which returns another request object you can query for status:

```
destroy_req = resource.destroy
=> #<Vra::Request:0x00000006ea90d8 ... >

destroy_req.status
=> "SUCCESSFUL"
```

You can also list all resources and requests you have permission to see with these methods:

```
vra.resources.all_resources
vra.requests.all_requests
```

### Download VRA catalog templates
It can be quite useful to download the catalog templates from your VRA server for future playback or inspection.  This
can now be easily done with some helpful class methods.

To get a json string representation of the catalog template you can use `Vra::CatalogItem.dump_template(client, catalog_id)`

To dump the catalog template to a file instead of a string `Vra::CatalogItem.write_template(client, catalog_id)`.  This will create a file like `windows2012.json`.

If you just want to dump all the templates you can use `Vra::CatalogItem.dump_templates(client)`.  This will create a directory named vra_templates
with all the entitled templates for the current user.  

There are additional options you can provide to these methods in order to customize output file names and directories, so please see the source code in lib/vra/catalog_item.rb

### Pagination

vRA paginates API requests where lists of items are returned.  By default, this gem will ask vRA to provide items in groups of 20.  However, as reported in [Issue 10](https://github.com/chef-partners/vmware-vra-gem/issues/10), it appears vRA may have a pagination bug.  You can change the default page size from 20 to a value of your choice by passing in a `page_size` option when setting up the client:

```ruby
vra = Vra::Client.new(username: 'devmgr@corp.local', password: 'mypassword', tenant: 'mytenant', base_url: 'https://vra.corp.local', verify_ssl: true, page_size: 100)
```

... or setting `page_size` on the client object after you've created it:

```ruby
client.page_size = 100
```

## License and Authors

Author:: Chef Partner Engineering (<partnereng@chef.io>)

Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/vmware-vra-gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
