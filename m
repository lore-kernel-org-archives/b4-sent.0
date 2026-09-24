From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:34 +0200
Subject: [PATCH 06/10] example/single_file: take no sector size from a
 regular backing file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-6-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1109; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=iQGI5XBpYIw9sZ1fmYdLA8tHv9gJ9aAV1u8DgxBr5lg=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnqqsH/O+lfO6vfa652jTqzjVuNSnajlHBSklqtbk
 HnhUnZ0RykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAExE7y7Df69090nhRxzjG+wf
 /FYPMGh+0b3Ph3ti3IJHqw3N+wRXnGVkuGrQ/7X10cM3i2dsEtnlXfhvw7HIIMYdnBXT1dad+zr
 1KzsA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

single_file_configure() took the sector size of a regular backing file
from st_blksize, and refused to start when it was larger than the page
size. For a regular file st_blksize is only a preferred I/O size, and
the file is not opened with O_DIRECT, so any offset works. NFS reports
1 MiB there, so service_ll and service_hl failed on an image on NFS
with "lba size 1048576 smaller than blocksize 4096".

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 example/single_file.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/example/single_file.c b/example/single_file.c
index 59dbc6bbac5e..4260ecf3c5f5 100644
--- a/example/single_file.c
+++ b/example/single_file.c
@@ -887,7 +887,8 @@ int single_file_configure(const char *device, const char *filename)
 		perror(device);
 		return -1;
 	}
-	lbasize = stbuf.st_blksize;
+	/* A regular file takes any offset; its st_blksize is only an I/O hint */
+	lbasize = S_ISBLK(stbuf.st_mode) ? stbuf.st_blksize : 1;
 	backing_size = stbuf.st_size;
 
 	if (S_ISBLK(stbuf.st_mode)) {

-- 
2.53.0

