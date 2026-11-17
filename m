From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:43 +0000
Subject: [PATCH RFC 5/7] test: add pid "-" probe test for -p and non-zero
 link addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-5-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=4497;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=dQiH+AESeLnwXf9cwv1ByyOkvEcK/01fVnjiSBh0LAU=;
 b=k7SUprV3R7vBaXB/Ujkz1p1UonwrytAxBTExKQRFdRFdmN4Zq7oosM2pZC2VhLjXWmqulsU2X
 3qGzbzewz03CkADOjLmTyWgY1moC7Rs74QB7OGtTlIWzam9Xxcb4VOv
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Probe a function's link-time address as pid$target:a.out:-:ADDR in
non-PIE executables and PIEs linked by GNU ld and by lld, and in a PIE
linked by lld at 0x200000, both under -c and attached with -p.  Without
the previous patch the PIE linked at 0x200000 fails in both modes, and
every PIE fails with -p.

Linkers that are not installed are left out; the .x file skips the test
if neither is.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/pid/tst.dash-loadbias.r  |  1 +
 test/unittest/pid/tst.dash-loadbias.sh | 95 ++++++++++++++++++++++++++++++++++
 test/unittest/pid/tst.dash-loadbias.x  | 14 +++++
 3 files changed, 110 insertions(+)

diff --git a/test/unittest/pid/tst.dash-loadbias.r b/test/unittest/pid/tst.dash-loadbias.r
new file mode 100644
index 00000000..2e9ba477
--- /dev/null
+++ b/test/unittest/pid/tst.dash-loadbias.r
@@ -0,0 +1 @@
+success
diff --git a/test/unittest/pid/tst.dash-loadbias.sh b/test/unittest/pid/tst.dash-loadbias.sh
new file mode 100755
index 00000000..28e5f395
--- /dev/null
+++ b/test/unittest/pid/tst.dash-loadbias.sh
@@ -0,0 +1,95 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, d-Matrix Corporation. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check that pid$target:a.out:-:ADDR fires when ADDR is a function's
+# link-time address, in non-PIE executables and PIEs linked by GNU ld and by
+# lld, and in a PIE linked at 0x200000 by lld, both for a process dtrace
+# starts (-c) and for one it attaches to (-p).
+#
+# ADDR must be relocated by the executable's load bias.  The load address of
+# its first segment is the bias only if it is linked at 0; with -p, libproc
+# does not yet know the executable is ET_DYN when the probe is created.
+# Linkers that are not installed are left out (GNU ld cannot link a PIE at a
+# non-zero address); the .x file skips the test if neither is.
+#
+
+dtrace=$1
+utils=$PWD/test/utils
+ncalls=3
+
+DIRNAME=$tmpdir/pid-dash-loadbias.$$.$RANDOM
+mkdir -p $DIRNAME
+cd $DIRNAME
+
+cat > main.c <<EOF
+#include <unistd.h>
+
+volatile int sink;
+
+__attribute__((noinline)) int target(int x) { return x * 2 + 1; }
+
+/* With an argument, run long enough for dtrace -p to attach. */
+int main(int argc, char **argv)
+{
+	int i;
+
+	for (i = 0; i < (argc > 1 ? 100 : $ncalls); i++) {
+		sink = target(i);
+		if (argc > 1)
+			usleep(100000);
+	}
+	return 0;
+}
+EOF
+
+bins=
+for ld in $($utils/linkers.sh); do
+	$CC -O0 -fuse-ld=$ld -o pie-$ld main.c &&
+	$CC -O0 -fuse-ld=$ld -no-pie -o nopie-$ld main.c || exit 1
+	bins="$bins pie-$ld nopie-$ld"
+	if [ $ld = lld ]; then
+		$CC -O0 -fuse-ld=lld -Wl,--image-base=0x200000 \
+		    -o pie-lld-base main.c || exit 1
+		bins="$bins pie-lld-base"
+	fi
+done
+
+# last OPTION...: run dtrace and print the last line of its output (a count,
+# or an error)
+last() {
+	$dtrace $dt_flags "$@" 2>&1 | awk 'NF { last = $0 } END {
+		sub(/^dtrace: (invalid probe specifier .*: )?/, "", last)
+		print last
+	    }'
+}
+
+status=0
+for bin in $bins; do
+	addr=$(nm $bin | awk '$3 == "target" { sub(/^0*/, "", $1); print $1 }')
+	probe=pid\$target:a.out:-:$addr
+
+	n=$(last -qn "$probe { n++; } dtrace:::END { printf(\"%d\\n\", n); }" -c ./$bin)
+	if [ "$n" != $ncalls ]; then
+		echo "ERROR: $bin -c: $probe: got '$n', want $ncalls firings"
+		status=1
+	fi
+
+	./$bin wait &
+	pid=$!
+	sleep 0.5
+	n=$(last -p $pid -qn "$probe { n++; }
+	    tick-1s { printf(\"%d\\n\", n); exit(0); }")
+	kill $pid
+	wait $pid 2> /dev/null
+	if ! [ "$n" -gt 0 ] 2> /dev/null; then
+		echo "ERROR: $bin -p: $probe: got '$n', want at least 1 firing"
+		status=1
+	fi
+done
+
+[ $status -eq 0 ] && echo success
+exit $status
diff --git a/test/unittest/pid/tst.dash-loadbias.x b/test/unittest/pid/tst.dash-loadbias.x
new file mode 100755
index 00000000..e5a3ad3e
--- /dev/null
+++ b/test/unittest/pid/tst.dash-loadbias.x
@@ -0,0 +1,14 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, d-Matrix Corporation. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# This test needs GNU ld or lld.
+
+if ! test/utils/linkers.sh > /dev/null; then
+	echo "neither GNU ld nor ld.lld is available"
+	exit 2
+fi
+exit 0

-- 
2.55.0

