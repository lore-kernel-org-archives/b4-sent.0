From: Bochao Cao <bochaolucky@gmail.com>
Date: Fri, 04 Sep 2026 12:44:16 +0800
Subject: [PATCH net-next v3] selftests/bpf: Track test_xdp_features DUT
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-xdp-dut-process-lifecycle-gmail-v3-1-5b7eee4f7009@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42Oyw6DIBBFf8Ww7jSAj2pX/Y+mC4VBaXwF0GiM/
 16kG3ft8s7cOWc2YtFotOQebcTgrK0eeh/iS0REU/Y1gpY+E055RnOawiJHkJOD0QwCrYVWKxS
 raBHqrtQtZDKjlcqlkIoRTxkNKr0Ew5P06KDHxZHXd2On6o3CHYKj22jrBrOGZ2YWLv72zgwYJ
 GmRJ9LbeZE+wvwqhi7YZn7iMf6bxz2vojEqXpasKm5n3r7vHy+oWnY6AQAA
X-Change-ID: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1
To: Daniel Borkmann <daniel@iogearbox.net>, 
 Jakub Kicinski <kuba@kernel.org>
Cc: =?utf-8?q?Alexis_Lothor=C3=A9?= <alexis.lothore@bootlin.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 bpf@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Bochao Cao <bochaolucky@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788497071; l=6447;
 i=bochaolucky@gmail.com; s=20260805; h=from:subject:message-id;
 bh=I2n4a59uAKEvkbSso4YQc4bQe47kg2xl5vnB8E1CvlM=;
 b=p6gzwSNVBLab6wCc/Fk60sH5alBgRcLdhxrE9e+AFKFcFlF/7xCxhaTn/PP4yPX8ZnHMHoR7d
 +QVZsMgPQXlCeqzN22LC2kil+Pgo13uSEAutkJf3o7sfSPzzeysNRen
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
Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
Reviewed-by: Emil Tsalapatis <emil@etsalapatis.com>
---
Tests:
- bash -n tools/testing/selftests/bpf/test_xdp_features.sh
- make -C tools/testing/selftests/bpf xdp_features
- sudo tools/testing/selftests/bpf/test_xdp_features.sh
- verified cleanup terminates a blocked DUT without affecting an unrelated process
---
Changes in v3:
- Rebase onto net-next.
- Retarget the patch from bpf-next to net-next so the hardware-test
  migration can follow in the same tree without conflicts.
- Drop the Debian bug Closes tag; dependency cleanup can be handled
  independently by Debian.
- Add Emil's Reviewed-by tag.
- Link to v2: https://patch.msgid.link/20260812-xdp-dut-process-lifecycle-gmail-v2-1-b03ef2aa1b97@gmail.com

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
base-commit: 6ebcf5074cff0402730c6981d2397139fee6322d
change-id: 20260805-xdp-dut-process-lifecycle-gmail-6d60bf8dcdf1

Best regards,
--  
Bochao Cao <bochaolucky@gmail.com>

