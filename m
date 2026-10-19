From: Demos Ra <demosthenes.ra@gmail.com>
Date: Mon, 19 Oct 2026 13:35:51 +0700
Subject: [PATCH net-next] netlink: specs: Add a spec for nexthops in
 rtnetlink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-rt-nexthop-spec-v1-1-9c586edf86ab@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywqAIBAAf0X23IIPCuxXokPYWnsxUQkh/Pekj
 gMz80CmxJRhFg8kujnzFTqoQYA7t3AQ8t4ZtNSTkspiKhiolvOKmCM5lN5Js2lnrRmhVzGR5/o
 dFwj027C29gKo4Nx/awAAAA==
X-Change-ID: 20261019-rt-nexthop-spec-0fc03a2c9935
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Donald Hunter <donald.hunter@gmail.com>, 
 David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>
Cc: Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 Demos Ra <demosthenes.ra@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792391812; l=19503;
 i=demosthenes.ra@gmail.com; s=20261019; h=from:subject:message-id;
 bh=AgOHI97g4P+nb3cL7huyP7l7Zh+C9X8g6L/mUOvUcVw=;
 b=otjehsogbyBd5Ub3TTOYDJGBbjWSEUkpqYe6/1HoiarMkFQJBfAiugnb3ISa7weaHfxjrmmFZ
 ZA4K43wGbAdBJTJdZm1LQx0XhgYuU0D/t+iF8hcJTdlh8j3kx3CwGHP
X-Developer-Key: i=demosthenes.ra@gmail.com; a=ed25519;
 pk=sDKS9AI9zxhWgOqkhc9EOIo6cky+anqccB3VGtDvzCc=
X-Endpoint-Received: by B4 Relay for demosthenes.ra@gmail.com/20261019 with auth_id=1235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a YNL spec for nexthop objects and nexthop buckets in rtnetlink.

./tools/net/ynl/pyynl/cli.py \
    --spec Documentation/netlink/specs/rt-nexthop.yaml \
    --dump getnexthop

Exclude newnexthopbucket-ntf from the C code generation. ynl_gen_c.py
looks up a classic notification by the request of the same message
type, and no request uses RTM_NEWNEXTHOPBUCKET. The spec keeps the
notification, so the Python tools can still subscribe to it.

Signed-off-by: Demos Ra <demosthenes.ra@gmail.com>
---
Tested with tools/net/ynl/pyynl/cli.py on a 7.0 kernel: each
operation's replies match ip nexthop, and the create and delete
notifications are received. rt-nexthop-user.o builds with no warnings.

newnexthopbucket-ntf is left out of the C generation with
--exclude-op, as ethtool does for stats-get. If you would rather
have ynl_gen_c.py handle a notification with no matching request,
I can do that instead.
---
 Documentation/netlink/specs/rt-nexthop.yaml | 761 ++++++++++++++++++++++++++++
 MAINTAINERS                                 |   1 +
 tools/net/ynl/Makefile.deps                 |   9 +
 tools/net/ynl/generated/Makefile            |   1 +
 4 files changed, 772 insertions(+)

