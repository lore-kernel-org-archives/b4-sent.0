From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:31 +0200
Subject: [PATCH 03/10] mount_service: refuse OPEN after the MNTPT request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-3-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2878; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=7wcBx8/lW0cSYcKLbObPecvT5B5w3XTIogJlhwwIxeY=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnqSOOdkgtmixknZ8/6k65wRF49TuBi8aeKT9IZZE
 y070r5u6ShlYRDjYJAVU2TpkthjO+Ufn6za1/XXYeawMoEMYeDiFICJmD5k+Gf9Q9puRZTRh/SP
 lfHMSl+N34VLfrbZHHmn0UWs1dCwgo+R4e+bXdeSTDfKLWmJdkia1N0fOv0gw3LDwiTWa6veLEm
 fxgQA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fuse server sends fuservicemount3 a series of requests: OPEN for
its backing file, MNTPT to name the mount point, then MOUNT. The server
chooses the order. For a directory mount point, attach_to_mountpoint()
changes the working directory of the helper to the mount point. The
helper then mounts on ".", so a rename of the path cannot redirect the
mount.

A relative path in an OPEN request after MNTPT resolved inside the
mount point. For "fuservicemount3 disk.img /mnt -t fuse.service_ll",
an OPEN of "disk.img" matched the command line argument, but the helper
opened /mnt/disk.img, not disk.img in the user's working directory. The
helper now refuses OPEN once the mount point is set. No in-tree server
sends OPEN after MNTPT.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 doc/fuservicemount3.8  | 1 +
 include/fuse_service.h | 3 ++-
 util/mount_service.c   | 7 +++++++
 3 files changed, 10 insertions(+), 1 deletion(-)

diff --git a/doc/fuservicemount3.8 b/doc/fuservicemount3.8
index 06755d7c3c4e..9b8c752b3bb9 100644
--- a/doc/fuservicemount3.8
+++ b/doc/fuservicemount3.8
@@ -22,6 +22,7 @@ framework.
 The FUSE server may ask fuservicemount3 to open files on its behalf.
 fuservicemount3 opens only paths that appear verbatim on its command line
 and refuses any other request with EPERM.
+Requests after the server has sent the mount point are refused as well.
 
 The second form checks if there is a FUSE service available for the given
 filesystem type.
diff --git a/include/fuse_service.h b/include/fuse_service.h
index 3954f62aa2b8..56f40a44b670 100644
--- a/include/fuse_service.h
+++ b/include/fuse_service.h
@@ -139,7 +139,8 @@ int fuse_service_parse_cmdline_opts(struct fuse_args *args,
 
 /**
  * Ask the mount.service helper to open a file on behalf of the fuse server.
- * The helper refuses a path that is not verbatim on the mount command line;
+ * The helper refuses a path that is not verbatim on the mount command line,
+ * and any request made after the mount point was sent;
  * fuse_service_receive_file() then reports -EPERM.
  *
  * @param sf service context
diff --git a/util/mount_service.c b/util/mount_service.c
index 835d3d94aa4a..1f25dcde0349 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -801,6 +801,13 @@ static int mount_service_open_path(const struct mount_service *mo,
 		return mount_service_send_file_error(mo, EINVAL, oc->path);
 	}
 
+	/* After fchdir to the mountpoint, a relative path resolves there */
+	if (mo->mountpoint) {
+		fprintf(stderr, "%s: %s: files must be requested before the mount point\n",
+			mo->msgtag, oc->path);
+		return mount_service_send_file_error(mo, EPERM, oc->path);
+	}
+
 	/*
 	 * The file is opened outside the service sandbox, so only hand out
 	 * what the user named.

-- 
2.53.0

