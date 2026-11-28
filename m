From: Vincent Jardin <vjardin@free.fr>
Date: Sat, 28 Nov 2026 01:41:35 +0100
Subject: [PATCH net-next v2 3/5] docs: net: document the LISP devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-for-upstream-lisp-v1-v2-3-68e8649c3ed2@free.fr>
References: <20261128-for-upstream-lisp-v1-v2-0-68e8649c3ed2@free.fr>
In-Reply-To: <20261128-for-upstream-lisp-v1-v2-0-68e8649c3ed2@free.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795826502; l=9280;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=8e5RbI6cVe0qnP19u1JfP5nfVOjyBFC4ratoywdAAc4=;
 b=Ldijmsnm2+sdHaV5pRkcLDlT1z+vm3ygA0TO4GDEH85Ncl/ykLOwNJd27+BlJ8ykIEXd6g7sa
 dTgwmmiHoqdAvHvlaV6F1X9pEvS4RzIVptC3YjKbXMocAaYa1s28A22
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the LISP devices, how the routes and the nexthops
give the RLOCs and what checks the sources of the packets that a
device decapsulates.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/networking/index.rst |   1 +
 Documentation/networking/lisp.rst  | 159 +++++++++++++++++++++++++++++++++++++
 MAINTAINERS                        |   1 +
 drivers/net/Kconfig                |   3 +-
 4 files changed, 163 insertions(+), 1 deletion(-)

diff --git a/Documentation/networking/index.rst b/Documentation/networking/index.rst
index 44a422ad3b055..f2bc062f80d80 100644
--- a/Documentation/networking/index.rst
+++ b/Documentation/networking/index.rst
@@ -69,6 +69,7 @@ Contents:
    kcm
    l2tp
    lapb-module
+   lisp
    mac80211-injection
    mctp
    mpls-sysctl
