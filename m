From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:45 +0000
Subject: [PATCH RFC 7/7] test: add USDT test for libraries with a non-zero
 link address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-7-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=4263;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=LgoLY3MC3kK4GCv/r3CBeV+QjoVl+OXEZ5LxN18sER0=;
 b=MkVjQ+PU73LkgEr35InJKLoiBamXkc5rUfCBFFjElsb5M69mW2Jvb2gUs0If3YuvYqMgT63YV
 HRD/UwUJ6F4AvTdRenOziYh/X19QOBf7Ee7/QJq/+8SB2vAyGIBgGw5
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Build a USDT probe into shared libraries linked at 0 and at 0x200000,
with GNU ld and with lld, and check that it fires 3 times in each.
Without the previous patch no probe is created in the libraries linked
at 0x200000.

Linkers that are not installed are left out; the .x file skips the test
if neither is.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/usdt/tst.lib-loadbias.r  |  1 +
 test/unittest/usdt/tst.lib-loadbias.sh | 96 ++++++++++++++++++++++++++++++++++
 test/unittest/usdt/tst.lib-loadbias.x  | 14 +++++
 3 files changed, 111 insertions(+)

diff --git a/test/unittest/usdt/tst.lib-loadbias.r b/test/unittest/usdt/tst.lib-loadbias.r
new file mode 100644
index 00000000..2e9ba477
--- /dev/null
+++ b/test/unittest/usdt/tst.lib-loadbias.r
@@ -0,0 +1 @@
+success
diff --git a/test/unittest/usdt/tst.lib-loadbias.sh b/test/unittest/usdt/tst.lib-loadbias.sh
new file mode 100755
index 00000000..132e7a95
--- /dev/null
+++ b/test/unittest/usdt/tst.lib-loadbias.sh
@@ -0,0 +1,96 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, d-Matrix Corporation. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check that USDT probes are created and fire in shared libraries linked at
+# 0 and at 0x200000, by GNU ld and by lld.
+#
+# dtprobed turns each probe's link-time address into a runtime address by
+# adding the library's load bias.  The load address of its first segment is
+# the bias only if the library is linked at 0; otherwise the probe address
+# is too high by the link address and no probe is created.  Linkers that are
+# not installed are left out; the .x file skips the test if neither is.
+#
+
+dtrace=$1
+utils=$PWD/test/utils
+ncalls=3
+CFLAGS="$test_cppflags"
+LDFLAGS="$test_ldflags"
+declare -A base=([bfd]=-Wl,-Ttext-segment=0x200000
+		 [lld]=-Wl,--image-base=0x200000)
+
+DIRNAME=$tmpdir/usdt-lib-loadbias.$$.$RANDOM
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
+__attribute__((noinline)) void work(int i)
+{
+	TEST_PROV_TICK(i);
+}
+EOF
+
+cat > main.c <<EOF
+void work(int i);
+
+int main(void)
+{
+	int i;
+
+	for (i = 0; i < $ncalls; i++)
+		work(i);
+	return 0;
+}
+EOF
+
+$dtrace $dt_flags -h -s prov.d || exit 1
+
+# build NAME LD LDFLAGS...: libNAME.so linked by LD with LDFLAGS, and NAME
+# linked against it.  dtrace -G uses the same linker.
+build() {
+	local name=$1 ld=$2
+	shift 2
+
+	$CC $CFLAGS -fPIC -c -o $name.o work.c &&
+	$dtrace $dt_flags -x ldpath=ld.$ld -G -s prov.d -o prov-$name.o $name.o &&
+	$CC $LDFLAGS -fuse-ld=$ld -shared "$@" -o lib$name.so $name.o prov-$name.o &&
+	$CC $CFLAGS $LDFLAGS -fuse-ld=$ld -o $name main.c -L. -l$name \
+	    -Wl,-rpath,$DIRNAME
+}
+
+# fired BIN PROBE: how often PROBE fired in a run of ./BIN, or dtrace's error
+fired() {
+	$dtrace $dt_flags -qn "$2 { n++; } dtrace:::END { printf(\"%d\\n\", n); }" \
+	    -c ./$1 2>&1 | awk 'NF { last = $0 } END {
+		sub(/^dtrace: (invalid probe specifier .*: )?/, "", last)
+		print last
+	    }'
+}
+
+status=0
+for ld in $($utils/linkers.sh); do
+	build $ld $ld && build $ld-base $ld ${base[$ld]} || exit 1
+
+	for name in $ld $ld-base; do
+		n=$(fired $name 'test_prov$target:::tick')
+		if [ "$n" != $ncalls ]; then
+			echo "ERROR: lib$name.so: got '$n', want $ncalls firings"
+			status=1
+		fi
+	done
+done
+
+[ $status -eq 0 ] && echo success
+exit $status
diff --git a/test/unittest/usdt/tst.lib-loadbias.x b/test/unittest/usdt/tst.lib-loadbias.x
new file mode 100755
index 00000000..e5a3ad3e
--- /dev/null
+++ b/test/unittest/usdt/tst.lib-loadbias.x
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

