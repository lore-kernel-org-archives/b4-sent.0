From: Bochao Cao <bochaolucky@gmail.com>
Date: Sun, 18 Oct 2026 22:05:50 +0800
Subject: [PATCH net-next v6 1/5] selftests/bpf: Fix XDP feature test setup
 and teardown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-xdp-v5-send-20261008-v6-1-7336e1282ca3@gmail.com>
References: <20261018-xdp-v5-send-20261008-v6-0-7336e1282ca3@gmail.com>
In-Reply-To: <20261018-xdp-v5-send-20261008-v6-0-7336e1282ca3@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792332371; l=7300;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=tAY5Dk94/tGfujPcJ1sdQ5gyMHxW5FgaNjIP1qFRz34=;
 b=V1wKNH5PA2VZ75IKLMWS5UQ8OaKm3/p3JACfPW5BzaYvp2FOmGGu6T1AWSOaUviCuVvB1rlXk
 JH1VQOELfvSC9Q+gO2uPqD24bvXz3n/l+Ixtexx56gaQFN4rqfKFLbu
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initialize the DUT state and socket address lengths. Return the echo
socket to the caller and join the worker only after it starts. Stop the
worker on control EOF and other errors.

Read tester counters before teardown, which can produce extra echo
traffic. Detach only after a successful attach so a failed test
preserves an existing XDP program.

Tested on Ubuntu 6.8 with gcc. DUT and tester attach failures both
preserve the existing program ID.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/xdp_features.c | 63 ++++++++++++++++++++----------
 1 file changed, 42 insertions(+), 21 deletions(-)

diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/bpf/xdp_features.c
index a27ed663967c4..3076fdda61fa4 100644
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
@@ -339,14 +341,18 @@ static int dut_attach_xdp_prog(struct xdp_features *skel, int flags)
 
 static int recv_msg(int sockfd, void *buf, size_t bufsize, void *val,
 		    size_t val_size)
 {
 	struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
-	size_t len;
+	ssize_t len;
 
 	len = recv(sockfd, buf, bufsize, 0);
-	if (len != ntohs(tlv->len) || len < sizeof(*tlv))
+	if (len < 0)
+		return -errno;
+	if (!len)
+		return -ECONNRESET;
+	if (len < sizeof(*tlv) || len != ntohs(tlv->len))
 		return -EINVAL;
 
 	if (val) {
 		len -= sizeof(*tlv);
 		if (len > val_size)
@@ -359,14 +365,15 @@ static int recv_msg(int sockfd, void *buf, size_t bufsize, void *val,
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
+	bool thread_started = false, xdp_attached = false;
+	socklen_t addrlen = sizeof(ctrl_addr);
 
 	sockfd = start_reuseport_server(AF_INET6, SOCK_STREAM, NULL,
 					DUT_CTRL_PORT, 0, 1);
 	if (!sockfd) {
 		fprintf(stderr,
@@ -387,12 +394,14 @@ static int dut_run(struct xdp_features *skel)
 	while (!exiting) {
 		unsigned char buf[BUFSIZE] = {};
 		struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
 
 		err = recv_msg(ctrl_sockfd, buf, BUFSIZE, NULL, 0);
-		if (err)
+		if (err == -EAGAIN || err == -EINTR)
 			continue;
+		if (err)
+			goto end_thread;
 
 		switch (ntohs(tlv->type)) {
 		case CMD_START: {
 			if (state == CMD_START)
 				continue;
@@ -401,13 +410,16 @@ static int dut_run(struct xdp_features *skel)
 			/* Load the XDP program on the DUT */
 			err = dut_attach_xdp_prog(skel, flags);
 			if (err)
 				goto out;
 
+			xdp_attached = true;
+
 			err = dut_run_echo_thread(&dut_thread, &echo_sockfd);
 			if (err < 0)
 				goto out;
+			thread_started = true;
 
 			tlv->type = htons(CMD_ACK);
 			tlv->len = htons(sizeof(*tlv));
 			err = send(ctrl_sockfd, buf, sizeof(*tlv), 0);
 			if (err < 0)
@@ -420,10 +432,11 @@ static int dut_run(struct xdp_features *skel)
 
 			state = CMD_STOP;
 
 			exiting = true;
 			bpf_xdp_detach(env.ifindex, flags, NULL);
+			xdp_attached = false;
 
 			tlv->type = htons(CMD_ACK);
 			tlv->len = htons(sizeof(*tlv));
 			err = send(ctrl_sockfd, buf, sizeof(*tlv), 0);
 			goto end_thread;
@@ -482,13 +495,18 @@ static int dut_run(struct xdp_features *skel)
 			break;
 		}
 	}
 
 end_thread:
-	pthread_join(dut_thread, NULL);
+	exiting = true;
+	if (thread_started) {
+		shutdown(echo_sockfd, SHUT_RDWR);
+		pthread_join(dut_thread, NULL);
+	}
 out:
-	bpf_xdp_detach(env.ifindex, flags, NULL);
+	if (xdp_attached)
+		bpf_xdp_detach(env.ifindex, flags, NULL);
 	close(ctrl_sockfd);
 	free_fds(sockfd, 1);
 
 	return err;
 }
@@ -576,11 +594,11 @@ static int tester_run(struct xdp_features *skel)
 	int flags = XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE;
 	unsigned long long advertised_feature;
 	struct bpf_program *prog;
 	unsigned int stats;
 	int i, err, sockfd;
-	bool detected_cap;
+	bool detected_cap, xdp_attached = false;
 
 	sockfd = socket(AF_INET6, SOCK_STREAM, 0);
 	if (sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating tester service control socket\n");
@@ -618,10 +636,11 @@ static int tester_run(struct xdp_features *skel)
 		fprintf(stderr, "Failed attaching XDP program to device %s\n",
 			env.ifname);
 		goto out;
 	}
 
+	xdp_attached = true;
 	err = send_and_recv_msg(sockfd, CMD_START, NULL, 0);
 	if (err)
 		goto out;
 
 	for (i = 0; i < 10 && !exiting; i++) {
@@ -634,23 +653,25 @@ static int tester_run(struct xdp_features *skel)
 
 	err = send_and_recv_msg(sockfd, CMD_GET_STATS, &stats, sizeof(stats));
 	if (err)
 		goto out;
 
+	/* Sample before teardown, which can produce additional echo traffic. */
+	detected_cap = tester_collect_detected_cap(skel, ntohl(stats));
+
 	/* stop the test */
 	err = send_and_recv_msg(sockfd, CMD_STOP, NULL, 0);
 	/* send a new echo message to wake echo thread of the dut */
 	send_echo_msg();
 
-	detected_cap = tester_collect_detected_cap(skel, ntohl(stats));
-
 	fprintf(stdout, "Feature %s: [%s][%s]\n", get_xdp_feature_str(),
 		detected_cap ? GREEN("DETECTED") : RED("NOT DETECTED"),
 		env.feature.drv_feature & advertised_feature ? GREEN("ADVERTISED")
 							     : RED("NOT ADVERTISED"));
 out:
-	bpf_xdp_detach(env.ifindex, flags, NULL);
+	if (xdp_attached)
+		bpf_xdp_detach(env.ifindex, flags, NULL);
 	close(sockfd);
 	return err < 0 ? err : 0;
 }
 
 int main(int argc, char **argv)

-- 
Git-155)

