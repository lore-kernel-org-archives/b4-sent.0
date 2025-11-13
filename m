From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:41 +0100
Subject: [PATCH v2 07/12] drm/panel: sofef00: Add prepare_prev_first flag
 to drm_panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-7-e175053061ec@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=david@ixit.cz;
 h=from:subject:message-id; bh=4SM9hcft9HxR/OcdKpSF5Ee1W0Jyu8dLyBp//WZCcbk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwUfInDpnot2Lif7w3ILqlTPGJJ3Br0iShCu
 3feEgt+KOeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFAAKCRBgAj/E00kg
 cnYBEACQAwA9BeyyljPq7HJOHrhvZh9FYpzIvYsmzMx3dCPmLQ/Uuw3LgrnfNRZkC+Pw3exppn8
 jzW7JJE8SQTfdIpZ9KegVyMdvSGzayBPe/vya5/rpDatH1qHs2LDN1lWS1V2ZC64dqQjue/33nG
 Dupj+36uT2MTYklpig2tboB0osJHbvpPNPRLKkE3avGtHppiH7mVkA//heK4AEKvpFmAITJc0Qg
 D3vFzVAe5efNs2HDairb2vJSrMHPG9oevbvRhREYdQ7Iy1StCr6qaL/6lzkIDr/Boh1JdKb0zEg
 RDh3RTAHI4x7CrvIPy5MEHVx36S0ZDY90NDxQoOOW4QVNho2HUkrsT8lMImL/yUP7xz6hiCIdiD
 9SIgjrNey5IpWRhMOjKArSiwlVxxOB2t4QHqc64/cdNAf+6WYQSwBHnmox2t71YR4Ydhc0Yydy7
 wbCi6RffWzZOOK8fsLd9Q31rvBKAhzsk2RaSo4cX0EOwlY32dCQXqefs1uMh20IrUJWfHLEoGLh
 N3HWjT+TwPCtVeO/SBd1DZkef9+Utm+ks75ibtQ99W83nr3yyT3qfnZrILqV6n+tCUJgFEfRzNL
 QNYr2U7UuKm0a7SWVZaeYmPUEK1nAPoVUzrvOmiW/kn9LUPwUChXDnoccGnvvkCE8E5B98VFI+h
 CYW5lWzbe6JxS7w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This corrects the host initialisation sequence so that we can send
DSI/DCS commands in prepare().

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 97122ec8872a1..0d3ae0689a19b 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -242,6 +242,8 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 
+	ctx->panel.prepare_prev_first = true;
+
 	ctx->panel.backlight = sofef00_create_backlight(dsi);
 	if (IS_ERR(ctx->panel.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),

-- 
2.51.0

