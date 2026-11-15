From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:10 +0530
Subject: [PATCH 02/11] soc: qcom: socinfo: Add SM8845 SoC ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-soc-v1-2-3b2ee920fa3b@yahoo.com>
References: <20261116-molokai-soc-v1-0-3b2ee920fa3b@yahoo.com>
In-Reply-To: <20261116-molokai-soc-v1-0-3b2ee920fa3b@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774008; l=723;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=DgBdet3QcKHQL63BL9Z8vJtIwtwq2bjCyRVpFlDaj6M=;
 b=VbEiZcCcv6P+GCR4vrEXyOwUDhuUSd31Sj24tEABhjF/g/V0kWkOcZaDP7iCpGIu0oZSB8XQI
 7t/ocFYGbYyDKHCEt7HJfqIMuwak8/NAqzx759qeVbBgTLOzChb1ouE
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SoC ID for SM8845, a variant of SM8850 (Kaanapali).

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/soc/qcom/socinfo.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/qcom/socinfo.c b/drivers/soc/qcom/socinfo.c
index 18105ddcf04d..718d1fa7e830 100644
--- a/drivers/soc/qcom/socinfo.c
+++ b/drivers/soc/qcom/socinfo.c
@@ -541,6 +541,7 @@ static const struct soc_id soc_id[] = {
 	{ qcom_board_id(QCS8275) },
 	{ qcom_board_id(QCS9075) },
 	{ qcom_board_id(QCS615) },
+	{ qcom_board_id(SM8845) },
 	{ qcom_board_id(SA8797P) },
 	{ qcom_board_id(SM8975) },
 	{ qcom_board_id(CQ7790M) },

-- 
2.56.0

