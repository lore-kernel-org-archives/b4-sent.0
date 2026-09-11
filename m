From: Mark Amirkan <markdamirkan@gmail.com>
Date: Fri, 11 Sep 2026 16:11:22 -0700
Subject: [PATCH net 2/2] selftests: net: add RPL SRH loop test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-sympwn-rpl-send-v1-2-1753993bb584@gmail.com>
References: <20260911-sympwn-rpl-send-v1-0-1753993bb584@gmail.com>
In-Reply-To: <20260911-sympwn-rpl-send-v1-0-1753993bb584@gmail.com>
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Alexander Aring <alex.aring@gmail.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Mark Amirkan <markdamirkan@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789168285; l=2121;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=oYolW/2kgmaKhTJtOnbVhNTitMeYR8kNTB72g56mfrI=;
 b=0qrhrLzhLU4s5WCOOGL+Sb8Y7nG72SoC7cAB0bpXuevjbeF4Nb744BtxjOSTiIYledauPAv+f
 pVCl44yEdPQARSt1BVeseREqX1K8mXPvx8PtvZMGIX8NsnlTjjkAEG4
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two local addresses to a network namespace and exercise RPL route
validation. Verify that adjacent local addresses remain valid, while a
non-local address between them causes the route to be rejected.

Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
Assisted-by: Symbolic
---
 tools/testing/selftests/net/Makefile        |  1 +
 tools/testing/selftests/net/rpl_srh_loop.sh | 38 +++++++++++++++++++++++++++++
 2 files changed, 39 insertions(+)

diff --git a/tools/testing/selftests/net/Makefile b/tools/testing/selftests/net/Makefile
index 3ee3378f8b26..7fe7e38b9c6c 100644
--- a/tools/testing/selftests/net/Makefile
+++ b/tools/testing/selftests/net/Makefile
@@ -80,6 +80,7 @@ TEST_PROGS := \
 	reuseport_addr_any.sh \
 	route_hint.sh \
 	route_localnet.sh \
+	rpl_srh_loop.sh \
 	rps_default_mask.sh \
 	rtnetlink.py \
 	rtnetlink.sh \
diff --git a/tools/testing/selftests/net/rpl_srh_loop.sh b/tools/testing/selftests/net/rpl_srh_loop.sh
new file mode 100755
index 000000000000..a2e9991d789d
--- /dev/null
+++ b/tools/testing/selftests/net/rpl_srh_loop.sh
@@ -0,0 +1,38 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+
+source lib.sh
+
+cleanup()
+{
+	cleanup_ns "$NS"
+}
+
+trap cleanup EXIT
+
+require_command ip
+setup_ns NS || exit $?
+
+ip -n "$NS" -6 address add 2001:db8:1::1/128 dev lo nodad
+ip -n "$NS" -6 address add 2001:db8:3::1/128 dev lo nodad
+
+if ! ip -n "$NS" -6 route add 2001:db8:10::/64 \
+	encap rpl segs 2001:db8:4::1 dev lo 2>/dev/null; then
+	echo "SKIP: RPL lightweight tunnel support not available"
+	exit $ksft_skip
+fi
+
+RET=0
+ip -n "$NS" -6 route add 2001:db8:11::/64 \
+	encap rpl segs 2001:db8:1::1,2001:db8:3::1 dev lo
+check_err $? "Adjacent local addresses were rejected"
+log_test "RPL accepts adjacent local addresses"
+
+RET=0
+ip -n "$NS" -6 route add 2001:db8:12::/64 \
+	encap rpl segs 2001:db8:1::1,2001:db8:2::1,2001:db8:3::1 dev lo \
+	2>/dev/null
+check_fail $? "Separated local addresses were accepted"
+log_test "RPL rejects separated local addresses"
+
+exit $EXIT_STATUS

-- 
2.43.0

