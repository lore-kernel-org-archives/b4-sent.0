From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:34 -0600
Subject: [PATCH v9 38/39] dyndbg: add +c flag to count advantage of
 classmaps for DRM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-38-3a3f621f4a10@gmail.com>
References: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
In-Reply-To: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Jonathan Corbet <corbet@net.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=13274;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=QkBwYWYkNOngGU9HvtDOs+ck1f263U/+3talZNBccYM=;
 b=VHxpk8lcyu5L6ougGYncds0k/D8yVQhBlvFa6YIc0Eh3jxyEvbEHlsYYzPdV0ipxLpmtO4gCM
 hW8KRvxjEa8DVxKdsh56/s6z8Vl57TIWiu4e4mgFvkljF+Wc68pcMfF
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a +c flag, to increment a per-cpu counter: ddebug_count
when a flagged pr_debug() is called.

Reset the counter with:
  echo reset_stats > /proc/dynamic_debug/control

and see the count value with:
  tail -n1 /proc/dynamic_debug/control
  #: total count: 2295401

This counter lets us count drm*dbg() callrate without doing the
printk; it counts how often upstream drm_debug_enabled() would read
main memory, evict a cache-line, and test a bit.

CONFIG_DRM_USE_DYNAMIC_DEBUG=y gives drm a per callsite static-key to
avoid that cache-line insult.  On my amdgpu + nvidia laptop, thats
~3200 of them.

The benchmarks below are from a recent build running on my asus
amdgpu + nouveau laptop, using scripts from below the snip.

  #> count_hits 30 hammer_vk --
  Banging on: hammer_vk (&)
  [1] 100847
  [1]+  Done                       hammer_vk
  #: total hits: 2295401

  #> count_hits 30 hammer_vk -- DRM_UT_CORE
  Banging on: hammer_vk (&)
  [1] 99910
  [1]+  Done                       hammer_vk
  #: total hits: 2204406

Notably, the DRM_UT_CORE category dominates the call traffic, not
DRM_UT_VBL or any others, which contribute little extra to the above.

To see the distribution of debug categories (for vkcube load)

  #> isolate_drm_hits 2> /dev/null
  Starting isolation study: 10s per class using vkcube
  ----------------------------------------------------------
  DRM CLASS            | TOTAL HITS
  ----------------------------------------------------------
  DRM_UT_CORE          | 85305
  DRM_UT_DRIVER        | 0
  DRM_UT_KMS           | 1435
  DRM_UT_PRIME         | 0
  DRM_UT_ATOMIC        | 13645
  DRM_UT_VBL           | 4071
  DRM_UT_STATE         | 1780
  DRM_UT_LEASE         | 0
  DRM_UT_DP            | 0
  DRM_UT_DRMRES        | 0
  FOO                  | 0

REVIEW:

In every minute, 12 vkcubes issue ~4.6M drm_debug_enabled(__drm_debug)
macro-calls.  To test the bits, they all *may* go out to main memory,
though __drm_debug is ro-mostly.  Still, theres significant cache-line
eviction, and potentially meaningful costs we can avoid.

With CONFIG_DRM_USE_DYNAMIC_DEBUG=y, each pr_debug call-site is
replaced by a static-key, with the off-cost of few NOOPs, avoiding all
the unpredictable downsides.

NOTES:

The +c flag invokes the callsite, but avoids the heavy syslog writing.
It is currently independent of +p, but it could be compressed into a
state-machine, and the bit recovered, but not til we need to do so.

The +c flag has no predictive quality; to count usr_dbg() callsites,
you must have reimplemnted them already with pr_debug.  This just
gives DRM some numbers to consider, to balance against the work needed
o test this series.

Assisted-by: Gemini-CLI:gemini-2.5-pro
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v9:
. add missing kfree(tmpbuf) in reset_stats handler before early return.
. sum across for_each_possible_cpu() in get_ddebug_call_count() for hotplug stability.
. update !CONFIG_JUMP_LABEL branch check to check _DPRINTK_FLAGS_ENABLED.

