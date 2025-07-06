From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:07 -0400
Subject: [PATCH 11/11] ARM: dts: lpc18xx: add missed
 arm,num-irq-priority-bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-11-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=846;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=4fOjzjyuG5LcIby6pMbBo34EQluojfYnUqvpnhe6tYs=;
 b=U4ZGB18/725NcA20uH867GM0vXODJAffGPp5Nsh4hFcW7DdZ7HVPXiKDHemOdimHvz+joXaF6
 vg2989NPBcZBhuc5QIRBhHsEqCP/P1g+3r3TTeBkFmh4X/Zc7+NfgXX
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missed arm,num-irq-priority-bits to fix below CHECK_DTBS warning:
arm/boot/dts/nxp/lpc/lpc4337-ciaa.dtb: interrupt-controller@e000e100 (arm,armv7m-nvic): 'arm,num-irq-priority-bits' is a required property
	from schema $id: http://devicetree.org/schemas/interrupt-controller/arm,nvic.yaml#

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
index d212ca252b06dc97a0cdbe5ecff42780b51a02dd..152e98cf0c4e2a3eb4f2c989600698a93b3084a3 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi
@@ -537,3 +537,7 @@ gpio: gpio@400f4000 {
 		};
 	};
 };
+
+&nvic {
+	arm,num-irq-priority-bits = <3>;
+};

-- 
2.34.1

