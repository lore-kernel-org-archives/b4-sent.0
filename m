From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:48 -0500
Subject: [PATCH 57/60] selftests/dax: test private kmem devices and
 services
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-57-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=14437;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=idwblUguxyP7auq0Q+zpWj4PVxwt1E+r+ThtiJ7hgoY=;
 b=q38uwmfyBBphWMLKJXDTdBPM/s7/vheYjpqhQqz8er6+qA0nSHp7/JIQj+oBGXwL5FZ4NEhDy
 QhTrU4jaD6UBBeMn0zc1N7bBnEUpeIq3wusDWh309Qg6huBW/kMik9h
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test dax/kmem private mode on a device-dax instance:
  - the private attribute across memory hotplug: private memory joins
    has_private_memory, the mode changes only while unplugged, and
    online common memory cannot become private.
  - services on the private node: kswapd and kcompactd run,
    nodeN/reclaim and nodeN/compact are accepted, and HugeTLB pool
    growth stays off the node.

The tests reconfigure a device, so they run only when DAX_KMEM_TEST_DEV
names one (daxX.Y), or is "auto" to pick a device whose memory is not
online. The device's original configuration is restored on exit.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 tools/testing/selftests/dax/Makefile               |   3 +
 tools/testing/selftests/dax/config                 |   2 +
 tools/testing/selftests/dax/kmem_private.sh        |  94 ++++++++++
 .../testing/selftests/dax/kmem_private_services.sh |  97 ++++++++++
 tools/testing/selftests/dax/private_node_common.sh | 208 +++++++++++++++++++++
 5 files changed, 404 insertions(+)

diff --git a/tools/testing/selftests/dax/Makefile b/tools/testing/selftests/dax/Makefile
index 25a4f3d73a5b..55d2ba0de8d9 100644
--- a/tools/testing/selftests/dax/Makefile
+++ b/tools/testing/selftests/dax/Makefile
@@ -2,5 +2,8 @@
 all:
 
 TEST_PROGS := dax-kmem-hotplug.sh
+TEST_PROGS += kmem_private.sh
+TEST_PROGS += kmem_private_services.sh
+TEST_FILES := private_node_common.sh
 
 include ../lib.mk
diff --git a/tools/testing/selftests/dax/config b/tools/testing/selftests/dax/config
index 4c9aaeb6ceb4..42853ed9e99f 100644
--- a/tools/testing/selftests/dax/config
+++ b/tools/testing/selftests/dax/config
@@ -2,3 +2,5 @@ CONFIG_DEV_DAX=m
 CONFIG_DEV_DAX_KMEM=m
 CONFIG_MEMORY_HOTPLUG=y
 CONFIG_MEMORY_HOTREMOVE=y
