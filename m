From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 11:23:51 +0100
Subject: [PATCH v2 5/5] arm64: dts: exynos: Add initial support for Samsung
 Galaxy Watch FE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-v2-5-c4ecab4b1c4c@member.fsf.org>
References: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4867;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=FOKCeXOXBxhw0Q8L/8D3S7rg87yAZxUJT9zak2Y0VUI=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1e+7venDewHub2uoRbxOQPvrSOP1qhsGLMtvn
 k8jPetjdDOJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatXvuxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+s4MBAAuEPsnJz8ZPZPjqlOdT+gXkSzxCk54Dr
 luMfazMmirxc6C3I85mGCEXBwDuUVzfbXjIi0jXzuhD3BuiqjL4GFlu8vcTv0vD1fNgejR0OHKd
 q7aCxSFRQ3I/zf0ydTsW6zrWZ+MfcF2fTtLsO8/2HU5MoVjNZrD0Cl6nSTnjwcny4yoy8KVWjht
 u4bVKeNDiBqjIvI1sFZ+KMgfzsXkelyL1ZrX7jxFXOcOQE8ZUkIvHIQbyd3GW6JpNWYaAZmcvbO
 3/JxioetiCJF9MGVafO2XPcykHFUGeSLXQ5NmBvvthTxU5bk0iTr2g/Kc4rqbKtNqAo3/cufNry
 gwS244MGVecK0g+rvKlB9A4pBeTwchYMX91sEJD2eRDy/WKzKf6v1z29SDiMwO74vpYNprsp1zX
 1EsgqV3D89t8ud9len6t7JlHALPV+6LZyyTATIPjMlN91hRkV5g1pAp3GAJx/Mzef8gjvsq9b42
 4qXWhs6JtKFK/he9Kw57tXGSijx2izo20mQpwCLNq6y/Hdhk8M7vI/MVd+5DTYIkCT/1LUXI0xC
 FTWgdWtAVrs+R99gWY6tCWeC0WJyqyBUyXkpgIn9WlPQcoA5GhUxpGWacztblrP3xquus7iz0N8
 sLV/3pk0zGs203GtjCyOscBmQn/uZf8V8sfq3SaHzj7cN370VMi0=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung Galaxy Watch FE (SM-R861/SM-R866), codenamed lucky7, is a
smartwatch developed by Samsung and released in 2024. It has 1.5GiB RAM,
16GiB of eMMC storage, an Exynos5515 (W920) SoC, and a 396x396 display.

Support for the following is added by this device tree:
- Bootloader framebuffer
- Memory

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts | 219 +++++++++++++++++++++++
 1 file changed, 219 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts b/arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts
