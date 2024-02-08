From: Taylor Jackson <taylor.a.jackson@me.com>
Date: Thu, 08 Feb 2024 03:02:54 +0000
Subject: [PATCH v2] fs/mnt_idmapping.c: Return -EINVAL when no map is
 written
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240208-mnt-idmap-inval-v2-1-58ef26d194e0@me.com>
X-B4-Tracking: v=1; b=H4sIAF5ExGUC/3WNyw7CIBQFf6W5azE8bMWu/A/TBRSwNxFooCGah
 n8Xu3c5k5w5O2Sb0GYYux2SLZgxhgb81MG8qPC0BE1j4JRfKKcD8WFryquVYCjqRZg0QoneSeE
 MtNWarMP3UXxMjRfMW0yf46Cwn/3fKowwMkjtlNa3ay/E3dvzHD1MtdYvwx1MZKsAAAA=
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Seth Forshee <sforshee@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Taylor Jackson <taylor.a.jackson@me.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707361379; l=1297;
 i=taylor.a.jackson@me.com; s=20240206; h=from:subject:message-id;
 bh=y6gRCATQD4BQ+HtUr3Y6tmpmjhF1EH0eWIIzJbmFHZw=;
 b=xgJWSv9ONnVT6GLyCRj6fBt71hj75Q+dupY5rzp8TyN5h3llr5WNNsvfSWm0VOyXJP1K/yq6o
 323miYF4kyXCKxCPSsqNNvQBBGURN9XwnlJuC4SIqzgv2/LTWvpqcjR
X-Developer-Key: i=taylor.a.jackson@me.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for taylor.a.jackson@me.com/20240206 with auth_id=127
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, it is possible to create an idmapped mount using a user
namespace without any mappings. However, this yields an idmapped
mount that doesn't actually map the ids. With the following change,
it will no longer be possible to create an idmapped mount when using
a user namespace with no mappings, and will instead return EINVAL,
an “invalid argument” error code.

Reviewed-by: Christian Brauner <brauner@kernel.org>
Signed-off-by: Taylor Jackson <taylor.a.jackson@me.com>
---
Changes in v2:
- Updated commit message based on feedback 
- Link to v1: https://lore.kernel.org/r/20240206-mnt-idmap-inval-v1-1-68bfabb97533@me.com
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

