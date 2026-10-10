From: Bochao Cao <bochaolucky@gmail.com>
Date: Sat, 10 Oct 2026 18:22:49 +0800
Subject: [PATCH net-next v5 5/5] selftests/net: Move the XDP feature test
 to drivers/net/hw
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-xdp-v5-send-20261008-v5-5-de687cb67c40@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627780; l=19096;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=pqso4AVXoPi+9kxs99MPWGMShGSc0/24fbtC32buU4s=;
 b=XTIGISG8z1XFr0mEP426o6oHP55ngVUSIZeAMrCiNQSA6fPZnsFrvxzaAh9zznQSeH0zF/J9p
 LT2A2XF8C6xBITv/MUC7Vpv0T/aBsR79HpSLyTu6fdsndeomucY8vec
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the private-veth script with a NetDrvEpEnv test for a local DUT
and remote tester. Build the helper with the shared BPF rules and
installed kernel headers.

Check detected features against advertised support. Skip unsupported
native XDP and veth XDP_TX without a peer XDP program. Wait for DUT
readiness and run the remote helper under timeout.

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/Makefile               |   9 +-
 tools/testing/selftests/bpf/test_xdp_features.sh   | 169 ---------------------
 tools/testing/selftests/drivers/net/README.rst     |  18 +++
 tools/testing/selftests/drivers/net/hw/.gitignore  |   3 +
 tools/testing/selftests/drivers/net/hw/Makefile    |  15 +-
 tools/testing/selftests/drivers/net/hw/config      |   3 +
 .../net/hw/xdp_features.bpf.c}                     |   0
 .../{bpf => drivers/net/hw}/xdp_features.c         |   2 +
 .../{bpf => drivers/net/hw}/xdp_features.h         |   0
 .../selftests/drivers/net/hw/xdp_features.py       | 137 +++++++++++++++++
 10 files changed, 178 insertions(+), 178 deletions(-)

diff --git a/tools/testing/selftests/bpf/Makefile b/tools/testing/selftests/bpf/Makefile
index 883c92701b9f1..cb76b68c97dbb 100644
--- a/tools/testing/selftests/bpf/Makefile
+++ b/tools/testing/selftests/bpf/Makefile
@@ -124,11 +124,11 @@ TEST_FILES = xsk_prereqs.sh $(wildcard progs/btf_dump_test_case_*.c)
 TEST_PROGS := test_kmod.sh \
 	test_lirc_mode2.sh \
 	test_bpftool_build.sh \
 	test_doc_build.sh \
 	test_xsk.sh \
-	test_xdp_features.sh
+	#
 
 TEST_PROGS_EXTENDED := \
 	ima_setup.sh verify_sig_setup.sh
 
 TEST_KMODS := bpf_testmod.ko bpf_test_no_cfi.ko bpf_test_modorder_x.ko \
@@ -140,11 +140,10 @@ TEST_GEN_PROGS_EXTENDED = \
 	bench \
 	flow_dissector_load \
 	test_cpp \
 	test_lirc_mode2_user \
 	veristat \
-	xdp_features \
 	xdp_hw_metadata \
 	xdp_synproxy \
 	xskxceiver
 
 TEST_GEN_FILES += $(TEST_KMODS) liburandom_read.so urandom_read sign-file uprobe_multi
@@ -542,11 +541,10 @@ linked_maps.skel.h-deps := linked_maps1.bpf.o linked_maps2.bpf.o
 test_subskeleton.skel.h-deps := test_subskeleton_lib2.bpf.o test_subskeleton_lib.bpf.o test_subskeleton.bpf.o
 test_subskeleton_lib.skel.h-deps := test_subskeleton_lib2.bpf.o test_subskeleton_lib.bpf.o
 test_usdt.skel.h-deps := test_usdt.bpf.o test_usdt_multispec.bpf.o
 xsk_xdp_progs.skel.h-deps := xsk_xdp_progs.bpf.o
 xdp_hw_metadata.skel.h-deps := xdp_hw_metadata.bpf.o
