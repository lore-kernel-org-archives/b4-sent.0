From: Alireza Asgari <alireza@asgari.net>
Date: Thu, 24 Sep 2026 13:00:25 +0000
Subject: [PATCH net 2/2] selftests: net: cover UDP splice checksum fragment
 alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-fix-udp-splice-checksum-v1-2-fe61d65447a8@asgari.net>
References: <20260924-fix-udp-splice-checksum-v1-0-fe61d65447a8@asgari.net>
In-Reply-To: <20260924-fix-udp-splice-checksum-v1-0-fe61d65447a8@asgari.net>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Howells <dhowells@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790254849; l=12806;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=3WgZtjdGhpyGxXoJGzwfMeILWbCWZIJDIha+kdwRhbE=;
 b=eDUmMk6UCV4/tnQd/Og/OPP2nF/rl22EyU60LP0jIrTIJ6OC9+8tstvkRGhUZC5uSrU/308TU
 XCz5mvZGheaD8WgDq8MNqkhvfUSSYuO2QlNAQ3/aHKH2m2UqVodI0rp
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exercise software UDP checksums when splice() transfers multiple pipe
fragments into a corked datagram. Use separate source pipes so short writes
cannot merge, and use odd fragment lengths to expose checksum-position
errors between fragments.

Cover IPv4, IPv6 and IPv4-mapped destinations, connected and unconnected
sockets, resident prefixes, even and odd fragment lengths, and a fragment
starting near a page boundary. Ordinary sends provide a control. Check the
complete payload and reject extra datagrams after a successful send.

Keep receive waits bounded and skip unavailable address families or pipe
capacities. The test uses only loopback sockets with ephemeral ports and
has no dependency on the application that exposed the regression.

Assisted-by: LLM
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 tools/testing/selftests/net/.gitignore            |   1 +
 tools/testing/selftests/net/Makefile              |   1 +
 tools/testing/selftests/net/udp_splice_checksum.c | 378 ++++++++++++++++++++++
 3 files changed, 380 insertions(+)

diff --git a/tools/testing/selftests/net/.gitignore b/tools/testing/selftests/net/.gitignore
index c9f46031ac..dacd36ed84 100644
--- a/tools/testing/selftests/net/.gitignore
+++ b/tools/testing/selftests/net/.gitignore
@@ -55,6 +55,7 @@ tools
 tun
 txring_overwrite
 txtimestamp
+udp_splice_checksum
 udpgso
 udpgso_bench_rx
 udpgso_bench_tx
diff --git a/tools/testing/selftests/net/Makefile b/tools/testing/selftests/net/Makefile
index 3ee3378f8b..590b33e16d 100644
--- a/tools/testing/selftests/net/Makefile
+++ b/tools/testing/selftests/net/Makefile
@@ -199,6 +199,7 @@ TEST_GEN_PROGS := \
 	tap \
 	tcp_port_share \
 	tls \
+	udp_splice_checksum \
 # end of TEST_GEN_PROGS
 
 TEST_FILES := \
