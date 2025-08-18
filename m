From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 18 Aug 2025 14:31:43 +0200
Subject: [PATCH] media: nxp: imx8-isi: Check whether pad is non-NULL before
 access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250818-imx8_isi-v1-1-e9cfe994c435@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAC4do2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0ML3czcCot4oDJdS1MTC0sLMyOLpCQzJaDygqLUtMwKsFHRsbW1ADT
 i1PdaAAAA
X-Change-ID: 20250818-imx8_isi-954898628bb6
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Stefan Riedmueller <s.riedmueller@phytec.de>, 
 Jacopo Mondi <jacopo@jmondi.org>, Christian Hemp <c.hemp@phytec.de>, 
 Guoniu Zhou <guoniu.zhou@nxp.com>
Cc: Dong Aisheng <aisheng.dong@nxp.com>, linux-media@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755520303; l=1552;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=AcOnQUcEtLtKRIGyS551I2XQVk8kQXwsf7E/+Yff8TA=;
 b=LxPyeY5OtSuWC0dqmLOomQR+CNhDogbAv7Ktm7eAvNyw3RLKGvRZnoWkjAVyF9zkpodT26fDt
 BSNSf84OWnoCe6aD49C3B4Ijd31VQ5j0Tg6aujoKeWnTgkb3HIY05zI
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

media_pad_remote_pad_first() can return NULL if no valid link is found.
Check for this possibility before dereferencing it in the next line.

Reported/investigated in [1]:

Link: https://lore.kernel.org/all/1536a61b-b405-4762-9fb4-7e257f95e49e@gocontroll.com/ [1]
Fixes: cf21f328fcaf ("media: nxp: Add i.MX8 ISI driver")
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
I'm not sure if this should be a dev_dbg(), just following the pattern
around it for now, also not sure if EPIPE is the correct error.
---
 drivers/media/platform/nxp/imx8-isi/imx8-isi-crossbar.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/media/platform/nxp/imx8-isi/imx8-isi-crossbar.c b/drivers/media/platform/nxp/imx8-isi/imx8-isi-crossbar.c
index ede6cc74c0234049fa225ad82aaddaad64aa53d7..1ed8b031178b7d934b04a8752747f556bd1fc5a9 100644
--- a/drivers/media/platform/nxp/imx8-isi/imx8-isi-crossbar.c
+++ b/drivers/media/platform/nxp/imx8-isi/imx8-isi-crossbar.c
@@ -160,6 +160,13 @@ mxc_isi_crossbar_xlate_streams(struct mxc_isi_crossbar *xbar,
 	}
 
 	pad = media_pad_remote_pad_first(&xbar->pads[sink_pad]);
+
+	if (pad == NULL) {
+		dev_dbg(xbar->isi->dev, "no valid link found to pad %u\n",
+			sink_pad);
+		return ERR_PTR(-EPIPE);
+	}
+
 	sd = media_entity_to_v4l2_subdev(pad->entity);
 	if (!sd) {
 		dev_dbg(xbar->isi->dev,

---
base-commit: 3ac864c2d9bb8608ee236e89bf561811613abfce
change-id: 20250818-imx8_isi-954898628bb6

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

