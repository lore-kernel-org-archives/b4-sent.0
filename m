From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:46 +0100
Subject: [PATCH v2 12/12] drm/panel: sofef00: Non-continuous mode and video
 burst are supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-12-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=802; i=david@ixit.cz;
 h=from:subject:message-id; bh=OE1UAGoiypb8yw70x3xMaGL61XZlHwmG/9vzbFRjYK8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwVlzxcTH43qFIgD1KeqqVc+hIM0YBZcnxct
 +/4Os9eYZuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFQAKCRBgAj/E00kg
 cpu6EADNb3oMH/dyM3eFqfmZwlMVEwrACCIRZysVcIzs9Exj+pK1EtPklFvQtPe51Zy8cq6+BoV
 I/VWjBWU61WgHNTRk3u+pPMnJPM1iEBs6NbhH7XiGNHR5nZqQu7HTmMDDyU7q4PoNeXz74m5MaT
 j8GF8GhLkQodcCQ3VMKSzbNMQij8xJu8ZmxOMF3J9rbN1qQjlGnioxlKS5Qi7IJnhSJFxkYFdhC
 hVbnvErRCiap/Lf+r3AQ9JujZiYRhtE78vDaRcGkwVdFMCiQ1UJfApoh9r2pZ3//E4T5H9S0Wbk
 xIDN17ni2z58jGF00iFOOetDX2BhA0/9agxUUL3Yo6hQiizXX/lujDNf0FLDLEU6FTIiFPp4JZT
 VaVeWi4nzJkEfRC9awIxeKWdFtbdO7Yl5cIfnEh1TTlZ+yI9tzHEmeDxO/2fh4TZSSkMY8Lg3TV
 BKXBal4GfW/C/oniamNbZRmLp9P0bzOOjBFGGcqrUtS7uYXNlpsQfmBlmcU/Qq76etBkhkI1kI4
 aj6SjOCd4ncoaE131T8vGCmgyKGhRbPzTT0Sh7Mj/GjrzmKjZD9ZVsdYktAQpmixQMZKDHPtyLw
 K28YEkBQaNwODnumgKKmDl9YwYD0rmvJqE/y/Gs0DtdBbLk+ffzMOsH+yhmGZ8pPqWxcTdaHVUe
 qwQUmeS+ZPhuq6w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The panel supports both modes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 8286cad385738..b330c4a1ad19d 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -236,7 +236,8 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
-	dsi->mode_flags = MIPI_DSI_MODE_LPM;
+	dsi->mode_flags = MIPI_DSI_MODE_VIDEO_BURST |
+			  MIPI_DSI_CLOCK_NON_CONTINUOUS | MIPI_DSI_MODE_LPM;
 
 	ctx->panel.prepare_prev_first = true;
 

-- 
2.51.0

