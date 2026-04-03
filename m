From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:30 +0200
Subject: [PATCH WIP v3 01/11] Input: stmfts - Fix the MODULE_LICENSE()
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-1-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QPfJpOVCbfnnCtwRQ25JsCdJwSaQ1DCEJ1z
 w4fa/zpwnGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0DwAKCRBgAj/E00kg
 cq5mD/4yTLw1YnM4rI+iACitacCxgW0nmVtCq9jvEjg0eRc+Doih2LUZDIgT2hoGxStWlH9z3TU
 mTNEOe3T1xOHCG/tQHkqAb/IW9B/dKO7mjFFjCfCFKh8J2Z/kZz57hlSwJh8M79zezOCUPY+PHj
 vD8JoniSzdu2vjO3oV/UmglrT9BpZ3rOAQX1wOKkiVtyDj8P6p/a9wMY0yaJq3gqKMmj5TdC8NH
 h30Pbc2q2hcHmlew8HVX5uzH8CBqcE/M/0v/ngcqfha3mxPJ0GgelOsofM62TO75oH2vmyJtbdf
 6++KrthcQl0u0XtPs50kKUSBYgK1SlmFXJjTRVWvrlATqME7HKdlKLCWaZkHCFbCdg8xrIl2Snf
 +DFfqrCA338TmpVIiUG1MSvwSvkMGsvWfSMj5T3WSeSXyuLEX2N4Yq3qRStUGNavfKvDFdGQDRu
 h6yZUvoyQnaHkyt+wEs6qfpsCs1uN2yJeWMr/fKp6sKjmq9dIPiMN0yRl4lC/5eNIruMCZeCgFF
 dgfuqiMuZ0rEC8O9kWUshsp/XU0XBO6vYMunqsaLWp18/44ZdRKFLxpJfbb5GRolXc1cyqJiEX6
 HMFV1zfu1GqR7Xf+BDp8hQ0B/+qYoDM54sWZHsqyujpsQKaFJN7q03bEi+UWvjQD0dhl/okRJjp
 nD6jaImfTZCUfAw==
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

