From: Bochao Cao <bochaolucky@gmail.com>
Date: Wed, 12 Aug 2026 16:28:58 +0800
Subject: [PATCH bpf-next v2] selftests/bpf: Track test_xdp_features DUT
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-xdp-dut-process-lifecycle-gmail-v2-1-b03ef2aa1b97@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMoufGoC/42OQQ6DIBBFr9LMutMAUaNd9R6NC4VBaVQIoNEY7
 16lF+jyzfw/b3YI5A0FeN528LSYYOx0grjfQPbN1BEadTIIJgpWshxX5VDNEZ23kkLAwWiSmxw
 Iu7ExAxaqYK0ulVSaw3nFedJmTYY3tE7jRGuE+rcJc/shGS/Ble1NiNZv6ZmFp8bf3oUjxyyvy
 kyddlHlrzR/SDtCfRzHF7hPg/HqAAAA
X-Change-ID: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>
Cc: Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>, 
 bpf@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bochao Cao <bochaolucky@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786523357; l=6026;
 i=bochaolucky@gmail.com; s=20260805; h=from:subject:message-id;
 bh=pnFTax/Yu2UV2jh6eNQ9vvm+LoTOT+3qy7HlP2VL2dQ=;
 b=yooaFasxTq0Yi1a20cpTr61x200gih6rk2OrmxxSihec40KiqUM5goKCyXzw3uL2oFQoK6jn3
 79q0Rn6BaRBDhz93vamJePCUkg7Cy3bvl1YlGPSiiHGW1NdSVEZ1s25
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/20260805 with auth_id=920
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

test_xdp_features.sh waits for any xdp_features listener to appear and
uses pidof during cleanup. A concurrent test can therefore make another
test proceed before its own DUT is ready, and cleanup kills every
xdp_features process on the host. The readiness loop also has no timeout,
so a DUT that exits before listening leaves the test hung indefinitely.

Track one active DUT at a time, wait for ss to report that exact PID with
a bounded retry loop, and reap it after each test. Consult the shell job
table before signaling the DUT so a stale PID cannot target an unrelated
process. On failure, terminate the shell job with SIGKILL and reap it so
blocked I/O cannot hang cleanup. Install an EXIT trap and signal handlers
so failure paths also remove network setup.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Closes: https://bugs.debian.org/1136522
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
Tests:
- bash -n tools/testing/selftests/bpf/test_xdp_features.sh
- make -C tools/testing/selftests/bpf xdp_features
- sudo tools/testing/selftests/bpf/test_xdp_features.sh
- verified cleanup terminates a blocked DUT without affecting an unrelated process
---
Changes in v2:
- Clarify that avoiding name-wide process matching, rather than dropping a dependency, is the motivation.
- Track and reap one active DUT at a time instead of retaining historical PIDs.
- Address PID reuse by signaling only the current Bash job during cleanup.
- Use SIGKILL on failure cleanup so blocked DUT I/O cannot hang wait indefinitely.
- Link to v1: https://patch.msgid.link/20260805-xdp-dut-process-lifecycle-gmail-v1-1-45984df8d295@gmail.com
---
 tools/testing/selftests/bpf/test_xdp_features.sh | 82 ++++++++++++++++++------
 1 file changed, 62 insertions(+), 20 deletions(-)

diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
index 0aa71c4455c0..35ce0d4e2418 100755
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ b/tools/testing/selftests/bpf/test_xdp_features.sh
@@ -8,6 +8,7 @@ readonly V0_IP6=2001:db8::11
 readonly V1_IP6=2001:db8::1
 
 ret=1
+dut_pid=""
 
 setup() {
 	{
@@ -30,77 +31,118 @@ setup() {
 	} > /dev/null 2>&1
 }
 
+terminate_dut_server() {
+	[ -z "$dut_pid" ] && return
+
+	# Use the shell job instead of a PID which may have been reused.
+	if [ "$(jobs -pr %% 2> /dev/null)" = "$dut_pid" ]; then
+		kill -KILL %% 2> /dev/null || true
+	fi
+
+	wait "$dut_pid" 2> /dev/null || true
+	dut_pid=""
+}
+
 cleanup() {
-	ip link del v1 2> /dev/null
-	ip netns del ${NS} 2> /dev/null
-	[ "$(pidof xdp_features)" = "" ] || kill $(pidof xdp_features) 2> /dev/null
+	terminate_dut_server
+	ip link del v1 2> /dev/null || true
+	ip netns del "${NS}" 2> /dev/null || true
 }
 
 wait_for_dut_server() {
-	while sleep 1; do
-		ss -tlp | grep -q xdp_features
-		[ $? -eq 0 ] && break
+	local i
+
+	for ((i = 0; i < 10; i++)); do
+		if [ "$(jobs -pr %% 2> /dev/null)" != "$dut_pid" ]; then
+			echo "xdp_features server $dut_pid exited before accepting connections" >&2
+			return 1
+		fi
+
+		if ss -tlp 2> /dev/null | grep -q "pid=$dut_pid,"; then
+			return 0
+		fi
+
+		sleep 1
 	done
+
+	echo "Timed out waiting for xdp_features server $dut_pid" >&2
+	return 1
+}
+
+start_dut_server() {
+	./xdp_features "$@" &
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
 }
 
 set -e
-trap cleanup 2 3 6 9
+trap cleanup EXIT
+trap 'exit 129' HUP
+trap 'exit 130' INT
+trap 'exit 143' TERM
 
 test_xdp_features
 

---
base-commit: 07cb86aa50816b070b99c89bf948762ef035a1f2
change-id: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1

Best regards,
--  
Bochao Cao <bochaolucky@gmail.com>

