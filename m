From: Mark Amirkan <markdamirkan@gmail.com>
Subject: [PATCH net 0/2] ipv6: rpl: fix loop detection for separated local
 addresses
Date: Fri, 11 Sep 2026 16:11:20 -0700
Message-Id: <20260911-sympwn-rpl-send-v1-0-1753993bb584@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJiKpGoC/yWMSw6CQBAFr0Le2k4YJCBexbiAocU22k6m8UMId
 2eUZVVSNcM4ChuO2YzIbzF5agK3y+CvrQ5M0idGkRdV3jhHNj3CRymGOxlrT77eN13pD1XZ1kh
 ViHyR7/94gvKI8ybt1d3Yj78XlmUFNXz31XgAAAA=
X-Change-ID: 20260911-sympwn-rpl-send-c739b4c864a7
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Alexander Aring <alex.aring@gmail.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Mark Amirkan <markdamirkan@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789168285; l=1120;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=poZE6G7l8mXHXez7alx4IXviwmEYDJVB5doeIShWyj0=;
 b=eKXJgapi1xe1t9oJHeaMBIbo9BqmO/qfByRm+EboQECBMG3uU7xeBWbzJImoEd8KTpH3uYfym
 BpfddUkJZVUB4QeE8Gu+XOKslrgXJe+lbGkggCoISinnCf6ou6KBcRx
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ipv6_chk_rpl_srh_loop() misses the shortest RPL loop pattern containing
two local addresses with a non-local address between them. The check is
made before the current local address is counted, so found is 1 rather
than greater than 1 when the second local address is reached.

Patch 1 fixes the condition. Patch 2 adds a selftest which verifies that
adjacent local addresses are accepted and separated local addresses are
rejected.

The selftest fails on the unmodified net tree and passes with the fix.

Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
Mark Amirkan (2):
      ipv6: rpl: fix loop detection for separated local addresses
      selftests: net: add RPL SRH loop test

 net/ipv6/addrconf.c                         |  2 +-
 tools/testing/selftests/net/Makefile        |  1 +
 tools/testing/selftests/net/rpl_srh_loop.sh | 38 +++++++++++++++++++++++++++++
 3 files changed, 40 insertions(+), 1 deletion(-)
---
base-commit: 78445023439506ebd83b86d40b1e428a3b309d4a
change-id: 20260911-sympwn-rpl-send-c739b4c864a7

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

