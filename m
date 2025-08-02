From: Christoph Paasch <cpaasch@openai.com>
Date: Sat, 02 Aug 2025 16:52:23 -0700
Subject: [PATCH mptcp-next 2/2] selftests: Add tests for SO_MAX_PACING_RATE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250802-b4-mptcp_setsockopt-v1-2-50d4905a4c2b@openai.com>
References: <20250802-b4-mptcp_setsockopt-v1-0-50d4905a4c2b@openai.com>
In-Reply-To: <20250802-b4-mptcp_setsockopt-v1-0-50d4905a4c2b@openai.com>
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754178751; l=3352;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=gOr7CBsY//YX/X8nlYFqDWpnQ4w3KSIQzDe9v6s9fe4=;
 b=SdwAulYfjpSHTT/XgJkmFgmJ8ib1eiRiFSEpOUk1JGtEsPwexlftLG+inCyYF+wVW54LWbzSd
 2C425JNpMtNDRhGS2l8p2vAzwixQGJq8H8yOv3/U5cIiMD7XvwjLCg0
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test to check the API for SO_MAX_PACING_RATE in MPTCP.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 74 +++++++++++++++++++++++
 1 file changed, 74 insertions(+)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
index 9934a68df23708ecb413c4ab26523989e3b9f158..c7608df4cc2685478c3343646bfa1ed1f957000f 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
@@ -762,6 +762,79 @@ static void test_ip_tos_sockopt(int fd)
 		xerror("expect socklen_t == -1");
 }
 
+static void test_so_max_pacing_rate(int fd)
+{
+	/* SO_MAX_PACING_RATE is a unsigned long value in bytes/sec. Validate basic
+	 * set/get semantics and a few edge cases for getsockopt() lengths.
+	 */
+	unsigned long in, out;
+	socklen_t s;
+	int r;
+
+	/* Try a few representative values, including 0 (unlimited),
+	 * small, medium and a large one.
+	 */
+	unsigned long tests[] = {
+	    0U,
+	    1U,
+	    10U * 1000U * 1000U, /* 10 MB/s */
+	    5U * 1024 * 1024 * 1024 /* 5 GB/s - tests that 64-bit unsigned long correctly works */
+	};
+
+	for (size_t i = 0; i < sizeof(tests) / sizeof(unsigned long); i++) {
+		in = tests[i];
+
+		r = setsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &in, sizeof(in));
+		if (r != 0) {
+			char *msg;
+			(void)asprintf(&msg, "setsockopt SO_MAX_PACING_RATE to %lu", in);
+			die_perror(msg);
+		}
+
+		out = ~in; /* poison */
+		s = sizeof(out);
+		r = getsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &out, &s);
+		if (r != 0) {
+			char *msg;
+			(void)asprintf(&msg, "getsockopt SO_MAX_PACING_RATE expected %lu", in);
+			die_perror(msg);
+		}
+
+		if (s != sizeof(out))
+			xerror("SO_MAX_PACING_RATE length %d != %zu", s, sizeof(out));
+
+		if (out != in)
+			xerror("SO_MAX_PACING_RATE %u != %u", out, in);
+
+		/* Query with zero-length buffer. Kernel should succeed and not write. */
+		s = 0;
+		r = getsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &out, &s);
+		if (r != 0)
+			die_perror("getsockopt SO_MAX_PACING_RATE len=0");
+		if (s != 0)
+			xerror("expect socklen_t == 0 for SO_MAX_PACING_RATE");
+
+		/* Query with negative length should fail with -EINVAL and leave s unchanged. */
+		s = -1;
+		r = getsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &out, &s);
+		if (r != -1 && errno != EINVAL)
+			die_perror("getsockopt SO_MAX_PACING_RATE did not indicate -EINVAL");
+		if (s != -1)
+			xerror("expect socklen_t == -1 for SO_MAX_PACING_RATE");
+	}
+
+	/* Invalid set: zero length should fail. */
+	in = 1234U;
+	r = setsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &in, 0);
+	if (r != -1 && errno != EINVAL)
+		die_perror("setsockopt SO_MAX_PACING_RATE len=0 did not indicate -EINVAL");
+
+	/* Invalid set: too short length should fail. */
+	r = setsockopt(fd, SOL_SOCKET, SO_MAX_PACING_RATE, &in, 1);
+	if (r != -1 && errno != EINVAL)
+		die_perror("setsockopt SO_MAX_PACING_RATE short len did not indicate -EINVAL");
+}
+
 static int client(int pipefd)
 {
 	int fd = -1;
@@ -780,6 +853,7 @@ static int client(int pipefd)
 	}
 
 	test_ip_tos_sockopt(fd);
+	test_so_max_pacing_rate(fd);
 
 	connect_one_server(fd, pipefd);
 

-- 
2.50.1

