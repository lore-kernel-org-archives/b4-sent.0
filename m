From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH net 0/2] ipv6: fix IPv6 scope check of the source address
 in a VRF
Date: Mon, 23 Nov 2026 15:30:42 +0100
Message-Id: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-0-f667ab150ade@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJOBGsC/x3NQQrDIBBA0auEWXdAjZHSq5QuJI7pLKoyk0og5
 O6VLt/m/xOUhEnhMZ0g1Fm5lgF7m2B9x7IRchoGZ1yw1s2Yq+C36S4UP8itB+ySUWNKgrrWRtg
 tejI2LHfjk59hpJpQ5uO/eUKhHV7X9QMm8anyewAAAA==
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Willem de Bruijn <willemb@google.com>, Simon Horman <horms@kernel.org>, 
 Nicolas Dichtel <nicolas.dichtel@6wind.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795444251; l=1748;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=ckLhEkeU0s46EikTMohSy6D9LFFcDelhweYemdwaM7Y=;
 b=IhHwGmrL9GR8k8EXPg+veCjCJDcf7ZclMfh2fGb8EyR+/CoktYqy9ADqvvsbN8KfCOm6PLkAN
 4n1HjoSTl+sDWMy8Iib0gnkTy2Y0B+bTxJuKLHwFsIc0+1fHZHvv/PK
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a packet is sent through a device of a VRF, ipv6_dev_get_saddr()
first checks the addresses of that device and of the VRF device,
and stops when the best of them has a scope that fits the destination.

Since the commit abb9a68d2c64 ("ipv6: take care of scope when
choosing the src addr"), the check reads the scopedist of the best
candidate, which is an issue:

- with a single candidate, scopedist is not written: when the stack is
  zero-initialized, a device that only has a link-local address sends
  to global destinations with it, although another device of the VRF
  has a global address

- with more candidates, scopedist is negative, whether the scope fits
  or not: all the devices of the VRF are looked at, and one of their
  addresses can win over the address of the VRF device

Changes:
- patch 1 compares the scope of the best candidate with the scope
  of the destination

- patch 2 adds test cases to fib_tests.sh

Note: abb9a68d2c64 is in every kernel since v6.11 and was backported down
to 4.19, so the bug is in all the maintained trees (5.10, 5.15, 6.1, 6.6,
6.12, 6.18 and 7.3), hence this series for net.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (2):
      ipv6: check the scope of the best source address candidate in a VRF
      selftests: fib_tests: test IPv6 source address of a VRF

 net/ipv6/addrconf.c                      |  6 ++--
 tools/testing/selftests/net/fib_tests.sh | 47 +++++++++++++++++++++++++++++++-
 2 files changed, 50 insertions(+), 3 deletions(-)
---
base-commit: af6737b9066832a2017c281159950ba92385ce00
change-id: 20261123-for-upstream-ipv6-vrf-saddr-scope-v1-4e0165804d43

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

