From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 18:27:55 -0500
Subject: [PATCH] tests: add a regression test for the TCP Fast Open
 connect-mediation bypass
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-220b400d-v1-1-69d8f4ddf57e@proton.me>
X-B4-Tracking: v=1; b=H4sIAPrEOWoC/x3MMQqAMAxA0atIZgMxVkWvIg62iZpFpQURxLtbH
 N/w/wNJo2mCoXgg6mXJjj2jKgsI27yviibZwMQttczoHYqlE5nJOyLBWrpFmtoHdT3k7Iy62P0
 vx+l9P7QyOU9iAAAA
To: apparmor@lists.ubuntu.com
Cc: linux-security-module@vger.kernel.org, 
 John Johansen <john.johansen@canonical.com>, 
 Ryan Lee <ryan.lee@canonical.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782170874; l=15234;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=pz34+fbJMtj3MAiEmggC0Gsslhx3MK+XNCLyxbzmgQM=;
 b=r1fC5OJNWG2rbIA3/NySd3Mp3eeyg9iJG+IPkPXxF1LdZ80hwegRoYhamylY2GCMz/T02wPo0
 8GtNzfmyTlZAJw0k3UTuVrxlvftx5IfUEfBEazVhyXGLTUxYJFd1qhx
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sendto(MSG_FASTOPEN) performs an implicit connect that the kernel's
apparmor_socket_sendmsg() did not mediate as a connect, so a profile
granting inet/inet6 stream send but denying connect was bypassed. Add a
test that, under such a profile, asserts connect(2) is denied AND
sendto(MSG_FASTOPEN) is also denied -- the latter requires the kernel fix
"apparmor: mediate the implicit connect of TCP fast open sendmsg".

It exercises both producers the fix guards -- plain TCP (inet/inet6) and
MPTCP (IPPROTO_MPTCP) -- plus a positive control where connect is allowed.
The test red-baselines on a vulnerable kernel and skips cleanly when the
required fine-grained network mediation or TCP Fast Open is unavailable
(requires_any_of_kernel_features / requires_parser_support, plus a
tcp_fastopen guard); the MPTCP cases are skipped if MPTCP is disabled.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
This is the userspace regression test for the AppArmor TCP Fast Open
connect-mediation kernel fix posted to linux-security-module:
  https://lore.kernel.org/all/20260622-b4-disp-aba401c6-v1-1-9d74343c7ced@proton.me/
