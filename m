From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Mon, 03 Aug 2026 02:03:47 +0700
Subject: [PATCH v4 3/7] ARM: dts: qcom: msm8960: add SCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-msm8960-wifi-v4-3-5ffa27aea39d@smankusors.com>
References: <20260803-msm8960-wifi-v4-0-5ffa27aea39d@smankusors.com>
In-Reply-To: <20260803-msm8960-wifi-v4-0-5ffa27aea39d@smankusors.com>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785697465; l=1008;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=6qPCxJ060B6XOvr3QmmXdpO9Tte51UAy4LVFZRVscW8=;
 b=7gSUZvGsHd9lEsiq5M7AIjzo8rqjgFn6FJzuUZMrOBlKJEY7adDZLhxunZXPX/34lbv8H/HGJ
 yyvCnJugwl7DAg6BzZgAwRFz7vEUBXnxY2XkSImw7wWcfROgrKEqMT8
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Secure Channel Manager firmware device node to the MSM8960
device tree. The SCM is required for secure communication between the
application processor and other subsystems.

Tested-by: Rudraksha Gupta <guptarud@gmail.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index 6ead9fec557a..00957482dee6 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -77,6 +77,15 @@ l2: l2-cache {
 		};
 	};
 
+	firmware {
+		scm {
+			compatible = "qcom,scm-msm8960", "qcom,scm";
+
+			clocks = <&rpmcc RPM_DAYTONA_FABRIC_CLK>;
+			clock-names = "core";
+		};
+	};
+
 	memory@80000000 {
 		device_type = "memory";
 		reg = <0x80000000 0>;

-- 
2.34.1

