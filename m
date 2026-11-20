From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:50 -0500
Subject: [PATCH 59/60] selftests/dax: test cpuset interaction with private
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-59-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=31064;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=EI6JxHWnX1E8lmDW0ZNNtbtjkB4kd9zr5bG7TLb7SPI=;
 b=azX2IoQ0k/rNrnRYN5r39xQCJPo2uC5yWshnAuSDxixMsQXyTBNlaYZD4aZPk+RcVCgh5zKpz
 Y8NszRWT5+yD9YPyNGFlSe6opcaFAZwfNfLk183+H5TRmWjAtvmQLmq
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test private nodes in cgroup-v2 cpusets with kmem_private_rebind_tool:
  - cpuset.mems may name a private node, a private-only request
    inherits the parent's common nodes, and ordinary allocations in the
    cpuset stay on common memory.
  - policies across cpuset.mems changes and task attachment: interleave
    and positional rebinds never reach private memory, and a private
    binding keeps its node while it is allowed, evacuates to common
    memory when it is revoked, and returns when it is restored.
  - policies across hotplug: a private binding falls back while its
    node is offline or common and resumes once the node is private
    again, and a common binding falls back when its node becomes
    private.

Run with DAX_KMEM_TEST_DEV=<daxX.Y|auto>. The rebind tests need two
common memory nodes.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 tools/testing/selftests/dax/.gitignore             |   1 +
 tools/testing/selftests/dax/Makefile               |   3 +
 tools/testing/selftests/dax/config                 |   1 +
 tools/testing/selftests/dax/kmem_private_cpuset.sh |  70 +++
 tools/testing/selftests/dax/kmem_private_rebind.sh | 301 +++++++++++++
 .../selftests/dax/kmem_private_rebind_tool.c       | 495 +++++++++++++++++++++
 tools/testing/selftests/dax/private_node_common.sh |  32 ++
 7 files changed, 903 insertions(+)

diff --git a/tools/testing/selftests/dax/.gitignore b/tools/testing/selftests/dax/.gitignore
index fce2950a4e05..bb9c006203d0 100644
--- a/tools/testing/selftests/dax/.gitignore
+++ b/tools/testing/selftests/dax/.gitignore
@@ -1,2 +1,3 @@
 # SPDX-License-Identifier: GPL-2.0-only
 kmem_private_policy_tool
+kmem_private_rebind_tool
diff --git a/tools/testing/selftests/dax/Makefile b/tools/testing/selftests/dax/Makefile
index 26473b640a4c..de1327f3a7a7 100644
--- a/tools/testing/selftests/dax/Makefile
+++ b/tools/testing/selftests/dax/Makefile
@@ -5,8 +5,11 @@ TEST_PROGS := dax-kmem-hotplug.sh
 TEST_PROGS += kmem_private.sh
 TEST_PROGS += kmem_private_services.sh
 TEST_PROGS += kmem_private_policy.sh
+TEST_PROGS += kmem_private_cpuset.sh
+TEST_PROGS += kmem_private_rebind.sh
 TEST_FILES := private_node_common.sh
 TEST_GEN_FILES := kmem_private_policy_tool
+TEST_GEN_FILES += kmem_private_rebind_tool
 
 CFLAGS += -Wall $(KHDR_INCLUDES)
 
diff --git a/tools/testing/selftests/dax/config b/tools/testing/selftests/dax/config
index 5436c4a195c8..54ef671020c5 100644
--- a/tools/testing/selftests/dax/config
+++ b/tools/testing/selftests/dax/config
@@ -7,3 +7,4 @@ CONFIG_COMPACTION=y
 CONFIG_MIGRATION=y
 CONFIG_MEMCG=y
 CONFIG_TRANSPARENT_HUGEPAGE=y
