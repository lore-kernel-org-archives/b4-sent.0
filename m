From: Mattia Meleleo <mattia.meleleo@coralogix.com>
Date: Tue, 07 Jul 2026 18:15:53 +0200
Subject: [PATCH bpf] bpf, sockmap: Account for receive queue in FIONREAD
 without a verdict program
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-fionread-no-verdict-v1-1-ce94a72357ec@coralogix.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFr1L+2oFYpDFeRVykyYyOi7RMahFK7
 27U5fv89zZUNuWKS7fBeNWqU2lwPHRIj1juTJobo3f94LzzJO1gHDOViVa2rGmheJLzEHxMQQK
 aORuLvn/VK8ZZcPuP9TU+OS3fHvb9A1FPRcB8AAAA
X-Change-ID: 20260707-fionread-no-verdict-a4f8697ac9f9
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Mattia Meleleo <mattia.meleleo@coralogix.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783440961; l=4235;
 i=mattia.meleleo@coralogix.com; s=20260707; h=from:subject:message-id;
 bh=aFZBdyJoJSWVLETQmNXpLi70lCPgP+Z+qtlX8undb2c=;
 b=7VzhVRcI4/wPM/f39bOT4hg4dp0xF2Z8AKpWg83TJEmeLzjJFJza9F4yZ6pZbB3P+255nqEOT
 GZkJLvRwBfPACWBpY6Y2OPq6iQK3ApXuROFw7E7Tyl6Sm9rg2mwEGfD
X-Developer-Key: i=mattia.meleleo@coralogix.com; a=ed25519;
 pk=cs1zLoe3YDm4bJ7bfbPaZH0lHnd871JyJLiSh2eEzLs=
X-Endpoint-Received: by B4 Relay for mattia.meleleo@coralogix.com/20260707 with auth_id=857
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcp_bpf_ioctl() answers SIOCINQ from psock->msg_tot_len, which only
counts bytes in ingress_msg. Without a stream/skb verdict program
nothing is diverted there: data stays in sk_receive_queue, so FIONREAD
returns 0 even though read() returns data.

Add tcp_inq() to the reported value when the psock has no verdict
program. The two queues are disjoint, so bytes redirected into
ingress_msg from other sockets stay correctly accounted through
msg_tot_len.

Add a selftest covering FIONREAD without a verdict program.

Fixes: 929e30f93125 ("bpf, sockmap: Fix FIONREAD for sockmap")
Signed-off-by: Mattia Meleleo <mattia.meleleo@coralogix.com>
---
 net/ipv4/tcp_bpf.c                                 | 16 ++++++++-
 .../selftests/bpf/prog_tests/sockmap_basic.c       | 39 ++++++++++++++++++++++
 2 files changed, 54 insertions(+), 1 deletion(-)

diff --git a/net/ipv4/tcp_bpf.c b/net/ipv4/tcp_bpf.c
index cc0bd73f3..a001b1fff 100644
--- a/net/ipv4/tcp_bpf.c
+++ b/net/ipv4/tcp_bpf.c
@@ -334,6 +334,7 @@ static int tcp_bpf_recvmsg_parser(struct sock *sk,
 
 static int tcp_bpf_ioctl(struct sock *sk, int cmd, int *karg)
 {
+	struct sk_psock *psock;
 	bool slow;
 
 	if (cmd != SIOCINQ)
@@ -344,7 +345,20 @@ static int tcp_bpf_ioctl(struct sock *sk, int cmd, int *karg)
 		return -EINVAL;
 
 	slow = lock_sock_fast(sk);
-	*karg = sk_psock_msg_inq(sk);
+	psock = sk_psock_get(sk);
+	if (unlikely(!psock)) {
+		unlock_sock_fast(sk, slow);
+		return tcp_ioctl(sk, cmd, karg);
+	}
+	*karg = sk_psock_get_msg_len_nolock(psock);
+	/* Without a verdict program, ingress data is never diverted to
+	 * ingress_msg: it stays in sk_receive_queue and is read through
+	 * the fallback to tcp_recvmsg(), so account for it like
+	 * tcp_ioctl() does.
+	 */
+	if (!psock->progs.stream_verdict && !psock->progs.skb_verdict)
+		*karg += tcp_inq(sk);
+	sk_psock_put(sk, psock);
 	unlock_sock_fast(sk, slow);
 
 	return 0;
diff --git a/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c b/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
index cb3229711..f0f368201 100644
--- a/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
+++ b/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
@@ -1373,6 +1373,43 @@ static void test_sockmap_multi_channels(int sotype)
 	test_sockmap_pass_prog__destroy(skel);
 }
 
+/* A socket in a sockmap without a verdict program keeps its ingress data
+ * in sk_receive_queue: FIONREAD must account for it.
+ */
+static void test_sockmap_no_verdict_fionread(void)
+{
+	int err, map, zero = 0, sent, avail;
+	int c0 = -1, c1 = -1, p0 = -1, p1 = -1;
+	struct test_sockmap_pass_prog *skel;
+	char buf[256] = "0123456789";
+
+	skel = test_sockmap_pass_prog__open_and_load();
+	if (!ASSERT_OK_PTR(skel, "open_and_load"))
+		return;
+	map = bpf_map__fd(skel->maps.sock_map_rx);
+
+	err = create_socket_pairs(AF_INET, SOCK_STREAM, &c0, &c1, &p0, &p1);
+	if (!ASSERT_OK(err, "create_socket_pairs()"))
+		goto out;
+
+	err = bpf_map_update_elem(map, &zero, &c1, BPF_NOEXIST);
+	if (!ASSERT_OK(err, "bpf_map_update_elem(c1)"))
+		goto out_close;
+
+	sent = xsend(p1, &buf, sizeof(buf), 0);
+	ASSERT_EQ(sent, sizeof(buf), "xsend(p1)");
+	avail = wait_for_fionread(c1, sizeof(buf), IO_TIMEOUT_SEC);
+	ASSERT_EQ(avail, sizeof(buf), "ioctl(FIONREAD)");
+
+out_close:
+	close(c0);
+	close(p0);
+	close(c1);
+	close(p1);
+out:
+	test_sockmap_pass_prog__destroy(skel);
+}
+
 void test_sockmap_basic(void)
 {
 	if (test__start_subtest("sockmap create_update_free"))
@@ -1415,6 +1452,8 @@ void test_sockmap_basic(void)
 		test_sockmap_skb_verdict_shutdown();
 	if (test__start_subtest("sockmap skb_verdict fionread"))
 		test_sockmap_skb_verdict_fionread(true);
+	if (test__start_subtest("sockmap no_verdict fionread"))
+		test_sockmap_no_verdict_fionread();
 	if (test__start_subtest("sockmap skb_verdict fionread on drop"))
 		test_sockmap_skb_verdict_fionread(false);
 	if (test__start_subtest("sockmap skb_verdict change tail"))

---
base-commit: d2c9a99135da931377240942d44f3dea104cedb8
change-id: 20260707-fionread-no-verdict-a4f8697ac9f9

Best regards,
--  
Mattia Meleleo <mattia.meleleo@coralogix.com>

