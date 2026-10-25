From: Eli Skeggs <kernel@eliskeggs.com>
Date: Sun, 25 Oct 2026 16:41:58 -0700
Subject: [PATCH bpf 2/2] selftests/bpf: Redirect a bare FIN to another
 socket's egress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-sockmap-bare-fin-v1-2-bb8feae7c4a7@eliskeggs.com>
References: <20261025-sockmap-bare-fin-v1-0-bb8feae7c4a7@eliskeggs.com>
In-Reply-To: <20261025-sockmap-bare-fin-v1-0-bb8feae7c4a7@eliskeggs.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Cong Wang <cong.wang@bytedance.com>, 
 Daniel Borkmann <daniel@iogearbox.net>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: Geliang Tang <geliang@kernel.org>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Eli Skeggs <kernel@eliskeggs.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792971941; l=4880;
 i=kernel@eliskeggs.com; s=20261021; h=from:subject:message-id;
 bh=4le5YBHhX3XoOuXEtcw57i6wiQvbpdg4GyDHi4mqUR4=;
 b=BZlc7bOp4bZPIb1hWZMCebUp1rGvnBTGlTSBaXqnLzp3+B+yJygeG2w0oeCh/cHy71ZESi2Rq
 M1dy0JoM6g5BmBJQCDhfWz3GEwTDar2pWL3vesnmicUiNV1/sKXnlq/
X-Developer-Key: i=kernel@eliskeggs.com; a=ed25519;
 pk=38k+FqQ3STTnr2H4HZ7IEseBOHWRDYVhvyMmQlB51gc=
X-Endpoint-Received: by B4 Relay for kernel@eliskeggs.com/20261021 with auth_id=1252
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Redirect data from two sockets to a third socket's egress. Half-close
the first socket so that its FIN arrives in an skb of its own, then
confirm that data redirected from the second socket after the first
socket's half-close still egresses from the third socket, and that
the third socket reports no error.

Without the sk_psock_backlog() fix, the zero-length skb breaks the
target's psock: it ends up with a disabled transmit flag, and SO_ERROR
reports EPIPE.

Signed-off-by: Eli Skeggs <kernel@eliskeggs.com>
---
 .../selftests/bpf/prog_tests/sockmap_basic.c       | 74 ++++++++++++++++++++++
 .../selftests/bpf/progs/test_sockmap_pass_prog.c   |  8 +++
 2 files changed, 82 insertions(+)

diff --git a/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c b/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
index 1fef6ec2ba7a..e1e477ce72b3 100644
--- a/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
+++ b/tools/testing/selftests/bpf/prog_tests/sockmap_basic.c
@@ -1325,6 +1325,78 @@ static void test_sockmap_multi_channels(int sotype)
 	test_sockmap_pass_prog__destroy(skel);
 }
 
