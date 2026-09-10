From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Date: Thu, 10 Sep 2026 13:07:35 -0400
Subject: [PATCH v2 3/3] Update t4010 to use modern style.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-modernize-t4001-v2-3-ac53e9f5d717@fastmail.com>
References: <20260910-modernize-t4001-v2-0-ac53e9f5d717@fastmail.com>
In-Reply-To: <20260910-modernize-t4001-v2-0-ac53e9f5d717@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3836;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=jbDFKk5FP41wRp0ysubaMC1p6nuvLVe5p07ZV5O63Pw=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWPX5Wrl9cqvjq1neLJayyCn9cE+dGfFy88OICR6FbM
 8zvL/oZ1lHKwiDGxSArpsjy/59A4yuWBxJ+Qe8+wcxhZQIZwsDFKQATOSjFyHBMujlB4ec2v4Kt
 DrdvLQhW+im7W6cj5nlyKOPcdwKycXcYGXb1COzscrnG3ZJR32DeoVd3eNLDXy9rbBb2303vW75
 BiAcA
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 t/t4010-diff-pathspec.sh | 88 +++++++++++++++++-------------------------------
 1 file changed, 31 insertions(+), 57 deletions(-)

diff --git a/t/t4010-diff-pathspec.sh b/t/t4010-diff-pathspec.sh
index 8d980823b0..76ddd3ff4e 100755
--- a/t/t4010-diff-pathspec.sh
+++ b/t/t4010-diff-pathspec.sh
@@ -13,60 +13,34 @@ Prepare:
 . ./test-lib.sh
 . "$TEST_DIRECTORY"/lib-diff.sh ;# test-lib chdir's into trash
 
-test_expect_success \
-    setup \
-    'echo frotz >file0 &&
-     mkdir path1 &&
-     echo rezrov >path1/file1 &&
-     before0=$(git hash-object file0) &&
-     before1=$(git hash-object path1/file1) &&
-     git update-index --add file0 path1/file1 &&
-     tree=$(git write-tree) &&
-     echo "$tree" &&
-     echo nitfol >file0 &&
-     echo yomin >path1/file1 &&
-     after0=$(git hash-object file0) &&
-     after1=$(git hash-object path1/file1) &&
-     git update-index file0 path1/file1'
-
-cat >expected <<\EOF
-EOF
-test_expect_success \
-    'limit to path should show nothing' \
-    'git diff-index --cached $tree -- path >current &&
-     compare_diff_raw current expected'
-
-cat >expected <<EOF
-:100644 100644 $before1 $after1 M	path1/file1
-EOF
-test_expect_success \
-    'limit to path1 should show path1/file1' \
-    'git diff-index --cached $tree -- path1 >current &&
-     compare_diff_raw current expected'
-
-cat >expected <<EOF
-:100644 100644 $before1 $after1 M	path1/file1
-EOF
-test_expect_success \
-    'limit to path1/ should show path1/file1' \
-    'git diff-index --cached $tree -- path1/ >current &&
-     compare_diff_raw current expected'
-
-cat >expected <<EOF
-:100644 100644 $before1 $after1 M	path1/file1
-EOF
-test_expect_success \
-    '"*file1" should show path1/file1' \
-    'git diff-index --cached $tree -- "*file1" >current &&
-     compare_diff_raw current expected'
-
-cat >expected <<EOF
-:100644 100644 $before0 $after0 M	file0
-EOF
-test_expect_success \
-    'limit to file0 should show file0' \
-    'git diff-index --cached $tree -- file0 >current &&
-     compare_diff_raw current expected'
+
+test_expect_success 'limit to path should show nothing' '
+	echo frotz >file0 &&
+	mkdir path1 &&
+	echo rezrov >path1/file1 &&
+	before0=$(git hash-object file0) &&
+	before1=$(git hash-object path1/file1) &&
+	git update-index --add file0 path1/file1 &&
+	tree=$(git write-tree) &&
+	echo "$tree" &&
+	echo nitfol >file0 &&
+	echo yomin >path1/file1 &&
+	after0=$(git hash-object file0) &&
+	after1=$(git hash-object path1/file1) &&
+	git update-index file0 path1/file1 &&
+	: >expected &&
+	git diff-index --cached $tree -- path >current &&
+	compare_diff_raw current expected
+'
+
+test_expect_success 'limit to path1 should show path1/file1' '
+	cat >expected <<-EOF &&
+	:100644 100644 $before1 $after1 M	path1/file1
+	EOF
+
+	git diff-index --cached $tree -- path1 >current &&
+	compare_diff_raw current expected
+'
 
 test_expect_success 'limit to path1/ should show path1/file1' '
 	cat >expected <<-EOF &&
@@ -80,7 +54,7 @@ test_expect_success '"*file1" should show path1/file1' '
 	cat >expected <<-EOF &&
 	:100644 100644 $before1 $after1 M	path1/file1
 	EOF
-    
+
 	git diff-index --cached $tree -- "*file1" >current &&
 	compare_diff_raw current expected
 '
@@ -89,13 +63,13 @@ test_expect_success 'limit to file0 should show file0' '
 	cat >expected <<-EOF &&
 	:100644 100644 $before0 $after0 M	file0
 	EOF
-    
+
 	git diff-index --cached $tree -- file0 >current &&
 	compare_diff_raw current expected
 '
 
 test_expect_success 'limit to file0/ should emit nothing.' '
-    : >expected &&     
+    : >expected &&
 	git diff-index --cached $tree -- file0/ >current &&
 	compare_diff_raw current expected
 '

-- 
2.53.0

