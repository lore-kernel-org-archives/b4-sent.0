From: Bochao Cao <bochaolucky@gmail.com>
Date: Sun, 18 Oct 2026 22:05:51 +0800
Subject: [PATCH net-next v6 2/5] selftests/bpf: Track XDP test processes
 and isolate namespaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-xdp-v5-send-20261008-v6-2-7336e1282ca3@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792332371; l=10312;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=Ma+Q5a2YpvxxjtjYn33OkTL0G04LP0BT+h4trKbLTb0=;
 b=0wf1Lzv/Mb/MDuBYoYNN1K0pWa/6n03AdWqwKnXnZw/jFRxt5iB8KB1H1DF4lFmT1b8yesp4/
 8D64PsSZYS7DF7yhiddAvez3W5imKsE1mZ1zIuyZCyGBuZ7IJB3oBYn
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Track the DUT shell job and give each run separate DUT and tester
namespaces. Bound the readiness wait and handle signals during setup and
cleanup.

Filter tracepoint counters by this run's program and CPU map IDs. Return
failure when detected and advertised features differ.

Tested with two concurrent six-feature runs and three repeated-TERM
runs. All passed and left no helper processes or namespaces.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/progs/xdp_features.c |  18 +++-
 tools/testing/selftests/bpf/test_xdp_features.sh | 132 ++++++++++++++++++-----
 tools/testing/selftests/bpf/xdp_features.c       |  26 +++++
 3 files changed, 146 insertions(+), 30 deletions(-)

diff --git a/tools/testing/selftests/bpf/progs/xdp_features.c b/tools/testing/selftests/bpf/progs/xdp_features.c
index 67424084a38a1..07d1eaea5fbe5 100644
--- a/tools/testing/selftests/bpf/progs/xdp_features.c
+++ b/tools/testing/selftests/bpf/progs/xdp_features.c
@@ -2,10 +2,11 @@
 
 #include <stdbool.h>
 #include <linux/bpf.h>
 #include <linux/netdev.h>
 #include <bpf/bpf_helpers.h>
+#include <bpf/bpf_core_read.h>
 #include <bpf/bpf_endian.h>
 #include <bpf/bpf_tracing.h>
 #include <linux/if_ether.h>
 #include <linux/ip.h>
 #include <linux/ipv6.h>
@@ -20,11 +21,20 @@
 				 (a).s6_addr32[1] == (b).s6_addr32[1] &&	\
 				 (a).s6_addr32[2] == (b).s6_addr32[2] &&	\
 				 (a).s6_addr32[3] == (b).s6_addr32[3])
 
 struct net_device;
