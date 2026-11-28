From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH net-next v2 0/5] lisp: add a LISP (RFC 9300) tunnel device
Date: Sat, 28 Nov 2026 01:41:32 +0100
Message-Id: <20261128-for-upstream-lisp-v1-v2-0-68e8649c3ed2@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADwjCmsC/32NwQqDMBBEf0X23C0mlag9+R/FQzSbutBG2aRiE
 f+9wQ8ozGWYmTc7RBKmCPdiB6GVI88hG30pYJxseBKyyx50qY1S2qCfBT9LTEL2jS+OC64Kh6q
 2o2kbl1uQp4uQ5+3EPiBQwkBbgj4nE8c0y/f8W9WZ/0dnlVjfGm2rYfSuHTovRFcv0B/H8QPCz
 TqwwAAAAA==
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Vincent Jardin <vjardin@free.fr>, Donald Hunter <donald.hunter@gmail.com>, 
 Nicolas Dichtel <nicolas.dichtel@6wind.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 =?utf-8?q?Asbj=C3=B8rn_Sloth_T=C3=B8nnesen?= <ast@fiberby.net>, 
 Danielle Ratson <danieller@nvidia.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795826502; l=4327;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=3QIbv24rPwGBZWn9xkNpTTUXhCedhThkPImwKnrDxv8=;
 b=+M8pAoNkv4l30kgyWMv8hMT7VICYTTzvk8BqRtpPTRxtXemyU8UlqJ+AJYXn7ADWiQ+N1X6vr
 MfzW61hEDXmCMRQXr1wwNaWmCOqLwLTWYWRB7pZas7DFDfkYM/PnLU5
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LISP (Locator/ID Separation Protocol, RFC 9300) carries the packets sent
to an endpoint identifier (EID) over UDP, to a routing locator (RLOC) of
the site of that EID. An EID prefix and its RLOCs are a mapping, which
the LISP control plane (RFC 9301) provides.

This series adds the data plane of a LISP router (xTR): a tunnel device,
link kind "lisp", for IPv4 and IPv6 EIDs over IPv4 and IPv6 RLOCs.

A mapping is a route. The device takes the RLOC of a packet from its
tunnel metadata, which the lwtunnel encapsulation of the route
or of its nexthop provides. A remote site is a nexthop, shared by its
EID prefixes:

  ip link add link wan name lisp101 type lisp id 101 local 192.0.2.1
  ip link set lisp101 master site up
  ip -6 nexthop add id 1 encap ip dst 198.51.100.1 dev lisp101
  ip route add 10.2.0.0/24 vrf site nhid 1
  ip -6 route add 2001:db8:2::/48 vrf site nhid 1

Design:

- The kernel has no map-cache and it does not resolve anything: no
  upcall, no state that the packets of a host create. Its tables are the
  routes and the nexthops, which a control plane in user space writes,
  as it does for any other routing protocol. A packet without RLOC ends
  up dropped.

- A remote site is a nexthop object, not a device: it has been designed
  to scale.

- The common UDP tunnel code is used: its sockets, GRO cells, GSO, the
  dst cache of the encapsulation, and a zero UDP checksum unless the
  encapsulation asks for one.

Note: a LISP driver was posted to netdev back to 2014 and was not
merged. It had a device per remote RLOC and IPv4 RLOCs only, and a
map-cache that traffic fills was not accepted.
lwtunnels is an alternative.

This design shall allow routing daemons like FRRouting to support LISP.

Patches:
- patch 1 adds the driver, drivers/net/lisp.c, and its link attributes
- patch 2 describes them in the rt-link netlink spec
- patch 3 adds Documentation/networking/lisp.rst
- patch 4 adds a selftest, lisp.sh
- patch 5 adds a scale selftest, lisp_scale.sh

The series only adds: no existing code path is changed.

The lisp support of iproute2 is a separate series, for
iproute2-next. The tests are skipped without it:

  https://lore.kernel.org/all/20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr/

---
Changes in v2, based on CI's checks:
- 1/5: fix to 80 columns
- 4/5, 5/5: fix shellcheck report
- 4/5, 5/5: wrap the lines to 80 columns
- Cc recent contributors of rt-link.yaml

Changes in v2, based on Sashiko's review:
- 1/5: link an instance device again only after an RCU grace period
  since it left its chain (lisp_stop(), lisp_open())
- 1/5: fix build without CONFIG_IPV6
- 3/5: device with an instance ID that is down leaves its packets to
  the device that collects metadata
- 3/5: rp_filter is the larger of the value of "all" and of the device,
  ip6tables rpfilter or the nftables fib expression for IPv6
- 4/5: flush the path MTU of the host on each pass of mtu_test()
- 5/5: churn_test() improvements
- Link to v1: https://lore.kernel.org/r/20261126-for-upstream-lisp-v1-v1-0-7382a4bcfd9b@free.fr

---
Vincent Jardin (5):
      lisp: add LISP (Locator/ID Separation Protocol)
      netlink: specs: rt-link: add the lisp link type
      docs: net: document the LISP devices
      selftests: net: add a test of the LISP devices
      selftests: net: add a scale test for LISP

 Documentation/netlink/specs/rt-link.yaml  |   35 +
 Documentation/networking/index.rst        |    1 +
 Documentation/networking/lisp.rst         |  159 ++++
 MAINTAINERS                               |    8 +
 drivers/net/Kconfig                       |   20 +
 drivers/net/Makefile                      |    1 +
 drivers/net/lisp.c                        | 1040 ++++++++++++++++++++++++++
 include/uapi/linux/if_link.h              |   12 +
 tools/testing/selftests/net/Makefile      |    2 +
 tools/testing/selftests/net/config        |    4 +
 tools/testing/selftests/net/lisp.sh       | 1139 +++++++++++++++++++++++++++++
 tools/testing/selftests/net/lisp_scale.sh |  542 ++++++++++++++
 12 files changed, 2963 insertions(+)
---
base-commit: eb6d6c80d35449c27471b1874f13066c09a8964d
change-id: 20261126-for-upstream-lisp-v1-b47ac698d026

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

