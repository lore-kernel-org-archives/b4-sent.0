From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 05 Jun 2026 16:49:08 -0500
Subject: [PATCH 2/2] soc: qcom: socinfo: Add CQ8725S SoC ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-cq8725s-soc-id-v1-2-bb1ef93de649@gmail.com>
References: <20260605-cq8725s-soc-id-v1-0-bb1ef93de649@gmail.com>
In-Reply-To: <20260605-cq8725s-soc-id-v1-0-bb1ef93de649@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780696163; l=731;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=wkySf1dgX9Cw4+8ob2ohV1kwlJW81Sedb4xXGiINUAU=;
 b=Vvly/oG1MGvCiurwMdwBi0y5wrzw4aKDl4gtomZNK0IQZPfuJOmP3MUP7ITEyoYD228Wee8Nm
 U7RBv/Zm2sEAlVWIyrFj8dJ8Ux9LYrJYAY4XHnK5Ssh/Wz44f5hsKxu
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Add the ID for the Qualcomm CQ8725S SoC which represents the Pakala
platform.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/qcom/socinfo.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/qcom/socinfo.c b/drivers/soc/qcom/socinfo.c
index af418adad7aaf3..2b1395a85af45e 100644
--- a/drivers/soc/qcom/socinfo.c
+++ b/drivers/soc/qcom/socinfo.c
@@ -540,6 +540,7 @@ static const struct soc_id soc_id[] = {
 	{ qcom_board_id(QCS9075) },
 	{ qcom_board_id(QCS615) },
 	{ qcom_board_id(SA8797P) },
+	{ qcom_board_id(CQ8725S) },
 	{ qcom_board_id(CQ7790M) },
 	{ qcom_board_id(CQ7790S) },
 	{ qcom_board_id(CQ2390M) },

-- 
2.53.0

