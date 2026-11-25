From: Kalash Nainwal <kalash@nexthop.ai>
Subject: [PATCH net-next v2 0/2] tcp: add net.ipv4.tcp_l3mdev_exempt_ports
 sysctl
Date: Wed, 25 Nov 2026 14:17:45 -0700
Message-Id: <20261125-tcp-l3mdev-exempt-ports-v2-0-b920f3ff8f5e@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHlQB2sC/4WOQQ6CMBREr2L+2m/aEkhw5T0Mi/L7kRppm7Y2G
 MLdBTyAy8nMm5kFEkfLCa6nBSIXm6x3m1DnE9Co3YPRmk2DEqqRUgnMFPBVTYYL8sxTyBh8zAm
 pHWozcM9V3cBGh8iDnY/mOzjO6HjO0P2c9O6fTHkv3rOjTdnHz3GiyIP4u1ckCiQipSvdkBHtb
 R8YfbhoC926rl+pVAgu2wAAAA==
X-Change-ID: 20261120-tcp-l3mdev-exempt-ports-c9f5dfebe356
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, Neal Cardwell <ncardwell@google.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>
Cc: Shuah Khan <shuah@kernel.org>, Joel Granados <joel.granados@kernel.org>, 
 netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Kalash Nainwal <kalash@nexthop.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4398; i=kalash@nexthop.ai;
 h=from:subject:message-id; bh=gL/eOMgLt2xrx8fI3Mk4bs+cV56GAlBQ2KWpr+GQrDw=;
 b=owEB7QES/pANAwAKAdTKslu1X9B2AcsmYgBrB1B5M7xrqSbAKxNuP3sEOE16/RtTSoroHMNR/
 dacFmbMmzaJAbMEAAEKAB0WIQSWKdfHnHcAucb08LDUyrJbtV/QdgUCawdQeQAKCRDUyrJbtV/Q
 dhpTC/9MGgLNn849nJhgPys67rtFmcKAntVW9pYhI5Cbws2z2r8JbXw7CL6VSBWDUgSFkYBdgKv
 8XT4Rzule/r1wEpFYOLTEaaWKsU7Kjup6ixO01BvoseO3Fsfyt5kObIu6+xTVbp2cnLOOdRASFs
 7Vq60grwUc5MVKxVt6s21hHW72ySCZ7rLhMG2+YQqDB4dzS21vPZrHyNN6Z/oH0ipAUJszkCvmK
 uL1V87t/jiQUkrFHMIJSBqaX+ibuAQ9qiSEgMiInSNH9RPBBlhqUIH9V/mLMQDnlEXe6eVFXgMi
 CtgoQHKMMROHcdo+qccg2HciMfSqis9due22AczJ04AQYSan3xa67/jJf6y/Rdkn6f6kZCbQdHw
 /zup3MtEL+HUjDjmlAfCxtjuXoKE6GAcBI6n9ED//+NJJ70NwwQb/rReQbv/vaJ8ksHx6EbnPE0
 MWtnSodiwtxc5RGZ0qvkvgfrb1liARaOLEWFt15glHY6Y91pqJ94t1Ci8zZAmXbjOMV90=
X-Developer-Key: i=kalash@nexthop.ai; a=openpgp;
 fpr=9629D7C79C7700B9C6F4F0B0D4CAB25BB55FD076
X-Endpoint-Received: by B4 Relay for kalash@nexthop.ai/default with auth_id=1588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With net.ipv4.tcp_l3mdev_accept=1, an unbound TCP listener also accepts
connections that arrive in a VRF. When a VRF-bound listener exists on
the same port and both use SO_REUSEPORT, the lookup does not prefer the
VRF-bound one: inet_lhash2_lookup() returns the reuseport pick of the
first socket that beats the current best score, and the two sockets
are in different reuseport groups. The winner depends on bucket order,
and AF_INET6 reuseport listeners are added at the tail while AF_INET
ones are added at the head, so IPv4 and IPv6 behave differently.

