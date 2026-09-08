From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Date: Tue, 08 Sep 2026 15:44:53 -0400
Subject: [PATCH 1/3] Update t4001 to use modern syntax.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-modernize-t4001-v1-1-cab3933a173f@fastmail.com>
References: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
In-Reply-To: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2308;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=tYfimROY4pM4hcIs4mrY96uFgq+P8MDoIKlkcUrM5Jw=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWpO7W2m265owa90T3lPVPFKvkMnWjax7cd3Rc/+L4r
 Eml4Qn8HaUsDGJcDLJiiiz//wk0vmJ5IOEX9O4TzBxWJpAhDFycAjCRpX8YGTb9YSicc0HuwG5n
 uXNKz1Qy9ee73Vi+jiPBSuCGoUNK62xGhispD857bGHe/85getSq3cdV5B58znplvXRG40+3tzl
 d59gB
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 t/t4001-diff-rename.sh   | 31 ++++++++++++++++---------------
 t/t4009-diff-rename-4.sh |  8 ++++----
 2 files changed, 20 insertions(+), 19 deletions(-)

diff --git a/t/t4001-diff-rename.sh b/t/t4001-diff-rename.sh
index ad474100af..2aa161c217 100755
--- a/t/t4001-diff-rename.sh
+++ b/t/t4001-diff-rename.sh
@@ -88,28 +88,29 @@ test_expect_success 'setup' '
 	EOF
 '
 
-test_expect_success \
-    'update-index --add a file.' \
-    'git update-index --add path0'
+test_expect_success 'update-index --add a file.' '
+    git update-index --add path0
+'
 
-test_expect_success \
-    'write that tree.' \
-    'tree=$(git write-tree) && echo $tree'
+test_expect_success 'write that tree.' '
+    tree=$(git write-tree) && echo $tree
+'
 
 sed -e 's/line/Line/' <path0 >path1
 rm -f path0
-test_expect_success \
-    'renamed and edited the file.' \
-    'git update-index --add --remove path0 path1'
 
-test_expect_success \
-    'git diff-index -p -M after rename and editing.' \
-    'git diff-index -p -M $tree >current'
+test_expect_success 'renamed and edited the file.' '
+    git update-index --add --remove path0 path1
+'
+
+test_expect_success 'git diff-index -p -M after rename and editing.' '
+    git diff-index -p -M $tree >current
+'
 
 
-test_expect_success \
-    'validate the output.' \
-    'compare_diff_patch current expected'
+test_expect_success 'validate the output.' '
+    compare_diff_patch current expected
+'
 
 test_expect_success 'test diff.renames=true' '
 	git -c diff.renames=true diff --cached $tree >current &&
diff --git a/t/t4009-diff-rename-4.sh b/t/t4009-diff-rename-4.sh
index 59e71e3acd..8f86dc7274 100755
--- a/t/t4009-diff-rename-4.sh
+++ b/t/t4009-diff-rename-4.sh
@@ -19,10 +19,10 @@ test_expect_success \
     tree=$(git write-tree) &&
     echo $tree'
 
-test_expect_success \
-    'prepare work tree' \
-    'sed -e 's/HOWEVER/However/' <COPYING >COPYING.1 &&
-    sed -e 's/GPL/G.P.L/g' <COPYING >COPYING.2 &&
+
+test_expect_success 'prepare work tree' '
+    sed -e "s/HOWEVER/However/" <COPYING >COPYING.1 &&
+    sed -e "s/GPL/G.P.L/g" <COPYING >COPYING.2 &&
     rm -f COPYING &&
     c1=$(git hash-object COPYING.1) &&
     c2=$(git hash-object COPYING.2) &&

-- 
2.53.0

