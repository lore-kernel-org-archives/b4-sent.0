From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Thu, 29 Aug 2024 13:31:45 +0200
Subject: [PATCH v6 2/2] dt-bindings: rtc: Add support for SD2405AL.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240829-rtc-sd2405al-v6-2-4fbfe2624aa7@gmail.com>
References: <20240829-rtc-sd2405al-v6-0-4fbfe2624aa7@gmail.com>
In-Reply-To: <20240829-rtc-sd2405al-v6-0-4fbfe2624aa7@gmail.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-rtc@vger.kernel.org, 
 csokas.bence@prolan.hu, devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724931117; l=1442;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=7gympWliLOXfkOAZVaUnB51JPwKhR6f6uYQ7uncDrEQ=;
 b=+ZclLvcvAgzb0+xrE1b/163fsTkk4u/29du/NrUoYWMdhZpDsT1bqwKIktJlqr4nDvAkjTN4q
 clJ6wwqhRSZCZaVTJVbCh827Qk46EoFADzmY+buHLRR6/q34MPXMQYk
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the necessary documentation for SD2405AL.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 Documentation/devicetree/bindings/rtc/trivial-rtc.yaml | 2 ++
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 2 files changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/trivial-rtc.yaml b/Documentation/devicetree/bindings/rtc/trivial-rtc.yaml
index fffd759c603f..dae594626b2e 100644
--- a/Documentation/devicetree/bindings/rtc/trivial-rtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/trivial-rtc.yaml
@@ -38,6 +38,8 @@ properties:
       - dallas,ds1672
       # Extremely Accurate I²C RTC with Integrated Crystal and SRAM
       - dallas,ds3232
+      # SD2405AL Real-Time Clock
+      - dfrobot,sd2405al
       # EM Microelectronic EM3027 RTC
       - emmicro,em3027
       # I2C-BUS INTERFACE REAL TIME CLOCK MODULE
diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index a70ce43b3dc0..bd8b279a5152 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -368,6 +368,8 @@ patternProperties:
     description: Devantech, Ltd.
   "^dfi,.*":
     description: DFI Inc.
+  "^dfrobot,.*":
+    description: DFRobot Corporation
   "^dh,.*":
     description: DH electronics GmbH
   "^difrnce,.*":

-- 
2.34.1

