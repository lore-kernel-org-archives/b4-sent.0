From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:47 +0200
Subject: [PATCH 04/11] drm/panel: s6e3ha8: Introduce AMB577PX01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-4-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1322; i=david@ixit.cz;
 h=from:subject:message-id; bh=vNLA8ljeR4J/HqPCfoTtAaLLmwPmUGSGqujdb8X7JAM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74ILPghpGdFk2JPKioQ/CBEKEUlRYPW8YCxR
 OabUG9VYbiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 criHEACyex0p+sdn2RW0coN+uPAHjIF1Nex/5Ut0SRCiQak8JtdRY2rPccdKuV+Fx2vMf/hxwW3
 vtNdETHNiKARn0KMVEAUltCQIZ4SI/e/8T8c94t/oeiGFzwOej8AaQ7O2s4RbRh4QbV4qme/qB2
 5W+YK0Nk9/HC0jziYJUREDXmChSvtN5QBMJKOoLA9cXiy/C0zF8enBd9m/MBtN7uFLZDrM2CupR
 2vzAL4SQ5TahFxyZNWmQISXJx3wFLhdcuL6L0wGkl0wO36dhV7Xybfp+zRoINtkooiWMoj8NVnX
 ayu3trGiLtsNqkMGhgn8Rr96OB4ez56UWrP79tCl84N5Z3TxuemfALA3EGDajqljptneSofmIDU
 cZ01utFMfAvy82fqWNx+efBLt1YXNREdPJhNFYnGzFLMFbDJvYkezEXuEAzZbCa61/PkAKo3gDX
 aRjeTETO5ZwIvciGFSP53cW5TMvx6sh2uKxYAeRsdIuLDx7vJ+v7vmWWcTc1MFfF2vF7TgL+QL3
 r+E7P/d/vReuV0fmb/FbL+TnYw6Qd4UT1c1jvnw2U/BO9HyXWuE5wS4+ZZ3qDR1JH4XEoFL+x1S
 ls2TiR2tKsgK8wORCRePpomYwYGvIRP+UmDNCN0qqgUQbe5p+IHOcUSdBcf1CIQgsVhyobKjUMo
 vMH3Cv9xY6ecJPQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Match on the new panel compatible, and keep
the deprecated DDIC-only one working for existing devicetrees.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 835121b322f4a..a0015ac0e2782 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -296,17 +296,18 @@ static int s6e3ha8_amb577px01_wqhd_probe(struct mipi_dsi_device *dsi)
 		dev_err(dev, "Failed to attach to DSI host: %d\n", ret);
 		return ret;
 	}
 
 	return 0;
 }
 
 static const struct of_device_id s6e3ha8_amb577px01_wqhd_of_match[] = {
-	{ .compatible = "samsung,s6e3ha8" },
+	{ .compatible = "samsung,s6e3ha8" }, /* deprecated */
+	{ .compatible = "samsung,s6e3ha8-amb577px01" },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, s6e3ha8_amb577px01_wqhd_of_match);
 
 static struct mipi_dsi_driver s6e3ha8_amb577px01_wqhd_driver = {
 	.probe = s6e3ha8_amb577px01_wqhd_probe,
 	.driver = {
 		.name = "panel-s6e3ha8",

-- 
2.55.0

