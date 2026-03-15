From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:37 +0100
Subject: [PATCH WIP v2 01/11] Input: stmfts - Fix the MODULE_LICENSE()
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-1-70bc83ee9591@ixit.cz>
References: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
In-Reply-To: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
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
 h=from:subject:message-id; bh=GOG7YJ3B7o+VT+w4GnBTqkhN1kux8Pdc+XTRfCEP/IA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/5xvA2jZDZpaThkHd5fIt1f849y0fCPUsnG
 hXLFU7Ybe+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 cj3kEAC8flFyko3KgokdqnmsqY30E4QKqug+jx+R+RaNVCkI8FpRbdis6TXn7uLQqCrJdikYBPf
 KxcunVIjVjt/bDknbO2VRkUEd5Dh01Pvvqb6VBXSOW+jpRZB8OPPWttqhJC62jZaaIk2rGC8/yp
 8zg2zQslbVuiYN8BwH0EDPDYLGargId3yIAIvv8BZWiMCvox7BSSybfgJGx4iRs8aQndby1tReH
 qv0npS/Fm8lu/kRU9U84JPz2RBE82C4ktfIpDD+cV49ZWEvnLKatY3st5QCNaejIFrDXPJvE2jg
 JgjM6DNev53ejSSjK/ABnf0Z0vQ31+XcpKkgHrbpjuf41mChPzoq6FdgGXkqc3/ymN26Oymjrgi
 a5FzqJ/s3+nZwP+/Yo62Ao8EDUJfSD9vRXYOZKBnOLc+RZSj2x5Kd+2uBdaFYX4te8hpZKcKSkY
 pZtPRjblQ2WHvr2yvGZfn6SKCVQOrkvwgDJGmlyTNlK4Y5W/gf2iIKXHNpkBSkmTjkkTlMIQDS5
 zdeuGtNMKzoXYCANxYXga3Zo9I5uXaOH91S/4zYtpN8v3BzC+GlE2Bo+wJha6EBV6Ox2f3RB1rq
 uJk5xaWLKB2WfZnP6VV0rLXvgwv99SbqUB2WgjIwjKUvkmFHOiTGoejGCGGo4khGH6EnMs5OSEY
 E/x5OZYOTeloq5g==
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
index 4b166b0a9a5a6..d93ce68feca51 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -808,4 +808,4 @@ module_i2c_driver(stmfts_driver);
 
 MODULE_AUTHOR("Andi Shyti <andi.shyti@samsung.com>");
 MODULE_DESCRIPTION("STMicroelectronics FTS Touch Screen");
-MODULE_LICENSE("GPL v2");
+MODULE_LICENSE("GPL");

-- 
2.53.0

