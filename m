From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v6 0/3] Asus vivobook s15 improvements
Date: Wed, 04 Dec 2024 13:26:36 +0100
Message-Id: <20241204-asus_qcom_display-v6-0-91079cd8234e@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHxKUGcC/4XQ24rCQAwG4FeRud5Zksyh1ivfYxFJ25ntgFrtu
 EWRvvtGEXRpYW8Cf8h8IXNTOfQpZLVa3FQfhpRTd5DgPxaqbvnwHXRqJCsCsojoNeefvD3V3X7
 bpHzc8VXXwcVYUGmMBSXvjn2I6fIwvzaS25TPXX99rBjw3n1qZGa0ATXopeMyxpIsMK/b7rznt
 PuUKXX3BvrXIDEYqhiXrvAyNzXMu2HnDCMGAFUFmQpLgqlh3w03Z1gxPLJtGL0c46eGexlS5gw
 nRoDGFI7kmzH+NcZx/AUMDKlwxAEAAA==
X-Change-ID: 20241116-asus_qcom_display-ce5ff7293340
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Maud Spierings <maud_spierings@hotmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733315235; l=2711;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=8kJH1aCPRzLi27KAgWkroEiNcQgrobWypSWXyYNueFs=;
 b=U4kuwkINKUwXE0oYU7Wjb8/6ZPzy7nW045W7R+OL4f20Rqy5N2mz8IAZBCOBGlXZ9qcjTH73M
 7d7Nt7TmS6lC/kU27qv5tTz9HkcJ+YH0mbYWvTr2XME4TW+rNx39wQl
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves several parts of the devicetree:
1. The eDP panel bindings
2. Add a lid switch
3. Add bluetooth and describe wlan (depends on [1])

A big part of the bluetooth/wifi patch was copied from [1] as it is
mostly boiler plate regulator definitions
[1]: https://lore.kernel.org/all/20241007-x1e80100-pwrseq-qcp-v1-0-f7166510ab17@linaro.org/

---
I seem to get a warning that the pci17cb vendor is undocumented (wlan)
I can find this compatible in
Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml
But pci17cb doesn't really seem like a vendor name to me, I have ignored
this warning for now.

Changes in v6:
- Use the proper define for the pmic-gpio drive-strength in the panel
  driver patch
- Add a comment about the voltage to the pmic-gpio power-source in the
  panel driver patch
- Remove the alias for the not (yet) existing debug uart in the bt/wifi
  patch
- Remove output-low from the bt_en gpio in the bt/wifi patch
- Add wcn- prefix to the bt-en and wlan-en gpio node names in the
  bt/wifi patch
- Link to v5: https://lore.kernel.org/r/20241202-asus_qcom_display-v5-0-e0d3752ff71f@hotmail.com

Changes in v5:
- Fix the pinctrl-# definition in the wcn7850-pmu node in the
  bluetooth/wifi patch
- Link to v4: https://lore.kernel.org/r/20241125-asus_qcom_display-v4-0-61a4da162406@hotmail.com

Changes in v4:
- Fixed the pin parameters for the backlight enable pin
- Fixed the wcn_sw_en drive-strength, this was not in the acpi table I
  checked.
- Fixed the ordering of several nodes in the bluetooth/wifi patch
- Link to v3: https://lore.kernel.org/r/20241124-asus_qcom_display-v3-0-002b723b1920@hotmail.com

Changes in v3:
- Fixed commit message formatting (line wrapping)
- Fixed bad indentation (lid switch pinctrl)
- Fixed bluetooth addition and added wifi description
- Link to v2: https://lore.kernel.org/r/20241123-asus_qcom_display-v2-0-a0bff8576024@hotmail.com

Changes in v2:
- Add missing gpiokeys include in the lid switch patch
- Add depends on for the bluetooth patch
- Link to v1: https://lore.kernel.org/r/20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com

---
Maud Spierings (3):
      arm64: dts: qcom: x1e80100-vivobook-s15: Use the samsung,atna33xc20 panel driver
      arm64: dts: qcom: x1e80100-vivobook-s15: Add lid switch
      arm64: dts: qcom: x1e80100-vivobook-s15: Add bluetooth

 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 201 ++++++++++++++++++++-
 1 file changed, 200 insertions(+), 1 deletion(-)
---
base-commit: 9115d6b2d6bdbd14c1fda449a2a1653f7ad40dce
change-id: 20241116-asus_qcom_display-ce5ff7293340

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

