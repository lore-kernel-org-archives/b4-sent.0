From: Bochao Cao <bochaolucky@gmail.com>
Date: Sat, 10 Oct 2026 18:22:45 +0800
Subject: [PATCH net-next v5 1/5] selftests/bpf: Fix XDP feature test setup
 and teardown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-xdp-v5-send-20261008-v5-1-de687cb67c40@gmail.com>
References: <20261010-xdp-v5-send-20261008-v5-0-de687cb67c40@gmail.com>
In-Reply-To: <20261010-xdp-v5-send-20261008-v5-0-de687cb67c40@gmail.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, netdev@vger.kernel.org, 
 =?utf-8?q?Alexis_Lothor=C3=A9?= <alexis.lothore@bootlin.com>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Tiezhu Yang <tiozhang@didiglobal.com>, Bochao Cao <bochaolucky@gmail.com>, 
 Willem de Bruijn <willemdebruijn.kernel@gmail.com>, 
 Petr Machata <petrm@nvidia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627780; l=4510;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=TxgDD4VtYgKtx3oL9L3R6Oupn/bciAnEZltJtmyK9u0=;
 b=+E+eqTM/axFJ+1bt18PgVjA6zzwJIPFh/0neWWwZ7WxUmTCDjnghNRdxXSS6YsIz9v/pYQQ04
 N4GjPODPjTIAhVy5ZxQE7vN+GNmsDR4dZ+WDwititlxLR0hkpvuf9u2
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initialize the DUT state and socket address lengths. Return the echo
socket fd to the caller, close it in the worker, and join the worker only
if it was started. Stop the worker on error paths.

Read tester counters before stopping the DUT. The echo sent during
teardown can otherwise make XDP_DROP report a false failure.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/xdp_features.c | 36 ++++++++++++++++++------------
 1 file changed, 22 insertions(+), 14 deletions(-)

diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/bpf/xdp_features.c
index a27ed663967c4..5b802b14d8589 100644
--- a/tools/testing/selftests/bpf/xdp_features.c
+++ b/tools/testing/selftests/bpf/xdp_features.c
@@ -227,51 +227,53 @@ static void *dut_echo_thread(void *arg)
 	int sockfd = *(int *)arg;
 
 	while (!exiting) {
 		struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
 		struct sockaddr_storage addr;
-		socklen_t addrlen;
-		size_t n;
+		socklen_t addrlen = sizeof(addr);
+		ssize_t n;
 
 		n = recvfrom(sockfd, buf, sizeof(buf), MSG_WAITALL,
 			     (struct sockaddr *)&addr, &addrlen);
-		if (n != ntohs(tlv->len))
+		if (n != sizeof(*tlv) || n != ntohs(tlv->len))
 			continue;
 
 		if (ntohs(tlv->type) != CMD_ECHO)
 			continue;
 
 		sendto(sockfd, buf, sizeof(buf), MSG_NOSIGNAL | MSG_CONFIRM,
 		       (struct sockaddr *)&addr, addrlen);
 	}
 
-	pthread_exit((void *)0);
 	close(sockfd);
 
 	return NULL;
 }
 
 static int dut_run_echo_thread(pthread_t *t, int *sockfd)
 {
-	int err;
+	int *fds, err;
 
-	sockfd = start_reuseport_server(AF_INET6, SOCK_DGRAM, NULL,
+	fds = start_reuseport_server(AF_INET6, SOCK_DGRAM, NULL,
 					DUT_ECHO_PORT, 0, 1);
-	if (!sockfd) {
+	if (!fds) {
 		fprintf(stderr,
 			"Failed creating data UDP socket on device %s\n",
 			env.ifname);
 		return -errno;
 	}
 
+	*sockfd = *fds;
+	free(fds);
+
 	/* start echo channel */
 	err = pthread_create(t, NULL, dut_echo_thread, sockfd);
 	if (err) {
 		fprintf(stderr,
 			"Failed creating data UDP thread on device %s: %s\n",
-			env.ifname, strerror(-err));
-		free_fds(sockfd, 1);
+			env.ifname, strerror(err));
+		close(*sockfd);
 		return -EINVAL;
 	}
 
 	return 0;
 }
@@ -359,14 +361,15 @@ static int recv_msg(int sockfd, void *buf, size_t bufsize, void *val,
 }
 
 static int dut_run(struct xdp_features *skel)
 {
 	int flags = XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE;
-	int state, err = 0, *sockfd, ctrl_sockfd, echo_sockfd;
+	int state = CMD_STOP, err = 0, *sockfd, ctrl_sockfd, echo_sockfd;
 	struct sockaddr_storage ctrl_addr;
-	pthread_t dut_thread = 0;
-	socklen_t addrlen;
+	pthread_t dut_thread;
+	bool thread_started = false;
+	socklen_t addrlen = sizeof(ctrl_addr);
 
 	sockfd = start_reuseport_server(AF_INET6, SOCK_STREAM, NULL,
 					DUT_CTRL_PORT, 0, 1);
 	if (!sockfd) {
 		fprintf(stderr,
@@ -404,10 +407,11 @@ static int dut_run(struct xdp_features *skel)
 				goto out;
 
 			err = dut_run_echo_thread(&dut_thread, &echo_sockfd);
 			if (err < 0)
 				goto out;
+			thread_started = true;
 
 			tlv->type = htons(CMD_ACK);
 			tlv->len = htons(sizeof(*tlv));
 			err = send(ctrl_sockfd, buf, sizeof(*tlv), 0);
 			if (err < 0)
@@ -482,11 +486,13 @@ static int dut_run(struct xdp_features *skel)
 			break;
 		}
 	}
 
 end_thread:
-	pthread_join(dut_thread, NULL);
+	exiting = true;
+	if (thread_started)
+		pthread_join(dut_thread, NULL);
 out:
 	bpf_xdp_detach(env.ifindex, flags, NULL);
 	close(ctrl_sockfd);
 	free_fds(sockfd, 1);
 
@@ -634,16 +640,18 @@ static int tester_run(struct xdp_features *skel)
 
 	err = send_and_recv_msg(sockfd, CMD_GET_STATS, &stats, sizeof(stats));
 	if (err)
 		goto out;
 
+	/* Sample before teardown can produce additional echo traffic. */
+	detected_cap = tester_collect_detected_cap(skel, ntohl(stats));
+
 	/* stop the test */
 	err = send_and_recv_msg(sockfd, CMD_STOP, NULL, 0);
 	/* send a new echo message to wake echo thread of the dut */
 	send_echo_msg();
 
-	detected_cap = tester_collect_detected_cap(skel, ntohl(stats));
 
 	fprintf(stdout, "Feature %s: [%s][%s]\n", get_xdp_feature_str(),
 		detected_cap ? GREEN("DETECTED") : RED("NOT DETECTED"),
 		env.feature.drv_feature & advertised_feature ? GREEN("ADVERTISED")
 							     : RED("NOT ADVERTISED"));

-- 
Git-155)

