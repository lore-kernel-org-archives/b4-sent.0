From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v5 0/3] ath10k: Introduce a devicetree quirk to skip host
 cap QMI requests
Date: Tue, 07 Apr 2026 08:43:53 +0200
Message-Id: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKmn1GkC/43OTU7DMBCG4atUXjOVf2LX6ar3QCwcZ5KMaOLUN
 lGhyt1xIiHBAsHG0rfwM++DJYyEiZ0PDxZxoURhKkM/HZgf3NQjUFs2k1xqIQSH9EozDCFl8G6
 E20gQ8QYotDbSYuNVzcrfOWJH9919fim7i2GEPER0uyYMF1xbbQWIujLlhZ4yJJxawNHRFdxI+
 Ti/TS3Fy5UmF8MxxH6jB0o5xPe9eJHbgb/iFgkceOu6ympX25O70L3o/oNtaYv6MgxXUv9mqGI
 0wijfnRrlrfhpVP8yqs3w3Gplq5LxrWNd10+QucI1iwEAAA==
X-Change-ID: 20251110-skip-host-cam-qmi-req-e155628ebc39
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2286; i=david@ixit.cz;
 h=from:subject:message-id; bh=U9QnAdkvD3nYzFEe9H4Oehb+Ag2cpOlB5/v/LOfg9tU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1Keub60q5mQEpUHGJXTQFQ7qWWULRkCPbdMRK
 eCsbVZvf/mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadSnrgAKCRBgAj/E00kg
 cnFlD/9047bYzGRZ3blI36JI4PtmYhXFdOJ/+ywcceqoWf8WuFYetD3CUaD9Wijcw+G9+UiAqQ+
 rPMPZEcj0xKWM2zNNK3r3vmW6wghqi48c1jYWzLQKRwAqwoDPTO0xyk2Nvhhjvs7nznGCWur8RE
 /HiuW5VIK90X59+2kLWhkVWTmttUBA6UiL8PWI+bJchIimJkqj1CFKNgkheUFfnm/M6YSKWrJAM
 3iPVgPekQ8m8icmm4kd6cX2Lv8OKQKZjfnyIMcGHRP8ecNnB5Tro8pOLVzs3l8Zt14TKJRw+Q6Y
 Bj34uhZGPqxHSx/CIChyr2WSM2YA6AsieZh3L7hxGrV3VatrTK2UAb4Yedekw5bGs681z1D4syk
 RV71v4ar0Ox5vwo9zjRwlmPUF0+O8RshqT87E6noKZmGwDj8uJbCuJuTz4SlV1/IDr8Y9BbSOpu
 2hR9r1/6R0x+5WexVbPP/yFWrYlG5oBc19FwH0Y2P8bpDrylHJi32kg/wyxS1WbNFTCkTZfX1Hf
 0ckYAx2nkBntecoTL3UfTDB8+emi1q7bo7AYgkEUwD1hsX6lFAzVRW8/LR8C2WSeSKaSjaaBTWN
 c/gijt6v7F4zAf9YNa4dICd31TKKIa7mKmNTfbAm4iqkBp6HvM6ly4FWwGM8Dbh0V2xPbyQ131A
 +J+u76xZxycuXgw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This quirk is used so far used on:
 - LG G7 ThinQ
 - Xiaomi Poco F1

I'm resending it after ~ 4 years since initial send due to Snapdragon
845 being one of best supported platform for mobile phones running
Linux, so it would be shame to not have shiny support.

Original thread:
  https://lore.kernel.org/all/b796bfee-b753-479a-a8d6-ba1fe3ee6222@ixit.cz/

I tried the embedding the information inside the firmware, but the
information is required *before* loading the firmware itself.
Firmware quirk thread:
  https://lore.kernel.org/linux-wireless/20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz/

Until merged, available also at:
  https://codeberg.org/sdm845/linux/commits/branch/b4/skip-host-cam-qmi-req

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v5:
- Implement device-tree mutual-exclusion between
  snoc-host-cap-8bit-quirk and snoc-host-cap-skip-quirk. (Krzysztof)
- Link to v4: https://lore.kernel.org/r/20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz

Changes in v4:
- Added my own missing SoB. (Dmitry)
- Improve the commit message. (Dmitry)
- Link to v3: https://lore.kernel.org/r/20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz

Changes in v3:
- Rebased on recent linux-next (next-20260325).
- Improved motivation and description. (Dmitry)
- Link to v2: https://lore.kernel.org/r/20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz

---
Amit Pundir (3):
      dt-bindings: wireless: ath10k: Add quirk to skip host cap QMI requests
      ath10k: Add device-tree quirk to skip host cap QMI requests
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable ath10k host-cap skip quirk

 .../devicetree/bindings/net/wireless/qcom,ath10k.yaml       | 11 +++++++++++
 .../arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi |  1 +
 drivers/net/wireless/ath/ath10k/qmi.c                       | 13 ++++++++++---
 drivers/net/wireless/ath/ath10k/snoc.c                      |  3 +++
 drivers/net/wireless/ath/ath10k/snoc.h                      |  1 +
 5 files changed, 26 insertions(+), 3 deletions(-)
---
base-commit: 816f193dd0d95246f208590924dd962b192def78
change-id: 20251110-skip-host-cam-qmi-req-e155628ebc39

Best regards,
-- 
David Heidelberg <david@ixit.cz>

