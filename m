From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:24:43 +0100
Subject: [PATCH 4/5] drm/panel: mantix: Drop bank 9 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-mantix-halo-fixes-v1-4-1ebc9b195a34@puri.sm>
References: <20260105-mantix-halo-fixes-v1-0-1ebc9b195a34@puri.sm>
In-Reply-To: <20260105-mantix-halo-fixes-v1-0-1ebc9b195a34@puri.sm>
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1501;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=fTacoISDzrsIe/qkVdq5L0I6TElHekwwcldH8QJ1a6M=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXB4fC5NgsqchE/2gem2pBTgPEsSA3MSi0AeWO
 a0p6kjY03eJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVweHwAKCRDo8jXPO9vD
 /wgLD/45bdk37+Gb53U6QZv9uoKXGGwyUaY8L/3KxnZ816JREFJ49oc5oHv/swwujzDgNXYSkTb
 TOu04mrc8hU7YVfkAKfW7Rrnxk5tSvHSbBntHTQEglk+9gneSqqPpx8YmIUs4v1OVBqMzvVtRBO
 +ss7uwqEF0/HLv+FP26GrlqYCCy42NOR0peZmsR7uZ/+a+qdMEj42FZfRDd7CFe2iH22RyNA+tU
 0+obpqQicZCcvunr340lUFVO3WdaNNOM+cpEK9kaar1s0y0BTdgCtG3yxeT2nJrxp+3fsDOK/qd
 rFw4YI44HHP1IetZFwZafTIkaSVJgFO3MB0eq0SY7gNRa9KFRn/bFBrWtWGoi0t+HO/VDNW6xY2
 lE04/oOuxsjWkEKDGCXh0TNgW6XR9Ujzuyub1FfhXn9SoUXMm2+G06lmPrSHCUbXXAz6jHfVAuU
 WtxCoZ2z0ViH4vxCn0tcXlZSbkRidO3ggWreQslxGYCZmhZkCzJrl0D3fLZWoM/UvqidBCRHYvR
 lqoqA+f5XAS1G8EZG/whvSPJd+rCgbykUt6WfZK8SSnYOgxyxVmSiWUELfNEBAAucoD5e1L+OOq
 QomC7CuMvCoZNosYJcbIPKyqVKztZCypXTOhGA5hkRh9E7toX83m1xALZqgl9D4x61e8wBWIu6U
 A/VGE19oyJt8jhw==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This command is part of LIC sequence included in FT8006P firmware.
There's no need to repeat it here.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
index 0e66ee7a727d..30e378faafcd 100644
--- a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
+++ b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
@@ -53,11 +53,9 @@ static void mantix_init_sequence(struct mipi_dsi_multi_context *dsi_ctx)
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x5a);
 
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_INT_CANCEL, 0x03);
-	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x5a, 0x03);
-	mipi_dsi_generic_write_seq_multi(dsi_ctx, 0x80, 0xa9, 0x00);
 
-	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x5a, 0x09);
-	mipi_dsi_generic_write_seq_multi(dsi_ctx, 0x80, 0x64, 0x00, 0x64, 0x00, 0x00);
+	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x5a, 0x03);
+	mipi_dsi_generic_write_seq_multi(dsi_ctx, 0x80, 0xa9, 0x00); /* VCOM */
 
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_SPI_FINISH, 0xa5);
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x00, 0x2f);

-- 
2.52.0