+CONFIG_CPUSETS=y
diff --git a/tools/testing/selftests/dax/kmem_private_cpuset.sh b/tools/testing/selftests/dax/kmem_private_cpuset.sh
new file mode 100755
index 000000000000..2ae64b973f01
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_cpuset.sh
@@ -0,0 +1,70 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Check that cgroup-v2 cpuset.mems may name a private kmem node without
+# exposing it to ordinary allocations.
+#
+# Needs root, DAX_KMEM_TEST_DEV=<daxX.Y|auto> (see private_node_common.sh),
+# one common memory node and the cgroup-v2 cpuset controller.
+
+# shellcheck disable=SC1091
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR"/../kselftest/ktap_helpers.sh
+. "$DIR"/private_node_common.sh
+
+TOOL="$DIR/kmem_private_rebind_tool"
+CG="$CGROOT/kmem-private-cpuset-$$"
+
+# shellcheck disable=SC2317 # invoked by the EXIT trap
+cleanup()
+{
+	pn_cpuset_cleanup "$CG"
+	pn_unbind_kmem_private
+}
+trap cleanup EXIT
+
+pn_setup
+[ -x "$TOOL" ] || pn_skip "kmem_private_rebind_tool not built"
+pn_find_common_nodes 1
+pn_require_mask_nodes "$PN" "${COMMON[0]}"
+pn_cpuset_cgroup "$CG"
+
+ktap_set_plan 4
+
+name="mixed common/private cpuset.mems is accepted"
+if echo "${COMMON[0]},$PN" > "$CG/cpuset.mems" 2>/dev/null &&
+   pn_nodelist_has "$(cat "$CG/cpuset.mems.effective")" "$PN"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="a private-only request keeps the node and inherits common memory"
+if echo "$PN" > "$CG/cpuset.mems" 2>/dev/null &&
+   pn_nodelist_has "$(cat "$CG/cpuset.mems")" "$PN" &&
+   pn_nodelist_has "$(cat "$CG/cpuset.mems.effective")" "$PN" &&
+   pn_nodelist_has "$(cat "$CG/cpuset.mems.effective")" "${COMMON[0]}"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="ordinary allocation in the cpuset stays on common memory"
+out=$(timeout 60 sh -c "echo \$\$ > '$CG/cgroup.procs'; exec '$TOOL' \
+	ordinary '$PN' '${COMMON[0]}' '${COMMON[0]}'")
+if [ "$out" = "private=0" ]; then
+	ktap_test_pass "$name"
+else
+	ktap_print_msg "$out"
+	ktap_test_fail "$name"
+fi
+
+name="removing the private node revokes it"
+if echo "${COMMON[0]}" > "$CG/cpuset.mems" 2>/dev/null &&
+   ! pn_nodelist_has "$(cat "$CG/cpuset.mems.effective")" "$PN"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+ktap_finished
diff --git a/tools/testing/selftests/dax/kmem_private_rebind.sh b/tools/testing/selftests/dax/kmem_private_rebind.sh
new file mode 100755
index 000000000000..5d39be04f179
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_rebind.sh
@@ -0,0 +1,301 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Check memory policies on private kmem memory while a cgroup-v2 cpuset is
+# reshaped, tasks move between cpusets, and the node is hotplugged. Each case
+# starts kmem_private_rebind_tool, changes the cpuset or the node, and sends
+# the tool SIGUSR1 to check where its memory went.
+#
+# Needs root, DAX_KMEM_TEST_DEV=<daxX.Y|auto> (see private_node_common.sh),
+# two common memory nodes and the cgroup-v2 cpuset controller.
+
+# shellcheck disable=SC1091
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR"/../kselftest/ktap_helpers.sh
+. "$DIR"/private_node_common.sh
+
+TOOL="$DIR/kmem_private_rebind_tool"
+CG="$CGROOT/kmem-private-rebind-$$"
+CGCOMMON="$CGROOT/kmem-private-rebind-common-$$"
+OUT=$(mktemp)
+
+# CHILD is the timeout wrapper and TARGET the tool, which may be its child.
+stop_tool()
+{
+	[ -n "${TARGET:-}" ] && kill "$TARGET" 2>/dev/null
+	[ -n "${CHILD:-}" ] && kill "$CHILD" 2>/dev/null
+	[ -n "${CHILD:-}" ] && wait "$CHILD" 2>/dev/null
+	TARGET=
+	CHILD=
+}
+
+# shellcheck disable=SC2317 # invoked by the EXIT trap
+cleanup()
+{
+	stop_tool
+	rm -f "$OUT"
+	pn_cpuset_cleanup "$CG" "$CGCOMMON"
+	pn_unbind_kmem_private
+}
+trap cleanup EXIT
+
+wait_output()
+{
+	local pattern=$1 i
+
+	for ((i = 0; i < 100; i++)); do
+		grep -q "$pattern" "$OUT" && return 0
+		kill -0 "$CHILD" 2>/dev/null || break
+		sleep 0.1
+	done
+	return 1
+}
+
+# Start the tool in mode $1, inside cgroup $2 if given, and wait until it is
+# ready for the first SIGUSR1.
+start_tool()
+{
+	local mode=$1 cg=${2:-}
+
+	: > "$OUT"
+	if [ -n "$cg" ]; then
+		timeout 60 sh -ec "echo \$\$ > '$cg/cgroup.procs'; exec '$TOOL' \
+			'$mode' '$PN' '${COMMON[0]}' '${COMMON[1]}'" > "$OUT" 2>&1 &
+	else
+		timeout 60 "$TOOL" "$mode" "$PN" "${COMMON[0]}" "${COMMON[1]}" \
+			> "$OUT" 2>&1 &
+	fi
+	CHILD=$!
+	wait_output '^ready pid=' || return 1
+	TARGET=$(sed -n 's/^ready pid=//p' "$OUT")
+}
+
+# Signal the tool to check stage $1 and report its result as test $2.
+# Returns 1 if the tool did not answer.
+report_stage()
+{
+	local stage=$1 name=$2 line
+
+	if ! kill -USR1 "$TARGET" || ! wait_output "^stage=$stage "; then
+		ktap_print_msg "no answer from the tool"
+		ktap_test_fail "$name"
+		return 1
+	fi
+	line=$(grep "^stage=$stage " "$OUT")
+	ktap_print_msg "$line"
+	if grep -q 'ok=1$' <<<"$line"; then
+		ktap_test_pass "$name"
+	else
+		ktap_test_fail "$name"
+	fi
+}
+
+# Run task policy mode $1 in the cpuset across one cpuset.mems change. The
+# tool's result is the last line of $OUT.
+run_task_policy()
+{
+	echo "${COMMON[0]},$PN" > "$CG/cpuset.mems"
+	if ! start_tool "$1" "$CG" ||
+	   ! echo "${COMMON[1]},$PN" > "$CG/cpuset.mems" ||
+	   ! kill -USR1 "$TARGET" || ! wait "$CHILD"; then
+		stop_tool
+		echo "tool failed" >> "$OUT"
+		return 1
+	fi
+	CHILD=
+	TARGET=
+}
+
+# Allow or revoke the private node at stage $2, by attaching the tool to
+# another cpuset or by writing mask $3 to cpuset.mems, for action $1.
+transition_cpuset()
+{
+	local action=$1 stage=$2 mask=$3
+
+	case "$action:$stage" in
+	attach:1) echo "$TARGET" > "$CGCOMMON/cgroup.procs" ;;
+	attach:*) echo "$TARGET" > "$CG/cgroup.procs" ;;
+	*) echo "$mask" > "$CG/cpuset.mems" ;;
+	esac
+}
+
+# A private binding in tool mode $1 while its cpuset allows, revokes and
+# allows the private node again, by action reshape or attach.
+run_private_transitions()
+{
+	local mode=$1 label=$2 action=${3:-reshape}
+	local stage mask title cg=
+	local titles=("keeps private pages and placement while the node stays allowed"
+		"evacuates private pages and uses common placement when access is revoked"
+		"restores the original private request when access returns")
+
+	echo "${COMMON[0]},$PN" > "$CG/cpuset.mems"
+	if [ "$action" = attach ]; then
+		echo "${COMMON[1]},$PN" > "$CG/cpuset.mems"
+	fi
+	# Shared-policy parents and task-attachment tools start at the root.
+	if [ "$mode" = private-anon ] && [ "$action" = reshape ]; then
+		cg=$CG
+	fi
+	if ! start_tool "$mode" "$cg"; then
+		ktap_print_msg "tool setup failed"
+		for title in "${titles[@]}"; do
+			ktap_test_fail "$label $title"
+		done
+		stop_tool
+		return
+	fi
+	if [ "$mode" = private-shared ] && [ "$action" = reshape ]; then
+		echo "$TARGET" > "$CG/cgroup.procs"
+	fi
+	for stage in 0 1 2; do
+		mask=${COMMON[1]}
+		[ "$stage" = 1 ] || mask+=",$PN"
+		if ! transition_cpuset "$action" "$stage" "$mask"; then
+			ktap_print_msg "cannot change the cpuset"
+			ktap_test_fail "$label ${titles[$stage]}"
+			continue
+		fi
+		report_stage "$stage" "$label ${titles[$stage]}"
+	done
+	wait "$CHILD"
+	CHILD=
+	TARGET=
+}
+
+# Take the private node through stage $1: offline, common, offline, private.
+retype_node()
+{
+	case "$1" in
+	0|2) echo unplugged > "$D/state" ;;
+	1) echo 0 > "$D/private" && echo online_movable > "$D/state" ;;
+	3) echo 1 > "$D/private" && echo online_movable > "$D/state" ;;
+	esac
+}
+
+# A private binding in tool mode $1 while its node is hotplugged and retyped.
+run_private_retype()
+{
+	local mode=$1 label=$2
+	local stage name ready=false
+	local titles=("falls back while the private node is offline"
+		"binds the original node when it returns as common memory"
+		"falls back again after draining the common node"
+		"restores private placement when the node returns as private memory")
+
+	echo "${COMMON[1]},$PN" > "$CG/cpuset.mems"
+	start_tool "$mode" "$CG" && ready=true
+	for stage in 0 1 2 3; do
+		name="$label ${titles[$stage]}"
+		if [ "$ready" != true ]; then
+			ktap_print_msg "tool is not running"
+			ktap_test_fail "$name"
+		elif ! retype_node "$stage"; then
+			ktap_print_msg "cannot hotplug $(basename "$D")"
+			ktap_test_fail "$name"
+			ready=false
+		elif ! report_stage "$stage" "$name"; then
+			ready=false
+		fi
+	done
+	stop_tool
+	pn_bind_kmem_private "$D"
+}
+
+# A static binding in tool mode $1 of a common node that becomes private.
+run_common_retype()
+{
+	local mode=$1 name=$2 line
+
+	if ! echo unplugged > "$D/state" || ! echo 0 > "$D/private" ||
+	   ! echo online_movable > "$D/state"; then
+		ktap_print_msg "cannot provision common kmem memory"
+		ktap_test_fail "$name"
+		return
+	fi
+	echo "${COMMON[0]},$PN" > "$CG/cpuset.mems"
+	if ! start_tool "$mode" "$CG"; then
+		ktap_print_msg "tool setup failed"
+		ktap_test_fail "$name"
+		stop_tool
+		return
+	fi
+	if ! echo unplugged > "$D/state" || ! echo 1 > "$D/private" ||
+	   ! echo online_movable > "$D/state" ||
+	   ! echo "${COMMON[1]},$PN" > "$CG/cpuset.mems"; then
+		ktap_print_msg "cannot retype kmem memory"
+		ktap_test_fail "$name"
+		stop_tool
+		return
+	fi
+	kill -USR1 "$TARGET"
+	if wait "$CHILD"; then
+		line=$(tail -1 "$OUT")
+		ktap_print_msg "$line"
+		if grep -q 'ok=1$' <<<"$line"; then
+			ktap_test_pass "$name"
+		else
+			ktap_test_fail "$name"
+		fi
+	else
+		ktap_print_msg "tool failed or timed out"
+		ktap_test_fail "$name"
+	fi
+	CHILD=
+	TARGET=
+}
+
+pn_setup
+[ -x "$TOOL" ] || pn_skip "kmem_private_rebind_tool not built"
+pn_find_common_nodes 2
+pn_require_mask_nodes "$PN" "${COMMON[@]}"
+pn_cpuset_cgroup "$CG"
+pn_cpuset_cgroup "$CGCOMMON"
+echo "${COMMON[0]},$PN" > "$CG/cpuset.mems" ||
+	ktap_exit_fail_msg "cannot set cpuset.mems of $CG"
+echo "${COMMON[1]}" > "$CGCOMMON/cpuset.mems" ||
+	ktap_exit_fail_msg "cannot set cpuset.mems of $CGCOMMON"
+
+ktap_set_plan 25
+
+run_task_policy interleave
+line=$(tail -1 "$OUT")
+ktap_print_msg "$line"
+name="interleave policy cannot reacquire private memory on rebind"
+if grep -q '^private=0 ' <<<"$line"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+run_task_policy bind
+line=$(tail -1 "$OUT")
+ktap_print_msg "$line"
+name="positional cpuset migration excludes private memory"
+if grep -q '^private=0 ' <<<"$line"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+name="removed common-node pages migrate to common fallback"
+if grep -q ' new_common=64$' <<<"$line"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+run_private_transitions private-anon "anonymous binding"
+run_private_transitions private-shared \
+	"shared binding across distinct mapper cpusets"
+run_private_transitions private-anon \
+	"anonymous binding across task attachment" attach
+run_private_transitions private-shared \
+	"shared binding across task attachment" attach
+run_private_retype retype-anon "anonymous private binding"
+run_private_retype retype-shared "shared private binding"
+run_common_retype static \
+	"shared common binding falls back after its node becomes private"
+run_common_retype static-mixed \
+	"shared common binding requires an allowed common target"
+
+ktap_finished
diff --git a/tools/testing/selftests/dax/kmem_private_rebind_tool.c b/tools/testing/selftests/dax/kmem_private_rebind_tool.c
new file mode 100644
index 000000000000..3d88d1e61c2f
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_rebind_tool.c
@@ -0,0 +1,495 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Helper for kmem_private_cpuset.sh and kmem_private_rebind.sh. Most modes
+ * place memory under a policy, print "ready pid=<pid>" and wait for SIGUSR1
+ * while the script changes the cpuset or the node, then report where the
+ * memory went. Modes with several stages wait for one SIGUSR1 per stage and
+ * print one "stage=<n> ... ok=<0|1>" line each.
+ *
+ * Modes that check their own results exit 1 when a check fails. All modes
+ * exit 2 on usage or setup errors.
+ */
+#define _GNU_SOURCE
+#include <linux/mempolicy.h>
+#include <signal.h>
+#include <stdbool.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <sys/syscall.h>
+#include <sys/wait.h>
+#include <unistd.h>
+
+#ifndef MPOL_F_PRIVATE_NODES
+#define MPOL_F_PRIVATE_NODES (1 << 12)
+#endif
+
+#define NR_PAGES 64
+/* The kernel reads maxnode - 1 bits. */
+#define MAXNODE (8 * sizeof(unsigned long) + 1)
+
+enum mode {
+	ORDINARY,
+	INTERLEAVE,
+	BIND,
+	PRIVATE_ANON,
+	PRIVATE_SHARED,
+	RETYPE_ANON,
+	RETYPE_SHARED,
+	STATIC,
+	STATIC_MIXED,
+	NR_MODES,
+};
+
+static const struct {
+	const char *name;
+	const char *help;
+} modes[NR_MODES] = {
+	[ORDINARY] = { "ordinary", "allocate without a policy" },
+	[INTERLEAVE] = { "interleave",
+			 "task interleave over <private> and <common1>" },
+	[BIND] = { "bind", "task bind to <common1>" },
+	[PRIVATE_ANON] = { "private-anon",
+			   "private binding of anonymous memory" },
+	[PRIVATE_SHARED] = { "private-shared",
+			     "private binding of shared memory, two mappers" },
+	[RETYPE_ANON] = { "retype-anon",
+			  "private-anon across node hotplug" },
+	[RETYPE_SHARED] = { "retype-shared",
+			    "private-shared across node hotplug" },
+	[STATIC] = { "static", "static binding of shared memory to <private>" },
+	[STATIC_MIXED] = { "static-mixed",
+			   "static binding to <private> and <common1>" },
+};
+
+static void print_usage(const char *prog)
+{
+	int i;
+
+	fprintf(stderr, "usage: %s <mode> <private> <common1> <common2>\n",
+		prog);
+	for (i = 0; i < NR_MODES; i++)
+		fprintf(stderr, "  %-15s %s\n", modes[i].name, modes[i].help);
+	exit(2);
+}
+
+/* Node masks are a single unsigned long. */
+static bool node_fits(int nid)
+{
+	return nid >= 0 && nid < (int)(8 * sizeof(unsigned long));
+}
+
+static void *map_anon(long len)
+{
+	return mmap(NULL, len, PROT_READ | PROT_WRITE,
+		    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+}
+
+static void *map_shared(int *fd, long len)
+{
+	*fd = memfd_create("private-rebind", 0);
+	if (*fd < 0 || ftruncate(*fd, len))
+		return MAP_FAILED;
+	return mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, *fd, 0);
+}
+
+static void announce_ready(void)
+{
+	printf("ready pid=%d\n", getpid());
+	fflush(stdout);
+}
+
+static long count_node(void *addr, long page_size, int nid)
+{
+	void *pages[NR_PAGES];
+	int status[NR_PAGES];
+	long i, count = 0;
+
+	for (i = 0; i < NR_PAGES; i++)
+		pages[i] = addr + i * page_size;
+	if (syscall(SYS_move_pages, 0, NR_PAGES, pages, NULL, status, 0UL))
+		return -1;
+	for (i = 0; i < NR_PAGES; i++)
+		count += status[i] == nid;
+	return count;
+}
+
+static bool range_matches(void *ptr, long page_size, unsigned char value)
+{
+	long i;
+
+	for (i = 0; i < NR_PAGES; i++)
+		if (*(unsigned char *)(ptr + i * page_size) != value)
+			return false;
+	return true;
+}
+
+static int bind_mapping(void *ptr, long len, unsigned long mask, int flags)
+{
+	return syscall(SYS_mbind, ptr, len, MPOL_BIND | flags,
+		       &mask, MAXNODE, 0UL);
+}
+
+static bool policy_matches(void *ptr, unsigned long mask, int flags)
+{
+	unsigned long actual = 0;
+	int mode;
+
+	return !syscall(SYS_get_mempolicy, &mode, &actual, MAXNODE,
+			ptr, MPOL_F_ADDR) &&
+		mode == (MPOL_BIND | flags) && actual == mask;
+}
+
+/* Report how many pages are on the private node. */
+static int ordinary(long page_size, int priv)
+{
+	long len = NR_PAGES * page_size;
+	void *ptr = map_anon(len);
+
+	if (ptr == MAP_FAILED)
+		return 2;
+	memset(ptr, 0xab, len);
+	printf("private=%ld\n", count_node(ptr, page_size, priv));
+	return 0;
+}
+
+static void report_placement(void *ptr, long page_size, int priv,
+			     int common1, int common2)
+{
+	printf("private=%ld old_common=%ld new_common=%ld\n",
+	       count_node(ptr, page_size, priv),
+	       count_node(ptr, page_size, common1),
+	       count_node(ptr, page_size, common2));
+}
+
+/* Interleave over the private node and allocate after the cpuset change. */
+static int task_interleave(long page_size, int priv, int common1,
+			   int common2, const sigset_t *waitset)
+{
+	unsigned long mask = (1UL << common1) | (1UL << priv);
+	long len = NR_PAGES * page_size;
+	void *ptr;
+	int sig;
+
+	if (syscall(SYS_set_mempolicy, MPOL_INTERLEAVE, &mask, MAXNODE))
+		return 2;
+	announce_ready();
+	sigwait(waitset, &sig);
+	ptr = map_anon(len);
+	if (ptr == MAP_FAILED)
+		return 2;
+	memset(ptr, 0xcd, len);
+	report_placement(ptr, page_size, priv, common1, common2);
+	munmap(ptr, len);
+	return 0;
+}
+
+/* Bind to the first common node and allocate before the cpuset change. */
+static int task_bind(long page_size, int priv, int common1, int common2,
+		     const sigset_t *waitset)
+{
+	unsigned long mask = 1UL << common1;
+	long len = NR_PAGES * page_size;
+	void *ptr;
+	int sig;
+
+	if (syscall(SYS_set_mempolicy, MPOL_BIND, &mask, MAXNODE))
+		return 2;
+	ptr = map_anon(len);
+	if (ptr == MAP_FAILED)
+		return 2;
+	memset(ptr, 0xab, len);
+	announce_ready();
+	sigwait(waitset, &sig);
+	report_placement(ptr, page_size, priv, common1, common2);
+	munmap(ptr, len);
+	return 0;
+}
+
+struct shared_result {
+	long private_pages;
+	long shared_pages;
+};
+
+/* Keep one mapper outside the cpuset that is being changed. */
+static int shared_mapper(void *ptr, long len, long page_size, int priv,
+			 int common, int requests, int replies, pid_t child)
+{
+	struct shared_result result;
+	int stage, status;
+	bool contents;
+	void *range;
+
+	while (read(requests, &stage, sizeof(stage)) == sizeof(stage)) {
+		range = ptr + (stage + 4) * len;
+		memset(range, 0xef, len);
+		result.private_pages = count_node(range, page_size, priv);
+
+		/* Existing shared pages are not reallocated for another mapper. */
+		range = ptr + (stage + 1) * len;
+		contents = range_matches(range, page_size, 0xcd);
+		result.shared_pages = count_node(range, page_size,
+						 stage == 1 ? common : priv);
+		if (!contents)
+			result.shared_pages = -1;
+		if (write(replies, &result, sizeof(result)) != sizeof(result))
+			break;
+	}
+	close(requests);
+	close(replies);
+	if (waitpid(child, &status, 0) != child || !WIFEXITED(status))
+		return 1;
+	return WEXITSTATUS(status);
+}
+
+/*
+ * A private binding across three cpuset changes that allow, revoke and allow
+ * the node again. Range 0 of the mapping is populated up front and range
+ * 1 + stage at each stage. For shared memory the parent stays outside the
+ * cpuset as a second mapper and populates range 4 + stage.
+ */
+static int private_rebind(bool shared, long page_size, int priv, int common,
+			  const sigset_t *waitset)
+{
+	unsigned long mask = 1UL << priv;
+	long len = NR_PAGES * page_size;
+	long total = (shared ? 7 : 4) * len;
+	int fd = -1, requests[2], replies[2];
+	int stage, sig, failed = 0;
+	struct shared_result other;
+	long private_pages, common_pages, existing, existing_common;
+	bool policy, contents, ok;
+	pid_t child;
+	void *ptr, *range;
+
+	if (shared)
+		ptr = map_shared(&fd, total);
+	else
+		ptr = map_anon(total);
+	if (ptr == MAP_FAILED ||
+	    bind_mapping(ptr, total, mask, MPOL_F_PRIVATE_NODES))
+		return 2;
+	/* Keep later ranges absent until their respective cpuset transition. */
+	if (madvise(ptr, total, MADV_NOHUGEPAGE))
+		return 2;
+	memset(ptr, 0xab, len);
+	if (count_node(ptr, page_size, priv) != NR_PAGES)
+		return 1;
+
+	if (shared) {
+		if (pipe(requests) || pipe(replies))
+			return 2;
+		child = fork();
+		if (child < 0)
+			return 2;
+		if (child) {
+			close(requests[1]);
+			close(replies[0]);
+			failed = shared_mapper(ptr, len, page_size, priv, common,
+					       requests[0], replies[1], child);
+			goto out;
+		}
+		close(requests[0]);
+		close(replies[1]);
+		/* Populate the child's PTEs before cpuset-requested migration. */
+		if (!range_matches(ptr, page_size, 0xab))
+			return 2;
+	}
+
+	announce_ready();
+	for (stage = 0; stage < 3; stage++) {
+		if (sigwait(waitset, &sig))
+			return 2;
+		range = ptr + (stage + 1) * len;
+		memset(range, 0xcd, len);
+		private_pages = count_node(range, page_size, priv);
+		common_pages = count_node(range, page_size, common);
+		/* File-backed PTEs can be populated lazily after fork. */
+		contents = range_matches(ptr, page_size, 0xab);
+		existing = count_node(ptr, page_size, priv);
+		existing_common = count_node(ptr, page_size, common);
+		policy = policy_matches(ptr, mask, MPOL_F_PRIVATE_NODES);
+		ok = policy && contents;
+		/* Old pages leave the private node only once it is revoked. */
+		if (stage == 0)
+			ok &= existing == NR_PAGES && existing_common == 0;
+		else
+			ok &= existing == 0 && existing_common == NR_PAGES;
+		if (stage == 1)
+			ok &= common_pages == NR_PAGES && private_pages == 0;
+		else
+			ok &= private_pages == NR_PAGES && common_pages == 0;
+		other.private_pages = -1;
+		other.shared_pages = -1;
+		if (shared) {
+			if (write(requests[1], &stage, sizeof(stage)) != sizeof(stage) ||
+			    read(replies[0], &other, sizeof(other)) != sizeof(other))
+				return 2;
+			ok &= other.private_pages == NR_PAGES &&
+				other.shared_pages == NR_PAGES;
+		}
+		printf("stage=%d private=%ld common=%ld existing_private=%ld ",
+		       stage, private_pages, common_pages, existing);
+		printf("existing_common=%ld ", existing_common);
+		printf("policy=%d other_private=%ld shared_pages=%ld ok=%d\n",
+		       policy, other.private_pages, other.shared_pages, ok);
+		fflush(stdout);
+		failed |= !ok;
+	}
+	if (shared) {
+		close(requests[1]);
+		close(replies[0]);
+	}
+out:
+	munmap(ptr, total);
+	if (fd >= 0)
+		close(fd);
+	return failed;
+}
+
+/*
+ * A private binding while the node goes offline, returns as common memory,
+ * goes offline again and returns as private memory. Range @stage of the
+ * mapping is populated at each stage.
+ */
+static int private_retype(bool shared, long page_size, int target, int common,
+			  const sigset_t *waitset)
+{
+	unsigned long mask = 1UL << target;
+	long len = NR_PAGES * page_size;
+	long private_pages, common_pages;
+	int fd = -1, stage, sig, i, failed = 0;
+	bool policy, contents, ok;
+	void *ptr, *range;
+
+	if (shared)
+		ptr = map_shared(&fd, 4 * len);
+	else
+		ptr = map_anon(4 * len);
+	if (ptr == MAP_FAILED ||
+	    bind_mapping(ptr, 4 * len, mask, MPOL_F_PRIVATE_NODES) ||
+	    madvise(ptr, 4 * len, MADV_NOHUGEPAGE))
+		return 2;
+
+	/* Keep the policy alive without preventing the initial hot-unplug. */
+	announce_ready();
+	for (stage = 0; stage < 4; stage++) {
+		if (sigwait(waitset, &sig))
+			return 2;
+		range = ptr + stage * len;
+		memset(range, 0xa0 + stage, len);
+		private_pages = count_node(range, page_size, target);
+		common_pages = count_node(range, page_size, common);
+		policy = policy_matches(ptr, mask, MPOL_F_PRIVATE_NODES);
+		contents = true;
+		for (i = 0; i <= stage; i++)
+			contents &= range_matches(ptr + i * len, page_size,
+						  0xa0 + i);
+		ok = policy && contents;
+		if (stage & 1)
+			ok &= private_pages == NR_PAGES && common_pages == 0;
+		else
+			ok &= private_pages == 0 && common_pages == NR_PAGES;
+		printf("stage=%d target=%ld common=%ld policy=%d contents=%d ok=%d\n",
+		       stage, private_pages, common_pages, policy, contents, ok);
+		fflush(stdout);
+		failed |= !ok;
+	}
+	munmap(ptr, 4 * len);
+	if (fd >= 0)
+		close(fd);
+	return failed;
+}
+
+/*
+ * A static binding of shared memory to a common node, optionally with a
+ * second common node, that the script turns private before a second mapper
+ * faults the pages in.
+ */
+static int common_retype(bool mixed, long page_size, int target,
+			 int old_common, int new_common,
+			 const sigset_t *waitset)
+{
+	unsigned long mask = 1UL << target;
+	long len = NR_PAGES * page_size;
+	long private_pages, common_pages;
+	int fd, sig;
+	bool policy, ok;
+	void *ptr, *other;
+
+	if (mixed)
+		mask |= 1UL << old_common;
+	ptr = map_shared(&fd, len);
+	if (ptr == MAP_FAILED ||
+	    bind_mapping(ptr, len, mask, MPOL_F_STATIC_NODES))
+		return 2;
+	other = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
+	if (other == MAP_FAILED)
+		return 2;
+	/* No resident pages: the target can be removed and retyped. */
+	announce_ready();
+	if (sigwait(waitset, &sig))
+		return 2;
+	memset(other, 0xcd, len);
+	private_pages = count_node(other, page_size, target);
+	common_pages = count_node(other, page_size, new_common);
+	policy = policy_matches(other, mask, MPOL_F_STATIC_NODES);
+	ok = private_pages == 0 && common_pages == NR_PAGES && policy;
+	printf("private=%ld common=%ld policy=%d ok=%d\n",
+	       private_pages, common_pages, policy, ok);
+	munmap(other, len);
+	munmap(ptr, len);
+	close(fd);
+	return !ok;
+}
+
+int main(int argc, char **argv)
+{
+	long page_size = sysconf(_SC_PAGESIZE);
+	int priv, common1, common2, mode;
+	sigset_t waitset;
+
+	if (argc != 5)
+		print_usage(argv[0]);
+	for (mode = 0; mode < NR_MODES; mode++)
+		if (!strcmp(argv[1], modes[mode].name))
+			break;
+	if (mode == NR_MODES)
+		print_usage(argv[0]);
+	priv = atoi(argv[2]);
+	common1 = atoi(argv[3]);
+	common2 = atoi(argv[4]);
+	if (!node_fits(priv) || !node_fits(common1) || !node_fits(common2)) {
+		fprintf(stderr, "node ids must be 0 to %zu\n",
+			8 * sizeof(unsigned long) - 1);
+		return 2;
+	}
+
+	sigemptyset(&waitset);
+	sigaddset(&waitset, SIGUSR1);
+	sigprocmask(SIG_BLOCK, &waitset, NULL);
+
+	switch (mode) {
+	case ORDINARY:
+		return ordinary(page_size, priv);
+	case INTERLEAVE:
+		return task_interleave(page_size, priv, common1, common2,
+				       &waitset);
+	case BIND:
+		return task_bind(page_size, priv, common1, common2, &waitset);
+	case PRIVATE_ANON:
+	case PRIVATE_SHARED:
+		return private_rebind(mode == PRIVATE_SHARED, page_size, priv,
+				      common2, &waitset);
+	case RETYPE_ANON:
+	case RETYPE_SHARED:
+		return private_retype(mode == RETYPE_SHARED, page_size, priv,
+				      common2, &waitset);
+	case STATIC:
+	case STATIC_MIXED:
+		return common_retype(mode == STATIC_MIXED, page_size, priv,
+				     common1, common2, &waitset);
+	}
+	return 2;
+}
diff --git a/tools/testing/selftests/dax/private_node_common.sh b/tools/testing/selftests/dax/private_node_common.sh
index cd03d9489822..5c58f3195d22 100644
--- a/tools/testing/selftests/dax/private_node_common.sh
+++ b/tools/testing/selftests/dax/private_node_common.sh
@@ -234,3 +234,35 @@ pn_require_mask_nodes()
 			pn_skip "node $nid does not fit the helper node mask"
 	done
 }