We hit this with a BGP daemon that has a TCP-MD5 key on its VRF-bound
:179 listener and none on its unbound :179 listener. IPv6 VRF peers
reached the unbound listener and came up without MD5. Setting
tcp_l3mdev_accept=0 is not an option because other services on the
host need it.

Patch 1 adds a per-netns port list, net.ipv4.tcp_l3mdev_exempt_ports,
modeled on ip_local_reserved_ports. For a listed port, an unbound socket
does not match VRF traffic. The check runs only for VRF traffic
(sdif != 0) on unbound sockets, so other lookups are unchanged.

Patch 2 adds a selftest.

Testing:
- New selftest on net-next in virtme-ng: all 10 cases pass. Without the
  port listed, the first listener in the bucket wins (IPv4 fails when
  the VRF-bound listener is created first, IPv6 when the unbound one
  is).
- The same change on 6.12, with a BGP daemon over a VRF with TCP-MD5 on
  hardware: the IPv6 VRF session now uses the VRF-bound MD5 listener.

Why a sysctl rather than changing the default lookup: with both
listeners present, existing setups get a result that is stable but
depends on creation order and address family. Making the VRF-bound
listener always win would change that for every tcp_l3mdev_accept
user, so this series keeps the default and makes the new behavior
opt-in per port. If changing the default is preferred, I can rework it
that way.

Alternatives considered: a BPF sk_lookup program can do this, but needs
a loader attached in every netns that runs the daemon.

---
Changes in v2:
- Patch 1: only build the sysctl with CONFIG_NET_L3_MASTER_DEV, next to
  tcp_l3mdev_accept.
- Patch 1: say in the docs that only listener lookup changes, and that
  a listener bound to the receiving device also matches.
- Patch 1: add the field to net_cachelines/netns_ipv4_sysctl.rst.
- Patch 2: wait for the listeners with ss instead of a fixed sleep.
- Patch 2: skip if VRF is not supported; fail if setup fails.
- Patch 2: require a timeout from the listener that must not get the
  connection.
- Patch 2: use ALL_TESTS and check_gen_prog; fix shellcheck warnings.
- Wrap lines at 80 columns.
- Link to v1: https://patch.msgid.link/20261120-tcp-l3mdev-exempt-ports-v1-0-ccc2a3a6cd09@nexthop.ai

To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Simon Horman <horms@kernel.org>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
To: Randy Dunlap <rdunlap@infradead.org>
To: David Ahern <dsahern@kernel.org>
To: Ido Schimmel <idosch@nvidia.com>
To: Neal Cardwell <ncardwell@google.com>
To: Kuniyuki Iwashima <kuniyu@google.com>
To: Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-kselftest@vger.kernel.org

---
Kalash Nainwal (2):
      tcp: add net.ipv4.tcp_l3mdev_exempt_ports sysctl
      selftests: net: add tcp_l3mdev_exempt_ports test

 Documentation/networking/ip-sysctl.rst             |  24 ++
 .../net_cachelines/netns_ipv4_sysctl.rst           |   1 +
 include/net/ip.h                                   |  15 ++
 include/net/netns/ipv4.h                           |   3 +
 net/ipv4/inet_hashtables.c                         |   5 +
 net/ipv4/sysctl_net_ipv4.c                         |  21 ++
 net/ipv6/inet6_hashtables.c                        |   4 +
 tools/testing/selftests/net/Makefile               |   1 +
 .../selftests/net/tcp_l3mdev_exempt_ports.sh       | 260 +++++++++++++++++++++
 9 files changed, 334 insertions(+)
---
base-commit: 2208ab00f4f213ade91ab775e7f8c4dacdcc856e
change-id: 20261120-tcp-l3mdev-exempt-ports-c9f5dfebe356

Best regards,
--  
Kalash Nainwal <kalash@nexthop.ai>

