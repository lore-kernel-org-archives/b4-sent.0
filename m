From: Bochao Cao <bochaolucky@gmail.com>
Date: Mon, 21 Sep 2026 14:00:05 +0800
Subject: [PATCH net-next v4 2/2] selftests/net: Move XDP feature test to
 driver framework
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-xdp-features-v4-send-v4-2-a0d4ec392cb7@gmail.com>
References: <20260921-xdp-features-v4-send-v4-0-a0d4ec392cb7@gmail.com>
In-Reply-To: <20260921-xdp-features-v4-send-v4-0-a0d4ec392cb7@gmail.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, Eric Dumazet <edumazet@google.com>, 
 Paolo Abeni <pabeni@redhat.com>
Cc: =?utf-8?q?Alexis_Lothor=C3=A9?= <alexis.lothore@bootlin.com>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Tiezhu Yang <tiozhang@didiglobal.com>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bochao Cao <bochaolucky@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789970439; l=20294;
 i=bochaolucky@gmail.com; h=from:subject:message-id;
 bh=1PqzglOj5gNXkzijtiGwTwpCA9pEVko3J9VS9mddo5E=;
 b=rI/ysviGJ0qvvaTFKt6p//f5wrDKD5jtHBogaNqGxhZ0rQiXxaINJhsLJcudayjL9osoBM+WV
 27YkXGVwNyUDPTViog3FmfmYxJaaAkXgvxlwrofuyPzETQkuQL1kbkX
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the XDP feature test to drivers/net/hw and use NetDrvEpEnv to test
configured local and remote interfaces. Sample results before cleanup
traffic and fail tests when detected and advertised features disagree.

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/Makefile               |  11 +-
 tools/testing/selftests/bpf/test_xdp_features.sh   | 155 ---------------------
 tools/testing/selftests/drivers/net/hw/.gitignore  |   3 +
 tools/testing/selftests/drivers/net/hw/Makefile    |  22 +++
 .../net/hw/xdp_features.bpf.c}                     |   0
 .../{bpf => drivers/net/hw}/xdp_features.c         | 126 ++++++++++++-----
 .../{bpf => drivers/net/hw}/xdp_features.h         |   0
 .../selftests/drivers/net/hw/xdp_features.py       | 109 +++++++++++++++
 8 files changed, 226 insertions(+), 200 deletions(-)

diff --git a/tools/testing/selftests/bpf/Makefile b/tools/testing/selftests/bpf/Makefile
index 93c707116..cb76b68c9 100644
--- a/tools/testing/selftests/bpf/Makefile
+++ b/tools/testing/selftests/bpf/Makefile
@@ -126,7 +126,7 @@ TEST_PROGS := test_kmod.sh \
 	test_bpftool_build.sh \
 	test_doc_build.sh \
 	test_xsk.sh \
-	test_xdp_features.sh
+	#
 
 TEST_PROGS_EXTENDED := \
 	ima_setup.sh verify_sig_setup.sh
@@ -142,7 +142,6 @@ TEST_GEN_PROGS_EXTENDED = \
 	test_cpp \
 	test_lirc_mode2_user \
 	veristat \
-	xdp_features \
 	xdp_hw_metadata \
 	xdp_synproxy \
 	xskxceiver
@@ -544,7 +543,6 @@ test_subskeleton_lib.skel.h-deps := test_subskeleton_lib2.bpf.o test_subskeleton
 test_usdt.skel.h-deps := test_usdt.bpf.o test_usdt_multispec.bpf.o
 xsk_xdp_progs.skel.h-deps := xsk_xdp_progs.bpf.o
 xdp_hw_metadata.skel.h-deps := xdp_hw_metadata.bpf.o
-xdp_features.skel.h-deps := xdp_features.bpf.o
 tracing_multi.skel.h-deps := tracing_multi_attach.bpf.o tracing_multi_check.bpf.o
 tracing_multi_module.skel.h-deps := tracing_multi_attach_module.bpf.o tracing_multi_check.bpf.o
 tracing_multi_intersect.skel.h-deps := tracing_multi_intersect_attach.bpf.o tracing_multi_check.bpf.o