-xdp_features.skel.h-deps := xdp_features.bpf.o
 tracing_multi.skel.h-deps := tracing_multi_attach.bpf.o tracing_multi_check.bpf.o
 tracing_multi_module.skel.h-deps := tracing_multi_attach_module.bpf.o tracing_multi_check.bpf.o
 tracing_multi_intersect.skel.h-deps := tracing_multi_intersect_attach.bpf.o tracing_multi_check.bpf.o
 tracing_multi_session.skel.h-deps := tracing_multi_session_attach.bpf.o tracing_multi_check.bpf.o
 
@@ -945,15 +943,10 @@ $(OUTPUT)/xdp_hw_metadata: xdp_hw_metadata.c xsk.c network_helpers.c \
 			   xsk.h network_helpers.h test_progs.h bpf_util.h \
 			   $(OUTPUT)/xdp_hw_metadata.skel.h $(BPFOBJ) | $(OUTPUT)
 	$(call msg,BINARY,,$@)
 	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
 
-$(OUTPUT)/xdp_features: xdp_features.c xdp_features.h \
-			   $(OUTPUT)/xdp_features.skel.h $(BPFOBJ) | $(OUTPUT)
-	$(call msg,BINARY,,$@)
-	$(Q)$(CC) $(CFLAGS) $(filter %.a %.o %.c,$^) $(LDLIBS) -o $@
-
 # Make sure we are able to include and link libbpf against c++.
 CXXFLAGS += $(CFLAGS)
 CXXFLAGS := $(subst -D_GNU_SOURCE=,,$(CXXFLAGS))
 CXXFLAGS := $(subst -std=gnu11,-std=gnu++11,$(CXXFLAGS))
 $(OUTPUT)/test_cpp: test_cpp.cpp $(OUTPUT)/test_core_extern.skel.h $(BPFOBJ)
diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
deleted file mode 100755
index a28021ba74726..0000000000000
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ /dev/null
@@ -1,169 +0,0 @@
-#!/bin/bash
-# SPDX-License-Identifier: GPL-2.0
-
-readonly NS="ns1-$(mktemp -u XXXXXX)"
-readonly DUT_NS="dut-${NS}"
-readonly V0_IP4=10.10.0.11
-readonly V1_IP4=10.10.0.1
-readonly V0_IP6=2001:db8::11
-readonly V1_IP6=2001:db8::1
-
-ret=1
-dut_pid=""
-peer_created=false
-dut_created=false
-setup_in_progress=true
-pending_signal=0
-
-setup() {
-	{
-		ip netns add "${NS}"
-		peer_created=true
-		ip netns add "${DUT_NS}"
-		dut_created=true
-
-		ip -n "$DUT_NS" link add v1 type veth peer name v0 netns ${NS}
-
-		ip -n "$DUT_NS" link set v1 up
-		ip -n "$DUT_NS" addr add $V1_IP4/24 dev v1
-		ip -n "$DUT_NS" addr add $V1_IP6/64 nodad dev v1
-		ip -n ${NS} link set dev v0 up
-		ip -n ${NS} addr add $V0_IP4/24 dev v0
-		ip -n ${NS} addr add $V0_IP6/64 nodad dev v0
-
-		# Enable XDP mode and disable checksum offload
-		ip netns exec "$DUT_NS" ethtool -K v1 gro on
-		ip netns exec "$DUT_NS" ethtool -K v1 tx-checksumming off
-		ip netns exec ${NS} ethtool -K v0 gro on
-		ip netns exec ${NS} ethtool -K v0 tx-checksumming off
-	} > /dev/null 2>&1
-	setup_in_progress=false
-	[ "$pending_signal" -eq 0 ] || exit "$pending_signal"
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
-	trap - EXIT
-	trap '' HUP INT QUIT ABRT TERM
-	terminate_dut_server
-	if "$dut_created"; then
-		ip netns del "$DUT_NS" 2> /dev/null || true
-	fi
-	if "$peer_created"; then
-		ip netns del "$NS" 2> /dev/null || true
-	fi
-}
-
-wait_for_dut_server() {
-	while true; do
-		if [ "$(jobs -pr %% 2> /dev/null)" != "$dut_pid" ]; then
-			echo "xdp_features server $dut_pid exited before readiness" >&2
-			return 1
-		fi
-
-		if ip netns exec "$DUT_NS" ss -tlp 2> /dev/null |
-		   grep -q "pid=$dut_pid,"; then
-			return 0
-		fi
-
-		sleep 1
-	done
-}
-
-start_dut_server() {
-	ip netns exec "$DUT_NS" ./xdp_features "$@" &
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
-	# veth only flushes XDP_TX to a peer with native XDP attached.
-	echo "SKIP: XDP_TX needs a peer native XDP program"
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
-handle_signal() {
-	if "$setup_in_progress"; then
-		pending_signal=$1
-	else
-		exit "$1"
-	fi
-}
-
-set -e
-trap cleanup EXIT
-trap 'handle_signal 129' HUP
-trap 'handle_signal 130' INT
-trap 'handle_signal 131' QUIT
-trap 'handle_signal 134' ABRT
-trap 'handle_signal 143' TERM
-
-test_xdp_features
-
-exit $ret
diff --git a/tools/testing/selftests/drivers/net/README.rst b/tools/testing/selftests/drivers/net/README.rst
index 3fe49bce4f3a5..0791f02ba44b4 100644
--- a/tools/testing/selftests/drivers/net/README.rst
+++ b/tools/testing/selftests/drivers/net/README.rst
@@ -308,5 +308,23 @@ The code should be clean, avoid disabling pylint warnings explicitly!
 Running tests CI-style
 ======================
 
 See https://github.com/linux-netdev/nipa/wiki for instructions on how
 to easily run the tests using ``virtme-ng``.
+
+XDP feature test
+===============
+
+``hw/xdp_features.py`` compares the DUT's advertised XDP capabilities with
+packet observations. The endpoints must be directly connected at layer 2.
+The remote helper needs packet-socket privileges and GNU ``timeout``, but
+does not load BPF, attach XDP, or change interface/offload settings.
+Probe checksums are computed in software; TX checksum offload may remain
+at its configured value on both endpoints.
+
+A DUT without advertised native XDP support is skipped. On veth,
+``XDP_TX`` additionally requires an existing native XDP program on the
+peer, because veth only flushes its peer receive ring in that case.
+Without this prerequisite the TX subtest is skipped; the test does not
+change the shared remote endpoint to enable it. Other advertised versus
+observed mismatches are failures, including unsupported features that
+unexpectedly work.
diff --git a/tools/testing/selftests/drivers/net/hw/.gitignore b/tools/testing/selftests/drivers/net/hw/.gitignore
index 46540468a7753..a0cd8bc3739d8 100644
--- a/tools/testing/selftests/drivers/net/hw/.gitignore
+++ b/tools/testing/selftests/drivers/net/hw/.gitignore
@@ -1,4 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0-only
 iou-zcrx
 ncdevmem
 toeplitz
+tools/
+xdp_features
+xdp_features.skel.h
diff --git a/tools/testing/selftests/drivers/net/hw/Makefile b/tools/testing/selftests/drivers/net/hw/Makefile
index 18ce235a77f84..bd818e8625c23 100644
--- a/tools/testing/selftests/drivers/net/hw/Makefile
+++ b/tools/testing/selftests/drivers/net/hw/Makefile
@@ -49,10 +49,11 @@ TEST_PROGS = \
 	toeplitz.py \
 	tso.py \
 	userns_devmem.py \
 	uso.py \
 	vlan.py \
+	xdp_features.py \
 	xdp_metadata.py \
 	xsk_reconfig.py \
 	#
 
 TEST_PROGS_EXTENDED := \
@@ -77,11 +78,11 @@ TEST_INCLUDES := \
 YNL_GEN_FILES := \
 	ncdevmem \
 	toeplitz \
 	$(COND_GEN_FILES) \
 # end of YNL_GEN_FILES
-TEST_GEN_FILES += $(YNL_GEN_FILES)
+TEST_GEN_FILES += $(YNL_GEN_FILES) xdp_features
 TEST_GEN_FILES += $(patsubst %.c,%.o,$(wildcard *.bpf.c))
 
 include ../../../lib.mk
 
 # YNL build
@@ -92,8 +93,20 @@ YNL_GENS := \
 
 include ../../../net/ynl.mk
 
 include ../../../net/bpf.mk
 
+$(OUTPUT)/xdp_features.bpf.o: xdp_features.h
+
+$(OUTPUT)/xdp_features: CFLAGS += -I$(OUTPUT) -I$(SCRATCH_DIR)/include
+$(OUTPUT)/xdp_features: CFLAGS += -I../../../net/lib
+$(OUTPUT)/xdp_features: LDLIBS += -lelf -lz -lpthread
+$(OUTPUT)/xdp_features: xdp_features.c xdp_features.h \
+			   $(OUTPUT)/xdp_features.skel.h $(BPFOBJ)
+	$(call msg,BINARY,,$@)
+	$(Q)$(CC) $(CFLAGS) $(CPPFLAGS) $(KHDR_INCLUDES) \
+		$(filter %.c %.o,$^) $(BPFOBJ) \
+		$(LDFLAGS) $(LDLIBS) -o $@
+
 ifeq ($(HAS_IOURING_ZCRX),y)
 $(OUTPUT)/iou-zcrx: LDLIBS += -luring -lpthread
 endif
diff --git a/tools/testing/selftests/drivers/net/hw/config b/tools/testing/selftests/drivers/net/hw/config
index c6c2b64bb7124..14a8041b468ba 100644
--- a/tools/testing/selftests/drivers/net/hw/config
+++ b/tools/testing/selftests/drivers/net/hw/config
@@ -1,6 +1,8 @@
+CONFIG_BPF_EVENTS=y
 CONFIG_BPF_SYSCALL=y
+CONFIG_DEBUG_INFO_BTF=y
 CONFIG_FAIL_FUNCTION=y
 CONFIG_FAULT_INJECTION=y
 CONFIG_FAULT_INJECTION_DEBUG_FS=y
 CONFIG_FUNCTION_ERROR_INJECTION=y
 CONFIG_HUGETLBFS=y
@@ -19,10 +21,11 @@ CONFIG_NET_DEVMEM=y
 CONFIG_NET_IPGRE=y
 CONFIG_NET_IPGRE_DEMUX=y
 CONFIG_NET_IPIP=y
 CONFIG_NETKIT=y
 CONFIG_NET_SCH_INGRESS=y
+CONFIG_PACKET=y
 CONFIG_SYNC_FILE=y
 CONFIG_UDMABUF=y
 CONFIG_USER_NS=y
 CONFIG_VLAN_8021Q=m
 CONFIG_VXLAN=y
diff --git a/tools/testing/selftests/bpf/progs/xdp_features.c b/tools/testing/selftests/drivers/net/hw/xdp_features.bpf.c
similarity index 100%
rename from tools/testing/selftests/bpf/progs/xdp_features.c
rename to tools/testing/selftests/drivers/net/hw/xdp_features.bpf.c
diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/drivers/net/hw/xdp_features.c
similarity index 99%
rename from tools/testing/selftests/bpf/xdp_features.c
rename to tools/testing/selftests/drivers/net/hw/xdp_features.c
index 521c0e24a27ca..6aa5ac902448a 100644
--- a/tools/testing/selftests/bpf/xdp_features.c
+++ b/tools/testing/selftests/drivers/net/hw/xdp_features.c
@@ -27,10 +27,11 @@
 #include <unistd.h>
 #include <arpa/inet.h>
 #include <bpf/bpf.h>
 #include <bpf/libbpf.h>
 
+#include "ksft.h"
 #include "xdp_features.skel.h"
 #include "xdp_features.h"
 
 #define RED(str)	"\033[0;31m" str "\033[0m"
 #define GREEN(str)	"\033[0;32m" str "\033[0m"
@@ -478,10 +479,11 @@ static int dut_run(struct xdp_features *skel)
 	if (sockfd < 0) {
 		fprintf(stderr,
 			"Failed creating control socket on device %s\n", env.ifname);
 		return -errno;
 	}
+	ksft_ready();
 
 	/* Allow remote startup and BPF loading on slow test machines. */
 	ctrl_sockfd = -1;
 	for (attempt = 0; attempt < 20 && !should_exit(); attempt++) {
 		addrlen = sizeof(ctrl_addr);
diff --git a/tools/testing/selftests/bpf/xdp_features.h b/tools/testing/selftests/drivers/net/hw/xdp_features.h
similarity index 100%
rename from tools/testing/selftests/bpf/xdp_features.h
rename to tools/testing/selftests/drivers/net/hw/xdp_features.h
diff --git a/tools/testing/selftests/drivers/net/hw/xdp_features.py b/tools/testing/selftests/drivers/net/hw/xdp_features.py
new file mode 100755
index 0000000000000..1d59772b2a4d0
--- /dev/null
+++ b/tools/testing/selftests/drivers/net/hw/xdp_features.py
@@ -0,0 +1,137 @@
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
+from lib.py import bkg, cmd, ip, ksft_eq, ksft_exit, ksft_run, NetDrvEpEnv
+from lib.py import KsftFailEx, KsftSkipEx
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
+    """Build the helper command with the configured endpoint addresses."""
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
+    """Run one feature with bounded helper lifetimes and verify its result."""
+    cfg.require_cmd("timeout", local=False, remote=True)
+    probe = cmd(shlex.join([str(cfg.xdp_features), "-q", cfg.ifname]),
+                fail=False)
+    if probe.ret == 4:
+        raise KsftSkipEx(f"{cfg.ifname} does not advertise native XDP")
+    if probe.ret:
+        raise KsftFailEx(f"Unable to query XDP support: {probe}")
+    if feature == "XDP_TX":
+        link = ip(f"-d link show dev {cfg.ifname}", json=True)[0]
+        if link.get("linkinfo", {}).get("info_kind") == "veth":
+            peer = ip(f"-d link show dev {cfg.remote_ifname}", json=True,
+                      host=cfg.remote)[0]
+            # veth_xdp_flush() only schedules a peer with native XDP.
+            if peer.get("xdp", {}).get("mode") != 1:
+                raise KsftSkipEx("veth XDP_TX needs an existing peer native "
+                                 "XDP program to flush its receive ring")
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
+        # Bound the remote process itself, not just the local SSH wait.
+        result = cmd(f"timeout --signal=TERM --kill-after=5 90 {tester_cmd}",
+                     host=cfg.remote, timeout=100)
+
+    output = ANSI_ESCAPE.sub("", result.stdout)
+    match = RESULT.search(output)
+    if not match:
+        raise KsftFailEx(f"Unable to parse xdp_features output: {output}")
+
+    detected = match.group(1) is None
+    advertised = match.group(2) is None
+    ksft_eq(detected, advertised,
+            comment=f"{feature}: detected and advertised support")
+
+
+def test_xdp_pass(cfg):
+    """Check XDP_PASS detection against the advertised capability."""
+    run_feature(cfg, "XDP_PASS", "6")
+
+
+def test_xdp_drop(cfg):
+    """Check XDP_DROP detection against the advertised capability."""
+    run_feature(cfg, "XDP_DROP", "4")
+
+
+def test_xdp_aborted(cfg):
+    """Check XDP_ABORTED detection against the advertised capability."""
+    run_feature(cfg, "XDP_ABORTED", "6")
+
+
+def test_xdp_tx(cfg):
+    """Check XDP_TX detection against the advertised capability."""
+    run_feature(cfg, "XDP_TX", "4")
+
+
+def test_xdp_redirect(cfg):
+    """Check XDP_REDIRECT detection against the advertised capability."""
+    run_feature(cfg, "XDP_REDIRECT", "6")
+
+
+def test_xdp_ndo_xmit(cfg):
+    """Check XDP_NDO_XMIT detection against the advertised capability."""
+    run_feature(cfg, "XDP_NDO_XMIT", "4")
+
+
+def main():
+    """Deploy the helper and run the six feature checks."""
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
Git-155)

