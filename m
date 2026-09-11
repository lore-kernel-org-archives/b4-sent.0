From: Quanye Yang <quanyeyang@proton.me>
Date: Fri, 11 Sep 2026 23:42:08 +0800
Subject: [PATCH mptcp-net v2 2/2] selftests: mptcp: join: retry connect
 after early fallback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mptcp-connect-undo-net-v2-2-54224cea2238@proton.me>
References: <20260911-mptcp-connect-undo-net-v2-0-54224cea2238@proton.me>
In-Reply-To: <20260911-mptcp-connect-undo-net-v2-0-54224cea2238@proton.me>
To: mptcp@lists.linux.dev
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789141332; l=10390;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=TgcJx9K1BwzBI2BnFgkB7YkEtClbAU1cR8sXW8Q7B9k=;
 b=DUKG9g/M65dnDJ+K3T/XhgyezIaDRmgptVQqprMYMgpxrtinhEhPje5JTNiRUMxAXGRGAMcpF
 Hm2/zr2MjHEAOxTWI2ON/9jPLRfWQE1kMtccpPyeYWIQ/ruyzGNubGH
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover leftover msk state when connect() fails before
SS_CONNECTING. Existing mptcp_connect tests always use a fresh
socket, so they cannot see a sticky fallback on the same fd.

Add a small helper that optionally issues a wrong-family connect()
on an MPTCP socket, then connects to a real IPv4 destination and
checks MPTCP_INFO. A new mptcp_join.sh group (-n) runs two cases:

- a failed connect without early fallback must not poison the retry
- after a blackhole-driven early fallback plus a failed connect,
  clearing blackhole_timeout, the same fd must complete MP_CAPABLE
  again

Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 tools/testing/selftests/net/mptcp/.gitignore       |   1 +
 tools/testing/selftests/net/mptcp/Makefile         |   1 +
 .../selftests/net/mptcp/mptcp_connect_retry.c      | 216 +++++++++++++++++++++
 tools/testing/selftests/net/mptcp/mptcp_join.sh    | 108 +++++++++++
 4 files changed, 326 insertions(+)

diff --git a/tools/testing/selftests/net/mptcp/.gitignore b/tools/testing/selftests/net/mptcp/.gitignore
index 833279fb34e2..5ea8f3e4985f 100644
--- a/tools/testing/selftests/net/mptcp/.gitignore
+++ b/tools/testing/selftests/net/mptcp/.gitignore
@@ -1,5 +1,6 @@
 # SPDX-License-Identifier: GPL-2.0-only
 mptcp_connect
+mptcp_connect_retry
 mptcp_diag
 mptcp_inq
 mptcp_sockopt
diff --git a/tools/testing/selftests/net/mptcp/Makefile b/tools/testing/selftests/net/mptcp/Makefile
index 22ba0da2adb8..e2325d49228f 100644
--- a/tools/testing/selftests/net/mptcp/Makefile
+++ b/tools/testing/selftests/net/mptcp/Makefile
@@ -21,6 +21,7 @@ TEST_PROGS := \
 
 TEST_GEN_FILES := \
 	mptcp_connect \
+	mptcp_connect_retry \
 	mptcp_diag \
 	mptcp_inq \
 	mptcp_sockopt \
