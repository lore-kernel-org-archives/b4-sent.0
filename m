From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH 0/2] leds: flash: leds-qcom-flash: update torch current
 clamp setting
Date: Fri, 25 Jul 2025 18:04:02 +0800
Message-Id: <20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJJWg2gC/x2MSQqAMAwAvyI5G6jBIvgV8RBq1IAbjYog/bvF4
 8DMvGASVQza4oUot5ruW4aqLCDMvE2COmQGcuRdQx5HffDcY5gxLLweqGaXYGDyVBEzUQ25PaJ
 k8f92fUofXhFmo2cAAAA=
X-Change-ID: 20250725-fix-torch-clamp-issue-ca25212aa224
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Fenglin Wu <quic_fenglinw@quicinc.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753437856; l=733;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=SHpZYFN+ikBn9ViyXM+75AUWEhtspSgSY6IAV+p9ryM=;
 b=lHYmwcmrhp6R+lF5W5Lz1phwfYVbW+JEVJAYsqUQ7FhtriLhZ6fqHBQs4FQTVbd3pwaOztg84
 ykPPgCPMljBCiOyT7mjuqeCbykNXqf1wWGFLZ62HL0iEkphAAhrzcjr
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a current clamp register needs to be updated when enabling
torch LED, and the register address is different between different
PMIC flash LED modules. Add changes to address it.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Fenglin Wu (2):
      leds: flash: leds-qcom-flash: update torch current clamp setting
      leds: flash: leds-qcom-flash: add a separate register map for PMI8998

 drivers/leds/flash/leds-qcom-flash.c | 41 ++++++++++++++++++++++++++++++++----
 1 file changed, 37 insertions(+), 4 deletions(-)
---
base-commit: 4903924ac7ef31fbbe48b3261b1bc86ce6cd7e97
change-id: 20250725-fix-torch-clamp-issue-ca25212aa224

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

