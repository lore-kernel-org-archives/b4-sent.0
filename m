From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Date: Tue, 08 Sep 2026 15:44:54 -0400
Subject: [PATCH 2/3] Update t4009 to use modern style.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-modernize-t4001-v1-2-cab3933a173f@fastmail.com>
References: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
In-Reply-To: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3467;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=xNAADiP1ADadN8yIjMs2daoM5SExxWFRw/MYta0bF8s=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWpO6OfX/Q8kWdzCTnotSy9JYo6W2L3nf7Xnj0adOlF
 K9l2x2LOkpZGMS4GGTFFFn+/xNofMXyQMIv6N0nmDmsTCBDGLg4BWAiFQUM/+u1n5zk/zHldytn
 25yqxV+qr+8O71uVl/+otXeLZlLFvm6G/1UZwmvb697Xzfot/09k2a8HVfFn1m6MmfcybO2M/9l
 Jb3gA
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 t/t4009-diff-rename-4.sh | 48 ++++++++++++++++++++++++------------------------
 1 file changed, 24 insertions(+), 24 deletions(-)

diff --git a/t/t4009-diff-rename-4.sh b/t/t4009-diff-rename-4.sh
index 8f86dc7274..198de5d039 100755
--- a/t/t4009-diff-rename-4.sh
+++ b/t/t4009-diff-rename-4.sh
@@ -10,15 +10,14 @@ test_description='Same rename detection as t4003 but testing diff-raw -z.
 . ./test-lib.sh
 . "$TEST_DIRECTORY"/lib-diff.sh ;# test-lib chdir's into trash
 
-test_expect_success \
-    'prepare reference tree' \
-    'COPYING_test_data >COPYING &&
-     echo frotz >rezrov &&
+test_expect_success  'prepare reference tree' '
+    COPYING_test_data >COPYING &&
+    echo frotz >rezrov &&
     git update-index --add COPYING rezrov &&
     orig=$(git hash-object COPYING) &&
     tree=$(git write-tree) &&
-    echo $tree'
-
+    echo $tree
+'
 
 test_expect_success 'prepare work tree' '
     sed -e "s/HOWEVER/However/" <COPYING >COPYING.1 &&
@@ -26,7 +25,8 @@ test_expect_success 'prepare work tree' '
     rm -f COPYING &&
     c1=$(git hash-object COPYING.1) &&
     c2=$(git hash-object COPYING.2) &&
-    git update-index --add --remove COPYING COPYING.?'
+    git update-index --add --remove COPYING COPYING.?
+'
 
 # tree has COPYING and rezrov.  work tree has COPYING.1 and COPYING.2,
 # both are slightly edited, and unchanged rezrov.  We say COPYING.1
@@ -44,16 +44,16 @@ COPYING
 COPYING.2
 EOF
 
-test_expect_success \
-    'validate output from rename/copy detection (#1)' \
-    'compare_diff_raw_z current expected'
+test_expect_success 'validate output from rename/copy detection (#1)' '
+    compare_diff_raw_z current expected
+'
 
 ################################################################
 
-test_expect_success \
-    'prepare work tree again' \
-    'mv COPYING.2 COPYING &&
-     git update-index --add --remove COPYING COPYING.1 COPYING.2'
+test_expect_success 'prepare work tree again' '
+    mv COPYING.2 COPYING &&
+    git update-index --add --remove COPYING COPYING.1 COPYING.2
+'
 
 # tree has COPYING and rezrov.  work tree has COPYING and COPYING.1,
 # both are slightly edited, and unchanged rezrov.  We say COPYING.1
@@ -69,9 +69,9 @@ COPYING
 COPYING.1
 EOF
 
-test_expect_success \
-    'validate output from rename/copy detection (#2)' \
-    'compare_diff_raw_z current expected'
+test_expect_success 'validate output from rename/copy detection (#2)' '
+    compare_diff_raw_z current expected
+'
 
 ################################################################
 
@@ -80,10 +80,10 @@ test_expect_success \
 # anything about rezrov or COPYING, since the revised again diff-raw
 # nows how to say Copy.
 
-test_expect_success \
-    'prepare work tree once again' \
-    'COPYING_test_data >COPYING &&
-     git update-index --add --remove COPYING COPYING.1'
+test_expect_success 'prepare work tree once again' '
+    COPYING_test_data >COPYING &&
+    git update-index --add --remove COPYING COPYING.1
+'
 
 git diff-index -z -C --find-copies-harder $tree >current
 cat >expected <<EOF
@@ -92,8 +92,8 @@ COPYING
 COPYING.1
 EOF
 
-test_expect_success \
-    'validate output from rename/copy detection (#3)' \
-    'compare_diff_raw_z current expected'
+test_expect_success 'validate output from rename/copy detection (#3)' '
+    compare_diff_raw_z current expected
+'
 
 test_done

-- 
2.53.0

