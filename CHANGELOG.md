# Change Log

## [3.1.3](https://github.com/test-kitchen/vmware-vra-gem/tree/v3.1.3) (2022-05-26)

- Use regular admin catalog endpoint to fetch catalog items
- Fixed the issue with multi-tenancy
- Fix chefstyle issues and optimise workflow

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v3.1.2...v3.1.3)


## [3.1.2] (2022-03-28)

- Upgrade Rake dependency (@damacus)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v3.1.1...v3.1.1)

## [3.1.1] (2022-03-01)

- Send Authorization: Bearer header instead of csp-auth-token for greater compatibility [@oshvarts]

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v3.1.0...v3.1.1)

## [3.1.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v3.1.0) (2022-01-30)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v3.0.1...v3.1.0)

- Make the version param optional in deployment request api

## [3.0.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v3.0.1) (2022-01-25)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v3.0.0...v3.0.1)

- Fix access token workflow to work with VRA8

## [3.0.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v3.0.0) (2022-01-18)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.7.2...v3.0.0)

- Rewritten to support vRA 8. If you require support for 7 make sure to pin on the previous 2.7.2 release.

## [2.7.2](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.7.2) (2020-09-09)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.7.1...v2.7.2)

- Added an extra option to handle shirt size parameter
- Masking user credentials(password) in debug mode

## [2.7.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.7.1) (2019-05-28)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.7.0...v2.7.1)

**Closed issues:**

