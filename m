From: Igor Velkov <iav@iav.lv>
Date: Mon, 09 Nov 2026 00:57:49 +0000
Subject: [PATCH] arm64: dts: amlogic: meson-sm1-odroid: mark the Ethernet
 PHY as a wakeup source
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hc4-phy-wakeup-v1-1-d98784ecac88@iav.lv>
X-B4-Tracking: v=1; b=H4sIAIwa8WoC/x3MSQqAMAxA0atI1gYaJ6hXERe1RhsELS1OiHe3u
 HyL/x+IHIQjtNkDgQ+Jsq0JlGdgnVlnRhmToVBFQ6Q0OluhdzeeZuHdo7ZU82BMScSQIh94kus
 fdv37flgHcaZgAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1953; i=iav@iav.lv;
 h=from:subject:message-id; bh=th9XEIxslt9+U3iOsvDowXn3pt6YXgBXd1xZpRrr4n4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkfpfry3jIbvs9Z9Uatelmny21OjdLSH79fPbD2nPIzI
 mF67HyGjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRMCOGf7ofCvuMDwa/vHVx
 zlTZbeVOSdWZE/2Nv/j83z819/luTRuG/6VWdbxz7a99TLhh3Ngh/o//ywEJu7TgQx/uaf9m9Wi
 sZgMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTL8211F interrupt is wired to GPIOZ_14 and described in the PHY
node, but the node does not declare that it can wake the board. Without
wakeup-source the Realtek driver does not make the PHY wakeup capable,
so phylink leaves Wake-on-LAN to the MAC, and a magic packet does not
wake the board from s2idle.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-HC4 with Linux 7.4-rc1 and the U-Boot and .config of
Armbian: s2idle, Wake-on-LAN set with ethtool after the link is up. With
this change a magic packet woke the board 5 of 5 times, in 8 s, with
pm_wakeup_irq pointing at the PHY. Without it, 0 of 2: the RTC alarm
woke the board.

The test DTB had two other changes: the RTC alarm interrupt [1] and PCIe
disabled. With PCIe enabled the board did not resume 2 of 2. In the one
console capture resume starts when the packet is sent, then a hard LOCKUP
and a panic follow while pci_pm_resume_noirq() of the root port runs;
pci-meson has no system PM. So on the HC4 with its stock DT this property
alone does not give working Wake-on-LAN yet.

Not tested on ODROID-C4, which shares this node.

[1] https://lore.kernel.org/r/20261019-hc4-rtc-alarm-irq-v1-1-078fc79e596f@iav.lv
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
index e6f02d738a21..9a4684dfbde3 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
@@ -277,6 +277,7 @@ external_phy: ethernet-phy@0 {
 		interrupt-parent = <&gpio_intc>;
 		/* MAC_INTR on GPIOZ_14 */
 		interrupts = <IRQID_GPIOZ_14 IRQ_TYPE_LEVEL_LOW>;
+		wakeup-source;
 	};
 };
 

---
base-commit: 81e55899e134541583a4e611ff750e1868671c67
change-id: 20261109-hc4-phy-wakeup-9c15ebaa311e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

