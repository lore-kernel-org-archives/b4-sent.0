From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Subject: [PATCH v2 0/2] Add USB support for Exynos7885 and enable USB and
 FG on gta3xllte
Date: Tue, 24 Nov 2026 17:14:31 +0000
Message-Id: <20261124-gta3xllte-usb-battery-v2-0-80bdcb1753bb@mentallysanemainliners.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0K6toYWi+DKexgWLQwwprSmUwiEc
 HcBD+DyJe+/vzKCgEDskawswISE3u0gLwmre+064NjszGQqcyFEybuos9naCHwkw42OEcLCTan
 g1hSlhkKxffsJ0OJ8dl/Vj2k0b6jjETuMHin6sJzHkzi8fx+T4ClP61a19zxTUsJzABe1tQtpB
 4NGZ9FBoKsPHau2bfsCNwuHCd0AAAA=
X-Change-ID: 20261119-gta3xllte-usb-battery-b95e4d89ae85
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Henri Ommer <henri@ommer.net>, 
 David Virag <virag.david003@gmail.com>, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795540475; l=1538;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=DAbTxT7juIbYgrW7oPFGFfAP35r9haHx3DRvlkx81nY=;
 b=5u5JzQXguPwZgd20NoD1oFChHbxoRiu8ukXHEVrS9kIdvqu3ceo4WL4ihus8l0GK8Uc/SkrDQ
 o2xb7qia5wvAcwqSWIcAXQ1QOgsXH5xF0wwxoGCf+oR6A9REvB8sfqJ
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

[1] https://lore.kernel.org/linux-samsung-soc/20261123092244.1792040-1-virag.david003@gmail.com/T/#t

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
Changes in v2:
- Drop patches that are being picked up updated and corrected by David
- Link to v1: https://patch.msgid.link/20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Umer Uddin (2):
      arm64: dts: exynos: exynos7885-gta3xllte: Enable USB support
      arm64: dts: exynos: exynos7885-gta3xllte: Enable FuelGauge support

 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)
---
base-commit: 9b369f9debe1253032abb90a9469fe44146835d1
change-id: 20261119-gta3xllte-usb-battery-b95e4d89ae85

Best regards,
--  
Umer Uddin <umer.uddin@mentallysanemainliners.org>