+/* A bare FIN turns into an empty skb. When redirected to another socket,
+ * verify that it does not break the destination socket's psock. Data
+ * later redirected to the destination socket must still transmit.
+ */
+static void test_sockmap_skb_verdict_redir_fin(void)
+{
+	int c0 = -1, p0 = -1, c1 = -1, p1 = -1, c2 = -1, p2 = -1;
+	int err, map, zero = 0, one = 1, two = 2, sock_err;
+	struct test_sockmap_pass_prog *skel;
+	socklen_t len = sizeof(sock_err);
+	struct bpf_program *prog;
+	char buf = 'x', rcv;
+
+	skel = test_sockmap_pass_prog__open_and_load();
+	if (!ASSERT_OK_PTR(skel, "open_and_load"))
+		return;
+
+	err = create_socket_pairs(AF_INET, SOCK_STREAM, &c0, &c1, &p0, &p1);
+	if (!ASSERT_OK(err, "create_socket_pairs()"))
+		goto end;
+	err = create_pair(AF_INET, SOCK_STREAM, &c2, &p2);
+	if (!ASSERT_OK(err, "create_pair()"))
+		goto end;
+
+	map = bpf_map__fd(skel->maps.sock_map_rx);
+	prog = skel->progs.prog_skb_verdict_egress;
+	err = bpf_prog_attach(bpf_program__fd(prog), map,
+			      BPF_SK_SKB_STREAM_VERDICT, 0);
+	if (!ASSERT_OK(err, "bpf_prog_attach verdict"))
+		goto end;
+
+	err = bpf_map_update_elem(map, &zero, &p0, BPF_ANY);
+	if (!ASSERT_OK(err, "bpf_map_update_elem(p0)"))
+		goto end;
+	err = bpf_map_update_elem(map, &one, &p1, BPF_ANY);
+	if (!ASSERT_OK(err, "bpf_map_update_elem(p1)"))
+		goto end;
+	err = bpf_map_update_elem(map, &two, &p2, BPF_ANY);
+	if (!ASSERT_OK(err, "bpf_map_update_elem(p2)"))
+		goto end;
+
+	if (!ASSERT_EQ(xsend(c0, &buf, 1, 0), 1, "xsend(c0)"))
+		goto end;
+	if (!ASSERT_EQ(recv_timeout(c1, &rcv, 1, 0, IO_TIMEOUT_SEC), 1,
+		       "recv_timeout(c1)"))
+		goto end;
+
+	err = shutdown(c0, SHUT_WR);
+	if (!ASSERT_OK(err, "shutdown(c0)"))
+		goto end;
+	if (!ASSERT_OK(recv_timeout(p0, &rcv, 1, 0, IO_TIMEOUT_SEC),
+		       "recv_timeout(p0) EOF"))
+		goto end;
+
+	if (!ASSERT_EQ(xsend(c2, &buf, 1, 0), 1, "xsend(c2)"))
+		goto end;
+	ASSERT_EQ(recv_timeout(c1, &rcv, 1, 0, IO_TIMEOUT_SEC), 1,
+		  "recv_timeout(c1) after FIN");
+
+	err = getsockopt(p1, SOL_SOCKET, SO_ERROR, &sock_err, &len);
+	if (ASSERT_OK(err, "getsockopt(SO_ERROR)"))
+		ASSERT_OK(sock_err, "p1 error");
+end:
+	close_fd(&c0);
+	close_fd(&p0);
+	close_fd(&c1);
+	close_fd(&p1);
+	close_fd(&c2);
+	close_fd(&p2);
+	test_sockmap_pass_prog__destroy(skel);
+}
+
 /* A socket in a sockmap without a verdict program keeps its ingress data
  * in sk_receive_queue: FIONREAD must account for it.
  */
@@ -1404,6 +1476,8 @@ void test_sockmap_basic(void)
 		test_sockmap_no_verdict_fionread();
 	if (test__start_subtest("sockmap skb_verdict fionread on drop"))
 		test_sockmap_skb_verdict_fionread(false);
+	if (test__start_subtest("sockmap skb_verdict redirect bare FIN"))
+		test_sockmap_skb_verdict_redir_fin();
 	if (test__start_subtest("sockmap skb_verdict change tail"))
 		test_sockmap_skb_verdict_change_tail();
 	if (test__start_subtest("sockmap msg_verdict pop_data overflow"))
diff --git a/tools/testing/selftests/bpf/progs/test_sockmap_pass_prog.c b/tools/testing/selftests/bpf/progs/test_sockmap_pass_prog.c
index ef9edca184ea..dd3cb7524e21 100644
--- a/tools/testing/selftests/bpf/progs/test_sockmap_pass_prog.c
+++ b/tools/testing/selftests/bpf/progs/test_sockmap_pass_prog.c
@@ -52,6 +52,14 @@ int prog_skb_verdict_ingress(struct __sk_buff *skb)
 	return bpf_sk_redirect_map(skb, &sock_map_rx, one, BPF_F_INGRESS);
 }
 
+SEC("sk_skb/stream_verdict")
+int prog_skb_verdict_egress(struct __sk_buff *skb)
+{
+	int one = 1;
+
+	return bpf_sk_redirect_map(skb, &sock_map_rx, one, 0);
+}
+
 SEC("sk_skb/stream_parser")
 int prog_skb_verdict_ingress_strp(struct __sk_buff *skb)
 {

-- 
2.56.0