new file mode 100644
index 000000000000..e80a0f0948cb
--- /dev/null
+++ b/arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts
@@ -0,0 +1,219 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Samsung Galaxy Watch FE (lucky7/SM-R861/SM-R866) device tree source
+ *
+ * Copyright (c) 2026 Aiden Isik <aidenisik+git@member.fsf.org>
+ */
+
+/dts-v1/;
+#include "exynos5515.dtsi"
+
+/ {
+	compatible = "samsung,lucky7", "samsung,exynos5515";
+	chassis-type = "watch";
+	model = "Samsung Galaxy Watch FE (SM-R861/SM-R866)";
+
+	chosen {
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <1>;
+
+		framebuffer@9e0cf000 {
+			compatible = "simple-framebuffer";
+			reg = <0x0 0x9e0cf000 (396 * 396 * 4)>;
+			format = "a8r8g8b8";
+			height = <396>;
+			stride = <(396 * 4)>;
+			width = <396>;
+		};
+	};
+
+	memory@80000000 {
+		device_type = "memory";
+		reg = <0x0 0x80000000 0x3ea00000>,
+		      <0x0 0xc0000000 0x20000000>;
+	};
+
+	reserved-memory {
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <1>;
+
+		/*
+		 * Some of these misc-rmem regions belong to memory-mapped
+		 * devices, and will be assigned to drivers as support
+		 * is added.
+		 *
+		 * Other regions belong to the TrustZone firmware and should
+		 * never be touched.
+		 */
+		misc-rmem@87000000 {
+			reg = <0x0 0x87000000 0x200000>;
+			no-map;
+		};
+
+		misc-rmem@87fff000 {
+			reg = <0x0 0x87fff000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@8a000000 {
+			reg = <0x0 0x8a000000 0x31000>;
+			no-map;
+		};
+
+		misc-rmem@8d800000 {
+			reg = <0x0 0x8d800000 0x180000>;
+			no-map;
+		};
+
+		misc-rmem@8ffff000 {
+			reg = <0x0 0x8ffff000 0x33000>;
+			no-map;
+		};
+
+		misc-rmem@90100000 {
+			reg = <0x0 0x90100000 0x200000>;
+			no-map;
+		};
+
+		misc-rmem@98a00000 {
+			reg = <0x0 0x98a00000 0x600000>;
+			no-map;
+		};
+
+		misc-rmem@9a000000 {
+			reg = <0x0 0x9a000000 0xc00000>;
+			no-map;
+		};
+
+		misc-rmem@9b000000 {
+			reg = <0x0 0x9b000000 0x400000>;
+			no-map;
+		};
+
+		misc-rmem@9bd00000 {
+			reg = <0x0 0x9bd00000 0x208000>;
+			no-map;
+		};
+
+		misc-rmem@9c000000 {
+			reg = <0x0 0x9c000000 0x20000>;
+			no-map;
+		};
+
+		framebuffer@9e0cf000 {
+			/*
+			 * Reserve up to the end of the final page of the
+			 * framebuffer region, to prevent memory aliasing.
+			 *
+			 * size: align((396 * 396 * 4), 0x1000)
+			 */
+			reg = <0x0 0x9e0cf000 0x9a000>;
+			no-map;
+		};
+
+		misc-rmem@a0000000 {
+			reg = <0x0 0xa0000000 0x10000>;
+			no-map;
+		};
+
+		misc-rmem@a0010000 {
+			reg = <0x0 0xa0010000 0x400000>;
+			no-map;
+		};
+
+		misc-rmem@a0510000 {
+			reg = <0x0 0xa0510000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@a0900000 {
+			reg = <0x0 0xa0900000 0x2000>;
+			no-map;
+		};
+
+		misc-rmem@a0902000 {
+			reg = <0x0 0xa0902000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@a0910000 {
+			reg = <0x0 0xa0910000 0x3c000>;
+			no-map;
+		};
+
+		misc-rmem@b0000000 {
+			reg = <0x0 0xb0000000 0x200000>;
+			no-map;
+		};
+
+		misc-rmem@b1000000 {
+			reg = <0x0 0xb1000000 0x200000>;
+			no-map;
+		};
+
+		misc-rmem@bbfff000 {
+			reg = <0x0 0xbbfff000 0x1000000>;
+			no-map;
+		};
+
+		misc-rmem@bcfff000 {
+			reg = <0x0 0xbcfff000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@bd430000 {
+			reg = <0x0 0xbd430000 0x1250000>;
+			no-map;
+		};
+
+		misc-rmem@d0000000 {
+			reg = <0x0 0xd0000000 0x5d00000>;
+			no-map;
+		};
+
+		misc-rmem@dc444000 {
+			reg = <0x0 0xdc444000 0x2bbc000>;
+			no-map;
+		};
+
+		misc-rmem@df005000 {
+			reg = <0x0 0xdf005000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@df008000 {
+			reg = <0x0 0xdf008000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@df009000 {
+			reg = <0x0 0xdf009000 0x12000>;
+			no-map;
+		};
+
+		misc-rmem@df01b000 {
+			reg = <0x0 0xdf01b000 0x21000>;
+			no-map;
+		};
+
+		misc-rmem@df03c000 {
+			reg = <0x0 0xdf03c000 0x1000>;
+			no-map;
+		};
+
+		misc-rmem@df03d000 {
+			reg = <0x0 0xdf03d000 0xfc3000>;
+			no-map;
+		};
+	};
+};
+
+&oscclk {
+	clock-frequency = <26000000>;
+};
+
+&watchdog {
+	status = "okay";
+};

-- 
2.54.0

