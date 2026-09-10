From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Date: Thu, 10 Sep 2026 13:07:34 -0400
Subject: [PATCH v2 2/3] Update t4009 to use modern style.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-modernize-t4001-v2-2-ac53e9f5d717@fastmail.com>
References: <20260910-modernize-t4001-v2-0-ac53e9f5d717@fastmail.com>
In-Reply-To: <20260910-modernize-t4001-v2-0-ac53e9f5d717@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4663;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=aHQJ31CmjPuMd+DSJIB+ax1Dys+pJ8v7p02yCjw4tnQ=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWPX5q0FDLw5JXo1XMJSWmYHlKa8bNBcrd9e+uTlJMv
 G4QkTeho5SFQYyLQVZMkeX/P4HGVywPJPyC3n2CmcPKBDKEgYtTACZysonhD2evpfj0QJ3cWwe/
 fJYyOpwS/yX92izGiCtmmaybe/ZOs2b4zepw1rTj6v75h34w31n6fON+yQ69MMsrCtfnMfaevSv
 7ix0A
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 t/t4009-diff-rename-4.sh | 113 ++++++++++++++++++++++-------------------------
 1 file changed, 54 insertions(+), 59 deletions(-)

diff --git a/t/t4009-diff-rename-4.sh b/t/t4009-diff-rename-4.sh
index 198de5d039..7a48a7011c 100755
--- a/t/t4009-diff-rename-4.sh
+++ b/t/t4009-diff-rename-4.sh
@@ -10,67 +10,64 @@ test_description='Same rename detection as t4003 but testing diff-raw -z.
 . ./test-lib.sh
 . "$TEST_DIRECTORY"/lib-diff.sh ;# test-lib chdir's into trash
 
-test_expect_success  'prepare reference tree' '
+
+
+test_expect_success 'validate output from rename/copy detection (#1)' '
+    # prepare reference tree
     COPYING_test_data >COPYING &&
     echo frotz >rezrov &&
     git update-index --add COPYING rezrov &&
     orig=$(git hash-object COPYING) &&
     tree=$(git write-tree) &&
-    echo $tree
-'
-
-test_expect_success 'prepare work tree' '
+    echo $tree &&
+    # prepare work tree
     sed -e "s/HOWEVER/However/" <COPYING >COPYING.1 &&
     sed -e "s/GPL/G.P.L/g" <COPYING >COPYING.2 &&
     rm -f COPYING &&
     c1=$(git hash-object COPYING.1) &&
     c2=$(git hash-object COPYING.2) &&
-    git update-index --add --remove COPYING COPYING.?
-'
-
-# tree has COPYING and rezrov.  work tree has COPYING.1 and COPYING.2,
-# both are slightly edited, and unchanged rezrov.  We say COPYING.1
-# and COPYING.2 are based on COPYING, and do not say anything about
-# rezrov.
-
-git diff-index -z -C $tree >current
-
-cat >expected <<EOF
-:100644 100644 $orig $c1 C1234
-COPYING
-COPYING.1
-:100644 100644 $orig $c2 R1234
-COPYING
-COPYING.2
-EOF
-
-test_expect_success 'validate output from rename/copy detection (#1)' '
-    compare_diff_raw_z current expected
+	git update-index --add --remove COPYING COPYING.? &&
+
+	# tree has COPYING and rezrov.  work tree has COPYING.1 and COPYING.2,
+	# both are slightly edited, and unchanged rezrov.  We say COPYING.1
+	# and COPYING.2 are based on COPYING, and do not say anything about
+	# rezrov.
+
+    cat >expect <<-EOF &&
+	:100644 100644 $orig $c1 C1234
+	COPYING
+	COPYING.1
+	:100644 100644 $orig $c2 R1234
+	COPYING
+	COPYING.2
+	EOF
+
+    git diff-index -z -C $tree >actual &&
+    compare_diff_raw_z actual expect
 '
 
 ################################################################
 
-test_expect_success 'prepare work tree again' '
-    mv COPYING.2 COPYING &&
-    git update-index --add --remove COPYING COPYING.1 COPYING.2
-'
-
-# tree has COPYING and rezrov.  work tree has COPYING and COPYING.1,
-# both are slightly edited, and unchanged rezrov.  We say COPYING.1
-# is based on COPYING and COPYING is still there, and do not say anything
-# about rezrov.
-
-git diff-index -z -C $tree >current
-cat >expected <<EOF
-:100644 100644 $orig $c2 M
-COPYING
-:100644 100644 $orig $c1 C1234
-COPYING
-COPYING.1
-EOF
-
 test_expect_success 'validate output from rename/copy detection (#2)' '
-    compare_diff_raw_z current expected
+    # prepare work tree again
+    mv COPYING.2 COPYING &&
+    git update-index --add --remove COPYING COPYING.1 COPYING.2 &&
+
+	# tree has COPYING and rezrov.  work tree has COPYING and COPYING.1,
+	# both are slightly edited, and unchanged rezrov.  We say COPYING.1
+	# is based on COPYING and COPYING is still there, and do not say anything
+	# about rezrov.
+
+	git diff-index -z -C $tree >actual &&
+	cat >expect <<-EOF &&
+	:100644 100644 $orig $c2 M
+	COPYING
+	:100644 100644 $orig $c1 C1234
+	COPYING
+	COPYING.1
+	EOF
+
+    compare_diff_raw_z actual expect
 '
 
 ################################################################
@@ -80,20 +77,18 @@ test_expect_success 'validate output from rename/copy detection (#2)' '
 # anything about rezrov or COPYING, since the revised again diff-raw
 # nows how to say Copy.
 
-test_expect_success 'prepare work tree once again' '
-    COPYING_test_data >COPYING &&
-    git update-index --add --remove COPYING COPYING.1
-'
-
-git diff-index -z -C --find-copies-harder $tree >current
-cat >expected <<EOF
-:100644 100644 $orig $c1 C1234
-COPYING
-COPYING.1
-EOF
-
 test_expect_success 'validate output from rename/copy detection (#3)' '
-    compare_diff_raw_z current expected
+    # prepare work tree once again
+    COPYING_test_data >COPYING &&
+    git update-index --add --remove COPYING COPYING.1 &&
+    git diff-index -z -C --find-copies-harder $tree >actual &&
+    cat >expect <<-EOF &&
+	:100644 100644 $orig $c1 C1234
+	COPYING
+	COPYING.1
+	EOF
+
+    compare_diff_raw_z actual expect
 '
 
 test_done

-- 
2.53.0

