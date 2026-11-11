From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 11 Nov 2026 13:54:46 +0900
Subject: [PATCH 1/2] landlock: Fix landlock_restrict_self() failure on long
 executable paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-landlock-long-exe-v1-1-588cfd174a10@samsung.com>
References: <20261111-landlock-long-exe-v1-0-588cfd174a10@samsung.com>
In-Reply-To: <20261111-landlock-long-exe-v1-0-588cfd174a10@samsung.com>
To: =?utf-8?q?Micka=C3=ABl_Sala=C3=BCn?= <mic@digikod.net>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack@google.com>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Shuah Khan <shuah@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Dwi Siswanto <me@dw1.io>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack3000@gmail.com>, 
 linux-security-module@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372885; l=3932;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=f/18UpIHEi230vx5Ck3a8ZJ9SX6Z8YLTouikgG7pJjU=;
 b=lZtEj/fYt7MzgKNh5JAsBrOfa5F+2IWnMtSyCemCE/EOVEywBi5MDExD5cmbB8rPoEY24HC6S
 KbJ5auThT4eDTmbGYU3nETY59/zIMDOq2+DXamc9M8qY57RYXfx7l5D
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_current_exe() treats a d_path() error on the current executable as
a bug. But an absolute path is not bounded by PATH_MAX, and d_path()
returns -ENAMETOOLONG when the path does not fit in the
LANDLOCK_PATH_MAX_SIZE buffer.

An unprivileged task with such an executable triggers the
WARN_ON_ONCE(), and its landlock_restrict_self() call fails with
-ENAMETOOLONG.

The path is not used for enforcement. Record "<too_long>" instead, as
audit_log_d_path() does, and create the domain.

Reported-by: Dwi Siswanto <me@dw1.io>
Closes: https://lore.kernel.org/r/20261102022018.73143-1-me@dw1.io
Suggested-by: Dwi Siswanto <me@dw1.io>
Fixes: 1d636984e088 ("landlock: Add AUDIT_LANDLOCK_DOMAIN and log domain status")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 Documentation/admin-guide/LSM/landlock.rst |  3 ++-
 security/landlock/domain.c                 | 15 +++++++++++----
 security/landlock/domain.h                 |  3 ++-
 3 files changed, 15 insertions(+), 6 deletions(-)

diff --git a/Documentation/admin-guide/LSM/landlock.rst b/Documentation/admin-guide/LSM/landlock.rst
index 718e0d23ffb5..983223ce6818 100644
--- a/Documentation/admin-guide/LSM/landlock.rst
+++ b/Documentation/admin-guide/LSM/landlock.rst
@@ -104,7 +104,8 @@ AUDIT_LANDLOCK_DOMAIN
     - the enforcement ``mode``
     - the domain creator's ``pid``
     - the domain creator's ``uid``
-    - the domain creator's executable path (``exe``)
+    - the domain creator's executable path (``exe``), or ``"<too_long>"`` if
+      this path does not fit in the kernel buffer
     - the domain creator's command line (``comm``)
 
     Example::
diff --git a/security/landlock/domain.c b/security/landlock/domain.c
index 4c0b1f0e1db5..4c9858c11b3d 100644
--- a/security/landlock/domain.c
+++ b/security/landlock/domain.c
@@ -492,7 +492,8 @@ landlock_merge_ruleset(struct landlock_domain *const parent,
  * get_current_exe - Get the current's executable path, if any
  *
  * @exe_str: Returned pointer to a path string with a lifetime tied to the
- *           returned buffer, if any.
+ *           returned buffer, if any. It is "<too_long>" if the path does
+ *           not fit in this buffer.
  * @exe_size: Returned size of @exe_str (including the trailing null
  *            character), if any.
  *
@@ -502,6 +503,8 @@ landlock_merge_ruleset(struct landlock_domain *const parent,
 static const void *get_current_exe(const char **const exe_str,
 				   size_t *const exe_size)
 {
+	/* Cf. audit_log_d_path() */
+	static const char too_long_path[] = "<too_long>";
 	const size_t buffer_size = LANDLOCK_PATH_MAX_SIZE;
 	struct mm_struct *mm = current->mm;
 	struct file *file __free(fput) = NULL;
@@ -521,9 +524,13 @@ static const void *get_current_exe(const char **const exe_str,
 		return ERR_PTR(-ENOMEM);
 
 	exe = d_path(&file->f_path, buffer, buffer_size);
-	if (WARN_ON_ONCE(IS_ERR(exe)))
-		/* Should never happen according to LANDLOCK_PATH_MAX_SIZE. */
-		return ERR_CAST(exe);
+	if (IS_ERR(exe)) {
+		/* The path does not fit: it is not bounded by PATH_MAX. */
+		memcpy(buffer, too_long_path, sizeof(too_long_path));
+		*exe_size = sizeof(too_long_path);
+		*exe_str = buffer;
+		return no_free_ptr(buffer);
+	}
 
 	size = buffer + buffer_size - exe;
 	if (WARN_ON_ONCE(size <= 0))
diff --git a/security/landlock/domain.h b/security/landlock/domain.h
index 935e18b12b3c..d087882fd428 100644
--- a/security/landlock/domain.h
+++ b/security/landlock/domain.h
@@ -72,7 +72,8 @@ struct landlock_details {
 	/**
 	 * @exe_path: Executable path of the task that initially restricted
 	 * itself, at creation time.  Always NULL terminated, and never greater
-	 * than LANDLOCK_PATH_MAX_SIZE.
+	 * than LANDLOCK_PATH_MAX_SIZE. It is "<too_long>" if the path does not
+	 * fit.
 	 */
 	char exe_path[];
 };

-- 
2.43.0