@@ -947,13 +945,6 @@ $(OUTPUT)/xdp_hw_metadata: xdp_hw_metadata.c xsk.c network_helpers.c \
 	$(call msg,BINARY,,$@)
 	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
 
-$(OUTPUT)/xdp_features: xdp_features.c network_helpers.c xdp_features.h \
-			   network_helpers.h \
-			   test_progs.h bpf_util.h $(OUTPUT)/xdp_features.skel.h \
-			   $(BPFOBJ) | $(OUTPUT)
-	$(call msg,BINARY,,$@)
-	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
-
 # Make sure we are able to include and link libbpf against c++.
 CXXFLAGS += $(CFLAGS)
 CXXFLAGS := $(subst -D_GNU_SOURCE=,,$(CXXFLAGS))
diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
deleted file mode 100755
index a78e0fb9e..000000000
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ /dev/null
@@ -1,155 +0,0 @@
-#!/bin/bash
-# SPDX-License-Identifier: GPL-2.0
-
-readonly NS="ns1-$(mktemp -u XXXXXX)"
-readonly V0_IP4=10.10.0.11
-readonly V1_IP4=10.10.0.1
-readonly V0_IP6=2001:db8::11
-readonly V1_IP6=2001:db8::1
-
-ret=1
-dut_pid=""
-
-setup() {
-	{
-		ip netns add ${NS}
-
-		ip link add v1 type veth peer name v0 netns ${NS}
-
-		ip link set v1 up
-		ip addr add $V1_IP4/24 dev v1
-		ip addr add $V1_IP6/64 nodad dev v1
-		ip -n ${NS} link set dev v0 up
-		ip -n ${NS} addr add $V0_IP4/24 dev v0
-		ip -n ${NS} addr add $V0_IP6/64 nodad dev v0
-
-		# Enable XDP mode and disable checksum offload
-		ethtool -K v1 gro on
-		ethtool -K v1 tx-checksumming off
-		ip netns exec ${NS} ethtool -K v0 gro on
-		ip netns exec ${NS} ethtool -K v0 tx-checksumming off
-	} > /dev/null 2>&1
-}
-
-terminate_dut_server() {
-	local pid
-
-	# Use the shell job instead of dut_pid, which may not have been assigned
-	# yet if a signal arrived immediately after the server was started.
-	pid=$(jobs -pr %% 2> /dev/null) || true
-	if [ -z "$pid" ]; then
-		dut_pid=""
-		return
-	fi
-
-	kill -KILL %% 2> /dev/null || true
-	wait "$pid" 2> /dev/null || true
-	dut_pid=""
-}
-
-cleanup() {
-	terminate_dut_server
-	ip link del v1 2> /dev/null || true
-	ip netns del "${NS}" 2> /dev/null || true
-}
-
-wait_for_dut_server() {
-	local i
-
-	for ((i = 0; i < 10; i++)); do
-		if [ "$(jobs -pr %% 2> /dev/null)" != "$dut_pid" ]; then
-			echo "xdp_features server $dut_pid exited before accepting connections" >&2
-			return 1
-		fi
-
-		if ss -tlp 2> /dev/null | grep -q "pid=$dut_pid,"; then
-			return 0
-		fi
-
-		sleep 1
-	done
-
-	echo "Timed out waiting for xdp_features server $dut_pid" >&2
-	return 1
-}
-
-start_dut_server() {
-	./xdp_features "$@" &
-	dut_pid=$!
-	wait_for_dut_server
-}
-
-reap_dut_server() {
-	local status=0
-
-	wait "$dut_pid" || status=$?
-	dut_pid=""
-	return "$status"
-}
-
-test_xdp_features() {
-	setup
-
-	## XDP_PASS
-	start_dut_server -f XDP_PASS -D $V1_IP6 -T $V0_IP6 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_PASS \
-					   -D $V1_IP6 -C $V1_IP6 \
-					   -T $V0_IP6 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
-
-	## XDP_DROP
-	start_dut_server -f XDP_DROP -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_DROP \
-					   -D ::ffff:$V1_IP4 \
-					   -C ::ffff:$V1_IP4 \
-					   -T ::ffff:$V0_IP4 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
-
-	## XDP_ABORTED
-	start_dut_server -f XDP_ABORTED -D $V1_IP6 -T $V0_IP6 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_ABORTED \
-					   -D $V1_IP6 -C $V1_IP6 \
-					   -T $V0_IP6 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
-
-	## XDP_TX
-	start_dut_server -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_TX \
-					   -D ::ffff:$V1_IP4 \
-					   -C ::ffff:$V1_IP4 \
-					   -T ::ffff:$V0_IP4 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
-
-	## XDP_REDIRECT
-	start_dut_server -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_REDIRECT \
-					   -D $V1_IP6 -C $V1_IP6 \
-					   -T $V0_IP6 v0
-	[ $? -ne 0 ] && exit
-	reap_dut_server
-
-	## XDP_NDO_XMIT
-	start_dut_server -f XDP_NDO_XMIT -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
-	ip netns exec ${NS} ./xdp_features -t -f XDP_NDO_XMIT \
-					   -D ::ffff:$V1_IP4 \
-					   -C ::ffff:$V1_IP4 \
-					   -T ::ffff:$V0_IP4 v0
-	ret=$?
-	reap_dut_server
-}
-
-set -e
-trap cleanup EXIT
-trap 'exit 129' HUP
-trap 'exit 130' INT
-trap 'exit 131' QUIT
-trap 'exit 134' ABRT
-trap 'exit 143' TERM
-
-test_xdp_features
-
-exit $ret
diff --git a/tools/testing/selftests/drivers/net/hw/.gitignore b/tools/testing/selftests/drivers/net/hw/.gitignore
index 46540468a..a0cd8bc37 100644
--- a/tools/testing/selftests/drivers/net/hw/.gitignore
+++ b/tools/testing/selftests/drivers/net/hw/.gitignore
@@ -2,3 +2,6 @@
 iou-zcrx
 ncdevmem
 toeplitz
