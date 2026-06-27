From: David Heidelberg <david@ixit.cz>
Date: Sat, 27 Jun 2026 19:50:16 +0200
Subject: [PATCH v2 2/2] soc: qcom: socinfo: Add SoC ID for SDM850
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260627-sda850-v2-2-44bf46ade42e@ixit.cz>
References: <20260627-sda850-v2-0-44bf46ade42e@ixit.cz>
In-Reply-To: <20260627-sda850-v2-0-44bf46ade42e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=925; i=david@ixit.cz;
 h=from:subject:message-id; bh=Xn+qNAcb0PhgtgeqElX7l/kJ7Cxp5jn3JqQBWNWtfAc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqQA1Z98Bkl+uqsNZLU3rSbDb4orvxGE5iyjjxo
 dg+ikEit1eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakANWQAKCRBgAj/E00kg
 ckDwD/9OT1gp9OuR4ZFFwAEpeMmEavmBLdHmRZWYf4mkyYE2q28t+GmEpiQlD5rbFbMbbHM6Q6t
 mrUp5htDIy5hvC/c13936dA4iHzSNYg/GuESsgqJXOAwyOUAhWNOi47o3fjdglgVFuPlyRdaCwZ
 mw0ZYVjnTyyzPpirJzc7W2aiTtTEB6uAgGlYaYBBz3QQVp9DnJ3Jg7VSmXPg/qARI8iPmJJswQ/
 vzRolbblALhvDOfhQZDjlMCH2vf726zWsBtcAd7QoXySiiVr7J3A0ACYfTCqJ5BFbfEJJCs+ySR
 BPvUhPXuYRHcdcNfarn+Vc4fIFrowgBodKnUZ1eYttHweCfx91pITKe2BK+NYMLWxb1TAenmCfA
 6J3AaCxK16A77CP9qBafs7A+L3nhJYd5bMUTt8Cankz8ESxAqybFe/aXbeP4LBmPLp339BmGyZX
 IFnvQQU0PHvOglFaNl56hy5WU51Pp1ivJUUuHajS5lDw+hpuVMkr5IYxdcT7LOXnkZFp7A2EiQW
 GVnUK/Byx1pVOkhijsN41w6hjC9ufBlkyiznFM5O7+ZDXAETEp9hMaloTcsdDD7XF0au+Xp+TaG
 3npwBbQrh7KbX/T9IfI47PwFz54TSt5GdSPst/Az6WgcxZjX20V17A0l7/ZLMW7GwSbmcGVmTN0
 REA/XaCl8mWHjuQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Recognize the SDM850 SoC.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/soc/qcom/socinfo.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/qcom/socinfo.c b/drivers/soc/qcom/socinfo.c
index af418adad7aaf..1836e226a2945 100644
--- a/drivers/soc/qcom/socinfo.c
+++ b/drivers/soc/qcom/socinfo.c
@@ -420,16 +420,17 @@ static const struct soc_id soc_id[] = {
 	{ qcom_board_id(SDM450) },
 	{ qcom_board_id(SM8150) },
 	{ qcom_board_id(SDA845) },
 	{ qcom_board_id(IPQ8072) },
 	{ qcom_board_id(IPQ8076) },
 	{ qcom_board_id(IPQ8078) },
 	{ qcom_board_id(SDM636) },
 	{ qcom_board_id(SDA636) },
+	{ qcom_board_id(SDM850) },
 	{ qcom_board_id(SDM632) },
 	{ qcom_board_id(SDA632) },
 	{ qcom_board_id(SDA450) },
 	{ qcom_board_id(SDM439) },
 	{ qcom_board_id(SDM429) },
 	{ qcom_board_id(SM8250) },
 	{ qcom_board_id(SA8155) },
 	{ qcom_board_id(SDA439) },

-- 
2.53.0

