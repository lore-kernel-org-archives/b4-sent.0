From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Date: Thu, 06 Jun 2024 11:27:56 +0200
Subject: [PATCH bpf-next 5/5] selftests/bpf: sockmap: Add basic splice(2)
 mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-sockmap-splice-v1-5-4820a2ab14b5@datadoghq.com>
References: <20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com>
In-Reply-To: <20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717666080; l=2849;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=qELVPIBlr9FpIjNgB+sL7xYA/TV1+f+XF9UJjqd3aMg=;
 b=ggN8lIeM5Plq+xrdoFVFgz3/EOKmVgaXdBF6crk8pcfSEFnlpkOVPB4YTad1KnUptDRtnS0wG
 wsG7QYpib2jAZ7sn2EUnsC7Cy8BUfeGv8mnenVH8K9uPCjlPjvhcRBb
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test mode which uses splice(2) to do a read from the
socket.  Can be run with something like the below:

 ./test_sockmap -t splice --txmsg_omit_skb_parser --txmsg_pass_skb

Signed-off-by: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
---
 tools/testing/selftests/bpf/test_sockmap.c | 61 ++++++++++++++++++++++++++++++
 1 file changed, 61 insertions(+)

diff --git a/tools/testing/selftests/bpf/test_sockmap.c b/tools/testing/selftests/bpf/test_sockmap.c
index 8d72901aa314..5be29ccb3323 100644
--- a/tools/testing/selftests/bpf/test_sockmap.c
+++ b/tools/testing/selftests/bpf/test_sockmap.c
@@ -1,5 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 // Copyright (c) 2017-2018 Covalent IO, Inc. http://covalent.io
+#define _GNU_SOURCE
 #include <stdio.h>
 #include <stdlib.h>
 #include <sys/socket.h>
@@ -871,6 +872,61 @@ static int sendmsg_test(struct sockmap_options *opt)
 	return err;
 }
 
+static int splice_test(struct sockmap_options *opt)
+{
+	int pipefds[2];
+	char buf[1024] = {0};
+	ssize_t bytes;
+	int ret;
+
+	ret = pipe(pipefds);
+	if (ret < 0) {
+		perror("pipe");
+		return ret;
+	}
+
+	bytes = send(c1, buf, sizeof(buf), 0);
+	if (bytes < 0) {
+		perror("send failed");
+		return bytes;
+	}
+	if (bytes == 0) {
+		fprintf(stderr, "send wrote zero bytes\n");
+		return -1;
+	}
+
+	bytes = write(pipefds[1], buf, sizeof(buf));
+	if (bytes < 0) {
+		perror("pipe write failed");
+		return bytes;
+	}
+
+	bytes = splice(p1, NULL, pipefds[1], NULL, sizeof(buf), 0);
+	if (bytes < 0) {
+		perror("splice failed");
+		return bytes;
+	}
+	if (bytes == 0) {
+		fprintf(stderr, "spliced zero bytes\n");
+		return -1;
+	}
+
+	bytes = read(pipefds[0], buf, sizeof(buf));
+	if (bytes < 0) {
+		perror("pipe read failed");
+		return bytes;
+	}
+	if (bytes == 0) {
+		fprintf(stderr, "EOF from pipe\n");
+		return -1;
+	}
+
+	close(pipefds[1]);
+	close(pipefds[0]);
+
+	return 0;
+}
+
 static int forever_ping_pong(int rate, struct sockmap_options *opt)
 {
 	struct timeval timeout;
@@ -953,6 +1009,7 @@ enum {
 	BASE,
 	BASE_SENDPAGE,
 	SENDPAGE,
+	SPLICE,
 };
 
 static int run_options(struct sockmap_options *options, int cg_fd,  int test)
@@ -1284,6 +1341,8 @@ static int run_options(struct sockmap_options *options, int cg_fd,  int test)
 		options->base = true;
 		options->sendpage = true;
 		err = sendmsg_test(options);
+	} else if (test == SPLICE) {
+		err = splice_test(options);
 	} else
 		fprintf(stderr, "unknown test\n");
 out:
@@ -2028,6 +2087,8 @@ int main(int argc, char **argv)
 				test = BASE_SENDPAGE;
 			} else if (strcmp(optarg, "sendpage") == 0) {
 				test = SENDPAGE;
+			} else if (strcmp(optarg, "splice") == 0) {
+				test = SPLICE;
 			} else {
 				usage(argv);
 				return -1;

-- 
2.34.1

