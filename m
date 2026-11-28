From: Silvio Unkovic <silvio.unkovic@pm.me>
Date: Sat, 28 Nov 2026 02:24:29 +0100
Subject: [PATCH] media: gspca: ov534: Relabel the 137 fps QVGA mode as 143
 fps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pseye-ov534-v1-1-a71e4661d994@pm.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyML3YLi1MpU3fwyU2MTXYNEs5SURGPzxERLYyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgBGSfMvbwAAAA==
X-Change-ID: 20261128-pseye-ov534-0a6dda37aa93
To: Hans Verkuil <hverkuil@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Silvio Unkovic <silvio.unkovic@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795829078; l=3137;
 i=silvio.unkovic@pm.me; s=20261128; h=from:subject:message-id;
 bh=8fULFlrKgnlUMHAfhORSxpngQfJXvNB/Ft2M6SHjW8A=;
 b=o4SsLptTWwuz1h/BEDYhy/x32HByRpK63H8pC0OsR9Gs21cPx1UEFR5pIwZyfQ77zSSkqPVSW
 apN0Zshs4RgB2by3nGhTwEWS4K0EDPff/LsqJfZeMDKrz1IsZaI6ufr
X-Developer-Key: i=silvio.unkovic@pm.me; a=ed25519;
 pk=EnRsDjntfFouyIMyaboNgoB+wQ65iMW873YmPIjPiII=
X-Endpoint-Received: by B4 Relay for silvio.unkovic@pm.me/20261128 with auth_id=1673
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The OV772x QVGA rate table has an entry labelled 137 fps using the
register values r11=0x02, r0d=0xc1, re5=0x02.  On a PlayStation Eye
(1415:2000) this setting delivers about 143 fps: 143.27 fps measured
shortly after plugging in, drifting down to about 141.3 fps as the
camera warms up.  All other entries in both tables deliver their
labelled rate to within 0.1% and do not drift.

No combination of the three registers used by the table gives 137 fps,
so relabel the entry with the rate it really produces.  The images in
this mode are valid.

Note that set_frame_rate() selects the highest entry not above the
requested rate, so a request for exactly 137 fps now selects 125 fps
instead of this mode.

Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Silvio Unkovic <silvio.unkovic@pm.me>
---
Tested on a PlayStation Eye (1415:2000, bcdDevice 2.00, sensor OV772x)
on 7.3.4 with ov534 rebuilt with this patch.  Rates were measured with
"v4l2-ctl --stream-mmap" in YUYV:

  label  measured        label  measured
  187    187.34          75     74.93
  150    149.87          60     59.95
  137    143.27..141.3   50     49.96
  125    124.89          37     37.47
  100    99.91           30     29.97

With the patch VIDIOC_ENUM_FRAMEINTERVALS lists 143 instead of 137 and
the other modes are unchanged.  This mode uses the same r0d/re5 pair as
the commented-out 205 fps entry, and it is the only one whose rate
drifts, so its clock may not be locked; I have not confirmed that.
Dropping the entry instead would also be fine with me.

Tool use: an AI coding assistant (Claude Code) did the measurements and
the analysis of the rate table, wrote the patch and drafted this
changelog, working on my machine with the camera attached.  I loaded
the modules, and reviewed the change and the results.
---
 drivers/media/usb/gspca/ov534.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/usb/gspca/ov534.c b/drivers/media/usb/gspca/ov534.c
index bdff64a29..5b7bd1922 100644
--- a/drivers/media/usb/gspca/ov534.c
+++ b/drivers/media/usb/gspca/ov534.c
@@ -116,7 +116,7 @@ static const struct v4l2_pix_format ov767x_mode[] = {
 		.colorspace = V4L2_COLORSPACE_JPEG},
 };
 
-static const u8 qvga_rates[] = {187, 150, 137, 125, 100, 75, 60, 50, 37, 30};
+static const u8 qvga_rates[] = {187, 150, 143, 125, 100, 75, 60, 50, 37, 30};
 static const u8 vga_rates[] = {60, 50, 40, 30, 15};
 
 static const struct framerates ov772x_framerates[] = {
@@ -828,7 +828,7 @@ static void set_frame_rate(struct gspca_dev *gspca_dev)
 /*		{205, 0x01, 0xc1, 0x02},  * 205 FPS: video is partly corrupt */
 		{187, 0x01, 0x81, 0x02}, /* 187 FPS or below: video is valid */
 		{150, 0x01, 0xc1, 0x04},
-		{137, 0x02, 0xc1, 0x02},
+		{143, 0x02, 0xc1, 0x02}, /* measured 141-143 FPS, not crystal-stable */
 		{125, 0x02, 0x81, 0x02},
 		{100, 0x02, 0xc1, 0x04},
 		{75, 0x03, 0xc1, 0x04},

---
base-commit: b7ac871daee981f1963f632586ff9b9d898ce5dd
change-id: 20261128-pseye-ov534-0a6dda37aa93

Best regards,
--  
Silvio Unkovic <silvio.unkovic@pm.me>

