From: David Heidelberg <david@ixit.cz>
Date: Sat, 13 Sep 2025 21:19:47 +0200
Subject: [PATCH v6 1/3] drm: panel: nt36672a: Make some command sequences
 optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250913-nt35596s-v6-1-b5deb05e04af@ixit.cz>
References: <20250913-nt35596s-v6-0-b5deb05e04af@ixit.cz>
In-Reply-To: <20250913-nt35596s-v6-0-b5deb05e04af@ixit.cz>
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Molly Sophia <mollysophia379@gmail.com>, 
 Arnaud Ferraris <arnaud.ferraris@collabora.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2103; i=david@ixit.cz;
 h=from:subject:message-id; bh=QTYZEo7wDH4JK80WKEmXRMnm9sUlw16EBzi/obT5zQ0=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGjFw9Wiz6mWj07JiHm6qevg86j9McXDcPlt/chYi0NaAMDNR
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJoxcPVAAoJEGACP8TTSSByOs0P/21U
 TZd6OHLvr3BU1Xdty/CGUydc1FZm6ai45xC1u3qU/2A8e62YzTdw2IzimQ7sOdBpMRy1Zzyco2d
 Njsnf9kVicuAKt96lmxmxqrbXAUiOpZy/nczu+HpsBwp/5ElvQtBfMdCodH0gXqXK3OTlkR84Ou
 xBGh2BmubM5Habr1Oz/hG4scz99+tbsK2wmYM3V+PactnIqK9F32E+2vOhYjPOUkTs3SQRaap4H
 GJi8g8IJiB9CmdCHde9lG5sZ6EaCkBvXb6RYyt3l+PEsqhlT7IsWPLddLX4rkDqsuV9nrTiCnRv
 J5gTt4NNa2DF6Wts6lmn45LYa1GS+pcJWkq54n8/wcO1AuBZeblHjo3KgPi518LsRp/2Ka0/88M
 26tY5RLn/JJc0RQCUOhLMB1+YLILkYDx/Iz9H+JulJq2Mv53NFpOxAxylg7lXby7mMTTwy29mUz
 pL8vB04bbgzUTHssVbT/TkoG3aZia6Zh0ZZc/J9p9LjGJaFOmZ1N1GYeCqrnNZZu5oLxGpMzTMQ
 RIPqETejk8aPGN4oT3k5dDwZMWsPnuKU86Nf3aEVo5QDAXUzC+S86KLD4Z5MBPD4F3Td9DQrCIB
 BbEECYECD7i2xpjlgiIoDpgj/g6vldfR7q0uVWOikwpJismepvj3lr0MDa3swORiLT3zGsRlKHt
 6Dvhx
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Molly Sophia <mollysophia379@gmail.com>

Preparation for the follow-up nt35596s support, where not all sequences
are provided.

Signed-off-by: Molly Sophia <mollysophia379@gmail.com>
Signed-off-by: Arnaud Ferraris <arnaud.ferraris@collabora.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-novatek-nt36672a.c | 27 ++++++++++++++------------
 1 file changed, 15 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-novatek-nt36672a.c b/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
index 29e1f6aea48060384f4639999174b67097a6c8a7..f7518ec469176a4e2d4f2b03f8e77f03511a12a7 100644
--- a/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
+++ b/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
@@ -117,12 +117,13 @@ static int nt36672a_panel_unprepare(struct drm_panel *panel)
 	struct nt36672a_panel *pinfo = to_nt36672a_panel(panel);
 	int ret;
 
-	/* send off cmds */
-	ret = nt36672a_send_cmds(panel, pinfo->desc->off_cmds,
-				 pinfo->desc->num_off_cmds);
-
-	if (ret < 0)
-		dev_err(panel->dev, "failed to send DCS off cmds: %d\n", ret);
+	if (pinfo->desc->num_off_cmds != 0) {
+		/* send off cmds if present */
+		ret = nt36672a_send_cmds(panel, pinfo->desc->off_cmds,
+					 pinfo->desc->num_off_cmds);
+		if (ret < 0)
+			dev_err(panel->dev, "failed to send DCS off cmds: %d\n", ret);
+	}
 
 	ret = mipi_dsi_dcs_set_display_off(pinfo->link);
 	if (ret < 0)
@@ -200,13 +201,15 @@ static int nt36672a_panel_prepare(struct drm_panel *panel)
 		goto poweroff;
 	}
 
-	/* Send rest of the init cmds */
-	err = nt36672a_send_cmds(panel, pinfo->desc->on_cmds_2,
-				 pinfo->desc->num_on_cmds_2);
+	if (pinfo->desc->num_on_cmds_2 != 0) {
+		/* Send rest of the init cmds if present */
+		err = nt36672a_send_cmds(panel, pinfo->desc->on_cmds_2,
+					 pinfo->desc->num_on_cmds_2);
 
-	if (err < 0) {
-		dev_err(panel->dev, "failed to send DCS Init 2nd Code: %d\n", err);
-		goto poweroff;
+		if (err < 0) {
+			dev_err(panel->dev, "failed to send DCS Init 2nd Code: %d\n", err);
+			goto poweroff;
+		}
 	}
 
 	msleep(120);

-- 
2.51.0

