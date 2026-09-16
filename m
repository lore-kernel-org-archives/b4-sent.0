From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:29 -0600
Subject: [PATCH v10 37/38] dyndbg: add +c flag to count advantage of
 classmaps for DRM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-37-af4cf4767707@gmail.com>
References: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
In-Reply-To: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=15846;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=UgEpeUYYslZ7ljuve3ooJVvCgWAYyjl+oKIxiw/dQXU=;
 b=I+A9sR8IVqhFZKqqppVFj+Dfgb8RkKVr+LJ84t42pk5yqvp7mzz6DwHHEnxpS3aPmIgtsGgjf
 EgWi7Cl71SIACoT5YuQ0jghR9CS5sRPe6zlXsgGEQB1OkY0ND6lxNlC
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
v10:
. add __DYNAMIC_DEBUG_BRANCH() checking _ENABLED while DYNAMIC_DEBUG_BRANCH() checks _ACTIVE.
. add early return guards in __dynamic_*_dbg() helpers checking _ACTIVE.

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
 include/linux/dynamic_debug.h | 54 ++++++++++++++++++++++++++++++++-----------
 lib/dynamic_debug.c           | 54 +++++++++++++++++++++++++++++++++++++++----
 2 files changed, 91 insertions(+), 17 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index d94ad3a2018a..55abe0dc275a 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -49,6 +49,10 @@ struct _ddebug {
 #define _DPRINTK_FLAGS_INCL_TID		(1<<4)
 #define _DPRINTK_FLAGS_INCL_SOURCENAME	(1<<5)
 #define _DPRINTK_FLAGS_INCL_STACK	(1<<6)
+#define _DPRINTK_FLAGS_COUNT		(1<<7)
+
+#define _DPRINTK_FLAGS_ENABLED (_DPRINTK_FLAGS_PRINT | _DPRINTK_FLAGS_COUNT)
+#define _DPRINTK_FLAGS_ACTIVE  (_DPRINTK_FLAGS_PRINT)
 
 #define _DPRINTK_FLAGS_INCL_ANY		\
 	(_DPRINTK_FLAGS_INCL_MODNAME | _DPRINTK_FLAGS_INCL_FUNCNAME |\
@@ -383,28 +387,44 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 
 #define _DPRINTK_KEY_INIT .key.dd_key_true = (STATIC_KEY_TRUE_INIT)
 
-#define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	static_branch_likely(&descriptor.key.dd_key_true)
+#define __DYNAMIC_DEBUG_BRANCH(descriptor) \
+	static_branch_likely(&(descriptor).key.dd_key_true)
 #else
 #define _DPRINTK_KEY_INIT .key.dd_key_false = (STATIC_KEY_FALSE_INIT)
 
-#define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	static_branch_unlikely(&descriptor.key.dd_key_false)
+#define __DYNAMIC_DEBUG_BRANCH(descriptor) \
+	static_branch_unlikely(&(descriptor).key.dd_key_false)
 #endif
 
 #else /* !CONFIG_JUMP_LABEL */
 
 #define _DPRINTK_KEY_INIT
 
+#ifdef DEBUG
+#define __DYNAMIC_DEBUG_BRANCH(descriptor) \
+	likely((descriptor).flags & _DPRINTK_FLAGS_ENABLED)
+#else
+#define __DYNAMIC_DEBUG_BRANCH(descriptor) \
+	unlikely((descriptor).flags & _DPRINTK_FLAGS_ENABLED)
+#endif
+
+#endif /* CONFIG_JUMP_LABEL */
+
 #ifdef DEBUG
 #define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	likely(descriptor.flags & _DPRINTK_FLAGS_PRINT)
+	(__DYNAMIC_DEBUG_BRANCH(descriptor) && \
+	 likely((descriptor).flags & _DPRINTK_FLAGS_ACTIVE))
 #else
 #define DYNAMIC_DEBUG_BRANCH(descriptor) \
-	unlikely(descriptor.flags & _DPRINTK_FLAGS_PRINT)
+	(__DYNAMIC_DEBUG_BRANCH(descriptor) && \
+	 unlikely((descriptor).flags & _DPRINTK_FLAGS_ACTIVE))
 #endif
 
-#endif /* CONFIG_JUMP_LABEL */
+void ddebug_increment_call_count(void);
+#define DYNAMIC_DEBUG_COUNT(descriptor) {			\
+	if (unlikely(descriptor.flags & _DPRINTK_FLAGS_COUNT))	\
+		ddebug_increment_call_count();			\
+	}
 
 /*
  * Factory macros: ($prefix)dynamic_func_call($suffix)
@@ -417,11 +437,15 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
  * (|_cls):	adds in _DPRINT_CLASS_DFLT as needed
  * (|_no_desc):	former gets callsite descriptor as 1st arg (for prdbgs)
  */
+
 #define __dynamic_func_call_cls(id, cls, fmt, func, ...) do {	\
 	DEFINE_DYNAMIC_DEBUG_METADATA_CLS(id, cls, fmt);	\
-	if (DYNAMIC_DEBUG_BRANCH(id)) {				\
-		func(&id, ##__VA_ARGS__);			\
-		__dynamic_dump_stack(id);			\
+	if (__DYNAMIC_DEBUG_BRANCH(id)) {				\
+		DYNAMIC_DEBUG_COUNT(id);			\
+		if (id.flags & _DPRINTK_FLAGS_ACTIVE) {		\
+			func(&id, ##__VA_ARGS__);		\
+			__dynamic_dump_stack(id);		\
+		}						\
 	}							\
 } while (0)
 #define __dynamic_func_call(id, fmt, func, ...)				\
@@ -430,9 +454,12 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 
 #define __dynamic_func_call_cls_no_desc(id, cls, fmt, func, ...) do {	\
 	DEFINE_DYNAMIC_DEBUG_METADATA_CLS(id, cls, fmt);		\
-	if (DYNAMIC_DEBUG_BRANCH(id)) {					\
-		func(__VA_ARGS__);					\
-		__dynamic_dump_stack(id);				\
+	if (__DYNAMIC_DEBUG_BRANCH(id)) {					\
+		DYNAMIC_DEBUG_COUNT(id);				\
+		if (id.flags & _DPRINTK_FLAGS_ACTIVE) {			\
+			func(__VA_ARGS__);				\
+			__dynamic_dump_stack(id);			\
+		}							\
 	}								\
 } while (0)
 #define __dynamic_func_call_no_desc(id, fmt, func, ...)			\
@@ -525,6 +552,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #define DYNAMIC_DEBUG_CLASSMAP_PARAM_REF(_name, _bits, _var, _flags)	\
 	module_param_named(_name, _bits, uint, 0600)
 #define DEFINE_DYNAMIC_DEBUG_METADATA(name, fmt)
+#define __DYNAMIC_DEBUG_BRANCH(descriptor) false
 #define DYNAMIC_DEBUG_BRANCH(descriptor) false
 #define DECLARE_DYNDBG_CLASSMAP(...)
 
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 406b64d67440..bdc6d32ec685 100644
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
@@ -71,6 +73,21 @@ struct flag_settings {
 	unsigned int mask;
 };
 
+static DEFINE_PER_CPU(unsigned long, ddebug_call_count);
+void ddebug_increment_call_count(void)
+{
+	this_cpu_inc(ddebug_call_count);
+}
+EXPORT_SYMBOL(ddebug_increment_call_count);
+
+static void reset_ddebug_call_count(void)
+{
+	int cpu;
+
+	for_each_possible_cpu(cpu)
+		per_cpu(ddebug_call_count, cpu) = 0;
+}
+
 static bool ddebug_class_map_in_range(const int class_id,
 				      const struct ddebug_class_map *map);
 static bool ddebug_class_user_in_range(const int class_id,
@@ -101,6 +118,7 @@ static const struct { unsigned flag:8; char opt_char; } opt_array[] = {
 	{ _DPRINTK_FLAGS_INCL_LINENO, 'l' },
 	{ _DPRINTK_FLAGS_INCL_TID, 't' },
 	{ _DPRINTK_FLAGS_INCL_STACK, 'd' },
+	{ _DPRINTK_FLAGS_COUNT, 'c' },
 	{ _DPRINTK_FLAGS_NONE, '_' },
 };
 
@@ -365,10 +383,10 @@ static int ddebug_change(const struct ddebug_query *query, struct flag_settings
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
@@ -727,6 +745,11 @@ static int ddebug_exec_queries(char *query, const char *modname)
 		if (!query || !*query || *query == '#')
 			continue;
 
+		if (!strcmp(query, "reset_stats")) {
+			reset_ddebug_call_count();
+			continue;
+		}
+
 		if (modname)
 			v2pr_info("query %d: module %s \"%s\"\n", i, modname, query);
 		else
@@ -980,6 +1003,9 @@ void __dynamic_pr_debug(struct _ddebug *descriptor, const char *fmt, ...)
 	BUG_ON(!descriptor);
 	BUG_ON(!fmt);
 
+	if (!(descriptor->flags & _DPRINTK_FLAGS_ACTIVE))
+		return;
+
 	va_start(args, fmt);
 
 	vaf.fmt = fmt;
@@ -1000,6 +1026,9 @@ void __dynamic_dev_dbg(struct _ddebug *descriptor,
 	BUG_ON(!descriptor);
 	BUG_ON(!fmt);
 
+	if (!(descriptor->flags & _DPRINTK_FLAGS_ACTIVE))
+		return;
+
 	va_start(args, fmt);
 
 	vaf.fmt = fmt;
@@ -1031,6 +1060,9 @@ void __dynamic_netdev_dbg(struct _ddebug *descriptor,
 	BUG_ON(!descriptor);
 	BUG_ON(!fmt);
 
+	if (!(descriptor->flags & _DPRINTK_FLAGS_ACTIVE))
+		return;
+
 	va_start(args, fmt);
 
 	vaf.fmt = fmt;
@@ -1067,6 +1099,9 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 	struct va_format vaf;
 	va_list args;
 
+	if (!(descriptor->flags & _DPRINTK_FLAGS_ACTIVE))
+		return;
+
 	va_start(args, fmt);
 
 	vaf.fmt = fmt;
@@ -1106,6 +1141,7 @@ static __init int dyndbg_setup(char *str)
 
 __setup("dyndbg=", dyndbg_setup);
 
+
 /*
  * File_ops->write method for <debugfs>/dynamic_debug/control.  Gathers the
  * command text from userspace, parses and executes it.
@@ -1263,6 +1299,16 @@ static const char *ddebug_class_name(struct _ddebug_info *di, struct _ddebug *dp
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
@@ -1282,7 +1328,7 @@ static int ddebug_proc_show(struct seq_file *m, void *p)
 		return 0;
 	}
 	if (p == EPILOGUE_TOKEN) {
-		/* use this soon */
+		seq_printf(m, "#: total call-counts: %lu\n", get_ddebug_call_count());
 		return 0;
 	}
 

-- 
2.55.0

