From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH iproute2-next 0/3] ip: support LISP (RFC 9300) tunnel
 devices
Date: Fri, 27 Nov 2026 23:37:38 +0100
Message-Id: <20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADIGCmsC/z2M0QpAMBhGX0X/tZX9NPEqciG+8ZdmbUjJu1suX
 J4659wUEQSR2uymgFOibC6BzjMal8HNUDIlJi7YaM21Eh+2YwerVaJXpmyGpgLXFiWlxgdYub5
 fR7/qcO3UP88LyedEtm4AAAA=
To: David Ahern <dsahern@kernel.org>, 
 Stephen Hemminger <stephen@networkplumber.org>
Cc: netdev@vger.kernel.org, Matthieu Baerts <matttbe@kernel.org>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795819063; l=1702;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=7nd6BlqaJsHgxYsTrMLtC0L57s6XiuJ62VdGDLEwrvw=;
 b=WHzsU4HmU2rdBO7RCecfGGKZX0kQYFjNY4iJ3rNAc4i+PU5BSlwio9yzH1DVUGMWfniADGx7i
 vwCJH+vpSXpCSIQO3IM64IjtPeMijPHRytppnHeKs9A8D9XJl0wjTvX
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the lisp link type to ip, for the LISP (RFC 9300)
tunnel devices of the kernel series
  "lisp: add a LISP (RFC 9300) tunnel device"
posted for net-next:

  https://lore.kernel.org/r/20261126-for-upstream-lisp-v1-v1-0-7382a4bcfd9b@free.fr

The purpose of this serie is to support the selftest of the kernel:

  https://lore.kernel.org/all/8707e3b0-c948-44ea-8afc-d33387925173@kernel.org/

A LISP device carries the packets of an instance ID, or of the
instance IDs that have no device when it collects metadata. The routing
locators of a destination come from the encapsulation of its route or
of its nexthop, which ip already sets: the series only adds the device.

  ip link add link wan name lisp101 type lisp id 101 local 192.0.2.1
  ip -6 nexthop add id 1 encap ip dst 198.51.100.1 dev lisp101
  ip route add 10.2.0.0/24 vrf site nhid 1

Patches:
- patch 1 uAPI header
- patch 2 link type, with its manual page
- patch 3 test

---
Vincent Jardin (3):
      uapi: add the attributes of the lisp devices
      ip: add the lisp link type
      testsuite: add test for lisp

 include/uapi/linux/if_link.h            |  12 +++
 ip/Makefile                             |   2 +-
 ip/iplink.c                             |   2 +-
 ip/iplink_lisp.c                        | 137 ++++++++++++++++++++++++++++++++
 man/man8/ip-link.8.in                   |  66 +++++++++++++++
 testsuite/tests/ip/link/add_type_lisp.t |  59 ++++++++++++++
 6 files changed, 276 insertions(+), 2 deletions(-)
---
base-commit: 8055701cb470fdc9e5e9909369bff3f7e24c872e
change-id: 20261127-iproute2-lisp-639a94e27fe3

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

