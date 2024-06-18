From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 18 Jun 2024 14:08:20 +0200
Subject: [PATCH RESEND v10 09/12] dt-bindings: marvell: Document PXA1908
 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240618-pxa1908-lkml-v10-9-754e5ece9078@skole.hr>
References: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
In-Reply-To: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>, 
 Kees Cook <kees@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=890;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=sKkIzhW7HxgO/mwjme6nrHzJLLNyn3Ni8Blvn7ov2qY=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmcXjSmDe4RK5IUJ00M+M7KHJRka8cD3nxrs29K
 JZdzl66DVGJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZnF40gAKCRCaEZ6wQi2W
 4TczEACcGHC/FbESIR7UQzur4xcp9cz1kY+6ci3KLdG4mULEXIXK8gfmGJb4CHwFIXzYCpZB/c8
 cCwiUF8NJq3C46vAZSQ3oXjFsC7OXUWzuVxqOgJn4DSFtKNgVBDVxk30pjnBCi7+z9kWy28Yom9
 ed22QBR6A3snS+5AM7ukq4OrKCQKb7T8tWAaAhbfqOJY4Tsk6mzRx56ryF1nCAVx74/p+N+f+0f
 58/6LsjODLyXotsWhbNz+JTb5sKPgHJ0Vzs7c+/PKXJK6zfenZGKsmK8B33JZQI5m6WTm8ULG1/
 TdOQK0iRdkjh5l9Bhr2Lrq4BhT0UkTbQ3Gl7Pa8JjOEVbcFSMdfbxRoBAB9GmsihVi+bffVS4rx
 sZFChC0s2eF4q/hmdJeyad0B6chrtXVdX9HB6RiNRp6o+D+iUHoBBf06tn9kpgKM3WYVERR9KnF
 Jchdup0CeSvrd86RJOzfSWtYNPD4cgdXJFeG9jryFbOXlrvI7+F+1AXKfEaQAPeg1WYZR5vROfQ
 ZHen7IMoHjzWUHqn7m+fXhCJioVJD5BZrEmBacJ7CZMIUWO1hvND3mqeGSZGdjiVPsbhYs5ObyF
 euZ/L4srlFjCdMO2jPwt3XtRLOC41Ka2hJbM+/J+K+NXKh49oCwZNwJa1hBCABkrOSROCqgUC3u
 t62+w4NE2rJvZxA==
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
2.45.2

