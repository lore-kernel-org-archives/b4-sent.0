From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:29 +0800
Subject: [PATCH 14/21] media: i2c: it6625: fix link-frequency reporting for
 one-/two-trio C-PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-14-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=2869;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=Glt5rCqFCDYbF0ZgrcqztJES4wgIaxcox5FrgQZ10+8=;
 b=73roMt8CkxBrRlrslmG5oZj7S7/jyD2u1BiYkgxfhE29Zt2lvBj1Cb2nQd2C9NhxT0nnieF9s
 tfvoeg1g4NtCzmNCepCs/kG40qR2/r3qE01b+4VZMFgep0TYyHZTY+a
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_v4l2_init_controls() selected the 2.5 Gsym/s link-frequency
menu entry for any C-PHY configuration, but it6625_get_timings_cap()
only raises the DV-timings pixel-clock ceiling for three-trio C-PHY,
matching the actually-tested hardware capability. A one-/two-trio
C-PHY device was reporting an inflated V4L2_CID_LINK_FREQ.

Split the shared two-entry array into two single-entry arrays and
select between them with the same condition it6625_get_timings_cap()
uses (bus_type == V4L2_MBUS_CSI2_CPHY && csi_lanes == 3; C-PHY is only
ever set for IT6626, so this is equivalent to that function's chip-type
check as well). Name them for what they actually cover rather than for
a PHY type alone, since one-/two-trio C-PHY uses the low-rate array
too, not a "D-PHY" array.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 90b87dbf54fcfc7ad2a1245d4594beee24a193ca..882eda8b836d655585ba45b0a33d1c068bb3a8ee 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -317,11 +317,18 @@ struct it6625 {
 };
 
 /*
- * Index 0: D-PHY (4-lane). Index 1: C-PHY (3-trio) -- the confirmed
- * hardware max C-PHY capability, tested single-port/three-trio.
+ * Reported link frequency for every topology except the reference
+ * exception below: D-PHY (any lane count) and one-/two-trio C-PHY.
  */
-static const s64 it6625_link_freq[] = {
+static const s64 it6625_link_freq_default[] = {
 	445500000,
+};
+
+/*
+ * IT6626 C-PHY, three trios: the confirmed hardware max C-PHY
+ * capability, tested single-port/three-trio.
+ */
+static const s64 it6626_cphy_3trio_link_freq[] = {
 	2500000000LL,
 };
 
@@ -1850,6 +1857,8 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 	struct v4l2_ctrl_handler *hdl = &it6625->hdl;
+	bool cphy_3trio = it6625->bus_type == V4L2_MBUS_CSI2_CPHY &&
+			   it6625->csi_lanes == 3;
 
 	v4l2_ctrl_handler_init(hdl, 4);
 	it6625->ctrl_5v_detect =
@@ -1863,10 +1872,9 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 	it6625->ctrl_audio_present =
 		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_present, NULL);
 	it6625->ctrl_link_freq =
-		v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ,
-				       ARRAY_SIZE(it6625_link_freq) - 1,
-				       it6625->bus_type == V4L2_MBUS_CSI2_CPHY ? 1 : 0,
-				       it6625_link_freq);
+		v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ, 0, 0,
+				       cphy_3trio ? it6626_cphy_3trio_link_freq :
+						    it6625_link_freq_default);
 	if (hdl->error) {
 		v4l2_err(sd, "Failed to initialize controls");
 		v4l2_ctrl_handler_free(hdl);

-- 
2.34.1

