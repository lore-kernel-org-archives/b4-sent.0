From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 00:07:56 +0200
Subject: [PATCH] video: simplefb: add an a8r8g8b8 format with an opaque
 alpha
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-simplefb-a8r8g8b8-v1-1-ce7e80682a5c@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQBEmDV5EunDjREauS0VIQ7
 960Xb7F/ycoZ2GFpjoh80tU1qXA3iqIY7cMjNIXgzPOW2M9Uo0qz23mRNiFHIZAAV0f74bY1yk
 SlHTLnOT927aPv/WgieP+fcF1fQBSdF96eAAAAA==
X-Change-ID: 20261016-b4-simplefb-a8r8g8b8-2dc70be64fcb
To: u-boot@lists.u-boot-project.org
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Tom Rini <trini@konsulko.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Aelin Reidel <aelin@mainlining.org>, Luca Weiss <luca.weiss@fairphone.com>, 
 Simon Glass <sjg@chromium.org>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Quentin Schulz <quentin.schulz@cherry.de>, David Heidelberg <david@ixit.cz>, 
 Petr Pavlata <petr@acrux.cz>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792188481; l=3780;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=YOPmvffoCNj7UsY0sY0TJB0H0U4VwmiM/L0E2yVOwww=;
 b=BHw2g3kJGfT4+a2AfHiOvl0I2sdXwnBo9QWLTbuYQ67syAjpm27uoIJRirzU2zIOemtCkKSI6
 VXPQ0CgGXBvA5LqiOCKAHoTAbhoxzrYOcWqGLZP6/rAFInbO5yjz9Xl
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Map "a8r8g8b8" to a new VIDEO_A8R8G8B8 format that writes 0xff in the
alpha byte for the console colours and for the BMP/logo paths.

Adds support for the framebuffer on Xiaomi Redmi Note 8 Pro (begonia).

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Doing bringup on the Xiaomi Xiaomi Redmi Note 8 Pro (begonia) and
encountered the following frambuffer format.

For a simple-framebuffer node with format "a8r8g8b8" U-Boot currently writes
the pixels as x8r8g8b8 leaving the alpha byte zero. Therefore the console
background and logo are fully transparent and the screen stays black.
---
 drivers/video/simplefb.c     | 6 ++++--
 drivers/video/video-uclass.c | 5 +++++
 drivers/video/video_bmp.c    | 9 ++++++---
 include/video.h              | 1 +
 4 files changed, 16 insertions(+), 5 deletions(-)

diff --git a/drivers/video/simplefb.c b/drivers/video/simplefb.c
index 8d0772d4e51..3dc073bce9e 100644
--- a/drivers/video/simplefb.c
+++ b/drivers/video/simplefb.c
@@ -71,8 +71,10 @@ static int simple_video_probe(struct udevice *dev)
 		   strcmp(format, "x8b8g8r8") == 0) {
 		uc_priv->bpix = VIDEO_BPP32;
 		uc_priv->format = VIDEO_X8B8G8R8;
-	} else if (strcmp(format, "a8r8g8b8") == 0 ||
-		   strcmp(format, "x8r8g8b8") == 0) {
+	} else if (strcmp(format, "a8r8g8b8") == 0) {
+		uc_priv->bpix = VIDEO_BPP32;
+		uc_priv->format = VIDEO_A8R8G8B8;
+	} else if (strcmp(format, "x8r8g8b8") == 0) {
 		uc_priv->bpix = VIDEO_BPP32;
 		uc_priv->format = VIDEO_X8R8G8B8;
 	} else if (strcmp(format, "a2r10g10b10") == 0 ||
diff --git a/drivers/video/video-uclass.c b/drivers/video/video-uclass.c
index 53641fc28b6..68fd9ef38c0 100644
--- a/drivers/video/video-uclass.c
+++ b/drivers/video/video-uclass.c
@@ -354,6 +354,11 @@ u32 video_index_to_colour(struct video_priv *priv, enum colour_idx idx)
 				return (colours[idx].r << 24) |
 				       (colours[idx].g << 16) |
 				       (colours[idx].b << 8) | 0xff;
+			case VIDEO_A8R8G8B8:
+				return 0xff000000 |
+				       (colours[idx].r << 16) |
+				       (colours[idx].g <<  8) |
+				       (colours[idx].b <<  0);
 			default:
 				return (colours[idx].r << 16) |
 				       (colours[idx].g <<  8) |
diff --git a/drivers/video/video_bmp.c b/drivers/video/video_bmp.c
index 1f267d45812..98ed59e275e 100644
--- a/drivers/video/video_bmp.c
+++ b/drivers/video/video_bmp.c
@@ -88,7 +88,7 @@ static void write_pix8(u8 *fb, uint bpix, enum video_format eformat,
 			*fb++ = cte->blue;
 			*fb++ = cte->green;
 			*fb++ = cte->red;
-			*fb++ = 0;
+			*fb++ = eformat == VIDEO_A8R8G8B8 ? 0xff : 0;
 		}
 	}
 }
@@ -409,7 +409,8 @@ int video_bmp_display(struct udevice *dev, ulong bmp_image, int x, int y,
 						*fb++ = *bmap++;
 						*fb++ = *bmap++;
 						*fb++ = *bmap++;
-						*fb++ = 0;
+						*fb++ = eformat == VIDEO_A8R8G8B8 ?
+							0xff : 0;
 					}
 				}
 				fb -= priv->line_length + width * (bpix / 8);
@@ -447,7 +448,9 @@ int video_bmp_display(struct udevice *dev, ulong bmp_image, int x, int y,
 						*fb++ = *bmap++;
 						*fb++ = *bmap++;
 						*fb++ = *bmap++;
-						*fb++ = *bmap++;
+						/* blend on alpha */
+						*fb++ = eformat == VIDEO_A8R8G8B8 ?
+							(bmap++, 0xff) : *bmap++;
 					}
 				}
 				fb -= priv->line_length + width * (bpix / 8);
diff --git a/include/video.h b/include/video.h
index 9ea6b676463..71e9558dba1 100644
--- a/include/video.h
+++ b/include/video.h
@@ -67,6 +67,7 @@ enum video_format {
 	VIDEO_X8B8G8R8,
 	VIDEO_X8R8G8B8,
 	VIDEO_X2R10G10B10,
+	VIDEO_A8R8G8B8,
 };
 
 /**

---
base-commit: 1bcb2fe324180d0a8cfbdb0511737eba1d5b8550
change-id: 20261016-b4-simplefb-a8r8g8b8-2dc70be64fcb

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

