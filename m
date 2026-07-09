From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 09 Jul 2026 13:18:32 +0400
Subject: [PATCH v5 6/6] MAINTAINERS: Add IPQ5018 driver to Qualcomm
 Bluetooth driver entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-ipq5018-bluetooth-v5-6-e476c41f03b8@outlook.com>
References: <20260709-ipq5018-bluetooth-v5-0-e476c41f03b8@outlook.com>
In-Reply-To: <20260709-ipq5018-bluetooth-v5-0-e476c41f03b8@outlook.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783588713; l=702;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=2A14I/9djkbP7Q/3gMV0xrYoXvOWpPLiNZFRJ5IU8Qc=;
 b=E5AlHnX2v2ikivvWxaDyWRXrdlt6w6bqiiGkCWHWmGorm+1BvaoideNHaGiMCcdgSiOtl8BWq
 0/u/tBoJAIgC7Np7whNWHhHMrfMbsfGyVnRtN7mdb4vXTtINRJ8rf4Z
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Qualcomm IPQ5018 Bluetooth driver to the existing entry for
Qualcomm Bluetooth drivers.

Acked-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 MAINTAINERS | 1 +
 1 file changed, 1 insertion(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index eb8cdcc76324..33dd0c70c277 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21876,6 +21876,7 @@ L:	linux-arm-msm@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/net/bluetooth/qcom,*
 F:	drivers/bluetooth/btqca.[ch]
+F:	drivers/bluetooth/btqcomipc.c
 F:	drivers/bluetooth/btqcomsmd.c
 F:	drivers/bluetooth/hci_qca.c
 

-- 
2.53.0