-struct bpf_prog;
+struct bpf_prog_aux {
+	__u32 id;
+} __attribute__((preserve_access_index));
+
+struct bpf_prog {
+	struct bpf_prog_aux *aux;
+} __attribute__((preserve_access_index));
+
+__u32 dut_prog_id;
+__u32 dut_cpumap_id;
 
 struct xdp_cpumap_stats {
 	unsigned int redirect;
 	unsigned int pass;
 	unsigned int drop;
@@ -226,10 +236,13 @@ SEC("tp_btf/xdp_exception")
 int BPF_PROG(xdp_exception, const struct net_device *dev,
 	     const struct bpf_prog *xdp, __u32 act)
 {
 	__u32 *val, key = 0;
 
+	if (!dut_prog_id || BPF_CORE_READ(xdp, aux, id) != dut_prog_id)
+		return 0;
+
 	val = bpf_map_lookup_elem(&dut_stats, &key);
 	if (val)
 		__sync_add_and_fetch(val, 1);
 
 	return 0;
@@ -239,10 +252,13 @@ SEC("tp_btf/xdp_cpumap_kthread")
 int BPF_PROG(tp_xdp_cpumap_kthread, int map_id, unsigned int processed,
 	     unsigned int drops, int sched, struct xdp_cpumap_stats *xdp_stats)
 {
 	__u32 *val, key = 0;
 
+	if (!dut_cpumap_id || map_id != dut_cpumap_id)
+		return 0;
+
 	val = bpf_map_lookup_elem(&dut_stats, &key);
 	if (val)
 		__sync_add_and_fetch(val, 1);
 
 	return 0;
diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
index 0aa71c4455c05..5b68b20d94ac9 100755
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ b/tools/testing/selftests/bpf/test_xdp_features.sh
@@ -1,107 +1,181 @@
 #!/bin/bash
 # SPDX-License-Identifier: GPL-2.0
 
 readonly NS="ns1-$(mktemp -u XXXXXX)"
+readonly DUT_NS="dut-${NS}"
 readonly V0_IP4=10.10.0.11
 readonly V1_IP4=10.10.0.1
 readonly V0_IP6=2001:db8::11
 readonly V1_IP6=2001:db8::1
 
 ret=1
+dut_pid=""
+peer_created=false
+dut_created=false
+setup_in_progress=true
+pending_signal=0
 
 setup() {
 	{
-		ip netns add ${NS}
-
-		ip link add v1 type veth peer name v0 netns ${NS}
-
-		ip link set v1 up
-		ip addr add $V1_IP4/24 dev v1
-		ip addr add $V1_IP6/64 nodad dev v1
+		[ ! -e "/run/netns/${NS}" ]
+		peer_created=true
+		ip netns add "${NS}"
+		[ ! -e "/run/netns/${DUT_NS}" ]
+		dut_created=true
+		ip netns add "${DUT_NS}"
+
+		ip -n "$DUT_NS" link add v1 type veth peer name v0 netns ${NS}
+
+		ip -n "$DUT_NS" link set v1 up
+		ip -n "$DUT_NS" addr add $V1_IP4/24 dev v1
+		ip -n "$DUT_NS" addr add $V1_IP6/64 nodad dev v1
 		ip -n ${NS} link set dev v0 up
 		ip -n ${NS} addr add $V0_IP4/24 dev v0
 		ip -n ${NS} addr add $V0_IP6/64 nodad dev v0
 
 		# Enable XDP mode and disable checksum offload
-		ethtool -K v1 gro on
-		ethtool -K v1 tx-checksumming off
+		ip netns exec "$DUT_NS" ethtool -K v1 gro on
+		ip netns exec "$DUT_NS" ethtool -K v1 tx-checksumming off
 		ip netns exec ${NS} ethtool -K v0 gro on
 		ip netns exec ${NS} ethtool -K v0 tx-checksumming off
 	} > /dev/null 2>&1
+	setup_in_progress=false
+	[ "$pending_signal" -eq 0 ] || exit "$pending_signal"
+}
+
+terminate_dut_server() {
+	local pid
+
+	# Use the shell job instead of dut_pid, which may not have been assigned
+	# yet if a signal arrived immediately after the server was started.
+	pid=$(jobs -pr 2> /dev/null) || true
+	if [ -z "$pid" ]; then
+		dut_pid=""
+		return
+	fi
+
+	kill -KILL %% 2> /dev/null || true
+	wait "$pid" 2> /dev/null || true
+	dut_pid=""
 }
 
 cleanup() {
-	ip link del v1 2> /dev/null
-	ip netns del ${NS} 2> /dev/null
-	[ "$(pidof xdp_features)" = "" ] || kill $(pidof xdp_features) 2> /dev/null
+	trap '' HUP INT QUIT ABRT TERM
+	trap - EXIT
+	terminate_dut_server
+	if "$dut_created"; then
+		ip netns del "$DUT_NS" 2> /dev/null || true
+	fi
+	if "$peer_created"; then
+		ip netns del "$NS" 2> /dev/null || true
+	fi
 }
 
 wait_for_dut_server() {
-	while sleep 1; do
-		ss -tlp | grep -q xdp_features
-		[ $? -eq 0 ] && break
+	local attempt
+
+	for ((attempt = 0; attempt < 30; attempt++)); do
+		if [ "$(jobs -pr 2> /dev/null)" != "$dut_pid" ]; then
+			echo "xdp_features server $dut_pid exited before readiness" >&2
+			return 1
+		fi
+
+		if ip netns exec "$DUT_NS" ss -tlp 2> /dev/null |
+		   grep -q "pid=$dut_pid,"; then
+			return 0
+		fi
+
+		sleep 1
 	done
+	echo "xdp_features server $dut_pid did not become ready" >&2
+	return 1
+}
+
+start_dut_server() {
+	ip netns exec "$DUT_NS" ./xdp_features "$@" &
+	dut_pid=$!
+	wait_for_dut_server
+}
+
+reap_dut_server() {
+	local status=0
+
+	wait "$dut_pid" || status=$?
+	dut_pid=""
+	return "$status"
 }
 
 test_xdp_features() {
 	setup
 
 	## XDP_PASS
-	./xdp_features -f XDP_PASS -D $V1_IP6 -T $V0_IP6 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_PASS -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_PASS \
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
+	reap_dut_server
 
 	## XDP_DROP
-	./xdp_features -f XDP_DROP -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_DROP -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_DROP \
 					   -D ::ffff:$V1_IP4 \
 					   -C ::ffff:$V1_IP4 \
 					   -T ::ffff:$V0_IP4 v0
 	[ $? -ne 0 ] && exit
+	reap_dut_server
 
 	## XDP_ABORTED
-	./xdp_features -f XDP_ABORTED -D $V1_IP6 -T $V0_IP6 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_ABORTED -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_ABORTED \
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
+	reap_dut_server
 
 	## XDP_TX
-	./xdp_features -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_TX \
 					   -D ::ffff:$V1_IP4 \
 					   -C ::ffff:$V1_IP4 \
 					   -T ::ffff:$V0_IP4 v0
 	[ $? -ne 0 ] && exit
+	reap_dut_server
 
 	## XDP_REDIRECT
-	./xdp_features -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_REDIRECT \
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
+	reap_dut_server
 
 	## XDP_NDO_XMIT
-	./xdp_features -f XDP_NDO_XMIT -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_NDO_XMIT -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_NDO_XMIT \
 					   -D ::ffff:$V1_IP4 \
 					   -C ::ffff:$V1_IP4 \
 					   -T ::ffff:$V0_IP4 v0
 	ret=$?
-	cleanup
+	reap_dut_server
+}
+
+handle_signal() {
+	if "$setup_in_progress"; then
+		pending_signal=$1
+	else
+		exit "$1"
+	fi
 }
 
 set -e
-trap cleanup 2 3 6 9
+trap cleanup EXIT
+trap 'handle_signal 129' HUP
+trap 'handle_signal 130' INT
+trap 'handle_signal 131' QUIT
+trap 'handle_signal 134' ABRT
+trap 'handle_signal 143' TERM
 
 test_xdp_features
 
 exit $ret
diff --git a/tools/testing/selftests/bpf/xdp_features.c b/tools/testing/selftests/bpf/xdp_features.c
index 3076fdda61fa4..97c0e871c5b65 100644
--- a/tools/testing/selftests/bpf/xdp_features.c
+++ b/tools/testing/selftests/bpf/xdp_features.c
@@ -665,17 +665,39 @@ static int tester_run(struct xdp_features *skel)
 
 	fprintf(stdout, "Feature %s: [%s][%s]\n", get_xdp_feature_str(),
 		detected_cap ? GREEN("DETECTED") : RED("NOT DETECTED"),
 		env.feature.drv_feature & advertised_feature ? GREEN("ADVERTISED")
 							     : RED("NOT ADVERTISED"));
+	if (!err && detected_cap != !!(env.feature.drv_feature & advertised_feature))
+		err = -EINVAL;
 out:
 	if (xdp_attached)
 		bpf_xdp_detach(env.ifindex, flags, NULL);
 	close(sockfd);
 	return err < 0 ? err : 0;
 }
 
+static int dut_set_trace_ids(struct xdp_features *skel)
+{
+	struct bpf_prog_info prog = {};
+	struct bpf_map_info map = {};
+	__u32 len = sizeof(prog);
+	int err;
+
+	err = bpf_prog_get_info_by_fd(bpf_program__fd(skel->progs.xdp_do_aborted),
+				      &prog, &len);
+	if (err)
+		return err;
+	len = sizeof(map);
+	err = bpf_map_get_info_by_fd(bpf_map__fd(skel->maps.cpu_map), &map, &len);
+	if (err)
+		return err;
+	skel->bss->dut_prog_id = prog.id;
+	skel->bss->dut_cpumap_id = map.id;
+	return 0;
+}
+
 int main(int argc, char **argv)
 {
 	struct xdp_features *skel;
 	int err;
 
@@ -714,10 +736,14 @@ int main(int argc, char **argv)
 	if (err) {
 		fprintf(stderr, "Failed to load and verify BPF skeleton\n");
 		goto cleanup;
 	}
 
+	err = dut_set_trace_ids(skel);
+	if (err)
+		goto cleanup;
+
 	err = xdp_features__attach(skel);
 	if (err) {
 		fprintf(stderr, "Failed to attach BPF skeleton\n");
 		goto cleanup;
 	}

-- 
Git-155)