diff --git a/Documentation/netlink/specs/rt-nexthop.yaml b/Documentation/netlink/specs/rt-nexthop.yaml
new file mode 100644
index 000000000..06c28fa7d
--- /dev/null
+++ b/Documentation/netlink/specs/rt-nexthop.yaml
@@ -0,0 +1,761 @@
+# SPDX-License-Identifier: ((GPL-2.0 WITH Linux-syscall-note) OR BSD-3-Clause)
+---
+name: rt-nexthop
+protocol: netlink-raw
+uapi-header: linux/nexthop.h
+protonum: 0
+
+doc: >-
+  Nexthop object management over rtnetlink.
+
+definitions:
+  -
+    name: nhmsg
+    type: struct
+    members:
+      -
+        name: nh-family
+        type: u8
+      -
+        name: nh-scope
+        type: u8
+      -
+        name: nh-protocol
+        type: u8
+      -
+        name: resvd
+        type: pad
+        len: 1
+      -
+        name: nh-flags
+        type: u32
+        enum: rtnh-f
+  -
+    name: rtnh-f
+    type: flags
+    name-prefix: rtnh-f-
+    enum-name:
+    entries:
+      - dead
+      - pervasive
+      - onlink
+      - offload
+      - linkdown
+      - unresolved
+      - trap
+  -
+    name: nexthop-grp
+    type: struct
+    members:
+      -
+        name: id
+        type: u32
+      -
+        name: weight
+        type: u8
+      -
+        name: weight-high
+        type: u8
+      -
+        name: resvd2
+        type: pad
+        len: 2
+  -
+    name: nexthop-grp-type
+    type: enum
+    name-prefix: nexthop-grp-type-
+    enum-name:
+    entries:
+      - mpath
+      - res
+  -
+    name: encap-type
+    type: enum
+    name-prefix: lwtunnel-encap-
+    enum-name:
+    entries:
+      - none
+      - mpls
+      - ip
+      - ila
+      - ip6
+      - seg6
+      - bpf
+      - seg6-local
+      - rpl
+      - ioam6
+      - xfrm
+  -
+    name: seg6-local-actions
+    type: enum
+    name-prefix: seg6-local-action-
+    enum-name:
+    entries:
+      - unspec
+      - end
+      - end-x
+      - end-t
+      - end-dx2
+      - end-dx6
+      - end-dx4
+      - end-dt6
+      - end-dt4
+      - end-b6
+      - end-b6-encap
+      - end-bm
+      - end-s
+      - end-as
+      - end-am
+      - end-bpf
+      - end-dt46
+  -
+    name: seg6-local-flv-ops
+    type: enum
+    name-prefix: seg6-local-flv-op-
+    enum-name:
+    entries:
+      -
+        name: unspec
+      -
+        name: psp
+      -
+        name: usp
+      -
+        name: usd
+      -
+        name: next-csid
+  -
+    name: nha-op-flag
+    type: flags
+    name-prefix: nha-op-flag-
+    enum-name:
+    entries:
+      - dump-stats
+      - dump-hw-stats
+  -
+    name: nha-op-flag-resp-grp-resvd-0
+    type: const
+    value: 2147483648
+
+sub-messages:
+  -
+    name: encap-data
+    formats:
+      -
+        value: mpls
+        attribute-set: mpls-iptunnel
+      -
+        value: ip
+        attribute-set: lwtunnel-ip
+      -
+        value: ila
+        attribute-set: ila-attrs
+      -
+        value: ip6
+        attribute-set: lwtunnel-ip6
+      -
+        value: seg6
+        attribute-set: seg6-iptunnel
+      -
+        value: bpf
+        attribute-set: lwt-bpf
+      -
+        value: seg6-local
+        attribute-set: seg6-local
+      -
+        value: rpl
+        attribute-set: rpl-iptunnel
+      -
+        value: ioam6
+        attribute-set: ioam6-iptunnel
+      -
+        value: xfrm
+        attribute-set: lwt-xfrm
+
+attribute-sets:
+  -
+    name: nexthop-attrs
+    name-prefix: nha-
+    attributes:
+      -
+        name: id
+        type: u32
+      -
+        name: group
+        type: binary  # array of struct: nexthop-grp
+      -
+        name: group-type
+        type: u16
+        enum: nexthop-grp-type
+      -
+        name: blackhole
+        type: flag
+      -
+        name: oif
+        type: u32
+      -
+        name: gateway
+        type: binary
+        display-hint: ipv4-or-v6
+      -
+        name: encap-type
+        type: u16
+        enum: encap-type
+      -
+        name: encap
+        type: sub-message
+        sub-message: encap-data
+        selector: encap-type
+      -
+        name: groups
+        type: flag
+      -
+        name: master
+        type: u32
+      -
+        name: fdb
+        type: flag
+      -
+        name: res-group
+        type: nest
+        nested-attributes: res-group-attrs
+      -
+        name: res-bucket
+        type: nest
+        nested-attributes: res-bucket-attrs
+      -
+        name: op-flags
+        type: u32
+        checks:
+          flags-mask: nha-op-flag
+      -
+        name: group-stats
+        type: nest
+        nested-attributes: group-stats-attrs
+      -
+        name: hw-stats-enable
+        type: u32
+        checks:
+          max: 1
+      -
+        name: hw-stats-used
+        type: u32
+      -
+        name: dst-port
+        type: u16
+        byte-order: big-endian
+        checks:
+          min: 1
+  -
+    name: mpls-iptunnel
+    name-prefix: mpls-iptunnel-
+    header: linux/mpls_iptunnel.h
+    attributes:
+      -
+        name: dst
+        type: binary
+      -
+        name: ttl
+        type: u8
+  -
+    name: lwtunnel-ip
+    name-prefix: lwtunnel-ip-
+    header: linux/lwtunnel.h
+    attributes:
+      -
+        name: id
+        type: u64
+        byte-order: big-endian
+      -
+        name: dst
+        type: u32
+        byte-order: big-endian
+        display-hint: ipv4
+      -
+        name: src
+        type: u32
+        byte-order: big-endian
+        display-hint: ipv4
+      -
+        name: ttl
+        type: u8
+      -
+        name: tos
+        type: u8
+      -
+        name: flags
+        type: u16
+        byte-order: big-endian
+      -
+        name: pad
+        type: pad
+      -
+        name: opts
+        type: nest
+        nested-attributes: lwtunnel-ip-opts
+  -
+    name: ila-attrs
+    name-prefix: ila-attr-
+    header: linux/ila.h
+    attributes:
+      -
+        name: locator
+        type: u64
+        byte-order: big-endian
+      -
+        name: identifier
+        type: u64
+      -
+        name: locator-match
+        type: u64
+        byte-order: big-endian
+      -
+        name: ifindex
+        type: s32
+      -
+        name: dir
+        type: u32
+      -
+        name: pad
+        type: pad
+      -
+        name: csum-mode
+        type: u8
+      -
+        name: ident-type
+        type: u8
+      -
+        name: hook-type
+        type: u8
+  -
+    name: lwtunnel-ip6
+    name-prefix: lwtunnel-ip6-
+    header: linux/lwtunnel.h
+    attributes:
+      -
+        name: id
+        type: u64
+        byte-order: big-endian
+      -
+        name: dst
+        type: binary
+        display-hint: ipv6
+      -
+        name: src
+        type: binary
+        display-hint: ipv6
+      -
+        name: hoplimit
+        type: u8
+      -
+        name: tc
+        type: u8
+      -
+        name: flags
+        type: u16
+        byte-order: big-endian
+      -
+        name: pad
+        type: pad
+      -
+        name: opts
+        type: nest
+        nested-attributes: lwtunnel-ip-opts
+  -
+    name: seg6-iptunnel
+    name-prefix: seg6-iptunnel-
+    header: linux/seg6_iptunnel.h
+    attributes:
+      -
+        name: srh
+        type: binary
+      -
+        name: src
+        type: binary
+        display-hint: ipv6
+      -
+        name: table
+        type: u32
+  -
+    name: lwt-bpf
+    name-prefix: lwt-bpf-
+    header: linux/lwtunnel.h
+    attributes:
+      -
+        name: in
+        type: nest
+        nested-attributes: lwt-bpf-prog
+      -
+        name: out
+        type: nest
+        nested-attributes: lwt-bpf-prog
+      -
+        name: xmit
+        type: nest
+        nested-attributes: lwt-bpf-prog
+      -
+        name: xmit-headroom
+        type: u32
+  -
+    name: seg6-local
+    name-prefix: seg6-local-
+    header: linux/seg6_local.h
+    attributes:
+      -
+        name: action
+        type: u32
+        enum: seg6-local-actions
+      -
+        name: srh
+        type: binary
+      -
+        name: table
+        type: u32
+      -
+        name: nh4
+        type: u32
+        byte-order: big-endian
+        display-hint: ipv4
+      -
+        name: nh6
+        type: binary
+        display-hint: ipv6
+      -
+        name: iif
+        type: u32
+      -
+        name: oif
+        type: u32
+      -
+        name: bpf
+        type: nest
+        nested-attributes: seg6-local-bpf
+      -
+        name: vrftable
+        type: u32
+      -
+        name: counters
+        type: nest
+        nested-attributes: seg6-local-cnt
+      -
+        name: flavors
+        type: nest
+        nested-attributes: seg6-local-flv
+  -
+    name: rpl-iptunnel
+    name-prefix: rpl-iptunnel-
+    header: linux/rpl_iptunnel.h
+    attributes:
+      -
+        name: srh
+        type: binary
+  -
+    name: ioam6-iptunnel
+    name-prefix: ioam6-iptunnel-
+    header: linux/ioam6_iptunnel.h
+    attributes:
+      -
+        name: mode
+        type: u8
+      -
+        name: dst
+        type: binary
+        display-hint: ipv6
+      -
+        name: trace
+        type: binary
+      -
+        name: freq-k
+        type: u32
+      -
+        name: freq-n
+        type: u32
+      -
+        name: src
+        type: binary
+        display-hint: ipv6
+  -
+    name: lwt-xfrm
+    name-prefix: lwt-xfrm-
+    header: linux/lwtunnel.h
+    attributes:
+      -
+        name: if-id
+        type: u32
+      -
+        name: link
+        type: u32
+  -
+    name: lwtunnel-ip-opts
+    name-prefix: lwtunnel-ip-opts-
+    attributes:
+      -
+        name: geneve
+        type: binary
+      -
+        name: vxlan
+        type: nest
+        nested-attributes: lwtunnel-ip-opt-vxlan
+      -
+        name: erspan
+        type: nest
+        nested-attributes: lwtunnel-ip-opt-erspan
+  -
+    name: lwtunnel-ip-opt-vxlan
+    name-prefix: lwtunnel-ip-opt-vxlan-
+    attributes:
+      -
+        name: gbp
+        type: u32
+  -
+    name: lwtunnel-ip-opt-erspan
+    name-prefix: lwtunnel-ip-opt-erspan-
+    attributes:
+      -
+        name: ver
+        type: u8
+      -
+        name: index
+        type: u32
+        byte-order: big-endian
+      -
+        name: dir
+        type: u8
+      -
+        name: hwid
+        type: u8
+  -
+    name: lwt-bpf-prog
+    name-prefix: lwt-bpf-prog-
+    attributes:
+      -
+        name: fd
+        type: u32
+      -
+        name: name
+        type: string
+        checks:
+          max-len: 256
+  -
+    name: seg6-local-bpf
+    name-prefix: seg6-local-bpf-
+    attr-max-name: seg6-local-bpf-prog-max
+    attributes:
+      -
+        name: prog
+        type: u32
+      -
+        name: prog-name
+        type: string
+        checks:
+          max-len: 256
+  -
+    name: seg6-local-cnt
+    name-prefix: seg6-local-cnt-
+    attributes:
+      -
+        name: pad
+        type: pad
+      -
+        name: packets
+        type: u64
+      -
+        name: bytes
+        type: u64
+      -
+        name: errors
+        type: u64
+  -
+    name: seg6-local-flv
+    name-prefix: seg6-local-flv-
+    attributes:
+      -
+        name: operation
+        type: u32
+        enum: seg6-local-flv-ops
+        enum-as-flags: true
+      -
+        name: lcblock-bits
+        type: u8
+      -
+        name: lcnode-fn-bits
+        type: u8
+  -
+    name: res-group-attrs
+    name-prefix: nha-res-group-
+    attributes:
+      -
+        name: pad
+        type: pad
+        value: 0
+      -
+        name: buckets
+        type: u16
+      -
+        name: idle-timer
+        type: u32
+      -
+        name: unbalanced-timer
+        type: u32
+      -
+        name: unbalanced-time
+        type: u64
+  -
+    name: res-bucket-attrs
+    name-prefix: nha-res-bucket-
+    attributes:
+      -
+        name: pad
+        type: pad
+        value: 0
+      -
+        name: index
+        type: u16
+      -
+        name: idle-time
+        type: u64
+      -
+        name: nh-id
+        type: u32
+  -
+    name: group-stats-attrs
+    name-prefix: nha-group-stats-
+    attributes:
+      -
+        name: entry
+        type: nest
+        nested-attributes: group-stats-entry-attrs
+        multi-attr: true
+  -
+    name: group-stats-entry-attrs
+    name-prefix: nha-group-stats-entry-
+    attributes:
+      -
+        name: id
+        type: u32
+      -
+        name: packets
+        type: uint
+      -
+        name: packets-hw
+        type: uint
+
+operations:
+  enum-model: directional
+  fixed-header: nhmsg
+  name-prefix: rtm-
+  list:
+    -
+      name: newnexthop
+      doc: Add new nexthop entry
+      attribute-set: nexthop-attrs
+      do:
+        request:
+          value: 104
+          attributes:
+            - id
+            - group
+            - group-type
+            - blackhole
+            - oif
+            - gateway
+            - encap-type
+            - encap
+            - fdb
+            - res-group
+            - hw-stats-enable
+            - dst-port
+    -
+      name: delnexthop
+      doc: Delete nexthop with given id.
+      attribute-set: nexthop-attrs
+      do:
+        request:
+          value: 105
+          attributes:
+            - id
+    -
+      name: getnexthop
+      doc: Get or dump nexthop entries
+      attribute-set: nexthop-attrs
+      do:
+        request:
+          value: 106
+          attributes:
+            - id
+            - op-flags
+        reply:
+          value: 104
+          attributes: &nexthop-all-attrs
+            - id
+            - group
+            - group-type
+            - blackhole
+            - oif
+            - gateway
+            - encap-type
+            - encap
+            - fdb
+            - res-group
+            - op-flags
+            - group-stats
+            - hw-stats-enable
+            - hw-stats-used
+            - dst-port
+      dump:
+        request:
+          value: 106
+          attributes:
+            - oif
+            - groups
+            - master
+            - fdb
+            - op-flags
+        reply:
+          value: 104
+          attributes: *nexthop-all-attrs
+    -
+      name: newnexthop-ntf
+      doc: Notification about a created nexthop.
+      value: 104
+      notify: getnexthop
+    -
+      name: delnexthop-ntf
+      doc: Notification about a deleted nexthop.
+      value: 105
+      notify: getnexthop
+    -
+      name: getnexthopbucket
+      doc: Get or dump nexthop buckets
+      attribute-set: nexthop-attrs
+      do:
+        request:
+          value: 118
+          attributes: &nexthop-bucket-all-attrs
+            - id
+            - res-bucket
+        reply:
+          value: 116
+          attributes: *nexthop-bucket-all-attrs
+      dump:
+        request:
+          value: 118
+          attributes:
+            - id
+            - oif
+            - master
+            - res-bucket
+        reply:
+          value: 116
+          attributes: *nexthop-bucket-all-attrs
+    -
+      name: newnexthopbucket-ntf
+      doc: Notification about a created nexthop bucket.
+      value: 116
+      notify: getnexthopbucket
+
+mcast-groups:
+  list:
+    -
+      name: rtnlgrp-nexthop
+      value: 32
diff --git a/MAINTAINERS b/MAINTAINERS
index 23e919448..6a5062f02 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19144,6 +19144,7 @@ L:	netdev@vger.kernel.org
 S:	Maintained
 F:	Documentation/netlink/specs/rt-addr.yaml
 F:	Documentation/netlink/specs/rt-neigh.yaml