- Some Extra Parameters are not passing through to VRA [\#75](https://github.com/test-kitchen/vmware-vra-gem/issues/75)

**Merged pull requests:**

- Add support for boolean vRA parameters, fix deep merge, add tracing [\#76](https://github.com/test-kitchen/vmware-vra-gem/pull/76) ([stuartpreston](https://github.com/stuartpreston))

## [2.7.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.7.0) (2019-05-10)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.6.1...v2.7.0)

**Closed issues:**

- Extra Parameters Not Being Sent to vRA [\#73](https://github.com/test-kitchen/vmware-vra-gem/issues/73)

**Merged pull requests:**

- vRA7 multiple fixes for nested, non-nested and merged parameters for a Blueprint [\#74](https://github.com/test-kitchen/vmware-vra-gem/pull/74) ([stuartpreston](https://github.com/stuartpreston))

## [2.6.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.6.1) (2018-07-31)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.6.0...2.6.1)

**Closed issues:**

- Vra::Resource\#ip\_addresses non-deterministically returns an empty array in error [\#65](https://github.com/test-kitchen/vmware-vra-gem/issues/65)

**Merged pull requests:**

- Removed the deep merge [\#68](https://github.com/test-kitchen/vmware-vra-gem/pull/68) ([jjasghar](https://github.com/jjasghar))

## [v2.6.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.6.0) (2018-03-01)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.5.2...v2.6.0)

**Closed issues:**

- undefined method `\[\]' for nil:NilClass if data for json content is of single entity [\#55](https://github.com/test-kitchen/vmware-vra-gem/issues/55)

**Merged pull requests:**

- Accept subtenant name as input in kitchen.yml [\#67](https://github.com/test-kitchen/vmware-vra-gem/pull/67) ([vinuphilip](https://github.com/vinuphilip))
- Lgustafson/fix 65 [\#66](https://github.com/test-kitchen/vmware-vra-gem/pull/66) ([lgustafson](https://github.com/lgustafson))

## [v2.5.2](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.5.2) (2018-01-22)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.5.1...v2.5.2)

**Merged pull requests:**

- Added a method to retrieve catalog id's from catalog name [\#64](https://github.com/test-kitchen/vmware-vra-gem/pull/64) ([rupeshpatel88](https://github.com/rupeshpatel88))

## [v2.5.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.5.1) (2017-10-19)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.5.0...v2.5.1)

**Merged pull requests:**

- Fixes a bug with Resource.by\_name [\#63](https://github.com/test-kitchen/vmware-vra-gem/pull/63) ([logicminds](https://github.com/logicminds))

## [v2.5.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.5.0) (2017-10-17)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.4.0...v2.5.0)

**Closed issues:**

- Use mkdir\_p when creating template directory [\#60](https://github.com/test-kitchen/vmware-vra-gem/issues/60)

**Merged pull requests:**

- Adds ability to lookup resource by name [\#62](https://github.com/test-kitchen/vmware-vra-gem/pull/62) ([logicminds](https://github.com/logicminds))

## [v2.4.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.4.0) (2017-09-19)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.3.0...v2.4.0)

**Closed issues:**

- cpu and memory parameters request [\#52](https://github.com/test-kitchen/vmware-vra-gem/issues/52)
- Minor typo in README [\#51](https://github.com/test-kitchen/vmware-vra-gem/issues/51)

**Merged pull requests:**

- Adds ability to supply template files to catalog request [\#57](https://github.com/test-kitchen/vmware-vra-gem/pull/57) ([logicminds](https://github.com/logicminds))
- Adds the ability to dump catalog templates via class methods [\#56](https://github.com/test-kitchen/vmware-vra-gem/pull/56) ([logicminds](https://github.com/logicminds))
- Symbols [\#53](https://github.com/test-kitchen/vmware-vra-gem/pull/53) ([logicminds](https://github.com/logicminds))

## [v2.3.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.3.0) (2017-06-30)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.2.0...v2.3.0)

**Closed issues:**

- catalog\_request SSLError [\#30](https://github.com/test-kitchen/vmware-vra-gem/issues/30)
- Incompatible with vagrant 1.8+ \(at least\) [\#26](https://github.com/test-kitchen/vmware-vra-gem/issues/26)

**Merged pull requests:**

- Extra parameters [\#50](https://github.com/test-kitchen/vmware-vra-gem/pull/50) ([lloydsmithjr03](https://github.com/lloydsmithjr03))
- Initial Jenkinsfile for integration tests [\#49](https://github.com/test-kitchen/vmware-vra-gem/pull/49) ([jjasghar](https://github.com/jjasghar))

## [v2.2.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.2.0) (2017-06-08)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.1.3...v2.2.0)

**Closed issues:**

- usage of openssl raises error [\#45](https://github.com/test-kitchen/vmware-vra-gem/issues/45)
- why is chefstyle a runtime dependency? [\#44](https://github.com/test-kitchen/vmware-vra-gem/issues/44)
- Error when using set\_parameter and support for extra\_parameters [\#38](https://github.com/test-kitchen/vmware-vra-gem/issues/38)

**Merged pull requests:**

- Fixes issue with chefstyle and unnecessary runtime dependency [\#48](https://github.com/test-kitchen/vmware-vra-gem/pull/48) ([logicminds](https://github.com/logicminds))
- adds ability to specify additional params to catalog request [\#47](https://github.com/test-kitchen/vmware-vra-gem/pull/47) ([logicminds](https://github.com/logicminds))
- Fixes \#45 - usage of openssl raises error [\#46](https://github.com/test-kitchen/vmware-vra-gem/pull/46) ([logicminds](https://github.com/logicminds))

## [v2.1.3](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.1.3) (2017-03-28)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.1.2...v2.1.3)

**Merged pull requests:**

- Fixing missing messages from some HTTP exceptions [\#43](https://github.com/test-kitchen/vmware-vra-gem/pull/43) ([nsdavidson](https://github.com/nsdavidson))

## [v2.1.2](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.1.2) (2017-03-28)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.1.1...v2.1.2)

**Merged pull requests:**

- Updates extra\_params to check for top level props [\#42](https://github.com/test-kitchen/vmware-vra-gem/pull/42) ([nsdavidson](https://github.com/nsdavidson))

## [v2.1.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.1.1) (2017-03-14)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.1.0...v2.1.1)

**Merged pull requests:**

- Converted to chefstyle [\#41](https://github.com/test-kitchen/vmware-vra-gem/pull/41) ([jjasghar](https://github.com/jjasghar))

## [v2.1.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.1.0) (2017-03-14)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Added skips [\#40](https://github.com/test-kitchen/vmware-vra-gem/pull/40) ([jjasghar](https://github.com/jjasghar))
- Support extra params for vra7 [\#39](https://github.com/test-kitchen/vmware-vra-gem/pull/39) ([nsdavidson](https://github.com/nsdavidson))

## [v2.0.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.0.0) (2016-12-15)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.0.0.pre2...v2.0.0)

## [v2.0.0.pre2](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.0.0.pre2) (2016-12-08)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v2.0.0.pre1...v2.0.0.pre2)

**Closed issues:**

- \_\_Notes property does not work with vRA 7 [\#33](https://github.com/test-kitchen/vmware-vra-gem/issues/33)

## [v2.0.0.pre1](https://github.com/test-kitchen/vmware-vra-gem/tree/v2.0.0.pre1) (2016-12-03)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.7.0...v2.0.0.pre1)

**Merged pull requests:**

- 2.0.0.pre1 release [\#37](https://github.com/test-kitchen/vmware-vra-gem/pull/37) ([jjasghar](https://github.com/jjasghar))
- vRA 7.1 Support [\#36](https://github.com/test-kitchen/vmware-vra-gem/pull/36) ([jjasghar](https://github.com/jjasghar))
- Updated travis rubies [\#35](https://github.com/test-kitchen/vmware-vra-gem/pull/35) ([jjasghar](https://github.com/jjasghar))
- vra 7.0.1 compatibility [\#34](https://github.com/test-kitchen/vmware-vra-gem/pull/34) ([stevehedrick](https://github.com/stevehedrick))

## [v1.7.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.7.0) (2016-08-02)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.6.1...v1.7.0)

**Merged pull requests:**

- v1.7.0 [\#32](https://github.com/test-kitchen/vmware-vra-gem/pull/32) ([jjasghar](https://github.com/jjasghar))
- instructing Net::HTTP not to verify SSL when verify\_ssl is false [\#31](https://github.com/test-kitchen/vmware-vra-gem/pull/31) ([bvandgrift](https://github.com/bvandgrift))

## [v1.6.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.6.1) (2016-05-10)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.6.0...v1.6.1)

## [v1.6.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.6.0) (2016-05-10)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.5.4...v1.6.0)

**Merged pull requests:**

- Remove rest-client dependency [\#28](https://github.com/test-kitchen/vmware-vra-gem/pull/28) ([regularfry](https://github.com/regularfry))

## [v1.5.4](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.5.4) (2016-04-27)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.5.3...v1.5.4)

**Closed issues:**

- when org data is nil, knife vra barfs [\#27](https://github.com/test-kitchen/vmware-vra-gem/issues/27)

**Merged pull requests:**

- Fixing potential NilClass errors [\#29](https://github.com/test-kitchen/vmware-vra-gem/pull/29) ([adamleff](https://github.com/adamleff))

## [v1.5.3](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.5.3) (2016-04-18)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.5.2...v1.5.3)

**Closed issues:**

- fork of this gem [\#24](https://github.com/test-kitchen/vmware-vra-gem/issues/24)
- `Vra::Exception::HTTPError` initialized incorrectly [\#23](https://github.com/test-kitchen/vmware-vra-gem/issues/23)

**Merged pull requests:**

- updating \#http\_head to use same http exception handling [\#25](https://github.com/test-kitchen/vmware-vra-gem/pull/25) ([adamleff](https://github.com/adamleff))

## [v1.5.2](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.5.2) (2016-04-01)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.5.1...v1.5.2)

**Closed issues:**

- require 'json' missing from client.rb [\#21](https://github.com/test-kitchen/vmware-vra-gem/issues/21)
- request feeder file [\#20](https://github.com/test-kitchen/vmware-vra-gem/issues/20)

**Merged pull requests:**

- use FFI\_Yajl::Encoder instead of \#to\_json [\#22](https://github.com/test-kitchen/vmware-vra-gem/pull/22) ([adamleff](https://github.com/adamleff))

## [v1.5.1](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.5.1) (2016-03-11)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.5.0...v1.5.1)

**Closed issues:**

- Machine status is MachineActivated causing errors \(VRA7\) [\#18](https://github.com/test-kitchen/vmware-vra-gem/issues/18)

**Merged pull requests:**

- Support for MachineActivated state [\#19](https://github.com/test-kitchen/vmware-vra-gem/pull/19) ([stevehedrick](https://github.com/stevehedrick))
- fixing travis notifications [\#17](https://github.com/test-kitchen/vmware-vra-gem/pull/17) ([adamleff](https://github.com/adamleff))
- fixing new rubocop 0.36 complaints and testing travis [\#16](https://github.com/test-kitchen/vmware-vra-gem/pull/16) ([adamleff](https://github.com/adamleff))

## [v1.5.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.5.0) (2015-11-18)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.4.0...v1.5.0)

**Merged pull requests:**

- Add support for Infrastructure.Cloud resources [\#15](https://github.com/test-kitchen/vmware-vra-gem/pull/15) ([adamleff](https://github.com/adamleff))

## [v1.4.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.4.0) (2015-11-13)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.3.0...v1.4.0)

**Closed issues:**

- attr\_accessor :bearer\_token has to be changed due to PR \#9 change [\#12](https://github.com/test-kitchen/vmware-vra-gem/issues/12)

**Merged pull requests:**

- Add accessors for bearer\_token [\#14](https://github.com/test-kitchen/vmware-vra-gem/pull/14) ([adamleff](https://github.com/adamleff))

## [v1.3.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.3.0) (2015-11-12)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.2.0...v1.3.0)

**Merged pull requests:**

- Additional changes to support chef-provisoning-vra [\#13](https://github.com/test-kitchen/vmware-vra-gem/pull/13) ([adamleff](https://github.com/adamleff))

## [v1.2.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.2.0) (2015-09-24)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.1.0...v1.2.0)

**Closed issues:**

- bug in pagination at path "/catalog-service/api/consumer/resources?limit=20" duplicate machines returned [\#10](https://github.com/test-kitchen/vmware-vra-gem/issues/10)

**Merged pull requests:**

- Allow setting of pagination page size, raise exception on duplicates [\#11](https://github.com/test-kitchen/vmware-vra-gem/pull/11) ([adamleff](https://github.com/adamleff))

## [v1.1.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.1.0) (2015-09-17)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.0.0...v1.1.0)

**Merged pull requests:**

- Adding masking of passwords in console output [\#9](https://github.com/test-kitchen/vmware-vra-gem/pull/9) ([adamleff](https://github.com/adamleff))
- Removing specific error class from \#validate\_client\_options test [\#8](https://github.com/test-kitchen/vmware-vra-gem/pull/8) ([adamleff](https://github.com/adamleff))
- README update - spaces update only [\#6](https://github.com/test-kitchen/vmware-vra-gem/pull/6) ([adamleff](https://github.com/adamleff))

## [v1.0.0](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.0.0) (2015-08-07)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.0.0.rc2...v1.0.0)

**Merged pull requests:**

- Release v1.0.0 [\#5](https://github.com/test-kitchen/vmware-vra-gem/pull/5) ([adamleff](https://github.com/adamleff))

## [v1.0.0.rc2](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.0.0.rc2) (2015-07-30)

[Full Changelog](https://github.com/test-kitchen/vmware-vra-gem/compare/v1.0.0.rc1...v1.0.0.rc2)

**Merged pull requests:**

- Add resource ownership information [\#4](https://github.com/test-kitchen/vmware-vra-gem/pull/4) ([adamleff](https://github.com/adamleff))

## [v1.0.0.rc1](https://github.com/test-kitchen/vmware-vra-gem/tree/v1.0.0.rc1) (2015-07-29)

**Closed issues:**

- general 500 server errors should generate better error messages [\#3](https://github.com/test-kitchen/vmware-vra-gem/issues/3)
- sanity-check the VRA base URL [\#2](https://github.com/test-kitchen/vmware-vra-gem/issues/2)

**Merged pull requests:**

- initial release [\#1](https://github.com/test-kitchen/vmware-vra-gem/pull/1) ([adamleff](https://github.com/adamleff))
