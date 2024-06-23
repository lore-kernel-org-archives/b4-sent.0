From: George Chan <gchan9527@gmail.com>
Date: Mon, 24 Jun 2024 07:22:45 +0800
Subject: [PATCH v2 6/8] Add debug log info to msm_csid_subdev_init function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240624-b4-sc7180-camss-v2-6-0dfecdc50073@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719184974; l=892;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=xalkNP77MBkGfMNCvE+EDKlSV1hYrIaNytEu+tgrW+s=;
 b=DhNwZ3i0n2A6g2xn04mAHFVW0aP5PSgdJNKSdD6r8n7PdY51bQlsdfAHt0/VTvjyyOGrFvgk5
 uUUNtXfX8LJDriZKfAHFJuTMZBWqB+oFnKpt1uCkzKvd9nzn0D+PPp+
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Print out missing clock's name when doing msm_csid_subdev_init().

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index eb27d69e89a1..02162bf9dbc0 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -628,8 +628,10 @@ int msm_csid_subdev_init(struct camss *camss, struct csid_device *csid,
 		struct camss_clock *clock = &csid->clock[i];
 
 		clock->clk = devm_clk_get(dev, res->clock[i]);
-		if (IS_ERR(clock->clk))
+		if (IS_ERR(clock->clk)) {
+			dev_err(dev, "missing clk %s", res->clock[i]);
 			return PTR_ERR(clock->clk);
+		}
 
 		clock->name = res->clock[i];
 

-- 
2.34.1