+tools/
+xdp_features
+xdp_features.skel.h
diff --git a/tools/testing/selftests/drivers/net/hw/Makefile b/tools/testing/selftests/drivers/net/hw/Makefile
index 8aebdc6fe..a5dea02ee 100644
--- a/tools/testing/selftests/drivers/net/hw/Makefile
+++ b/tools/testing/selftests/drivers/net/hw/Makefile
@@ -50,6 +50,7 @@ TEST_PROGS = \
 	tso.py \
 	userns_devmem.py \
 	uso.py \
+	xdp_features.py \
 	xdp_metadata.py \
 	xsk_reconfig.py \
 	#
@@ -80,6 +81,7 @@ YNL_GEN_FILES := \
 # end of YNL_GEN_FILES
 TEST_GEN_FILES += $(YNL_GEN_FILES)
 TEST_GEN_FILES += $(patsubst %.c,%.o,$(wildcard *.bpf.c))
+TEST_GEN_PROGS += xdp_features
 
 include ../../../lib.mk
 
@@ -93,6 +95,26 @@ include ../../../net/ynl.mk
 
 include ../../../net/bpf.mk
 
+BPFTOOL ?= bpftool
+
+CFLAGS += -I$(OUTPUT) -I$(SCRATCH_DIR)/include
+CFLAGS += -I$(top_srcdir)/tools/include
+CFLAGS += -I$(top_srcdir)/tools/arch/$(SRCARCH)/include
+CFLAGS += -I$(top_srcdir)/tools/include/uapi
+CFLAGS += -I../../../net/lib
+
+$(OUTPUT)/xdp_features.skel.h: $(OUTPUT)/xdp_features.bpf.o
+	$(call msg,GEN-SKEL,,$@)
+	$(Q)$(BPFTOOL) gen skeleton $< name xdp_features > $@
+
+$(OUTPUT)/xdp_features: xdp_features.c xdp_features.h \
+			   $(OUTPUT)/xdp_features.skel.h $(BPFOBJ)
+	$(call msg,BINARY,,$@)
+	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) \
+		$(LDLIBS) -lelf -lz -lpthread -o $@
+
+EXTRA_CLEAN += $(OUTPUT)/xdp_features.skel.h
+
 ifeq ($(HAS_IOURING_ZCRX),y)
 $(OUTPUT)/iou-zcrx: LDLIBS += -luring -lpthread
 endif
