From: Taylor Jackson <taylor.a.jackson@me.com>
Date: Tue, 06 Feb 2024 15:17:52 +0000
Subject: [PATCH] fs/mnt_idmapping.c: Return -EINVAL when no map is written
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240206-mnt-idmap-inval-v1-1-68bfabb97533@me.com>
X-B4-Tracking: v=1; b=H4sIAJ9NwmUC/x2MWwqAIBAAryL7neCjIrpK9CG51kKaaEgQ3j3pc
 wZmXsiYCDPM7IWEhTJdoYHsGGyHCTtyso1BCdULJUbuw92UN5FTKObkcrLa6MFN2lloVUzo6Pm
 Py1rrBxyJvE5hAAAA
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Seth Forshee <sforshee@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Taylor Jackson <taylor.a.jackson@me.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707232700; l=891;
 i=taylor.a.jackson@me.com; s=20240206; h=from:subject:message-id;
 bh=2l2Nt8j5OYHJJurGGPNUw+7blMKm2R2dG9Yx/CViUyI=;
 b=KmXGWKD8500obyfmmDYWwluHofdz3w2KdArnaAT553VlbvcAPHEfkuirTLne5vUdfSQ0ybnv2
 5NsuDm3y269DxhGLXuFEhejM8RpOD4hmSb8MQKXBpti7AhwVCzH3aIW
X-Developer-Key: i=taylor.a.jackson@me.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for taylor.a.jackson@me.com/20240206 with auth_id=127
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This change will return an "invalid argument" error code when a map is
not provided when attempting to remap files using the id mapped mount
command, rather than returning nothing.

Signed-off-by: Taylor Jackson <taylor.a.jackson@me.com>
---
 fs/mnt_idmapping.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/mnt_idmapping.c b/fs/mnt_idmapping.c
index 64c5205e2b5e..3c60f1eaca61 100644
--- a/fs/mnt_idmapping.c
+++ b/fs/mnt_idmapping.c
@@ -214,7 +214,7 @@ static int copy_mnt_idmap(struct uid_gid_map *map_from,
 	 * anything at all.
 	 */
 	if (nr_extents == 0)
-		return 0;
+		return -EINVAL;
 
 	/*
 	 * Here we know that nr_extents is greater than zero which means

---
base-commit: 54be6c6c5ae8e0d93a6c4641cb7528eb0b6ba478
change-id: 20240206-mnt-idmap-inval-18d3a35f83fd

Best regards,
-- 
Taylor Jackson <taylor.a.jackson@me.com>

