From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 15 Oct 2026 03:53:45 +0000
Subject: [PATCH 5/7] test: add USDT probe placement test for lld-linked
 objects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-bug001-uprobe-file-offset-v1-5-bf4c53af8f39@d-matrix.ai>
References: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
In-Reply-To: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=4723;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=iFwFZBiTxGr9NqjqFOSMiyi8GarTtNfqWB4qAy8vIYE=;
 b=Z7UUnnAzGmuDbWTMLpsdxt7bETW5ux0PuHT7h/i66Jm5zCrGRHcuxwMwVfHORJ3xjn3odg/XR
 hTYtwCyh2j2AufSPjHCXjNlcC22nRF9yo+Q847qy0weEae8/+xcBa+Y
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Build a USDT probe with an is-enabled test into a PIE, a non-PIE
executable and a shared library, each linked with GNU ld and with lld,
and check that the probe fires and is-enabled is true as many times as
the site runs.  Without the previous patch, every lld build fails.

The GNU ld builds reject fixes that work only for lld's layout, and the
shared-library builds reject fixes that handle only the main executable.
Linkers that are not installed are left out; the .x file skips the test
when lld is not installed.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/usdt/tst.lld-offset.r  |   1 +
 test/unittest/usdt/tst.lld-offset.sh | 104 +++++++++++++++++++++++++++++++++++
 test/unittest/usdt/tst.lld-offset.x  |  14 +++++
 3 files changed, 119 insertions(+)

diff --git a/test/unittest/usdt/tst.lld-offset.r b/test/unittest/usdt/tst.lld-offset.r
new file mode 100644
index 00000000..2e9ba477
--- /dev/null
+++ b/test/unittest/usdt/tst.lld-offset.r
@@ -0,0 +1 @@
+success
diff --git a/test/unittest/usdt/tst.lld-offset.sh b/test/unittest/usdt/tst.lld-offset.sh
new file mode 100755
index 00000000..6b80b856
--- /dev/null
+++ b/test/unittest/usdt/tst.lld-offset.sh
@@ -0,0 +1,104 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check that USDT probes and their is-enabled probes work in PIEs, non-PIE
+# executables and shared libraries linked by GNU ld and by lld.
+#
+# Uprobes are placed by file offset.  lld's text segment has p_vaddr =
+# p_offset + 0x1000 (x86_64), so an offset computed as the probe site's
+# distance from the first segment misses the site by 0x1000: the
+# probe does not fire and the is-enabled test stays false.  The GNU ld
+# builds reject fixes that only work for lld, the shared libraries fixes
+# that only handle the main executable.  Linkers that are not installed are
+# left out; the .x file skips the test if lld is one of them.
+#
+
+dtrace=$1
+utils=$PWD/test/utils
+ncalls=3
+CFLAGS="$test_cppflags"
+LDFLAGS="$test_ldflags"
+
+DIRNAME=$tmpdir/usdt-lld-offset.$$.$RANDOM
+mkdir -p $DIRNAME
+cd $DIRNAME
+
+cat > prov.d <<EOF
+provider test_prov {
+	probe tick(int);
+};
+EOF
+
+cat > work.c <<EOF
+#include "prov.h"
+
+int enabled;
+
+__attribute__((noinline)) void work(int i)
+{
+	if (TEST_PROV_TICK_ENABLED())
+		enabled++;
+	TEST_PROV_TICK(i);
+}
+EOF
+
+cat > main.c <<EOF
+#include <stdio.h>
+
+extern int enabled;
+void work(int i);
+
+int main(void)
+{
+	int i;
+
+	for (i = 0; i < $ncalls; i++)
+		work(i);
+	printf("enabled %d\n", enabled);
+	return 0;
+}
+EOF
+
+$dtrace $dt_flags -h -s prov.d || exit 1
+
+# build NAME LD KIND: link NAME with LD.  KIND is pie, nopie, or shlib (work
+# in libNAME.so).  dtrace -G uses the same linker.
+build() {
+	local name=$1 ld=$2 kind=$3 cflags= link="$name.o prov-$name.o"
+
+	case $kind in
+	nopie)	cflags="-fno-pie -no-pie";;
+	shlib)	cflags=-fPIC;;
+	esac
+	$CC $CFLAGS $cflags -c -o $name.o work.c &&
+	$dtrace $dt_flags -x ldpath=ld.$ld -G -s prov.d -o prov-$name.o $name.o ||
+	    return 1
+	if [ $kind = shlib ]; then
+		$CC $LDFLAGS -fuse-ld=$ld -shared -o lib$name.so $link || return 1
+		link="-L. -l$name -Wl,-rpath,$DIRNAME"
+	fi
+	$CC $CFLAGS $LDFLAGS $cflags -fuse-ld=$ld -o $name main.c $link
+}
+
+status=0
+for ld in $($utils/linkers.sh); do
+	for kind in pie nopie shlib; do
+		name=$kind-$ld
+		build $name $ld $kind || exit 1
+
+		got=$($dtrace $dt_flags -qn 'test_prov$target:::tick { n++; }
+		    END { printf("fired %d\n", n); }' -c ./$name 2>&1 | awk NF | sort | paste -sd " ")
+		want="enabled $ncalls fired $ncalls"
+		if [ "$got" != "$want" ]; then
+			echo "ERROR: $name: got '$got', want '$want'"
+			status=1
+		fi
+	done
+done
+
+[ $status -eq 0 ] && echo success
+exit $status
diff --git a/test/unittest/usdt/tst.lld-offset.x b/test/unittest/usdt/tst.lld-offset.x
new file mode 100755
index 00000000..6a44074d
--- /dev/null
+++ b/test/unittest/usdt/tst.lld-offset.x
@@ -0,0 +1,14 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# The layout this test is about is produced only by lld.
+
+if ! test/utils/linkers.sh lld > /dev/null; then
+	echo "ld.lld is not available"
+	exit 2
+fi
+exit 0

-- 
2.55.0

