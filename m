From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Sun, 18 Oct 2026 07:46:10 +0000
Subject: [PATCH 2/2] test: add pid probe test for noninvasively grabbed
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-bug005-pid-noninvasive-names-v1-2-417b0f34f0b8@d-matrix.ai>
References: <20261018-bug005-pid-noninvasive-names-v1-0-417b0f34f0b8@d-matrix.ai>
In-Reply-To: <20261018-bug005-pid-noninvasive-names-v1-0-417b0f34f0b8@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Alan Maguire <alan.maguire@oracle.com>, 
 Kris Van Hees <kris.van.hees@oracle.com>, dtrace-devel@oss.oracle.com, 
 Eugene Loh <eugene.loh@oracle.com>, Nick Alcock <nick.alcock@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792309584; l=4632;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=jMZCa4Uii02w74ugVb10B3j58wbzlGj1aAp9FgKCVwc=;
 b=lrPQ60FMiuAJFYQGzxLXtOyATCd+JRk73HPrgNNN7f7NR+XAm+35xyJjX1aj1hNeaaOsSoQwx
 Z0LMIDDFnUXAVKubFNTyo3DKShewEYAErOe4FcWRR95xKeiKf/vMw+S
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A process that is already being traced is always grabbed
noninvasively, whether or not it counts as a system daemon.  Run a
program as the ptrace() child of another process and check that pid$pid
probes on a.out:target, libwork.so:work and :target fire.  Without the
previous patch all three fail.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/pid/tst.noninvasive.r  |   1 +
 test/unittest/pid/tst.noninvasive.sh | 119 +++++++++++++++++++++++++++++++++++
 test/unittest/pid/tst.noninvasive.x  |  15 +++++
 3 files changed, 135 insertions(+)

diff --git a/test/unittest/pid/tst.noninvasive.r b/test/unittest/pid/tst.noninvasive.r
new file mode 100644
index 00000000..2e9ba477
--- /dev/null
+++ b/test/unittest/pid/tst.noninvasive.r
@@ -0,0 +1 @@
+success
diff --git a/test/unittest/pid/tst.noninvasive.sh b/test/unittest/pid/tst.noninvasive.sh
new file mode 100755
index 00000000..9ef9968a
--- /dev/null
+++ b/test/unittest/pid/tst.noninvasive.sh
@@ -0,0 +1,119 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check that pid$PID probes named by module and function fire in a process
+# that dtrace can only grab noninvasively: here, the ptrace() child of
+# another process.
+#
+# A noninvasive grab has no rtld_db, hence no link map, which is where
+# libproc otherwise gets each object's name.  The objects must be found by
+# the files they are mapped from: the executable as a.out, a library by its
+# base name, and every object for an empty module.
+#
+
+dtrace=$1
+
+DIRNAME=$tmpdir/pid-noninvasive.$$.$RANDOM
+mkdir -p $DIRNAME
+cd $DIRNAME
+
+cat > work.c <<EOT
+__attribute__((noinline)) int work(int i)
+{
+	return i * 3 + 1;
+}
+EOT
+
+cat > main.c <<EOT
+#include <unistd.h>
+
+extern int work(int);
+volatile int sink;
+
+__attribute__((noinline)) int target(int i)
+{
+	return i * 2 + 1;
+}
+
+int main(void)
+{
+	int i;
+
+	for (i = 0; i < 600; i++) {
+		sink = target(i) + work(i);
+		usleep(100000);
+	}
+	return 0;
+}
+EOT
+
+# tracer PROG: run PROG as a ptrace()d child, print its pid, and resume it
+# at every stop until it exits
+cat > tracer.c <<EOT
+#include <signal.h>
+#include <stdio.h>
+#include <sys/ptrace.h>
+#include <sys/wait.h>
+#include <unistd.h>
+
+int main(int argc, char **argv)
+{
+	pid_t pid;
+	int status, sig;
+
+	if ((pid = fork()) == 0) {
+		ptrace(PTRACE_TRACEME, 0, NULL, NULL);
+		execv(argv[1], &argv[1]);
+		_exit(127);
+	}
+	printf("%d\n", pid);
+	fflush(stdout);
+	while (waitpid(pid, &status, 0) == pid && WIFSTOPPED(status)) {
+		sig = WSTOPSIG(status) == SIGTRAP ? 0 : WSTOPSIG(status);
+		ptrace(PTRACE_CONT, pid, NULL, (void *)(long)sig);
+	}
+	return 0;
+}
+EOT
+
+$CC -O0 -fPIC -shared -o libwork.so work.c &&
+$CC -O0 -o main main.c -L. -lwork -Wl,-rpath,$DIRNAME &&
+$CC -o tracer tracer.c || exit 1
+
+./tracer ./main > pid &
+tracer=$!
+for i in $(seq 50); do
+	pid=$(cat pid)
+	[ -n "$pid" ] && grep -q libwork.so /proc/$pid/maps && break
+	sleep 0.1
+done 2> /dev/null
+
+# fired PROBE: how often PROBE fired in a second, or dtrace's error
+fired() {
+	$dtrace $dt_flags -qn "$1 { n++; }" \
+	    -n 'tick-1s { printf("%d\n", n); exit(0); }' 2>&1 |
+	    awk 'NF { last = $0 } END {
+		sub(/^dtrace: (invalid probe specifier .*: )?/, "", last)
+		print last
+	    }'
+}
+
+status=0
+for spec in a.out:target libwork.so:work :target; do
+	n=$(fired "pid$pid:$spec:entry")
+	case "$n" in
+	''|*[!0-9]*|0)
+		echo "ERROR: pid\$pid:$spec:entry: got '$n', want firings"
+		status=1;;
+	esac
+done
+
+kill $pid
+wait $tracer 2> /dev/null
+
+[ $status -eq 0 ] && echo success
+exit $status
diff --git a/test/unittest/pid/tst.noninvasive.x b/test/unittest/pid/tst.noninvasive.x
new file mode 100755
index 00000000..5c70ea6b
--- /dev/null
+++ b/test/unittest/pid/tst.noninvasive.x
@@ -0,0 +1,15 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# This test links its programs with $CC's default linker.
+
+if ! echo 'int main(void) { return 0; }' |
+    ${CC:-gcc} -x c -o /dev/null - > /dev/null 2>&1; then
+	echo "${CC:-gcc} cannot link"
+	exit 2
+fi
+exit 0

-- 
2.55.0