diff --git a/tools/testing/selftests/bpf/progs/xdp_features.c b/tools/testing/selftests/drivers/net/hw/xdp_features.bpf.c
similarity index 100%
rename from tools/testing/selftests/bpf/progs/xdp_features.c
rename to tools/testing/selftests/drivers/net/hw/xdp_features.bpf.c
diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/drivers/net/hw/xdp_features.c
similarity index 86%
rename from tools/testing/selftests/bpf/xdp_features.c
rename to tools/testing/selftests/drivers/net/hw/xdp_features.c
index a27ed6639..ccc0630bb 100644
--- a/tools/testing/selftests/bpf/xdp_features.c
+++ b/tools/testing/selftests/drivers/net/hw/xdp_features.c
@@ -1,22 +1,26 @@
 // SPDX-License-Identifier: GPL-2.0
-#include <uapi/linux/bpf.h>
-#include <uapi/linux/netdev.h>
+#include <linux/bpf.h>
+#include <linux/netdev.h>
 #include <linux/if_link.h>
-#include <signal.h>
 #include <argp.h>
+#include <errno.h>
 #include <net/if.h>
+#include <pthread.h>
+#include <signal.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
 #include <sys/socket.h>
+#include <sys/time.h>
 #include <netinet/in.h>
 #include <netinet/tcp.h>
 #include <unistd.h>
 #include <arpa/inet.h>
 #include <bpf/bpf.h>
 #include <bpf/libbpf.h>
-#include <pthread.h>
 
-#include <network_helpers.h>
-
-#include "bpf_util.h"
+#include "ksft.h"
 #include "xdp_features.skel.h"
 #include "xdp_features.h"
 
@@ -40,7 +44,63 @@ static struct env {
 
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
+	struct sockaddr_storage addr;
+	int fd, on = 1;
+
+	fd = socket(AF_INET6, type, 0);
+	if (fd < 0)
+		return -1;
+
+	if (settimeo(fd, 0) ||
+	    setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &on, sizeof(on)) ||
+	    (type == SOCK_STREAM &&
+	     setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on))) ||
+	    make_sockaddr(NULL, port, &addr) ||
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
@@ -151,8 +211,7 @@ static error_t parse_arg(int key, char *arg, struct argp_state *state)
 		}
 		break;
 	case 'D':