+F:	Documentation/netlink/specs/rt-nexthop.yaml
 F:	Documentation/netlink/specs/rt-route.yaml
 F:	Documentation/netlink/specs/rt-rule.yaml
 F:	include/linux/inetdevice.h
diff --git a/tools/net/ynl/Makefile.deps b/tools/net/ynl/Makefile.deps
index 3eee34e0e..9389f3752 100644
--- a/tools/net/ynl/Makefile.deps
+++ b/tools/net/ynl/Makefile.deps
@@ -45,6 +45,15 @@ CFLAGS_rt-link:=$(call get_hdr_inc,__LINUX_RTNETLINK_H,rtnetlink.h) \
 	$(call get_hdr_inc,_LINUX_IF_LINK_H,if_link.h)
 CFLAGS_rt-neigh:=$(call get_hdr_inc,__LINUX_RTNETLINK_H,rtnetlink.h) \
 	$(call get_hdr_inc,__LINUX_NEIGHBOUR_H,neighbour.h)
+CFLAGS_rt-nexthop:=$(call get_hdr_inc,__LINUX_RTNETLINK_H,rtnetlink.h) \
+	$(call get_hdr_inc,_LINUX_NEXTHOP_H,nexthop.h) \
+	$(call get_hdr_inc,_LINUX_ILA_H,ila.h) \
+	$(call get_hdr_inc,_LINUX_IOAM6_IPTUNNEL_H,ioam6_iptunnel.h) \
+	$(call get_hdr_inc,_LINUX_MPLS_IPTUNNEL_H,mpls_iptunnel.h) \
+	$(call get_hdr_inc,_LINUX_RPL_IPTUNNEL_H,rpl_iptunnel.h) \
+	$(call get_hdr_inc,_LINUX_SEG6_IPTUNNEL_H,seg6_iptunnel.h) \
+	$(call get_hdr_inc,_LINUX_SEG6_LOCAL_H,seg6_local.h) \
+	$(call get_hdr_inc,_LWTUNNEL_H_,lwtunnel.h)
 CFLAGS_rt-route:=$(call get_hdr_inc,_LINUX_ILA_H,ila.h) \
 	$(call get_hdr_inc,_LINUX_IOAM6_IPTUNNEL_H,ioam6_iptunnel.h) \
 	$(call get_hdr_inc,_LINUX_MPLS_IPTUNNEL_H,mpls_iptunnel.h) \
diff --git a/tools/net/ynl/generated/Makefile b/tools/net/ynl/generated/Makefile
index 5a186349b..d76d4ca94 100644
--- a/tools/net/ynl/generated/Makefile
+++ b/tools/net/ynl/generated/Makefile
@@ -18,6 +18,7 @@ include ../Makefile.deps
 
 YNL_GEN_ARG_ethtool:=--user-header linux/ethtool_netlink.h \
 	--exclude-op stats-get
+YNL_GEN_ARG_rt-nexthop:=--exclude-op newnexthopbucket-ntf
 
 TOOL:=../pyynl/ynl_gen_c.py
 TOOL_RST:=../pyynl/ynl_gen_rst.py

---
base-commit: 98c2ad4f5d805dbc1ea436a334ee59311806a48c
change-id: 20261019-rt-nexthop-spec-0fc03a2c9935

Best regards,
-- 
Demos Ra <demosthenes.ra@gmail.com>

