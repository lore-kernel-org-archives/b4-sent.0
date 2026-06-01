From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Subject: [PATCH v4 0/3] Add support and enable the debug UART in the Pixel
 3a and Pixel 3a XL
Date: Mon, 01 Jun 2026 18:55:35 +0200
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/53Oz07EIBAG8FfZcHYMhRZbT76H8TDA0MU/UIE22
 2z67tLVZC96cDOnbzKZ33dmmZKnzB4PZ5Zo8dnHUEN7d2DmiGEk8LZmJrhQXIoeJtTvca3jc0G
 wpOcRZkwFYoBk0eCKAQKdCqhBPLSy6w25ltV/UyLnTxfr+eU751m/kik78HOR6HOuJcr17Fihm
 NZLw6XZt7eUWRrgwDVq1/UtGqufppjLB6Y3KjHfxzSyHVvEzYCoQCdR28Hq3nH8A5BXQPHmP4C
 sgHLWWKUGqVr6Bdi27QuLEa3o0gEAAA==
X-Change-ID: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1490;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=6v7pnbHEqhl+JmazKgM2s3MkutECEkPUWqCabk1RSmU=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbmUlpMWuavpjbrdQjFyXUapD9LCdvOcV+MZ4
 kpBj1fAzTqJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25lAAKCRB6NCVl/2Nf
 eavtD/9G8We3Cij1iJa5rONvtJ1/dXXRDm7VEDpKtuXLvuqH61ahri9hyiWn3NdppeuurJpPJxQ
 ftw1kTg9baQqArC+4lspnUwmj1sod7GbKNuw7VD17a1trQFVm25cIwN5rPMHLibppzM/SxxQzY+
 bwONh1q9WqjcXhfVj6QArF0lw07cVuyb8zwKYK4AIMn5kpiKFIjaF1++GoJw0uD/va7rHhXyx//
 tNQzYTIBW2+htUHINQ33zPx9J0zLaV3708mak/LVaTyFD2Zfuxq2rCpGSgZitAflw1TVR3Dge08
 zZbPxEkwhnJpzzKe4S0c5yZBTRUna02qCTHNgkj7aDEVps359jishDN2TYynr7o5CpZy1cgfZwH
 wJIqNlEKWVDPc73siXpAMVfQOe16gROrL2+ZkJYuGZDEHMAkwyZU2YP9U/HmYUjOlVXyZNBGjfz
 INPSBsv+lje8zCufMJsd/i2nUblwOaje/fI687Bxv0gcRZnDnAS5QeXSCBTQTzI031rBhmZ3ICW
 0EMca/GGWLXYpH4U+9F6CERP+bxjZD1B2IwgUvcayygJNXE7ubDR+SpmvKCChUsGqT+IMsi9Ers
 L9HVVN2W5g5sjFGPNzoznrV4rt7yITXVFpBfZbUadMuQh1oO+8Flf9sQdY7G+moFL35xYJMyc32
 n2Q8gQ9oOq2mkZA==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to get logs through the SBU pins in Google Pixel devices, it is
necessary to add support to the devicetree, and enable the corresponding
UART. With this code and an USB-Cereal board, I was able to get full kernel
logs through serial.

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
Changes in v4:
- Picked Reviewed-by tags
- Link to v3: https://patch.msgid.link/20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org

Changes in v3:
- Drop dependency on already-picked patches
- Link to v2: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org

Changes in v2:
- Fix typo in (3/3) commit message
- Link to v1: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org

---
Pablo Correa Gómez (3):
      arm64: dts: qcom: sdm670: add default uart pinctrl nodes
      arm64: dts: qcom: sdm670: add debug uart soc node
      arm64: dts: qcom: sdm670-google-common: enable debug uart

 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  18 +-
 arch/arm64/boot/dts/qcom/sdm670.dtsi               | 207 +++++++++++++++++++++
 2 files changed, 224 insertions(+), 1 deletion(-)
---
base-commit: be0cd82a9f584e562b243684303054134c8f6583
change-id: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4

Best regards,
--  
Pablo Correa Gómez <pabloyoyoista@postmarketos.org>