+CONFIG_NUMA=y
+CONFIG_COMPACTION=y
diff --git a/tools/testing/selftests/dax/kmem_private.sh b/tools/testing/selftests/dax/kmem_private.sh
new file mode 100755
index 000000000000..ceba05e69e14
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private.sh
@@ -0,0 +1,94 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Exercise the kmem "private" attribute across memory hotplug: when it may
+# change, and whether onlined memory joins has_private_memory or
+# has_common_memory.
+#
+# Needs root and DAX_KMEM_TEST_DEV=<daxX.Y|auto>, see private_node_common.sh.
+
+# shellcheck disable=SC1091
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR"/../kselftest/ktap_helpers.sh
+. "$DIR"/private_node_common.sh
+
+trap pn_unbind_kmem_private EXIT
+pn_setup
+
+if ! echo unplugged > "$D/state" 2>/dev/null ||
+   pn_node_in "$PN" has_memory; then
+	ktap_exit_fail_msg "private memory cannot be unplugged"
+fi
+
+ktap_set_plan 8
+
+name="private mode can be selected while unplugged"
+if echo 0 > "$D/private" 2>/dev/null && echo 1 > "$D/private" 2>/dev/null &&
+   [ "$(cat "$D/private")" = 1 ]; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="invalid private setting is rejected"
+if ! echo invalid > "$D/private" 2>/dev/null &&
+   [ "$(cat "$D/private")" = 1 ]; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="private online publishes private memory"
+if echo online_movable > "$D/state" 2>/dev/null &&
+   pn_node_is_private "$PN" && ! pn_node_in "$PN" has_common_memory; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+# Writing the current value again is accepted.
+name="private mode cannot change while memory blocks exist"
+if ! echo 0 > "$D/private" 2>/dev/null &&
+   [ "$(cat "$D/private")" = 1 ] && echo 1 > "$D/private" 2>/dev/null; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="unplug removes the private node from memory lists"
+if echo unplugged > "$D/state" 2>/dev/null &&
+   ! pn_node_in "$PN" has_memory &&
+   ! pn_node_in "$PN" has_private_memory; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="common mode preserves normal kmem behavior"
+if echo 0 > "$D/private" 2>/dev/null &&
+   echo online_movable > "$D/state" 2>/dev/null &&
+   pn_node_in "$PN" has_common_memory; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="online common memory cannot be reclassified as private"
+if ! echo 1 > "$D/private" 2>/dev/null &&
+   [ "$(cat "$D/private")" = 0 ]; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+name="private mode can be restored through an unplug cycle"
+if echo unplugged > "$D/state" 2>/dev/null &&
+   echo 1 > "$D/private" 2>/dev/null &&
+   echo online_movable > "$D/state" 2>/dev/null &&
+   pn_node_is_private "$PN"; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+ktap_finished
diff --git a/tools/testing/selftests/dax/kmem_private_services.sh b/tools/testing/selftests/dax/kmem_private_services.sh
new file mode 100755
index 000000000000..df5d17fdb947
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_services.sh
@@ -0,0 +1,97 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Check which MM services a private kmem node gets: no HugeTLB pool pages,
+# but kswapd, kcompactd and per-node compaction and reclaim.
+#
+# Needs root and DAX_KMEM_TEST_DEV=<daxX.Y|auto>, see private_node_common.sh.
+
+# shellcheck disable=SC1091
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR"/../kselftest/ktap_helpers.sh
+. "$DIR"/private_node_common.sh
+
+trap pn_unbind_kmem_private EXIT
+pn_setup
+
+ktap_set_plan 5
+
+# Use the default size: a gigantic page may not fit the device at all.
+hsize=$(awk '/^Hugepagesize:/ { print $2 }' /proc/meminfo)
+pool="$NODE_BASE/node$PN/hugepages/hugepages-${hsize}kB/nr_hugepages"
+global=/sys/kernel/mm/hugepages/hugepages-${hsize}kB/nr_hugepages
+name_node="per-node HugeTLB pool growth skips private memory"
+name_global="HugeTLB pool growth falls back to other nodes"
+if [ -z "$hsize" ] || [ ! -w "$pool" ] || [ ! -w "$global" ]; then
+	ktap_print_msg "HugeTLB pools unavailable"
+	ktap_test_skip "$name_node"
+	ktap_test_skip "$name_global"
+else
+	before=$(cat "$pool")
+	echo $((before + 8)) > "$pool" 2>/dev/null
+	after=$(cat "$pool")
+	echo "$before" > "$pool" 2>/dev/null
+	if [ "$after" = "$before" ]; then
+		ktap_test_pass "$name_node"
+	else
+		ktap_print_msg "private-node pool grew $before->$after"
+		ktap_test_fail "$name_node"
+	fi
+
+	gbefore=$(cat "$global")
+	echo $((gbefore + 64)) > "$global" 2>/dev/null
+	gafter=$(cat "$global")
+	after=$(cat "$pool")
+	echo "$gbefore" > "$global" 2>/dev/null
+	if [ "$gafter" -le "$gbefore" ]; then
+		ktap_print_msg "HugeTLB pool could not grow on any node"
+		ktap_test_skip "$name_global"
+	elif [ "$after" = "$before" ]; then
+		ktap_test_pass "$name_global"
+	else
+		ktap_print_msg "private-node pool grew $before->$after"
+		ktap_test_fail "$name_global"
+	fi
+fi
+
+compact="$NODE_BASE/node$PN/compact"
+name="kswapd and kcompactd run for the private node"
+if ! pgrep -x "kswapd$PN" >/dev/null; then
+	ktap_print_msg "kswapd$PN is not running"
+	ktap_test_fail "$name"
+elif [ ! -e "$compact" ]; then
+	ktap_print_msg "kcompactd unavailable without compaction"
+	ktap_test_skip "$name"
+elif pgrep -x "kcompactd$PN" >/dev/null; then
+	ktap_test_pass "$name"
+else
+	ktap_print_msg "kcompactd$PN is not running"
+	ktap_test_fail "$name"
+fi
+
+name="private-node compaction is accepted"
+if [ ! -e "$compact" ]; then
+	ktap_print_msg "per-node compaction unavailable"
+	ktap_test_skip "$name"
+elif echo 1 > "$compact" 2>/dev/null; then
+	ktap_test_pass "$name"
+else
+	ktap_test_fail "$name"
+fi
+
+reclaim="$NODE_BASE/node$PN/reclaim"
+name="private-node reclaim is accepted"
+if [ ! -e "$reclaim" ]; then
+	ktap_print_msg "per-node reclaim unavailable"
+	ktap_test_skip "$name"
+elif err=$(export LC_ALL=C; echo 1M 2>&1 > "$reclaim"); then
+	ktap_test_pass "$name"
+elif [[ $err == *"Resource temporarily unavailable"* ]]; then
+	# An idle node may have nothing to reclaim.
+	ktap_test_pass "$name"
+else
+	ktap_print_msg "$err"
+	ktap_test_fail "$name"
+fi
+
+ktap_finished
diff --git a/tools/testing/selftests/dax/private_node_common.sh b/tools/testing/selftests/dax/private_node_common.sh
new file mode 100644
index 000000000000..57c5231e768b
--- /dev/null
+++ b/tools/testing/selftests/dax/private_node_common.sh
@@ -0,0 +1,208 @@
+# SPDX-License-Identifier: GPL-2.0
+# shellcheck shell=bash disable=SC2034
+# Helpers shared by the kmem_private*.sh selftests, sourced after
+# ../kselftest/ktap_helpers.sh.
+#
+# DAX_KMEM_TEST_DEV=<daxX.Y|auto> opts into reconfiguring a device-dax
+# instance as private kmem memory. "auto" only uses devices whose memory is
+# not online and that no process has open or mapped. A named device is used
+# whatever its state. Either is restored on exit.
+#
+# pn_setup() sets D to the sysfs directory of that device and PN to its node.
+
+DAX_BASE=/sys/bus/dax/devices
+NODE_BASE=/sys/devices/system/node
+
+# Whether nodelist $1 (e.g. "0-2,4") contains node $2.
+pn_nodelist_has()
+{
+	local nid=$2 token low high
+
+	for token in ${1//,/ }; do
+		low=${token%-*}
+		high=${token#*-}
+		if [ "$nid" -ge "$low" ] 2>/dev/null &&
+		   [ "$nid" -le "$high" ] 2>/dev/null; then
+			return 0
+		fi
+	done
+	return 1
+}
+
+# Whether node $1 is in the node state list $2, e.g. has_memory.
+pn_node_in()
+{
+	[ -r "$NODE_BASE/$2" ] &&
+		pn_nodelist_has "$(cat "$NODE_BASE/$2")" "$1"
+}
+
+pn_node_is_private()
+{
+	pn_node_in "$1" has_private_memory
+}
+
+# Whether any process has device node $1 open or mapped.
+pn_dev_in_use()
+{
+	local fd
+
+	for fd in /proc/[0-9]*/fd/*; do
+		[ "$(readlink "$fd" 2>/dev/null)" = "$1" ] && return 0
+	done
+	grep -qs " $1\$" /proc/[0-9]*/maps
+}
+
+# Record the original configuration of device $1, bound to driver $2, for
+# pn_unbind_kmem_private().
+pn_record_kmem()
+{
+	# Binding the recorded device again keeps its original configuration.
+	[ "${PN_DEV:-}" != "$1" ] || return 0
+	PN_DEV=$1
+	PN_ORIG_DRIVER=$2
+	PN_ORIG_STATE=$(cat "$1/state" 2>/dev/null)
+	PN_ORIG_PRIVATE=$(cat "$1/private" 2>/dev/null)
+	PN_NEW_ID=
+}
+
+# Move device $1 from driver $2 to kmem and online it as private memory on
+# node $3.
+pn_online_private()
+{
+	local dev=$1 driver=$2 nid=$3 name
+
+	name=$(basename "$dev")
+	if [ "$driver" = kmem ]; then
+		echo unplugged > "$dev/state" || return 1
+	elif [ -n "$driver" ]; then
+		echo "$name" > "/sys/bus/dax/drivers/$driver/unbind" || return 1
+	fi
+	# A private node holds the memory of this device only.
+	if pn_node_in "$nid" has_memory; then
+		return 1
+	fi
+	if [ "$driver" != kmem ]; then
+		echo "$name" > /sys/bus/dax/drivers/kmem/new_id || return 1
+		PN_NEW_ID=1
+	fi
+	echo unplugged > "$dev/state" &&
+		echo 1 > "$dev/private" &&
+		echo online_movable > "$dev/state" &&
+		pn_node_is_private "$nid"
+}
+
+# Online device $1 as private kmem memory, or return 1 if it is unusable.
+pn_bind_kmem_private()
+{
+	local dev=$1 name driver nid
+
+	name=$(basename "$dev")
+	nid=$(cat "$dev/target_node" 2>/dev/null) || return 1
+	driver=$(basename "$(readlink "$dev/driver" 2>/dev/null)" 2>/dev/null)
+	if [ "$driver" = kmem ] &&
+	   [ "$(cat "$dev/state" 2>/dev/null)" != unplugged ]; then
+		# Leave online kmem memory alone unless it is ours or was named.
+		if [ "$DAX_KMEM_TEST_DEV" = auto ] &&
+		   [ "${PN_DEV:-}" != "$dev" ]; then
+			return 1
+		fi
+		if [ "$(cat "$dev/private" 2>/dev/null)" = 1 ] &&
+		   pn_node_is_private "$nid"; then
+			pn_record_kmem "$dev" "$driver"
+			return 0
+		fi
+	elif pn_node_in "$nid" has_memory; then
+		return 1
+	elif [ "$DAX_KMEM_TEST_DEV" = auto ] && pn_dev_in_use "/dev/$name"; then
+		return 1
+	fi
+
+	pn_record_kmem "$dev" "$driver"
+	if ! pn_online_private "$dev" "$driver" "$nid" 2>/dev/null; then
+		pn_unbind_kmem_private
+		return 1
+	fi
+}
+
+# Restore the device recorded by pn_bind_kmem_private(), if any.
+pn_unbind_kmem_private()
+{
+	local dev=${PN_DEV:-} name
+
+	[ -n "$dev" ] || return 0
+	PN_DEV=
+	name=$(basename "$dev")
+	if [ "$(basename "$(readlink "$dev/driver" 2>/dev/null)")" = kmem ]; then
+		echo unplugged > "$dev/state" 2>/dev/null || return 1
+		if [ -n "$PN_ORIG_PRIVATE" ]; then
+			echo "$PN_ORIG_PRIVATE" > "$dev/private" 2>/dev/null
+		fi
+	fi
+	if [ "$PN_ORIG_DRIVER" = kmem ]; then
+		case "$PN_ORIG_STATE" in
+		unplugged) ;;
+		offline)
+			# kmem cannot restore blocks onlined behind its back.
+			ktap_print_msg "$name was offline and is left unplugged"
+			;;
+		*) echo "$PN_ORIG_STATE" > "$dev/state" 2>/dev/null ;;
+		esac
+		return 0
+	fi
+	if [ -e "$dev/driver" ]; then
+		echo "$name" > /sys/bus/dax/drivers/kmem/unbind 2>/dev/null
+	fi
+	if [ -n "$PN_NEW_ID" ]; then
+		echo "$name" > /sys/bus/dax/drivers/kmem/remove_id 2>/dev/null
+	fi
+	if [ -n "$PN_ORIG_DRIVER" ]; then
+		echo "$name" > "/sys/bus/dax/drivers/$PN_ORIG_DRIVER/bind" \
+			2>/dev/null
+	fi
+	return 0
+}
+
+pn_skip()
+{
+	ktap_skip_all "$1"
+	exit "$KSFT_SKIP"
+}
+
+# An explicitly selected device must provision, auto may find none.
+pn_skip_or_fail()
+{
+	if [ "$DAX_KMEM_TEST_DEV" = auto ]; then
+		pn_skip "$1"
+	fi
+	ktap_exit_fail_msg "$1"
+}
+
+# Print the KTAP header, check the prerequisites and bind a private kmem
+# device, setting D and PN.
+pn_setup()
+{
+	local dev nid
+
+	ktap_print_header
+	[ "$(id -u)" = 0 ] || pn_skip "must be run as root"
+	[ -n "${DAX_KMEM_TEST_DEV:-}" ] ||
+		pn_skip "set DAX_KMEM_TEST_DEV=<daxX.Y|auto> to select a test device"
+	[ -e "$NODE_BASE/has_private_memory" ] ||
+		pn_skip "kernel lacks private memory nodes"
+	modprobe -q kmem 2>/dev/null
+	[ -d /sys/bus/dax/drivers/kmem ] || pn_skip "dax kmem driver unavailable"
+
+	for dev in "$DAX_BASE"/dax*; do
+		if [ "$DAX_KMEM_TEST_DEV" != auto ] &&
+		   [ "$(basename "$dev")" != "$DAX_KMEM_TEST_DEV" ]; then
+			continue
+		fi
+		nid=$(cat "$dev/target_node" 2>/dev/null) || continue
+		[ "$nid" -ge 0 ] 2>/dev/null || continue
+		pn_bind_kmem_private "$dev" || continue
+		D=$dev
+		PN=$nid
+		return 0
+	done
+	pn_skip_or_fail "no private kmem device"
+}

-- 
2.56.1

