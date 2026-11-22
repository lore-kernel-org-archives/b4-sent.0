From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 23 Nov 2026 00:37:46 +0530
Subject: [PATCH v4 01/11] soc: qcom: socinfo: Define the SM8845 SoC ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-molokai-soc-v4-1-851e5a9f4878@yahoo.com>
References: <20261123-molokai-soc-v4-0-851e5a9f4878@yahoo.com>
In-Reply-To: <20261123-molokai-soc-v4-0-851e5a9f4878@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795374466; l=812;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=k6HqI7lXxogfHltCEOVIpJCxC5/r/ZaR6jpLGT2PIZg=;
 b=huKNfo3uPxQYRavsMLtMSb7SwJtczZkQu7uZtbc2HzNAALqrdjHo+TrPBbQ/PkepXQU2Y0y8Z
 IV9e9c3ikViBdVTWkw2hCRa973uKld3p/mYAFQ6jc1iNA7VFkJ851SR
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ID of the Qualcomm SM8845 (Molokai), a variant of the SM8850
(Kaanapali), as the Motorola Signature reports it in SMEM. socinfo uses
it to report the SoC by name.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 include/linux/soc/qcom/socinfo.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/soc/qcom/socinfo.h b/include/linux/soc/qcom/socinfo.h
index cd2e8eddf3b5..fcdc750f4b20 100644
--- a/include/linux/soc/qcom/socinfo.h
+++ b/include/linux/soc/qcom/socinfo.h
@@ -184,6 +184,7 @@ enum qcom_socinfo_feature_code {
 #define QCOM_ID_QCS8275			675
 #define QCOM_ID_QCS9075			676
 #define QCOM_ID_QCS615			680
+#define QCOM_ID_SM8845			685
 #define QCOM_ID_SA8797P			690
 #define QCOM_ID_SM8975			707
 #define QCOM_ID_CQ7790M			731

-- 
2.56.1

