From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Date: Mon, 09 Jun 2025 15:27:01 +0200
Subject: [PATCH bpf-next v2 4/5] selftests/bpf: sockmap: Allow SK_PASS in
 verdict
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-sockmap-splice-v2-4-9c50645cfa32@datadoghq.com>
References: <20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com>
In-Reply-To: <20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: Kuniyuki Iwashima <kuniyu@amazon.com>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749475632; l=2649;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=ttXkzBtePefhL92l8qDuBVl8NcBEWEyezoI06KE7GQg=;
 b=/mT4P4ZWbZCQSLeySFp0UlmZ4Jy852XVvbwDQyMD61nJGBVFgqRb5PhdkS2eBmMaZDTp3IGnN
 7VrH9pEkKYkDGkoqSVqJ5pwhhSF/vUZcyYQIo8N4/SMBLn7J6/MZJG6
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an option to always return SK_PASS in the verdict callback
instead of redirecting the skb.  This allows testing cases
which are not covered by the test program as of now.

Signed-off-by: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
---
 tools/testing/selftests/bpf/test_sockmap.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/test_sockmap.c b/tools/testing/selftests/bpf/test_sockmap.c
index cf1c36ed32c1..8be2714dd573 100644
--- a/tools/testing/selftests/bpf/test_sockmap.c
+++ b/tools/testing/selftests/bpf/test_sockmap.c
@@ -80,6 +80,7 @@ int txmsg_end_push;
 int txmsg_start_pop;
 int txmsg_pop;
 int txmsg_ingress;
+int txmsg_pass_skb;
 int txmsg_redir_skb;
 int txmsg_ktls_skb;
 int txmsg_ktls_skb_drop;
@@ -114,6 +115,7 @@ static const struct option long_options[] = {
 	{"txmsg_start_pop",  required_argument,	NULL, 'w'},
 	{"txmsg_pop",	     required_argument,	NULL, 'x'},
 	{"txmsg_ingress", no_argument,		&txmsg_ingress, 1 },
+	{"txmsg_pass_skb", no_argument,		&txmsg_pass_skb, 1 },
 	{"txmsg_redir_skb", no_argument,	&txmsg_redir_skb, 1 },
 	{"ktls", no_argument,			&ktls, 1 },
 	{"peek", no_argument,			&peek_flag, 1 },
@@ -183,6 +185,7 @@ static void test_reset(void)
 	txmsg_pass = txmsg_drop = txmsg_redir = 0;
 	txmsg_apply = txmsg_cork = 0;
 	txmsg_ingress = txmsg_redir_skb = 0;
+	txmsg_pass_skb = 0;
 	txmsg_ktls_skb = txmsg_ktls_skb_drop = txmsg_ktls_skb_redir = 0;
 	txmsg_omit_skb_parser = 0;
 	skb_use_parser = 0;
@@ -1050,6 +1053,7 @@ static int run_options(struct sockmap_options *options, int cg_fd,  int test)
 {
 	int i, key, next_key, err, zero = 0;
 	struct bpf_program *tx_prog;
+	struct bpf_program *skb_verdict_prog;
 
 	/* If base test skip BPF setup */
 	if (test == BASE || test == BASE_SENDPAGE)
@@ -1066,7 +1070,12 @@ static int run_options(struct sockmap_options *options, int cg_fd,  int test)
 		}
 	}
 
-	links[1] = bpf_program__attach_sockmap(progs[1], map_fd[0]);
+	if (txmsg_pass_skb)
+		skb_verdict_prog = progs[2];
+	else
+		skb_verdict_prog = progs[1];
+
+	links[1] = bpf_program__attach_sockmap(skb_verdict_prog, map_fd[0]);
 	if (!links[1]) {
 		fprintf(stderr, "ERROR: bpf_program__attach_sockmap (sockmap): (%s)\n",
 			strerror(errno));
@@ -1455,6 +1464,8 @@ static void test_options(char *options)
 	}
 	if (txmsg_ingress)
 		append_str(options, "ingress,", OPTSTRING);
+	if (txmsg_pass_skb)
+		append_str(options, "pass_skb,", OPTSTRING);
 	if (txmsg_redir_skb)
 		append_str(options, "redir_skb,", OPTSTRING);
 	if (txmsg_ktls_skb)

-- 
2.34.1