-		if (make_sockaddr(AF_INET6, arg, DUT_ECHO_PORT,
-				  &env.dut_addr, NULL)) {
+		if (make_sockaddr(arg, DUT_ECHO_PORT, &env.dut_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Device Under Test: %s\n",
 				arg);
@@ -160,8 +219,7 @@ static error_t parse_arg(int key, char *arg, struct argp_state *state)
 		}
 		break;
 	case 'C':
-		if (make_sockaddr(AF_INET6, arg, DUT_CTRL_PORT,
-				  &env.dut_ctrl_addr, NULL)) {
+		if (make_sockaddr(arg, DUT_CTRL_PORT, &env.dut_ctrl_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Device Under Test: %s\n",
 				arg);
@@ -169,7 +227,7 @@ static error_t parse_arg(int key, char *arg, struct argp_state *state)
 		}
 		break;
 	case 'T':
-		if (make_sockaddr(AF_INET6, arg, 0, &env.tester_addr, NULL)) {
+		if (make_sockaddr(arg, 0, &env.tester_addr)) {
 			fprintf(stderr,
 				"Invalid address assigned to the Tester device: %s\n",
 				arg);
@@ -213,12 +271,11 @@ static void set_env_default(void)
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
@@ -229,7 +286,7 @@ static void *dut_echo_thread(void *arg)
 	while (!exiting) {
 		struct tlv_hdr *tlv = (struct tlv_hdr *)buf;
 		struct sockaddr_storage addr;
-		socklen_t addrlen;
+		socklen_t addrlen = sizeof(addr);
 		size_t n;
 
 		n = recvfrom(sockfd, buf, sizeof(buf), MSG_WAITALL,
@@ -244,7 +301,6 @@ static void *dut_echo_thread(void *arg)
 		       (struct sockaddr *)&addr, addrlen);
 	}
 
-	pthread_exit((void *)0);
 	close(sockfd);
 
 	return NULL;
@@ -254,9 +310,8 @@ static int dut_run_echo_thread(pthread_t *t, int *sockfd)
 {
 	int err;
 
-	sockfd = start_reuseport_server(AF_INET6, SOCK_DGRAM, NULL,
-					DUT_ECHO_PORT, 0, 1);
-	if (!sockfd) {
+	*sockfd = start_server(SOCK_DGRAM, DUT_ECHO_PORT);
+	if (*sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating data UDP socket on device %s\n",
 			env.ifname);
@@ -269,7 +324,7 @@ static int dut_run_echo_thread(pthread_t *t, int *sockfd)
 		fprintf(stderr,
 			"Failed creating data UDP thread on device %s: %s\n",
 			env.ifname, strerror(-err));
-		free_fds(sockfd, 1);
+		close(*sockfd);
 		return -EINVAL;
 	}
 
@@ -361,25 +416,25 @@ static int recv_msg(int sockfd, void *buf, size_t bufsize, void *val,
 static int dut_run(struct xdp_features *skel)
 {
 	int flags = XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE;
-	int state, err = 0, *sockfd, ctrl_sockfd, echo_sockfd;
+	int state = CMD_STOP, err = 0, sockfd, ctrl_sockfd, echo_sockfd;
 	struct sockaddr_storage ctrl_addr;
 	pthread_t dut_thread = 0;
-	socklen_t addrlen;
+	socklen_t addrlen = sizeof(ctrl_addr);
 
-	sockfd = start_reuseport_server(AF_INET6, SOCK_STREAM, NULL,
-					DUT_CTRL_PORT, 0, 1);
-	if (!sockfd) {
+	sockfd = start_server(SOCK_STREAM, DUT_CTRL_PORT);
+	if (sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating control socket on device %s\n", env.ifname);
 		return -errno;
 	}
+	ksft_ready();
 
-	ctrl_sockfd = accept(*sockfd, (struct sockaddr *)&ctrl_addr, &addrlen);
+	ctrl_sockfd = accept(sockfd, (struct sockaddr *)&ctrl_addr, &addrlen);
 	if (ctrl_sockfd < 0) {
 		fprintf(stderr,
 			"Failed accepting connections on device %s control socket\n",
 			env.ifname);
-		free_fds(sockfd, 1);
+		close(sockfd);
 		return -errno;
 	}
 
@@ -488,7 +543,7 @@ static int dut_run(struct xdp_features *skel)
 out:
 	bpf_xdp_detach(env.ifindex, flags, NULL);
 	close(ctrl_sockfd);
-	free_fds(sockfd, 1);
+	close(sockfd);
 
 	return err;
 }
@@ -636,13 +691,14 @@ static int tester_run(struct xdp_features *skel)
 	if (err)
 		goto out;
 
+	/* Collect results before cleanup traffic can reach the tester. */
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
diff --git a/tools/testing/selftests/bpf/xdp_features.h b/tools/testing/selftests/drivers/net/hw/xdp_features.h
similarity index 100%
rename from tools/testing/selftests/bpf/xdp_features.h
rename to tools/testing/selftests/drivers/net/hw/xdp_features.h
diff --git a/tools/testing/selftests/drivers/net/hw/xdp_features.py b/tools/testing/selftests/drivers/net/hw/xdp_features.py
new file mode 100755
index 000000000..5eeadf803
--- /dev/null
+++ b/tools/testing/selftests/drivers/net/hw/xdp_features.py
@@ -0,0 +1,109 @@
+#!/usr/bin/env python3
+# SPDX-License-Identifier: GPL-2.0
+
+"""Check that a device's advertised XDP features match its behavior."""
+
+import ipaddress
+from pathlib import Path
+import re
+import shlex
+
+from lib.py import bkg, cmd, ksft_eq, ksft_exit, ksft_run, NetDrvEpEnv
+
+
+ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*m")
+RESULT = re.compile(
+    r"Feature .*: \[(NOT )?DETECTED\]\[(NOT )?ADVERTISED\]"
+)
+
+
+def mapped_address(address):
+    """Return an IPv6 or IPv4-mapped IPv6 address for xdp_features."""
+    address = ipaddress.ip_address(address)
+    if address.version == 4:
+        return f"::ffff:{address}"
+    return str(address)
+
+
+def feature_command(binary, feature, dut_addr, tester_addr, ifname,
+                    tester=False):
+    args = [str(binary)]
+    if tester:
+        args.append("-t")
+    args += ["-f", feature, "-D", dut_addr]
+    if tester:
+        args += ["-C", dut_addr]
+    args += ["-T", tester_addr, ifname]
+    return shlex.join(args)
+
+
+def run_feature(cfg, feature, ipver):
+    if not cfg.addr_v[ipver]:
+        ipver = "4" if ipver == "6" else "6"
+    cfg.require_ipver(ipver)
+    dut_addr = mapped_address(cfg.addr_v[ipver])
+    tester_addr = mapped_address(cfg.remote_addr_v[ipver])
+
+    dut_cmd = feature_command(cfg.xdp_features, feature, dut_addr,
+                              tester_addr, cfg.ifname)
+    tester_cmd = feature_command(cfg.remote_xdp_features, feature, dut_addr,
+                                 tester_addr, cfg.remote_ifname, tester=True)
+
+    with bkg(dut_cmd, exit_wait=True, ksft_ready=True):
+        result = cmd(tester_cmd, host=cfg.remote)
+
+    output = ANSI_ESCAPE.sub("", result.stdout)
+    match = RESULT.search(output)
+    if not match:
+        raise Exception(f"Unable to parse xdp_features output: {output}")
+
+    detected = match.group(1) is None
+    advertised = match.group(2) is None
+    ksft_eq(detected, advertised,
+            comment=f"{feature}: detected and advertised support")
+
+
+def test_xdp_pass(cfg):
+    run_feature(cfg, "XDP_PASS", "6")
+
+
+def test_xdp_drop(cfg):
+    run_feature(cfg, "XDP_DROP", "4")
+
+
+def test_xdp_aborted(cfg):
+    run_feature(cfg, "XDP_ABORTED", "6")
+
+
+def test_xdp_tx(cfg):
+    run_feature(cfg, "XDP_TX", "4")
+
+
+def test_xdp_redirect(cfg):
+    run_feature(cfg, "XDP_REDIRECT", "6")
+
+
+def test_xdp_ndo_xmit(cfg):
+    run_feature(cfg, "XDP_NDO_XMIT", "4")
+
+
+def main():
+    with NetDrvEpEnv(__file__, nsim_test=False) as cfg:
+        cfg.xdp_features = (Path(__file__).parent / "xdp_features").resolve()
+        cfg.remote_xdp_features = cfg.remote.deploy(
+            cfg.xdp_features.as_posix()
+        )
+
+        ksft_run([
+            test_xdp_pass,
+            test_xdp_drop,
+            test_xdp_aborted,
+            test_xdp_tx,
+            test_xdp_redirect,
+            test_xdp_ndo_xmit,
+        ], args=(cfg,))
+    ksft_exit()
+
+
+if __name__ == "__main__":
+    main()

-- 
2.43.0

