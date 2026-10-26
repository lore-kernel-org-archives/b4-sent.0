From: Esko Mobius <echoowall@gmail.com>
Subject: [PATCH net 0/2] Revert advertising the TCP MSS from the configured
 MTU
Date: Mon, 26 Oct 2026 15:23:07 +0800
Message-Id: <20261026-advmss-revert-v1-0-272fa4b7ecb6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANv/3moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINZNTCnLLS7WBapNLSrRNbUwME1JNTQ3NrNMUwLqKShKTcusAJsXrZS
 XWqIUCxEsLk3KSk0uAZmkVFsLAFqhlOV2AAAA
X-Change-ID: 20261026-advmss-revert-5805de17369f
To: netdev@vger.kernel.org
Cc: Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, Shuah Khan <shuah@kernel.org>, 
 Thorsten Leemhuis <regressions@leemhuis.info>, regressions@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Esko Mobius <echoowall@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792999388; l=1884;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=XaR0Gk8SmZ1BSXypb/zmzgZFcyeFs/xIK7D652IwkuE=;
 b=1UtGo0a2fgm7Z14XWVa6/EaFpZ4ZKjTgedpVnVQW7PmVrgnzJb5IAT2ykAQfhMa27+gN/Y4Su
 9CVc7UOGdAYCpkkdt3jSZAgu/96ThC6LY37mBdYYOdPI1tHLgZrpP84
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 2640e6419594 ("net: advertise TCP MSS from the configured MTU,
not the learned PMTU") breaks TCP for clients behind networks that
filter inbound ICMP, when the server reaches them through a hop with a
smaller MTU: the handshake completes, then the connection stalls as
soon as the client sends full-size segments. This was reported in [1]
and confirmed on 7.3-rc7; reverting the commit on top of 7.3-rc7 fixes
it. Details and numbers are in patch 2.

The asymmetric (DSR-style) case that commit targets can still be served
by the existing per-route advmss metric, which overrides the default
after the revert; patch 2 includes a test of that as well. If you would
rather keep the new behaviour as an explicit opt-in some other way, I
am happy to test or rework this.

Patch 1 removes the packetdrill tests that assert the reverted
behaviour, patch 2 is the revert itself.

[1] https://lore.kernel.org/regressions/4F0FAEB6-A13B-47F3-BFF1-C706686C6F64@gmail.com/

Signed-off-by: Esko Mobius <echoowall@gmail.com>
---
Esko Mobius (2):
      Revert "selftests: net: packetdrill: add tests for advertised MSS with PMTU exceptions"
      Revert "net: advertise TCP MSS from the configured MTU, not the learned PMTU"

 include/net/ip.h                                   | 25 --------
 include/net/ip6_route.h                            | 37 ------------
 net/ipv4/route.c                                   |  4 +-
 net/ipv6/route.c                                   |  2 +-
 .../net/packetdrill/tcp_advmss_pmtu_ipv4.pkt       | 67 ----------------------
 .../net/packetdrill/tcp_advmss_pmtu_ipv6.pkt       | 67 ----------------------
 6 files changed, 3 insertions(+), 199 deletions(-)
---
base-commit: 7076f684d5132e6a6145e1da2fa74771ecd052e5
change-id: 20261026-advmss-revert-5805de17369f

Best regards,
--  
Esko Mobius <echoowall@gmail.com>

