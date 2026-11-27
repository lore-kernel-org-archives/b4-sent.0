From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 27 Nov 2026 23:37:41 +0100
Subject: [PATCH iproute2-next 3/3] testsuite: add test for lisp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iproute2-lisp-v1-3-df8ea175bc06@free.fr>
References: <20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr>
In-Reply-To: <20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr>
To: David Ahern <dsahern@kernel.org>, 
 Stephen Hemminger <stephen@networkplumber.org>
Cc: netdev@vger.kernel.org, Matthieu Baerts <matttbe@kernel.org>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795819063; l=2428;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=WXV+PDL4dcCQwPuXlvDRBbz0HV1YFgXClHcIX/Zyvgs=;
 b=QPx5sQVmJPzptU9SthlUiSkF6FIHbKrfQ5PQg+mrHOIHfnFLFwiY8zJ3NfCZT3xRJFdfh10Ri
 10PkHB/DXOeC54IfswMr2ztOyEL9wVoAXh/KjMmEeUH+3Qecik7pv5F
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LISP checks

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 testsuite/tests/ip/link/add_type_lisp.t | 59 +++++++++++++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/testsuite/tests/ip/link/add_type_lisp.t b/testsuite/tests/ip/link/add_type_lisp.t
new file mode 100755
index 00000000..d42f6dd3
--- /dev/null
+++ b/testsuite/tests/ip/link/add_type_lisp.t
@@ -0,0 +1,59 @@
+#!/bin/sh
+# SPDX-License-Identifier: GPL-2.0-or-later
+# Copyright (c) 2026 Vincent Jardin <vjardin@free.fr>, Free Mobile
+
+. lib/generic.sh
+
+# Skip test on a kernel without LISP
+NEW_DEV="$(rand_dev)"
+$IP link add dev "$NEW_DEV" type lisp id 1 2> /dev/null || ts_skip
+$IP link del dev "$NEW_DEV"
+
+ts_log "[Testing Add LISP interface (instance ID)]"
+NEW_DEV="$(rand_dev)"
+
+ts_ip "$0" "Add $NEW_DEV LISP interface (instance ID)" link add dev "$NEW_DEV" type lisp id 101
+
+ts_ip "$0" "Show $NEW_DEV LISP interface (instance ID)" -d link show dev "$NEW_DEV"
+test_on "$NEW_DEV"
+test_on "lisp id 101"
+test_on_not "external"
+test_on_not "local"
+
+ts_ip "$0" "Del $NEW_DEV LISP interface (instance ID)" link del dev "$NEW_DEV"
+
+
+ts_log "[Testing Add LISP interface (local RLOCs)]"
+NEW_DEV="$(rand_dev)"
+
+ts_ip "$0" "Add $NEW_DEV LISP interface (local RLOCs)" link add dev "$NEW_DEV" type lisp id 16777215 local 192.0.2.1 local 2001:db8::1
+
+ts_ip "$0" "Show $NEW_DEV LISP interface (local RLOCs)" -d link show dev "$NEW_DEV"
+test_on "$NEW_DEV"
+test_on "lisp id 16777215"
+test_on "local 192.0.2.1"
+test_on "local 2001:db8::1"
+
+ts_ip "$0" "Show $NEW_DEV LISP interface (local RLOCs, JSON)" -d -j link show dev "$NEW_DEV"
+test_on '"id":16777215'
+test_on '"local":"192.0.2.1"'
+test_on '"local6":"2001:db8::1"'
+
+ts_ip "$0" "Del $NEW_DEV LISP interface (local RLOCs)" link del dev "$NEW_DEV"
+
+
+ts_log "[Testing Add LISP interface (metadata)]"
+NEW_DEV="$(rand_dev)"
+
+ts_ip "$0" "Add $NEW_DEV LISP interface (metadata)" link add dev "$NEW_DEV" type lisp external
+
+ts_ip "$0" "Show $NEW_DEV LISP interface (metadata)" -d link show dev "$NEW_DEV"
+test_on "$NEW_DEV"
+test_on "lisp external"
+test_on_not "lisp id"
+
+ts_ip "$0" "Show $NEW_DEV LISP interface (metadata, JSON)" -d -j link show dev "$NEW_DEV"
+test_on '"external":true'
+
+ts_ip "$0" "Del $NEW_DEV LISP interface (metadata)" link del dev "$NEW_DEV"
+

-- 
2.43.0