+
+# Create cgroup $1 with the cpuset controller enabled and all CPUs.
+pn_cpuset_cgroup()
+{
+	[ "$(stat -fc %T "$CGROOT" 2>/dev/null)" = cgroup2fs ] ||
+		pn_skip "requires cgroup v2"
+	grep -qw cpuset "$CGROOT/cgroup.controllers" 2>/dev/null ||
+		pn_skip "cpuset controller unavailable"
+	if ! grep -qw cpuset "$CGROOT/cgroup.subtree_control"; then
+		echo +cpuset > "$CGROOT/cgroup.subtree_control" 2>/dev/null ||
+			pn_skip "cannot enable cpuset controller"
+		PN_CPUSET_ENABLED=1
+	fi
+	if ! mkdir "$1" ||
+	   ! cat "$CGROOT/cpuset.cpus.effective" > "$1/cpuset.cpus"; then
+		ktap_exit_fail_msg "cannot create $1"
+	fi
+}
+
+# Remove the cgroups $@ made by pn_cpuset_cgroup(), and the cpuset
+# controller if it enabled it.
+pn_cpuset_cleanup()
+{
+	local cg
+
+	for cg in "$@"; do
+		[ -d "$cg" ] && rmdir "$cg" 2>/dev/null
+	done
+	[ -n "${PN_CPUSET_ENABLED:-}" ] || return 0
+	PN_CPUSET_ENABLED=
+	echo -cpuset > "$CGROOT/cgroup.subtree_control" 2>/dev/null
+}

-- 
2.56.1

