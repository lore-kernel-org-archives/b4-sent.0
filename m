From: Bochao Cao <bochaolucky@gmail.com>
Date: Sat, 10 Oct 2026 18:22:47 +0800
Subject: [PATCH net-next v5 3/5] selftests/bpf: Send XDP feature probes
 with AF_PACKET
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-xdp-v5-send-20261008-v5-3-de687cb67c40@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627780; l=34159;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=WGWUAFI0AY2cQD65CD6vyq0htL6mqzTdtWDVKLbyu6g=;
 b=SnoLO/w2Nruv5rKbjQiW3zXr9YFXPne4TbIo8p4rRiCSa1f5csk+0bFD8uI3gI6NNyHHt4nd2
 8TMb1wrncNDChT+0PFZXz1SLpFdnUIPkUaa80Yr2uAzqwEl58ATUpdi
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Send probes and count replies with AF_PACKET so the tester needs no XDP
support. Build UDP checksums in software and filter replies by address,
port and echo header. Get the DUT MAC address over the control connection.

Use an XDP link on the DUT so process exit releases only the test's
attachment. Check control peers and message lengths, handle partial
transfers and EOF, and bound helper runtime.

Add a native-XDP query for the runner and drop the network_helpers
dependency. Skip veth XDP_TX in the shell test: it needs a peer XDP program
to flush the receive ring.

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/Makefile             |   6 +-
 tools/testing/selftests/bpf/progs/xdp_features.c |  42 +-
 tools/testing/selftests/bpf/test_xdp_features.sh |  10 +-
 tools/testing/selftests/bpf/xdp_features.c       | 612 ++++++++++++++++-------
 tools/testing/selftests/bpf/xdp_features.h       |   1 +
 5 files changed, 455 insertions(+), 216 deletions(-)

diff --git a/tools/testing/selftests/bpf/Makefile b/tools/testing/selftests/bpf/Makefile
index 93c707116fad0..883c92701b9f1 100644
--- a/tools/testing/selftests/bpf/Makefile
+++ b/tools/testing/selftests/bpf/Makefile
@@ -945,14 +945,12 @@ $(OUTPUT)/xdp_hw_metadata: xdp_hw_metadata.c xsk.c network_helpers.c \
 			   xsk.h network_helpers.h test_progs.h bpf_util.h \
 			   $(OUTPUT)/xdp_hw_metadata.skel.h $(BPFOBJ) | $(OUTPUT)
 	$(call msg,BINARY,,$@)
 	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
 
-$(OUTPUT)/xdp_features: xdp_features.c network_helpers.c xdp_features.h \
-			   network_helpers.h \
-			   test_progs.h bpf_util.h $(OUTPUT)/xdp_features.skel.h \
-			   $(BPFOBJ) | $(OUTPUT)
+$(OUTPUT)/xdp_features: xdp_features.c xdp_features.h \
+			   $(OUTPUT)/xdp_features.skel.h $(BPFOBJ) | $(OUTPUT)
 	$(call msg,BINARY,,$@)
 	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
 
 # Make sure we are able to include and link libbpf against c++.
 CXXFLAGS += $(CFLAGS)
diff --git a/tools/testing/selftests/bpf/progs/xdp_features.c b/tools/testing/selftests/bpf/progs/xdp_features.c
index 67424084a38a1..a3e01bb2b8020 100644
--- a/tools/testing/selftests/bpf/progs/xdp_features.c
+++ b/tools/testing/selftests/bpf/progs/xdp_features.c
@@ -28,17 +28,10 @@ struct xdp_cpumap_stats {
 	unsigned int redirect;
 	unsigned int pass;
 	unsigned int drop;
 };
 
-struct {
-	__uint(type, BPF_MAP_TYPE_ARRAY);
-	__type(key, __u32);
-	__type(value, __u32);
-	__uint(max_entries, 1);
-} stats SEC(".maps");
-
 struct {
 	__uint(type, BPF_MAP_TYPE_ARRAY);
 	__type(key, __u32);
 	__type(value, __u32);
 	__uint(max_entries, 1);
@@ -123,67 +116,46 @@ xdp_process_echo_packet(struct xdp_md *xdp, bool dut)
 	port = dut ? uh->dest : uh->source;
 	if (port != bpf_htons(DUT_ECHO_PORT))
 		return -EINVAL;
 
 	tlv = (struct tlv_hdr *)(uh + 1);
-	if (tlv + 1 > data_end)
+	if ((void *)(tlv + 1) > data_end)
 		return -EINVAL;
 
 	return bpf_htons(tlv->type) == CMD_ECHO ? 0 : -EINVAL;
 }
 
 static __always_inline int
-xdp_update_stats(struct xdp_md *xdp, bool tx, bool dut)
+xdp_update_stats(struct xdp_md *xdp)
 {
 	__u32 *val, key = 0;
 
-	if (xdp_process_echo_packet(xdp, tx))
+	if (xdp_process_echo_packet(xdp, true))
 		return -EINVAL;
 
-	if (dut)
-		val = bpf_map_lookup_elem(&dut_stats, &key);
-	else
-		val = bpf_map_lookup_elem(&stats, &key);
+	val = bpf_map_lookup_elem(&dut_stats, &key);
 
 	if (val)
 		__sync_add_and_fetch(val, 1);
 
 	return 0;
 }
 