It mirrors the SELinux testsuite test ("[PATCH testsuite] tests/inet_socket:
add tests for TCP Fast Open", Stephen Smalley) and was requested by the
AppArmor team (Ryan Lee).

It covers both producers the kernel fix mediates -- plain TCP (inet/inet6)
and MPTCP -- plus a positive control. It red-baselines on a vulnerable
kernel (the fastopen assertions fail) and skips cleanly when TCP Fast Open
or fine-grained network mediation is unavailable.
---
 tests/regression/apparmor/Makefile                 |   2 +
 tests/regression/apparmor/net_inet_tcp_fastopen.c  | 241 +++++++++++++++++++++
 tests/regression/apparmor/net_inet_tcp_fastopen.sh | 119 ++++++++++
 3 files changed, 362 insertions(+)

diff --git a/tests/regression/apparmor/Makefile b/tests/regression/apparmor/Makefile
index 345f39968..18e408f5c 100644
--- a/tests/regression/apparmor/Makefile
+++ b/tests/regression/apparmor/Makefile
@@ -151,6 +151,7 @@ SRC=access.c \
     named_pipe.c \
     net_inet_rcv.c \
     net_inet_snd.c \
+    net_inet_tcp_fastopen.c \
     net_raw.c \
     open.c \
     openat.c \
@@ -325,6 +326,7 @@ TESTS=aa_exec \
       namespaces \
       net_iface \
       net_inet \
+      net_inet_tcp_fastopen \
       net_raw \
       overlayfs_kernel \
       open \
diff --git a/tests/regression/apparmor/net_inet_tcp_fastopen.c b/tests/regression/apparmor/net_inet_tcp_fastopen.c
new file mode 100644
index 000000000..cfc1ff9c5
--- /dev/null
+++ b/tests/regression/apparmor/net_inet_tcp_fastopen.c
@@ -0,0 +1,241 @@
+/*
+ *	Copyright (C) 2026 Canonical, Ltd.
+ *
+ *	This program is free software; you can redistribute it and/or
+ *	modify it under the terms of the GNU General Public License as
+ *	published by the Free Software Foundation, version 2 of the
+ *	License.
+ */
+
+/*
+ * TCP Fast Open connect-mediation bypass regression test.
+ *
+ * Under an AppArmor profile that grants inet/inet6 stream "send" but DENIES
+ * "connect", a plain connect(2) must be refused (EACCES/EPERM). Historically
+ * the kernel's TFO fast path (sendto(..., MSG_FASTOPEN, ...), which performs
+ * an implicit connect) only checked the send permission (AA_NET_SEND 0x02)
+ * and skipped the connect permission (AA_NET_CONNECT 0x40), so a confined
+ * task could open an outbound connection that connect(2) would have blocked.
+ * The kernel fix mediates both producers: plain TCP and MPTCP (IPPROTO_MPTCP).
+ *
+ * This binary takes a mode and asserts the operation is DENIED:
+ *   argv[1] = "connect"  -> baseline: connect(2) must be denied
+ *   argv[1] = "fastopen" -> the bug: sendto(MSG_FASTOPEN) must be denied
+ *   argv[2] = family: "inet"/"inet6" (TCP) or "minet"/"minet6" (MPTCP)
+ *   argv[3] = port (the listener port, set up by this same process)
+ *
+ * Output contract (parsed by checktestfg in prologue.inc):
+ *   "PASS\n"  -> the operation was DENIED as required (regression OK)
+ *   "FAIL ..."-> the operation was ALLOWED (connect bypass) OR a setup error
+ *
+ * The .sh runs this with expected outcome "pass"; it also enables TCP Fast
+ * Open first, so an EOPNOTSUPP here is a real setup error, not a skip.
+ */
+
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <unistd.h>
+#include <errno.h>
+#include <signal.h>
+#include <netinet/in.h>
+#include <netinet/tcp.h>
+#include <sys/socket.h>
+#include <sys/types.h>
+#include <sys/wait.h>
+#include <arpa/inet.h>
+
+#ifndef MSG_FASTOPEN
+#define MSG_FASTOPEN 0x20000000
+#endif
+
+#ifndef IPPROTO_MPTCP
+#define IPPROTO_MPTCP 262
+#endif
+
+/* Map a family token to (AF_*, protocol). "minet"/"minet6" select MPTCP.
+ * Returns 0 on success, -1 on an unknown token.
+ */
+static int parse_family(const char *tok, int *family, int *proto)
+{
+	*proto = 0;
+	if (strcmp(tok, "inet") == 0) {
+		*family = AF_INET;
+	} else if (strcmp(tok, "inet6") == 0) {
+		*family = AF_INET6;
+	} else if (strcmp(tok, "minet") == 0) {
+		*family = AF_INET;
+		*proto = IPPROTO_MPTCP;
+	} else if (strcmp(tok, "minet6") == 0) {
+		*family = AF_INET6;
+		*proto = IPPROTO_MPTCP;
+	} else {
+		return -1;
+	}
+	return 0;
+}
+
+/* Build a loopback sockaddr for the requested family. Returns addrlen. */
+static socklen_t make_addr(int family, int port, struct sockaddr_storage *ss)
+{
+	memset(ss, 0, sizeof(*ss));
+	if (family == AF_INET) {
+		struct sockaddr_in *a = (struct sockaddr_in *)ss;
+
+		a->sin_family = AF_INET;
+		a->sin_port = htons(port);
+		inet_pton(AF_INET, "127.0.0.1", &a->sin_addr);
+		return sizeof(*a);
+	}
+	{
+		struct sockaddr_in6 *a = (struct sockaddr_in6 *)ss;
+
+		a->sin6_family = AF_INET6;
+		a->sin6_port = htons(port);
+		inet_pton(AF_INET6, "::1", &a->sin6_addr);
+		return sizeof(*a);
+	}
+}
+
+/* Start a plain TCP listener so the connect/TFO target exists. Returns the fd
+ * or -1. A TCP listener accepts both TCP and MPTCP clients, which keeps the
+ * test on the client-side mediation under examination. bind/listen perms are
+ * granted by the profile so this must succeed.
+ */
+static int start_listener(int family, int port)
+{
+	int s, one = 1;
+	struct sockaddr_storage ss;
+	socklen_t len = make_addr(family, port, &ss);
+
+	s = socket(family, SOCK_STREAM, 0);
+	if (s < 0) {
+		printf("FAIL - listener socket: %m\n");
+		return -1;
+	}
+	(void)setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
+	/* Enable TFO on the listener (qlen). Best-effort; the mediation check
+	 * under test happens on the client side. */
+	(void)setsockopt(s, IPPROTO_TCP, TCP_FASTOPEN, &one, sizeof(one));
+	if (bind(s, (struct sockaddr *)&ss, len) < 0) {
+		printf("FAIL - listener bind: %m\n");
+		close(s);
+		return -1;
+	}
+	if (listen(s, 5) < 0) {
+		printf("FAIL - listener listen: %m\n");
+		close(s);
+		return -1;
+	}
+	return s;
+}
+
+/* Returns 1 if the kernel DENIED the operation (EACCES/EPERM) => regression OK.
+ * Returns 0 if the operation was ALLOWED (connect bypass) => regression FAIL.
+ * Returns -1 on a setup error.
+ */
+static int try_connect(int family, int proto, int port)
+{
+	int s, rc;
+	struct sockaddr_storage ss;
+	socklen_t len = make_addr(family, port, &ss);
+
+	s = socket(family, SOCK_STREAM, proto);
+	if (s < 0)
+		return -1;
+	rc = connect(s, (struct sockaddr *)&ss, len);
+	if (rc == 0) {
+		close(s);
+		return 0;			/* allowed */
+	}
+	if (errno == EACCES || errno == EPERM) {
+		close(s);
+		return 1;			/* denied by AppArmor */
+	}
+	/* ECONNREFUSED/ETIMEDOUT mean it reached the network: mediation did not
+	 * block it, so count as allowed. */
+	close(s);
+	return (errno == ECONNREFUSED || errno == ETIMEDOUT) ? 0 : -1;
+}
+
+static int try_fastopen(int family, int proto, int port)
+{
+	int s;
+	ssize_t rc;
+	char msg[] = "tfo";
+	struct sockaddr_storage ss;
+	socklen_t len = make_addr(family, port, &ss);
+
+	s = socket(family, SOCK_STREAM, proto);
+	if (s < 0)
+		return -1;
+
+	/* The bug: this implicit-connect send must be mediated as a connect. */
+	rc = sendto(s, msg, sizeof(msg), MSG_FASTOPEN,
+		    (struct sockaddr *)&ss, len);
+	if (rc >= 0) {
+		close(s);
+		return 0;			/* allowed: connect bypass */
+	}
+	if (errno == EACCES || errno == EPERM) {
+		close(s);
+		return 1;			/* denied by AppArmor */
+	}
+	if (errno == EOPNOTSUPP || errno == EINVAL) {
+		/* The .sh enabled TCP Fast Open before running, so this is a
+		 * real setup error, not an expected condition. Fail loudly
+		 * rather than masking it as a denial. */
+		close(s);
+		return -1;
+	}
+	close(s);
+	return (errno == ECONNREFUSED || errno == ETIMEDOUT) ? 0 : -1;
+}
+
+int main(int argc, char *argv[])
+{
+	int family, proto, port, denied, listener;
+	const char *mode;
+
+	if (argc < 4) {
+		printf("FAIL - usage: %s connect|fastopen inet|inet6|minet|minet6 port\n",
+		       argv[0]);
+		return 1;
+	}
+	mode = argv[1];
+	if (parse_family(argv[2], &family, &proto) < 0) {
+		printf("FAIL - unknown family '%s'\n", argv[2]);
+		return 1;
+	}
+	port = atoi(argv[3]);
+
+	signal(SIGPIPE, SIG_IGN);
+
+	listener = start_listener(family, port);
+	if (listener < 0)
+		return 1;			/* FAIL already printed */
+
+	if (strcmp(mode, "connect") == 0) {
+		denied = try_connect(family, proto, port);
+	} else if (strcmp(mode, "fastopen") == 0) {
+		denied = try_fastopen(family, proto, port);
+	} else {
+		printf("FAIL - unknown mode '%s'\n", mode);
+		close(listener);
+		return 1;
+	}
+
+	close(listener);
+
+	if (denied == 1) {
+		printf("PASS\n");
+		return 0;
+	}
+	if (denied == 0) {
+		printf("FAIL - %s was ALLOWED despite deny connect "
+		       "(connect-mediation bypass)\n", mode);
+		return 1;
+	}
+	printf("FAIL - %s setup error: %m\n", mode);
+	return 1;
+}
diff --git a/tests/regression/apparmor/net_inet_tcp_fastopen.sh b/tests/regression/apparmor/net_inet_tcp_fastopen.sh
new file mode 100755
index 000000000..76300c53f
--- /dev/null
+++ b/tests/regression/apparmor/net_inet_tcp_fastopen.sh
@@ -0,0 +1,119 @@
+#! /bin/bash
+#	Copyright (C) 2026 Canonical, Ltd.
+#
+#	This program is free software; you can redistribute it and/or
+#	modify it under the terms of the GNU General Public License as
+#	published by the Free Software Foundation, version 2 of the
+#	License.
+
+#=NAME net_inet_tcp_fastopen
+#=DESCRIPTION
+# Regression test for the TCP Fast Open connect-mediation bypass. Under a
+# profile that grants inet/inet6 stream "send" but DENIES "connect", a plain
+# connect(2) is refused, and sendto(..., MSG_FASTOPEN, ...) (which performs an
+# implicit connect) MUST also be refused -- for both plain TCP and MPTCP. Pre-fix
+# the TFO path checked only the send permission (AA_NET_SEND 0x02) and skipped
+# connect (AA_NET_CONNECT 0x40).
+#=END
+
+pwd=`dirname $0`
+pwd=`cd $pwd ; /bin/pwd`
+
+bin=$pwd
+
+. "$bin/prologue.inc"
+
+# Need fine-grained inet mediation (connect/send are separable only there).
+requires_any_of_kernel_features network_v8/af_inet network_v9/af_inet
+requires_parser_support "network (send) ip=::1,"
+
+settest net_inet_tcp_fastopen
+
+tfo_sysctl=/proc/sys/net/ipv4/tcp_fastopen
+tfo_saved=""
+
+cleanup()
+{
+	# restore the original tcp_fastopen value if we changed it
+	if [ -n "$tfo_saved" ]; then
+		echo "$tfo_saved" > "$tfo_sysctl" 2>/dev/null || true
+	fi
+}
+do_onexit="cleanup"
+
+# The sendto(MSG_FASTOPEN) client path needs the TCP Fast Open client bit
+# (0x1). Enable it for the run; if it is unavailable (no sysctl, or it cannot
+# be enabled) the bug cannot be exercised at all, so skip rather than report a
+# spurious failure.
+if [ ! -w "$tfo_sysctl" ]; then
+	echo "    TCP Fast Open sysctl ($tfo_sysctl) not available. Skipping tests ..."
+	exit 0
+fi
+tfo_saved=`cat "$tfo_sysctl"`
+echo $((tfo_saved | 1)) > "$tfo_sysctl" 2>/dev/null || true
+if [ $(($(cat "$tfo_sysctl") & 1)) -ne 1 ]; then
+	echo "    Could not enable the TCP Fast Open client bit. Skipping tests ..."
+	exit 0
+fi
+
+# add ::1 if not already present (loopback usually has it)
+ip -6 addr add ::1/128 dev lo 2>/dev/null || true
+
+# pick a free port for the listener this binary creates
+port=4321
+while lsof -i:$port >/dev/null 2>&1; do
+	let port=$port+1
+done
+
+# Profile: allow stream send/receive + the perms needed to stand up the
+# in-process listener (bind/listen/accept), allow setopt/getopt for TFO
+# sockopts, but explicitly DENY connect on both inet and inet6.
+gen_send_no_connect()
+{
+	genprofile \
+	  "network;(send,receive,accept,listen,bind);ip=127.0.0.1;port=$port" \
+	  "network;(send,receive,accept,listen,bind);ip=::1;port=$port" \
+	  "network;(send,receive);peer=(ip=127.0.0.1)" \
+	  "network;(send,receive);peer=(ip=::1)" \
+	  "network;(setopt,getopt);ip=0.0.0.0;port=0" \
+	  "network;(setopt,getopt);ip=::0;port=0" \
+	  "qual=deny:network;(connect);ip=127.0.0.1" \
+	  "qual=deny:network;(connect);ip=::1"
+}
+
+# ---- inet (IPv4) ----
+gen_send_no_connect
+# baseline: a normal connect(2) must be denied -> binary prints PASS (denied),
+# expected outcome 'pass'
+runchecktest "TFO inet - connect(2) denied" pass connect inet $port
+# the bug: sendto(MSG_FASTOPEN) must ALSO be denied post-fix
+runchecktest "TFO inet - sendto(MSG_FASTOPEN) denied" pass fastopen inet $port
+
+# ---- inet6 (IPv6) ----
+gen_send_no_connect
+runchecktest "TFO inet6 - connect(2) denied" pass connect inet6 $port
+runchecktest "TFO inet6 - sendto(MSG_FASTOPEN) denied" pass fastopen inet6 $port
+
+# ---- MPTCP: the second producer the fix guards (IPPROTO_MPTCP) ----
+# The deny-connect rule is family/type based, so it covers MPTCP (inet/inet6
+# stream) too. Only run when MPTCP is enabled.
+if [ "`cat /proc/sys/net/mptcp/enabled 2>/dev/null`" = "1" ]; then
+	gen_send_no_connect
+	runchecktest "TFO MPTCP inet - connect(2) denied" pass connect minet $port
+	runchecktest "TFO MPTCP inet - sendto(MSG_FASTOPEN) denied" pass fastopen minet $port
+	gen_send_no_connect
+	runchecktest "TFO MPTCP inet6 - connect(2) denied" pass connect minet6 $port
+	runchecktest "TFO MPTCP inet6 - sendto(MSG_FASTOPEN) denied" pass fastopen minet6 $port
+fi
+
+# ---- positive control: when connect IS allowed, both succeed (no false deny) ----
+genprofile \
+  "network;(connect,send,receive,accept,listen,bind);ip=127.0.0.1;port=$port" \
+  "network;(connect,send,receive);peer=(ip=127.0.0.1)" \
+  "network;(setopt,getopt);ip=0.0.0.0;port=0"
+# Here the binary's "denied" assertion is FALSE (op allowed), so it prints
+# FAIL; we expect that, i.e. expected outcome 'fail'.
+runchecktest "TFO inet - connect allowed (control)" fail connect inet $port
+runchecktest "TFO inet - fastopen allowed (control)" fail fastopen inet $port
+
+exit 0

---
base-commit: bdccc1ebd2e1a1b75ceb8f87b23831fe273b9ebb
change-id: 20260622-b4-disp-220b400d-3d7fd53bce49

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

