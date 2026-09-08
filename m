From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Date: Tue, 08 Sep 2026 15:44:55 -0400
Subject: [PATCH 3/3] Update t4010 to use modern style.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-modernize-t4001-v1-3-cab3933a173f@fastmail.com>
References: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
In-Reply-To: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3914;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=bAxyW5cKMBKDeqjkUFMgQbzWUqVHI8lm4LH44N6SDEE=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWpO5Zmu1sKcF5Iv2U8/VAx2aZGX+W2GbuVlxmdaJTX
 eF7cp9RRykLgxgXg6yYIsv/fwKNr1geSPgFvfsEM4eVCWQIAxenAEzk0W2GfwoHdn/JuC4tvjM5
 sfnnjbvXrn1+eGKV6wmtpocPDjWGVSoxMqx6MLudcdq6ex+lXJpufClQv8nYIl1lYfPofKxI/ix
 VAy4A
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 t/t4010-diff-pathspec.sh | 78 ++++++++++++++++++++++++------------------------
 1 file changed, 39 insertions(+), 39 deletions(-)

diff --git a/t/t4010-diff-pathspec.sh b/t/t4010-diff-pathspec.sh
index c84c3fa05b..59e4501203 100755
--- a/t/t4010-diff-pathspec.sh
+++ b/t/t4010-diff-pathspec.sh
@@ -13,67 +13,67 @@ Prepare:
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
+test_expect_success setup '
+    echo frotz >file0 &&
+    mkdir path1 &&
+    echo rezrov >path1/file1 &&
+    before0=$(git hash-object file0) &&
+    before1=$(git hash-object path1/file1) &&
+    git update-index --add file0 path1/file1 &&
+    tree=$(git write-tree) &&
+    echo "$tree" &&
+    echo nitfol >file0 &&
+    echo yomin >path1/file1 &&
+    after0=$(git hash-object file0) &&
+    after1=$(git hash-object path1/file1) &&
+    git update-index file0 path1/file1
+'
 
 cat >expected <<\EOF
 EOF
-test_expect_success \
-    'limit to path should show nothing' \
-    'git diff-index --cached $tree -- path >current &&
-     compare_diff_raw current expected'
+test_expect_success 'limit to path should show nothing' '
+    git diff-index --cached $tree -- path >current &&
+    compare_diff_raw current expected
+'
 
 cat >expected <<EOF
 :100644 100644 $before1 $after1 M	path1/file1
 EOF
-test_expect_success \
-    'limit to path1 should show path1/file1' \
-    'git diff-index --cached $tree -- path1 >current &&
-     compare_diff_raw current expected'
+test_expect_success 'limit to path1 should show path1/file1' '
+    git diff-index --cached $tree -- path1 >current &&
+    compare_diff_raw current expected
+'
 
 cat >expected <<EOF
 :100644 100644 $before1 $after1 M	path1/file1
 EOF
-test_expect_success \
-    'limit to path1/ should show path1/file1' \
-    'git diff-index --cached $tree -- path1/ >current &&
-     compare_diff_raw current expected'
+test_expect_success 'limit to path1/ should show path1/file1' '
+    git diff-index --cached $tree -- path1/ >current &&
+    compare_diff_raw current expected
+'
 
 cat >expected <<EOF
 :100644 100644 $before1 $after1 M	path1/file1
 EOF
-test_expect_success \
-    '"*file1" should show path1/file1' \
-    'git diff-index --cached $tree -- "*file1" >current &&
-     compare_diff_raw current expected'
+test_expect_success '"*file1" should show path1/file1' '
+    git diff-index --cached $tree -- "*file1" >current &&
+    compare_diff_raw current expected
+'
 
 cat >expected <<EOF
 :100644 100644 $before0 $after0 M	file0
 EOF
-test_expect_success \
-    'limit to file0 should show file0' \
-    'git diff-index --cached $tree -- file0 >current &&
-     compare_diff_raw current expected'
+test_expect_success 'limit to file0 should show file0' '
+    git diff-index --cached $tree -- file0 >current &&
+    compare_diff_raw current expected
+'
 
 cat >expected <<\EOF
 EOF
-test_expect_success \
-    'limit to file0/ should emit nothing.' \
-    'git diff-index --cached $tree -- file0/ >current &&
-     compare_diff_raw current expected'
+test_expect_success 'limit to file0/ should emit nothing.' '
+    git diff-index --cached $tree -- file0/ >current &&
+    compare_diff_raw current expected
+'
 
 test_expect_success 'diff-tree pathspec' '
 	tree2=$(git write-tree) &&

-- 
2.53.0

