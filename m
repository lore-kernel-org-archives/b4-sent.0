From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Subject: [PATCH v3 0/2] Add USB support for Exynos7885 and enable USB and
 FG on gta3xllte
Date: Wed, 25 Nov 2026 16:12:40 +0000
Message-Id: <20261125-gta3xllte-usb-battery-v3-0-2ef962bf5423@mentallysanemainliners.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTsJLdiKVzEuWhxgDEHTGQyGc
 HeKLt/i/xWEEpPAtVgh0YeFX1NGdSqgHcLUE/IjG2xpnTH2jL2GahlHJZwlYgyqlL4YLr42vnO
 NdR5y+07U8fL73u5/yxyf1Ooxg23bAfBKBbJ5AAAA
X-Change-ID: 20261125-gta3xllte-usb-battery-a87417f69267
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Henri Ommer <henri@ommer.net>, David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795623167; l=1837;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=kpn0cpERSh/Ga6YdBXYn7twRHHIGblxKBB2fEDSemIw=;
 b=/l+UvcwX5Ng35YNKWuwYMVIZ9cqOucSSq4NLhgLWQOA0cduHh51C8ku69lcPaJN7dr83KyaJ8
 XVtRAwrER2IDy4VaccSNif3ClnII3qkeb2a2xXfQvxiKDqfgdsHAd9h
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi guys, this patch series enables USB and FG on gta3xllte. All is tested.

DT changes were tested with make dtbs_check W=1, and the dt styling check
scripts with --mode strict flags, both of which returned no warnings.

Please note this patch now depends on David Virag's changes for USB[1].

Best regards,
Umer

[1] https://lore.kernel.org/linux-samsung-soc/20261125145458.2594179-1-virag.david003@gmail.com/T/#t

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
Changes in v2:
- Drop patches that are being picked up updated and corrected by David
- Link to v1: https://patch.msgid.link/20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org

Changes in v3:
- Change dependency link
- Move define maximum-speed on board
- Link to v2: https://lore.kernel.org/linux-samsung-soc/20261124-gta3xllte-usb-battery-v2-0-80bdcb1753bb@mentallysanemainliners.org/T/#t

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Henri Ommer <henri@ommer.net>
Cc: David Virag <virag.david003@gmail.com>

---
Umer Uddin (2):
      arm64: dts: exynos: exynos7885-gta3xllte: Enable USB support
      arm64: dts: exynos: exynos7885-gta3xllte: Enable FuelGauge support

 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 56 ++++++++++++++++++++++
 1 file changed, 56 insertions(+)
---
base-commit: 7ed7d0761cca220e521c66f87b48def6c5a8edf7
change-id: 20261125-gta3xllte-usb-battery-a87417f69267

Best regards,
--  
Umer Uddin <umer.uddin@mentallysanemainliners.org>

