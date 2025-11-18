From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Tue, 18 Nov 2025 15:34:25 -0600
Subject: [PATCH RESEND v2] Make edit_in_editor use temporary file in Git
 repository
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-edit-with-tmp-file-in-repo-v2-1-0b633b471ddb@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAGDmHGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0ML3dSUzBLd8sySDN2S3ALdtMwcoIo83aLUgnzdpGSDFAMTM1MzM8N
 EJaABBUWpaZkVYMOjlYJcg139XJRia2sBrvDwf3QAAAA=
X-Change-ID: 20251118-edit-with-tmp-file-in-repo-bc0d0465661a
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763501669; l=1793;
 i=davemarq@linux.ibm.com; s=20250630; h=from:subject:message-id;
 bh=ngJvMGXX1Dy1JqdS+DDokUJ9Gr/lhNU5s71yzHfnFNg=;
 b=IT9xwP2MjpyFEL9n3PUSRlawabt1OX3jrgcCSu0kNIbLSw6Gb2E9B356jHZnkMiQE7moin/9t
 mxkhOQ1wUFFBeSQ7Bz7XkfRKGUsUS627nbd7jVRM04Wu0ahRRBkkzTd
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=eCwwhqOykPrqNNTH1uSGAhXUfNQI0Zlz7hb8uGTjPVU=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20250630 with auth_id=447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>



---
This is a resend of a patch I sent in June 2025. I noticed on
reinstalling b4 that this hadn't been included in recent releases, and
I couldn't find it in the master branch either.

In edit_with_editor, create temporary directory in toplevel/.git/b4 if
git top level exists. Otherwise let tempfile.TemporaryDirectory use
its default directory. This avoids issues with Emacs and Magit, which
insists COMMIT_EDITMSG must be in the repo's directory tree.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 src/b4/__init__.py | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index 7689550..cc7623a 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -4575,8 +4575,16 @@ def edit_in_editor(bdata: bytes, filehint: str = 'COMMIT_EDITMSG') -> bytes:
     corecfg = get_config_from_git(r'core\..*', {'editor': os.environ.get('EDITOR', 'vi')})
     editor = corecfg.get('editor')
     logger.debug('editor=%s', editor)
+
+    topdir = git_get_toplevel()
+    if topdir is not None:
+        p = Path(topdir)
+        p = p / '.git' / 'b4'
+        p.mkdir(parents=True, exist_ok=True)
+    else:
+        p = None
     # Use filehint name in hopes that editors autoload necessary highlight rules
-    with tempfile.TemporaryDirectory(prefix='b4-editor') as temp_dir:
+    with tempfile.TemporaryDirectory(prefix='b4-editor', dir=p) as temp_dir:
         temp_fpath = os.path.join(temp_dir, filehint)
         with open(temp_fpath, 'xb') as edit_file:
             edit_file.write(bdata)

---
base-commit: a6db3f06ce9836a7fc8921f588452804fc62bed1
change-id: 20251118-edit-with-tmp-file-in-repo-bc0d0465661a

Best regards,
--  
Dave Marquardt <davemarq@linux.ibm.com>

