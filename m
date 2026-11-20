From: Kalash Nainwal <kalash@nexthop.ai>
Subject: [PATCH net-next 0/2] tcp: add net.ipv4.tcp_l3mdev_exempt_ports
 sysctl
Date: Fri, 20 Nov 2026 15:47:04 -0700
Message-Id: <20261120-tcp-l3mdev-exempt-ports-v1-0-ccc2a3a6cd09@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOnNAGsC/yWMQQqDMBQFryJ/3Q8motBepXRRkxebUmNIvhIQ7
 960LodhZqeM5JHp1uyUsPnsl1BBXRoyr2eYwN5WJt3qQSndspjIn2622BgFcxSOS5LM5up66zC
 i6weqdUxwvvzPdwoQDihCj9PkdXzDyG9Mx/EFqCK7g4UAAAA=
X-Change-ID: 20261120-tcp-l3mdev-exempt-ports-c9f5dfebe356
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, Neal Cardwell <ncardwell@google.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Kalash Nainwal <kalash@nexthop.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2534; i=kalash@nexthop.ai;
 h=from:subject:message-id; bh=5+wJ1wgapkViv2nkjqCc0s6p6SRRlJLd1BhMgD5qp6M=;
 b=owEB7QES/pANAwAKAdTKslu1X9B2AcsmYgBrAM3pSLifdKN9WQiB9uTQC326a2VgvdGJGuG0Z
 ZcS1mQdXgCJAbMEAAEKAB0WIQSWKdfHnHcAucb08LDUyrJbtV/QdgUCawDN6QAKCRDUyrJbtV/Q
 dpiQC/45wVLA7WusfOWS+DB5ZPRdHU4CjiyC2sqtaRTkjfypUyKuBek3eeEGhV0mYpsFR4ubI00
 zFWDbkpjtkmpVplJwk1ppAE+gXen8Q+FKiybedp5ZHWyQLR2mxdbJ6kLUXwbpposaaMmcR0VugI
 mPEbW96k3yMzIYude7imhCg5JwGdBy02gcmr6pI1Pwtouzjue22PLwICmfZmik2eZHMBTKVaDNT
 CibfZcVA9Aw4kavc5jsv4PecwzhIGXxC0m/Lqc+MzYSBFSMESuyrH969rI6eDa+uQud0g+pT2Di
 RNovoVTwMokPw3BGaERqzDJdNi6p2fx8aFKsYMFV0qHZw/k0RAHOjK0Ogp2dmfDNziZKEM8zCtT
 YU/HRthwKC26zR2iUlXdTxi+4WSqMtygy4qtCxpfAbkwGDKI0kgFLG9Ap5YcOfEVmV9CjZhzcd/
 c6q11CKgB45X1HSm2PgesjFfpL+oKWsgt3Dbe7t88fI33bOqkr/DgfZOK9shhptPng2Us=
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

Alternatives considered: a BPF sk_lookup program can do this, but needs
a loader attached in every netns that runs the daemon.

---
Kalash Nainwal (2):
      tcp: add net.ipv4.tcp_l3mdev_exempt_ports sysctl
      selftests: net: add tcp_l3mdev_exempt_ports test

 Documentation/networking/ip-sysctl.rst             |  19 ++
 include/net/ip.h                                   |  14 ++
 include/net/netns/ipv4.h                           |   1 +
 net/ipv4/inet_hashtables.c                         |   5 +
 net/ipv4/sysctl_net_ipv4.c                         |  14 ++
 net/ipv6/inet6_hashtables.c                        |   4 +
 tools/testing/selftests/net/Makefile               |   1 +
 .../selftests/net/tcp_l3mdev_exempt_ports.sh       | 213 +++++++++++++++++++++
 8 files changed, 271 insertions(+)
---
base-commit: 2208ab00f4f213ade91ab775e7f8c4dacdcc856e
change-id: 20261120-tcp-l3mdev-exempt-ports-c9f5dfebe356

Best regards,
--  
Kalash Nainwal <kalash@nexthop.ai>

