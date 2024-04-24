From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Wed, 24 Apr 2024 20:42:36 +0200
Subject: [PATCH v10 09/12] dt-bindings: marvell: Document PXA1908 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240424-pxa1908-lkml-v10-9-36cdfb5841f9@skole.hr>
References: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
In-Reply-To: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=890;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=+wdJL/Vtg+IC9uzo2i9e96b+dkkyPr63PvOur5KT8gc=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmKVKVIBYsEytUyJd8oGqAJAOqjbQngyPWzrdYK
 7HGB2hqFqWJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZilSlQAKCRCaEZ6wQi2W
 4USaD/wLLRbFPuTWEtYuyS5px4fRWghtgdvUbmHh0SjsuF5PL7R95OhGodO9nJQquwTcYHAwZwP
 5fLe40LbmCrOIquAF3I3vUcr3JnQIAiHAg/Scn1UkjBT1GlCQK4/NifXF8s9qEd6OZjyNhTvtS1
 HSpDuL7E2VTKSOKDDa9H42yHvK57U5/jLxE/q/kp5vXjTXWs6x0p6Hds2qR+fs7QnVJ09T7wszg
 SDIssc8btUJcppyPDS9mhVh53nCFRZbO0GgRaG2VWnFlHUvGp3gODcdlH1P2D7SN9x/dHf0Sji4
 vXbqRU6A8d7cVhBshStPGkeLknJXkpfUh/23gZJUJh68lCy2nWxiYP9DMLE7c1tfAFu0E5dtGuQ
 rQ7o9s+egoo6J+cLHBA+nuvTXMoZCQuey4FTaoIpi7Wn1QJP5lxxfc+VdhTH44oCVDx6ppP0LNQ
 D09I1axki7uYB93o6wQ6IvUGJItfbV92EOHUMB5b0PYoOjScyeWmuDQN3iAs8I1eHG+Kosa8qvg
 fqIQapFwT72KQAhi+S1uJNsHTayN/ZNLwb1dKFH/ANpg7sHtRw8cEvsvykwDyV76nh1DMwC9fM5
 BAUO9NRSilRLPIXZvttvXP+zV7uE6c2KuQJzZAyDSwSPFlyN6c2kTmzNuIiviDrtZ3Rn67eYtLB
 W+u8pOhSkSzSK1w==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=53DF9D4D9C3FE110FB362D789A119EB0422D96E1
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/default with auth_id=112
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt binding for the Marvell PXA1908 SoC.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 Documentation/devicetree/bindings/arm/mrvl/mrvl.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/mrvl/mrvl.yaml b/Documentation/devicetree/bindings/arm/mrvl/mrvl.yaml
index 4c43eaf3632e..f73bb8ec3a1a 100644
--- a/Documentation/devicetree/bindings/arm/mrvl/mrvl.yaml
+++ b/Documentation/devicetree/bindings/arm/mrvl/mrvl.yaml
@@ -35,6 +35,11 @@ properties:
           - enum:
               - dell,wyse-ariel
           - const: marvell,mmp3
+      - description: PXA1908 based boards
+        items:
+          - enum:
+              - samsung,coreprimevelte
+          - const: marvell,pxa1908
 
 additionalProperties: true
 

-- 
2.44.0

