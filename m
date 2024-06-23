From: George Chan <gchan9527@gmail.com>
Date: Mon, 24 Jun 2024 07:22:44 +0800
Subject: [PATCH v2 5/8] Add debug log info to camss_enable_clocks function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240624-b4-sc7180-camss-v2-5-0dfecdc50073@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719184974; l=811;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=6aIAhDdR6ba+wStFSXsVTf8OUMR91nQ2Q2sdegpU84I=;
 b=nVTVcI2zBFK7DgJRrC8BySXVYzj3UDol6nS+rZRiLKHFSruoRZAaoPj/RVDpwaaZjiSJ8UH13
 R+aGtDssKe2CEuw3x9gprS7qtANiic5xi8BKZXDNpjHPc9BCfBim+/G
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Print out missing clock's name when doing camss_enable_clocks().

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/media/platform/qcom/camss/camss.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 86ba80c47188..d50f98565531 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -1467,7 +1467,7 @@ int camss_enable_clocks(int nclocks, struct camss_clock *clock,
 	for (i = 0; i < nclocks; i++) {
 		ret = clk_prepare_enable(clock[i].clk);
 		if (ret) {
-			dev_err(dev, "clock enable failed: %d\n", ret);
+			dev_err(dev, "clock enable failed: %s %d\n", clock[i].name, ret);
 			goto error;
 		}
 	}

-- 
2.34.1