diff --git a/tools/testing/selftests/net/udp_splice_checksum.c b/tools/testing/selftests/net/udp_splice_checksum.c
new file mode 100644
index 0000000000..dc61444e64
--- /dev/null
+++ b/tools/testing/selftests/net/udp_splice_checksum.c
@@ -0,0 +1,378 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Exercise UDP software checksums over multiple spliced pipe fragments.
+ * All traffic stays on loopback; no privileges or external services are needed.
+ * Exit status: 0 = pass, 1 = failure, 4 = all cases skipped.
+ */
+#define _GNU_SOURCE
+
+#include <arpa/inet.h>
+#include <errno.h>
+#include <fcntl.h>
+#include <poll.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/socket.h>
+#include <time.h>
+#include <unistd.h>
+
+#include "kselftest.h"
+
+#define TIMEOUT_MS 200
+
+struct test_case {
+	const char *name;
+	const char *body;
+	const char *prefix;
+	size_t fragments[3];
+	bool ordinary;
+	bool page_tail;
+};
+
+static const struct test_case cases[] = {
+	{ "ordinary-control", "abcDEFGH", "", { 3, 5 }, true, false },
+	{ "uniform-odd-fragments", "BBBBBBBB", "", { 3, 5 }, false, false },
+	{ "even-fragments", "abcdEFGH", "", { 4, 4 }, false, false },
+	{ "odd-fragments", "abcDEFGH", "", { 3, 5 }, false, false },
+	{ "odd-prefix-odd-fragments", "abcDEFGH", "P", { 3, 5 }, false, false },
+	{ "even-prefix-odd-fragments", "abcDEFGH", "PQ", { 3, 5 }, false, false },
+	{ "page-tail-odd-fragments", "abcDEFGH", "", { 3, 5 }, false, true },
+	{ "three-fragments", "abcDEFGhijkl", "", { 3, 4, 5 }, false, false },
+	{ "odd-prefix-three-fragments",
+	  "abcDEFGhijkl",
+	  "P",
+	  { 3, 4, 5 },
+	  false,
+	  false },
+};
+
+static const char *const families[] = { "IPv4", "IPv6", "IPv4-mapped" };
+
+static int error(const char *what)
+{
+	ksft_perror(what);
+	return 1;
+}
+
+static bool unavailable(void)
+{
+	return errno == EAFNOSUPPORT || errno == EPROTONOSUPPORT ||
+	       errno == EADDRNOTAVAIL;
+}
+
+static long long now_ms(void)
+{
+	struct timespec ts;
+
+	if (clock_gettime(CLOCK_MONOTONIC, &ts))
+		ksft_exit_fail_perror("clock_gettime");
+	return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
+}
+
+static int receive_one(int fd, const char *expected, size_t length)
+{
+	struct pollfd pfd = { .fd = fd, .events = POLLIN };
+	long long deadline = now_ms() + TIMEOUT_MS;
+	int remaining, ret;
+	char received[64];
+	ssize_t count;
+
+	for (;;) {
+		remaining = deadline - now_ms();
+		if (remaining < 0)
+			remaining = 0;
+		ret = poll(&pfd, 1, remaining);
+		if (ret < 0) {
+			if (errno == EINTR)
+				continue;
+			return error("poll");
+		}
+		if (!ret) {
+			ksft_print_msg("no datagram within %d ms after send\n",
+				       TIMEOUT_MS);
+			return 1;
+		}
+		count = recv(fd, received, sizeof(received),
+			     MSG_DONTWAIT | MSG_TRUNC);
+		if (count < 0) {
+			if (errno == EINTR || errno == EAGAIN)
+				continue;
+			return error("recv");
+		}
+		break;
+	}
+	if (count != (ssize_t)length || memcmp(received, expected, length)) {
+		ksft_print_msg("received %zd bytes; expected %zu matching\n",
+			       count, length);
+		return 1;
+	}
+	count = recv(fd, received, sizeof(received), MSG_DONTWAIT | MSG_TRUNC);
+	if (count >= 0) {
+		ksft_print_msg("unexpected extra datagram (%zd bytes)\n",
+			       count);
+		return 1;
+	}
+	if (errno != EAGAIN)
+		return error("extra-datagram check");
+	return 0;
+}
+
+/* Separate source pipes prevent adjacent small writes merging into one buffer. */
+static int append_fragment(int dest, const char *data, size_t length)
+{
+	int source[2], ret = 1;
+
+	if (pipe2(source, O_NONBLOCK | O_CLOEXEC))
+		return error("source pipe");
+	if (write(source[1], data, length) != (ssize_t)length) {
+		error("source write");
+		goto out;
+	}
+	if (splice(source[0], NULL, dest, NULL, length, SPLICE_F_NONBLOCK) !=
+	    (ssize_t)length) {
+		error("pipe-to-pipe splice");
+		goto out;
+	}
+	ret = 0;
+out:
+	close(source[0]);
+	close(source[1]);
+	return ret;
+}
+
+static int pipe_capacity(int fd, unsigned int slots, const char **skip_reason)
+{
+	long required = slots * sysconf(_SC_PAGESIZE);
+	int capacity = fcntl(fd, F_GETPIPE_SZ);
+
+	if (capacity < 0)
+		return error("query pipe capacity");
+	if (capacity >= required ||
+	    fcntl(fd, F_SETPIPE_SZ, required) >= required)
+		return 0;
+	ksft_print_msg("cannot reserve %u pipe slots: %s\n", slots,
+		       strerror(errno));
+	*skip_reason = "required pipe capacity unavailable";
+	return KSFT_SKIP;
+}
+
+/* Leave three bytes at a page's end, followed by five bytes on the next page. */
+static int append_page_tail(int dest, const char *body,
+			    const char **skip_reason)
+{
+	long page = sysconf(_SC_PAGESIZE);
+	int source[2], ret = 1;
+	char *data;
+
+	if (page < 8) {
+		ksft_print_msg("invalid page size %ld\n", page);
+		return 1;
+	}
+	data = malloc(page + 5);
+	if (!data)
+		return error("malloc");
+	memset(data, 'x', page - 3);
+	memcpy(data + page - 3, body, 8);
+	if (pipe2(source, O_NONBLOCK | O_CLOEXEC)) {
+		error("page-tail source pipe");
+		goto free_data;
+	}
+	ret = pipe_capacity(source[1], 2, skip_reason);
+	if (ret)
+		goto out;
+	ret = 1;
+	if (write(source[1], data, page + 5) != page + 5) {
+		error("page-tail write");
+		goto out;
+	}
+	if (read(source[0], data, page - 3) != page - 3) {
+		error("page-tail discard");
+		goto out;
+	}
+	if (splice(source[0], NULL, dest, NULL, 8, SPLICE_F_NONBLOCK) != 8) {
+		error("page-tail pipe-to-pipe splice");
+		goto out;
+	}
+	ret = 0;
+out:
+	close(source[0]);
+	close(source[1]);
+free_data:
+	free(data);
+	return ret;
+}
+
+static int run_case(unsigned int family, bool connected,
+		    const struct test_case *test, const char **skip_reason)
+{
+	size_t body_length = strlen(test->body), offset = 0;
+	int tx_family = family == 0 ? AF_INET : AF_INET6;
+	int rx_family = family == 1 ? AF_INET6 : AF_INET;
+	int rx = -1, tx = -1, pipefd[2] = { -1, -1 };
+	size_t prefix_length = strlen(test->prefix);
+	struct sockaddr_storage address = { 0 };
+	socklen_t address_length;
+	struct sockaddr_in6 *v6;
+	struct sockaddr_in *v4;
+	int ret = 1, zero = 0;
+	char expected[64];
+	unsigned int i;
+	ssize_t count;
+
+	v4 = (struct sockaddr_in *)&address;
+	v6 = (struct sockaddr_in6 *)&address;
+	*skip_reason = "address family unavailable";
+	memcpy(expected, test->prefix, prefix_length);
+	memcpy(expected + prefix_length, test->body, body_length);
+	rx = socket(rx_family, SOCK_DGRAM | SOCK_CLOEXEC, 0);
+	if (rx < 0) {
+		ret = unavailable() ? KSFT_SKIP : error("receive socket");
+		goto out;
+	}
+	if (rx_family == AF_INET) {
+		v4->sin_family = AF_INET;
+		v4->sin_addr.s_addr = htonl(INADDR_LOOPBACK);
+		address_length = sizeof(*v4);
+	} else {
+		v6->sin6_family = AF_INET6;
+		v6->sin6_addr = in6addr_loopback;
+		address_length = sizeof(*v6);
+	}
+	if (bind(rx, (struct sockaddr *)&address, address_length)) {
+		ret = unavailable() ? KSFT_SKIP : error("bind loopback");
+		goto out;
+	}
+	if (getsockname(rx, (struct sockaddr *)&address, &address_length)) {
+		error("getsockname");
+		goto out;
+	}
+	if (family == 2) {
+		unsigned short port = v4->sin_port;
+
+		memset(&address, 0, sizeof(address));
+		v6->sin6_family = AF_INET6;
+		v6->sin6_port = port;
+		inet_pton(AF_INET6, "::ffff:127.0.0.1", &v6->sin6_addr);
+		address_length = sizeof(*v6);
+	}
+	tx = socket(tx_family, SOCK_DGRAM | SOCK_CLOEXEC, 0);
+	if (tx < 0) {
+		ret = unavailable() ? KSFT_SKIP : error("send socket");
+		goto out;
+	}
+	if (family == 2 &&
+	    setsockopt(tx, IPPROTO_IPV6, IPV6_V6ONLY, &zero, sizeof(zero))) {
+		error("disable IPV6_V6ONLY");
+		goto out;
+	}
+	if (connected &&
+	    connect(tx, (struct sockaddr *)&address, address_length)) {
+		error("connect");
+		goto out;
+	}
+	if (test->ordinary) {
+		count = sendto(tx, expected, prefix_length + body_length, 0,
+			       (struct sockaddr *)&address, address_length);
+		if (count != (ssize_t)(prefix_length + body_length)) {
+			error("ordinary sendto");
+			goto out;
+		}
+	} else {
+		if (pipe2(pipefd, O_NONBLOCK | O_CLOEXEC)) {
+			error("assembled pipe");
+			goto out;
+		}
+		ret = pipe_capacity(pipefd[1], test->fragments[2] ? 3 : 2,
+				    skip_reason);
+		if (ret)
+			goto out;
+		ret = 1;
+		if (test->page_tail) {
+			ret = append_page_tail(pipefd[1], test->body,
+					       skip_reason);
+			if (ret)
+				goto out;
+			ret = 1;
+		} else {
+			for (i = 0; i < ARRAY_SIZE(test->fragments); i++) {
+				if (!test->fragments[i])
+					break;
+				if (append_fragment(pipefd[1],
+						    test->body + offset,
+						    test->fragments[i]))
+					goto out;
+				offset += test->fragments[i];
+			}
+		}
+		/* Even an empty prefix establishes the destination and UDP cork. */
+		count = sendto(tx, test->prefix, prefix_length, MSG_MORE,
+			       (struct sockaddr *)&address, address_length);
+		if (count != (ssize_t)prefix_length) {
+			error("prime sendto(MSG_MORE)");
+			goto out;
+		}
+		count = splice(pipefd[0], NULL, tx, NULL, body_length,
+			       SPLICE_F_NONBLOCK | SPLICE_F_MORE);
+		if (count != (ssize_t)body_length) {
+			ksft_print_msg("socket splice: %zd, expected %zu: %s\n",
+				       count, body_length,
+				       count < 0 ? strerror(errno) :
+						   "short transfer");
+			goto out;
+		}
+		if (sendto(tx, "", 0, 0, (struct sockaddr *)&address,
+			   address_length)) {
+			error("commit sendto");
+			goto out;
+		}
+	}
+	ret = receive_one(rx, expected, prefix_length + body_length);
+out:
+	if (pipefd[0] >= 0) {
+		close(pipefd[0]);
+		close(pipefd[1]);
+	}
+	if (tx >= 0)
+		close(tx);
+	if (rx >= 0)
+		close(rx);
+	return ret;
+}
+
+int main(void)
+{
+	unsigned int family, connected, i;
+	const char *connection, *skip;
+	int ret;
+
+	ksft_print_header();
+	ksft_set_plan(ARRAY_SIZE(families) * 2 * ARRAY_SIZE(cases));
+	for (family = 0; family < ARRAY_SIZE(families); family++) {
+		for (connected = 0; connected < 2; connected++) {
+			connection = connected ? "connected" : "unconnected";
+			for (i = 0; i < ARRAY_SIZE(cases); i++) {
+				ret = run_case(family, connected, &cases[i],
+					       &skip);
+				if (ret == KSFT_SKIP)
+					ksft_test_result_skip("%s %s %s: %s\n",
+							      families[family],
+							      connection,
+							      cases[i].name,
+							      skip);
+				else
+					ksft_test_result(!ret, "%s %s %s\n",
+							 families[family],
+							 connection,
+							 cases[i].name);
+			}
+		}
+	}
+	if (!ksft_get_pass_cnt() && !ksft_get_fail_cnt()) {
+		/* ksft_exit_skip() would add a result beyond the plan. */
+		ksft_print_cnts();
+		return KSFT_SKIP;
+	}
+	ksft_finished();
+}

-- 
2.34.1

