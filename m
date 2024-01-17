From: Janne Grunau <j@jannau.net>
Date: Wed, 17 Jan 2024 23:29:29 +0100
Subject: [PATCH] video: console: Fix buffer overflow in cmd 'font list'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240117-cmd_font_bitmap_segfault-v1-1-26a9239b3831@jannau.net>
X-B4-Tracking: v=1; b=H4sIAMlUqGUC/x3MQQqEMAxA0atI1hZMEEWvIlJqTTWgVdrOIIh3t
 7h8i/9viByEI/TFDYH/EuXwGVgWYFfjF1YyZwNVVFeIrbL7rN3hk54k7ebUkRdnfltS1lGHTA2
 hRcj5GdjJ9a2H8XleBj1x0moAAAA=
To: Anatolij Gustschin <agust@denx.de>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=870; i=j@jannau.net;
 h=from:subject:message-id; bh=oLWLRpQevmWiJT2aHHLeLaW3z9ApfhZ2ZwzHiJ6rOn4=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtQVIaf3PXnjHeGebWX+6dHqYtk6kThugevXPdekG+04w
 1PslqHbUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgFYCKxYgx/pcW1fRbrli7h1J8w
 hUnT/LTc/dVvD5zc8faxu9uHf6Zs2xkZngi8Xzn7rO+BTMkvL6Ns/p/83Kq+k0lLRjX4AEvQlvc
 f2QE=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vidconsole_ops.get_font is documented to return -ENOENT after the last
video_fontdata entry.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/video/console_core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/console_core.c b/drivers/video/console_core.c
index d17764d0b0..939363653f 100644
--- a/drivers/video/console_core.c
+++ b/drivers/video/console_core.c
@@ -225,7 +225,7 @@ int console_simple_get_font(struct udevice *dev, int seq, struct vidfont_info *i
 {
 	info->name = fonts[seq].name;
 
-	return 0;
+	return info->name ? 0 : -ENOENT;
 }
 
 int console_simple_select_font(struct udevice *dev, const char *name, uint size)

---
base-commit: 866ca972d6c3cabeaf6dbac431e8e08bb30b3c8e
change-id: 20240117-cmd_font_bitmap_segfault-cf291e2621c1

Best regards,
-- 
Janne Grunau <j@jannau.net>

