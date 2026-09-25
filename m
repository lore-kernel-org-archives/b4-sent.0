From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 23:22:20 +0200
Subject: [PATCH v8 2/5] dt-bindings: input: touchscreen: st,stmfts: Improve
 example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-stmfts5-v8-2-0fcf49e2c85f@ixit.cz>
References: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
In-Reply-To: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1432; i=david@ixit.cz;
 h=from:subject:message-id; bh=8hrNriBZ9r5NUpjg2ye3gjvx8mrHqp+97D+QCG0V3A8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtuYMItkEShhRrfUYkEQkLKY95RkKZ9aBK821r
 KzsaRioKoeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarbmDAAKCRBgAj/E00kg
 cgUwD/0fup7gi4EPXq8XUj2gTbqngr8fFCroIEUBSk69EYJYBEP3euvVnv7BWAb1FueivXZz8Qy
 VcRY+on9bUdVD28j9oP8q3bYjsQwtlI4CkBJYYPxRqT0kdkLWlfyWWWqFR6d6IcB2kdzeuuGnYd
 zTsdPPhrNH2D61G35Z5ajlLItQ1asun/oSGNOZNlMdFwSD7JGxidOVWh19i3Bgx6/8vyWpZO3s2
 OmESlUJIexP0O4l19baYbTmUb08kbQONDEvDJBPBz74fcb/aPG0uOhzpczCT3r65QLUkCxncM2a
 xYMYoqHN61vTJrWl8W4hCFswqPPG3Yf7VNDoXL3AHpjqDpNo40DdHY+YbdcFkUWHKJhNTzgegiB
 ftN0w+ZnWgZZsiRqyUmK6hMRkKyKRU1ifRGU10K4rjq3kby5BXjtyGPKf3CrEz8BlKgx29ZaOz8
 hoPrmMzkk/dxle3kgDwwlAP1dEzVhe5va21gj2EX1UIVWUcyu0mz2nboz4sx+9NtG94PRav5btm
 XgNlDQjkoGyBLkQTMUUVw+7EkTAJiW7FcmXyyhgAUeaaMUI90AY3d+lKYsRfNyuGST3cdWXxqtA
 q9TAzHZVMhNhKIa7qJai5FkT9o9H8FJ0BWN2TpK0syQqrWLorz8sg0HdydidnDnbG/tB349J6/b
 zgKF1caJjGptipw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The touchscreen-size-{x,y} is exact number, the -1 deduction is done on
driver side.

Example now use interrupts-extended and size obviously not deducted by
one.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
index 64c4f24ea3dd0..6eb1ad6582d82 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -59,18 +59,17 @@ examples:
 
     i2c {
         #address-cells = <1>;
         #size-cells = <0>;
 
         touchscreen@49 {
             compatible = "st,stmfts";
             reg = <0x49>;
-            interrupt-parent = <&gpa1>;
-            interrupts = <1 IRQ_TYPE_LEVEL_LOW>;
-            touchscreen-size-x = <1599>;
-            touchscreen-size-y = <2559>;
+            interrupts-extended = <&gpa1 1 IRQ_TYPE_LEVEL_LOW>;
+            touchscreen-size-x = <1600>;
+            touchscreen-size-y = <2560>;
             touch-key-connected;
             avdd-supply = <&ldo30_reg>;
             vdd-supply = <&ldo31_reg>;
             ledvdd-supply = <&ldo33_reg>;
         };
     };

-- 
2.55.0

