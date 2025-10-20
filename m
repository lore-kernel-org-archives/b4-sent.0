From: George Chan <gchan9527@gmail.com>
Subject: [PATCH 0/2] Minor fixes for QCOM sc7180 soc
Date: Tue, 21 Oct 2025 00:23:57 +0800
Message-Id: <20251021-sc7180-minor-v1-0-9fe33c73365e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB1i9mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAyMD3eJkc0MLA93czLz8Il0zixRLkxRjA2MzgyQloJaCotS0zAqwcdG
 xtbUAXPf2sF4AAAA=
To: u-boot@lists.denx.de
Cc: George Chan <gchan9527@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760977468; l=563;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=rRdl5D5O+xYI2mdluE1GksWK6UhkW/zDEvGtV5sZRtM=;
 b=1q2xIX2oLSymu9aIW2grcn34H+h/ufE3gf4st2oLlkEzBBFmJLi7otqh9sG/DGtH9KHE2YUOK
 dVeDEpgtcLRBNSMfPyzfIXW/khw+3l58DsHR/zo+3K+vqvizMDnvBK7
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exclusively 2 minor patches for sc7180 splited from another series.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
George Chan (2):
      iommu: qcom-smmu: Introduce sc7180 compatible string
      usb: gadget: Introduce usb gadget vendor/product default id for ARCH_QCOM

 drivers/iommu/qcom-hyp-smmu.c | 1 +
 drivers/usb/gadget/Kconfig    | 2 ++
 2 files changed, 3 insertions(+)
---
base-commit: 4e4a9de31de2a5f395ee25c59e4026422fbcb27e
change-id: 20251020-sc7180-minor-68d94d30360b

Best regards,
-- 
George Chan <gchan9527@gmail.com>

