kea
===

Install and configure the Kea DHCP server.

Requirements
------------

Since Kea is not packaged in either CentOS 8 or EPEL, this role
fetches it from the upstream repository at Cloudsmith. This repository
needs to be reachable from the system running Kea.

Generate the Kea configuration file using the palletjack2kea tool and
store it as files/kea-dhcp4.conf.

License
-------

MIT

Author Information
------------------

Karl-Johan Karlsson
Part of Pallet Jack: https://github.com/creideiki/palletjack
