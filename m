From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:44 +0200
Subject: [PATCH v4 01/11] Input: stmfts - Fix the MODULE_LICENSE() string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-1-64fe62027db5@ixit.cz>
References: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
In-Reply-To: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1002; i=david@ixit.cz;
 h=from:subject:message-id; bh=QDQEyb6yQN5WPWE8pVdtCQECptdn8p6xNSQzeqr7Q2U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tORTVIWUARSt+X8PEgpRWebBk61lkEJPfSUe
 Qn5hhASu4WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkQAKCRBgAj/E00kg
 cpLTEACo06/04dYc2te03+Sy7fTTeUeGNPVohJ8IYXHmRlzwNqxLbH3zEffYQo4ogIp4AzNTrdQ
 PQMBbB9CZKT8OJSWPojgGhodpGdwTQLAxShW6fr0vY14adVsuUUie7qLGvopPQRm1tYaA+uqxe9
 mr2M+ylz9qrFPPrJaogMehFSipIUAdMFb5MnqDFWA0NjEqZp1uGbHC4T1F65w+49RlzaBu7z1AC
 zDrENGQ3dmQS8uNxV5xr08qCHSJq9U3PqSR3fc5jsrqTzxoLA48AGBGsbBEsFUrvpI6kCt/XXFO
 UdGalj2w2HB2KHwaYeneO4KFu/mD3Fe2Ylme65GClsUAjmxyoWfTPgOltIpUXgdBV1il1iS/+22
 ixalfRz2aHIDZv6t2lGFPM8eNxL/RgaRygUjSu4kvSIXJnodGhIXXs/VsIX0bVPccnbOSL2Afwh
 pzurDOVnmHN1gJitTqPEbmY17fl4llN1pEpYqDCB09ZjMdg99pYvhQqgxDxq+mc+NuGeGvOMt8n
 KjRzDRDXQy02HnXXjyKPdVEBnt1oWpHNdvS/dDaZXkoXHbbVLrTLtD7iQnuT2DulPtl/Sxp9+r1
 RXOiG/xINI+Hwj/2Azta5YpuTyxQOfNwpZyr6Lt5fLSnNJOkVVt5xvrzx/cs1tiCsYIXjRdvM8k
 wl7YY81E8PSVRWA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the bogus "GPL v2" with "GPL" as MODULE_LICNSE() string. The
value does not declare the module's exact license, but only lets the
module loader test whether the module is Free Software or not.

See commit bf7fbeeae6db ("module: Cure the MODULE_LICENSE "GPL" vs.
"GPL v2" bogosity") in the details of the issue. The fix is to use
"GPL" for all modules under any variant of the GPL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 8af87d0b6eb64..def6bd0c8e059 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -807,4 +807,4 @@ module_i2c_driver(stmfts_driver);
 
 MODULE_AUTHOR("Andi Shyti <andi.shyti@samsung.com>");
 MODULE_DESCRIPTION("STMicroelectronics FTS Touch Screen");
-MODULE_LICENSE("GPL v2");
+MODULE_LICENSE("GPL");

-- 
2.53.0

