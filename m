From: Florian Schmaus <flo@geekplace.eu>
Date: Tue, 26 May 2026 10:01:08 +0200
Subject: [PATCH] selftests: Fix Makefile target for nsfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260526-kselftest-nsfs-v1-1-7b042ebe42d6@geekplace.eu>
X-B4-Tracking: v=1; b=H4sIAENTFWoC/3XMSw7CIBSF4a00dywGqGjqyH2YDnhcWtKmbbhIN
 A17Fzt3+J/kfDsQxoAE92aHiDlQWJca4tSAHfUyIAuuNkgur1yJlk2Es09IiS3kiRmjldfyYg2
 /QT1tEX14H+Czrz0GSmv8HH4Wv/UvlQUTTKnOmI47J0X7GBCnbdYWz/iCvpTyBTGZdsyvAAAA
X-Change-ID: 20260513-kselftest-nsfs-bba5fa24cb07
To: Shuah Khan <shuah@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Christian Brauner <brauner@kernel.org>
Cc: linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Florian Schmaus <flo@geekplace.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1450; i=flo@geekplace.eu;
 h=from:subject:message-id; bh=TUlHqQjYGKoBvaYsSZ35pR+AMu2KoxpwBqlSKvhoHdg=;
 b=owGbwMvMwMWoZLn8xddWhSDG02pJDFmiwa49cvcr12gyP+9Iu7VejtXJ6fXFJ8ILtZMvBO0xv
 /HKRCu/k3E9CwMjF8NMMUWW6aWs860U7zzMfvJ7HcwgViaQKdIiDQxAwMLAl5uYV2qkY6Rnqm2o
 Zwhk6BjFQ+T0GDQyi4tLU4t00wqKHPLySxJLMvPzivXyC1LzCtIL9NIy00oyMvKLilOBRujlpZZ
 YmpubGphauhk7Ghm6OLsamjm5mrg5OboaGRlbOpq7WriZWpgaGZgaMXBxCsBck1jD/t/dR57pxX
 rmR+3PvndWtWxSE605/9aXq6LCl/cJw8ONUwQT3Wpe7ejyb7/nMHPhhjlnyr6ej2o8yXDEwESgX
 dtfhL8s2r5RcNsOecnlHn3TWrx4L2SVMnBvvqdfY/jRpu9NVBBn6N6mT0LNzRqsrvZ3a3jubFHs
 NljCr2psN/WaR5ztCe6qMkufuLUBL9Okv1yzlanKZH+5wJWLLbHyzC3d4LpORkPuYkmrTX0Fqw8
 9PDXn0ZcZMjbbQ2vV9N5vORLza/HOnM5Jt/rZrhakC3ydqnBa3/1+d3DpIdUfHrPSbb1rlftvP9
 iUwr7hlVa1bVPCLvfIAIsuiyd/2Za7+6y8eKer8lEgQ+29P8cB
X-Developer-Key: i=flo@geekplace.eu; a=openpgp;
 fpr=1357B01865B2503C18453D208CAC2A9678548E35
X-Endpoint-Received: by B4 Relay for flo@geekplace.eu/default with auth_id=792
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kselftests for nsfs where moved under filesystem/ with
commit cae73d3bdce5 ("seltests: move nsfs into filesystems
subfolder"). However, the kselftest TARGETS declaration was not
adjusted.

Since the kselftest Makefile ignores errors unless no target builds,
the invalid target declaration can easily be missed.

Fix this by adjusting the TARGETS accordingly.

Fixes: cae73d3bdce5 ("seltests: move nsfs into filesystems subfolder")
Signed-off-by: Florian Schmaus <flo@geekplace.eu>
---
 tools/testing/selftests/Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/Makefile b/tools/testing/selftests/Makefile
index 6e59b8f63e41..641a180fb35f 100644
--- a/tools/testing/selftests/Makefile
+++ b/tools/testing/selftests/Makefile
@@ -37,6 +37,7 @@ TARGETS += filesystems/fat
 TARGETS += filesystems/overlayfs
 TARGETS += filesystems/statmount
 TARGETS += filesystems/mount-notify
+TARGETS += filesystems/nsfs
 TARGETS += filesystems/fuse
 TARGETS += filesystems/move_mount
 TARGETS += filesystems/empty_mntns
@@ -85,7 +86,6 @@ TARGETS += net/ppp
 TARGETS += net/rds
 TARGETS += net/tcp_ao
 TARGETS += nolibc
-TARGETS += nsfs
 TARGETS += pci_endpoint
 TARGETS += pcie_bwctrl
 TARGETS += perf_events

---
base-commit: 1d5dcaa3bd65f2e8c9baa14a393d3a2dc5db7524
change-id: 20260513-kselftest-nsfs-bba5fa24cb07

Best regards,
-- 
Florian Schmaus <flo@geekplace.eu>