function ddcmd () {
    local cmd="$*"
    # Direct write - assume the parent script is run with 'sudo' or as root
    [ -f /proc/dynamic_debug/control ] || return 1;
    if ! echo "$cmd" > /proc/dynamic_debug/control 2>/tmp/dd_err; then
        local ret=$?
        echo "ERROR ($ret): $(cat /tmp/dd_err)" #>&2
        # Check dmesg for the "!" syntax error on wk-baseline
        dmesg | grep -i "dyndbg" | tail -n 2 #>&2
        return $ret
    fi
}

function _get_cal_count() {
    if [ ! -f /proc/interrupts ]; then
        echo 0
        return
    fi
    # sum all CPU columns for any line starting with CAL:
    # the awk starts at $2 to skip the label (CAL:)
    # NF-2 skips the trailing text "Function call interrupts"
    grep "^ *CAL:" /proc/interrupts | \
        awk '{ for(i=2; i<=NF-2; i++) sum+=$i } END { print sum+0 }'
}

function wrap_cal_count() {
    local cal_before
    cal_before=$(_get_cal_count)
    printf " wrapping: %s\n" "$*" #>&2
    #time \
	"$@" || return 1
    local cal_after
    cal_after=$(_get_cal_count)
    local delta=$(( ${cal_after:-0} - ${cal_before:-0} ))
    printf "Delta-CAL (IPI): %d\n" "$delta" #>&2
}

TEST_CLASSES_LIST="D2_CORE D2_DRIVER D2_KMS D2_PRIME D2_ATOMIC D2_VBL D2_STATE D2_LEASE D2_DP D2_DRMRES V0 V1 V2 V3 V4 V5 V6 V7"

DRM_CLASSES_LIST="DRM_UT_CORE DRM_UT_DRIVER DRM_UT_KMS DRM_UT_PRIME DRM_UT_ATOMIC DRM_UT_VBL DRM_UT_STATE DRM_UT_LEASE DRM_UT_DP DRM_UT_DRMRES"

function dd_setup_() {
    local flags="${1:-+p}"
    # Use $2 if provided, otherwise fallback to the full list
    local CLASSES_LIST="$2"
    local q=""
    local C

    # Safeguard: if list is empty, don't do anything
    [[ -z "$CLASSES_LIST" ]] && echo "no classes!" && return 0

    for C in $CLASSES_LIST; do
        q+="class $C $flags ; "
    done
    #echo "sending: $q"
    ddcmd "$q"
}

function dd_setup_test() {
    modprobe test_dynamic_debug || return 1
    dd_setup_ $1 "${2:-$TEST_CLASSES_LIST}"
}

function dd_setup_drm() {
    dd_setup_ $1 "${2:-$DRM_CLASSES_LIST}"
}

