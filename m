From: Bochao Cao <bochaolucky@gmail.com>
Date: Wed, 05 Aug 2026 15:29:42 +0800
Subject: [PATCH bpf-next] selftests/bpf: Track test_xdp_features DUT
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-xdp-dut-process-lifecycle-gmail-v1-1-45984df8d295@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQrCMBAAv1L27EJaMBS/Ih7a3U1diWlIUomU/
 t2ox2FgZocsSSXDpdshyUuzrqFBf+qA7lNYBJUbw2AGa0ZzxsoReSsY00qSM3p1Qm/ygstzUo+
 WrZndyMSuh1aJSZzW3+EKc3QYpBa4/U3e5odQ+Q7gOD6htoNVjQAAAA==
X-Change-ID: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>
Cc: Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, bpf@vger.kernel.org, 
 netdev@vger.kernel.org, Bochao Cao <bochaolucky@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785914999; l=4986;
 i=bochaolucky@gmail.com; s=20260805; h=from:subject:message-id;
 bh=2PX0a8BnWsRv3IzbYZsE6aRgPFWWou64hmODJGIhqFk=;
 b=G+ama6iOK6PZpitgtc3PszYOiC+EWiymrju6cQy/uyhX0yJ87JwgGGwizfCUE/hjAD0Rq9mIm
 jEaicJZFRvKBya927CRm6Cs4PF7/TdUYZFjFwIU6lETjqkGK0H7pPiU
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/20260805 with auth_id=920
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

test_xdp_features.sh waits for any xdp_features listener to appear and
uses pidof during cleanup. A concurrent test can therefore make another
test proceed before its own DUT is ready, and cleanup kills every
xdp_features process on the host. The readiness loop also has no timeout,
so a DUT that exits before listening leaves the test hung indefinitely.

Record each DUT PID when it is spawned, wait for ss to report that exact
PID with a bounded retry loop, and only terminate and reap recorded
children. Install an EXIT trap and signal handlers so failure paths also
remove child processes and network setup.

This also removes the runtime dependency on pidof.

Fixes: 4dba3e7852b7 ("selftests/bpf: introduce XDP compliance test tool")
Closes: https://bugs.debian.org/1136522
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
Tests:
- bash -n tools/testing/selftests/bpf/test_xdp_features.sh
- make -C tools/testing/selftests/bpf xdp_features
- sudo tools/testing/selftests/bpf/test_xdp_features.sh
- verified cleanup leaves an unrelated xdp_features process running
---
 tools/testing/selftests/bpf/test_xdp_features.sh | 60 ++++++++++++++++--------
 1 file changed, 40 insertions(+), 20 deletions(-)

diff --git a/tools/testing/selftests/bpf/test_xdp_features.sh b/tools/testing/selftests/bpf/test_xdp_features.sh
index 0aa71c4..f3aa4d1 100755
--- a/tools/testing/selftests/bpf/test_xdp_features.sh
+++ b/tools/testing/selftests/bpf/test_xdp_features.sh
@@ -8,6 +8,7 @@ readonly V0_IP6=2001:db8::11
 readonly V1_IP6=2001:db8::1
 
 ret=1
+dut_pids=()
 
 setup() {
 	{
@@ -31,32 +32,53 @@ setup() {
 }
 
 cleanup() {
-	ip link del v1 2> /dev/null
-	ip netns del ${NS} 2> /dev/null
-	[ "$(pidof xdp_features)" = "" ] || kill $(pidof xdp_features) 2> /dev/null
+	for pid in "${dut_pids[@]}"; do
+		kill "$pid" 2> /dev/null || true
+		wait "$pid" 2> /dev/null || true
+	done
+	ip link del v1 2> /dev/null || true
+	ip netns del "${NS}" 2> /dev/null || true
 }
 
 wait_for_dut_server() {
-	while sleep 1; do
-		ss -tlp | grep -q xdp_features
-		[ $? -eq 0 ] && break
+	local pid=$1
+	local i
+
+	for ((i = 0; i < 10; i++)); do
+		if ! kill -0 "$pid" 2> /dev/null; then
+			echo "xdp_features server $pid exited before accepting connections" >&2
+			return 1
+		fi
+
+		if ss -tlp 2> /dev/null | grep -q "pid=$pid,"; then
+			return 0
+		fi
+
+		sleep 1
 	done
+
+	echo "Timed out waiting for xdp_features server $pid" >&2
+	return 1
+}
+
+start_dut_server() {
+	./xdp_features "$@" &
+	dut_pids+=("$!")
+	wait_for_dut_server "$!"
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
 
 	## XDP_DROP
-	./xdp_features -f XDP_DROP -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_DROP -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_DROP \
 					   -D ::ffff:$V1_IP4 \
 					   -C ::ffff:$V1_IP4 \
@@ -64,16 +86,14 @@ test_xdp_features() {
 	[ $? -ne 0 ] && exit
 
 	## XDP_ABORTED
-	./xdp_features -f XDP_ABORTED -D $V1_IP6 -T $V0_IP6 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_ABORTED -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_ABORTED \
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
 
 	## XDP_TX
-	./xdp_features -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_TX -D ::ffff:$V1_IP4 -T ::ffff:$V0_IP4 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_TX \
 					   -D ::ffff:$V1_IP4 \
 					   -C ::ffff:$V1_IP4 \
@@ -81,26 +101,26 @@ test_xdp_features() {
 	[ $? -ne 0 ] && exit
 
 	## XDP_REDIRECT
-	./xdp_features -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1 &
-	wait_for_dut_server
+	start_dut_server -f XDP_REDIRECT -D $V1_IP6 -T $V0_IP6 v1
 	ip netns exec ${NS} ./xdp_features -t -f XDP_REDIRECT \
 					   -D $V1_IP6 -C $V1_IP6 \
 					   -T $V0_IP6 v0
 	[ $? -ne 0 ] && exit
 
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
 }
 
 set -e
-trap cleanup 2 3 6 9
+trap cleanup EXIT
+trap 'exit 129' HUP
+trap 'exit 130' INT
+trap 'exit 143' TERM
 
 test_xdp_features
 

---
base-commit: 6655c409707ec8ce9ce0850ffe4fe02331fd4d9c
change-id: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1

Best regards,
--  
Bochao Cao <bochaolucky@gmail.com>