diff --git a/Documentation/networking/lisp.rst b/Documentation/networking/lisp.rst
new file mode 100644
index 0000000000000..aae350cf04f77
--- /dev/null
+++ b/Documentation/networking/lisp.rst
@@ -0,0 +1,159 @@
+.. SPDX-License-Identifier: GPL-2.0
+.. Copyright (c) 2026 Vincent Jardin <vjardin@free.fr>, Free Mobile
+
+=============================================
+Locator/ID Separation Protocol (LISP) devices
+=============================================
+
+LISP separates the addresses of the hosts, the endpoint identifiers (EIDs),
+from the addresses of the routers that the hosts are reachable through, the
+routing locators (RLOCs). A LISP router, an xTR, carries the packets that are
+sent to a remote EID over UDP to an RLOC of the site of that EID (:rfc:`9300`).
+
+A LISP device is the data plane of an xTR. It encapsulates IPv4 and IPv6
+packets in a LISP header, UDP port 4341, and an IPv4 or IPv6 header, and it
+decapsulates what it receives. The family of the RLOCs is independent from the
+family of the EIDs.
+
+The kernel has no LISP control plane and no map-cache: the association of an
+EID prefix with its RLOCs, a mapping, is a route. Its nexthop gives the RLOC as
+a lightweight tunnel encapsulation, ``encap ip`` for an IPv4 RLOC and ``encap
+ip6`` for an IPv6 one, and has the LISP device as output device. The routes are
+configured, or installed by a LISP control plane in user space (:rfc:`9301`)
+as any routing daemon does. A packet whose destination has no route with an
+RLOC is not resolved by the kernel.
+
+Devices
+=======
+
+There are two kinds of LISP devices.
+
+A device (1) with an instance ID sends and receives the packets of that instance::
+
+  ip link add site type vrf table 10
+  ip link set site up
+  ip link add lisp101 type lisp id 101
+  ip link set lisp101 master site up
+
+It is meant to be in the VRF of the EIDs of the instance: what it receives is
+routed in that VRF, and the routes of that VRF send to it. A site has one
+device per instance, whatever the number of remote sites.
+
+A device (2) that collects metadata serves all the instance IDs that have no device
+of their own::
+
+  ip link add lisp0 type lisp external
+  ip link set lisp0 up
+
+The instance ID then comes with the RLOC, as the ``id`` of the encapsulation
+of the nexthop. The packets that the device receives have it in their tunnel
+metadata, where a routing rule (``ip rule add tun_id``), a traffic control
+filter or a BPF program finds it.
+
+A device with an instance ID takes the packets of its instance only while it
+is up: while it is down, they go to the device that collects metadata, if
+there is one.
+
+Both kinds take the RLOC from the tunnel metadata of the packet. A packet
+without metadata, sent by a route that has no encapsulation, is dropped and
+counted as a transmit error.
+
+``id IID``
+  The instance ID, from 0 to 16777215. The header of the packets of the
+  instance 0 has no instance ID, and a packet without instance ID is received
+  by the instance 0.
+
+``external``
+  The device collects metadata.
+
+``local ADDR``
+  The source address of the packets that are sent to an RLOC of the same
+  family, a local RLOC. It can be given once per family. A source address in
+  the encapsulation of the nexthop is used instead. Without either, the route
+  to the RLOC gives the source address.
+
+``link DEVICE``
+  A generic option of ``ip link add``, before ``type lisp``. The packets are
+  sent to the RLOCs through ``DEVICE``: by the routes of a VRF when it is a
+  VRF device, by its own routes otherwise. The LISP device receives what
+  comes from the VRF that ``DEVICE`` is, or is in. Without link, or with a
+  link that is in no VRF, the RLOCs are in the main table. The LISP device is
+  removed with ``DEVICE``::
+
+    ip link add link wan name lisp101 type lisp id 101 local 192.0.2.1
+
+The devices that have the same VRF of RLOCs share their UDP sockets, one per
+address family. The sockets are in the network namespace of ``DEVICE``: the
+one that the LISP device is created from, unless ``link-netns`` names another
+one, which the LISP device is then removed with. An instance ID is used once
+per VRF of RLOCs, and one device collects its metadata. The sockets of a VRF
+and those of the main table cannot coexist: the RLOCs of a network namespace
+are either in VRFs or in the main table.
+
+Mappings
+========
+
+The RLOC of an EID prefix is a nexthop, shared by the prefixes of the same
+site, or a group of nexthops for the RLOCs that share the traffic::
+
+  ip -6 nexthop add id 1 encap ip dst 192.0.2.1 dev lisp101
+  ip -6 nexthop add id 2 encap ip6 dst 2001:db8::1 dev lisp101
+  ip nexthop add id 3 group 1,3/2,1
+
+  ip route add 10.1.0.0/16 vrf site nhid 1
+  ip -6 route add 2001:db8:1::/48 vrf site nhid 3
+
+An IPv6 nexthop is used by IPv4 and IPv6 routes. With the device that
+collects metadata, the nexthop gives the instance ID too::
+
+  ip -6 nexthop add id 4 encap ip id 102 dst 192.0.2.1 dev lisp0
+
+A route can carry the encapsulation itself, without nexthop object. This does
+not scale with the number of RLOCs: the routes that only differ by their
+encapsulation are compared with each other when one is added.
+
+A group counts the packets that it forwards to each of its nexthops
+(``ip -s nexthop``).
+
+A nexthop is removed with its routes when the device goes down.
+
+Checking the IP sources
+=======================
+
+The device decapsulates what comes for its instance ID, from any RLOC: it
+does not check the source of a packet. What the kernel has for any device
+applies to it.
+
+The reverse path filter of IPv4 checks the source EID. With ``rp_filter`` set
+to 1 for the LISP device, a packet is dropped unless the route to its source
+sends to that device, that is, unless its source has a mapping in that
+instance. The packets that it drops are counted as ``IPReversePathFilter``.
+The kernel uses the larger of the value of the device and of ``all``: with
+``all`` at 2, as some distributions set it, the check is the loose one, which
+accepts a source that has any route::
+
+  sysctl -w net.ipv4.conf.all.rp_filter=0
+  sysctl -w net.ipv4.conf.lisp101.rp_filter=1
+
+IPv6 has no ``rp_filter``: the ``rpfilter`` match of ip6tables, or the ``fib``
+expression of nftables, makes the same check::
+
+  ip6tables -t raw -A PREROUTING -i lisp101 -m rpfilter --invert -j DROP
+
+These checks do not look at the RLOC that a packet comes from. With mappings
+that user space installs when packets need them, they drop what a site sends
+until the mapping of that site is there.
+
+The packets that a device that collects metadata receives have the RLOC that
+they come from and their instance ID in their tunnel metadata, which a traffic
+control filter matches with the source EID. These filters accept an EID
+prefix from the RLOC of its site and drop what else the device receives,
+which the last one counts::
+
+  tc qdisc add dev lisp0 clsact
+  tc filter add dev lisp0 ingress protocol ip pref 10 flower \
+      enc_key_id 102 enc_src_ip 192.0.2.1 src_ip 10.1.0.0/16 action pass
+  tc filter add dev lisp0 ingress pref 100 matchall action drop
+
+A device with an instance ID gives its packets no tunnel metadata: nothing
+checks the RLOC that they come from.
diff --git a/MAINTAINERS b/MAINTAINERS
index 6b62bc1f45bae..addedadf43446 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -15510,6 +15510,7 @@ LISP DATA PLANE DRIVER
 M:	Vincent Jardin <vjardin@free.fr>
 L:	netdev@vger.kernel.org
 S:	Maintained
+F:	Documentation/networking/lisp.rst
 F:	drivers/net/lisp.c
 
 LIST KUNIT TEST
diff --git a/drivers/net/Kconfig b/drivers/net/Kconfig
index aa78fd48e77a9..6201f5046422b 100644
--- a/drivers/net/Kconfig
+++ b/drivers/net/Kconfig
@@ -280,7 +280,8 @@ config LISP
 	  (LISP, RFC 9300): a tunnel device that carries the IPv4 and IPv6
 	  packets of an instance ID over UDP, to the routing locator (RLOC)
 	  that the route or the nexthop of their destination gives as a
-	  lightweight tunnel encapsulation.
+	  lightweight tunnel encapsulation. See
+	  Documentation/networking/lisp.rst.
 
 	  The mappings of the destinations to the RLOCs come from user space,
 	  from a LISP control plane or from the configuration.

-- 
2.43.0

