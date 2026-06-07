From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Convert qcm6490 framebuffers to use memory-region
Date: Sun, 07 Jun 2026 16:12:17 +0200
Message-Id: <20260607-shift8-fb-v1-0-72b9dac25f4a@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEF8JWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNz3eKMzLQSC920JF0zg7QUM7MkA/MUCzMloPqCotS0zAqwWdGxtbU
 ABywqtlsAAAA=
X-Change-ID: 20260607-shift8-fb-60fd66b07d86
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=635; i=david@ixit.cz;
 h=from:subject:message-id; bh=VXFI2Thg0ZPZn98L4AfzCgC22eFLe52VScYx6+NF/yU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqJXxHGDqvCtvP8Vvnx1zOU2LExgk5yOf4Ltu8I
 KlzHGelSKyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiV8RwAKCRBgAj/E00kg
 cjerEAC7ml4ybpC2agnoPSETQiKU7QNKBAJWZEib4uznq4lSZy7DKIwhk4udcgBbI7+RGeLMh4S
 VuTv3wZpRGCbuIIieuZlCrcVrKX1757jsrUOTaoLd180aCWc1ZIDQAGP7Vl2Z/w2Yv3G3XdPgW0
 E9X4mo7pu339AhNKSZuC/7Evzi5FR6ykFd5F889dpiuOM5mn4dfOk4yb+B6B26opvsh8YBIrDjC
 cJ1Wx48il8O4i6GqltQAa7joEMW7d+UVbNnC013ln12dToERGiX4w/v61oOCf1aCHBWCElzkHLq
 pdv7YW49jWMAXzrb4xIEcmqk91yr4OmelxnlyP5/Tr8xskcxM5NZfRPiXnhkz8GiDmdaTwrNm1g
 uC4TKhhRZz+gulJc9XoQ/g+sPH8LgdNmlQjZF1957T/oTWa9PnSDp0RlKmgYi5hgWJQnehlT1Xb
 iRWTzwg2ht/7S1Arh9I2Ca4eLSXGzz7UxBw7X+5oAmr5hr/N3Sph/S7KWfFIvq2HqDj3icg87Ew
 84EelkKhnKU/h9RfYRsWQuFyY7XTF/oGERY3STRrz+XKQiuftUhMF/k9qpmOxCmaONxzy6RefdV
 LhnEXvtU9UHTglrH9bG9v4OB2ihibwwZFjcVWiDjNkw0FtJDuyWRkC3j1/182y+rIQ8dpInpTJj
 wCtRwoDKT5LM9ew==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that upstream u-boot recognize it, no reason to not do.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: qcm6490-shift-otter: Convert fb to use memory-region
      arm64: dts: qcom: qcm6490-fairphone-fp5: Convert fb to use memory-region

 arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts | 4 ++--
 arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts   | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: b99ae45861eccff1e1d8c7b05a13650be805d437
change-id: 20260607-shift8-fb-60fd66b07d86

Best regards,
-- 
David Heidelberg <david@ixit.cz>