diff --git a/tools/testing/selftests/net/mptcp/mptcp_connect_retry.c b/tools/testing/selftests/net/mptcp/mptcp_connect_retry.c
new file mode 100644
index 000000000000..a034d2ad73f7
--- /dev/null
+++ b/tools/testing/selftests/net/mptcp/mptcp_connect_retry.c
@@ -0,0 +1,216 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Same-fd MPTCP connect() retry helper.
+ *
+ * Optionally fails an initial connect() with the wrong address family, then
+ * connects to the given IPv4 destination and checks MPTCP_INFO flags.
+ */
+
+#define _GNU_SOURCE
+
+#include <errno.h>
+#include <fcntl.h>
+#include <getopt.h>
+#include <netinet/in.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <unistd.h>
+#include <arpa/inet.h>
+#include <sys/socket.h>
+
+#include <linux/mptcp.h>
+
+#ifndef IPPROTO_MPTCP
+#define IPPROTO_MPTCP 262
+#endif
+#ifndef SOL_MPTCP
+#define SOL_MPTCP 284
+#endif
+
+static void die_perror(const char *msg)
+{
+	perror(msg);
+	exit(1);
+}
+
+static void usage(const char *argv0)
+{
+	fprintf(stderr,
+		"Usage: %s [-e] [-c] <ipv4> <port>\n"
+		"  -e  first connect() with a wrong sin_family (EAFNOSUPPORT)\n"
+		"  -c  clear net.mptcp.blackhole_timeout after the failed connect\n",
+		argv0);
+	exit(1);
+}
+
+static int getsockopt_mptcp_info(int fd, struct mptcp_info *info)
+{
+	socklen_t olen = sizeof(*info);
+
+	memset(info, 0, sizeof(*info));
+	return getsockopt(fd, SOL_MPTCP, MPTCP_INFO, info, &olen);
+}
+
+static int get_mptcp_info(int fd, struct mptcp_info *info)
+{
+	if (!getsockopt_mptcp_info(fd, info))
+		return 0;
+
+	/* Fallback sockets forward SOL_MPTCP to TCP. */
+	if (errno == EOPNOTSUPP) {
+		info->mptcpi_flags = MPTCP_INFO_FLAG_FALLBACK;
+		return 0;
+	}
+	return -1;
+}
+
+static int clear_blackhole_timeout(void)
+{
+	ssize_t n;
+	int fd;
+
+	fd = open("/proc/sys/net/mptcp/blackhole_timeout", O_WRONLY);
+	if (fd < 0)
+		return -1;
+
+	n = write(fd, "0\n", 2);
+	close(fd);
+	return n == 2 ? 0 : -1;
+}
+
+static int connect_wrong_family(int fd)
+{
+	struct sockaddr_in addr = {
+		.sin_family = AF_INET6,
+	};
+
+	if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
+		fprintf(stderr, "wrong-family connect() unexpectedly succeeded\n");
+		return -1;
+	}
+	if (errno != EAFNOSUPPORT) {
+		fprintf(stderr, "wrong-family connect(): unexpected errno %d (%s)\n",
+			errno, strerror(errno));
+		return -1;
+	}
+	return 0;
+}
+
+static int connect_ipv4(int fd, const char *ip, unsigned short port)
+{
+	struct sockaddr_in addr = {
+		.sin_family = AF_INET,
+		.sin_port = htons(port),
+	};
+
+	if (inet_pton(AF_INET, ip, &addr.sin_addr) != 1) {
+		fprintf(stderr, "invalid IPv4 address %s\n", ip);
+		return -1;
+	}
+	if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
+		fprintf(stderr, "connect(%s:%u): %s\n", ip, port, strerror(errno));
+		return -1;
+	}
+	return 0;
+}
+
+int main(int argc, char **argv)
+{
+	bool fail_first = false, clear_bh = false;
+	struct mptcp_info after_fail = { 0 }, after_ok, probe;
+	bool fail_fb = false, ok_fb, ok_key;
+	const char *ip;
+	unsigned short port;
+	int fd, opt, err = 0;
+	char buf[128];
+	ssize_t n;
+
+	while ((opt = getopt(argc, argv, "ec")) != -1) {
+		switch (opt) {
+		case 'e':
+			fail_first = true;
+			break;
+		case 'c':
+			clear_bh = true;
+			break;
+		default:
+			usage(argv[0]);
+		}
+	}
+
+	if (optind + 2 != argc)
+		usage(argv[0]);
+
+	ip = argv[optind];
+	port = atoi(argv[optind + 1]);
+	if (!port)
+		usage(argv[0]);
+
+	fd = socket(AF_INET, SOCK_STREAM, IPPROTO_MPTCP);
+	if (fd < 0)
+		die_perror("socket(IPPROTO_MPTCP)");
+
+	if (getsockopt_mptcp_info(fd, &probe)) {
+		fprintf(stderr, "getsockopt(MPTCP_INFO): %s\n", strerror(errno));
+		close(fd);
+		return 2;
+	}
+
+	if (fail_first && connect_wrong_family(fd)) {
+		close(fd);
+		return 1;
+	}
+
+	if (fail_first) {
+		if (get_mptcp_info(fd, &after_fail)) {
+			fprintf(stderr, "getsockopt(MPTCP_INFO) after fail: %s\n",
+				strerror(errno));
+			close(fd);
+			return 2;
+		}
+		fail_fb = after_fail.mptcpi_flags & MPTCP_INFO_FLAG_FALLBACK;
+	}
+
+	if (clear_bh && clear_blackhole_timeout()) {
+		fprintf(stderr, "unable to clear blackhole_timeout: %s\n",
+			strerror(errno));
+		close(fd);
+		return 1;
+	}
+
+	if (connect_ipv4(fd, ip, port)) {
+		close(fd);
+		return 1;
+	}
+
+	if (get_mptcp_info(fd, &after_ok)) {
+		fprintf(stderr, "getsockopt(MPTCP_INFO) after connect: %s\n",
+			strerror(errno));
+		close(fd);
+		return 2;
+	}
+
+	if (write(fd, "retry\n", 6) < 0)
+		perror("write");
+	shutdown(fd, SHUT_WR);
+	do {
+		n = read(fd, buf, sizeof(buf));
+	} while (n > 0);
+	close(fd);
+
+	ok_fb = after_ok.mptcpi_flags & MPTCP_INFO_FLAG_FALLBACK;
+	ok_key = after_ok.mptcpi_flags & MPTCP_INFO_FLAG_REMOTE_KEY_RECEIVED;
+
+	if (fail_fb) {
+		fprintf(stderr, "fallback still set after failed connect()\n");
+		err = 1;
+	}
+	if (ok_fb || !ok_key) {
+		fprintf(stderr, "second connect() did not complete MPTCP handshake\n");
+		err = 1;
+	}
+
+	return err;
+}
diff --git a/tools/testing/selftests/net/mptcp/mptcp_join.sh b/tools/testing/selftests/net/mptcp/mptcp_join.sh
index 18ce7136a2b0..dd7984414747 100755
--- a/tools/testing/selftests/net/mptcp/mptcp_join.sh
+++ b/tools/testing/selftests/net/mptcp/mptcp_join.sh
@@ -3876,6 +3876,113 @@ fail_tests()
 	fi
 }
 
