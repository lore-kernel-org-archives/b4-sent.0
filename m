From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 15:14:45 +0000
Subject: [PATCH v2 3/6] include: fpga: adi-axi-common: add new helper
 macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-axi-clkgen-limits-v2-3-173ae2ad6311@analog.com>
References: <20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com>
In-Reply-To: <20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741878886; l=2067;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HReA2MAYtduz2bb2HnPbeBWJeXtFJv4KCDm8xe4UC+Q=;
 b=wvEskadfW/ZpqWTnJAPIwY9fIq4O3mfs0reybrhuJw0AN1LRtGWgIC8Aj2VJD0iNsDkUDltVf
 jD1NlVx9bHVDE3Apc/oYjzqhMSMyxkH1rEJ3GMtu0VoiPmlz4qrGbwS
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new helper macros and enums to help identifying the platform and some
characteristics of it at runtime.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 include/linux/fpga/adi-axi-common.h | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/include/linux/fpga/adi-axi-common.h b/include/linux/fpga/adi-axi-common.h
index 141ac3f251e6f256526812b9d55cd440a2a46e76..a832ef9b37473ca339a2a2ff8a4a5716d428fd29 100644
--- a/include/linux/fpga/adi-axi-common.h
+++ b/include/linux/fpga/adi-axi-common.h
@@ -12,6 +12,8 @@
 #define ADI_AXI_COMMON_H_
 
 #define ADI_AXI_REG_VERSION			0x0000
+#define ADI_AXI_REG_FPGA_INFO			0x001C
+#define ADI_AXI_REG_FPGA_VOLTAGE		0x0140
 
 #define ADI_AXI_PCORE_VER(major, minor, patch)	\
 	(((major) << 16) | ((minor) << 8) | (patch))
@@ -20,4 +22,37 @@
 #define ADI_AXI_PCORE_VER_MINOR(version)	(((version) >> 8) & 0xff)
 #define ADI_AXI_PCORE_VER_PATCH(version)	((version) & 0xff)
 
+#define ADI_AXI_INFO_FPGA_TECH(info)            (((info) >> 24) & 0xff)
+#define ADI_AXI_INFO_FPGA_FAMILY(info)          (((info) >> 16) & 0xff)
+#define ADI_AXI_INFO_FPGA_SPEED_GRADE(info)     (((info) >> 8) & 0xff)
+#define ADI_AXI_INFO_FPGA_VOLTAGE(val)          ((val) & 0xffff)
+
+enum adi_axi_fpga_technology {
+	ADI_AXI_FPGA_TECH_UNKNOWN = 0,
+	ADI_AXI_FPGA_TECH_SERIES7,
+	ADI_AXI_FPGA_TECH_ULTRASCALE,
+	ADI_AXI_FPGA_TECH_ULTRASCALE_PLUS,
+};
+
+enum adi_axi_fpga_family {
+	ADI_AXI_FPGA_FAMILY_UNKNOWN = 0,
+	ADI_AXI_FPGA_FAMILY_ARTIX,
+	ADI_AXI_FPGA_FAMILY_KINTEX,
+	ADI_AXI_FPGA_FAMILY_VIRTEX,
+	ADI_AXI_FPGA_FAMILY_ZYNQ,
+};
+
+enum adi_axi_fpga_speed_grade {
+	ADI_AXI_FPGA_SPEED_UNKNOWN      = 0,
+	ADI_AXI_FPGA_SPEED_1    = 10,
+	ADI_AXI_FPGA_SPEED_1L   = 11,
+	ADI_AXI_FPGA_SPEED_1H   = 12,
+	ADI_AXI_FPGA_SPEED_1HV  = 13,
+	ADI_AXI_FPGA_SPEED_1LV  = 14,
+	ADI_AXI_FPGA_SPEED_2    = 20,
+	ADI_AXI_FPGA_SPEED_2L   = 21,
+	ADI_AXI_FPGA_SPEED_2LV  = 22,
+	ADI_AXI_FPGA_SPEED_3    = 30,
+};
+
 #endif /* ADI_AXI_COMMON_H_ */

-- 
2.48.1