-/* Tester */
-
-SEC("xdp")
-int xdp_tester_check_tx(struct xdp_md *xdp)
-{
-	xdp_update_stats(xdp, true, false);
-
-	return XDP_PASS;
-}
-
-SEC("xdp")
-int xdp_tester_check_rx(struct xdp_md *xdp)
-{
-	xdp_update_stats(xdp, false, false);
-
-	return XDP_PASS;
-}
-
 /* DUT */
 
 SEC("xdp")
 int xdp_do_pass(struct xdp_md *xdp)
 {
-	xdp_update_stats(xdp, true, true);
+	xdp_update_stats(xdp);
 
 	return XDP_PASS;
 }
 
 SEC("xdp")
 int xdp_do_drop(struct xdp_md *xdp)
 {
-	if (xdp_update_stats(xdp, true, true))
+	if (xdp_update_stats(xdp))
 		return XDP_PASS;
 
 	return XDP_DROP;
 }
 
@@ -201,11 +173,11 @@ int xdp_do_tx(struct xdp_md *xdp)
 {
 	void *data = (void *)(long)xdp->data;
 	struct ethhdr *eh = data;
 	__u8 tmp_mac[ETH_ALEN];
 
-	if (xdp_update_stats(xdp, true, true))
+	if (xdp_update_stats(xdp))
 		return XDP_PASS;
 
 	__builtin_memcpy(tmp_mac, eh->h_source, ETH_ALEN);
 	__builtin_memcpy(eh->h_source, eh->h_dest, ETH_ALEN);
 	__builtin_memcpy(eh->h_dest, tmp_mac, ETH_ALEN);
diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
index 7b96222b690a6..a28021ba74726 100755
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ b/tools/testing/selftests/bpf/test_xdp_features.sh
@@ -125,18 +125,12 @@ test_xdp_features() {
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
 	reap_dut_server
 
-	## XDP_TX
-	start_dut_server -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_TX \
-					   -D ::ffff:$V1_IP4 \
-					   -C ::ffff:$V1_IP4 \
-					   -T ::ffff:$V0_IP4 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
+	# veth only flushes XDP_TX to a peer with native XDP attached.
+	echo "SKIP: XDP_TX needs a peer native XDP program"
 
 	## XDP_REDIRECT
 	start_dut_server -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_REDIRECT \
 					   -D $V1_IP6 -C $V1_IP6 \
diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/bpf/xdp_features.c
index 5b802b14d8589..521c0e24a27ca 100644
--- a/tools/testing/selftests/bpf/xdp_features.c
+++ b/tools/testing/selftests/bpf/xdp_features.c
@@ -1,24 +1,36 @@
 // SPDX-License-Identifier: GPL-2.0
-#include <uapi/linux/bpf.h>
-#include <uapi/linux/netdev.h>
+#include <netinet/in.h>
+#include <linux/bpf.h>
+#include <linux/if_ether.h>
+#include <linux/if_packet.h>
+#include <linux/ip.h>
+#include <linux/ipv6.h>
+#include <linux/udp.h>
+#include <linux/netdev.h>
 #include <linux/if_link.h>
-#include <signal.h>
 #include <argp.h>
+#include <errno.h>
 #include <net/if.h>
+#include <pthread.h>
+#include <poll.h>
+#include <sys/ioctl.h>
+#include <time.h>
+#include <signal.h>
+#include <stdatomic.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
 #include <sys/socket.h>
-#include <netinet/in.h>
+#include <sys/time.h>
 #include <netinet/tcp.h>
 #include <unistd.h>
 #include <arpa/inet.h>
 #include <bpf/bpf.h>
 #include <bpf/libbpf.h>
-#include <pthread.h>
 
-#include <network_helpers.h>
-
-#include "bpf_util.h"
 #include "xdp_features.skel.h"
 #include "xdp_features.h"
 
 #define RED(str)	"\033[0;31m" str "\033[0m"
 #define GREEN(str)	"\033[0;32m" str "\033[0m"
@@ -27,10 +39,11 @@
 static struct env {
 	bool verbosity;
 	char ifname[IF_NAMESIZE];
 	int ifindex;
 	bool is_tester;
+	bool query_only;
 	struct {
 		enum netdev_xdp_act drv_feature;
 		enum xdp_action action;
 	} feature;
 	struct sockaddr_storage dut_ctrl_addr;
@@ -38,25 +51,86 @@ static struct env {
 	struct sockaddr_storage tester_addr;
 } env;
 
 #define BUFSIZE		128
 
-void test__fail(void) { /* for network_helpers.c */ }
+static int make_sockaddr(const char *addr_str, __u16 port,
+			 struct sockaddr_storage *addr)
+{
+	struct sockaddr_in6 *sin6 = (void *)addr;
+
+	memset(addr, 0, sizeof(*addr));
+	sin6->sin6_family = AF_INET6;
+	sin6->sin6_port = htons(port);
+	if (addr_str && inet_pton(AF_INET6, addr_str, &sin6->sin6_addr) != 1)
+		return -1;
+
+	return 0;
+}
+
+static int settimeo(int fd, int timeout_ms)
+{
+	struct timeval timeout = { .tv_sec = 3 };
+
+	if (timeout_ms > 0) {
+		timeout.tv_sec = timeout_ms / 1000;
+		timeout.tv_usec = (timeout_ms % 1000) * 1000;
+	}
+
+	if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout,
+		       sizeof(timeout)) ||
+	    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout,
+		       sizeof(timeout)))
+		return -1;
+
+	return 0;
+}
+
+static int start_server(int type, __u16 port)
+{
+	struct sockaddr_storage addr = env.dut_addr;
+	int fd, on = 1;
+
+	fd = socket(AF_INET6, type, 0);
+	if (fd < 0)
+		return -1;
+
+	((struct sockaddr_in6 *)&addr)->sin6_port = htons(port);
+	if (settimeo(fd, 0) ||
+	    (type == SOCK_STREAM &&
+	     setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on))) ||
+	    bind(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr_in6)) ||
+	    (type == SOCK_STREAM && listen(fd, 1))) {
+		int err = errno;
+
+		close(fd);
+		errno = err;
+		return -1;
+	}
+
+	return fd;
+}
 
 static int libbpf_print_fn(enum libbpf_print_level level,
 			   const char *format, va_list args)
 {
 	if (level == LIBBPF_DEBUG && !env.verbosity)
 		return 0;
 	return vfprintf(stderr, format, args);
 }
 
