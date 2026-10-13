From: Juerg Haefliger <juerg.haefliger@canonical.com>
Subject: [PATCH 0/3] Add HP EliteBook 6 G1q support
Date: Tue, 13 Oct 2026 16:40:55 +0200
Message-Id: <20261013-add-elitebook-6-dts-v1-0-f22e67fc7f9d@canonical.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTuQVEnFq4iLJvOro9JIJhWh9
 O5GXX6L9xYyFIXRoVuo4KWmeWrwm47SdZwuYJVm6l0fvPOORxHGQytizncOLNV4vx12AwKiuES
 tfBac9f27Hk9/2xxvSPW7onX9ACOJbjZ3AAAA
X-Change-ID: 20261010-add-elitebook-6-dts-83747e6ebd0c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1529;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=GlHnK+4qKaDdo2A0sNEUCUKte5M3D8EeHi5/6oE29Hc=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzkMJdjBH+e71xDFFZWeY2vRqWhkMlm1s5Fagh
 29aPPMoP6KJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas5DCQAKCRAP04sJC6ZC
 tz0FEACrNr1YSn/J/2G+UoExKVjjXsMAyrJGqler8XGvHLlVP0ioLmK42DBcMVlKW8CpJYZBdK6
 jqV91fP3yl7EVD+qZU94OVOft32zdXuz6uXT8FIFfhSNKBdQNLFAoTEPXrp14LrJQZL8XfvBe5L
 ReTe+37cyGLoIHOjBq8fcOhHMd8nLMGTGiljCLJhZAtGpPq0DrVYfuXCquhstewNq/u3/lIkMiN
 4bd6DvxbmE5nCGKYonqT0PL8gfr1QqIpbIz7iPSvgKgL9sedNqbQjArgkOnF3kEutC02P4U3yT6
 XcwEr20AhanxBG+5qLJgQdn1JGH0t9lLPwbVCS46475xreviBuLhV+1x9mR/P5abgRloXjQzS0I
 iCUd7WU/0ql0KFGSi2zUtcZt/5ZnXUYUBzPMu7DOzrljek2W3g6QjvV+Im5+/zTbuqtVxw1T+Y6
 eMNYG8/v74WLFFmpMr5GKwBXuQnBSS+fTxyIdAT5A1A9gBeWHqO9vtdOIywBXe9eHhnq2Jk28y8
 27bFBKZX4/Vz9lOyqZYSnJauR7T7ilRDRmH9LC1lzXJ0FRK+WcAsr9IYqACVKb+RTUK0rOr8VrX
 ZJlp6wVg/EuepCoCUN2leW9DIsSZeEtHZmzUr1h3ZrrQQn7PaWIZvmdNvDOUP3oF3C1dvt127EG
 YeQC6mi4iw+HPdA==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the HP EliteBook 6 G1q laptop
(SKU B16TPAV, 32GB, WWAN), based on the Snapdragon X1P42100 SoC.

It's very similar to the existing HP OmniBook X14 but comes with an
additional built-in fingerprint reader and Ethernet port, so the DT is
largely a copy-paste from OmniBook.

Confirmed working on real hardware:
- Keyboard
- Touchpad
- Touchscreen
- USB A and C ports
- Ethernet NIC
- HDMI-A port
- Wifi
- Bluetooth
- Integrated Speakers and microphone
- Camera
- Fingerprint reader
- WWAN modem

There are two additional small patches required for the kernel to
recognize the eDP panel and the WWAN modems. I'll submit those
separately soon.

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
Juerg Haefliger (3):
      dt-bindings: arm: qcom: Document HP EliteBook 6 G1q
      arm64: dts: qcom: Add dts for HP EliteBook 6 G1q
      firmware: qcom: scm: Allow QSEECOM for HP EliteBook 6 G1q

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    2 +
 .../arm64/boot/dts/qcom/x1-hp-elitebook-6-g1q.dtsi | 1568 ++++++++++++++++++++
 .../boot/dts/qcom/x1p42100-hp-elitebook-6-g1q.dts  |  246 +++
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 5 files changed, 1818 insertions(+)
---
base-commit: 705529dab1fa872d8b53b09c95e1b03a95573376
change-id: 20261010-add-elitebook-6-dts-83747e6ebd0c

Best regards,
-- 
Juerg Haefliger <juerg.haefliger@canonical.com>

