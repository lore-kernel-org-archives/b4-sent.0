From: Taylor Jackson <tjackson9431@gmail.com>
Date: Tue, 26 Mar 2024 20:33:52 +0000
Subject: [PATCH 2/2] vfs/idmapped_mounts.c: Change mount_setattr expected
 output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240326-mount-setattr-test-v1-2-c061b040d0f7@gmail.com>
References: <20240326-mount-setattr-test-v1-0-c061b040d0f7@gmail.com>
In-Reply-To: <20240326-mount-setattr-test-v1-0-c061b040d0f7@gmail.com>
To: fstests@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Taylor Jackson <tjackson9431@gmail.com>, 
 kernel test robot <oliver.sang@intel.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711485236; l=1608;
 i=tjackson9431@gmail.com; s=20240206; h=from:subject:message-id;
 bh=2hauqK72ItpVFiPIDTfm1+0Ak2rYzw7tFM3DP+H91uU=;
 b=sV5+jr4uCvsdK+uySs+MkAtagvqhBfdDtpJAWq8BurlIHYhWzLvNwre8oLUPmkW3mtZzTsQ4f
 CsZDldH5ELMBoO1nKCet2/npXcUL8+l38Icj2mQk9G99mR8xHpDw0gw
X-Developer-Key: i=tjackson9431@gmail.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for tjackson9431@gmail.com/20240206 with auth_id=145
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In kernel commit dacfd001eaf2 (“fs/mnt_idmapping.c: Return -EINVAL
when no map is written”), the behavior of mount_setattr changed to
return EINVAL when attempting to create an idmapped mount when using
a user namespace with no mappings. The following commit updates the test
to expect no mount to be created in that case. And since no mount is created,
this commit also removes the check for overflow IDs because it does not make
sense to check for overflow IDs for a mount that was not created.

Signed-off-by: Taylor Jackson <tjackson9431@gmail.com>
---
 src/vfs/idmapped-mounts.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/src/vfs/idmapped-mounts.c b/src/vfs/idmapped-mounts.c
index 34052ca3..f4dfc3f3 100644
--- a/src/vfs/idmapped-mounts.c
+++ b/src/vfs/idmapped-mounts.c
@@ -6667,7 +6667,7 @@ static int nested_userns(const struct vfstest_info *info)
 	}
 
 	if (sys_mount_setattr(fd_open_tree_level4, "", AT_EMPTY_PATH,
-			      &attr_level4, sizeof(attr_level4))) {
+			      &attr_level4, sizeof(attr_level4)) != -1 || errno != EINVAL) {
 		log_stderr("failure: sys_mount_setattr");
 		goto out;
 	}
@@ -6706,11 +6706,6 @@ static int nested_userns(const struct vfstest_info *info)
 			log_stderr("failure: check ownership %s", file);
 			goto out;
 		}
-
-		if (!expected_uid_gid(fd_open_tree_level4, file, 0, info->t_overflowuid, info->t_overflowgid)) {
-			log_stderr("failure: check ownership %s", file);
-			goto out;
-		}
 	}
 
 	/* Verify that ownership looks correct for callers in the first userns. */

-- 
2.34.1

