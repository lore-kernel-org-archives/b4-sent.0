From: Bochao Cao <bochaolucky@gmail.com>
Date: Sat, 10 Oct 2026 18:22:46 +0800
Subject: [PATCH net-next v5 2/5] selftests/bpf: Track XDP test processes
 and isolate namespaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-xdp-v5-send-20261008-v5-2-de687cb67c40@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627780; l=6201;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=qWufqBCzlAQK5TriZ7+XYMaHjEHbAtfOKvQxbtjZ2oM=;
 b=CJaVwcrdJzaweF+SNtOuq2e3yftBSMlhmZM1DqNh1rFL4gZWwNQoN2CGpOq3KXI+6OMDsODxp
 wwt3kb5/LoXBOAKg6sb5pNZ1BpYL9jsyLA134UC3pvWA0Yw+wNferaA
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Track the DUT shell job so cleanup does not kill other test instances.
Wait for readiness while the DUT is alive.

Give each run separate DUT and tester namespaces to avoid name, address
and port conflicts. Handle signals during setup and ignore repeated
signals during cleanup.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/bpf/test_xdp_features.sh | 122 ++++++++++++++++++-----
 1 file changed, 95 insertions(+), 27 deletions(-)

diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
index 0aa71c4455c05..7b96222b690a6 100755
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ b/tools/testing/selftests/bpf/test_xdp_features.sh
@@ -1,107 +1,175 @@
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
+		ip netns add "${NS}"
+		peer_created=true
+		ip netns add "${DUT_NS}"
+		dut_created=true
 
-		ip link add v1 type veth peer name v0 netns ${NS}
+		ip -n "$DUT_NS" link add v1 type veth peer name v0 netns ${NS}
 
-		ip link set v1 up
-		ip addr add $V1_IP4/24 dev v1
-		ip addr add $V1_IP6/64 nodad dev v1
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
+	pid=$(jobs -pr %% 2> /dev/null) || true
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
+	trap - EXIT
+	trap '' HUP INT QUIT ABRT TERM
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
+	while true; do
+		if [ "$(jobs -pr %% 2> /dev/null)" != "$dut_pid" ]; then
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
 }
 
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
+}
+
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

-- 
Git-155)