function count_hits() {
    local duration=60
    [[ "$1" =~ ^[0-9]+$ ]] && { duration=$1; shift; }

    local cmd_to_run=()
    local custom_classes=""
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--" ]]; then
            shift
            custom_classes="$*"
            break
        fi
        cmd_to_run+=("$1")
        shift
    done

    ddcmd reset_stats
    dd_setup_drm "+c" "$custom_classes"

    if [[ ${#cmd_to_run[@]} -gt 0 ]]; then
        echo "Banging on: ${cmd_to_run[*]} (&)"
        # Use eval so bash functions work
        eval "${cmd_to_run[*]} &"
        local cmd_pid=$!
        sleep "$duration"
        killall vkcube 2>/dev/null
        kill "$cmd_pid" 2>/dev/null
    else
        sleep "$duration"
    fi

    dd_setup_drm "-c" "$custom_classes"
    tail -n1 /proc/dynamic_debug/control
}

function hammer_vk() {
    for i in {1..12}; do vkcube >/dev/null 2>&1 & done
}

function isolate_drm_hits() {
    local duration=${1:-10}
    local cmd=${2:-vkcube}

    echo "Starting isolation study: ${duration}s per class using ${cmd}"
    echo "----------------------------------------------------------"
    printf "%-20s | %-10s\n" "DRM CLASS" "TOTAL HITS"
    echo "----------------------------------------------------------"

    for class in $DRM_CLASSES_LIST FOO; do
        # Run count_hits for the specific class
        # Use 'capture' logic to grab only the hit count from the tail output
        result=$(count_hits "$duration" "$cmd" -- "$class" | grep "total hits" | awk '{print $NF}')

        printf "%-20s | %-10s\n" "$class" "$result"
    done
    #result=$(count_hits "$duration" "$cmd" -- "FOO" | grep "total hits" | awk '{print $NF}')
    #printf "%-20s | %-10s\n" "$class" "$result"
}

[ $SHLVL == 2 -a -n "$*" ] && echo " doing: $* in $PWD" #>&2

if [ $SHLVL == 2 ]; then
    # run args as cmd
    $@
fi
---
 include/linux/dynamic_debug.h | 29 +++++++++++++++++++++++------
 lib/dynamic_debug.c           | 41 +++++++++++++++++++++++++++++++++++++----
 2 files changed, 60 insertions(+), 10 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index 39de59c8bac2..064df695b3a4 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -56,6 +56,10 @@ struct _ddebug {
 #define _DPRINTK_FLAGS_INCL_TID		(1<<4)
 #define _DPRINTK_FLAGS_INCL_SOURCENAME	(1<<5)
 #define _DPRINTK_FLAGS_INCL_STACK	(1<<6)
+#define _DPRINTK_FLAGS_COUNT		(1<<7)
+
+#define _DPRINTK_FLAGS_ENABLED (_DPRINTK_FLAGS_PRINT | _DPRINTK_FLAGS_COUNT)
+#define _DPRINTK_FLAGS_ACTIVE  (_DPRINTK_FLAGS_PRINT)
 
 #define _DPRINTK_FLAGS_INCL_ANY		\
 	(_DPRINTK_FLAGS_INCL_MODNAME | _DPRINTK_FLAGS_INCL_FUNCNAME |\
@@ -403,14 +407,20 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 
 #ifdef DEBUG
 #define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	likely(descriptor.flags & _DPRINTK_FLAGS_PRINT)
+	likely(descriptor.flags & _DPRINTK_FLAGS_ENABLED)
 #else
 #define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	unlikely(descriptor.flags & _DPRINTK_FLAGS_PRINT)
+	unlikely(descriptor.flags & _DPRINTK_FLAGS_ENABLED)
 #endif
 
 #endif /* CONFIG_JUMP_LABEL */
 
+void ddebug_increment_call_count(void);
+#define DYNAMIC_DEBUG_COUNT(descriptor) {			\
+	if (unlikely(descriptor.flags & _DPRINTK_FLAGS_COUNT))	\
+		ddebug_increment_call_count();			\
+	}
+
 /*
  * Factory macros: ($prefix)dynamic_func_call($suffix)
  *
@@ -422,11 +432,15 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
  * (|_cls):	adds in _DPRINT_CLASS_DFLT as needed
  * (|_no_desc):	former gets callsite descriptor as 1st arg (for prdbgs)
  */
+
 #define __dynamic_func_call_cls(id, cls, fmt, func, ...) do {	\
 	DEFINE_DYNAMIC_DEBUG_METADATA_CLS(id, cls, fmt);	\
 	if (DYNAMIC_DEBUG_BRANCH(id)) {				\
-		func(&id, ##__VA_ARGS__);			\
-		__dynamic_dump_stack(id);			\
+		DYNAMIC_DEBUG_COUNT(id);			\
+		if (id.flags & _DPRINTK_FLAGS_ACTIVE) {		\
+			func(&id, ##__VA_ARGS__);		\
+			__dynamic_dump_stack(id);		\
+		}						\
 	}							\
 } while (0)
 #define __dynamic_func_call(id, fmt, func, ...)				\
@@ -436,8 +450,11 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #define __dynamic_func_call_cls_no_desc(id, cls, fmt, func, ...) do {	\
 	DEFINE_DYNAMIC_DEBUG_METADATA_CLS(id, cls, fmt);		\
 	if (DYNAMIC_DEBUG_BRANCH(id)) {					\
-		func(__VA_ARGS__);					\
-		__dynamic_dump_stack(id);				\
+		DYNAMIC_DEBUG_COUNT(id);				\
+		if (id.flags & _DPRINTK_FLAGS_ACTIVE) {			\
+			func(__VA_ARGS__);				\
+			__dynamic_dump_stack(id);			\
+		}							\
 	}								\
 } while (0)
 #define __dynamic_func_call_no_desc(id, fmt, func, ...)			\
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 77976e7b264c..9fa1a6e3afe6 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -19,12 +19,14 @@
 #include <linux/kallsyms.h>
 #include <linux/types.h>
 #include <linux/mutex.h>
+#include <linux/percpu.h>
 #include <linux/proc_fs.h>
 #include <linux/seq_file.h>
 #include <linux/list.h>
 #include <linux/sysctl.h>
 #include <linux/ctype.h>
 #include <linux/string.h>
+
 #include <linux/parser.h>
 #include <linux/string_helpers.h>
 #include <linux/uaccess.h>
@@ -71,6 +73,13 @@ struct flag_settings {
 	unsigned int mask;
 };
 
+static DEFINE_PER_CPU(unsigned long, ddebug_call_count);
+void ddebug_increment_call_count(void)
+{
+	this_cpu_inc(ddebug_call_count);
+}
+EXPORT_SYMBOL(ddebug_increment_call_count);
+
 static bool ddebug_class_map_in_range(const int class_id,
 				      const struct ddebug_class_map *map);
 static bool ddebug_class_user_in_range(const int class_id,
@@ -101,6 +110,7 @@ static const struct { unsigned flag:8; char opt_char; } opt_array[] = {
 	{ _DPRINTK_FLAGS_INCL_LINENO, 'l' },
 	{ _DPRINTK_FLAGS_INCL_TID, 't' },
 	{ _DPRINTK_FLAGS_INCL_STACK, 'd' },
+	{ _DPRINTK_FLAGS_COUNT, 'c' },
 	{ _DPRINTK_FLAGS_NONE, '_' },
 };
 
@@ -365,10 +375,10 @@ static int ddebug_change(const struct ddebug_query *query, struct flag_settings
 			if (newflags == dp->flags)
 				continue;
 #ifdef CONFIG_JUMP_LABEL
-			if (dp->flags & _DPRINTK_FLAGS_PRINT) {
-				if (!(newflags & _DPRINTK_FLAGS_PRINT))
+			if (dp->flags & _DPRINTK_FLAGS_ENABLED) {
+				if (!(newflags & _DPRINTK_FLAGS_ENABLED))
 					static_branch_disable(&dp->key.dd_key_true);
-			} else if (newflags & _DPRINTK_FLAGS_PRINT) {
+			} else if (newflags & _DPRINTK_FLAGS_ENABLED) {
 				static_branch_enable(&dp->key.dd_key_true);
 			}
 #endif
@@ -1082,6 +1092,14 @@ static __init int dyndbg_setup(char *str)
 
 __setup("dyndbg=", dyndbg_setup);
 
+static void reset_ddebug_call_count(void)
+{
+	int cpu;
+
+	for_each_possible_cpu(cpu)
+		per_cpu(ddebug_call_count, cpu) = 0;
+}
+
 /*
  * File_ops->write method for <debugfs>/dynamic_debug/control.  Gathers the
  * command text from userspace, parses and executes it.
@@ -1104,6 +1122,11 @@ static ssize_t ddebug_proc_write(struct file *file, const char __user *ubuf,
 		return PTR_ERR(tmpbuf);
 	v2pr_info("read %zu bytes from userspace\n", len);
 
+	if (len >= 11 && !strncmp(tmpbuf, "reset_stats", 11)) {
+		reset_ddebug_call_count();
+		kfree(tmpbuf);
+		return len;
+	}
 	ret = ddebug_exec_queries(tmpbuf, NULL);
 	kfree(tmpbuf);
 	if (ret < 0)
@@ -1239,6 +1262,16 @@ static const char *ddebug_class_name(struct _ddebug_info *di, struct _ddebug *dp
 	return NULL;
 }
 
+static unsigned long get_ddebug_call_count(void)
+{
+	unsigned long total = 0;
+	int cpu;
+
+	for_each_possible_cpu(cpu)
+		total += per_cpu(ddebug_call_count, cpu);
+	return total;
+}
+
 /*
  * Seq_ops show method.  Called several times within a read()
  * call from userspace, with ddebug_lock held.  Formats the
@@ -1258,7 +1291,7 @@ static int ddebug_proc_show(struct seq_file *m, void *p)
 		return 0;
 	}
 	if (p == EPILOGUE_TOKEN) {
-		/* use this soon */
+		seq_printf(m, "#: total call-counts: %lu\n", get_ddebug_call_count());
 		return 0;
 	}
 

-- 
2.55.0

