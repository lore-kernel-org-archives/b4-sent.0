From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 21 Mar 2025 13:47:26 +0100
Subject: [PATCH 3/4] sysctl: call sysctl tests with a for loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250321-jag-test_extra_val-v1-3-a01b3b17dc66@kernel.org>
References: <20250321-jag-test_extra_val-v1-0-a01b3b17dc66@kernel.org>
In-Reply-To: <20250321-jag-test_extra_val-v1-0-a01b3b17dc66@kernel.org>
To: Kees Cook <kees@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Shuah Khan <shuah@kernel.org>, John Sperbeck <jsperbeck@google.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1407;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=pDm2RKtKMseczShscO8UmtOM+OBDdzP3KgppVzDVCvA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfdYAj1VTNzzhCdo4uFhBpVgJh0tmg7KFxvR
 b25NxXekUiLW4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn3WAIAAoJELqXzVK3
 lkFP4RAL/jj/ahISU6Y7eCrqcrae6/t3XdMoNHXWa/1AXf0bWTJCKp+jVm1H3HErHsntU8SZ0Hw
 8MBxVCRSsDiX6l3MQyg3S5Q3DrMflT1ESSMvUyzdDLENq5n/yCYZ/1IqVJ60IeQt/ZJ1OjPPVMd
 AMOVr1iDpO5m+7fghdVqlnup+6izSRaL3dGG9EBDh7zMIm2dOb5RZ4qSZBjcgDoYq5MwuNyrIdo
 cl88YqbSb8oCH53zCIdq42tzwOl2d+rkb3myetz/oC1Wix+DMCD3fUJNwOs4Yk6rSCR25QeGgEg
 GIzcTZfEP2at2C4sCj9sO6pOEB4sQHg6J3e7y8fMkr6zKqII2a+3a8OFZf7+kkDytmqOjHPRpvy
 8nUI2OLJdikgn8hN6w0/Vf06GS9bAkOqItENFXr2T7GSLOQt7bRlY2EB1a6z15LGLVSVvtrpkRg
 768mNcGn33dQR6RqT80A1lbCf5gXqu+UaZ1LFOfqv2pmFW2cn6UZNRHJWMPxnvFGYE3nkKs5rA5
 2w=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As we add more test functions in lib/tests_sysctl the main test function
(test_sysctl_init) grows. Condense the logic to make it easier to
add/remove tests.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 lib/test_sysctl.c | 28 ++++++++++------------------
 1 file changed, 10 insertions(+), 18 deletions(-)

diff --git a/lib/test_sysctl.c b/lib/test_sysctl.c
index 54a22e4b134677e022af05df3c75268e7a4a79e7..4b3d56de6269b93220ecbeb3d3d4e42944b0ca78 100644
--- a/lib/test_sysctl.c
+++ b/lib/test_sysctl.c
@@ -301,27 +301,19 @@ static int test_sysctl_register_u8_extra(void)
 
 static int __init test_sysctl_init(void)
 {
-	int err;
+	int err = 0;
 
-	err = test_sysctl_setup_node_tests();
-	if (err)
-		goto out;
+	int (*func_array[])(void) = {
+		test_sysctl_setup_node_tests,
+		test_sysctl_run_unregister_nested,
+		test_sysctl_run_register_mount_point,
+		test_sysctl_run_register_empty,
+		test_sysctl_register_u8_extra
+	};
 
-	err = test_sysctl_run_unregister_nested();
-	if (err)
-		goto out;
+	for (int i = 0; !err && i < ARRAY_SIZE(func_array); i++)
+		err = func_array[i]();
 
-	err = test_sysctl_run_register_mount_point();
-	if (err)
-		goto out;
-
-	err = test_sysctl_run_register_empty();
-	if (err)
-		goto out;
-
-	err = test_sysctl_register_u8_extra();
-
-out:
 	return err;
 }
 module_init(test_sysctl_init);

-- 
2.47.2