-static volatile bool exiting;
+static volatile sig_atomic_t stop_signal;
+static atomic_bool exiting;
+
+static bool should_exit(void)
+{
+	return stop_signal || atomic_load(&exiting);
+}
 
 static void sig_handler(int sig)
 {
-	exiting = true;
+	stop_signal = sig;
 }
 
 const char *argp_program_version = "xdp-features 0.0";
 const char argp_program_doc[] =
 "XDP features detection application.\n"
@@ -76,10 +150,11 @@ const char argp_program_doc[] =
 "- XDP_TX\n";
 
 static const struct argp_option opts[] = {
 	{ "verbose", 'v', NULL, 0, "Verbose debug output" },
 	{ "tester", 't', NULL, 0, "Tester mode" },
+	{ "query", 'q', NULL, 0, "Check native XDP support without attaching" },
 	{ "feature", 'f', "XDP-FEATURE", 0, "XDP feature to test" },
 	{ "dut_data_ip", 'D', "DUT-DATA-IP", 0, "DUT IP data channel" },
 	{ "dut_ctrl_ip", 'C', "DUT-CTRL-IP", 0, "DUT IP control channel" },
 	{ "tester_data_ip", 'T', "TESTER-DATA-IP", 0, "Tester IP data channel" },
 	{},
@@ -138,10 +213,13 @@ static error_t parse_arg(int key, char *arg, struct argp_state *state)
 {
 	switch (key) {
 	case 'v':
 		env.verbosity = true;
 		break;
+	case 'q':
+		env.query_only = true;
+		break;
 	case 't':
 		env.is_tester = true;
 		break;
 	case 'f':
 		if (get_xdp_feature(arg) < 0) {
@@ -149,29 +227,27 @@ static error_t parse_arg(int key, char *arg, struct argp_state *state)
 			argp_usage(state);
 			return ARGP_ERR_UNKNOWN;
 		}
 		break;
 	case 'D':
-		if (make_sockaddr(AF_INET6, arg, DUT_ECHO_PORT,
-				  &env.dut_addr, NULL)) {
+		if (make_sockaddr(arg, DUT_ECHO_PORT, &env.dut_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Device Under Test: %s\n",
 				arg);
 			return ARGP_ERR_UNKNOWN;
 		}
 		break;
 	case 'C':
-		if (make_sockaddr(AF_INET6, arg, DUT_CTRL_PORT,
-				  &env.dut_ctrl_addr, NULL)) {
+		if (make_sockaddr(arg, DUT_CTRL_PORT, &env.dut_ctrl_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Device Under Test: %s\n",
 				arg);
 			return ARGP_ERR_UNKNOWN;
 		}
 		break;
 	case 'T':
-		if (make_sockaddr(AF_INET6, arg, 0, &env.tester_addr, NULL)) {
+		if (make_sockaddr(arg, 0, &env.tester_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Tester device: %s\n",
 				arg);
 			return ARGP_ERR_UNKNOWN;
 		}
@@ -211,24 +287,23 @@ static const struct argp argp = {
 static void set_env_default(void)
 {
 	env.feature.drv_feature = NETDEV_XDP_ACT_NDO_XMIT;
 	env.feature.action = -EINVAL;
 	env.ifindex = -ENODEV;
-	strscpy(env.ifname, "unknown");
-	make_sockaddr(AF_INET6, "::ffff:127.0.0.1", DUT_CTRL_PORT,
-		      &env.dut_ctrl_addr, NULL);
-	make_sockaddr(AF_INET6, "::ffff:127.0.0.1", DUT_ECHO_PORT,
-		      &env.dut_addr, NULL);
-	make_sockaddr(AF_INET6, "::ffff:127.0.0.1", 0, &env.tester_addr, NULL);
+	snprintf(env.ifname, sizeof(env.ifname), "unknown");
+	make_sockaddr("::ffff:127.0.0.1", DUT_CTRL_PORT,
+		      &env.dut_ctrl_addr);
+	make_sockaddr("::ffff:127.0.0.1", DUT_ECHO_PORT, &env.dut_addr);
+	make_sockaddr("::ffff:127.0.0.1", 0, &env.tester_addr);
 }
 
 static void *dut_echo_thread(void *arg)
 {
 	unsigned char buf[sizeof(struct tlv_hdr)];
 	int sockfd = *(int *)arg;
 
-	while (!exiting) {
+	while (!should_exit()) {
 		struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
 		struct sockaddr_storage addr;
 		socklen_t addrlen = sizeof(addr);
 		ssize_t n;
 
@@ -249,24 +324,20 @@ static void *dut_echo_thread(void *arg)
 	return NULL;
 }
 
 static int dut_run_echo_thread(pthread_t *t, int *sockfd)
 {
-	int *fds, err;
+	int err;
 
-	fds = start_reuseport_server(AF_INET6, SOCK_DGRAM, NULL,
-					DUT_ECHO_PORT, 0, 1);
-	if (!fds) {
+	*sockfd = start_server(SOCK_DGRAM, DUT_ECHO_PORT);
+	if (*sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating data UDP socket on device %s\n",
 			env.ifname);
 		return -errno;
 	}
 
-	*sockfd = *fds;
-	free(fds);
-
 	/* start echo channel */
 	err = pthread_create(t, NULL, dut_echo_thread, sockfd);
 	if (err) {
 		fprintf(stderr,
 			"Failed creating data UDP thread on device %s: %s\n",
@@ -276,16 +347,17 @@ static int dut_run_echo_thread(pthread_t *t, int *sockfd)
 	}
 
 	return 0;
 }
 
-static int dut_attach_xdp_prog(struct xdp_features *skel, int flags)
+static int dut_attach_xdp_prog(struct xdp_features *skel)
 {
 	enum xdp_action action = env.feature.action;
 	struct bpf_program *prog;
 	unsigned int key = 0;
 	int err, fd = 0;
+	LIBBPF_OPTS(bpf_link_create_opts, opts, .flags = XDP_FLAGS_DRV_MODE);
 
 	if (env.feature.drv_feature == NETDEV_XDP_ACT_NDO_XMIT) {
 		struct bpf_devmap_val entry = {
 			.ifindex = env.ifindex,
 		};
@@ -330,109 +402,179 @@ static int dut_attach_xdp_prog(struct xdp_features *skel, int flags)
 	}
 	default:
 		return -EINVAL;
 	}
 
-	err = bpf_xdp_attach(env.ifindex, bpf_program__fd(prog), flags, NULL);
-	if (err)
+	err = bpf_link_create(bpf_program__fd(prog), env.ifindex, BPF_XDP,
+			      &opts);
+	if (err < 0)
 		fprintf(stderr, "Failed attaching XDP program to device %s\n",
 			env.ifname);
 	return err;
 }
 
+static int send_msg(int sockfd, const void *buf, size_t len)
+{
+	const char *data = buf;
+
+	while (len && !should_exit()) {
+		ssize_t n = send(sockfd, data, len, MSG_NOSIGNAL);
+
+		if (n < 0) {
+			if (errno == EINTR)
+				continue;
+			return -errno;
+		}
+		if (!n)
+			return -EIO;
+		data += n;
+		len -= n;
+	}
+	return len ? -EINTR : 0;
+}
+
 static int recv_msg(int sockfd, void *buf, size_t bufsize, void *val,
 		    size_t val_size)
 {
 	struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
+	ssize_t received;
 	size_t len;
 
-	len = recv(sockfd, buf, bufsize, 0);
-	if (len != ntohs(tlv->len) || len < sizeof(*tlv))
+	received = recv(sockfd, buf, sizeof(*tlv), MSG_WAITALL);
+	if (received < 0)
+		return -errno;
+	if (received != sizeof(*tlv))
+		return -ECONNRESET;
+	len = ntohs(tlv->len);
+	if (len < sizeof(*tlv) || len > bufsize)
 		return -EINVAL;
+	if (len > sizeof(*tlv)) {
+		received = recv(sockfd, tlv->data, len - sizeof(*tlv), MSG_WAITALL);
+		if (received < 0 || (size_t)received != len - sizeof(*tlv))
+			return -ECONNRESET;
+	}
 
 	if (val) {
 		len -= sizeof(*tlv);
-		if (len > val_size)
+		if (len != val_size)
 			return -ENOMEM;
 
 		memcpy(val, tlv->data, len);
 	}
 
 	return 0;
 }
 
 static int dut_run(struct xdp_features *skel)
 {
-	int flags = XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE;
-	int state = CMD_STOP, err = 0, *sockfd, ctrl_sockfd, echo_sockfd;
+	int link_fd = -1;
+	int state = CMD_STOP, err = 0, sockfd, ctrl_sockfd, echo_sockfd;
 	struct sockaddr_storage ctrl_addr;
 	pthread_t dut_thread;
 	bool thread_started = false;
+	int attempt;
 	socklen_t addrlen = sizeof(ctrl_addr);
 
-	sockfd = start_reuseport_server(AF_INET6, SOCK_STREAM, NULL,
-					DUT_CTRL_PORT, 0, 1);
-	if (!sockfd) {
+	sockfd = start_server(SOCK_STREAM, DUT_CTRL_PORT);
+	if (sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating control socket on device %s\n", env.ifname);
 		return -errno;
 	}
 
-	ctrl_sockfd = accept(*sockfd, (struct sockaddr *)&ctrl_addr, &addrlen);
+	/* Allow remote startup and BPF loading on slow test machines. */
+	ctrl_sockfd = -1;
+	for (attempt = 0; attempt < 20 && !should_exit(); attempt++) {
+		addrlen = sizeof(ctrl_addr);
+		ctrl_sockfd = accept(sockfd, (struct sockaddr *)&ctrl_addr,
+				     &addrlen);
+		if (ctrl_sockfd >= 0 || (errno != EAGAIN && errno != EINTR))
+			break;
+	}
 	if (ctrl_sockfd < 0) {
 		fprintf(stderr,
 			"Failed accepting connections on device %s control socket\n",
 			env.ifname);
-		free_fds(sockfd, 1);
-		return -errno;
+		err = should_exit() ? -EINTR : -errno;
+		close(sockfd);
+		return err;
+	}
+
+	if (memcmp(&((struct sockaddr_in6 *)&ctrl_addr)->sin6_addr,
+		   &((struct sockaddr_in6 *)&env.tester_addr)->sin6_addr,
+		   sizeof(struct in6_addr))) {
+		err = -EPERM;
+		goto out;
+	}
+
+	if (settimeo(ctrl_sockfd, 3000)) {
+		err = -errno;
+		goto out;
 	}
 
 	/* CTRL loop */
-	while (!exiting) {
+	while (!should_exit()) {
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
 
 			state = CMD_START;
 			/* Load the XDP program on the DUT */
-			err = dut_attach_xdp_prog(skel, flags);
-			if (err)
+			link_fd = dut_attach_xdp_prog(skel);
+			if (link_fd < 0) {
+				err = link_fd;
 				goto out;
+			}
 
 			err = dut_run_echo_thread(&dut_thread, &echo_sockfd);
 			if (err < 0)
 				goto out;
 			thread_started = true;
 
 			tlv->type = htons(CMD_ACK);
 			tlv->len = htons(sizeof(*tlv));
-			err = send(ctrl_sockfd, buf, sizeof(*tlv), 0);
+			err = send_msg(ctrl_sockfd, buf, sizeof(*tlv));
 			if (err < 0)
 				goto end_thread;
 			break;
 		}
 		case CMD_STOP:
 			if (state != CMD_START)
 				break;
 
 			state = CMD_STOP;
 
-			exiting = true;
-			bpf_xdp_detach(env.ifindex, flags, NULL);
-
 			tlv->type = htons(CMD_ACK);
 			tlv->len = htons(sizeof(*tlv));
-			err = send(ctrl_sockfd, buf, sizeof(*tlv), 0);
+			err = send_msg(ctrl_sockfd, buf, sizeof(*tlv));
 			goto end_thread;
+		case CMD_GET_MAC: {
+			struct ifreq ifr = {};
+
+			snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", env.ifname);
+			if (ioctl(sockfd, SIOCGIFHWADDR, &ifr)) {
+				err = -errno;
+				goto end_thread;
+			}
+			tlv->type = htons(CMD_ACK);
+			tlv->len = htons(sizeof(*tlv) + ETH_ALEN);
+			memcpy(tlv->data, ifr.ifr_hwaddr.sa_data, ETH_ALEN);
+			err = send_msg(ctrl_sockfd, buf, sizeof(*tlv) + ETH_ALEN);
+			if (err)
+				goto end_thread;
+			break;
+		}
 		case CMD_GET_XDP_CAP: {
 			LIBBPF_OPTS(bpf_xdp_query_opts, opts);
 			unsigned long long val;
 			size_t n;
 
@@ -450,11 +592,11 @@ static int dut_run(struct xdp_features *skel)
 			tlv->len = htons(n);
 
 			val = htobe64(opts.feature_flags);
 			memcpy(tlv->data, &val, sizeof(val));
 
-			err = send(ctrl_sockfd, buf, n, 0);
+			err = send_msg(ctrl_sockfd, buf, n);
 			if (err < 0)
 				goto end_thread;
 			break;
 		}
 		case CMD_GET_STATS: {
@@ -475,11 +617,11 @@ static int dut_run(struct xdp_features *skel)
 			tlv->len = htons(n);
 
 			val = htonl(val);
 			memcpy(tlv->data, &val, sizeof(val));
 
-			err = send(ctrl_sockfd, buf, n, 0);
+			err = send_msg(ctrl_sockfd, buf, n);
 			if (err < 0)
 				goto end_thread;
 			break;
 		}
 		default:
@@ -490,177 +632,300 @@ static int dut_run(struct xdp_features *skel)
 end_thread:
 	exiting = true;
 	if (thread_started)
 		pthread_join(dut_thread, NULL);
 out:
-	bpf_xdp_detach(env.ifindex, flags, NULL);
+	if (link_fd >= 0)
+		close(link_fd);
 	close(ctrl_sockfd);
-	free_fds(sockfd, 1);
+	close(sockfd);
 
 	return err;
 }
 
-static bool tester_collect_detected_cap(struct xdp_features *skel,
-					unsigned int dut_stats)
-{
-	unsigned int err, key = 0, val;
-
-	if (!dut_stats)
-		return false;
-
-	err = bpf_map__lookup_elem(skel->maps.stats, &key, sizeof(key),
-				   &val, sizeof(val), 0);
-	if (err) {
-		fprintf(stderr, "bpf_map_lookup_elem failed (%d)\n", err);
-		return false;
-	}
-
-	switch (env.feature.action) {
-	case XDP_PASS:
-	case XDP_TX:
-	case XDP_REDIRECT:
-		return val > 0;
-	case XDP_DROP:
-	case XDP_ABORTED:
-		return val == 0;
-	default:
-		break;
-	}
-
-	if (env.feature.drv_feature == NETDEV_XDP_ACT_NDO_XMIT)
-		return val > 0;
-
-	return false;
-}
-
 static int send_and_recv_msg(int sockfd, enum test_commands cmd, void *val,
 			     size_t val_size)
 {
 	unsigned char buf[BUFSIZE] = {};
 	struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
 	int err;
 
 	tlv->type = htons(cmd);
 	tlv->len = htons(sizeof(*tlv));
 
-	err = send(sockfd, buf, sizeof(*tlv), 0);
+	err = send_msg(sockfd, buf, sizeof(*tlv));
 	if (err < 0)
 		return err;
 
 	err = recv_msg(sockfd, buf, BUFSIZE, val, val_size);
 	if (err < 0)
 		return err;
 
 	return ntohs(tlv->type) == CMD_ACK ? 0 : -EINVAL;
 }
 
-static int send_echo_msg(void)
+/* Compute checksums in software; packet sockets do not request TX offload. */
+static __u16 packet_checksum(const void *data, size_t len)
 {
-	unsigned char buf[sizeof(struct tlv_hdr)];
-	struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
-	int sockfd, n;
+	const unsigned char *p = data;
+	unsigned int sum = 0;
 
-	sockfd = socket(AF_INET6, SOCK_DGRAM, 0);
-	if (sockfd < 0) {
-		fprintf(stderr,
-			"Failed creating data UDP socket on device %s\n",
-			env.ifname);
-		return -errno;
+	while (len > 1) {
+		sum += (p[0] << 8) | p[1];
+		p += 2;
+		len -= 2;
 	}
+	if (len)
+		sum += p[0] << 8;
+	while (sum >> 16)
+		sum = (sum & 0xffff) + (sum >> 16);
+	return ~sum;
+}
 
-	tlv->type = htons(CMD_ECHO);
-	tlv->len = htons(sizeof(*tlv));
+static size_t make_echo_packet(unsigned char *packet, __be16 source_port)
+{
+	const struct in6_addr *src = &((struct sockaddr_in6 *)&env.tester_addr)->sin6_addr;
+	const struct in6_addr *dst = &((struct sockaddr_in6 *)&env.dut_addr)->sin6_addr;
+	struct udphdr udp = {
+		.source = source_port,
+		.dest = htons(DUT_ECHO_PORT),
+		.len = htons(sizeof(udp) + sizeof(struct tlv_hdr)),
+	};
+	struct tlv_hdr echo = {
+		.type = htons(CMD_ECHO),
+		.len = htons(sizeof(echo)),
+	};
+	unsigned char pseudo[40 + sizeof(udp) + sizeof(echo)] = {};
+	size_t ip_len, pseudo_len;
+	__u16 checksum;
+
+	if (IN6_IS_ADDR_V4MAPPED(dst)) {
+		struct iphdr ip = {
+			.version = 4, .ihl = 5, .ttl = 64,
+			.protocol = IPPROTO_UDP,
+			.tot_len = htons(sizeof(ip) + sizeof(udp) + sizeof(echo)),
+		};
 
-	n = sendto(sockfd, buf, sizeof(*tlv), MSG_NOSIGNAL | MSG_CONFIRM,
-		   (struct sockaddr *)&env.dut_addr, sizeof(env.dut_addr));
-	close(sockfd);
+		memcpy(&ip.saddr, &src->s6_addr[12], 4);
+		memcpy(&ip.daddr, &dst->s6_addr[12], 4);
+		ip.check = htons(packet_checksum(&ip, sizeof(ip)));
+		memcpy(packet, &ip, sizeof(ip));
+		memcpy(pseudo, &ip.saddr, 4);
+		memcpy(pseudo + 4, &ip.daddr, 4);
+		pseudo[9] = IPPROTO_UDP;
+		memcpy(pseudo + 10, &udp.len, 2);
+		pseudo_len = 12;
+		ip_len = sizeof(ip);
+	} else {
+		struct ipv6hdr ip = {
+			.version = 6, .hop_limit = 64,
+			.nexthdr = IPPROTO_UDP, .payload_len = udp.len,
+			.saddr = *src, .daddr = *dst,
+		};
+		__be32 len = htonl(sizeof(udp) + sizeof(echo));
+
+		memcpy(packet, &ip, sizeof(ip));
+		memcpy(pseudo, src, sizeof(*src));
+		memcpy(pseudo + 16, dst, sizeof(*dst));
+		memcpy(pseudo + 32, &len, sizeof(len));
+		pseudo[39] = IPPROTO_UDP;
+		pseudo_len = 40;
+		ip_len = sizeof(ip);
+	}
+	memcpy(pseudo + pseudo_len, &udp, sizeof(udp));
+	memcpy(pseudo + pseudo_len + sizeof(udp), &echo, sizeof(echo));
+	checksum = packet_checksum(pseudo, pseudo_len + sizeof(udp) + sizeof(echo));
+	udp.check = htons(checksum ? checksum : 0xffff);
+	memcpy(packet + ip_len, &udp, sizeof(udp));
+	memcpy(packet + ip_len + sizeof(udp), &echo, sizeof(echo));
+	return ip_len + sizeof(udp) + sizeof(echo);
+}
 
-	return n == ntohs(tlv->len) ? 0 : -EINVAL;
+static bool is_echo_reply(const unsigned char *packet, size_t len,
+			  __be16 source_port)
+{
+	const struct in6_addr *tester = &((struct sockaddr_in6 *)&env.tester_addr)->sin6_addr;
+	const struct in6_addr *dut = &((struct sockaddr_in6 *)&env.dut_addr)->sin6_addr;
+	bool reflected = env.feature.action == XDP_TX ||
+			 env.feature.drv_feature == NETDEV_XDP_ACT_NDO_XMIT;
+	const struct in6_addr *src = reflected ? tester : dut;
+	const struct in6_addr *dst = reflected ? dut : tester;
+	struct tlv_hdr echo;
+	struct udphdr udp;
+	size_t ip_len;
+
+	if (IN6_IS_ADDR_V4MAPPED(dut)) {
+		struct iphdr ip;
+
+		if (len < sizeof(ip))
+			return false;
+		memcpy(&ip, packet, sizeof(ip));
+		ip_len = ip.ihl * 4;
+		if (ip.version != 4 || ip_len < sizeof(ip) ||
+		    ip.protocol != IPPROTO_UDP ||
+		    memcmp(&ip.saddr, &src->s6_addr[12], 4) ||
+		    memcmp(&ip.daddr, &dst->s6_addr[12], 4))
+			return false;
+	} else {
+		struct ipv6hdr ip;
+
+		if (len < sizeof(ip))
+			return false;
+		memcpy(&ip, packet, sizeof(ip));
+		ip_len = sizeof(ip);
+		if (ip.version != 6 || ip.nexthdr != IPPROTO_UDP ||
+		    memcmp(&ip.saddr, src, sizeof(*src)) ||
+		    memcmp(&ip.daddr, dst, sizeof(*dst)))
+			return false;
+	}
+	if (len < ip_len + sizeof(udp) + sizeof(echo))
+		return false;
+	memcpy(&udp, packet + ip_len, sizeof(udp));
+	memcpy(&echo, packet + ip_len + sizeof(udp), sizeof(echo));
+	return udp.source == (reflected ? source_port : htons(DUT_ECHO_PORT)) &&
+	       udp.dest == (reflected ? htons(DUT_ECHO_PORT) : source_port) &&
+	       echo.type == htons(CMD_ECHO) && echo.len == htons(sizeof(echo));
+}
+
+static long long monotonic_ms(void)
+{
+	struct timespec ts;
+
+	clock_gettime(CLOCK_MONOTONIC, &ts);
+	return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
+}
+
+static int collect_echoes(int fd, __be16 source_port, unsigned int *count)
+{
+	long long deadline = monotonic_ms() + 1000;
+	struct pollfd pfd = { .fd = fd, .events = POLLIN };
+
+	while (!should_exit()) {
+		unsigned char packet[2048];
+		struct sockaddr_ll from;
+		socklen_t addrlen = sizeof(from);
+		int remaining = deadline - monotonic_ms();
+		ssize_t len;
+		int err;
+
+		if (remaining <= 0)
+			break;
+		err = poll(&pfd, 1, remaining);
+		if (err < 0) {
+			if (errno == EINTR)
+				continue;
+			return -errno;
+		}
+		if (!err)
+			break;
+		len = recvfrom(fd, packet, sizeof(packet), MSG_DONTWAIT,
+			       (struct sockaddr *)&from, &addrlen);
+		if (len < 0) {
+			if (errno == EAGAIN || errno == EINTR)
+				continue;
+			return -errno;
+		}
+		if (env.verbosity)
+			fprintf(stderr, "packet type=%u len=%zd match=%d\n",
+				from.sll_pkttype, len,
+				is_echo_reply(packet, len, source_port));
+		if (from.sll_pkttype != PACKET_OUTGOING &&
+		    is_echo_reply(packet, len, source_port))
+			(*count)++;
+	}
+	return should_exit() ? -EINTR : 0;
 }
 
-static int tester_run(struct xdp_features *skel)
+static int tester_run(void)
 {
-	int flags = XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE;
+	struct sockaddr_ll peer = {
+		.sll_family = AF_PACKET, .sll_ifindex = env.ifindex,
+		.sll_protocol = htons(ETH_P_ALL), .sll_halen = ETH_ALEN,
+	};
+	struct sockaddr_in6 local = *(struct sockaddr_in6 *)&env.tester_addr;
 	unsigned long long advertised_feature;
-	struct bpf_program *prog;
-	unsigned int stats;
+	unsigned int stats, received = 0;
+	unsigned char packet[128];
+	int data_fd = -1, port_fd = -1;
+	socklen_t addrlen = sizeof(local);
 	int i, err, sockfd;
+	size_t packet_len;
 	bool detected_cap;
 
 	sockfd = socket(AF_INET6, SOCK_STREAM, 0);
-	if (sockfd < 0) {
-		fprintf(stderr,
-			"Failed creating tester service control socket\n");
-		return -errno;
-	}
-
-	if (settimeo(sockfd, 1000) < 0)
-		return -EINVAL;
-
-	err = connect(sockfd, (struct sockaddr *)&env.dut_ctrl_addr,
-		      sizeof(env.dut_ctrl_addr));
-	if (err) {
-		fprintf(stderr,
-			"Failed connecting to the Device Under Test control socket\n");
+	if (sockfd < 0)
 		return -errno;
+	if (settimeo(sockfd, 30000) ||
+	    bind(sockfd, (struct sockaddr *)&local, sizeof(local)) ||
+	    connect(sockfd, (struct sockaddr *)&env.dut_ctrl_addr,
+		    sizeof(struct sockaddr_in6))) {
+		err = -errno;
+		goto out;
 	}
-
 	err = send_and_recv_msg(sockfd, CMD_GET_XDP_CAP, &advertised_feature,
 				sizeof(advertised_feature));
-	if (err < 0) {
-		close(sockfd);
-		return err;
-	}
-
+	if (err)
+		goto out;
 	advertised_feature = be64toh(advertised_feature);
+	err = send_and_recv_msg(sockfd, CMD_GET_MAC, peer.sll_addr, ETH_ALEN);
+	if (err)
+		goto out;
 
-	if (env.feature.drv_feature == NETDEV_XDP_ACT_NDO_XMIT ||
-	    env.feature.action == XDP_TX)
-		prog = skel->progs.xdp_tester_check_tx;
-	else
-		prog = skel->progs.xdp_tester_check_rx;
-
-	err = bpf_xdp_attach(env.ifindex, bpf_program__fd(prog), flags, NULL);
-	if (err) {
-		fprintf(stderr, "Failed attaching XDP program to device %s\n",
-			env.ifname);
+	/* Reserve an ephemeral source port without changing the peer NIC. */
+	port_fd = socket(AF_INET6, SOCK_DGRAM, 0);
+	if (port_fd < 0 || bind(port_fd, (struct sockaddr *)&local, sizeof(local)) ||
+	    getsockname(port_fd, (struct sockaddr *)&local, &addrlen)) {
+		err = -errno;
 		goto out;
 	}
-
+	data_fd = socket(AF_PACKET, SOCK_DGRAM, htons(ETH_P_ALL));
+	if (data_fd < 0 || bind(data_fd, (struct sockaddr *)&peer, sizeof(peer))) {
+		err = -errno;
+		goto out;
+	}
+	peer.sll_protocol = IN6_IS_ADDR_V4MAPPED(&local.sin6_addr) ?
+			    htons(ETH_P_IP) : htons(ETH_P_IPV6);
+	packet_len = make_echo_packet(packet, local.sin6_port);
 	err = send_and_recv_msg(sockfd, CMD_START, NULL, 0);
 	if (err)
 		goto out;
+	for (i = 0; i < 10 && !should_exit(); i++) {
+		ssize_t len;
 
-	for (i = 0; i < 10 && !exiting; i++) {
-		err = send_echo_msg();
-		if (err < 0)
+		len = sendto(data_fd, packet, packet_len, 0,
+			     (struct sockaddr *)&peer, sizeof(peer));
+		if (len < 0 || (size_t)len != packet_len) {
+			err = len < 0 ? -errno : -EIO;
+			goto out;
+		}
+		err = collect_echoes(data_fd, local.sin6_port, &received);
+		if (err)
 			goto out;
-
-		sleep(1);
 	}
-
 	err = send_and_recv_msg(sockfd, CMD_GET_STATS, &stats, sizeof(stats));
 	if (err)
 		goto out;
-
-	/* Sample before teardown can produce additional echo traffic. */
-	detected_cap = tester_collect_detected_cap(skel, ntohl(stats));
-
-	/* stop the test */
+	detected_cap = ntohl(stats) &&
+		       ((env.feature.action == XDP_DROP ||
+			 env.feature.action == XDP_ABORTED) ? !received : received);
+	if (env.verbosity)
+		fprintf(stderr, "dut=%u received=%u advertised=%llx\n",
+			ntohl(stats), received, advertised_feature);
 	err = send_and_recv_msg(sockfd, CMD_STOP, NULL, 0);
-	/* send a new echo message to wake echo thread of the dut */
-	send_echo_msg();
-
-
+	if (err)
+		goto out;
 	fprintf(stdout, "Feature %s: [%s][%s]\n", get_xdp_feature_str(),
 		detected_cap ? GREEN("DETECTED") : RED("NOT DETECTED"),
 		env.feature.drv_feature & advertised_feature ? GREEN("ADVERTISED")
 							     : RED("NOT ADVERTISED"));
 out:
-	bpf_xdp_detach(env.ifindex, flags, NULL);
+	if (data_fd >= 0)
+		close(data_fd);
+	if (port_fd >= 0)
+		close(port_fd);
 	close(sockfd);
-	return err < 0 ? err : 0;
+	return err;
 }
 
 int main(int argc, char **argv)
 {
 	struct xdp_features *skel;
@@ -669,10 +934,12 @@ int main(int argc, char **argv)
 	libbpf_set_strict_mode(LIBBPF_STRICT_ALL);
 	libbpf_set_print(libbpf_print_fn);
 
 	signal(SIGINT, sig_handler);
 	signal(SIGTERM, sig_handler);
+	signal(SIGALRM, sig_handler);
+	alarm(90);
 
 	set_env_default();
 
 	/* Parse command line arguments */
 	err = argp_parse(&argp, argc, argv, 0, NULL, NULL);
@@ -682,10 +949,24 @@ int main(int argc, char **argv)
 	if (env.ifindex < 0) {
 		fprintf(stderr, "Invalid device name %s\n", env.ifname);
 		return -ENODEV;
 	}
 
+	if (env.query_only) {
+		LIBBPF_OPTS(bpf_xdp_query_opts, opts);
+
+		err = bpf_xdp_query(env.ifindex, XDP_FLAGS_DRV_MODE, &opts);
+		if (err)
+			return 1;
+		return opts.feature_flags & NETDEV_XDP_ACT_BASIC ? 0 : 4;
+	}
+
+	if (env.is_tester) {
+		err = tester_run();
+		return stop_signal ? EINTR : (err < 0 ? -err : 0);
+	}
+
 	/* Load and verify BPF application */
 	skel = xdp_features__open();
 	if (!skel) {
 		fprintf(stderr, "Failed to open and load BPF skeleton\n");
 		return -EINVAL;
@@ -707,21 +988,14 @@ int main(int argc, char **argv)
 	if (err) {
 		fprintf(stderr, "Failed to attach BPF skeleton\n");
 		goto cleanup;
 	}
 
-	if (env.is_tester) {
-		/* Tester */
-		fprintf(stdout, "Starting tester service on device %s\n",
-			env.ifname);
-		err = tester_run(skel);
-	} else {
-		/* DUT */
-		fprintf(stdout, "Starting test on device %s\n", env.ifname);
-		err = dut_run(skel);
-	}
+	err = dut_run(skel);
 
 cleanup:
 	xdp_features__destroy(skel);
 
+	if (stop_signal)
+		return EINTR;
 	return err < 0 ? -err : 0;
 }
diff --git a/tools/testing/selftests/bpf/xdp_features.h b/tools/testing/selftests/bpf/xdp_features.h
index 2670c541713b6..ba776e5ce7ebb 100644
--- a/tools/testing/selftests/bpf/xdp_features.h
+++ b/tools/testing/selftests/bpf/xdp_features.h
@@ -6,10 +6,11 @@ enum test_commands {
 	CMD_START,		/* CMD */
 	CMD_ECHO,		/* CMD */
 	CMD_ACK,		/* CMD + data */
 	CMD_GET_XDP_CAP,	/* CMD */
 	CMD_GET_STATS,		/* CMD */
+	CMD_GET_MAC,		/* CMD + data */
 };
 
 #define DUT_CTRL_PORT	12345
 #define DUT_ECHO_PORT	12346
 

-- 
Git-155)

