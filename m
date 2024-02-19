From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Feb 2024 03:34:13 +0800
Subject: [PATCH v5 2/5] mmc: dw_mmc-hi3798cv200: remove MODULE_ALIAS()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-b4-mmc-hi3798mv200-v5-2-f506c55f8e43@outlook.com>
References: <20240220-b4-mmc-hi3798mv200-v5-0-f506c55f8e43@outlook.com>
In-Reply-To: <20240220-b4-mmc-hi3798mv200-v5-0-f506c55f8e43@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708371252; l=722;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=MzqKbWX8E5l9h/hzBiWtMINHXtoCtQN0jkOqsqOv7OM=;
 b=Bkbs/tWN2onE0fLGjRMLTNg7wCp7OAIkTmcySRNxFXCkM1RZnu8uWY43nY65UTKj4IVAywetk
 0wUdrpDDF0RAChUwOFV37GTB4YGs0be3LZbYdpmbC94BQlXJSNR24uu
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The alias is not used and should be removed.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/mmc/host/dw_mmc-hi3798cv200.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/mmc/host/dw_mmc-hi3798cv200.c b/drivers/mmc/host/dw_mmc-hi3798cv200.c
index e9470c50a348..61923a518369 100644
--- a/drivers/mmc/host/dw_mmc-hi3798cv200.c
+++ b/drivers/mmc/host/dw_mmc-hi3798cv200.c
@@ -201,4 +201,3 @@ module_platform_driver(dw_mci_hi3798cv200_driver);
 
 MODULE_DESCRIPTION("HiSilicon Hi3798CV200 Specific DW-MSHC Driver Extension");
 MODULE_LICENSE("GPL v2");
-MODULE_ALIAS("platform:dwmmc_hi3798cv200");

-- 
2.43.0

