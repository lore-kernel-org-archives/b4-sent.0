From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Wed, 18 Nov 2026 23:25:05 +0000
Subject: [PATCH 2/2] test: add test for system daemons with regular files
 as streams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-b4-bug008-daemon-readlink-v1-2-187c9eb22d11@d-matrix.ai>
References: <20261118-b4-bug008-daemon-readlink-v1-0-187c9eb22d11@d-matrix.ai>
In-Reply-To: <20261118-b4-bug008-daemon-readlink-v1-0-187c9eb22d11@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, 
 Nick Alcock <nix@esperi.org.uk>, Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044315; l=4037;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=yDF0D43XW758YL8hvfsIvhrmkyTvfY82BKQGj04GcnE=;
 b=7HjMy9rZZeOOm212xzsu9Kq1NbvObb7wdiQ2a/sDosP2xOXZQorC+RzJiEQ16vsY9Dc+08hWW
 8vl92DdiunSBazTNPhz/9E8Bp517OkpEt4LdnVmH7hxVtIIhUkOyzMb
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Start a root process without a terminal with its stdout to a regular
file outside /var, then to one under /var, and check how libproc
classifies it from DTRACE_DEBUG: not a system daemon, then a system
daemon.

libproc asks systemd whenever /run/systemd/system exists, and for a
process in a systemd slice the slice decides.  So on a systemd system
the test runs dtrace under unshare -m, in a mount namespace of its own
with a tmpfs over /run/systemd: libproc does not find systemd and uses
the rules under test.

The first case fails without the previous patch.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 test/unittest/proc/tst.system-daemon-files.r  |  2 +
 test/unittest/proc/tst.system-daemon-files.sh | 94 +++++++++++++++++++++++++++
 2 files changed, 96 insertions(+)

diff --git a/test/unittest/proc/tst.system-daemon-files.r b/test/unittest/proc/tst.system-daemon-files.r
new file mode 100644
index 00000000..0a2b3945
--- /dev/null
+++ b/test/unittest/proc/tst.system-daemon-files.r
@@ -0,0 +1,2 @@
+outside /var: not a system daemon
+under /var: system daemon
diff --git a/test/unittest/proc/tst.system-daemon-files.sh b/test/unittest/proc/tst.system-daemon-files.sh
new file mode 100755
index 00000000..a24b5eb1
--- /dev/null
+++ b/test/unittest/proc/tst.system-daemon-files.sh
@@ -0,0 +1,94 @@
+#!/bin/bash
+#
+# Oracle Linux DTrace.
+# Copyright (c) 2026, d-Matrix Corporation. All rights reserved.
+# Licensed under the Universal Permissive License v 1.0 as shown at
+# http://oss.oracle.com/licenses/upl.
+#
+# Check how libproc classifies a root process without a terminal when it
+# does not ask systemd: a standard stream to a regular file outside /var
+# means it is not a system daemon, one under /var does not.
+#
+# libproc asks systemd whenever /run/systemd/system exists, and for a
+# process in a systemd slice, as this one is, the slice decides and these
+# rules are never reached.  So on a systemd system, dtrace runs under
+# unshare -m, in a mount namespace of its own, with a tmpfs mounted over
+# /run/systemd: libproc does not find systemd and uses these rules.  The
+# namespace is made private first, so the rest of the system still sees
+# /run/systemd.
+#
+
+dtrace=$1
+
+DIRNAME=$tmpdir/system-daemon-files.$$.$RANDOM
+mkdir -p $DIRNAME
+cd $DIRNAME
+
+case $DIRNAME in
+/var/*)	echo "$DIRNAME is under /var"; exit 1;;
+esac
+VARFILE=$(mktemp /var/tmp/system-daemon-files.XXXXXX) || exit 1
+trap "rm -f $VARFILE" EXIT
+
+# main PIDFILE: leave the terminal's session, write the pid to PIDFILE and
+# sleep for a minute
+cat > main.c <<EOT
+#include <stdio.h>
+#include <unistd.h>
+
+int main(int argc, char **argv)
+{
+	FILE *f;
+	int i;
+
+	if (setsid() < 0 || (f = fopen(argv[1], "w")) == NULL)
+		return 1;
+	fprintf(f, "%d\n", getpid());
+	fclose(f);
+	for (i = 0; i < 600; i++)
+		usleep(100000);
+	return 0;
+}
+EOT
+$CC -o main main.c || exit 1
+
+# run_dtrace DTRACE ARGS: run dtrace, with /run/systemd hidden if it exists
+run_dtrace() {
+	if [ -d /run/systemd/system ]; then
+		unshare -m sh -c 'mount --make-rprivate / &&
+		    mount -t tmpfs none /run/systemd && exec "$@"' sh "$@"
+	else
+		"$@"
+	fi
+}
+
+# verdict LABEL FILE: run main with stdout to FILE and print LABEL and
+# libproc's verdict
+verdict() {
+	local pid out
+
+	rm -f pid
+	./main pid < /dev/null > $2 2> /dev/null &
+	for i in $(seq 50); do
+		[ -s pid ] && break
+		sleep 0.1
+	done
+	pid=$(cat pid)
+
+	out=$(DTRACE_DEBUG=t run_dtrace $dtrace $dt_flags \
+	    -ln "pid$pid:a.out:main:entry" 2>&1)
+	if grep -q " $pid is a system daemon process" <<< "$out"; then
+		echo "$1: system daemon"
+	elif grep -q "^ *[0-9]* *pid$pid " <<< "$out"; then
+		echo "$1: not a system daemon"
+	else
+		echo "$1: no verdict"
+		grep -v DEBUG <<< "$out" | tail -2
+	fi
+	kill $pid
+}
+
+verdict "outside /var" $DIRNAME/out.txt
+verdict "under /var" $VARFILE
+
+exit 0

-- 
2.55.0