+# $1: ns ; $2: addr ; $3: port
+start_mptcp_listener()
+{
+	local ns="${1}"
+	local addr="${2}"
+	local port="${3}"
+	local pid
+
+	ip netns exec "${ns}" ./mptcp_connect -t ${timeout_poll} -l -p "${port}" \
+		-s MPTCP "${addr}" < "${sin}" > "${sout}" &
+	pid=$!
+	mptcp_lib_wait_local_port_listen "${ns}" "${port}"
+	echo "${pid}"
+}
+
+# Drop MP_CAPABLE SYNs until the client netns records a blackhole.
+trigger_mptcp_blackhole()
+{
+	local port spid rc=0
+	local count
+
+	print_check "trigger blackhole"
+
+	ip netns exec $ns2 sysctl -q net.mptcp.syn_retrans_before_tcp_fallback=0
+
+	if ! ip netns exec $ns2 ${iptables} -A OUTPUT -p tcp \
+			-m tcp --tcp-option 30 -j DROP; then
+		mark_as_skipped "unable to drop MP_CAPABLE SYNs"
+		return 1
+	fi
+
+	port=$(get_port)
+	spid=$(start_mptcp_listener "$ns1" 10.0.1.1 "${port}")
+
+	timeout ${timeout_test} ip netns exec $ns2 ./mptcp_connect \
+		-t ${timeout_poll} -p "${port}" -s MPTCP 10.0.1.1 \
+		< "$cin" > "$cout" || rc=$?
+	wait "${spid}" 2>/dev/null || true
+
+	ip netns exec $ns2 ${iptables} -D OUTPUT -p tcp \
+		-m tcp --tcp-option 30 -j DROP 2>/dev/null || true
+
+	if [ ${rc} -ne 0 ]; then
+		fail_test "blackhole helper connect failed (rc=${rc})"
+		return 1
+	fi
+
+	count=$(mptcp_lib_get_counter $ns2 "MPTcpExtBlackhole")
+	if [ "${count:-0}" -lt 1 ]; then
+		fail_test "got ${count:-0} Blackhole event(s) expected >= 1"
+		return 1
+	fi
+
+	print_ok
+	return 0
+}
+
+connect_retry_tests()
+{
+	# failed connect without fallback, then retry
+	if reset "retry connect after failed connect"; then
+		local port spid rc
+
+		port=$(get_port)
+		spid=$(start_mptcp_listener "$ns1" 10.0.1.1 "${port}")
+
+		print_check "MPTCP after failed connect"
+		ip netns exec $ns2 ./mptcp_connect_retry -e 10.0.1.1 "${port}"
+		rc=$?
+		wait "${spid}" 2>/dev/null || true
+
+		if [ ${rc} -eq 2 ]; then
+			mark_as_skipped "MPTCP_INFO not available"
+		elif [ ${rc} -ne 0 ]; then
+			fail_test "retry connect without fallback failed (rc=${rc})"
+		else
+			print_ok
+		fi
+	fi
+
+	# early fallback + failed connect, then retry with blackhole disabled
+	if reset_check_counter "retry connect after early fallback fail" \
+			       "MPTcpExtBlackhole"; then
+		local port spid rc
+
+		if ! trigger_mptcp_blackhole; then
+			return
+		fi
+
+		port=$(get_port)
+		spid=$(start_mptcp_listener "$ns1" 10.0.1.1 "${port}")
+
+		print_check "MPTCP after sticky fallback fail"
+		ip netns exec $ns2 ./mptcp_connect_retry -e -c 10.0.1.1 "${port}"
+		rc=$?
+		wait "${spid}" 2>/dev/null || true
+
+		if [ ${rc} -eq 2 ]; then
+			mark_as_skipped "MPTCP_INFO not available"
+		elif [ ${rc} -ne 0 ]; then
+			fail_test "sticky fallback survived failed connect() (rc=${rc})"
+		else
+			print_ok
+		fi
+	fi
+}
+
 # $1: ns ; $2: addr ; $3: id
 userspace_pm_add_addr()
 {
@@ -4617,6 +4724,7 @@ all_tests_sorted=(
 	m@fullmesh_tests
 	z@fastclose_tests
 	F@fail_tests
+	n@connect_retry_tests
 	u@userspace_tests
 	I@endpoint_tests
 )

-- 
2.55.0

