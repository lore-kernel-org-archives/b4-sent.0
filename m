From: Janne Grunau <j@jannau.net>
Date: Wed, 17 Jan 2024 23:27:34 +0100
Subject: [PATCH] video: Support VIDEO_X2R10G10B10 in truetype console
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240117-console_truetype_x2r10g10b10-v1-1-25b11c6d7e40@jannau.net>
X-B4-Tracking: v=1; b=H4sIAFVUqGUC/x3MQQrCMBAF0KuUWRuYCbENXkWkaPtbByQpkyqV0
 rsbXL7N26nAFIUuzU6GjxbNqUJODQ3Pe5rhdKwmzz6wSOeGnEp+oV/tjfW7oN+8Cc/CD2E3IUa
 cYxvawFSLxTDp9u+vt+P4ATVqE5tuAAAA
To: Anatolij Gustschin <agust@denx.de>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1524; i=j@jannau.net;
 h=from:subject:message-id; bh=VhuaE+WdSXG5cJBj7RmqpaXvyiL4ENZrweTmabGHOF8=;
 b=kA0DAAoWoRs8240vZWYByyZiAGWoVFeh7CRFgOOWMZF1bp0isOCC1xFVlsrkI4LKnrRO7ncaX
 oh1BAAWCgAdFiEEYivpiACrfCFcfeBWoRs8240vZWYFAmWoVFcACgkQoRs8240vZWb7rAD7BqJH
 LqSLm/V/bmyDU+1tdwXbF2ktlsbUe71dmhZznR8A/jhJ+28Q1Xe8uKtgmMbPbE60vJcLh53cvs0
 sl9I3NJcM
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without explicit support for VIDEO_X2R10G10B10 VIDEO_X8R8G8B8 white
will be rendered as cyan-ish. The conversion leaves to lowest 2 bits
unset for more compact code.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/video/console_truetype.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/video/console_truetype.c b/drivers/video/console_truetype.c
index 14fb81e956..547e5a8d9c 100644
--- a/drivers/video/console_truetype.c
+++ b/drivers/video/console_truetype.c
@@ -397,7 +397,10 @@ static int console_truetype_putc_xy(struct udevice *dev, uint x, uint y,
 
 					if (vid_priv->colour_bg)
 						val = 255 - val;
-					out = val | val << 8 | val << 16;
+					if (vid_priv->format == VIDEO_X2R10G10B10)
+						out = val << 2 | val << 12 | val << 22;
+					else
+						out = val | val << 8 | val << 16;
 					if (vid_priv->colour_fg)
 						*dst++ |= out;
 					else
@@ -911,7 +914,10 @@ static int truetype_set_cursor_visible(struct udevice *dev, bool visible,
 				for (i = 0; i < width; i++) {
 					int out;
 
-					out = val | val << 8 | val << 16;
+					if (vid_priv->format == VIDEO_X2R10G10B10)
+						out = val << 2 | val << 12 | val << 22;
+					else
+						out = val | val << 8 | val << 16;
 					if (vid_priv->colour_fg)
 						*dst++ |= out;
 					else

---
base-commit: 866ca972d6c3cabeaf6dbac431e8e08bb30b3c8e
change-id: 20240117-console_truetype_x2r10g10b10-fe88e5864640

Best regards,
-- 
Janne Grunau <j@jannau.net>

