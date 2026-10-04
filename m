From: Ben Kuo <ben.kuo.tw@proton.me>
Date: Sun, 04 Oct 2026 16:49:17 +0800
Subject: [PATCH] man/man7/mount_namespaces.7: Add missing 'filesystemtype'
 argument to mount(2)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-mount-ns-mount-args-v1-1-a344b18c0c22@proton.me>
X-B4-Tracking: v=1; b=H4sIAAwTwmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwMT3dz80rwS3bxiKCOxKL1Y19LC0tIgLSUxyczSUgmos6AoNS2zAmx
 qdGxtLQCarbFsZQAAAA==
X-Change-ID: 20261004-mount-ns-mount-args-98990fdab699
To: Alejandro Colomar <alx@kernel.org>
Cc: linux-man@vger.kernel.org, Ben Kuo <ben.kuo.tw@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791103793; l=1247;
 i=ben.kuo.tw@proton.me; s=20261004; h=from:subject:message-id;
 bh=0hTM8yyVZi7R4ypo1hfKJWwCiZ9rEiA1Wk0lIvHRdeY=;
 b=jUYOYgGdNl3mLrxOG8sZfgNgw24FpfcqrKVh8wA86pxJMm0/Q9KhlbJx94BHtYdUBT1A6ksus
 oZdRFmRjEizANa/BT6qLVcaoMbuSJvbO+cSz4ZlG2zCbekKMJE4z3Xk
X-Developer-Key: i=ben.kuo.tw@proton.me; a=ed25519;
 pk=gXi9Dh9ncDWJiQmei79Ms5wulBAOhOVhaWE+qzS5nXY=
X-Endpoint-Received: by B4 Relay for ben.kuo.tw@proton.me/20261004 with auth_id=1107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The example call omits the 'filesystemtype' argument, so it passes
four arguments to mount(2), which takes five.  As written, it fails
to compile:

	error: too few arguments to function 'mount'

Tested by compiling the corrected call with gcc 14.2.0 and running
it after unshare(CLONE_NEWNS) on Linux 6.12 (Debian 13, arm64);
findmnt(8) shows '/' with slave propagation.

Fixes: a2fc45a9f (2019-10-07; "mount_namespaces.7: It may be desirable to disable propagation after creating a namespace")
Signed-off-by: Ben Kuo <ben.kuo.tw@proton.me>
---
 man/man7/mount_namespaces.7 | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/man/man7/mount_namespaces.7 b/man/man7/mount_namespaces.7
index 8ed43a34623310f5c0b6b2071815340b287415aa..8f9c8e6e147a42b85d9d2cc2c691037ef82395f5 100644
--- a/man/man7/mount_namespaces.7
+++ b/man/man7/mount_namespaces.7
@@ -1051,7 +1051,7 @@ using a call such as the following:
 .P
 .in +4n
 .EX
-mount(NULL, "/", MS_SLAVE | MS_REC, NULL);
+mount(NULL, "/", NULL, MS_SLAVE | MS_REC, NULL);
 .EE
 .in
 .P

---
base-commit: 31d36870d5f239d485772f1dbf17948bc35bee80
change-id: 20261004-mount-ns-mount-args-98990fdab699

Best regards,
-- 
Ben Kuo <ben.kuo.tw@proton.me>

