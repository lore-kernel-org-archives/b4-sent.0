From: =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
Subject: [PATCH 0/3] power: supply: qcom_battmgr: fix SM8350/SM8550 units,
 acks, and negative temp
Date: Thu, 19 Nov 2026 00:16:49 +0100
Message-Id: <20261119-upstream-qcom-battmgr-fixes-v1-v1-0-ca83700c08c1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQrDMAxA0asErSuwXHe8SunCcZTUBWeQnFAIu
 Xvcdvn48FdQlsgK92oF4SVqHPoCOlQQXr7vGGNTDNbYMxHdcB41C/uEUxgS1j7n1Am28cOKC6E
 xrj260/USnIUyGYV/rTwez791rt8c8vcK27YD2U51/IIAAAA=
X-Change-ID: 20261119-upstream-qcom-battmgr-fixes-v1-004f34587c42
To: Sebastian Reichel <sre@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org, 
 =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795043834; l=1715;
 i=alex.andries.aa@gmail.com; s=20261118; h=from:subject:message-id;
 bh=m10mZSU/1Zs9cTC5pq8aFlYb+YKIJMjUiK5nOQ8Ic5U=;
 b=14Lq8wuWQuoQc3cNz9//dLqgr1JXctqOo4kFuKLkJS5coL8EnvrYoqD4Hmn/Xuy24mz+804oV
 Ot47XW7aOgGDN+Xcx13lP93bzbL+7qiM343UtygdiLY50P/9tSM4AHS
X-Developer-Key: i=alex.andries.aa@gmail.com; a=ed25519;
 pk=kNAqgavfB7uUd1mA8o8TszhGxzyqBwY71PGO/oK4v84=
X-Endpoint-Received: by B4 Relay for alex.andries.aa@gmail.com/20261118 with auth_id=1564
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix three issues in qcom_battmgr encountered while bringing up PMIC GLINK
battery reporting on a Xiaomi MIX 4 (xiaomi-odin, SM8350):

1. Set battmgr->unit to QCOM_BATTMGR_UNIT_mAh on SM8350 and SM8550 so
   charge_full and charge_full_design stop returning -ENODATA.
2. Complete &battmgr->ack on invalid payload length errors in both
   callbacks so callers receive -ENODATA immediately instead of stalling
   for 1s with -ETIMEDOUT and aborting power_supply_uevent().
3. Change status.temperature and qcom_battmgr_sc8280xp_convert_temp() to
   int and cast SM8350 BATT_TEMP values to s32 before dividing by 10 so
   sub-zero temperatures do not wrap into large positive values.

Testing:
- Built warning-free (W=1) on arm64 against commit 97d73c825122.
- Tested on a Xiaomi MIX 4 (xiaomi-odin, SM8350) with UPower 1.91.0.
- The SM8550 variant in patch 1, the SC8280XP paths in patches 2 and 3,
  and sub-zero battery temperatures (< 0 C) in patch 3 were not
  hardware-tested.

AI disclosure:
- Debugged and drafted with assistance from Gemini 4 Carbon
  (Antigravity), and reviewed and tested on hardware by the submitter.

---
Alexandru Andrieș (3):
      power: supply: qcom_battmgr: set mAh unit for SM8350 and SM8550
      power: supply: qcom_battmgr: complete ack on callback payload errors
      power: supply: qcom_battmgr: fix negative temperature values

 drivers/power/supply/qcom_battmgr.c | 27 ++++++++++++++++-----------
 1 file changed, 16 insertions(+), 11 deletions(-)
---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261119-upstream-qcom-battmgr-fixes-v1-004f34587c42

Best regards,
--  
Alexandru Andrieș <alex.andries.aa@gmail.com>

