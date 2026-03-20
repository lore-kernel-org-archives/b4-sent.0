From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Fri, 20 Mar 2026 14:57:24 -0500
Subject: [PATCH b4] prep: Make `b4 prep --edit-cover` remove already_ran
 file under $GIT_DIR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-fix-edit-cover-with-workspace-v1-1-6023305b0f93@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0Q6CMAyF4VchvbbJHAaJr2K8YF2RasJIO8CE8
 O5OufxPcr4NjFXY4FZtoLyISRpLnE8V0NCNT0aJpcE737jaO+zlgxwlI6WFFVfJA65J3zZ1xEj
 BteTrNjbhCsWYlMvh798hXOBxbDaHF1P+wbDvXyti+g6FAAAA
X-Change-ID: 20260320-fix-edit-cover-with-workspace-cb08c238d6b7
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774036645; l=2942;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=wG9tDn/tdqEtNmXCivhG+G9IX8uEt4PbH8HvACzz4Hw=;
 b=yhu4x3KU5C9yEwIKnvDPhkVJPeFspiRBz1Hfv2FLpjkDz9oaN6Ouh8hoXu7jTXAO1A9CnAHT+
 J+z6FtalcOkAewTJTsfOhrgLsh4mX0CDqraptH3NQEfw7JCe79ECpiL
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>



---
The `b4 prep --edit-cover` code calls git-filter-repo to update the
cover letter. When using a Git worktree, the user may get a confusing
message like

    Invoking git-filter-repo to update the cover letter.
    The previous run is older than a day (/home/davemarq/linux/linux/.git/worktrees/ibmvfc-fpin-bis/filter-repo/already_ran already exists).
    See "Already Ran" section in the manual for more information.
    Treat this run as a continuation of filtering in the previous run (Y/N)? n

There's code in run_frf() that removes
<top-level>/.git/filter-repo/already_ran, which may have been left
behind by git-filter-repo. This doesn't work for Git worktrees, where
the file is $GIT_DIR/filter-repo/already_ran. GIT_DIR is set to a
worktree-unique directory under the repository top level directory in
the worktree case. This update uses $GIT_DIR, which works for both
repositories and worktrees.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 src/b4/__init__.py | 10 ++++++++++
 src/b4/ez.py       |  8 ++++----
 2 files changed, 14 insertions(+), 4 deletions(-)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index 46f3598..5a3c249 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -4029,6 +4029,16 @@ def git_get_toplevel(path: Optional[str] = None) -> Optional[str]:
         topdir = lines[0]
     return topdir
 
+def git_get_gitdir(path: Optional[str] = None) -> Optional[str]:
+    topdir = None
+    # Are we in a git tree and if so, what is our git-dir?
+    gitargs = ['rev-parse', '--git-dir']
+    lines = git_get_command_lines(path, gitargs)
+    if len(lines) == 1:
+        topdir = lines[0]
+        if not pathlib.PurePath(topdir).is_absolute():
+            topdir = Path.cwd().joinpath(topdir)
+    return topdir
 
 def git_get_common_dir(path: Optional[str] = None) -> Optional[str]:
     gitargs = ['rev-parse', '--git-common-dir']
diff --git a/src/b4/ez.py b/src/b4/ez.py
index 9b0e010..b7afab5 100644
--- a/src/b4/ez.py
+++ b/src/b4/ez.py
@@ -156,10 +156,10 @@ def run_frf(frf: fr.RepoFilter) -> None:
     logger.debug('Running git-filter-repo...')
     frf.run()
     logger.debug('git-filter-repo complete')
-    gtl = b4.git_get_toplevel()
-    if isinstance(gtl, str):
-        # Remove .git/filter-repo/already_ran
-        already_ran = os.path.join(gtl, '.git', 'filter-repo', 'already_ran')
+    gitdir = b4.git_get_gitdir()
+    if isinstance(gitdir, str):
+        # Remove $GIT_DIR/filter-repo/already_ran
+        already_ran = os.path.join(gitdir, 'filter-repo', 'already_ran')
         if os.path.exists(already_ran):
             logger.debug('Removing %s', already_ran)
             os.remove(already_ran)

---
base-commit: bc6c4d853c7eace3b7f325cbd17dfe2d67760fb7
change-id: 20260320-fix-edit-cover-with-workspace-cb08c238d6b7

Best regards,
--  
Dave Marquardt <davemarq@linux.ibm.com>

