From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:40 +0000
Subject: [PATCH RFC 2/7] test: add ufunc() test for libraries with a
 non-zero link address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-2-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=4205;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=Njf1unyjBHRByVolS5NPRPLzAKagoAYgS8m2ruhOZVc=;
 b=xLjQr0O+gYHKA6K9JBIb/pcyBScOJp5qBIyNycPYJ32SKYY3xs/6ECsf2aRiwja8fiAa2H9eR
 1ymd0d8ElstDDzZ55UNKryf5LxrBXL/ML3/PLToMDwgC4eY6f7GG+dE
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sample a process that dtrace neither started nor attached to, and check
that ufunc() names the function running in its shared library, for
libraries linked at 0 and at 0x200000 by GNU ld (-Ttext-segment) and by
lld (--image-base).  Symbolizing such a process uses libproc's computed
load bias; without the previous patch the samples in the libraries
linked at 0x200000 are shown as bare addresses.

Linkers that are not installed are left out; the .x file skips the test
if neither is.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/profile-n/tst.ufunc-loadbias.r  |  1 +
 test/unittest/profile-n/tst.ufunc-loadbias.sh | 85 +++++++++++++++++++++++++++
 test/unittest/profile-n/tst.ufunc-loadbias.x  | 14 +++++
 3 files changed, 100 insertions(+)

diff --git a/test/unittest/profile-n/tst.ufunc-loadbias.r b/test/unittest/profile-n/tst.ufunc-loadbias.r
new file mode 100644
index 00000000..2e9ba477
--- /dev/null
+++ b/test/unittest/profile-n/tst.ufunc-loadbias.r
@@ -0,0 +1 @@
+success
diff --git a/test/unittest/profile-n/tst.ufunc-loadbias.sh b/test/unittest/profile-n/tst.ufunc-loadbias.sh
new file mode 100755
index 00000000..a409477c
--- /dev/null
+++ b/test/unittest/profile-n/tst.ufunc-loadbias.sh
@@ -0,0 +1,85 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, d-Matrix Corporation. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check that ufunc() names the function running in a shared library of a
+# process that dtrace neither started nor attached to, for libraries linked
+# at 0 and at 0x200000 by GNU ld and by lld.
+#
+# Without the dynamic linker's link map, libproc computes a library's load
+# bias from its first mapping.  The bias is the mapping's start minus the
+# first PT_LOAD's page-aligned p_vaddr; subtracting only the part of p_vaddr
+# below p_align leaves it too high by the link address, and the samples are
+# shown as bare addresses.  Linkers that are not installed are left out; the
+# .x file skips the test if neither is.
+#
+
+dtrace=$1
+utils=$PWD/test/utils
+declare -A base=([bfd]=-Wl,-Ttext-segment=0x200000
+		 [lld]=-Wl,--image-base=0x200000)
+
+DIRNAME=$tmpdir/ufunc-loadbias.$$.$RANDOM
+mkdir -p $DIRNAME
+cd $DIRNAME
+
+cat > work.c <<EOF
+volatile unsigned long spin;
+
+__attribute__((noinline)) void work(void)
+{
+	unsigned long i;
+
+	for (i = 0; i < 20000000UL; i++)
+		spin += i;
+}
+EOF
+
+cat > main.c <<EOF
+#include <unistd.h>
+
+extern void work(void);
+
+int main(void)
+{
+	int i;
+
+	for (i = 0; i < 1000; i++) {
+		work();
+		usleep(1000);
+	}
+	return 0;
+}
+EOF
+
+status=0
+for ld in $($utils/linkers.sh); do
+	$CC -O0 -fuse-ld=$ld -fPIC -shared -o libwork-$ld.so work.c &&
+	$CC -O0 -fuse-ld=$ld -fPIC -shared ${base[$ld]} \
+	    -o libwork-$ld-base.so work.c || exit 1
+
+	for l in $ld $ld-base; do
+		$CC -fuse-ld=$ld -o main-$l main.c -L. -lwork-$l \
+		    -Wl,-rpath,$DIRNAME || exit 1
+		./main-$l &
+		pid=$!
+		$dtrace $dt_flags -qn '
+		profile-997 /pid == '$pid' && arg1 != 0/ { @[ufunc(arg1)] = count(); }
+		tick-1s { exit(0); }' > out-$l 2>&1
+		kill $pid
+		wait $pid 2> /dev/null
+
+		if ! awk -v f="libwork-$l.so\`work" '$1 == f { found = 1 }
+		    END { exit !found }' out-$l; then
+			echo "ERROR: libwork-$l.so: no sample in work():"
+			cat out-$l
+			status=1
+		fi
+	done
+done
+
+[ $status -eq 0 ] && echo success
+exit $status
diff --git a/test/unittest/profile-n/tst.ufunc-loadbias.x b/test/unittest/profile-n/tst.ufunc-loadbias.x
new file mode 100755
index 00000000..e5a3ad3e
--- /dev/null
+++ b/test/unittest/profile-n/tst.ufunc-loadbias.x
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

