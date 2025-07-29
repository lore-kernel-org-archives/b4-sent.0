From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH v2 0/2] leds: flash: leds-qcom-flash: update torch current
 clamp setting
Date: Tue, 29 Jul 2025 12:51:21 +0800
Message-Id: <20250729-fix-torch-clamp-issue-v2-0-9b83816437a3@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAElTiGgC/4WNTQ6CQAyFr0JmbQlUkMSV9zAs6likCTA4FaIhc
 3crF3Dzku/l/WxOOQqrO2ebi7yKSpgM8JA539P0YJC7scMC66LBGjp5wytE34MfaJxBVBcGT1h
 jiUSIlbPuHNmC++61Ne5FrfTZb9by5/5bXEsooPLdkW9ElT81l6CaPxcafBjH3MS1KaUvXmf1f
 sEAAAA=
X-Change-ID: 20250725-fix-torch-clamp-issue-ca25212aa224
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753764686; l=1056;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=dKYGSCbks/KUDflV6ussEDmTnM88IuSNnO/6SfSJ1v4=;
 b=p9Dd8qj3QnbN00t2Peuil908E+TcycfB7gOqALi/uoCKxFI5+XdLiGUtTL2g7bhMGPcekUA2B
 V7TY8+rRf1GA86fo54pMZ1XRpqjVV2ljD9Ol9VD0QtVMOMQwpz2lWbH
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a current clamp register needs to be updated when enabling
torch LED, and the register address is different between different
PMIC flash LED modules. Add changes to address it.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Changes in v2:
- Update the register mapping to use designated initializers and ensure
  they are sorted by register address.
- Update the 'msb' of 'status1' register to 5 for pmi8998 flash LED
  module
- Link to v1: https://lore.kernel.org/r/20250725-fix-torch-clamp-issue-v1-0-4cf3ebaa4c67@oss.qualcomm.com

---
Fenglin Wu (2):
      leds: flash: leds-qcom-flash: update torch current clamp setting
      leds: flash: leds-qcom-flash: add a separate register map for PMI8998

 drivers/leds/flash/leds-qcom-flash.c | 87 +++++++++++++++++++++++++-----------
 1 file changed, 60 insertions(+), 27 deletions(-)
---
base-commit: 4903924ac7ef31fbbe48b3261b1bc86ce6cd7e97
change-id: 20250725-fix-torch-clamp-issue-ca25212aa224

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

