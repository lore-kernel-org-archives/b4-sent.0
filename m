From: George Chan <gchan9527@gmail.com>
Date: Mon, 24 Jun 2024 07:22:46 +0800
Subject: [PATCH v2 7/8] Add debug log info to vfe block init and set clock
 rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240624-b4-sc7180-camss-v2-7-0dfecdc50073@gmail.com>
References: <20240624-b4-sc7180-camss-v2-0-0dfecdc50073@gmail.com>
In-Reply-To: <20240624-b4-sc7180-camss-v2-0-0dfecdc50073@gmail.com>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, cros-qcom-dts-watchers@chromium.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719184974; l=1258;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=8g7c7y+bobDHCG87OSB8UdNx46oyvLYRoK1ecGyKT60=;
 b=TQ85B/lPVHtG5nfsfD/pB0LTzbsLt1MHncCyWrQ3FK94pgtLdjUZPMXrjQjqsl/oP1xoIEzpr
 cdAKlEFnX8XDxvX/NCQ0S70zYUWLQwaLrj0ruJRcZlNelKi6x0NHgFd
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Print out missing clock's name when doing msm_vfe_subdev_init().
Also print out min clock rate required at vfe_set_clock_rates().

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 05fa1adc1661..fbbf38755c0e 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -579,7 +579,8 @@ static int vfe_set_clock_rates(struct vfe_device *vfe)
 
 			if (j == clock->nfreqs) {
 				dev_err(dev,
-					"Pixel clock is too high for VFE");
+					"Pixel clock(%s) is too high for VFE, at least set to %lld",
+					 clock->name, min_rate);
 				return -EINVAL;
 			}
 
@@ -1452,8 +1453,10 @@ int msm_vfe_subdev_init(struct camss *camss, struct vfe_device *vfe,
 		struct camss_clock *clock = &vfe->clock[i];
 
 		clock->clk = devm_clk_get(dev, res->clock[i]);
-		if (IS_ERR(clock->clk))
+		if (IS_ERR(clock->clk)) {
+			dev_err(dev, "missing clk %s", res->clock[i]);
 			return PTR_ERR(clock->clk);
+		}
 
 		clock->name = res->clock[i];
 

-- 
2.34.1

